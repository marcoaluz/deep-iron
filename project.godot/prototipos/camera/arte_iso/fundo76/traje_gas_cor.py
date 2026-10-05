"""Bloco 76: a caminhada de 8 quadros do traje_gas_m saiu (2 vezes, nas 2 direções) com um colete marrom e a
calça cinza por cima do traje amarelo — a pose parada (rotações) é o traje amarelo inteiro. Aqui os marrons do
tronco e os cinzas das pernas viram os tons do amarelo da rotação da mesma direção (pelo brilho); capacete,
máscara, luvas, botas e o contorno ficam.

  python traje_gas_cor.py <pasta com caminhada/SE e caminhada/NE>   (reescreve os quadros no lugar)
"""
import glob, os, sys
import numpy as np
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
ROT = os.path.join(AQUI, "..", "traje_gas_m", "rotacoes")


def hsv(a):
    r, g, b = a[..., 0] / 255, a[..., 1] / 255, a[..., 2] / 255
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    d = mx - mn + 1e-6
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    s = np.where(mx > 0, d / (mx + 1e-6), 0)
    return h, s, mx


def paleta(rot_png):
    f0 = np.array(Image.open(rot_png).convert("RGBA")).astype(float)
    h0, s0, _ = hsv(f0)
    am = (f0[..., 3] > 0) & (h0 > 38) & (h0 < 60) & (s0 > 0.55)
    pal = f0[am][:, :3]
    lum = pal @ np.array([0.3, 0.59, 0.11])
    o = np.argsort(lum)
    return pal[o], lum[o]


def corrige(a, pal, lum):
    h, s, v = hsv(a)
    ys, _ = np.nonzero(a[..., 3] > 0)
    top, bot = ys.min(), ys.max()
    y = np.arange(a.shape[0])[:, None] * np.ones((1, a.shape[1]))
    corpo = (y > top + 18) & (y < bot - 9)
    pernas = (y > top + (bot - top) * 0.55) & (y < bot - 9)
    ja = (h > 38) & (h < 62) & (s > 0.5)
    alvo = (a[..., 3] > 0) & ((corpo & (h > 8) & (h < 42) & (s > 0.18) & (v < 0.7))
                              | (pernas & (s <= 0.35) & (v > 0.17) & (v < 0.62) & ~ja))
    l = a[..., :3] @ np.array([0.3, 0.59, 0.11])
    lm = l[alvo]
    if len(lm):
        t = np.clip((lm - np.percentile(lm, 3)) / max(1.0, np.percentile(lm, 97) - np.percentile(lm, 3)), 0, 1)
        idx = np.clip(np.searchsorted(lum, lum.min() + t * (np.percentile(lum, 85) - lum.min())), 0, len(lum) - 1)
        a = a.copy()
        a[alvo, :3] = pal[idx]
    return a


def main(pasta):
    for d, rot in (("SE", "south-east"), ("NE", "north-east")):
        pal, lum = paleta(os.path.join(ROT, rot + ".png"))
        for f in glob.glob(os.path.join(pasta, "caminhada", d, "*.png")):
            a = np.array(Image.open(f).convert("RGBA")).astype(float)
            Image.fromarray(corrige(a, pal, lum).astype(np.uint8)).save(f)
        print(d, "corrigido")


if __name__ == "__main__":
    main(sys.argv[1])
