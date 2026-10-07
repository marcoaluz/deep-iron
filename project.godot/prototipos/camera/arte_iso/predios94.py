"""Bloco 94: a CARPINTARIA no PixelLab, na receita dos prédios do jogo (regra 11 do CLAUDE.md): a evolução da
obra até ficar pronta (obra 1 -> 2 -> 3 -> pronto).

  python predios94.py guia      -> carpintaria/predio.json + carpintaria/guia.png (a guia 2:1 desenhada aqui,
                                   com as mesmas linhas do pixelart_workbench: caixa cinza + porta amarela)
  python predios94.py pronto    -> carpintaria/pronto.png (guia + a oficina e a casa aprovadas + o minerador)
  python predios94.py obra      -> carpintaria/obra_2.png (o esqueleto no mesmo quadro) e jobs.json
  python obras.py carpintaria   -> obra_1 e obra_3 (corte do esqueleto e do pronto)
  python predios94.py menu      -> assets/game/ui/icones/predios/carpintaria.png (o cartão do CONSTRUIR, como o
                                   ui/icones.py faz: render reduzido do pronto em 96 x 64; só este)
  python predios94.py legado    -> assets/game/carpintaria.png (o desenho do mapa antigo e do fantasma do
                                   posicionador: o pronto reduzido, 2 quadros — parada e trabalhando)
"""
import base64, io, json, os, sys
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
sys.path.insert(0, os.path.join(AQUI, "..", "..", "..", "..", "tools", "pixellab"))
import gen  # noqa: E402
import predio  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

PASTA = os.path.join(AQUI, "carpintaria")
PREDIOS = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", "iso", "predios"))
CASA = "https://api.pixellab.ai/mcp/pixel-tools/31a6e399-011f-46c5-a845-e80e7731747b/assets/south/full.png"
MINERADOR_SE = ("https://backblaze.pixellab.ai/file/pixellab-characters/731c5e37-851f-4127-aec6-b6ac884bc069/"
                "bb4bd3f2-6661-445c-a546-ffe7bee5d2cc/rotations/south-east.png")
JOBS = os.path.join(AQUI, "predios94_jobs.json")
# caixa da guia: largura x fundo x altura, sobra em cima (telhado/chaminé), porta (largura, altura)
CAIXA = (120.0, 90.0, 80.0, 40.0, (40.0, 55.0))
FIM = ("Grimy, dark, desaturated palette: soot black, dark browns, rust, lead grey; %s. Crisp 1px near-black outline "
       "around the silhouette; interior detail with darker shades of the local color. Light from top-left, low color "
       "count, clean readable pixel clusters.")
PRONTO = ("A village CARPENTRY WORKSHOP for a gritty isometric mining colony that survived a solar catastrophe, exactly "
          "filling the isometric 2:1 box of the guide: a sturdy timber-frame shed of dark weathered planks on a low "
          "stone base, a pitched roof of overlapping wooden shingles patched with a few rusty iron sheets, a short "
          "stone chimney for the glue stove, a WIDE open front where the orange outline is (two big plank doors swung "
          "open), and inside, in the shadow, a workbench with clamps and a hand saw on the wall. Outside, against the "
          "walls: a sawhorse with a plank on it, a neat stack of fresh pale sawn planks, a pile of rough logs, a "
          "half-built wooden bed frame leaning on the wall, a barrel of nails, wood shavings on the ground at the "
          "door, a small hanging wooden sign with a carved saw. The lantern by the door is unlit (light is added in "
          "code, no glow). Same art style and scale as the reference workshop and house. No characters, no background, "
          "no ground tiles. " + FIM % "one accent: pale fresh-cut wood")
OBRA = ("CONSTRUCTION of the SAME carpentry workshop as the reference, exactly on the same footprint, position, size "
        "and angle in the canvas: only the low stone base and the bare timber frame (posts and beams) standing, a few "
        "wall planks nailed on the lower part, the roof only bare rafters with no shingles, no chimney yet, no doors; "
        "stacked planks, a pile of logs, a sawhorse and a ladder on the ground around it. No characters, no "
        "background, no ground tiles. Same art style, palette and pixel size as the reference; crisp 1px near-black "
        "outline; light from top-left.")


def _b64(path):
    b = io.BytesIO()
    Image.open(path).convert("RGBA").save(b, "PNG")
    return base64.b64encode(b.getvalue()).decode()


def guia():
    fw, fd, h, sobra, porta = CAIXA
    predio.guia(PASTA, fw, fd, h, sobra, porta)  # (grava o predio.json e imprime a receita do workbench)
    meta = json.load(open(os.path.join(PASTA, "predio.json")))
    W, H = meta["quadro"]
    ax, ay = meta["ancora"]
    P = lambda x, y, z: (ax + predio.iso(x, y, z)[0], ay + predio.iso(x, y, z)[1])
    x0, x1, y0, y1 = -fw / 2, fw / 2, -fd / 2, fd / 2
    im = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(im)
    cinza, amarelo = (200, 200, 210, 255), (255, 200, 80, 255)
    for z in (0, h):
        d.line([P(x0, y0, z), P(x1, y0, z), P(x1, y1, z), P(x0, y1, z), P(x0, y0, z)], fill=cinza)
    for (x, y) in ((x0, y0), (x1, y0), (x1, y1), (x0, y1)):
        d.line([P(x, y, 0), P(x, y, h)], fill=cinza)
    pl, ph = porta
    cx = -fw / 4.0
    d.line([P(cx - pl / 2, y1, 0), P(cx - pl / 2, y1, ph), P(cx + pl / 2, y1, ph), P(cx + pl / 2, y1, 0)], fill=amarelo)
    im.save(os.path.join(PASTA, "guia.png"))
    print("guia", W, H)


def pronto():
    meta = json.load(open(os.path.join(PASTA, "predio.json")))
    W, H = meta["quadro"]
    args = {"description": PRONTO, "width": W, "height": H, "no_background": True,
            "reference_images": [
                {"base64": _b64(os.path.join(PASTA, "guia.png")),
                 "usage": "layout guide ONLY (do not draw the lines): the isometric box the workshop fills (the chimney "
                          "may rise above it); the orange outline marks the wide open front doors"},
                {"base64": _b64(os.path.join(PREDIOS, "oficina", "pronto.png")),
                 "usage": "the approved tool workshop of the same game: art style, timber and roof rendering, props "
                          "around the walls, and scale"},
                {"url": CASA, "usage": "the approved house of the same game: art style, palette and scale"},
                {"url": MINERADOR_SE, "usage": "scale: this miner is about 75 px tall"}],
            "style_image_url": CASA, "style_copy": ["color_palette", "outline", "detail", "shading"]}
    print(gen.lote([("carpintaria", "create_image_pro", args, os.path.join(PASTA, "pronto.png"))], registro=JOBS))


def obra():
    job = json.load(open(JOBS, encoding="utf-8"))["carpintaria"]["job"]
    url = "https://api.pixellab.ai/mcp/images/%s/download" % job
    meta = json.load(open(os.path.join(PASTA, "predio.json")))
    W, H = meta["quadro"]
    args = {"description": OBRA, "width": W, "height": H, "no_background": True,
            "reference_images": [{"base64": _b64(os.path.join(PASTA, "pronto.png")),
                                  "usage": "the finished workshop: keep exactly its footprint, size, position and "
                                           "angle; draw it half built"}],
            "style_image_url": url, "style_copy": ["color_palette", "outline", "detail", "shading"]}
    r = gen.lote([("carpintaria_obra", "create_image_pro", args, os.path.join(PASTA, "obra_2.png"))], registro=JOBS)
    print(r)
    json.dump({"_obs": "Bloco 94", "pronto": job, "obra_2": r["carpintaria_obra"].get("job"),
               "obras_1_3": "script (obras.py): obra_1 = base do esqueleto + material; obra_3 = pronto embaixo + esqueleto em cima"},
              open(os.path.join(PASTA, "jobs.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)


def legado():
    """o desenho do mapa antigo (cena 2D) e do fantasma do posicionador: o pronto reduzido a ~92 px de largura,
    2 quadros lado a lado (0 = parada, 1 = trabalhando: a porta com a lamparina acesa)."""
    im = Image.open(os.path.join(PASTA, "pronto.png")).convert("RGBA")
    im = im.crop(im.getbbox())
    k = 92.0 / im.width
    p = im.resize((92, max(1, round(im.height * k))), Image.LANCZOS)
    a = p.split()[3].point(lambda v: 255 if v >= 110 else 0)
    p.putalpha(a)
    aceso = p.copy()
    px = aceso.load()
    for y in range(aceso.height):  # a mesma imagem um pouco mais quente (o lampião aceso na porta)
        for x in range(aceso.width):
            r, g, b, al = px[x, y]
            if al:
                px[x, y] = (min(255, int(r * 1.12)), min(255, int(g * 1.05)), b, al)
    out = Image.new("RGBA", (p.width * 2, p.height))
    out.alpha_composite(p, (0, 0))
    out.alpha_composite(aceso, (p.width, 0))
    dest = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", "carpintaria.png"))
    out.save(dest)
    print("->", dest, out.size)


def menu():
    import numpy as np
    from PIL import ImageFilter

    def limpa(im):
        a = np.array(im.convert("RGBA"))
        a[..., 3] = np.where(a[..., 3] >= 110, 255, 0)
        im = Image.fromarray(a, "RGBA")
        bb = im.getbbox()
        return im.crop(bb) if bb else im

    im = limpa(Image.open(os.path.join(PREDIOS, "carpintaria", "pronto.png")))
    k = min(96 / im.width, 64 / im.height)
    r = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
    r = limpa(r.filter(ImageFilter.UnsharpMask(radius=1, percent=60, threshold=2)))
    q = Image.new("RGBA", (96, 64))
    q.alpha_composite(r, ((96 - r.width) // 2, 64 - r.height))
    dest = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", "ui", "icones", "predios", "carpintaria.png"))
    q.save(dest)
    lista_p = os.path.join(os.path.dirname(os.path.dirname(dest)), "icones.json")
    lista = json.load(open(lista_p, encoding="utf-8"))
    if "carpintaria" not in lista["predios"]:
        lista["predios"].append("carpintaria")
        json.dump(lista, open(lista_p, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("->", dest)


if __name__ == "__main__":
    {"guia": guia, "pronto": pronto, "obra": obra, "legado": legado, "menu": menu}[sys.argv[1]]()
