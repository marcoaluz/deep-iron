#!/usr/bin/env python
"""Bloco 115: NORMALIZA o volume dos sons gerados (o ElevenLabs entrega cada arquivo num nível: de -60 a 0 dBFS de pico).

Os dB do data/audio/slots.json foram pensados pros sons antigos (loops com RMS perto de -18 dBFS e picos perto de -2; sons curtos com pico entre -1 e -6).
Esta passagem leva os arquivos novos pra esse mesmo nível e SÓ SOBE o que está baixo (nunca abaixa o que já está alto): o mix fica no slots.json.

    python tools/normaliza_audio.py --dry-run     # mostra os ganhos, não grava nada
    python tools/normaliza_audio.py               # grava os arquivos (WAV de 16 bits) com o ganho

  Loops (ambiencia/, predios/): RMS alvo -20 dBFS, pico no máximo -2 dBFS.
  Os outros (curtos, voz, passos, stingers...): pico alvo -3 dBFS.
  Ganho máximo +36 dB (acima disso o arquivo é quase silêncio: regerar com --force em gera_audio_elevenlabs.py).
Só biblioteca padrão. Rodar o import da Godot depois.
"""
import argparse
import json
import math
import os
import struct
import sys
import wave

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SLOTS = os.path.join(RAIZ, "project.godot", "data", "audio", "slots.json")
PASTA = os.path.join(RAIZ, "project.godot", "assets", "audio")
RMS_LOOP = -20.0
PICO_LOOP = -2.0
PICO_CURTO = -3.0
GANHO_MAX = 36.0
## Ganho abaixo disso não vale regravar.
GANHO_MIN = 0.5


def nomes(s):
    n = int(s.get("variacoes", 0))
    return [s["id"]] if n <= 0 else ["%s_%d" % (s["id"], i) for i in range(n)]


def db(v):
    return 20.0 * math.log10(max(v, 1.0) / 32768.0)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    slots = json.load(open(SLOTS, encoding="utf-8"))["slots"]
    mudou = 0
    longe = []
    for s in slots:
        if s["id"].startswith("musica/"):
            continue
        loop = s["tipo"] in ("loop", "loop_predio")
        for nome in nomes(s):
            p = os.path.join(PASTA, *(nome + ".wav").split("/"))
            if not os.path.exists(p):
                continue
            w = wave.open(p)
            ch, taxa, k = w.getnchannels(), w.getframerate(), w.getnframes()
            x = struct.unpack("<%dh" % (k * ch), w.readframes(k))
            w.close()
            rms = db(math.sqrt(sum(v * v for v in x) / len(x)))
            pico = db(max(abs(v) for v in x))
            ganho = min(RMS_LOOP - rms, PICO_LOOP - pico) if loop else (PICO_CURTO - pico)
            if ganho < GANHO_MIN:
                continue
            capado = ganho > GANHO_MAX
            ganho = min(ganho, GANHO_MAX)
            if capado:
                longe.append(nome)
            mudou += 1
            print("  %+5.1f dB  %-32s (rms %6.1f, pico %6.1f)%s" % (ganho, nome, rms, pico, "  <- limitado a +%d dB: quase silêncio, regerar" % GANHO_MAX if capado else ""))
            if a.dry_run:
                continue
            f = 10.0 ** (ganho / 20.0)
            y = struct.pack("<%dh" % len(x), *[max(-32768, min(32767, int(round(v * f)))) for v in x])
            with wave.open(p, "wb") as o:
                o.setnchannels(ch)
                o.setsampwidth(2)
                o.setframerate(taxa)
                o.writeframes(y)
    print("%d arquivos %s" % (mudou, "mudariam" if a.dry_run else "normalizados"))
    if longe:
        print("Quase silenciosos (regerar): %s" % ", ".join(longe))
    return 0


if __name__ == "__main__":
    sys.exit(main())
