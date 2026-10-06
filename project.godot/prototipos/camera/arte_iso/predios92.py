"""Bloco 92: a arte do PixelLab pros prédios e a decoração dos Blocos 86–90, na receita dos prédios do jogo
(Prompt 12: guia 2:1 + a casa aprovada + o minerador pra escala; obra 2 = o esqueleto no mesmo quadro;
obras.py monta a obra 1 e a 3).

- FORNALHA = a Fundição já gerada no Prompt 12 (fundicao/: pronto + obra_1..3), que não estava no jogo.
- IGREJA = nova, no mesmo desenho da capela velha do mapa (fundo71/itens: igreja), mas inteira e cuidada.
- DECORAÇÃO: banco, mesa e tocha já existem (props do mapa); faltam lampião, cerca, canteiro de flores e
  bandeira (create_image_pro, 16 candidatos, com o banco e a tocha do jogo como referência de escala/estilo).

  python predios92.py igreja          -> igreja/pronto.png (1 imagem)
  python predios92.py igreja_obra     -> igreja/obra_2.png (o esqueleto no mesmo quadro) e jobs.json
  python predios92.py decor [nomes]   -> decor92/<nome>/cNN.png + grade
  python predios92.py escolhe lampiao=c03 cerca=c01 ...  -> decor92/<nome>.png (recortado)
"""
import base64, io, json, os, sys
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(AQUI, "..", "..", "..", "..", "tools", "pixellab"))
import gen  # noqa: E402
from PIL import Image  # noqa: E402

PROPS = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", "iso", "props"))
GUIA_IGREJA = "https://api.pixellab.ai/mcp/pixel-tools/2449ddf6-8d81-4b37-8643-bd34ed6bf55a/assets/south/full.png"
CASA = "https://api.pixellab.ai/mcp/pixel-tools/31a6e399-011f-46c5-a845-e80e7731747b/assets/south/full.png"
MINERADOR_SE = ("https://backblaze.pixellab.ai/file/pixellab-characters/731c5e37-851f-4127-aec6-b6ac884bc069/"
                "bb4bd3f2-6661-445c-a546-ffe7bee5d2cc/rotations/south-east.png")
CAPELA_VELHA = os.path.join(PROPS, "igreja_0.png")  # (o link do Bloco 71 expirou: vai a imagem do jogo)
JOBS = os.path.join(AQUI, "predios92_jobs.json")
FIM = ("Grimy, dark, desaturated palette: soot black, dark browns, rust, lead grey; %s. Crisp 1px near-black outline "
       "around the silhouette; interior detail with darker shades of the local color. Light from top-left, low color "
       "count, clean readable pixel clusters.")

IGREJA = ("A small VILLAGE CHURCH for a gritty isometric mining colony that survived a solar catastrophe, exactly filling "
          "the isometric 2:1 box of the guide: the SAME architecture as the reference old chapel (dark stone blocks, "
          "dark timber, steep grey slate roof, a square bell tower at the front with a pointed slate spire and a small "
          "dull bronze bell, a simple wooden cross on top) but INTACT and CARED FOR by the villagers: the roof complete "
          "and patched with a few rusty iron plates, tall narrow arched windows with dark stained glass in muted "
          "colors (unlit, no glow), a small round rose window, a wide arched wooden double door where the orange "
          "outline is, three worn stone steps at the door, an iron lantern hook beside the door (no light), a small "
          "wooden notice board, a few potted plants and a stone bench by the wall. Same art style and scale as the "
          "reference house. No characters, no background, no ground tiles. " + FIM % "one accent: muted stained glass "
          "and a dull bronze bell")
IGREJA_OBRA = ("CONSTRUCTION of the SAME church as the reference, exactly on the same footprint, position, size and "
               "angle in the canvas: the dark stone walls half built, the bell tower only a timber frame inside wooden "
               "scaffolding, no spire and no bell yet, timber roof frame with bare rafters and no slates, window "
               "openings empty; stacked stone blocks, slates, planks and a ladder on the ground around it. No "
               "characters, no background, no ground tiles. Same art style, palette and pixel size as the reference; "
               "crisp 1px near-black outline; light from top-left.")

# nome -> (largura, altura, descrição, acento)
DECOR = {
    "lampiao": (32, 84, "a village STREET LAMP: a single slim black iron post on a small square stone base, with a "
                        "four-sided iron lantern with amber glass panes and a little peaked iron cap on top, a small "
                        "hook; the glass is unlit (light is added in code, no glow, no rays)",
                "one accent: dull amber glass"),
    "cerca": (64, 48, "a short rustic WOODEN FENCE segment: three weathered posts and two horizontal split rails, one "
                      "rail patched with wire, running diagonally in the isometric 2:1 view from the top-left to the "
                      "bottom-right (along the ground diamond's right-down edge), seen from the front-left",
              "weathered grey-brown wood"),
    "canteiro_flores": (48, 40, "a small raised FLOWER BED: a low rectangular border of old planks and stones, dark "
                                "soil, small clumps of hardy flowers (muted yellow, faded red and white) and green "
                                "leaves, lying flat on the ground in the isometric 2:1 view",
                        "one accent: small muted yellow and red flowers"),
    "bandeira": (40, 84, "a village FLAG on a tall thin wooden pole on a small pile of stones: a ragged rectangular "
                         "cloth banner in faded rust-red with a simple pale sun-and-pickaxe emblem, waving a little to "
                         "the right",
                 "one accent: faded rust-red cloth"),
}


def _data_url(path):
    b = io.BytesIO()
    Image.open(path).convert("RGBA").save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def igreja():
    args = {"description": IGREJA, "width": 260, "height": 360, "no_background": True,
            "reference_images": [
                {"url": GUIA_IGREJA, "usage": "layout guide ONLY (do not draw the lines): the isometric box the church "
                                              "fills (the bell tower spire rises above it); the orange outline marks "
                                              "the door"},
                {"base64": base64.b64encode(open(CAPELA_VELHA, "rb").read()).decode(), "usage": "the old ruined chapel of the same game: keep this architecture, "
                                               "materials and bell tower, but draw it intact, repaired and in use"},
                {"url": CASA, "usage": "the approved house of the same game: art style, palette, stone and slate "
                                       "rendering, and scale"},
                {"url": MINERADOR_SE, "usage": "scale: this miner is about 75 px tall"}],
            "style_image_url": CASA, "style_copy": ["color_palette", "outline", "detail", "shading"]}
    r = gen.lote([("igreja", "create_image_pro", args, os.path.join(AQUI, "igreja", "pronto.png"))], registro=JOBS)
    print(r)


def igreja_obra():
    job = json.load(open(JOBS, encoding="utf-8"))["igreja"]["job"]
    url = "https://api.pixellab.ai/mcp/images/%s/download" % job
    args = {"description": IGREJA_OBRA, "width": 260, "height": 360, "no_background": True,
            "reference_images": [{"url": url, "usage": "the finished church: keep exactly its footprint, size, "
                                                       "position and angle; draw it half built"}],
            "style_image_url": url, "style_copy": ["color_palette", "outline", "detail", "shading"]}
    r = gen.lote([("igreja_obra", "create_image_pro", args, os.path.join(AQUI, "igreja", "obra_2.png"))], registro=JOBS)
    print(r)
    jobs = {"_obs": "Bloco 92", "pronto": job, "obra_2": r["igreja_obra"].get("job"),
            "obras_1_3": "script (obras.py): obra_1 = base do esqueleto + material; obra_3 = pronto embaixo + esqueleto em cima"}
    json.dump(jobs, open(os.path.join(AQUI, "igreja", "jobs.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)


def decor(nomes):
    banco = _data_url(os.path.join(PROPS, "banco.png"))
    tocha = _data_url(os.path.join(PROPS, "tocha_chao_f0.png"))
    itens = []
    for nome in nomes:
        w, h, desc, acento = DECOR[nome]
        args = {"description": "Isometric 2:1 view, same angle, scale and art style as the reference bench of the same "
                               "game: " + desc + ". Only the object, transparent background, no ground tile, no "
                               "characters. " + FIM % acento,
                "width": w, "height": h, "no_background": True,
                "reference_images": [{"url": banco, "usage": "the wooden bench of the same game: art style, outline, "
                                                            "palette and pixel scale (the bench is 60 px wide)"},
                                     {"url": tocha, "usage": "the ground torch of the same game: height scale (about "
                                                            "50 px tall) and style"}],
                "style_image_url": banco, "style_copy": ["color_palette", "outline", "detail", "shading"]}
        itens.append((nome, "create_image_pro", args, os.path.join(AQUI, "decor92", nome + "_grade.png")))
    os.makedirs(os.path.join(AQUI, "decor92"), exist_ok=True)
    for nome, r in gen.lote(itens, registro=JOBS).items():
        print(nome, r)


def _sem_soltos(im, minimo=12):
    """apaga os pedacinhos soltos (pixel perdido longe do objeto: o recorte ficaria grande à toa)."""
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
    for par in pares:
        nome, c = par.split("=")
        im = _sem_soltos(Image.open(os.path.join(AQUI, "decor92", nome + "_grade", c + ".png")).convert("RGBA"))
        bb = im.getbbox()
        im.crop((max(0, bb[0] - 1), max(0, bb[1] - 1), min(im.width, bb[2] + 1), min(im.height, bb[3] + 1))).save(
            os.path.join(AQUI, "decor92", nome + ".png"))
        print(nome, c, im.getbbox())
    # (a cerca saiu em "/"; a pegada dela, ao longo do x do mundo, vai em "\" na vista iso: espelhada à mão)


if __name__ == "__main__":
    cmd, resto = sys.argv[1], sys.argv[2:]
    if cmd == "igreja":
        igreja()
    elif cmd == "igreja_obra":
        igreja_obra()
    elif cmd == "decor":
        decor([n for n in resto if n in DECOR] or list(DECOR))
    elif cmd == "escolhe":
        escolhe(resto)
