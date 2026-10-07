"""Bloco 71: arte do S4 (cachoeira e lava) e do S5 (lago azul).

  python objetos.py gera        -> candidatos (create_image_pro) de cachoeira, casinhas de pedra e poça d'água
  python objetos.py escolhe cachoeira=c01 casas=c03,c09 poca_agua=c00,c02
  python objetos.py cachoeira   -> efeitos/anim/cachoeira/c00..c06 (a água descendo, por script)
  python objetos.py instala     -> poças d'água em assets/game/iso/chao/
As jazidas de gema azul saem do fundo70/jazidas.py (mesma edição da jazida de prata).
"""
import sys, os, base64, io, glob
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import gen
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
ARTE = os.path.join(AQUI, "..")
ISO = os.path.join(AQUI, "..", "..", "..", "..", "assets", "game", "iso")
ESTILO_IMG = os.path.join(ISO, "predios", "coletor_minerio", "pronto.png")
PEDIDOS = {
    "cachoeira": (80, 160, "Isometric 2:1 view: an underground WATERFALL pouring from a dark rocky ledge high in a cave "
                  "wall down to the floor: a narrow column of falling white-blue water with streaks, wet black rock "
                  "around it, a small splash and foam at the bottom. Only the waterfall and its rock, transparent "
                  "background. ", "white-blue falling water", None),
    "casas": (84, 84, "Isometric 2:1 view (like the reference building): a small ABANDONED STONE HUT from an old "
              "underground village: rough dry-stone walls, a low doorway, a collapsed slate roof, moss and blue "
              "mineral dust, no people. Only the hut, transparent background. ", "faint blue crystal glow in the doorway",
              ESTILO_IMG),
    "poca_agua": (160, 84, "Isometric 2:1 view: a wide flat irregular PUDDLE of clear dark blue water lying FLAT on a "
                  "dark wet cave floor (a wide flattened oval twice as wide as tall), small ripples and light "
                  "reflections, a dark wet-rock rim; flat, no height, no shadow. Only the puddle, transparent "
                  "background around it. ", "calm blue water reflections",
                  os.path.join(ISO, "chao", "poca_acido_0.png")),
}


def _data_url(path):
    b = io.BytesIO()
    Image.open(path).convert("RGBA").save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def gera():
    itens = []
    for nome, (w, h, desc, acento, ref) in PEDIDOS.items():
        args = {"description": desc + gen.ESTILO % acento, "width": w, "height": h, "no_background": True}
        if ref:
            if nome == "casas":
                args.update({"style_image_url": _data_url(ref), "style_copy": ["color_palette", "outline", "shading"]})
            else:
                args["reference_images"] = '[{"url": "%s", "usage": "shape, rim and size of the flat puddle (redraw it as water)"}]' % _data_url(ref)
        itens.append((nome, "create_image_pro", args, os.path.join(AQUI, nome + ".png")))
    gen.lote(itens, registro=os.path.join(AQUI, "jobs.json"), espera=15)


def escolhe(args):
    for a in args:
        nome, cs = a.split("=")
        for k, c in enumerate(cs.split(",")):
            im = Image.open(os.path.join(AQUI, nome, c + ".png")).convert("RGBA")
            im = im.crop(im.getbbox())
            base = {"casas": "casa_pedra", "cachoeira": "cachoeira", "poca_agua": "poca_agua"}[nome]
            dst = os.path.join(AQUI, base + ("_%d" % k if nome != "cachoeira" else "") + ".png")
            im.save(dst)
            print(dst, im.size)


def cachoeira(n=6):
    """A água descendo: os pixels claros/azuis da queda (a máscara da água) rolam pra baixo 3 px por
    quadro dentro da própria máscara; a rocha fica parada. c00 = o desenho de entrada."""
    import colorsys
    im = Image.open(os.path.join(AQUI, "cachoeira.png")).convert("RGBA")
    W, H = im.size
    px = im.load()

    def agua(p):
        if p[3] < 40:
            return False
        h, s, v = colorsys.rgb_to_hsv(p[0] / 255, p[1] / 255, p[2] / 255)
        return v > 0.45 and (0.45 < h < 0.72 or s < 0.18)

    mask = [[agua(px[x, y]) for x in range(W)] for y in range(H)]
    pasta = os.path.join(ARTE, "efeitos", "anim", "cachoeira")
    os.makedirs(pasta, exist_ok=True)
    im.save(os.path.join(pasta, "c00.png"))
    for f in range(1, n + 1):
        out = im.copy()
        op = out.load()
        for x in range(W):
            col = [y for y in range(H) if mask[y][x]]
            if len(col) < 4:
                continue
            cores = [px[x, y] for y in col]
            k = (f * 3) % len(col)
            for i, y in enumerate(col):
                op[x, y] = cores[(i - k) % len(col)]
        out.save(os.path.join(pasta, "c%02d.png" % f))
    print("efeitos/anim/cachoeira: %d quadros" % n)


def instala():
    chao = os.path.join(ISO, "chao")
    for v in range(2):
        Image.open(os.path.join(AQUI, "poca_agua_%d.png" % v)).save(os.path.join(chao, "poca_agua_%d.png" % v))
    print("instalado: chao/poca_agua_*.png")


if __name__ == "__main__":
    {"gera": gera, "cachoeira": cachoeira, "instala": instala}.get(sys.argv[1], lambda: escolhe(sys.argv[2:]))()
