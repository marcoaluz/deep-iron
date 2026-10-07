"""Prompt 18: texturas de PARTÍCULA (pequenas, em faixas de cor, no tamanho de arte) e quadros
de efeito feitos por script. As nuvens grandes (fumaça, gás, poeira), a folha, o brilho de achado
e a martelada vêm do PixelLab (efeitos/particulas/*.png, pixen).

  python efeitos/particulas.py   -> assets/game/iso/fx/*.png

Textura CINZA (tingível): a cor vem da partícula do jogo (fumaça, poeira, lascas, gota, neve).
Textura COLORIDA: já vem na cor (faísca, brasa, confete, radiação).
"""
import os, math, random
import numpy as np
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
FX = os.path.normpath(os.path.join(AQUI, "../../../../assets/game/iso/fx"))
PX = os.path.join(AQUI, "particulas")
os.makedirs(FX, exist_ok=True)


def salva(nome, a):
    Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA").save(os.path.join(FX, nome + ".png"))


def disco(n, r, cx=None, cy=None, faixas=((1.0, 255),), borda=None, sy=1.0):
    """Disco em faixas: [(raio relativo, valor)] do maior pro menor; luz de cima-esquerda."""
    a = np.zeros((n, n, 4), np.float32)
    cx = (n - 1) / 2.0 if cx is None else cx
    cy = (n - 1) / 2.0 if cy is None else cy
    yy, xx = np.mgrid[0:n, 0:n]
    d = np.sqrt((xx - cx) ** 2 + ((yy - cy) / sy) ** 2) / r
    dl = np.sqrt((xx - cx + r * 0.35) ** 2 + ((yy - cy + r * 0.35) / sy) ** 2) / r  # luz
    m = d <= 1.0
    v = np.full((n, n), faixas[0][1], np.float32)
    for rr, val in faixas[1:]:
        v = np.where(dl <= rr, val, v)
    a[..., 0] = a[..., 1] = a[..., 2] = v
    a[..., 3] = np.where(m, 255, 0)
    if borda is not None:
        op = a[..., 3] > 0
        pad = np.pad(op, 1)
        inner = pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:]
        b = op & ~inner
        for k in range(3):
            a[..., k] = np.where(b, a[..., k] * borda, a[..., k])
    return a


def cor(a, rgb):
    out = a.copy()
    for k in range(3):
        out[..., k] = a[..., k] / 255.0 * rgb[k]
    return out


# ---- trabalho
salva("faisca", cor(disco(5, 2.4, faixas=((1, 200), (0.75, 255))), (255, 190, 90)))            # 5 px
f = np.zeros((7, 3, 4), np.float32)                                                               # faísca riscada
f[0:2, 1] = (255, 120, 40, 140); f[2:5, 1] = (255, 190, 90, 255); f[5:7, 1] = (255, 245, 200, 255)
salva("faisca_risco", f)
salva("brasa", cor(disco(4, 1.9, faixas=((1, 170), (0.6, 255))), (255, 110, 40)))
la = np.zeros((5, 5, 4), np.float32)                                                              # lasca de pedra (cinza)
for (y, x, v) in [(0, 2, 230), (1, 1, 210), (1, 2, 240), (1, 3, 170), (2, 0, 190), (2, 1, 200), (2, 2, 180), (2, 3, 150), (3, 1, 150), (3, 2, 120), (4, 2, 90)]:
    la[y, x] = (v, v, v, 255)
salva("lasca", la)
se = np.zeros((4, 6, 4), np.float32)                                                              # serragem (lasca de madeira)
for (y, x, v) in [(0, 1, 230), (0, 2, 240), (1, 2, 220), (1, 3, 200), (2, 3, 180), (2, 4, 150), (3, 4, 120)]:
    se[y, x] = (v, v, v, 255)
salva("serragem", cor(se, (210, 160, 100)))
salva("poeira", disco(9, 4.3, faixas=((1, 150), (0.85, 190), (0.45, 225))))                     # cinza, tingível
salva("poeira_p", disco(5, 2.4, faixas=((1, 160), (0.6, 215))))
# ---- fogo e fumaça
salva("fumaca", disco(13, 6.2, faixas=((1, 140), (0.9, 180), (0.55, 215)), borda=0.8))          # cinza, tingível
salva("fumaca_p", disco(8, 3.8, faixas=((1, 150), (0.7, 205))))
salva("vapor", disco(9, 4.3, faixas=((1, 225), (0.6, 250))))
# ---- mina
g = disco(5, 2.4, faixas=((1, 170), (0.5, 255))); salva("radiacao", cor(g, (190, 255, 110)))
go = np.zeros((5, 3, 4), np.float32)
go[0, 1] = (200, 200, 200, 160); go[1, 1] = (220, 220, 220, 255); go[2, :] = (210, 210, 210, 255); go[3, :] = (240, 240, 240, 255); go[4, 1] = (180, 180, 180, 255)
salva("gota", go)
pc = disco(6, 2.9, faixas=((1, 70), (0.6, 120)), borda=0.5)                                      # pedrinha caindo
salva("pedra", cor(pc, (150, 140, 128)))
# ---- clima
ch = np.zeros((6, 2, 4), np.float32)
ch[0:2, 1] = (210, 220, 235, 120); ch[2:4, 1] = (220, 230, 245, 200); ch[4:6, 0] = (240, 245, 255, 255)
salva("chuva", ch)
ne = np.zeros((5, 5, 4), np.float32)
for (y, x) in [(0, 2), (1, 1), (1, 3), (2, 0), (2, 2), (2, 4), (3, 1), (3, 3), (4, 2)]:
    ne[y, x] = (245, 248, 255, 255)
ne[2, 2] = (255, 255, 255, 255)
salva("neve", ne)
salva("neve_p", disco(3, 1.4, faixas=((1, 255),)))
salva("polen", cor(disco(3, 1.4, faixas=((1, 255),)), (255, 240, 150)))
# neblina: faixa larga e mole (tingível), alfa em faixas
nw, nh = 96, 24
yy, xx = np.mgrid[0:nh, 0:nw]
d = np.sqrt(((xx - nw / 2) / (nw / 2)) ** 2 + ((yy - nh / 2) / (nh / 2)) ** 2)
al = np.where(d < 0.45, 120, np.where(d < 0.7, 80, np.where(d < 1.0, 40, 0)))
nb = np.zeros((nh, nw, 4), np.float32); nb[..., :3] = 235; nb[..., 3] = al
salva("neblina", nb)
# ---- festa
random.seed(7)
for k, rgb in enumerate([(200, 70, 60), (230, 190, 80), (90, 170, 160), (220, 220, 210)]):
    c = np.zeros((3, 3, 4), np.float32); c[0:2, 0:3] = (*rgb, 255); c[2, 0:2] = (*[v * 0.6 for v in rgb], 255)
    salva("confete_%d" % k, c)
salva("fogos", cor(disco(3, 1.4, faixas=((1, 255),)), (255, 255, 255)))  # brilho branco (a cor vem da partícula)
# ---- interface no mundo (iso): anel de seleção, marcador de destino, obra válida/inválida
def elipse_anel(w, h, rx, ry, cor_luz, cor_sombra, tracejado=0):
    a = np.zeros((h, w, 4), np.float32)
    cx, cy = (w - 1) / 2.0, (h - 1) / 2.0
    for k in range(720):
        t = k / 720.0 * 2 * math.pi
        if tracejado and int(k / (720 / tracejado)) % 2:
            continue
        x, y = int(round(cx + rx * math.cos(t))), int(round(cy + ry * math.sin(t)))
        if 0 <= x < w and 0 <= y + 1 < h:
            if a[y + 1, x, 3] == 0:
                a[y + 1, x] = (*cor_sombra, 255)
            a[y, x] = (*cor_luz, 255)
    return a


salva("anel_selecao", elipse_anel(44, 24, 20, 10, (255, 214, 90), (60, 40, 10)))
fr = []
for k in range(6):  # o anel encolhe e a setinha desce até o chão
    t = k / 5.0
    q = np.zeros((40, 40, 4), np.float32)
    rx = 18 - 12 * t
    an = elipse_anel(40, 22, rx, rx / 2.0, (255, 214, 90), (60, 40, 10))
    q[18:40] = an
    y0 = int(2 + 10 * t)
    for i, half in enumerate([4, 3, 2, 1]):  # seta (triângulo) apontando pra baixo
        for x in range(20 - half, 20 + half):
            q[y0 + i, x] = (255, 214, 90, 255)
        q[y0 + i, 20 - half - 1] = (60, 40, 10, 255); q[y0 + i, 20 + half] = (60, 40, 10, 255)
    q[y0 + 4, 19:21] = (60, 40, 10, 255)
    fr.append(q)
salva("marcador_destino", np.concatenate(fr, axis=1))
ok = np.zeros((11, 11, 4), np.float32)
for (x, y) in [(2, 5), (3, 6), (4, 7), (5, 6), (6, 5), (7, 4), (8, 3)]:
    ok[y, x] = ok[y + 1, x] = (120, 230, 110, 255)
    ok[y + 2, x] = (20, 50, 20, 255)
salva("obra_ok", ok)
xx = np.zeros((11, 11, 4), np.float32)
for i in range(2, 9):
    for (x, y) in [(i, i), (10 - i, i)]:
        xx[y, x] = (240, 80, 60, 255)
        if y + 1 < 11 and xx[y + 1, x, 3] == 0:
            xx[y + 1, x] = (60, 15, 10, 255)
salva("obra_x", xx)

# ---- as nuvens grandes e os detalhes gerados (pixen): recortadas no desenho
for nome, dest in [("fumaca", "nuvem_fumaca"), ("gas", "nuvem_gas"), ("poeira", "nuvem_poeira"), ("folha", "folha"),
                   ("brilho_achado", "brilho_achado"), ("martelada", "martelada")]:
    im = Image.open(os.path.join(PX, nome + ".png")).convert("RGBA")
    im = im.crop(im.getbbox())
    im.save(os.path.join(FX, dest + ".png"))
print("fx:", len(os.listdir(FX)), "arquivos em", FX)
