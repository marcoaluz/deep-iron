#!/usr/bin/env python
"""Bloco 117: gera a MÚSICA do jogo pela API de música do ElevenLabs (Eleven Music), a partir dos slots musica/* de
project.godot/data/audio/slots.json (abertura, intro, jogo, perigo).

API (documentação oficial, conferida em 2026-10-10): POST https://api.elevenlabs.io/v1/music, header xi-api-key, corpo JSON com
prompt, music_length_ms (3000 a 600000), model_id (music_v1 padrão), force_instrumental; query output_format. Funcionou no plano Creator.
Aqui pedimos pcm_44100 (estéreo de verdade, 16 bits): dá pra medir e corrigir o volume e emendar o loop em Python.

    python tools/elevenlabs/gerar_musica.py --lista
    python tools/elevenlabs/gerar_musica.py --so musica/abertura --dry-run
    python tools/elevenlabs/gerar_musica.py --tudo                          # as 4 músicas (1 chamada cada)
    python tools/elevenlabs/gerar_musica.py --so musica/jogo --candidatos 3 # 3 versões em audio_candidatos/musica/
    python tools/elevenlabs/gerar_musica.py --aprovar musica/jogo 2         # fica a 2ª
    python tools/elevenlabs/gerar_musica.py --so musica/jogo --force        # gasta de novo, sorteia outra versão

Pós-processamento (numpy, sem ffmpeg): normaliza o volume para RMS -18 dBFS sem passar de pico -1,5 dBFS e, nas músicas de LOOP, faz um
crossfade longo (3 s) entre o fim e o começo, para repetir sem emenda. A intro não repete: só ganha um fade-out curto. Sai em WAV
(project.godot/assets/audio/musica/<nome>.wav); com o ffmpeg instalado a conversão pra OGG fica a cargo do posprocessa.py.
A chave vem do .env (nunca é impressa). Cache das chamadas em audio_candidatos/_cache_musica/ (mesmo pedido = 0 crédito).
"""
import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error

try:
    import numpy as np
except ImportError:  # --lista e --dry-run funcionam sem; gerar/aprovar precisam (pip install numpy)
    np = None

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gerar_sons as gs  # noqa: E402  (chave, mascara, pede, saldo)

SLOTS = gs.SLOTS
GERADOS = os.path.join(gs.RAIZ, "project.godot", "data", "audio", "musicas.json")
PASTA = os.path.join(gs.RAIZ, "project.godot", "assets", "audio")
CANDIDATOS = os.path.join(gs.RAIZ, "audio_candidatos", "musica")
CACHE = os.path.join(gs.RAIZ, "audio_candidatos", "_cache_musica")
TAXA = 44100
MODELO = "music_v1"
RMS_ALVO = -18.0  # dBFS: um pouco abaixo da música antiga (-16): sobra espaço pro ducking e pro slider de música
PICO_MAX = -1.5  # dBFS
XFADE_S = 3.0  # crossfade do loop (música precisa de mais que o efeito: 3 s)
FADE_FIM_S = 2.5  # a intro termina com fade-out


def slots_musica():
    return [s for s in json.load(open(SLOTS, encoding="utf-8"))["slots"] if s["id"].startswith("musica/") and s.get("prompt")]


def hash_de(s):
    return hashlib.sha1(("%s|%s|%d|%s" % (s["prompt"], MODELO, int(s["seg"]), TAXA)).encode("utf-8")).hexdigest()[:10]


def corpo_de(s):
    return {"prompt": s["prompt"], "music_length_ms": int(s["seg"]) * 1000, "model_id": MODELO, "force_instrumental": True}


def destino(s):
    return os.path.join(PASTA, s["id"] + ".wav")


def cache_de(s, n):
    return os.path.join(CACHE, "%s_%s_%d.pcm" % (hash_de(s), s["id"].replace("/", "__"), n))


def registro():
    return json.load(open(GERADOS, encoding="utf-8")) if os.path.exists(GERADOS) else {"arquivos": {}}


def grava_registro(r):
    json.dump(r, open(GERADOS, "w", encoding="utf-8"), ensure_ascii=False, indent="\t", sort_keys=True)


def chama(k, s, n, ignora_cache=False):
    """O PCM estéreo (int16 intercalado) do pedido: do cache, ou da API (e guarda no cache)."""
    c = cache_de(s, n)
    if not ignora_cache and os.path.exists(c):
        return open(c, "rb").read(), True
    d = gs.pede("POST", "/v1/music?output_format=pcm_%d" % TAXA, k, corpo_de(s))
    os.makedirs(CACHE, exist_ok=True)
    open(c, "wb").write(d)
    return d, False


# ------------------------------------------------------------ pós-processamento
def db(v):
    return 20.0 * np.log10(max(float(v), 1.0) / 32768.0)


def emenda_longa(x, taxa, seg):
    """Crossfade de potência igual: o fim continua direto no começo (o arquivo encurta `seg`). x: (frames, 2) float."""
    n = min(int(seg * taxa), len(x) // 3)
    t = (np.arange(n) + 0.5) / n
    a = np.sin(t * np.pi / 2.0)[:, None]  # o começo entra
    b = np.cos(t * np.pi / 2.0)[:, None]  # o fim sai
    saida = x[: len(x) - n].copy()
    saida[:n] = x[:n] * a + x[len(x) - n:] * b
    return saida


def fade_fim(x, taxa, seg):
    n = min(int(seg * taxa), len(x))
    x = x.copy()
    x[len(x) - n:] *= np.linspace(1.0, 0.0, n)[:, None]
    return x


def processa(pcm, s):
    """PCM bruto -> (frames, 2) int16 pronto: corta o silêncio do começo/fim da intro, normaliza e emenda (ou faz fade-out)."""
    a = np.frombuffer(pcm, dtype="<i2")
    a = a[: len(a) // 2 * 2].reshape(-1, 2).astype(np.float64)
    if s.get("loop"):
        a = emenda_longa(a, TAXA, XFADE_S)
    else:
        a = fade_fim(a, TAXA, FADE_FIM_S)
    rms = db(np.sqrt(np.mean(a * a)))
    pico = db(np.max(np.abs(a)))
    g = RMS_ALVO - rms
    g = min(g, PICO_MAX - pico)  # o pico manda: não passa de PICO_MAX
    a = a * (10.0 ** (g / 20.0))
    return np.clip(np.round(a), -32768, 32767).astype("<i2"), g


def grava_wav(caminho, x):
    import wave
    os.makedirs(os.path.dirname(caminho), exist_ok=True)
    with wave.open(caminho, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(TAXA)
        w.writeframes(x.tobytes())


def relatorio(x):
    f = x.astype(np.float64)
    return "%.1f s, RMS %.1f dBFS, pico %.1f dBFS" % (len(x) / TAXA, db(np.sqrt(np.mean(f * f))), db(np.max(np.abs(f))))


def razao_estalo(x):
    """Salto no ponto do loop / diferença típica entre amostras vizinhas (canal esquerdo)."""
    c = x[:, 0].astype(np.float64)
    tip = np.mean(np.abs(np.diff(c[:200000])))
    return abs(c[0] - c[-1]) / max(tip, 1.0)


# ------------------------------------------------------------ principal
def escolhe(args, todos):
    if args.tudo:
        return todos
    alvo = []
    for t in args.so or []:
        alvo += [s for s in todos if s["id"] == t or s["id"].split("/", 1)[1] == t]
    return alvo


def main():
    ap = argparse.ArgumentParser(description="Gera a música do jogo pela API de música do ElevenLabs.")
    ap.add_argument("--so", nargs="+", help="ids (musica/jogo) ou só o nome (jogo)")
    ap.add_argument("--tudo", action="store_true", help="as 4 músicas")
    ap.add_argument("--lista", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--candidatos", type=int, default=0, help="N versões em audio_candidatos/musica/ (não troca o arquivo do jogo)")
    ap.add_argument("--aprovar", nargs=2, metavar=("ID", "N"), help="copia a candidata N pro jogo")
    ap.add_argument("--force", action="store_true", help="ignora o cache (gasta crédito: sorteia outra versão)")
    ap.add_argument("--max-geracoes", type=int, default=8, help="teto de chamadas por execução")
    ap.add_argument("--sim", action="store_true", help="confirma sem perguntar")
    args = ap.parse_args()
    todos = slots_musica()
    reg = registro()
    if np is None and not (args.lista or args.dry_run):
        sys.exit("Falta o numpy para processar o áudio: pip install numpy")

    if args.lista:
        for s in todos:
            f = destino(s)
            ok = os.path.exists(f)
            est = ""
            if ok:
                h = reg["arquivos"].get(s["id"], {}).get("hash")
                est = "  [desatualizado: o prompt mudou]" if h and h != hash_de(s) else ""
            print("%-18s %3d s  %-5s %s%s" % (s["id"], s["seg"], "loop" if s.get("loop") else "uma vez", "TEM arquivo" if ok else "falta", est))
        return 0

    if args.aprovar:
        s = next((x for x in todos if x["id"] == args.aprovar[0] or x["id"].split("/", 1)[1] == args.aprovar[0]), None)
        n = int(args.aprovar[1])
        c = cache_de(s, n) if s else None
        if not s or not os.path.exists(c):
            print("ERRO: candidata não existe (gere antes com --candidatos).")
            return 1
        x, g = processa(open(c, "rb").read(), s)
        grava_wav(destino(s), x)
        reg["arquivos"][s["id"]] = {"hash": hash_de(s), "candidata": n, "aprovado": True, "ganho_db": round(float(g), 1)}
        grava_registro(reg)
        print("%s <- candidata %d  (%s)" % (s["id"], n, relatorio(x)))
        return 0

    alvo = escolhe(args, todos)
    if not alvo:
        print("Nada escolhido: use --tudo ou --so musica/jogo (--lista mostra o que existe).")
        return 1
    n_cand = max(1, args.candidatos)
    plano = []
    for s in alvo:
        if args.candidatos:
            plano += [(s, n) for n in range(n_cand)]
        elif args.force or not os.path.exists(destino(s)) or reg["arquivos"].get(s["id"], {}).get("hash") not in (None, hash_de(s)):
            plano.append((s, 0))
    chamadas = [(s, n) for s, n in plano if args.force or not os.path.exists(cache_de(s, n))]
    seg = sum(s["seg"] for s, n in chamadas)
    print("%d arquivo(s) no plano, %d chamada(s) à API (%d s de música; o resto vem do cache)." % (len(plano), len(chamadas), seg))
    print("Custo em créditos: o contador do plano NÃO se mexeu nos testes (10 s); confira com --saldo depois.")
    if args.dry_run:
        for s, n in plano:
            print("  %s #%d  %d s  %s" % (s["id"], n, s["seg"], "(cache)" if (s, n) not in chamadas else "(API)"))
        return 0
    if len(chamadas) > args.max_geracoes:
        print("RECUSADO: %d chamadas passam do teto de %d (--max-geracoes)." % (len(chamadas), args.max_geracoes))
        return 1
    if chamadas and not args.sim and sys.stdin.isatty():
        if input("Gerar %d chamada(s)? [s/N] " % len(chamadas)).strip().lower() not in ("s", "sim", "y"):
            return 1
    elif chamadas and not args.sim and not sys.stdin.isatty():
        print("Sem terminal: confirme com --sim.")
        return 1
    k = gs.chave() if chamadas or plano else None
    for s, n in plano:
        try:
            pcm, cache = chama(k, s, n, ignora_cache=args.force)
        except urllib.error.HTTPError as e:
            print("ERRO %d em %s: %s" % (e.code, s["id"], gs.mascara(e.read().decode("utf-8", "replace")[:400], k)))
            return 1
        x, g = processa(pcm, s)
        if args.candidatos:
            grava_wav(os.path.join(CANDIDATOS, s["id"].split("/", 1)[1], "%d.wav" % n), x)
            print("  %s #%d -> audio_candidatos/musica/%s/%d.wav  (%s)%s" % (s["id"], n, s["id"].split("/", 1)[1], n, relatorio(x), " [cache]" if cache else ""))
        else:
            grava_wav(destino(s), x)
            reg["arquivos"][s["id"]] = {"hash": hash_de(s), "candidata": n, "aprovado": False, "ganho_db": round(float(g), 1)}
            grava_registro(reg)
            extra = "  estalo do loop: %.1f" % razao_estalo(x) if s.get("loop") else ""
            print("  %s -> %s  (%s)%s%s" % (s["id"], os.path.relpath(destino(s), gs.RAIZ), relatorio(x), extra, " [cache]" if cache else ""))
        time.sleep(0.5)
    print("Depois: godot --headless --path project.godot --import")
    return 0


if __name__ == "__main__":
    sys.exit(main())
