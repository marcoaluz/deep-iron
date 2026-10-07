"""Bloco 74: o material da MONTANHA da mina (maquete v3) — a pedra em blocos da `rocha`, que era azulada
("lia como água"), levada pra um cinza quente de pedra (a cor da montanha na maquete do Blender).

  python montanha.py   -> final/montanha/bloco*.png, bloco_sem_beira*.png, chao_*.png

Troca só a cor: cada pixel vai pra mesma claridade numa rampa de pedra (escuro marrom-acinzentado ->
claro bege-acinzentado); o contorno quase preto continua.
"""
import glob, os
import numpy as np
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
DE = os.path.join(AQUI, "final", "rocha")
PARA = os.path.join(AQUI, "final", "montanha")
# rampa da pedra: (claridade 0..1 -> cor)
RAMPA = [(0.00, (14, 12, 11)), (0.20, (40, 35, 31)), (0.45, (74, 66, 57)), (0.70, (112, 101, 86)), (1.00, (160, 148, 128))]


def cor(l):
    for (a, ca), (b, cb) in zip(RAMPA, RAMPA[1:]):
        if l <= b:
            t = (l - a) / (b - a)
            return [ca[k] + (cb[k] - ca[k]) * t for k in range(3)]
    return list(RAMPA[-1][1])


def recolore(im):
    a = np.array(im.convert("RGBA")).astype(float)
    rgb = a[..., :3]
    lum = (0.30 * rgb[..., 0] + 0.59 * rgb[..., 1] + 0.11 * rgb[..., 2]) / 110.0  # a rocha vai até ~100
    lum = np.clip(lum, 0.0, 1.0)
    tab = np.array([cor(v / 255.0) for v in range(256)])
    out = tab[(lum * 255).astype(int)]
    a[..., :3] = out
    return Image.fromarray(a.astype(np.uint8), "RGBA")


if __name__ == "__main__":
    os.makedirs(PARA, exist_ok=True)
    n = 0
    for f in sorted(glob.glob(os.path.join(DE, "*.png"))):
        recolore(Image.open(f)).save(os.path.join(PARA, os.path.basename(f)))
        n += 1
    print(n, "->", PARA)
