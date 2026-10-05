"""Bloco 76: a BOCA DA ESCADA EM ESPIRAL na superfície (a maquete superficie_v3: a casinha de madeira à direita do
armazém, em cima da espiral que desce a coluna).

  python espiral.py gera                -> candidatos (create_image_pro) em fundo76/espiral/cNN.png
  python espiral.py escolhe c03         -> fundo76/boca_espiral.png (recortada; a escolhida foi a c03)
Depois: integra.py props (âncora/pegada) e o environment.gd põe ela no lugar.
"""
import sys, os, base64, io
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import gen
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
ISO = os.path.join(AQUI, "..", "..", "..", "..", "assets", "game", "iso")
ESTILO_IMG = os.path.join(ISO, "predios", "coletor_minerio", "pronto.png")
DESC = ("Isometric 2:1 view (like the reference building): a small WOODEN SHED built over the top of a SPIRAL STAIRCASE "
        "that goes down into a mine: weathered plank walls on three sides, a slanted plank roof, the front wide open "
        "with a dark opening where the first wooden steps curve down into darkness, a small hanging oil lantern, "
        "a little wooden sign. No people. Only the shed, transparent background. ")


def _data_url(path):
    b = io.BytesIO()
    Image.open(path).convert("RGBA").save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def gera():
    args = {"description": DESC + gen.ESTILO % "warm lantern glow at the doorway", "width": 96, "height": 96,
            "no_background": True, "style_image_url": _data_url(ESTILO_IMG),
            "style_copy": ["color_palette", "outline", "shading"]}
    gen.lote([("espiral", "create_image_pro", args, os.path.join(AQUI, "espiral.png"))],
             registro=os.path.join(AQUI, "jobs.json"), espera=15)


def escolhe(c):
    im = Image.open(os.path.join(AQUI, "espiral", c + ".png")).convert("RGBA")
    im = im.crop(im.getbbox())
    im.save(os.path.join(AQUI, "boca_espiral.png"))  # (o integra.py props leva pro jogo)
    print("ok", im.size)


if __name__ == "__main__":
    if sys.argv[1] == "gera":
        gera()
    elif sys.argv[1] == "escolhe":
        escolhe(sys.argv[2])
