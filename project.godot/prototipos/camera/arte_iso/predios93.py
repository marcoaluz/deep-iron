"""Bloco 93: a arte do PixelLab do CEMITÉRIO, na receita dos prédios (guia 2:1 + a casa aprovada + o minerador pra
escala; obra 2 = o esqueleto no mesmo quadro; obras.py monta a obra 1 e a 3), e as peças do enterro:

- cemiterio/pronto.png + obra_2.png (obras.py cemiterio -> obra_1, obra_3): o terreno cercado, as covas velhas
  no FUNDO e a FRENTE vazia (é lá que entram os túmulos novos, um por enterro).
- tumulo_0..2: os túmulos novos (cova fresca com cruz de madeira / lápide); candidatos -> escolhe.
- corpo: quem morreu, envolto na mortalha, no chão (até o padre buscar).
- corpo_costas: a mortalha carregada no ombro do padre (sobreposta à caminhada, como o saco do minerador).
- pq_ritos: o ícone da pesquisa "Ritos fúnebres" (32 px, no estilo dos ícones do laboratório).

  python predios93.py cemiterio | cemiterio_obra | pecas | escolhe tumulo_0=c03 ... | icone_escolhe c05
"""
import base64, io, json, os, sys
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(AQUI, "..", "..", "..", "..", "tools", "pixellab"))
import gen  # noqa: E402
from PIL import Image  # noqa: E402

PROPS = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", "iso", "props"))
ICONES = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", "ui", "icones"))
GUIA = "https://api.pixellab.ai/mcp/pixel-tools/adabbdcf-eb52-436a-b4f5-8e58f56d153a/assets/south/full.png"
CASA = "https://api.pixellab.ai/mcp/pixel-tools/31a6e399-011f-46c5-a845-e80e7731747b/assets/south/full.png"
MINERADOR_SE = ("https://backblaze.pixellab.ai/file/pixellab-characters/731c5e37-851f-4127-aec6-b6ac884bc069/"
                "bb4bd3f2-6661-445c-a546-ffe7bee5d2cc/rotations/south-east.png")
JOBS = os.path.join(AQUI, "predios93_jobs.json")
FIM = ("Grimy, dark, desaturated palette: soot black, dark browns, rust, lead grey; %s. Crisp 1px near-black outline "
       "around the silhouette; interior detail with darker shades of the local color. Light from top-left, low color "
       "count, clean readable pixel clusters.")

CEMITERIO = ("A small VILLAGE CEMETERY plot for a gritty isometric mining colony that survived a solar catastrophe, "
             "exactly filling the isometric 2:1 ground diamond of the guide: a low fence all around the plot made of "
             "weathered dark wooden posts and rusty iron railings, with a small wooden gate with a little arched "
             "wooden sign above it where the orange outline is; at the BACK half of the plot, two short rows of old "
             "weathered grey headstones and leaning wooden crosses with grass tufts; the FRONT half of the plot is "
             "EMPTY bare dark dirt ground, flat and clear (space for new graves); a gnarled leafless dead tree in the "
             "back corner, a small stone bench and an iron lantern post by the gate (unlit). Same art style and scale "
             "as the reference house. No characters, no background outside the plot, no ground tiles outside the "
             "fence. " + FIM % "one accent: pale moss on the stones")
CEMITERIO_OBRA = ("CONSTRUCTION of the SAME cemetery as the reference, exactly on the same footprint, position, size and "
                  "angle in the canvas: only some fence posts planted, the railings not placed yet (lying on the ground), "
                  "the gate frame alone without the sign, the ground being leveled with a shovel stuck in a dirt pile, "
                  "the old headstones still there, the dead tree; stacked posts and iron railings on the ground. No "
                  "characters, no background. Same art style, palette and pixel size as the reference; crisp 1px "
                  "near-black outline; light from top-left.")
PECAS = {
    "tumulo": (40, 40, "a single FRESH GRAVE seen in isometric 2:1 view: a low rectangular mound of dark freshly dug "
                       "dirt with a simple wooden cross (or a small rough grey headstone) at its head, a few small "
                       "stones; each candidate a different marker", "one accent: pale fresh dirt"),
    "corpo": (48, 32, "a DEAD BODY completely wrapped in a dirty off-white linen burial shroud tied with three bands of "
                      "rope, lying flat on the ground, seen in isometric 2:1 view, head to the upper left; no face, no "
                      "blood, nothing else", "dirty off-white linen"),
    "corpo_costas": (36, 24, "a long bundle: a body completely wrapped in a dirty off-white linen burial shroud tied "
                             "with rope bands, lying horizontally, seen from the side, as if carried across someone's "
                             "shoulders (only the bundle, no person, no face, no blood)", "dirty off-white linen"),
}
# Bloco 93 (o Marco: "o cemitério começa vazio" e "pode ser criado com proporção estendida"): a cerca é MODULAR —
# trecho, poste e portão, montados em volta do retângulo que o jogador marca; a arte do cemitério pronto (acima)
# serve de referência do estilo da cerca.
CERCA = {
    "cerca_cem": (64, 48, "ONE straight segment of a cemetery fence: rusty dark iron railings with small spear tips "
                          "between two dark weathered wooden posts, running diagonally in the isometric 2:1 view from the "
                          "TOP-LEFT down to the BOTTOM-RIGHT (along the ground diamond's right-down edge), seen from the "
                          "front-left; the two posts at the two ends", "rusty iron"),
    "poste_cem": (24, 48, "ONE single fence post of the same cemetery fence: a dark weathered square wooden post with a "
                          "small rusty iron cap on top, standing upright", "rusty iron cap"),
    "portao_cem": (64, 64, "the small GATE of the same cemetery fence: two dark wooden posts and a double gate of rusty "
                           "iron bars, with a little arched rusty iron sign above it, running diagonally in the isometric "
                           "2:1 view from the TOP-LEFT down to the BOTTOM-RIGHT, like the fence segment; closed",
                   "rusty iron"),
}

ICONE = ("game UI icon: a small grey headstone with a white lily flower and a lit candle in front of it. Same style, "
         "size, outline and light as the reference icons of the same game: chunky readable pixel art, 1px near-black "
         "outline, warm muted palette, centered, transparent background, no text, no frame.")


def _b64(path):
    return base64.b64encode(open(path, "rb").read()).decode()


def cemiterio():
    args = {"description": CEMITERIO, "width": 280, "height": 264, "no_background": True,
            "reference_images": [
                {"url": GUIA, "usage": "layout guide ONLY (do not draw the lines): the isometric ground diamond the "
                                       "fenced plot fills; the orange outline marks the gate"},
                {"base64": _b64(os.path.join(PROPS, "cova.png")), "usage": "an old grave of the same game: style"},
                {"url": CASA, "usage": "the approved house of the same game: art style, palette and scale"},
                {"url": MINERADOR_SE, "usage": "scale: this miner is about 75 px tall"}],
            "style_image_url": CASA, "style_copy": ["color_palette", "outline", "detail", "shading"]}
    print(gen.lote([("cemiterio", "create_image_pro", args, os.path.join(AQUI, "cemiterio", "pronto.png"))], registro=JOBS))


def cemiterio_obra():
    job = json.load(open(JOBS, encoding="utf-8"))["cemiterio"]["job"]
    url = "https://api.pixellab.ai/mcp/images/%s/download" % job
    args = {"description": CEMITERIO_OBRA, "width": 280, "height": 264, "no_background": True,
            "reference_images": [{"url": url, "usage": "the finished cemetery: keep exactly its footprint, size, "
                                                       "position and angle; draw it being built"}],
            "style_image_url": url, "style_copy": ["color_palette", "outline", "detail", "shading"]}
    r = gen.lote([("cemiterio_obra", "create_image_pro", args, os.path.join(AQUI, "cemiterio", "obra_2.png"))], registro=JOBS)
    print(r)
    json.dump({"_obs": "Bloco 93", "pronto": job, "obra_2": r["cemiterio_obra"].get("job"),
               "obras_1_3": "script (obras.py)"}, open(os.path.join(AQUI, "cemiterio", "jobs.json"), "w"), indent=1)


def pecas():
    banco = _b64(os.path.join(PROPS, "banco.png"))
    itens = []
    for nome, (w, h, desc, acento) in PECAS.items():
        args = {"description": "Same angle, scale and art style as the reference bench of the same game: " + desc +
                               ". Only the object, transparent background, no ground tile, no characters. " + FIM % acento,
                "width": w, "height": h, "no_background": True,
                "reference_images": [{"base64": banco, "usage": "the wooden bench of the same game: art style, outline, "
                                                               "palette and pixel scale (the bench is 60 px wide)"},
                                     {"base64": _b64(os.path.join(PROPS, "cova.png")), "usage": "an old grave of the same game"}],
                "style_image_base64": banco, "style_copy": ["color_palette", "outline", "detail", "shading"]}
        itens.append((nome, "create_image_pro", args, os.path.join(AQUI, "cemiterio", "_cand_" + nome + ".png")))
    med = _b64(os.path.join(ICONES, "pq_medicina.png"))
    itens.append(("pq_ritos", "create_image_pro", {
        "description": ICONE, "width": 32, "height": 32, "no_background": True,
        "reference_images": [{"base64": med, "usage": "the 'field medicine' research icon of the same game: style and size"},
                             {"base64": _b64(os.path.join(ICONES, "padre.png")), "usage": "the priest job icon of the same game"}],
        "style_image_base64": med, "style_copy": ["color_palette", "outline", "detail", "shading"]},
        os.path.join(AQUI, "cemiterio", "_cand_pq_ritos.png")))
    for nome, r in gen.lote(itens, registro=JOBS).items():
        print(nome, r)


def cerca():
    ref = os.path.join(AQUI, "cemiterio", "pronto.png")
    seg = os.path.join(AQUI, "decor92", "cerca.png")
    itens = []
    for nome, (w, h, desc, acento) in CERCA.items():
        args = {"description": "Same art style and scale as the reference cemetery of the same game: " + desc +
                               ". Only the object, transparent background, no ground tile, no grass, no characters. " + FIM % acento,
                "width": w, "height": h, "no_background": True,
                "reference_images": [{"base64": _b64(ref), "usage": "the cemetery of the same game: copy the style of its "
                                                                   "fence, posts and gate"},
                                     {"base64": _b64(seg), "usage": "a fence segment of the same game: the same diagonal "
                                                                   "direction and pixel scale"}],
                "style_image_base64": _b64(ref), "style_copy": ["color_palette", "outline", "detail", "shading"]}
        itens.append((nome, "create_image_pro", args, os.path.join(AQUI, "cemiterio", "_cand_" + nome + ".png")))
    for nome, r in gen.lote(itens, registro=JOBS).items():
        print(nome, r)


def _sem_soltos(im, minimo=40):
    import numpy as np
    a = np.array(im)
    op = a[..., 3] > 0
    vis = np.zeros_like(op)
    H, W = op.shape
    for y0 in range(H):
        for x0 in range(W):
            if not op[y0, x0] or vis[y0, x0]:
                continue
            pilha, comp = [(y0, x0)], []
            vis[y0, x0] = True
            while pilha:
                y, x = pilha.pop()
                comp.append((y, x))
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        yy, xx = y + dy, x + dx
                        if 0 <= yy < H and 0 <= xx < W and op[yy, xx] and not vis[yy, xx]:
                            vis[yy, xx] = True
                            pilha.append((yy, xx))
            if len(comp) < minimo:
                for y, x in comp:
                    a[y, x, 3] = 0
    return Image.fromarray(a)


def escolhe(pares):
    """tumulo_0=c03 corpo=c01 ... -> cemiterio/<nome>.png recortado (o tumulo_N sai dos candidatos do 'tumulo')."""
    for par in pares:
        nome, c = par.split("=")
        base = "tumulo" if nome.startswith(("tumulo", "cruz", "lapide")) else nome
        im = _sem_soltos(Image.open(os.path.join(AQUI, "cemiterio", "_cand_" + base, c + ".png")).convert("RGBA"))
        bb = im.getbbox()
        im.crop((max(0, bb[0] - 1), max(0, bb[1] - 1), min(im.width, bb[2] + 1), min(im.height, bb[3] + 1))).save(
            os.path.join(AQUI, "cemiterio", nome + ".png"))
        print(nome, c, bb)


def icone_escolhe(c):
    import numpy as np
    im = Image.open(os.path.join(AQUI, "cemiterio", "_cand_pq_ritos", c + ".png")).convert("RGBA")
    a = np.array(im)
    a[..., 3] = np.where(a[..., 3] >= 110, 255, 0)
    im = Image.fromarray(a)
    im = im.crop(im.getbbox())
    for lado, dest in ((32, os.path.join(ICONES, "pq_ritos.png")), (24, os.path.join(ICONES, "p24", "pq_ritos.png"))):
        q = Image.new("RGBA", (lado, lado))
        x = im if max(im.size) <= lado else im.resize((round(im.width * lado / max(im.size)), round(im.height * lado / max(im.size))), Image.LANCZOS)
        q.alpha_composite(x, ((lado - x.width) // 2, (lado - x.height) // 2))
        q.save(dest)
    lista = json.load(open(os.path.join(ICONES, "icones.json"), encoding="utf-8"))
    if "pq_ritos" not in lista["icones"]:
        lista["icones"].append("pq_ritos")
        json.dump(lista, open(os.path.join(ICONES, "icones.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("pq_ritos", c)


if __name__ == "__main__":
    cmd, resto = sys.argv[1], sys.argv[2:]
    {"cemiterio": lambda: cemiterio(), "cemiterio_obra": lambda: cemiterio_obra(), "pecas": lambda: pecas(),
     "escolhe": lambda: escolhe(resto), "cerca": lambda: cerca(), "icone_escolhe": lambda: icone_escolhe(resto[0])}[cmd]()
