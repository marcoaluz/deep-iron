"""PROTÓTIPO: tiles de relevo isométrico 2:1 (mapa de altura em degraus fixos).

Geometria (contrato, regra 6):
- tile = 32 x 32 no chão -> losango de topo 64 x 32 na tela;
- degrau = 32 de altura -> um bloco de platô é 64 x 64 (topo + as 2 faces visíveis);
- o chão (nível 0) usa só o losango de topo do bloco.
Ordem de desenho: coluna por coluna em ordem de (i + j) crescente, e dentro da coluna de baixo
pra cima. Face escondida por vizinho é coberta sozinha: não existe tile de "canto" pra desenhar.

  python tiles.py mascara <bloco.png> <saida_bloco.png> <saida_topo.png>
  python tiles.py cena <bloco.png> <topo.png> <saida.png> [<personagem.png>]
"""
import sys
from PIL import Image

T = 32        # lado do tile no chão
STEP = 32     # altura de um degrau
W, H = 64, 64  # quadro do bloco


def mascara_topo():
    m = Image.new("L", (W, 32), 0)
    px = m.load()
    for r in range(32):
        half = 2 * (r + 1) if r < 16 else 2 * (32 - r)
        for x in range(32 - half, 32 + half):
            px[x, r] = 255
    return m


def mascara_bloco():
    m = Image.new("L", (W, H), 0)
    px = m.load()
    top = mascara_topo().load()
    for y in range(H):
        for x in range(W):
            if y < 32 and top[x, y]:
                px[x, y] = 255
            # faces: entre a borda de cima (linha do losango de baixo) e a de baixo (32 abaixo)
            d = x if x < 32 else 63 - x          # distância à borda lateral
            y_top = 16 + d // 2                    # borda de baixo do losango naquela coluna
            if 16 <= y_top <= y < y_top + STEP and y >= 16:
                px[x, y] = 255
    return m


def aplica(img, m):
    img = img.convert("RGBA")
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), m)
    return out


def tela(i, j, k):
    """canto de cima-esquerda do quadro do bloco cujo TOPO fica na altura k degraus."""
    return (i - j) * T, (i + j) * (T // 2) - k * STEP


def cena(bloco, topo, alturas, pessoas=(), escada=None, fundo=1.0, topo_fn=None):
    """alturas: dict (i, j) -> degraus. pessoas: [(img, i, j, k, ancora_x, ancora_y)]."""
    niv = {c: (h[1] + 1 if isinstance(h, tuple) else h) for c, h in alturas.items()}
    xs = [tela(i, j, k)[0] for (i, j), k in niv.items()]
    ys = [tela(i, j, k)[1] for (i, j), k in niv.items()]
    ox, oy = -min(xs) + 20, -min(ys) + 120
    c = Image.new("RGBA", (max(xs) - min(xs) + W + 40, max(ys) - min(ys) + H + 160), (40, 38, 36, 255))
    itens = []
    topos = topo if isinstance(topo, list) else [topo]
    blocos = bloco if isinstance(bloco, list) else [bloco]
    if isinstance(bloco, tuple):    # (blocos com beira, blocos sem beira)
        blocos, baixos = bloco
    else:
        baixos = blocos
    base = min((h[1] if isinstance(h, tuple) else h) for h in alturas.values())
    base = min(base, 0)

    def luz(img, k):   # abaixo do chão, cada degrau escurece um pouco (o fundo do buraco)
        return escurece(img, fundo ** max(0, -k)) if fundo < 1 else img
    for (i, j), h in alturas.items():
        if isinstance(h, tuple):       # ("escada", nível de baixo, "N" ou "O")
            _, k0, lado = h
            for k in range(base + 1, k0 + 1):
                itens.append((i + j, k, 0, escolhe(baixos, i, j, k, False), tela(i, j, k)))
            e = escada if lado == "N" else escada.transpose(Image.FLIP_LEFT_RIGHT)
            itens.append((i + j, k0 + 1, 0, e, tela(i, j, k0 + 1)))
            continue
        tp = topo_fn(i, j) if topo_fn else escolhe(topos, i, j, 99)
        if h == base:
            itens.append((i + j, base, 0, luz(tp, h), tela(i, j, base)))
        for k in range(base + 1, h + 1):
            b = escolhe(blocos if k == h else baixos, i, j, k, False).copy()
            if k == h:   # o topo da coluna usa as mesmas variações do chão
                b.paste(tp, (0, 0), tp)
            itens.append((i + j, k, 0, luz(b, k), tela(i, j, k)))
    for img, i, j, k, ax, ay in pessoas:
        # pé no centro do losango do tile (i, j) na altura k
        x, y = tela(i, j, k)
        itens.append((i + j + 0.5, k, 1, img, (x + 32 - ax, y + 16 - ay)))
    for _, _, _, img, (x, y) in sorted(itens, key=lambda t: (t[0], t[1], t[2])):
        c.alpha_composite(img, (x + ox, y + oy))
    return c


def main():
    if sys.argv[1] == "mascara":
        src = Image.open(sys.argv[2]).convert("RGBA")
        aplica(src, mascara_bloco()).save(sys.argv[3])
        aplica(src.crop((0, 0, W, 32)), mascara_topo()).save(sys.argv[4])
    elif sys.argv[1] == "cena":
        bloco = Image.open(sys.argv[2]).convert("RGBA")
        topo = Image.open(sys.argv[3]).convert("RGBA")
        alt = {(i, j): 0 for i in range(10) for j in range(10)}
        for i in range(2, 7):
            for j in range(2, 6):
                alt[(i, j)] = 1           # platô de 1 degrau
        for i in range(2, 4):
            for j in range(2, 4):
                alt[(i, j)] = 2           # 2º andar
        pessoas = []
        if len(sys.argv) > 5:
            p = Image.open(sys.argv[5]).convert("RGBA")
            bb = p.getbbox()
            ax, ay = (bb[0] + bb[2]) // 2, bb[3] - 2
            pessoas = [(p, 5, 4, 1, ax, ay), (p, 7, 7, 0, ax, ay), (p, 3, 6, 0, ax, ay)]
        cena(bloco, topo, alt, pessoas).save(sys.argv[4])


if __name__ == "__main__":
    main()


# ---------------------------------------------------------------- retificação
# A IA desenha o bloco dentro da guia, mas 1-2 px menor e com contorno preto em volta. Pra
# emendar sem grade: acha os vértices do bloco dela, e reamostra topo e faces (vizinho mais
# próximo) na geometria exata, recuando MARGEM px de cada borda (o contorno fica de fora).
MARGEM = 2.0
MARGEM_TOPO = 3.0


def vertices(img):
    """(T, L, R, B, h) do bloco desenhado: topo, esquerda, direita, frente do losango e altura."""
    a = img.split()[3].point(lambda v: 255 if v > 40 else 0)
    x0, y0, x1, y1 = a.getbbox()
    px = a.load()
    xmin, xmax = x0, x1 - 1
    rows = [y for y in range(y0, y1) if px[xmin, y]]
    yl0, yl1 = rows[0], rows[-1]            # a borda vertical da esquerda
    cx = (xmin + xmax + 1) / 2.0
    T = (cx, y0)
    L = (xmin, yl0)
    R = (xmax + 1, yl0)
    B = (cx, 2 * yl0 - y0)
    h = yl1 - yl0 + 1
    return T, L, R, B, h


def _lin(p, a, b, u, v):
    return (p[0] + u * (a[0] - p[0]) + v * (b[0] - p[0]), p[1] + u * (a[1] - p[1]) + v * (b[1] - p[1]))


def retifica(src, pula_beira=0.0):
    """bloco 64x64 exato a partir de um bloco desenhado pela IA. pula_beira: fração do alto da
    face que fica de fora (a borda de terra pendurada), pro bloco que tem outro em cima."""
    src = src.convert("RGBA")
    sp = src.load()
    T, L, R, B, h = vertices(src)
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    op = out.load()
    mt = mascara_topo().load()
    mb = mascara_bloco().load()
    # geometria alvo (centros de pixel)
    tT, tL, tR, tB = (32.0, 0.0), (0.0, 16.0), (64.0, 16.0), (32.0, 32.0)
    su = MARGEM / 30.0

    def amostra(x, y):
        x = min(max(int(x), 0), src.width - 1)
        y = min(max(int(y), 0), src.height - 1)
        return sp[x, y]

    for y in range(H):
        for x in range(W):
            if not mb[x, y]:
                continue
            X, Y = x + 0.5, y + 0.5
            if y < 32 and mt[x, y]:
                # topo: X,Y = tT + u*(tR-tT) + v*(tL-tT)  ->  u, v
                dx, dy = X - tT[0], Y - tT[1]
                u = (dx / 32.0 + dy / 16.0) / 2.0
                v = (-dx / 32.0 + dy / 16.0) / 2.0
                st = MARGEM_TOPO / 30.0
                u = st + u * (1 - 2 * st)
                v = st + v * (1 - 2 * st)
                op[x, y] = amostra(*_lin(T, R, L, u, v))
            elif x < 32:
                # face da esquerda: de L (u=0) a B (u=1), v pra baixo
                u = X / 32.0
                v = (Y - (16.0 + X / 2.0)) / STEP
                u = su + u * (1 - 2 * su)
                v = pula_beira + min(v, 1.0) * (1 - MARGEM / h - pula_beira)
                p = _lin(L, B, (L[0], L[1] + h), u, 0)
                op[x, y] = amostra(p[0], p[1] + v * h)
            else:
                u = (X - 32.0) / 32.0
                v = (Y - (32.0 - (X - 32.0) / 2.0)) / STEP
                u = su + u * (1 - 2 * su)
                v = pula_beira + min(v, 1.0) * (1 - MARGEM / h - pula_beira)
                p = _lin(B, R, (B[0], B[1] + h), u, 0)
                op[x, y] = amostra(p[0], p[1] + v * h)
    return out


# ---------------------------------------------------------------- chão sem grade
def _lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def _dist_borda(x, y):
    """distância (em px de tile, 0..16) do pixel (x, y) do losango até a borda mais perto."""
    X, Y = x + 0.5, y + 0.5
    u = ((X - 32) / 32 + Y / 16) / 2
    v = ((32 - X) / 32 + Y / 16) / 2
    return min(u, v, 1 - u, 1 - v) * 32


def equaliza_borda(topo, faixa=4):
    """A IA escurece a borda do losango (sombra de contorno): na emenda isso vira grade.
    Cada faixa de distância à borda ganha a diferença de luz até o miolo, trocando o pixel
    pela cor MAIS PARECIDA da própria paleta do tile (não cria cor nova)."""
    topo = topo.convert("RGBA")
    p = topo.load()
    mt = mascara_topo().load()
    pal = sorted({p[x, y][:3] for y in range(32) for x in range(64) if mt[x, y] and p[x, y][3] > 40})
    bandas = {}
    for y in range(32):
        for x in range(64):
            if mt[x, y] and p[x, y][3] > 40:
                b = min(int(_dist_borda(x, y)), faixa)
                bandas.setdefault(b, []).append(_lum(p[x, y]))
    miolo = sum(bandas[faixa]) / len(bandas[faixa])
    delta = {b: miolo - sum(v) / len(v) for b, v in bandas.items() if b < faixa}
    out = topo.copy()
    op = out.load()
    for y in range(32):
        for x in range(64):
            if not (mt[x, y] and p[x, y][3] > 40):
                continue
            b = min(int(_dist_borda(x, y)), faixa)
            if b >= faixa or abs(delta[b]) < 0.5:
                continue
            c = p[x, y]
            alvo = tuple(min(255, max(0, v + delta[b])) for v in c[:3])
            op[x, y] = min(pal, key=lambda q: sum((q[k] - alvo[k]) ** 2 for k in range(3))) + (c[3],)
    return out


def topo_de(bloco_retificado):
    return equaliza_borda(aplica(bloco_retificado.crop((0, 0, W, 32)), mascara_topo()))


def _h(i, j, s):
    return ((i * 73856093) ^ (j * 19349663) ^ (s * 83492791)) & 0xFFFF


def escolhe(lista, i, j, s=0, espelha=True):
    """variação fixa por tile (sempre a mesma no mesmo lugar), com espelho sorteado.
    Bloco NÃO espelha: o espelho troca a face clara (esquerda) com a escura (direita)."""
    img = lista[_h(i, j, s) % len(lista)]
    return img.transpose(Image.FLIP_LEFT_RIGHT) if espelha and _h(i, j, s + 7) % 2 else img


# ---------------------------------------------------------------- escada (1 tile, sobe 1 degrau pro norte)
# Quadro 64x64. Rampa = paralelogramo A B C D; lado visível (leste) = triângulo B B0 C.
# O vértice A é o canto norte do tile na altura de CIMA: desenha em tela(i, j, k0 + 1).
# Espelhada (FLIP_LEFT_RIGHT) = escada que sobe pro oeste, no mesmo lugar.
E_A, E_B, E_C, E_D, E_B0 = (32.0, 0.0), (64.0, 16.0), (32.0, 64.0), (0.0, 48.0), (64.0, 48.0)


def _dentro_tri(p, a, b, c):
    def s(p1, p2, p3):
        return (p1[0] - p3[0]) * (p2[1] - p3[1]) - (p2[0] - p3[0]) * (p1[1] - p3[1])
    d1, d2, d3 = s(p, a, b), s(p, b, c), s(p, c, a)
    neg = d1 < 0 or d2 < 0 or d3 < 0
    pos = d1 > 0 or d2 > 0 or d3 > 0
    return not (neg and pos)


def mascara_escada():
    m = Image.new("L", (W, H), 0)
    px = m.load()
    for y in range(H):
        for x in range(W):
            p = (x + 0.5, y + 0.5)
            if (_dentro_tri(p, E_A, E_B, E_C) or _dentro_tri(p, E_A, E_C, E_D)
                    or _dentro_tri(p, E_B, E_B0, E_C)):
                px[x, y] = 255
    return m


def vertices_escada(img):
    a = img.split()[3].point(lambda v: 255 if v > 40 else 0)
    x0, y0, x1, y1 = a.getbbox()
    px = a.load()
    top = [x for x in range(x0, x1) if px[x, y0]]
    bot = [x for x in range(x0, x1) if px[x, y1 - 1]]
    dir_ = [y for y in range(y0, y1) if px[x1 - 1, y]]
    esq = [y for y in range(y0, y1) if px[x0, y]]
    A = (sum(top) / len(top) + 0.5, y0)
    C = (sum(bot) / len(bot) + 0.5, y1)
    B = (x1, dir_[0])
    B0 = (x1, dir_[-1] + 1)
    D = (x0, sum(esq) / len(esq) + 0.5)
    return A, B, C, D, B0


def _afim(src_tri, dst_tri):
    """função que leva um ponto do triângulo dst pro triângulo src (coordenadas baricêntricas)."""
    (x1, y1), (x2, y2), (x3, y3) = dst_tri
    den = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)

    def f(p):
        l1 = ((y2 - y3) * (p[0] - x3) + (x3 - x2) * (p[1] - y3)) / den
        l2 = ((y3 - y1) * (p[0] - x3) + (x1 - x3) * (p[1] - y3)) / den
        l3 = 1 - l1 - l2
        return (l1 * src_tri[0][0] + l2 * src_tri[1][0] + l3 * src_tri[2][0],
                l1 * src_tri[0][1] + l2 * src_tri[1][1] + l3 * src_tri[2][1])
    return f


def _encolhe(tri, px):
    cx = sum(p[0] for p in tri) / 3
    cy = sum(p[1] for p in tri) / 3
    out = []
    for p in tri:
        d = ((p[0] - cx) ** 2 + (p[1] - cy) ** 2) ** 0.5 or 1
        k = max(0.0, (d - px) / d)
        out.append((cx + (p[0] - cx) * k, cy + (p[1] - cy) * k))
    return out


def retifica_escada(src):
    src = src.convert("RGBA")
    sp = src.load()
    A, B, C, D, B0 = vertices_escada(src)
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    op = out.load()
    m = mascara_escada().load()
    partes = [((E_A, E_B, E_C), (A, B, C)), ((E_A, E_C, E_D), (A, C, D)), ((E_B, E_B0, E_C), (B, B0, C))]
    mapas = [(dst, _afim(_encolhe(s, MARGEM), dst)) for dst, s in partes]
    for y in range(H):
        for x in range(W):
            if not m[x, y]:
                continue
            p = (x + 0.5, y + 0.5)
            for dst, f in mapas:
                if _dentro_tri(p, *dst):
                    sx, sy = f(p)
                    op[x, y] = sp[min(max(int(sx), 0), src.width - 1), min(max(int(sy), 0), src.height - 1)]
                    break
    return out


# ---------------------------------------------------------------- transição entre tipos de chão
# O tipo de chão é dado nos VÉRTICES do grid (cantos dos tiles). Dentro do tile, a mistura dos
# 4 cantos + um ruído calculado em coordenada de MUNDO decide, pixel a pixel, qual textura
# aparece. Como o ruído é do mundo, a borda irregular continua certinha de um tile pro outro:
# não precisa desenhar os 16 tiles de canto de cada par.
def _ruido(x, y, s=0):
    import math
    def h(ix, iy):
        n = (ix * 374761393 + iy * 668265263 + s * 982451653) & 0xFFFFFFFF
        n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
        return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0
    def suave(x, y):
        ix, iy = math.floor(x), math.floor(y)
        fx, fy = x - ix, y - iy
        fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
        a, b = h(ix, iy), h(ix + 1, iy)
        c, d = h(ix, iy + 1), h(ix + 1, iy + 1)
        return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy
    return 0.6 * suave(x * 2.3, y * 2.3) + 0.4 * suave(x * 5.1, y * 5.1)


def topo_misto(i, j, cantos, texturas, fundo_de):
    """cantos: tipos nos vértices (NO, NE, SE, SO) = (i,j) (i+1,j) (i+1,j+1) (i,j+1).
    texturas: tipo -> imagem de topo já escolhida pra este tile. fundo_de: ordem de prioridade
    (o tipo que "cobre" o outro na borda vem depois na lista)."""
    tipos = sorted(set(cantos), key=fundo_de.index)
    if len(tipos) == 1:
        return texturas[tipos[0]]
    out = texturas[tipos[0]].copy()
    op = out.load()
    mt = mascara_topo().load()
    for t in tipos[1:]:
        tp = texturas[t].load()
        w = [1.0 if c == t else 0.0 for c in cantos]
        for y in range(32):
            for x in range(W):
                if not mt[x, y]:
                    continue
                X, Y = x + 0.5, y + 0.5
                u = min(max(((X - 32) / 32 + Y / 16) / 2, 0), 1)   # ao longo de i
                v = min(max(((32 - X) / 32 + Y / 16) / 2, 0), 1)   # ao longo de j
                m = (w[0] * (1 - u) * (1 - v) + w[1] * u * (1 - v) + w[2] * u * v + w[3] * (1 - u) * v)
                if m + 0.55 * (_ruido(i + u, j + v, len(t)) - 0.5) > 0.5:
                    op[x, y] = tp[x, y]
    return out


def escurece(img, f):
    if f >= 0.999:
        return img
    r, g, b, a = img.split()
    return Image.merge("RGBA", [c.point(lambda v: int(v * f)) for c in (r, g, b)] + [a])
