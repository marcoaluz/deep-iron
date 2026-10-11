#!/usr/bin/env python
"""Blocos 117 e 120: gera a MÚSICA do jogo pela API de música do ElevenLabs (Eleven Music) e confere se as camadas ficaram sincronizadas.

Faixas: as 4 músicas do Bloco 117 (abertura, intro, jogo, perigo, em project.godot/data/audio/slots.json) e a música em camadas do Bloco 120
(project.godot/data/audio/musica.json: tema do menu, vitória, derrota e, por estação, dia/noite/perigo, todas no MESMO BPM e no MESMO tom).

API (documentação oficial, https://elevenlabs.io/docs/api-reference/music/compose, conferida em 2026-10-11): POST https://api.elevenlabs.io/v1/music, header
xi-api-key; corpo: prompt, music_length_ms (3000 a 600000), model_id (music_v1 padrão; music_v2 e music_v2_5 existem), force_instrumental; query
output_format. Usamos só isso. (Seed não vale com prompt; composition_plan não é usado.) Pedimos pcm_44100: estéreo de verdade, 16 bits.

    python tools/elevenlabs/gerar_musica.py --lista
    python tools/elevenlabs/gerar_musica.py --confere                       # BPM, tom, compassos e "sem vocais" nos prompts
    python tools/elevenlabs/gerar_musica.py --so estacao:primavera --dry-run
    python tools/elevenlabs/gerar_musica.py --so estacao:primavera --sim   # as 3 camadas da primavera
    python tools/elevenlabs/gerar_musica.py --sincronia primavera          # mede se as camadas ficaram sincronizadas
    python tools/elevenlabs/gerar_musica.py --so musica/jogo --candidatos 3 --sim
    python tools/elevenlabs/gerar_musica.py --aprovar musica/jogo 2

--so aceita: o id (musica/jogo), só o nome (jogo), estacao:<nome> (primavera, verao, outono, inverno) ou temas (menu, vitória, derrota). Sem --so/--tudo não gera nada.
Limites: --max-geracoes (chamadas por execução, padrão 8), --max-creditos (padrão 10000: acima disso recusa) e --confirma-acima (padrão 1500: acima
disso pede confirmação, ou --sim). Custo estimado: %.1f créditos por segundo de música (medido no Bloco 117; o contador do plano atrasa).

Pós-processamento (numpy, sem ffmpeg): normaliza o volume para RMS -18 dBFS sem passar de pico -1,5 dBFS; nas músicas de LOOP faz um crossfade de 3 s entre o fim e
o começo; as que não repetem ganham um fade-out. Todas as faixas de uma estação saem com o mesmo tamanho, então continuam alinhadas. Sai em WAV
(project.godot/assets/audio/musica/<nome>.wav). A chave vem do .env (nunca é impressa). Cache das chamadas em audio_candidatos/_cache_musica/.
"""
import argparse
import hashlib
import json
import os
import re
import sys
import time
import urllib.error

try:
    import numpy as np
except ImportError:  # --lista, --confere e --dry-run funcionam sem; gerar/aprovar/sincronia precisam (pip install numpy)
    np = None

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gerar_sons as gs  # noqa: E402  (chave, mascara, pede, saldo)

SLOTS = gs.SLOTS
MANIFESTO = os.path.join(gs.RAIZ, "project.godot", "data", "audio", "musica.json")
GERADOS = os.path.join(gs.RAIZ, "project.godot", "data", "audio", "musicas.json")
PASTA = os.path.join(gs.RAIZ, "project.godot", "assets", "audio")
CANDIDATOS = os.path.join(gs.RAIZ, "audio_candidatos", "musica")
CACHE = os.path.join(gs.RAIZ, "audio_candidatos", "_cache_musica")
RELATORIO = os.path.join(gs.RAIZ, "docs", "audio", "SINCRONIA_MUSICA.md")
TAXA = 44100
MODELO = "music_v1"
RMS_ALVO = -18.0  # dBFS: um pouco abaixo da música antiga (-16): sobra espaço pro ducking e pro slider de música
PICO_MAX = -1.5  # dBFS
XFADE_S = 3.0  # crossfade do loop (música precisa de mais que o efeito: 3 s)
FADE_FIM_S = 2.5  # o que não repete termina com fade-out
CREDITOS_POR_S = 13.7  # medido no Bloco 117 (4.600 créditos por 335 s)
__doc__ = __doc__ % CREDITOS_POR_S


# ------------------------------------------------------------ faixas
def faixas():
    """Todas as faixas pedidas: as do slots.json (Bloco 117) e as do musica.json (Bloco 120)."""
    out = [s for s in json.load(open(SLOTS, encoding="utf-8"))["slots"] if s["id"].startswith("musica/") and s.get("prompt")]
    if os.path.exists(MANIFESTO):
        out += json.load(open(MANIFESTO, encoding="utf-8"))["faixas"]
    return out


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


def escolhe(args, todas):
    """--tudo, ou --so: id, nome, estacao:<nome> ou o nome de um tema."""
    if args.tudo:
        return todas
    alvo = []
    for t in args.so or []:
        if t.startswith("estacao:"):
            alvo += [s for s in todas if s.get("estacao") == t.split(":", 1)[1]]
        else:
            alvo += [s for s in todas if s["id"] == t or s["id"].split("/", 1)[1] == t or s["id"].split("/", 1)[1] == "tema_" + t]
    vistos, out = set(), []
    for s in alvo:
        if s["id"] not in vistos:
            vistos.add(s["id"])
            out.append(s)
    return out


# ------------------------------------------------------------ confere o manifesto
def confere(todas):
    """Os prompts das camadas têm o mesmo BPM e o mesmo tom? Os compassos fecham com a duração? Tudo instrumental? Ids únicos?"""
    erros = []
    ids = [s["id"] for s in todas]
    if len(ids) != len(set(ids)):
        erros.append("ids repetidos")
    for s in todas:
        p = s["prompt"]
        if "no vocals" not in p.lower():
            erros.append("%s: o prompt não diz 'no vocals'" % s["id"])
        if not (3 <= int(s["seg"]) <= 600):
            erros.append("%s: duração fora de 3 a 600 s" % s["id"])
        if "bpm" in s:
            if not re.search(r"\b%d BPM" % int(s["bpm"]), p):
                erros.append("%s: o prompt não traz '%d BPM'" % (s["id"], s["bpm"]))
            if s["tom"] not in p:
                erros.append("%s: o prompt não traz o tom '%s'" % (s["id"], s["tom"]))
            esperado = int(s["bpm"]) * int(s["seg"]) / 60.0 / 4.0
            if abs(esperado - int(s.get("compassos", 0))) > 0.01:
                erros.append("%s: %d compassos não fecham com %d s a %d BPM (%.1f)" % (s["id"], s.get("compassos", 0), s["seg"], s["bpm"], esperado))
    camadas = [s for s in todas if s.get("tipo") == "camada"]
    for chave in ("bpm", "tom", "seg"):
        valores = {s[chave] for s in camadas}
        if len(valores) > 1:
            erros.append("as camadas não têm o mesmo %s: %s" % (chave, sorted(valores)))
    return erros


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
    """PCM bruto -> (frames, 2) int16 pronto: emenda (ou fade-out) e normaliza (RMS alvo, pico máximo)."""
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


def le_wav(caminho):
    import wave
    with wave.open(caminho) as w:
        ch, taxa, n = w.getnchannels(), w.getframerate(), w.getnframes()
        x = np.frombuffer(w.readframes(n), dtype="<i2").reshape(-1, ch).astype(np.float64)
    return x, taxa


def relatorio(x):
    f = x.astype(np.float64)
    return "%.1f s, RMS %.1f dBFS, pico %.1f dBFS" % (len(x) / TAXA, db(np.sqrt(np.mean(f * f))), db(np.max(np.abs(f))))


def razao_estalo(x):
    """Salto no ponto do loop / diferença típica entre amostras vizinhas (canal esquerdo)."""
    c = x[:, 0].astype(np.float64)
    tip = np.mean(np.abs(np.diff(c[:200000])))
    return abs(c[0] - c[-1]) / max(tip, 1.0)


# ------------------------------------------------------------ sincronia das camadas
HOP = 512
NFFT = 2048


def envelope(x, taxa):
    """Força de ataque (spectral flux) por quadro de HOP amostras, do canal médio. Devolve (envelope, segundos por quadro)."""
    m = x.mean(axis=1)
    n = (len(m) - NFFT) // HOP
    quadros = np.lib.stride_tricks.sliding_window_view(m, NFFT)[::HOP][:n]
    mag = np.abs(np.fft.rfft(quadros * np.hanning(NFFT), axis=1))
    lm = np.log1p(mag / 200.0)
    fluxo = np.maximum(0.0, np.diff(lm, axis=0)).sum(axis=1)
    fluxo -= np.convolve(fluxo, np.ones(43) / 43.0, mode="same")  # tira a tendência (~0,5 s)
    return fluxo, HOP / float(taxa)


def tempo_de(env, dt, faixa=(55.0, 130.0)):
    """BPM pelo pico da autocorrelação do envelope (refinado por parábola)."""
    e = env - env.mean()
    ac = np.fft.irfft(np.abs(np.fft.rfft(e, 2 * len(e))) ** 2)[: len(e)]
    ac /= max(ac[0], 1e-9)
    lo, hi = int(60.0 / faixa[1] / dt), int(60.0 / faixa[0] / dt)
    i = lo + int(np.argmax(ac[lo:hi]))
    y0, y1, y2 = ac[i - 1], ac[i], ac[i + 1]
    den = y0 - 2 * y1 + y2  # (negativa num pico)
    d = 0.5 * (y0 - y2) / den if abs(den) > 1e-9 else 0.0
    d = max(-1.0, min(1.0, d))
    return 60.0 / ((i + d) * dt), float(ac[i])


def _xcorr(a, b, mx):
    """Correlação normalizada de a e b nos atrasos de -mx a +mx quadros: (atrasos, valores)."""
    n = len(a)
    a = a - a.mean()
    b = b - b.mean()
    corr = np.fft.irfft(np.fft.rfft(a, 2 * n).conj() * np.fft.rfft(b, 2 * n))
    cand = np.concatenate([corr[-mx:], corr[:mx + 1]])
    lags = np.concatenate([np.arange(-mx, 0), np.arange(0, mx + 1)])
    return lags, cand / max(np.sqrt((a * a).sum() * (b * b).sum()), 1e-9)


def atraso(e1, e2, dt, janela_s=30.0, max_s=3.2, fino_s=0.08):
    """Atraso (s) de e2 em relação a e1. Primeiro o atraso GLOBAL (a faixa inteira, até um compasso pra cada lado: não muda com a janela, então
    a repetição da batida não confunde); depois, por janelas de ~30 s, o quanto ele se mexe (busca só até `fino_s` em volta do global: isso é a DERIVA).
    Devolve [(inicio_s, atraso_s, força)]."""
    lags, v = _xcorr(e1, e2, int(max_s / dt))
    glob = int(lags[int(np.argmax(v))])
    n = int(janela_s / dt)
    fino = int(fino_s / dt)
    out = []
    for ini in range(0, min(len(e1), len(e2)) - n + 1, n):
        a = e1[ini: ini + n]
        b = e2[max(0, ini + glob - fino): ini + n + glob + fino]
        if len(b) < n + 2 * fino or ini + glob - fino < 0:
            continue
        # b é a janela deslocada pelo atraso global, com folga fino de cada lado: procura o atraso fino
        a0 = a - a.mean()
        melhor = (-2.0, 0)
        for d in range(-fino, fino + 1):
            seg = b[fino + d: fino + d + n]
            seg0 = seg - seg.mean()
            c = float((a0 * seg0).sum() / max(np.sqrt((a0 * a0).sum() * (seg0 * seg0).sum()), 1e-9))
            if c > melhor[0]:
                melhor = (c, d)
        out.append((ini * dt, (glob + melhor[1]) * dt, melhor[0]))
    return out


NOTAS = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
PERFIL_MAIOR = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88]) if np is not None else None
PERFIL_MENOR = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17]) if np is not None else None


def tom_estimado(x, taxa):
    """Tom pelo cromagrama (perfis de Krumhansl): devolve ('D minor', correlação). Usa o canal médio, de 65 Hz a 2 kHz."""
    m = x.mean(axis=1)
    n = (len(m) - 8192) // 8192
    q = np.lib.stride_tricks.sliding_window_view(m, 8192)[::8192][:n]
    mag = np.abs(np.fft.rfft(q * np.hanning(8192), axis=1)).mean(axis=0)
    f = np.fft.rfftfreq(8192, 1.0 / taxa)
    cro = np.zeros(12)
    for i in range(len(f)):
        if 65.0 <= f[i] <= 2000.0:
            cro[int(round(12 * np.log2(f[i] / 440.0) + 69)) % 12] += mag[i] ** 2
    cro = cro / max(cro.sum(), 1e-9)
    melhor = (-2.0, "?")
    for tonica in range(12):
        for nome, perfil in (("major", PERFIL_MAIOR), ("minor", PERFIL_MENOR)):
            c = float(np.corrcoef(cro, np.roll(perfil, tonica))[0, 1])
            if c > melhor[0]:
                melhor = (c, "%s %s" % (NOTAS[tonica], nome))
    return melhor[1], melhor[0]


LIMITE_DERIVA_MS = 40.0  # camadas que se afastam mais que isso ao longo da faixa soam fora do tempo
FORCA_MIN = 0.08  # janela com ataque de menos que isso (pad) não serve pra medir


def sincronia(estacao):
    """Mede as camadas de uma estação (dia, noite, perigo): tempo de cada uma, atraso entre elas ao longo da faixa e o veredito."""
    todas = [s for s in faixas() if s.get("estacao") == estacao]
    envs = {}
    tons, bpms = {}, {}
    batida = 60.0 / float(todas[0]["bpm"]) if todas else 0.75
    linhas = ["### %s" % estacao, "", "| camada | tempo estimado | força do compasso | tom estimado |", "|---|---|---|---|"]
    for s in todas:
        f = destino(s)
        if not os.path.exists(f):
            print("  falta %s (gere antes)" % s["id"])
            return None
        x, taxa = le_wav(f)
        env, dt = envelope(x, taxa)
        bpm, forca = tempo_de(env, dt)
        envs[s["periodo"]] = (env, dt)
        tom, corr = tom_estimado(x, taxa)
        tons[s["periodo"]] = tom
        bpms[s["periodo"]] = bpm
        linhas.append("| %s | %.2f BPM | %.2f | %s (%.2f) |" % (s["periodo"], bpm, forca, tom, corr))
        print("  %-8s tempo %.2f BPM (alvo %d), força %.2f, tom %s (%.2f), %.1f s" % (s["periodo"], bpm, s["bpm"], forca, tom, corr, len(x) / taxa))
    linhas += ["", "| par | desvio de batidas | fase média | deriva (variação entre janelas) | janelas |", "|---|---|---|---|---|"]
    piores = []
    for a, b in (("dia", "noite"), ("dia", "perigo"), ("noite", "perigo")):
        if a not in envs or b not in envs:
            continue
        res = [r for r in atraso(envs[a][0], envs[b][0], envs[a][1]) if r[2] >= FORCA_MIN]
        if len(res) < 2:
            linhas.append("| %s x %s | — | (sem ataques para medir) | — | %d |" % (a, b, len(res)))
            print("  %s x %s: sem ataques suficientes para medir" % (a, b))
            continue
        lags = np.array([r[1] for r in res])
        batidas = np.round(lags / batida)
        fases = (lags - batidas * batida) * 1000.0  # ms, dentro da batida
        desvio = int(np.bincount((batidas + 8).astype(int)).argmax()) - 8  # a quantidade de batidas mais comum (informativo: o ataque se repete a cada batida)
        deriva = float(fases.max() - fases.min())
        if (a, b) == ("dia", "perigo"):  # o par com ataque dos dois lados: é o que decide (o pad quase não tem ataque; os outros pares só informam)
            piores.append(deriva)
        linhas.append("| %s x %s | %+d batida(s) | %.0f ms | %.0f ms | %d |" % (a, b, desvio, fases.mean(), deriva, len(res)))
        print("  %s x %s: desvio %+d batida(s), fase média %.0f ms, deriva %.0f ms (%d janelas)" % (a, b, desvio, fases.mean(), deriva, len(res)))
    # o pad (noite) não tem ataque: pra ele só contam o tempo e o tom
    dif_tempo = max(bpms.values()) - min(bpms.values()) if bpms else 99.0
    alvo_tom = todas[0]["tom"].split()[0] if todas else "D"
    permitidos = {alvo_tom, NOTAS[(NOTAS.index(alvo_tom) + 7) % 12]}  # a tônica ou a quinta (os drones do pad e da percussão firmam na quinta)
    mesmo_tom = all(t.split()[0] in permitidos for t in tons.values())
    ok = bool(piores) and max(piores) <= LIMITE_DERIVA_MS and dif_tempo <= 0.6 and mesmo_tom
    razoes = []
    if not piores or max(piores) > LIMITE_DERIVA_MS:
        razoes.append("deriva entre os ataques" if piores else "sem como medir os ataques")
    if dif_tempo > 0.6:
        razoes.append("tempos diferentes (%.2f BPM de diferença)" % dif_tempo)
    if not mesmo_tom:
        razoes.append("tons fora do alvo %s (%s)" % (todas[0]["tom"], ", ".join("%s=%s" % kv for kv in tons.items())))
    veredito = ("SINCRONIZADAS o bastante (deriva dos ataques até %.0f ms, tempos a %.2f BPM de diferença, tons compatíveis com %s): dá para tocar juntas (AudioStreamSynchronized)."
                % (max(piores), dif_tempo, todas[0]["tom"])) if ok else         ("NÃO sincronizadas o bastante (%s): trocar faixas inteiras com crossfade (AudioStreamInteractive)." % "; ".join(razoes))
    linhas += ["", "**Veredito:** " + veredito, ""]
    print("  ->", veredito)
    return "\n".join(linhas), ok


# ------------------------------------------------------------ principal
def main():
    ap = argparse.ArgumentParser(description="Gera a música do jogo pela API de música do ElevenLabs.")
    ap.add_argument("--so", nargs="+", help="id (musica/jogo), nome (jogo), estacao:<nome> ou tema (menu, vitoria, derrota)")
    ap.add_argument("--tudo", action="store_true", help="todas as faixas")
    ap.add_argument("--lista", action="store_true")
    ap.add_argument("--confere", action="store_true", help="confere o manifesto (BPM, tom, compassos, instrumental)")
    ap.add_argument("--sincronia", metavar="ESTACAO", help="mede se as camadas dessa estação ficaram sincronizadas")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--candidatos", type=int, default=0, help="N versões em audio_candidatos/musica/ (não troca o arquivo do jogo)")
    ap.add_argument("--aprovar", nargs=2, metavar=("ID", "N"), help="copia a candidata N pro jogo")
    ap.add_argument("--force", action="store_true", help="ignora o cache (gasta crédito: sorteia outra versão)")
    ap.add_argument("--max-geracoes", type=int, default=8, help="teto de chamadas por execução")
    ap.add_argument("--max-creditos", type=float, default=10000.0, help="recusa se o custo estimado passar disso")
    ap.add_argument("--confirma-acima", type=float, default=1500.0, help="acima deste custo estimado pede confirmação (ou --sim)")
    ap.add_argument("--sim", action="store_true", help="confirma sem perguntar")
    args = ap.parse_args()
    todas = faixas()
    reg = registro()

    if args.confere:
        erros = confere(todas)
        print("%d faixas conferidas." % len(todas))
        for e in erros:
            print("  ERRO:", e)
        print("tudo certo." if not erros else "%d erro(s)." % len(erros))
        return 1 if erros else 0

    if args.lista:
        for s in todas:
            ok = os.path.exists(destino(s))
            est = ""
            if ok:
                h = reg["arquivos"].get(s["id"], {}).get("hash")
                est = "  [desatualizado: o prompt mudou]" if h and h != hash_de(s) else ""
            print("%-22s %3d s  %-5s %s%s" % (s["id"], s["seg"], "loop" if s.get("loop") else "uma vez", "TEM arquivo" if ok else "falta", est))
        return 0

    if np is None and not args.dry_run:
        sys.exit("Falta o numpy para processar o áudio: pip install numpy")

    if args.sincronia:
        r = sincronia(args.sincronia)
        if r is None:
            return 1
        texto, ok = r
        os.makedirs(os.path.dirname(RELATORIO), exist_ok=True)
        antigo = open(RELATORIO, encoding="utf-8").read() if os.path.exists(RELATORIO) else "# Sincronia das camadas de música (Bloco 120)\n\n" \
            "Medido por `python tools/elevenlabs/gerar_musica.py --sincronia <estacao>`: tempo de cada camada (autocorrelação do envelope de ataques) e atraso entre elas ao longo da faixa.\n\n"
        partes = re.split(r"(?m)^### ", antigo)
        mantem = [p for p in partes[1:] if not p.startswith(args.sincronia + "\n")]
        open(RELATORIO, "w", encoding="utf-8").write(partes[0] + "".join("### " + p for p in mantem) + texto + "\n")
        print("-> docs/audio/SINCRONIA_MUSICA.md")
        return 0 if ok else 2

    if args.aprovar:
        s = next((x for x in todas if x["id"] == args.aprovar[0] or x["id"].split("/", 1)[1] == args.aprovar[0]), None)
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

    alvo = escolhe(args, todas)
    if not alvo:
        print("Nada escolhido: use --tudo ou --so musica/jogo | estacao:primavera | menu (--lista mostra o que existe).")
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
    custo = seg * CREDITOS_POR_S
    print("%d arquivo(s) no plano, %d chamada(s) à API (%d s de música; o resto vem do cache), custo estimado ~%d créditos." % (len(plano), len(chamadas), seg, round(custo)))
    if args.dry_run:
        for s, n in plano:
            print("  %s #%d  %d s  %s" % (s["id"], n, s["seg"], "(cache)" if (s, n) not in chamadas else "(API)"))
        return 0
    if len(chamadas) > args.max_geracoes:
        print("RECUSADO: %d chamadas passam do teto de %d (--max-geracoes)." % (len(chamadas), args.max_geracoes))
        return 1
    if custo > args.max_creditos:
        print("RECUSADO: custo estimado ~%d créditos passa do teto de %d (--max-creditos)." % (round(custo), round(args.max_creditos)))
        return 1
    if chamadas and custo > args.confirma_acima and not args.sim:
        if sys.stdin.isatty():
            if input("Gerar %d chamada(s), ~%d créditos? [s/N] " % (len(chamadas), round(custo))).strip().lower() not in ("s", "sim", "y"):
                return 1
        else:
            print("Custo acima de %d créditos sem terminal: confirme com --sim." % round(args.confirma_acima))
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
