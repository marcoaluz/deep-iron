"""PROTÓTIPO: pisos novos da superfície (Prompt 6) a partir dos candidatos escolhidos.
  python superficie.py monta     -> final/superficie/<piso>/chao_<k>.png (+ escada_pedra, rampa)
  python superficie.py brilho    -> brilho médio (HSV valor) de cada piso, contra a terra da colônia
  python superficie.py prancha <saida.png> -> cada piso ladrilhado 5x5 + escada de pedra e rampa
  python superficie.py cena <saida.png>    -> mini-mapa de teste (platô da vila, paredão com boca de mina, escada)
Topos saem da mesma retificação dos outros ambientes (tiles.retifica + topo_de).
"""
import sys, os, colorsys
from PIL import Image, ImageEnhance
import tiles

# piso: candidatos escolhidos (cada um vira uma variação), ajuste de brilho (1.0 = como veio),
# e se a borda é refeita com textura do miolo (pisos lisos, onde a borda escura vira grade).
# Alvo (valor HSV médio): terra 0,24 · clareira 0,34 · trilha/canteiro/laje ~0,30 (um pouco acima da terra)
ESCOLHA = {
    "grama_alta": ((0, 4, 8, 12, 13), 0.66, False),
    "trilha":     ((0, 12, 1, 10, 2), 0.50, True),
    "cascalho":   ((2, 7, 10, 14), 1.0, False),
    "lama":       ((5,), 1.22, True),
    "laje":       ((1, 5, 6, 15), 0.93, False),
    "canteiro":   ((15, 10), 0.51, True),
}
ESCADA_PEDRA, RAMPA = 1, 0


def cand(piso, i):
    return Image.open("superficie/%s/candidatos/c%02d.png" % (piso, i)).convert("RGBA")


def valor(img):
    px = [p for p in img.get_flattened_data() if p[3] > 200]
    return sum(colorsys.rgb_to_hsv(*(c / 255 for c in p[:3]))[2] for p in px) / max(1, len(px))


def escurece_hsv(img, f):
    """baixa o brilho e um pouco a saturação (o laranja do canteiro fica mais terroso)."""
    out = img.copy(); px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            r, g, b = colorsys.hsv_to_rgb(h, min(1.0, s * (0.75 + 0.25 * f)), min(1.0, v * f))
            px[x, y] = (int(r * 255), int(g * 255), int(b * 255), a)
    return out


def recheia_borda(topo, faixa=5):
    """a faixa perto da borda do losango recebe o pixel do miolo, puxado `faixa` px pro centro."""
    out = topo.copy(); p = topo.load(); o = out.load(); mt = tiles.mascara_topo().load()
    for y in range(32):
        for x in range(64):
            if not mt[x, y] or tiles._dist_borda(x, y) >= faixa:
                continue
            dx, dy = 32 - (x + 0.5), 16 - (y + 0.5)
            n = max(1e-6, (dx * dx + (2 * dy) ** 2) ** 0.5)
            sx, sy = int(x + 2 * faixa * dx / n), int(y + faixa * 2 * dy / n)
            if 0 <= sx < 64 and 0 <= sy < 32 and mt[sx, sy]:
                o[x, y] = p[sx, sy]
    return out


def monta():
    for piso, (idx, f, borda) in ESCOLHA.items():
        out = "final/superficie/%s" % piso
        os.makedirs(out, exist_ok=True)
        for k, i in enumerate(idx):
            t = tiles.topo_de(tiles.retifica(cand(piso, i)))
            if borda:
                t = tiles.aplica(recheia_borda(t), tiles.mascara_topo())
            if f != 1.0:
                t = escurece_hsv(t, f)
            t.save("%s/chao_%d.png" % (out, k))
    e = tiles.retifica_escada(cand("escada_pedra", ESCADA_PEDRA))
    e.save("final/superficie/escada_pedra_N.png"); e.transpose(Image.FLIP_LEFT_RIGHT).save("final/superficie/escada_pedra_O.png")
    r = tiles.retifica_escada(cand("rampa", RAMPA))
    r.save("final/superficie/rampa_N.png"); r.transpose(Image.FLIP_LEFT_RIGHT).save("final/superficie/rampa_O.png")
    print("ok")


def brilho():
    ref = [valor(Image.open("final/colonia/chao_%d.png" % k).convert("RGBA")) for k in range(4)]
    print("colonia (terra batida) %.3f" % (sum(ref) / len(ref)))
    for piso in ESCOLHA:
        vs = [valor(Image.open("final/superficie/%s/chao_%d.png" % (piso, k)).convert("RGBA"))
              for k in range(len(ESCOLHA[piso][0]))]
        print("%-10s %.3f" % (piso, sum(vs) / len(vs)))


def remendo(topos, n=5, s=0):
    """n x n tiles do mesmo piso, variação e espelho sorteados como no jogo."""
    c = Image.new("RGBA", (n * 64, n * 32 + 32), (0, 0, 0, 0))
    for i in range(n):
        for j in range(n):
            x, y = tiles.tela(i, j, 0)
            c.alpha_composite(tiles.escolhe(topos, i, j, s), (x + (n - 1) * 32, y))
    return c


def prancha(saida):
    from PIL import ImageDraw
    pisos = ["colonia", "clareira"] + list(ESCOLHA)
    W_, H_ = 5 * 64 + 20, 5 * 32 + 60
    c = Image.new("RGB", (4 * W_, ((len(pisos) + 3) // 4) * H_ + 150), (40, 38, 36)); d = ImageDraw.Draw(c)
    import glob
    for k, p in enumerate(pisos):
        pasta = "final/%s" % p if p in ("colonia", "clareira") else "final/superficie/%s" % p
        topos = [Image.open(f).convert("RGBA") for f in sorted(glob.glob(pasta + "/chao_*.png"))]
        r = remendo(topos)
        x, y = (k % 4) * W_ + 10, (k // 4) * H_ + 20
        c.paste(r, (x, y), r); d.text((x, y - 16), "%s (%d var.)" % (p, len(topos)), fill=(255, 230, 150))
    y0 = ((len(pisos) + 3) // 4) * H_ + 10
    for k, f in enumerate(("escada_pedra_N", "escada_pedra_O", "rampa_N", "rampa_O")):
        im = Image.open("final/superficie/%s.png" % f).convert("RGBA").resize((128, 128), Image.NEAREST)
        c.paste(im, (10 + k * 150, y0 + 16), im); d.text((10 + k * 150, y0), f, fill=(255, 230, 150))
    c.save(saida)


# ---------------------------------------------------------------- mini-mapa de teste
def cena(saida):
    """canto da superfície no espírito da imagem de referência do Marco: vila num platô alto
    (praça de laje, trilha, grama), paredão com a boca de mina, escada de pedra de 3 lances,
    embaixo terra batida, cascalho de rejeito na frente da mina, lama e canteiro de obra."""
    import glob
    ld = lambda pasta: [Image.open(f).convert("RGBA") for f in sorted(glob.glob(pasta + "/chao_*.png"))]
    T = {"colonia": ld("final/colonia"), "clareira": ld("final/clareira")}
    for p in ESCOLHA:
        T[p] = ld("final/superficie/%s" % p)
    col_b = [Image.open("final/colonia/bloco.png").convert("RGBA"), Image.open("final/colonia/bloco_1.png").convert("RGBA")]
    col_s = [Image.open("final/colonia/bloco_sem_beira.png").convert("RGBA"), Image.open("final/colonia/bloco_sem_beira_1.png").convert("RGBA")]
    esc = Image.open("final/superficie/escada_pedra_N.png").convert("RGBA")
    rampa = Image.open("final/superficie/rampa_N.png").convert("RGBA")
    boca = Image.open("final/superficie/boca_mina.png").convert("RGBA")
    casa = Image.open("../casa/casa_v0.png").convert("RGBA")
    NI, NJ, ALTO = 18, 15, 3
    alt = {}
    for i in range(NI):
        for j in range(NJ):
            alt[(i, j)] = ALTO if (i >= 8 and j <= 6) else 0
    for i in range(1, 5):                       # platô baixo à esquerda, com rampa
        for j in range(4, 8): alt[(i, j)] = 1
    alt[(2, 8)] = ("rampa", 0)
    alt[(9, 9)] = ("escada", 0); alt[(9, 8)] = ("escada", 1); alt[(9, 7)] = ("escada", 2)
    boca_tiles = {(11, 6), (12, 6)}
    # tipo de chão nos VÉRTICES
    def tipo_v(vi, vj):
        if vi >= 8 and vj <= 7:                 # em cima do platô
            if 12 <= vi <= 16 and 1 <= vj <= 5: return "laje"
            if vj >= 6 or vi >= 17 or vj == 0: return "grama_alta"
            if vi in (9, 10) or vj in (4,): return "trilha"
            return "clareira"
        if (vi - 11.5) ** 2 + (vj - 8.5) ** 2 < 5: return "cascalho"
        if 10 <= vj <= 12 and 9 <= vi <= 10: return "trilha"
        if vi == 9 and vj >= 9: return "trilha"
        if (vi - 4) ** 2 + (vj - 11.5) ** 2 < 5: return "lama"
        if 13 <= vi <= 16 and 9 <= vj <= 12: return "canteiro"
        if vi <= 1 or vj >= NJ - 1: return "grama_alta"
        return "colonia"
    ordem = ["colonia", "clareira", "trilha", "cascalho", "lama", "canteiro", "laje", "grama_alta"]
    def topo_fn(i, j):
        cant = (tipo_v(i, j), tipo_v(i + 1, j), tipo_v(i + 1, j + 1), tipo_v(i, j + 1))
        tex = {t: tiles.escolhe(T[t], i, j, 90 + k) for k, t in enumerate(ordem)}
        return tiles.topo_misto(i, j, cant, tex, ordem)
    itens = []
    for (i, j), h in alt.items():
        if (i, j) in boca_tiles:
            continue
        if isinstance(h, tuple):
            tipo, k0 = h
            for k in range(1, k0 + 1):
                itens.append((i + j, k, 0, tiles.escolhe(col_s, i, j, k, False), tiles.tela(i, j, k)))
            itens.append((i + j, k0 + 1, 0, esc if tipo == "escada" else rampa, tiles.tela(i, j, k0 + 1)))
            continue
        tp = topo_fn(i, j)
        if h == 0:
            itens.append((i + j, 0, 0, tp, tiles.tela(i, j, 0)))
        for k in range(1, h + 1):
            b = tiles.escolhe(col_b if k == h else col_s, i, j, k, False).copy()
            if k == h:
                b.paste(tp, (0, 0), tp)
            itens.append((i + j, k, 0, b, tiles.tela(i, j, k)))
    # boca de mina: caixa 2x1 tiles (11..12, 6), 3 degraus; o canto N do topo fica em (34, 2) do quadro
    x, y = tiles.tela(11, 6, ALTO)
    itens.append((18, ALTO + 0.5, 0, boca, (x - 2, y - 2)))
    for (i, j) in boca_tiles:    # o topo da boca é o próprio chão do platô (senão lê como caixa)
        itens.append((18, ALTO + 0.6, 0, topo_fn(i, j), tiles.tela(i, j, ALTO)))
    # casa no platô: âncora (centro da pegada no chão) = (120, 222) do quadro
    x, y = tiles.tela(13, 2, ALTO)
    itens.append((17.9, ALTO + 0.5, 1, casa, (x + 32 - 120, y + 16 - 222)))
    # gente
    pes = []
    for nome, d_, i, j, k in (("minerador", "south-west", 11, 8, 0), ("mineradora", "south-east", 13, 8, 0),
                               ("lenhador", "south-west", 9, 11, 0), ("engenheiro", "south-east", 14, 10, 0),
                               ("guarda", "south-east", 10, 3, ALTO), ("cozinheira", "south-west", 15, 5, ALTO),
                               ("civil", "south-east", 3, 5, 1)):
        im = Image.open("../%s/rotacoes/%s.png" % (nome, d_)).convert("RGBA")
        bb = im.getbbox(); ax, ay = (bb[0] + bb[2]) // 2, bb[3] - 2
        x, y = tiles.tela(i, j, k)
        itens.append((i + j + 0.5, k, 1, im, (x + 32 - ax, y + 16 - ay)))
    xs = [t[4][0] for t in itens]; ys = [t[4][1] for t in itens]
    ox, oy = -min(xs) + 10, -min(ys) + 10
    c = Image.new("RGBA", (max(xs) - min(xs) + 300, max(ys) - min(ys) + 120), (20, 19, 18, 255))
    for _, _, _, img, (x, y) in sorted(itens, key=lambda t: (t[0], t[1], t[2])):
        c.alpha_composite(img, (x + ox, y + oy))
    c = c.crop(c.getbbox())
    c.save(saida)
    c.resize((c.width * 2, c.height * 2), Image.NEAREST).save(saida.replace(".png", "_x2.png"))
    print(c.size)


if __name__ == "__main__":
    if sys.argv[1] == "cena":
        cena(sys.argv[2])
    elif sys.argv[1] == "prancha":
        prancha(sys.argv[2])
    else:
        {"monta": monta, "brilho": brilho}[sys.argv[1]]()
