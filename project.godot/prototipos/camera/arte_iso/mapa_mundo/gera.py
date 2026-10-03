"""Bloco 72 (revisão do Marco): o MAPA DO MUNDO como a referência — a coluna inteira, da floresta ao
lago, com a mina descendo debaixo da vila (escada em espiral e elevador), cada nível embaixo do outro em
forma de caverna. Teste do PixelLab: create_image_pro com a coluna da referência como guia de composição
e a arte aprovada do jogo como estilo.

  python gera.py -> mapa_mundo/<nome>.png (grade de candidatos) e mapa_mundo/<nome>/cNN.png
"""
import sys, os, base64, io
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import gen
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.join(AQUI, "..", "..", "..", "..")
REF = os.path.join(RAIZ, "..", "docs", "arte", "referencia_mapa_mundo.jpg")
CASA = os.path.join(RAIZ, "assets", "game", "iso", "predios", "casa", "pronto_0.png")


def _url(im):
    b = io.BytesIO()
    im.convert("RGBA").save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


COLUNA = ("A tall vertical CUTAWAY of one whole underground mining world, seen in isometric 3/4 view, one "
          "continuous column of earth sliced open at the front, everything stacked DIRECTLY ONE UNDER THE OTHER: "
          "TOP: dark pine forest on a grassy hill, and a small rough quarry village of weathered wooden houses with "
          "a wooden mine headframe, a crane and a broken palisade gate; a dirt path descends into a quarry pit. "
          "BELOW the village: the mine entrance opens into level 1, mine galleries with wooden supports, lanterns "
          "and rails. A WOODEN SPIRAL STAIRCASE winds down a round shaft on the right side through all levels, and "
          "next to it a vertical ELEVATOR shaft with a cage; wooden scaffolding and platforms connect each level to "
          "them. Level 2: a green acid cave with toxic pools, mossy rock and purple crystals. Level 3: a lava cave "
          "with molten rivers, glowing cracks and a drilling machine. Level 4: a waterfall falling onto hot rock "
          "with steam, lava and water together, colourful crystals. Level 5 at the very bottom: a calm underground "
          "blue lake with blue gems and two small stone huts on the shore. Every level is an organic irregular cave "
          "(no square rooms), rock walls between them, the whole column narrowing to a point at the bottom. ")


def gera():
    ref = Image.open(REF).convert("RGB").crop((8, 40, 418, 768))
    estilo = Image.open(CASA)
    refs = '[{"url": "%s", "usage": "overall layout and composition: the vertical stacked column of levels, the spiral staircase on the right, the forest and village on top, the lake at the bottom"}]' % _url(ref)
    itens = []
    for nome, (w, h) in {"coluna": (384, 688), "quadrado": (512, 512)}.items():
        args = {"description": COLUNA + gen.ESTILO % "warm lantern light, orange lava, green acid, blue lake",
                "width": w, "height": h, "no_background": False, "reference_images": refs,
                "style_image_url": _url(estilo), "style_copy": ["color_palette", "outline", "shading"]}
        itens.append((nome, "create_image_pro", args, os.path.join(AQUI, nome + ".png")))
    gen.lote(itens, registro=os.path.join(AQUI, "jobs.json"), espera=20)


if __name__ == "__main__":
    gera()
