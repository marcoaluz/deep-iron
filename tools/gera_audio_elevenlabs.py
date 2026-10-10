#!/usr/bin/env python
"""Bloco 115: gera os sons do jogo no ElevenLabs (Sound Effects) a partir de project.godot/data/audio/slots.json.

A chave fica em .env (ELEVENLABS_API_KEY=...; o .env está no .gitignore) ou na variável de ambiente. Só biblioteca padrão.

    python tools/gera_audio_elevenlabs.py --saldo                       # créditos do plano (não gera nada)
    python tools/gera_audio_elevenlabs.py --lista                       # o que falta gerar
    python tools/gera_audio_elevenlabs.py --ids sfx/picareta passos/pedra   # gera só esses slots
    python tools/gera_audio_elevenlabs.py --pasta stingers               # gera uma pasta inteira
    python tools/gera_audio_elevenlabs.py --tudo                          # todos os slots (menos a música)
    python tools/gera_audio_elevenlabs.py --ids ... --dry-run             # mostra o que faria, sem gastar

Já existe arquivo? Pula (use --force pra refazer). Salva em project.godot/assets/audio/<id>.wav (variações: <id>_0.wav, _1...).
Loops e sons curtos saem em PCM e viram WAV (sem o vazio de começo e fim do MP3, que quebra o loop).
Depois: godot --headless --path project.godot --import  e  python tools/lista_audio.py
"""
import argparse
import json
import os
import re
import struct
import sys
import time
import urllib.error
import urllib.request
import wave

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SLOTS = os.path.join(RAIZ, "project.godot", "data", "audio", "slots.json")
PASTA = os.path.join(RAIZ, "project.godot", "assets", "audio")
API = "https://api.elevenlabs.io"
## Os loops saem a 24 kHz (ambiência: arquivo menor); o resto a 44,1 kHz.
TAXA_LOOP = 24000
TAXA_TIRO = 44100
## A API aceita de 0,5 a 30 s.
DUR_MIN, DUR_MAX = 0.5, 30.0
## Quanto o prompt pesa (0 a 1): mais alto = segue mais o texto.
INFLUENCIA = 0.5


def chave():
    k = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    env = os.path.join(RAIZ, ".env")
    if not k and os.path.exists(env):
        for linha in open(env, encoding="utf-8"):
            m = re.match(r"\s*ELEVENLABS_API_KEY\s*=\s*(.*)", linha)
            if m:
                k = m.group(1).strip().strip("'\"")
    if not k:
        sys.exit("Sem ELEVENLABS_API_KEY (ponha no .env ou na variável de ambiente).")
    return k


def pede(metodo, caminho, k, corpo=None):
    req = urllib.request.Request(API + caminho, method=metodo, data=json.dumps(corpo).encode() if corpo is not None else None,
                                 headers={"xi-api-key": k, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=180) as r:
        return r.read(), dict(r.headers)


def saldo(k):
    dados, _ = pede("GET", "/v1/user/subscription", k)
    d = json.loads(dados)
    usado = d.get("character_count")
    limite = d.get("character_limit")
    print("Plano: %s  •  créditos usados %s de %s  •  restam %s" % (d.get("tier"), usado, limite,
                                                                   (limite - usado) if isinstance(usado, int) and isinstance(limite, int) else "?"))
    return usado


def duracao_de(s):
    """'loop 40 s', '0.5 s cada', '2.5 s' -> segundos (limitados ao máximo da API)."""
    m = re.search(r"([\d.]+)\s*s", str(s.get("duracao", "")))
    d = float(m.group(1)) if m else 3.0
    return max(DUR_MIN, min(DUR_MAX, d))


def nomes(s):
    n = int(s.get("variacoes", 0))
    return [s["id"]] if n <= 0 else ["%s_%d" % (s["id"], i) for i in range(n)]


def caminho_wav(nome):
    return os.path.join(PASTA, *(nome + ".wav").split("/"))


def tem_arquivo(nome):
    return any(os.path.exists(os.path.join(PASTA, *(nome + "." + e).split("/"))) for e in ("ogg", "wav", "mp3"))


def estereo_de(s):
    """Ambiência, interface, stingers, introdução e sons sem posição ficam estéreo; o resto (prédios, efeitos, passos, voz, sons soltos) vira MONO."""
    return s.get("tipo") == "loop" or s.get("bus") == "UI" or bool(s.get("global")) or s["id"].split("/")[0] in ("stingers", "intro")


def grava_wav(destino, pcm_estereo, taxa, estereo):
    """pcm_estereo = PCM de 16 bits estéreo intercalado; mono = a média dos dois canais."""
    if not estereo:
        n = len(pcm_estereo) // 4
        amostras = struct.unpack("<%dh" % (n * 2), pcm_estereo)
        pcm = struct.pack("<%dh" % n, *[(amostras[2 * i] + amostras[2 * i + 1]) // 2 for i in range(n)])
    else:
        pcm = pcm_estereo
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    with wave.open(destino, "wb") as w:
        w.setnchannels(2 if estereo else 1)
        w.setsampwidth(2)
        w.setframerate(taxa)
        w.writeframes(pcm)


def gera_um(k, s, nome, dry):
    loop = s.get("tipo") in ("loop", "loop_predio")
    taxa = TAXA_LOOP if loop else TAXA_TIRO
    dur = duracao_de(s)
    corpo = {"text": s["prompt"], "duration_seconds": dur, "prompt_influence": INFLUENCIA, "loop": loop, "model_id": "eleven_text_to_sound_v2"}
    destino = caminho_wav(nome)
    if dry:
        print("  [dry-run] %s  (%.1f s, %s, %d Hz)" % (nome, dur, "loop" if loop else "tiro", taxa))
        return True
    for tentativa in range(4):
        try:
            dados, cab = pede("POST", "/v1/sound-generation?output_format=pcm_%d" % taxa, k, corpo)
            break
        except urllib.error.HTTPError as e:
            msg = e.read().decode("utf-8", "replace")[:300]
            if e.code == 429 and tentativa < 3:
                time.sleep(8 * (tentativa + 1))
                continue
            print("  ERRO %s em %s: %s" % (e.code, nome, msg))
            return False
    frames = len(dados) // 4  # a API devolve PCM de 16 bits ESTÉREO intercalado (conferido na prática, a documentação diz mono)
    seg = frames / float(taxa)
    if frames < taxa * 0.2:
        print("  ERRO: %s veio com %.2f s (pequeno demais)" % (nome, seg))
        return False
    grava_wav(destino, dados[: frames * 4], taxa, estereo_de(s))
    print("  ok  %s  (%.1f s pedidos, %.1f s gerados, %s, %d KB)" % (nome, dur, seg, "estéreo" if estereo_de(s) else "mono", os.path.getsize(destino) // 1024))
    return True


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--saldo", action="store_true")
    ap.add_argument("--lista", action="store_true")
    ap.add_argument("--ids", nargs="*", default=[])
    ap.add_argument("--pasta", nargs="*", default=[])
    ap.add_argument("--tudo", action="store_true")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    k = chave()
    if a.saldo:
        saldo(k)
        return 0
    slots = json.load(open(SLOTS, encoding="utf-8"))["slots"]
    slots = [s for s in slots if not s["id"].startswith("musica/") and s.get("prompt")]
    if a.tudo:
        esc = slots
    else:
        esc = [s for s in slots if s["id"] in a.ids or s["id"].split("/")[0] in a.pasta]
    falta = [(s, n) for s in esc for n in nomes(s) if a.force or not tem_arquivo(n)]
    if a.lista:
        todos = [(s, n) for s in slots for n in nomes(s) if not tem_arquivo(n)]
        print("%d arquivos faltam de %d" % (len(todos), sum(len(nomes(s)) for s in slots)))
        for s, n in todos:
            print("  ", n)
        return 0
    if not esc:
        print("Nada escolhido (use --ids, --pasta ou --tudo).")
        return 1
    print("%d arquivos pra gerar (%d slots escolhidos)" % (len(falta), len(esc)))
    antes = None if a.dry_run else saldo(k)
    ok = erros = 0
    for s, n in falta:
        if gera_um(k, s, n, a.dry_run):
            ok += 1
        else:
            erros += 1
        if not a.dry_run:
            time.sleep(0.4)
    if not a.dry_run:
        depois = saldo(k)
        if isinstance(antes, int) and isinstance(depois, int) and ok:
            print("Custo: %d créditos pra %d arquivos (%.0f por arquivo)" % (depois - antes, ok, (depois - antes) / ok))
    print("%d gerados, %d com erro" % (ok, erros))
    return 0 if erros == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
