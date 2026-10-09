"""Bloco 104: o MAPA DA REGIÃO da janela das Expedições (PixelLab, create_image_pro), no estilo do mapa do mundo (o corte
da mina, assets/game/ui/corte/mapa_mundo.png).

  python mapa104.py gera            -> candidatos em _cand/mapa_regiao.png (+ a pasta com cNN.png)
  python mapa104.py escolhe cNN     -> assets/game/ui/expedicoes/mapa_regiao.png

O mapa mostra a SUPERFÍCIE em volta da vila: a vila e a pedreira no meio (com a boca da mina e a torre do elevador), a
floresta queimada funda a oeste, a estrada velha de asfalto rachado ao sul e as ruínas da cidade de antes a leste. As
regiões da mina ficam numa coluna à parte (as faixas do corte). O "?" e a equipe em viagem são desenhados por código.
"""
import sys, os, base64, io, shutil
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import gen
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.join(AQUI, "..", "..", "..", "..", "assets", "game")
CAND = os.path.join(AQUI, "_cand")
QUADRO = (384, 256)
DESC = ("Pixel art top-down regional MAP of a post-apocalyptic mining colony surroundings, drawn like an old explorer's map "
        "painted on stained parchment, seen from above with a slight isometric tilt, in the same art style, palette and "
        "pixel density as the reference. CENTER: a small mining village in a stone QUARRY with a few wooden houses, a mine "
        "entrance in the rock and a tall wooden elevator headframe tower. WEST (left third): a dense dark BURNED FOREST of "
        "black dead pine trees with a few green survivors and a winding animal trail. SOUTH (bottom): a long cracked "
        "asphalt ROAD covered in grey ash with rusted car wrecks, going off the bottom edge. EAST (right third): the RUINS "
        "of an old town: collapsed concrete buildings, a toppled radio tower and an old church. A wooden palisade wall with "
        "a gate between the forest and the village. Dark ash-grey sky edges, torn parchment border, small compass rose in a "
        "corner. No text, no labels, no letters, no people. ")


def _data_url(im):
    b = io.BytesIO()
    im.save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def gera():
    os.makedirs(CAND, exist_ok=True)
    ref = Image.open(os.path.join(GAME, "ui", "corte", "mapa_mundo.png")).convert("RGBA")
    topo = ref.crop((0, 0, ref.width, 160))
    args = {"description": DESC + gen.ESTILO % "a warm muted parchment",
            "width": QUADRO[0], "height": QUADRO[1], "no_background": False,
            "reference_images": [{"url": _data_url(topo), "usage": "the approved world map of the same game: the art "
                                  "style, palette, outline and the look of the village, quarry and elevator tower"}],
            "style_image_url": _data_url(topo), "style_copy": ["color_palette", "outline", "shading", "detail"]}
    gen.lote([("mapa_regiao", "create_image_pro", args, os.path.join(CAND, "mapa_regiao.png"))],
             registro=os.path.join(AQUI, "mapa104_jobs.json"), espera=20)


def escolhe(c):
    f = os.path.join(CAND, "mapa_regiao", c + ".png")
    im = Image.open(f).convert("RGBA")
    if im.size != QUADRO:
        im = im.resize(QUADRO, Image.NEAREST)
    dest = os.path.join(GAME, "ui", "expedicoes")
    os.makedirs(dest, exist_ok=True)
    im.save(os.path.join(dest, "mapa_regiao.png"))
    print("ok", im.size)


def cartao():
    """o cartão do CONSTRUIR ("Posto de expedição"): um recorte do mapa (a vila e a saída pra floresta), 96x64."""
    im = Image.open(os.path.join(GAME, "ui", "expedicoes", "mapa_regiao.png")).convert("RGBA")
    rec = im.crop((96, 40, 288, 168)).resize((96, 64), Image.LANCZOS)
    rec.save(os.path.join(GAME, "ui", "icones", "cartoes", "posto_expedicao.png"))
    print("ok cartao")


if __name__ == "__main__":
    if sys.argv[1] == "gera":
        gera()
    elif sys.argv[1] == "cartao":
        cartao()
    else:
        escolhe(sys.argv[2])
