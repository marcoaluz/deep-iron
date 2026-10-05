"""Bloco 78: os MARCOS de cada andar (maquete v4, docs/NovoLayout): a arte que faltava.

  python marcos.py gera [nomes]          -> candidatos (create_image_pro) em fundo78/<nome>/cNN.png
  python marcos.py escolhe nome=cNN ...  -> fundo78/<nome>.png (recortada); depois integra.py props <nomes>

  fossil_gigante  S3: o esqueleto gigante deitado na rocha vulcânica, rachaduras de lava
  bica_vapor      S4: a fonte termal (anel de pedra molhada, água quente borbulhando; o vapor é partícula)
  lampiao_cristal S5: poste de pedra com um cristal ciano aceso (a luz da cidade subterrânea)
  cabana_mina     galerias: barraco de mineiro de tábuas encostado na parede, lampião na porta
  boca_tunel      galerias: entrada de túnel com escora de madeira, escuro dentro, lampião
"""
import sys, os, base64, io
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import gen
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
ISO = os.path.join(AQUI, "..", "..", "..", "..", "assets", "game", "iso")
ESTILO_IMG = os.path.join(ISO, "predios", "coletor_minerio", "pronto.png")
PEDIDOS = {
    "fossil_gigante": (192, 112, "Isometric 2:1 view (like the reference building): the FOSSIL SKELETON of a GIANT ancient beast "
                      "lying on its side, half-buried in dark volcanic rock: a long arched spine, big curved ribs, a huge "
                      "horned skull with jaws open, a few leg bones; cream and pale-yellow old bones with dark cracks, "
                      "glowing orange lava cracks in the rock around it. No people. Only the fossil and its rock bed, "
                      "transparent background. ", "faint orange lava glow in the cracks"),
    "bica_vapor": (64, 48, "Isometric 2:1 view (like the reference building): a small HOT SPRING VENT on a cave floor: a low ring "
                  "of wet dark stones with white-orange mineral crust around a small pool of bubbling pale-blue hot water, "
                  "flat on the ground. Only the vent, transparent background. ", "pale-blue hot water"),
    "lampiao_cristal": (32, 80, "Isometric 2:1 view (like the reference building): a tall STONE LAMP POST from an old underground "
                       "town: a carved stone pillar on a square base, on top a glowing CYAN CRYSTAL held in an iron cage. "
                       "Only the lamp post, transparent background. ", "glowing cyan crystal"),
    "cabana_mina": (80, 80, "Isometric 2:1 view (like the reference building): a small MINER'S SHACK in an underground mining "
                   "camp: rough wooden plank walls, a slanted corrugated tin roof, a narrow door, a little oil lantern "
                   "hanging by the door, a crate and a pickaxe leaning on the wall. No people. Only the shack, transparent "
                   "background. ", "warm lantern glow"),
    "boca_tunel": (64, 80, "Isometric 2:1 view (like the reference building): a MINE TUNNEL ENTRANCE cut in a dark rock face: a "
                  "heavy timber frame (two posts and a beam) around a pitch-dark opening, a little oil lantern hanging "
                  "from the beam, some loose rocks at the foot. Only the entrance and a bit of rock around it, "
                  "transparent background. ", "warm lantern glow"),
}


def _data_url(path):
    b = io.BytesIO()
    Image.open(path).convert("RGBA").save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def gera(nomes):
    itens = []
    for nome, (w, h, desc, acento) in PEDIDOS.items():
        if nomes and nome not in nomes:
            continue
        args = {"description": desc + gen.ESTILO % acento, "width": w, "height": h, "no_background": True,
                "style_image_url": _data_url(ESTILO_IMG), "style_copy": ["color_palette", "outline", "shading"]}
        itens.append((nome, "create_image_pro", args, os.path.join(AQUI, nome + ".png")))
    gen.lote(itens, registro=os.path.join(AQUI, "jobs.json"), espera=15)


def escolhe(args):
    for a in args:
        nome, c = a.split("=")
        im = Image.open(os.path.join(AQUI, nome, c + ".png")).convert("RGBA")
        im = im.crop(im.getbbox())
        im.save(os.path.join(AQUI, nome + ".png"))
        print("ok", nome, c, im.size)


if __name__ == "__main__":
    if sys.argv[1] == "gera":
        gera(sys.argv[2:])
    elif sys.argv[1] == "escolhe":
        escolhe(sys.argv[2:])
