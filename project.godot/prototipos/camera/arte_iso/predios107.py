"""Bloco 107: a ESTUFA (de vidro), a CARVOARIA e o CURTUME no PixelLab, na receita dos prédios do jogo (regra 11 do CLAUDE.md):
a evolução da obra até ficar pronta (obra 1 -> 2 -> 3 -> pronto). É o predios94.py (carpintaria) com os 3 prédios novos.

  python predios107.py guia <nome>      -> <nome>/predio.json + <nome>/guia.png (a guia 2:1)
  python predios107.py pronto <nome>    -> <nome>/pronto.png (guia + a oficina e a casa aprovadas + o minerador)
  python predios107.py obra <nome>      -> <nome>/obra_2.png (o esqueleto no mesmo quadro) e jobs.json
  python obras.py <nome>                -> obra_1 e obra_3 (corte do esqueleto e do pronto)
  python predios107.py menu <nome>      -> assets/game/ui/icones/predios/<nome>.png (o cartão do CONSTRUIR, 96 x 64)
  python predios107.py legado <nome>    -> assets/game/<nome>.png (o desenho da cena 2D e do fantasma do posicionador)
nomes: estufa, carvoaria, curtume
"""
import base64, io, json, os, sys
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
sys.path.insert(0, os.path.join(AQUI, "..", "..", "..", "..", "tools", "pixellab"))
import gen  # noqa: E402
import predio  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

PREDIOS = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", "iso", "predios"))
CASA = "https://api.pixellab.ai/mcp/pixel-tools/31a6e399-011f-46c5-a845-e80e7731747b/assets/south/full.png"
MINERADOR_SE = ("https://backblaze.pixellab.ai/file/pixellab-characters/731c5e37-851f-4127-aec6-b6ac884bc069/"
                "bb4bd3f2-6661-445c-a546-ffe7bee5d2cc/rotations/south-east.png")
JOBS = os.path.join(AQUI, "predios107_jobs.json")
FIM = ("Grimy, dark, desaturated palette: soot black, dark browns, rust, lead grey; %s. Crisp 1px near-black outline "
       "around the silhouette; interior detail with darker shades of the local color. Light from top-left, low color "
       "count, clean readable pixel clusters.")
SEM = "No characters, no background, no ground tiles. Same art style and scale as the reference workshop and house. "

# nome -> caixa da guia (largura x fundo x altura, sobra em cima, porta), a referência de estilo, o pronto e a obra
ESTRUTURAS = {
    "estufa": {
        "caixa": (140.0, 90.0, 55.0, 45.0, (36.0, 38.0)),
        "ref": "oficina",
        "pronto": ("A village GREENHOUSE for a gritty isometric mining colony that survived a solar catastrophe, exactly filling "
                   "the isometric 2:1 box of the guide: a long GLASS HOUSE with a dark weathered timber frame on a low stone base, "
                   "the walls and the pitched roof made of many small glass panes (pale dusty green-grey glass with soft "
                   "highlights, a few panes cracked and patched with planks and rusty tin), a small wooden door at the front where "
                   "the orange outline is, a rain barrel with a gutter at one corner. Through the glass you see long raised beds "
                   "with leafy green plants and pale cave mushrooms. Outside, by the door: a watering can, a wheelbarrow of soil, "
                   "a stack of clay pots, a hanging lantern (unlit: light is added in code, no glow). It must clearly read as a "
                   "GLASS greenhouse. " + SEM + FIM % "one accent: pale dusty glass green"),
        "obra": ("CONSTRUCTION of the SAME glass greenhouse as the reference, exactly on the same footprint, position, size and angle "
                 "in the canvas: only the low stone base and the bare dark timber frame (posts, beams and roof ribs) standing, no "
                 "glass in the roof and only two or three glass panes already fitted in the lower wall; wooden crates of glass "
                 "sheets leaning against the frame, a ladder, a sawhorse and a pile of putty buckets around it. No characters, no "
                 "background, no ground tiles. Same art style, palette and pixel size as the reference; crisp 1px near-black "
                 "outline; light from top-left.")},
    "carvoaria": {
        "caixa": (100.0, 80.0, 62.0, 36.0, (34.0, 38.0)),
        "ref": "oficina",
        "pronto": ("A village CHARCOAL BURNER'S KILN for a gritty isometric mining colony that survived a solar catastrophe, exactly "
                   "filling the isometric 2:1 box of the guide: a squat DOME KILN of clay and fieldstone, soot-blackened, with a "
                   "small smoking vent hole on top and a low arched iron-barred firing door at the front where the orange outline "
                   "is (a faint ember glow inside the door only), a lean-to roof of rough planks on posts beside it sheltering a "
                   "neat stack of split logs on one side and burlap sacks of black charcoal on the other. Around it: an iron rake "
                   "and long tongs hanging on a post, a wheelbarrow with lumps of charcoal, a bucket of water, soot on the ground. "
                   + SEM + FIM % "one accent: charcoal black with a tiny ember orange"),
        "obra": ("CONSTRUCTION of the SAME charcoal kiln as the reference, exactly on the same footprint, position, size and angle in "
                 "the canvas: only a ring of fieldstones and the lower half of the clay dome built, the top still open with wooden "
                 "centering ribs, the lean-to only bare posts and rafters, no chimney smoke; a pile of clay, loose stones, a "
                 "wooden form and a few split logs around it. No characters, no background, no ground tiles. Same art style, "
                 "palette and pixel size as the reference; crisp 1px near-black outline; light from top-left.")},
    "curtume": {
        "caixa": (130.0, 90.0, 62.0, 30.0, (44.0, 46.0)),
        "ref": "oficina",
        "pronto": ("A village TANNERY for a gritty isometric mining colony that survived a solar catastrophe, exactly filling the "
                   "isometric 2:1 box of the guide: an open-sided timber-frame shed with a sloping roof of rusty corrugated iron "
                   "sheets and planks on a low stone base, a wide open front where the orange outline is. Inside and around: big "
                   "round wooden tanning vats and barrels, drying racks with stretched pale and reddish animal hides, a scraping "
                   "beam with a half-scraped hide, a pit with planks and a pile of bark, a small hanging wooden sign with a hide "
                   "shape. Hides hang in several tones of leather brown. " + SEM + FIM % "one accent: warm leather brown and ochre"),
        "obra": ("CONSTRUCTION of the SAME tannery as the reference, exactly on the same footprint, position, size and angle in the "
                 "canvas: only the low stone base and the bare timber frame (posts and beams) standing, the roof only bare rafters "
                 "with a few corrugated sheets stacked on the ground, two empty round vats waiting, a pile of bark, coiled rope "
                 "and a ladder. No characters, no background, no ground tiles. Same art style, palette and pixel size as the "
                 "reference; crisp 1px near-black outline; light from top-left.")},
}


def pasta(nome):
    return os.path.join(AQUI, nome)


def _b64(path):
    b = io.BytesIO()
    Image.open(path).convert("RGBA").save(b, "PNG")
    return base64.b64encode(b.getvalue()).decode()


def guia(nome):
    fw, fd, h, sobra, porta = ESTRUTURAS[nome]["caixa"]
    P0 = pasta(nome)
    os.makedirs(P0, exist_ok=True)
    predio.guia(P0, fw, fd, h, sobra, porta)  # (grava o predio.json e imprime a receita do workbench)
    meta = json.load(open(os.path.join(P0, "predio.json")))
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
    im.save(os.path.join(P0, "guia.png"))
    print("guia", nome, W, H)


def pronto(nome):
    e = ESTRUTURAS[nome]
    P0 = pasta(nome)
    meta = json.load(open(os.path.join(P0, "predio.json")))
    W, H = meta["quadro"]
    args = {"description": e["pronto"], "width": W, "height": H, "no_background": True,
            "reference_images": [
                {"base64": _b64(os.path.join(P0, "guia.png")),
                 "usage": "layout guide ONLY (do not draw the lines): the isometric box the building fills (a chimney or roof "
                          "ridge may rise above it); the orange outline marks the front opening"},
                {"base64": _b64(os.path.join(PREDIOS, e["ref"], "pronto.png")),
                 "usage": "the approved tool workshop of the same game: art style, timber and roof rendering, props around the "
                          "walls, and scale"},
                {"url": CASA, "usage": "the approved house of the same game: art style, palette and scale"},
                {"url": MINERADOR_SE, "usage": "scale: this miner is about 75 px tall"}],
            "style_image_url": CASA, "style_copy": ["color_palette", "outline", "detail", "shading"]}
    print(gen.lote([(nome, "create_image_pro", args, os.path.join(P0, "pronto.png"))], registro=JOBS))


def obra(nome):
    e = ESTRUTURAS[nome]
    P0 = pasta(nome)
    job = json.load(open(JOBS, encoding="utf-8"))[nome]["job"]
    url = "https://api.pixellab.ai/mcp/images/%s/download" % job
    meta = json.load(open(os.path.join(P0, "predio.json")))
    W, H = meta["quadro"]
    args = {"description": e["obra"], "width": W, "height": H, "no_background": True,
            "reference_images": [{"base64": _b64(os.path.join(P0, "pronto.png")),
                                  "usage": "the finished building: keep exactly its footprint, size, position and angle; draw it "
                                           "half built"}],
            "style_image_url": url, "style_copy": ["color_palette", "outline", "detail", "shading"]}
    r = gen.lote([(nome + "_obra", "create_image_pro", args, os.path.join(P0, "obra_2.png"))], registro=JOBS)
    print(r)
    json.dump({"_obs": "Bloco 107", "pronto": job, "obra_2": r[nome + "_obra"].get("job"),
               "obras_1_3": "script (obras.py): obra_1 = base do esqueleto + material; obra_3 = pronto embaixo + esqueleto em cima"},
              open(os.path.join(P0, "jobs.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)


def legado(nome):
    """o desenho da cena 2D e do fantasma do posicionador: o pronto reduzido a ~92 px de largura, 2 quadros (0 = parada,
    1 = trabalhando: um pouco mais quente)."""
    im = Image.open(os.path.join(PREDIOS, nome, "pronto.png")).convert("RGBA")
    im = im.crop(im.getbbox())
    k = 92.0 / im.width
    p = im.resize((92, max(1, round(im.height * k))), Image.LANCZOS)
    a = p.split()[3].point(lambda v: 255 if v >= 110 else 0)
    p.putalpha(a)
    aceso = p.copy()
    px = aceso.load()
    for y in range(aceso.height):
        for x in range(aceso.width):
            r, g, b, al = px[x, y]
            if al:
                px[x, y] = (min(255, int(r * 1.12)), min(255, int(g * 1.05)), b, al)
    out = Image.new("RGBA", (p.width * 2, p.height))
    out.alpha_composite(p, (0, 0))
    out.alpha_composite(aceso, (p.width, 0))
    dest = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", nome + ".png"))
    out.save(dest)
    print("->", dest, out.size)


def menu(nome):
    import numpy as np
    from PIL import ImageFilter

    def limpa(im):
        a = np.array(im.convert("RGBA"))
        a[..., 3] = np.where(a[..., 3] >= 110, 255, 0)
        im = Image.fromarray(a, "RGBA")
        bb = im.getbbox()
        return im.crop(bb) if bb else im

    im = limpa(Image.open(os.path.join(PREDIOS, nome, "pronto.png")))
    k = min(96 / im.width, 64 / im.height)
    r = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
    r = limpa(r.filter(ImageFilter.UnsharpMask(radius=1, percent=60, threshold=2)))
    q = Image.new("RGBA", (96, 64))
    q.alpha_composite(r, ((96 - r.width) // 2, 64 - r.height))
    dest = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", "ui", "icones", "predios", nome + ".png"))
    q.save(dest)
    lista_p = os.path.join(os.path.dirname(os.path.dirname(dest)), "icones.json")
    lista = json.load(open(lista_p, encoding="utf-8"))
    if nome not in lista["predios"]:
        lista["predios"].append(nome)
        json.dump(lista, open(lista_p, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("->", dest)


if __name__ == "__main__":
    {"guia": guia, "pronto": pronto, "obra": obra, "legado": legado, "menu": menu}[sys.argv[1]](sys.argv[2])
