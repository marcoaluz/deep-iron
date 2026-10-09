"""Bloco 107: a RUÍNA do vagonete da boca da mina (pedida pelo Marco no Bloco 106): o carrinho velho e destruído, parado no
começo do trilho enquanto o jogador não restaura (a restauração é por etapas, com mecânico). PixelLab (regra 11): a partir do
carrinho vazio do jogo.

  python vagonete107.py gera      -> vagonete107/ruina_cand.png (candidatos, create_image_pro, no_background)
  python vagonete107.py escolhe N -> assets/game/iso/props/vagonete_ruina_SE.png e _SO (SO = espelho)
"""
import base64, io, os, sys
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(AQUI, "..", "..", "..", "..", "tools", "pixellab"))
import gen  # noqa: E402
from PIL import Image  # noqa: E402

PROPS = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", "iso", "props"))
PASTA = os.path.join(AQUI, "vagonete107")
CASA = "https://api.pixellab.ai/mcp/pixel-tools/31a6e399-011f-46c5-a845-e80e7731747b/assets/south/full.png"
DESC = ("The same small mine ore cart as the reference, but a WRECK: heavily rusted, tilted to one side with one wheel missing and "
        "another broken, a bent side plank and a cracked wooden box, weeds and dry grass growing through it, a few loose rotten "
        "rail sleepers beside it, no ore inside. Same camera angle, same pixel size and proportions as the reference cart "
        "(a bit lower and wider because it sags). Grimy, dark, desaturated palette: rust, dark browns, lead grey, a little dead "
        "green. Crisp 1px near-black outline. Light from top-left. No background, no ground tiles, no characters.")


def gera():
    os.makedirs(PASTA, exist_ok=True)
    b = io.BytesIO()
    Image.open(os.path.join(PROPS, "vagonete_vazio_SE.png")).convert("RGBA").resize((80, 84), Image.NEAREST).save(b, "PNG")
    args = {"description": DESC, "width": 64, "height": 64, "no_background": True,
            "reference_images": [{"base64": base64.b64encode(b.getvalue()).decode(),
                                  "usage": "the approved mine ore cart of the same game: same angle, same pixel size, same style"},
                                 {"url": CASA, "usage": "the approved house of the same game: art style and palette"}],
            "style_image_url": CASA, "style_copy": ["color_palette", "outline", "detail", "shading"]}
    print(gen.lote([("vagonete_ruina", "create_image_pro", args, os.path.join(PASTA, "ruina_cand.png"))],
                   registro=os.path.join(AQUI, "vagonete107_jobs.json")))


def escolhe(n):
    base = os.path.join(PASTA, "ruina_cand")
    p = os.path.join(base, "c%02d.png" % int(n))
    im = Image.open(p if os.path.exists(p) else base + ".png").convert("RGBA")
    bb = im.getbbox()
    im = im.crop(bb)
    # o carrinho do jogo tem 40 px de largura: a ruína um pouco maior (o carrinho arriado e o mato), reduzida a ~46 px (alfa
    # cortado de novo pra manter o pixel limpo)
    k = 46.0 / im.width
    im = im.resize((46, max(1, round(im.height * k))), Image.LANCZOS)
    im.putalpha(im.split()[3].point(lambda v: 255 if v >= 110 else 0))
    q = im
    q.save(os.path.join(PROPS, "vagonete_ruina_SE.png"))
    q.transpose(Image.FLIP_LEFT_RIGHT).save(os.path.join(PROPS, "vagonete_ruina_SO.png"))
    print("->", q.size)


if __name__ == "__main__":
    {"gera": gera, "escolhe": lambda: escolhe(sys.argv[2])}[sys.argv[1]]()
