"""PROTÓTIPO: trilhos da mina (Prompt 7) desenhados por script, na geometria exata do tile.

  python trilhos.py  -> final/mina/trilhos/*.png (64x32, só o trilho, fundo transparente)

A IA desenhou trilhos bonitos, mas cortados no quadro e fora do eixo: não encaixavam tile
com tile. Aqui cada pixel do losango vira coordenada de mundo (u ao longo de i, v ao longo
de j, 0..1) e o trilho é calculado lá: as pontas caem sempre no meio da borda.
Cores tiradas dos candidatos da IA (ferro enferrujado e madeira escura do jogo).
Peças: reto_i, reto_j, curva_N/E/S/O (centro da curva no canto N/E/S/O do tile),
cruz, fim_<borda> (para-choque de madeira). Junção = reto + curva sobrepostos.
"""
import os, math
from PIL import Image

W, H = 64, 32
BITOLA = 0.17        # meia bitola (em tile): trilhos a 0,5 ± 0,17
DORM = 0.31          # meio comprimento do dormente
N_DORM = 4           # dormentes por tile no reto
FERRO_CLARO, FERRO, FERRO_ESC = (128, 119, 108), (84, 77, 70), (24, 20, 17)
MAD_CLARA, MAD, MAD_ESC = (112, 90, 70), (86, 68, 52), (40, 30, 24)
OUT = "final/mina/trilhos"


def uv(x, y):
    X, Y = x + 0.5, y + 0.5
    return ((X - 32) / 32 + Y / 16) / 2, (Y / 16 - (X - 32) / 32) / 2


def dentro(u, v):
    return 0 <= u <= 1 and 0 <= v <= 1


def pinta(fn):
    """fn(u, v) -> cor ou None; devolve a imagem 64x32."""
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); px = im.load()
    for y in range(H):
        for x in range(W):
            u, v = uv(x, y)
            if dentro(u, v):
                c = fn(u, v)
                if c:
                    px[x, y] = c + (255,)
    return im


def via(s, t, n_dorm, s_max=1.0):
    """s = posição ao longo da via (0..s_max), t = afastamento do eixo (negativo = lado da luz)."""
    if s < 0 or s > s_max:
        return None
    d = abs(t) - BITOLA
    if abs(d) < 0.035:                       # trilho (~2 px): lado da luz claro, o outro médio
        return FERRO_CLARO if (t < 0) == (d < 0) else FERRO
    if abs(d) < 0.06:                        # contorno escuro do trilho
        return FERRO_ESC
    f = (s * n_dorm) % 1.0
    if abs(t) < DORM and 0.22 < f < 0.78:     # dormente
        if abs(t) > DORM - 0.035 or f > 0.70 or f < 0.27:
            return MAD_ESC
        return MAD_CLARA if f < 0.40 else MAD
    return None


def reto(eixo):
    return pinta(lambda u, v: via(u, v - 0.5, N_DORM) if eixo == "i" else via(v, 0.5 - u, N_DORM))


CANTOS = {"N": (0, 0), "E": (1, 0), "S": (1, 1), "O": (0, 1)}


def curva(canto):
    cu, cv = CANTOS[canto]
    def f(u, v):
        du, dv = u - cu, v - cv
        r = math.hypot(du, dv)
        a = math.atan2(abs(dv), abs(du)) / (math.pi / 2)      # 0..1 ao longo da curva
        return via(a, r - 0.5, 3)
    return pinta(f)


def fim(borda):
    """via entra pela borda dada e termina num para-choque de madeira perto do centro."""
    ret = {"NO": lambda u, v: (u, v - 0.5), "SE": lambda u, v: (1 - u, 0.5 - v),
           "NE": lambda u, v: (v, 0.5 - u), "SO": lambda u, v: (1 - v, u - 0.5)}[borda]
    base = pinta(lambda u, v: via(*ret(u, v), N_DORM, 0.56))
    # para-choque: viga de madeira atravessada, com 4 px de altura (face + topo)
    viga = Image.new("RGBA", (W, H), (0, 0, 0, 0)); vp = viga.load()
    topo = Image.new("RGBA", (W, H), (0, 0, 0, 0)); tp = topo.load()
    for y in range(H):
        for x in range(W):
            u, v = uv(x, y)
            if not dentro(u, v):
                continue
            s, t = ret(u, v)
            if 0.52 < s < 0.64 and abs(t) < 0.30:
                vp[x, y] = MAD_ESC + (255,)
                tp[x, y] = (MAD_CLARA if s < 0.56 else MAD) + (255,)
    out = base.copy()
    for k in range(1, 4):
        out.alpha_composite(viga, (0, -k))
    out.alpha_composite(topo, (0, -4))
    return out


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    pecas = {"reto_i": reto("i"), "reto_j": reto("j")}
    for c in CANTOS:
        pecas["curva_" + c] = curva(c)
    cruz = pecas["reto_i"].copy(); cruz.alpha_composite(pecas["reto_j"]); pecas["cruz"] = cruz
    for b in ("NO", "SE", "NE", "SO"):
        pecas["fim_" + b] = fim(b)
    for n, im in pecas.items():
        im.save("%s/%s.png" % (OUT, n))
    print(len(pecas), "peças")
