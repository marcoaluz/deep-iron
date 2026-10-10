#!/usr/bin/env python
"""Bloco 115/116: gera os sons do jogo pela API de efeitos sonoros do ElevenLabs, a partir de project.godot/data/audio/slots.json.

API (documentação oficial, conferida em 2026-10-10): POST https://api.elevenlabs.io/v1/sound-generation, header xi-api-key, corpo JSON
{text, duration_seconds (0,5 a 30), prompt_influence (0 a 1), loop (só no modelo v2), model_id (eleven_text_to_sound_v2)}; query output_format.
A chave vem de ELEVENLABS_API_KEY (variável de ambiente) ou de um .env na raiz (que está no .gitignore). Ela NUNCA é impressa, gravada em log,
em relatório ou no git (`--confere-segredos` varre os arquivos do git atrás dela). Só biblioteca padrão.

  --dry-run                   lista o que seria gerado, a contagem e o custo estimado, sem gastar nada
  --so <id|pasta> [...]       só esses slots (id exato, ou a pasta: ambiencia, predios, stingers, ui, sfx, passos, voz...); sem isso, nada é gerado
  --tudo                      todos os slots (menos a música), na ordem de prioridade
  --candidatos N              gera N variações de cada som em audio_candidatos/ (fora do git) pra você escolher
  --aprovar <nome> <n>        copia a candidata n pro destino final (project.godot/assets/audio/<nome>.wav)
  --force                     refaz mesmo o que já existe com o prompt atual (ignora o cache: GASTA crédito de novo, sorteia outra versão)
  --atualiza                  refaz o que ficou DESATUALIZADO (o prompt do slot mudou depois que o arquivo foi gerado)
  --max-geracoes N            teto de chamadas à API por execução (padrão 40)
  --confirma-acima C          pede confirmação se o custo estimado passar de C créditos (padrão 1500); --sim confirma sem perguntar
  --saldo | --lista | --desatualizados | --registra-existentes | --reprocessa | --confere-segredos | --docs

Cache: cada chamada à API fica guardada (audio_candidatos/_cache/, fora do git) pela chave hash(prompt+parâmetros)+nome+n: o mesmo pedido nunca gasta
crédito duas vezes. Depois de gerar: godot --headless --path project.godot --import
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import time
import urllib.error
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import posprocessa as pos  # noqa: E402

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SLOTS = os.path.join(RAIZ, "project.godot", "data", "audio", "slots.json")
GERADOS = os.path.join(RAIZ, "project.godot", "data", "audio", "gerados.json")
PASTA = os.path.join(RAIZ, "project.godot", "assets", "audio")
CANDIDATOS = os.path.join(RAIZ, "audio_candidatos")
CACHE = os.path.join(CANDIDATOS, "_cache")
API = "https://api.elevenlabs.io"
MODELO = "eleven_text_to_sound_v2"
## Os loops saem a 24 kHz (ambiência: arquivo menor); o resto a 44,1 kHz.
TAXA_LOOP = 24000
TAXA_TIRO = 44100
## A API aceita de 0,5 a 30 s.
DUR_MIN, DUR_MAX = 0.5, 30.0
## Quanto o prompt pesa (0 a 1) quando o slot não diz: mais alto = segue mais o texto.
INFLUENCIA = 0.5
## Créditos por segundo gerado (medido no lote de 186 arquivos: 10.068 créditos / 978 s).
CREDITOS_POR_S = 10.5
MAX_GERACOES = 40
CONFIRMA_ACIMA = 1500
## A ordem em que se gera (e se ouve): o que mais pesa na experiência primeiro.
PRIORIDADE = ["ambiencia/", "predios/fornalha", "predios/sino", "stingers/", "ui/", "predios/", "sfx/", "passos/", "voz/", "animais/", "criaturas/",
              "perigo/", "maquinas/", "vida/", "pontuais/", "intro/"]


# ------------------------------------------------------------ segredos
def chave():
    k = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    env = os.path.join(RAIZ, ".env")
    if not k and os.path.exists(env):
        for linha in open(env, encoding="utf-8"):
            m = re.match(r"\s*ELEVENLABS_API_KEY\s*=\s*(.*)", linha)
            if m:
                k = m.group(1).strip().strip("'\"")
    if not k:
        sys.exit("Sem ELEVENLABS_API_KEY (ponha no .env da raiz ou na variável de ambiente; veja .env.example).")
    return k


def mascara(texto, k):
    """Tira a chave de qualquer texto que vá pra tela."""
    return str(texto).replace(k, "***") if k else str(texto)


def confere_segredos():
    """Garante que o .env e a pasta de candidatos estão no .gitignore e que a chave não está em nenhum arquivo do git."""
    k = chave()
    ig = open(os.path.join(RAIZ, ".gitignore"), encoding="utf-8").read().split("\n")
    ok = True
    for padrao in (".env", "audio_candidatos/"):
        if padrao not in [l.strip() for l in ig]:
            print("ERRO: %s não está no .gitignore" % padrao)
            ok = False
    arquivos = subprocess.run(["git", "ls-files", "-z"], cwd=RAIZ, capture_output=True).stdout.split(b"\0")
    achou = []
    for a in arquivos:
        if not a:
            continue
        caminho = os.path.join(RAIZ, a.decode("utf-8", "replace"))
        try:
            if os.path.getsize(caminho) > 2_000_000 or caminho.lower().endswith((".png", ".wav", ".ogg", ".mp3", ".gif", ".jpg")):
                continue
            if k.encode() in open(caminho, "rb").read():
                achou.append(os.path.relpath(caminho, RAIZ))
        except OSError:
            pass
    if achou:
        print("ERRO: a chave aparece em arquivos do git: %s" % achou)
        ok = False
    print("Segredos: %s (%d arquivos do git varridos; o .env %s)" % ("OK" if ok else "FALHOU", len([a for a in arquivos if a]),
                                                                    "está no .gitignore" if ".env" in [l.strip() for l in ig] else "NÃO está no .gitignore"))
    return 0 if ok else 1


# ------------------------------------------------------------ API
def pede(metodo, caminho, k, corpo=None):
    req = urllib.request.Request(API + caminho, method=metodo, data=json.dumps(corpo).encode() if corpo is not None else None,
                                 headers={"xi-api-key": k, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=180) as r:
        return r.read()


def saldo(k):
    d = json.loads(pede("GET", "/v1/user/subscription", k))
    usado, limite = d.get("character_count"), d.get("character_limit")
    print("Plano: %s  •  créditos usados %s de %s  •  restam %s" % (d.get("tier"), usado, limite,
                                                                   (limite - usado) if isinstance(usado, int) and isinstance(limite, int) else "?"))
    return usado


# ------------------------------------------------------------ slots e hash
def carrega_slots():
    return [s for s in json.load(open(SLOTS, encoding="utf-8"))["slots"] if not s["id"].startswith("musica/") and s.get("prompt")]


def duracao_de(s):
    m = re.search(r"([\d.]+)\s*s", str(s.get("duracao", "")))
    return max(DUR_MIN, min(DUR_MAX, float(m.group(1)) if m else 3.0))


def eh_loop(s):
    return s.get("tipo") in ("loop", "loop_predio")


def nomes(s):
    n = int(s.get("variacoes", 0))
    return [s["id"]] if n <= 0 else ["%s_%d" % (s["id"], i) for i in range(n)]


def params_de(s):
    return {"text": s["prompt"], "duration_seconds": duracao_de(s), "prompt_influence": float(s.get("influencia", INFLUENCIA)),
            "loop": eh_loop(s), "model_id": MODELO}


def hash_de(s):
    """Identifica o PEDIDO (prompt + parâmetros): muda o texto ou a duração, muda o hash."""
    return hashlib.sha1(json.dumps(params_de(s), sort_keys=True).encode()).hexdigest()[:16]


def taxa_de(s):
    return TAXA_LOOP if eh_loop(s) else TAXA_TIRO


def estereo_de(s):
    """Ambiência, interface, stingers, introdução e sons sem posição ficam estéreo; o resto vira MONO."""
    return s.get("tipo") == "loop" or s.get("bus") == "UI" or bool(s.get("global")) or s["id"].split("/")[0] in ("stingers", "intro")


def caminho_final(nome):
    return os.path.join(PASTA, *(nome + ".wav").split("/"))


def tem_arquivo(nome):
    return any(os.path.exists(os.path.join(PASTA, *(nome + "." + e).split("/"))) for e in ("ogg", "wav", "mp3"))


def prioridade_de(s):
    for i, p in enumerate(PRIORIDADE):
        if s["id"].startswith(p):
            return i
    return len(PRIORIDADE)


def gerados():
    if os.path.exists(GERADOS):
        return json.load(open(GERADOS, encoding="utf-8"))
    return {"versao": 1, "arquivos": {}}


def salva_gerados(g):
    with open(GERADOS, "w", encoding="utf-8", newline="\n") as f:
        json.dump(g, f, ensure_ascii=False, indent=1, sort_keys=True)
        f.write("\n")


def estado_de(s, nome, g):
    """falta | ok | desatualizado | sem_registro"""
    if not tem_arquivo(nome):
        return "falta"
    reg = g["arquivos"].get(nome)
    if reg is None:
        return "sem_registro"
    return "ok" if reg.get("hash") == hash_de(s) else "desatualizado"


# ------------------------------------------------------------ gerar (com cache de chamadas)
def chave_cache(s, nome, n):
    return "%s_%s_%d" % (hash_de(s), nome.replace("/", "__"), n)


def bruto_do_cache(s, nome, n):
    p = os.path.join(CACHE, chave_cache(s, nome, n) + ".pcm")
    return open(p, "rb").read() if os.path.exists(p) else None


def chama_api(k, s, nome, n, ignora_cache=False):
    """O PCM estéreo de 16 bits do pedido (do cache, se já foi gerado; senão da API, e guarda no cache). ignora_cache = refazer (gasta crédito)."""
    d = None if ignora_cache else bruto_do_cache(s, nome, n)
    if d is not None:
        return d, True
    corpo = params_de(s)
    for tentativa in range(4):
        try:
            d = pede("POST", "/v1/sound-generation?output_format=pcm_%d" % taxa_de(s), k, corpo)
            break
        except urllib.error.HTTPError as e:
            msg = mascara(e.read().decode("utf-8", "replace")[:300], k)
            if e.code == 429 and tentativa < 3:
                time.sleep(8 * (tentativa + 1))
                continue
            print("  ERRO %s em %s: %s" % (e.code, nome, msg))
            return None, False
        except urllib.error.URLError as e:
            print("  ERRO de rede em %s: %s" % (nome, mascara(e.reason, k)))
            return None, False
    os.makedirs(CACHE, exist_ok=True)
    open(os.path.join(CACHE, chave_cache(s, nome, n) + ".pcm"), "wb").write(d)
    return d, False


def para_mono_ou_estereo(pcm, s):
    """A API devolve PCM de 16 bits ESTÉREO intercalado (conferido na prática; a documentação diz MP3/mono). Mono = média dos canais."""
    n = len(pcm) // 4
    a = struct.unpack("<%dh" % (n * 2), pcm[: n * 4])
    if estereo_de(s):
        return 2, list(a)
    return 1, [(a[2 * i] + a[2 * i + 1]) // 2 for i in range(n)]


def processa_pcm(pcm, s):
    ch, x = para_mono_ou_estereo(pcm, s)
    return ch, pos.processa(x, ch, taxa_de(s), s)


def grava_final(nome, s, pcm, g):
    ch, (x, notas) = processa_pcm(pcm, s)
    pos.escreve_wav(caminho_final(nome), ch, taxa_de(s), x)
    g["arquivos"][nome] = {"hash": hash_de(s), "gerado_em": time.strftime("%Y-%m-%d"), "aprovado": False}
    return len(x) // ch / float(taxa_de(s)), notas


def nome_pasta_candidatos(nome):
    return os.path.join(CANDIDATOS, nome.replace("/", "__"))


# ------------------------------------------------------------ plano, custo e confirmação
def escolhe(slots, so, tudo):
    if tudo:
        esc = slots
    else:
        esc = [s for s in slots if any(s["id"] == q or s["id"].startswith(q.rstrip("/") + "/") for q in so)]
    return sorted(esc, key=lambda s: (prioridade_de(s), s["id"]))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--saldo", action="store_true")
    ap.add_argument("--lista", action="store_true")
    ap.add_argument("--desatualizados", action="store_true")
    ap.add_argument("--registra-existentes", action="store_true")
    ap.add_argument("--reprocessa", action="store_true")
    ap.add_argument("--confere-segredos", action="store_true")
    ap.add_argument("--docs", action="store_true")
    ap.add_argument("--so", nargs="*", default=[])
    ap.add_argument("--tudo", action="store_true")
    ap.add_argument("--candidatos", type=int, default=0)
    ap.add_argument("--aprovar", nargs=2, metavar=("NOME", "N"))
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--atualiza", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--max-geracoes", type=int, default=MAX_GERACOES)
    ap.add_argument("--confirma-acima", type=float, default=CONFIRMA_ACIMA)
    ap.add_argument("--sim", action="store_true")
    a = ap.parse_args()

    if a.confere_segredos:
        return confere_segredos()
    if a.docs:
        import docs_audio
        return docs_audio.main()
    slots = carrega_slots()
    g = gerados()

    if a.lista or a.desatualizados:
        for s in sorted(slots, key=lambda s: (prioridade_de(s), s["id"])):
            for n in nomes(s):
                e = estado_de(s, n, g)
                if (a.lista and e == "falta") or (a.desatualizados and e in ("desatualizado", "sem_registro")):
                    print("  %-13s %s" % (e, n))
        return 0
    if a.registra_existentes:
        novos = 0
        for s in slots:
            for n in nomes(s):
                if tem_arquivo(n) and n not in g["arquivos"]:
                    g["arquivos"][n] = {"hash": hash_de(s), "gerado_em": time.strftime("%Y-%m-%d"), "aprovado": True}
                    novos += 1
        salva_gerados(g)
        print("%d arquivos registrados em gerados.json (já existiam; marcados como aprovados)" % novos)
        return 0
    if a.reprocessa:
        mudou = 0
        for s in slots:
            for n in nomes(s):
                p = caminho_final(n)
                if not os.path.exists(p):
                    continue
                ch, taxa, x = pos.le_wav(p)
                x2, notas = pos.processa(x, ch, taxa, s, corta=False)
                if notas:
                    mudou += 1
                    print("  %-34s %s" % (n, "; ".join(notas)))
                    pos.escreve_wav(p, ch, taxa, x2)
        print("%d arquivos reprocessados (ffmpeg %s)" % (mudou, "disponível (OGG possível)" if pos.tem_ffmpeg() else "NÃO instalado: fica em WAV, sem conversão pra OGG"))
        return 0

    if a.aprovar:
        nome, n = a.aprovar[0], int(a.aprovar[1])
        orig = os.path.join(nome_pasta_candidatos(nome), "%d.wav" % n)
        if not os.path.exists(orig):
            print("Não achei a candidata %d de %s (%s)" % (n, nome, orig))
            return 1
        dono = next((s for s in slots if nome in nomes(s)), None)
        if dono is None:
            print("Nome desconhecido: %s" % nome)
            return 1
        os.makedirs(os.path.dirname(caminho_final(nome)), exist_ok=True)
        shutil.copyfile(orig, caminho_final(nome))
        g["arquivos"][nome] = {"hash": hash_de(dono), "gerado_em": time.strftime("%Y-%m-%d"), "aprovado": True}
        salva_gerados(g)
        print("Aprovada: %s <- candidata %d. Rode o import da Godot." % (nome, n))
        return 0

    if a.saldo:
        saldo(chave())
        return 0

    esc = escolhe(slots, a.so, a.tudo)
    if not esc:
        print("Nada escolhido (use --so <id|pasta>, --tudo, --lista, --desatualizados...).")
        return 1
    # o que precisa de chamada à API (cache de chamadas: o que já foi pedido não gasta de novo)
    plano = []  # (slot, nome, take)
    n_take = max(a.candidatos, 1)
    for s in esc:
        for nome in nomes(s):
            e = estado_de(s, nome, g)
            if a.candidatos:
                takes = range(n_take)
            elif e == "falta" or a.force or (a.atualiza and e == "desatualizado"):
                takes = [0]
            else:
                continue  # já existe com o prompt atual (ok), sem registro (use --registra-existentes) ou desatualizado (use --atualiza)
            for t in takes:
                plano.append((s, nome, t))
    pedidos = [(s, n, t) for s, n, t in plano if a.force or bruto_do_cache(s, n, t) is None]
    segundos = sum(duracao_de(s) for s, n, t in pedidos)
    credito = segundos * CREDITOS_POR_S
    print("%d arquivo(s) no plano, %d chamada(s) à API (%d já em cache), %.0f s, custo estimado ~%.0f créditos" % (
        len(plano), len(pedidos), len(plano) - len(pedidos), segundos, credito))
    if a.dry_run:
        for s, n, t in plano:
            print("  [dry-run] %-34s take %d  %.1f s %s%s" % (n, t, duracao_de(s), "loop" if eh_loop(s) else "tiro", "  (cache)" if bruto_do_cache(s, n, t) else ""))
        return 0
    if len(pedidos) > a.max_geracoes:
        print("RECUSADO: %d chamadas passam do teto de %d por execução (--max-geracoes)." % (len(pedidos), a.max_geracoes))
        return 1
    if credito > a.confirma_acima and not a.sim:
        resp = None
        try:
            if sys.stdin.isatty():
                resp = input("Gastar ~%.0f créditos? (s/N) " % credito).strip().lower()
        except EOFError:
            resp = None
        if resp is None:
            print("PRECISA DE CONFIRMAÇÃO: ~%.0f créditos passam de %.0f (--confirma-acima). Rode de novo com --sim." % (credito, a.confirma_acima))
            return 1
        if resp not in ("s", "sim", "y"):
            print("Cancelado.")
            return 1
    k = chave()
    if pedidos:
        saldo(k)
    ok = erros = 0
    for s, nome, t in plano:
        pcm, do_cache = chama_api(k, s, nome, t, a.force)
        if pcm is None:
            erros += 1
            continue
        if a.candidatos:
            ch, (x, notas) = processa_pcm(pcm, s)
            pos.escreve_wav(os.path.join(nome_pasta_candidatos(nome), "%d.wav" % t), ch, taxa_de(s), x)
            print("  cand %s #%d  %.1f s%s%s" % (nome, t, len(x) // ch / float(taxa_de(s)), ("  [" + "; ".join(notas) + "]") if notas else "", "  (cache)" if do_cache else ""))
        else:
            seg, notas = grava_final(nome, s, pcm, g)
            print("  ok   %-34s %.1f s%s%s" % (nome, seg, ("  [" + "; ".join(notas) + "]") if notas else "", "  (cache)" if do_cache else ""))
        ok += 1
        if not do_cache:
            time.sleep(0.4)
    salva_gerados(g)
    if pedidos:
        saldo(k)
    print("%d feitos, %d com erro" % (ok, erros))
    if a.candidatos:
        print("Candidatas em audio_candidatos/<nome>/<n>.wav (fora do git). Escolha: python tools/elevenlabs/gerar_sons.py --aprovar <nome> <n>")
    return 0 if erros == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
