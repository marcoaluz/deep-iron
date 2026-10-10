"""Bloco 116: pós-processamento dos sons gerados (só biblioteca padrão; o ffmpeg é opcional).

  corta_silencio   tira o silêncio do começo e do fim dos sons curtos (nunca dos loops)
  normaliza        leva o volume ao nível dos sons antigos do jogo e SÓ SOBE o que está baixo (nunca abaixa)
  emenda_loop      suaviza o ponto onde o loop recomeça (crossfade de potência igual), se houver estalo
  converte_ogg     WAV -> OGG pelo ffmpeg (se não houver ffmpeg, avisa e deixa o WAV)

Os alvos vêm dos sons antigos do Bloco 55 (medidos): loops com RMS perto de -18 dBFS e pico perto de -2; curtos com pico entre -1 e -6;
interface com pico perto de -5.
"""
import math
import os
import shutil
import struct
import subprocess
import wave

# ---- alvos por categoria (dBFS)
RMS_LOOP = -20.0
PICO_LOOP = -2.0
PICO_CURTO = -3.0
PICO_UI = -5.0
## Ganho máximo (acima disso o arquivo é quase silêncio: regerar).
GANHO_MAX = 36.0
## Ganho abaixo disso não vale regravar.
GANHO_MIN = 0.5
## Silêncio (dBFS) e a margem que fica em volta do som ao cortar.
LIMIAR_SILENCIO = -55.0
MARGEM_MS = 15.0
## O salto no ponto do loop, em múltiplos da diferença típica entre amostras vizinhas, a partir do qual há estalo.
LIMITE_ESTALO = 6.0
## Duração (ms) do crossfade que suaviza a emenda do loop.
XFADE_MS = 400.0


def le_wav(caminho):
    w = wave.open(caminho)
    ch, taxa, k = w.getnchannels(), w.getframerate(), w.getnframes()
    x = list(struct.unpack("<%dh" % (k * ch), w.readframes(k)))
    w.close()
    return ch, taxa, x


def escreve_wav(caminho, ch, taxa, x):
    os.makedirs(os.path.dirname(caminho), exist_ok=True)
    with wave.open(caminho, "wb") as o:
        o.setnchannels(ch)
        o.setsampwidth(2)
        o.setframerate(taxa)
        o.writeframes(struct.pack("<%dh" % len(x), *x))


def db(v):
    return 20.0 * math.log10(max(v, 1.0) / 32768.0)


def pico_db(x):
    return db(max(abs(v) for v in x))


def rms_db(x):
    return db(math.sqrt(sum(v * v for v in x) / len(x)))


def categoria_de(slot):
    """loop | ui | curto"""
    if slot.get("tipo") in ("loop", "loop_predio"):
        return "loop"
    if slot.get("bus") == "UI":
        return "ui"
    return "curto"


def corta_silencio(x, ch, taxa):
    """Tira o silêncio do começo e do fim (deixa uma margem). Devolve x (igual se não houver o que cortar)."""
    limiar = 32768.0 * 10.0 ** (LIMIAR_SILENCIO / 20.0)
    frames = len(x) // ch
    ini, fim = 0, frames - 1
    while ini < frames and max(abs(x[ini * ch + c]) for c in range(ch)) < limiar:
        ini += 1
    while fim > ini and max(abs(x[fim * ch + c]) for c in range(ch)) < limiar:
        fim -= 1
    if ini >= frames:
        return x  # tudo silêncio: não mexe (o teste de "quase silêncio" avisa)
    m = int(MARGEM_MS / 1000.0 * taxa)
    ini, fim = max(0, ini - m), min(frames - 1, fim + m)
    return x[ini * ch: (fim + 1) * ch]


def ganho_para(x, categoria):
    """Ganho (dB) pra levar o arquivo ao nível alvo; 0 se já está alto (só sobe)."""
    pico = pico_db(x)
    if categoria == "loop":
        g = min(RMS_LOOP - rms_db(x), PICO_LOOP - pico)
    elif categoria == "ui":
        g = PICO_UI - pico
    else:
        g = PICO_CURTO - pico
    return g if g >= GANHO_MIN else 0.0


def aplica_ganho(x, g):
    f = 10.0 ** (g / 20.0)
    return [max(-32768, min(32767, int(round(v * f)))) for v in x]


def razao_estalo(x, ch):
    """Salto no ponto do loop / diferença típica entre amostras vizinhas (primeiro canal). > LIMITE_ESTALO = estalo provável."""
    c = x[0::ch]
    salto = abs(c[0] - c[-1])
    n = min(len(c) - 1, 40000)
    tipica = sum(abs(c[i + 1] - c[i]) for i in range(n)) / max(n, 1)
    return salto / max(tipica, 1.0)


def emenda_loop(x, ch, taxa):
    """Crossfade de potência igual entre o fim e o começo: o fim continua direto no começo. O arquivo encurta XFADE_MS."""
    frames = len(x) // ch
    n = int(XFADE_MS / 1000.0 * taxa)
    n = min(n, frames // 3)
    if n < 16:
        return x
    saida = list(x[: (frames - n) * ch])
    for i in range(n):
        t = (i + 0.5) / n
        a = math.sin(t * math.pi / 2.0)  # entra (o começo)
        b = math.cos(t * math.pi / 2.0)  # sai (o fim)
        for c in range(ch):
            v = x[i * ch + c] * a + x[(frames - n + i) * ch + c] * b
            saida[i * ch + c] = max(-32768, min(32767, int(round(v))))
    return saida


def processa(x, ch, taxa, slot, corta=True):
    """O pipeline completo de um som novo: corta o silêncio (curtos), normaliza (só sobe) e emenda o loop (se tem estalo).
    Devolve (x, notas)."""
    notas = []
    cat = categoria_de(slot)
    if cat != "loop" and corta:
        antes = len(x)
        x = corta_silencio(x, ch, taxa)
        if len(x) < antes:
            notas.append("cortou %.2f s de silêncio" % ((antes - len(x)) / ch / taxa))
    if cat == "loop" and razao_estalo(x, ch) > LIMITE_ESTALO:
        x = emenda_loop(x, ch, taxa)
        notas.append("emendou o loop (crossfade %d ms)" % XFADE_MS)
    g = ganho_para(x, cat)
    if g > 0.0:
        capado = g > GANHO_MAX
        g = min(g, GANHO_MAX)
        x = aplica_ganho(x, g)
        notas.append("+%.1f dB%s" % (g, " (limitado: quase silêncio, regerar)" if capado else ""))
    return x, notas


def tem_ffmpeg():
    return shutil.which("ffmpeg") is not None


def converte_ogg(wav, ogg, qualidade=4):
    """WAV -> OGG Vorbis pelo ffmpeg. Devolve True se converteu; False se não há ffmpeg (o WAV fica)."""
    if not tem_ffmpeg():
        return False
    r = subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", str(qualidade), ogg])
    return r.returncode == 0
