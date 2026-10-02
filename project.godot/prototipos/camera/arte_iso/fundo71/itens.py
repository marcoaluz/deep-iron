"""Itens de arte novos do documento de melhorias (fim do Bloco 71): decoração, não gameplay.

  python itens.py gera     -> candidatos (create_image_pro): igreja, torre do relógio, casas enxaimel (a vila
                              antiga do leste), passarela de madeira, ponte de corda, peças da rampa em espiral
  python itens.py escolhe igreja=c01 torre=c02 enxaimel=c03,c07 passarela=c04 ponte=c02 rampa=c01,c05,c09
"""
import sys, os, base64, io
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import gen
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
ISO = os.path.join(AQUI, "..", "..", "..", "..", "assets", "game", "iso")
CASA = os.path.join(ISO, "predios", "casa", "pronto_0.png")
VELHO = ("abandoned and weathered since the solar explosion: soot-stained, cracked, some boards missing, "
         "moss and dust, no people, no light inside. ")
PEDIDOS = {
    "igreja": (168, 168, "Isometric 2:1 view (same angle and scale as the reference house): a small old VILLAGE "
               "CHURCH of dark stone and timber with a pointed slate roof and a short bell tower at the front, "
               "arched door and narrow windows, " + VELHO + "Only the building, transparent background. ",
               "a dull bronze bell"),
    "torre": (100, 168, "Isometric 2:1 view (same angle and scale as the reference house): a tall narrow old CLOCK "
              "TOWER of dark stone with a timber top, a round clock face that stopped, a small pointed roof, "
              + VELHO + "Only the tower, transparent background. ", "a pale cracked clock face"),
    "enxaimel": (84, 84, "Isometric 2:1 view (same angle and scale as the reference house): a small HALF-TIMBERED "
                 "house (dark timber frame with plaster panels between the beams, steep roof), " + VELHO +
                 "Only the house, transparent background. ", "faded ochre plaster"),
    "passarela": (84, 84, "Isometric 2:1 view: a short WOODEN WALKWAY / pier of planks on wooden posts, lying low "
                  "over wet ground, a few loose boards, a simple rope handrail on one side. Only the walkway, "
                  "transparent background. ", "wet dark planks"),
    "ponte": (84, 84, "Isometric 2:1 view: a short ROPE BRIDGE of wooden planks hanging between two thick wooden "
              "posts, sagging in the middle, frayed ropes. Only the bridge, transparent background. ",
              "frayed hemp rope"),
    "rampa": (84, 84, "Isometric 2:1 view: modular pieces of a SPIRAL MINE RAMP made of wooden planks on a "
              "timber scaffold with iron brackets: a straight inclined ramp segment, a curved ramp segment, or a "
              "square landing with a short ladder; each candidate one piece. Only the piece, transparent "
              "background. ", "rusty iron brackets"),
}


def _data_url(path):
    b = io.BytesIO()
    Image.open(path).convert("RGBA").save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def gera():
    estilo = _data_url(CASA)
    itens = []
    for nome, (w, h, desc, acento) in PEDIDOS.items():
        args = {"description": desc + gen.ESTILO % acento, "width": w, "height": h, "no_background": True,
                "style_image_url": estilo, "style_copy": ["color_palette", "outline", "shading"]}
        itens.append((nome, "create_image_pro", args, os.path.join(AQUI, "itens", nome + ".png")))
    os.makedirs(os.path.join(AQUI, "itens"), exist_ok=True)
    gen.lote(itens, registro=os.path.join(AQUI, "itens_jobs.json"), espera=15)


def escolhe(args):
    for a in args:
        nome, cs = a.split("=")
        for k, c in enumerate(cs.split(",")):
            im = Image.open(os.path.join(AQUI, "itens", nome, c + ".png")).convert("RGBA")
            im = im.crop(im.getbbox())
            dst = os.path.join(AQUI, "%s_%d.png" % (nome, k))
            im.save(dst)
            print(dst, im.size)


if __name__ == "__main__":
    gera() if sys.argv[1] == "gera" else escolhe(sys.argv[2:])
