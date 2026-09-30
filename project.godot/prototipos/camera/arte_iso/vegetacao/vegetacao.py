"""PROTÓTIPO: árvores, vegetação, horta e madeira (Prompt 9).

  python vegetacao.py monta          -> final/*.png
  python vegetacao.py prancha <png>  -> prancha de entrega

Árvore no jogo (tree_node.gd): cheia -> sendo cortada -> toco -> rebrota (cresce de novo).
"Sendo cortada" = a árvore inteira + lascas de madeira (folha abaixo) + tremida no código;
"caída" = tora no chão (do lote de madeira: o lote de tora saiu cortado no quadro).
Horta (food_source.gd): cogumelos de caverna; os 6 estágios saíram do mesmo lote, no mesmo
canteiro: vazio, preparado, plantado, crescendo, pronto, colhido.
"""
import sys, os, colorsys, random
from PIL import Image, ImageDraw

C = lambda pasta, i: Image.open("%s/candidatos/c%02d.png" % (pasta, i)).convert("RGBA")

ARVORES = {"pinheiro": (1, 3), "carvalho": (0, 1, 3), "betula": (0, 1)}
SECA = ("betula", 2)
TOCO = {"pinheiro": 0, "carvalho": 5, "betula": 8}
MUDA = {"pinheiro": 12, "carvalho": 2, "betula": 7}
TORA = {"escura": ("madeira", 0), "clara": ("madeira", 1)}
HORTA = {"vazio": 0, "preparado": 1, "plantado": 2, "crescendo": 4, "pronto": 6, "colhido": 10}
MADEIRA = {"tora": 1, "toras_p": 3, "toras_m": 4, "toras_g": 7, "lenha_p": 9, "lenha_g": 10,
           "tabuas_p": 11, "tabuas_m": 13, "tabuas_g": 14}
RASTEIRA = {"flores": (24, 26, 27, 29), "capim": (32, 33, 35, 38), "galho": (40, 43, 45),
            "tronco_musgo": (44, 51, 52), "cogumelos": (56, 57, 59), "raizes": (60, 61)}
ARBUSTOS = {"arbusto": (0, 1, 3), "samambaia": (5, 6), "moita": (8, 9, 11), "espinheiro": (12, 13)}
MADEIRA_COR = [(112, 90, 70), (86, 68, 52), (150, 126, 96)]


def limpa_base_clara(im):
    """algumas vieram com uma mancha clara na base (sombra ao contrário): some."""
    out = im.copy(); px = out.load(); H = out.height
    for y in range(int(H * 0.6), H):
        for x in range(out.width):
            p = px[x, y]
            if p[3] > 40:
                h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in p[:3]))
                if v > 0.6 and s < 0.15:
                    px[x, y] = (0, 0, 0, 0)
    return out


def so_o_maior(im):
    """o lote de 64 vazou pedaços do vizinho na borda do quadro: fica só a peça principal
    (o maior pedaço e o que estiver a até 3 px dele)."""
    import numpy as np
    from collections import deque
    a = np.array(im); op = a[..., 3] > 40; H, W = op.shape
    lab = -np.ones((H, W), int); tam = []
    for y in range(H):
        for x in range(W):
            if op[y, x] and lab[y, x] < 0:
                n = len(tam); q = deque([(y, x)]); lab[y, x] = n; c = 0
                while q:
                    cy, cx = q.popleft(); c += 1
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < H and 0 <= nx < W and op[ny, nx] and lab[ny, nx] < 0:
                                lab[ny, nx] = n; q.append((ny, nx))
                tam.append(c)
    if not tam:
        return im
    big = int(np.argmax(tam))
    from PIL import ImageFilter
    perto = Image.fromarray(((lab == big) * 255).astype("uint8")).filter(ImageFilter.MaxFilter(7))
    pm = np.array(perto) > 0
    keep = np.zeros_like(op)
    for n in range(len(tam)):
        m = lab == n
        if n == big or (m & pm).any():
            keep |= m
    a[~keep] = 0
    return Image.fromarray(a)


def salva(im, nome, maior=False):
    os.makedirs("final", exist_ok=True)
    im = limpa_base_clara(im)
    if maior:
        im = so_o_maior(im)
    b = im.getbbox()
    (im.crop(b) if b else im).save("final/%s.png" % nome)


def lascas_madeira(n=6, seed=3):
    """folha do golpe de machado: lascas claras saem do tronco e caem (efeito, Prompt 18)."""
    rnd = random.Random(seed)
    parts = [(rnd.uniform(-1, 1), rnd.uniform(-2.0, -0.7), rnd.choice(MADEIRA_COR), rnd.choice((1, 2, 2))) for _ in range(8)]
    W, H = 40, 32
    f_ = Image.new("RGBA", (W * n, H), (0, 0, 0, 0)); d = ImageDraw.Draw(f_)
    for f in range(n):
        t = f + 0.5
        for vx, vy, c, s in parts:
            x = W / 2 + vx * 3.4 * t; y = H - 10 + vy * 3.0 * t + 0.45 * t * t
            if y < H - 2:
                d.rectangle([f * W + x, y, f * W + x + s, y + max(s - 1, 0)], fill=c + (255,))
    return f_


def monta():
    for esp, ids in ARVORES.items():
        for k, i in enumerate(ids):
            salva(C(esp, i), "arvore_%s_%d" % (esp, k))
        salva(C("toco", TOCO[esp]), "toco_%s" % esp)
        salva(C("muda", MUDA[esp]), "muda_%s" % esp)
    salva(C(*SECA), "arvore_seca")
    for nome, (p, i) in TORA.items():
        salva(C(p, i), "tora_caida_%s" % nome)
    for est, i in HORTA.items():
        salva(C("horta", i), "horta_%s" % est)
    for nome, i in MADEIRA.items():
        salva(C("madeira", i), "madeira_%s" % nome)
    for tipo, ids in RASTEIRA.items():
        for k, i in enumerate(ids):
            salva(C("rasteira", i), "%s_%d" % (tipo, k), maior=True)
    for tipo, ids in ARBUSTOS.items():
        for k, i in enumerate(ids):
            salva(C("arbustos", i), "%s_%d" % (tipo, k))
    lascas_madeira().save("final/lascas_madeira.png")
    print("ok")


def prancha(saida):
    import glob
    S = 2
    c = Image.new("RGB", (1500, 1000), (46, 44, 40)); d = ImageDraw.Draw(c)
    y = 6
    def linha(titulo, nomes, base_h, esc=S, gap=10):
        nonlocal y
        d.text((8, y), titulo, fill=(255, 230, 150)); y += 16
        x = 8
        for n in nomes:
            im = Image.open("final/%s.png" % n).convert("RGBA")
            im = im.resize((im.width * esc, im.height * esc), Image.NEAREST)
            c.paste(im, (x, y + base_h - im.height), im); x += im.width + gap
        y += base_h + 10
    m = Image.open("../minerador/rotacoes/south-east.png").convert("RGBA"); m.crop(m.getbbox()).save("final/_minerador.png")
    linha("ARVORES (3 especies + seca) e o minerador pra escala", ["arvore_pinheiro_0", "arvore_pinheiro_1", "arvore_carvalho_0", "arvore_carvalho_1",
          "arvore_carvalho_2", "arvore_betula_0", "arvore_betula_1", "arvore_seca", "_minerador"], 176, esc=1)
    linha("CICLO DA ARVORE: toco (depois do corte) / tora caida / muda rebrotando", ["toco_pinheiro", "toco_carvalho", "toco_betula",
          "tora_caida_escura", "tora_caida_clara", "muda_pinheiro", "muda_carvalho", "muda_betula"], 110)
    linha("HORTA DE COGUMELOS: vazio / preparado / plantado / crescendo / pronto / colhido", ["horta_%s" % e for e in HORTA], 100)
    linha("MADEIRA: tora, toras P/M/G, lenha P/G, tabuas P/M/G", ["madeira_%s" % n for n in MADEIRA], 100)
    linha("ARBUSTOS, SAMAMBAIAS, MOITAS, ESPINHEIROS", ["%s_%d" % (t, k) for t, ids in ARBUSTOS.items() for k in range(len(ids))], 90, gap=6)
    linha("FLORES, CAPIM ALTO, GALHOS, TRONCOS COM MUSGO, COGUMELOS, RAIZES", ["%s_%d" % (t, k) for t, ids in RASTEIRA.items() for k in range(len(ids))], 90, gap=6)
    la = Image.open("final/lascas_madeira.png").convert("RGBA"); la = la.resize((la.width * 3, la.height * 3), Image.NEAREST)
    d.text((8, y), "LASCAS DE MADEIRA (golpe do machado)", fill=(255, 230, 150)); c.paste(la, (8, y + 16), la)
    c.save(saida)


if __name__ == "__main__":
    monta() if sys.argv[1] == "monta" else prancha(sys.argv[2])
