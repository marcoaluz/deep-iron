"""Bloco 95: o ícone "sem ferramenta" = a picareta do PixelLab (candidato c09) com o cabo partido. O PixelLab não
desenhou a picareta quebrada em nenhum dos 64 candidatos; o corte é feito aqui, à mão, sem gerar de novo.
  python quebra_picareta.py -> _cand/sem_ferramenta/quebrada.png (depois: ui95.py escolhe sem_ferramenta=quebrada)
"""
import os
import numpy as np
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
CONTORNO = (22, 18, 16, 255)
a = np.array(Image.open(os.path.join(AQUI, "_cand", "sem_ferramenta", "c09.png")).convert("RGBA"))
h, w = a.shape[:2]
out = np.zeros_like(a)
for y in range(h):
    for x in range(w):
        s = x + y
        if a[y, x, 3] < 100 or s in (35, 36):  # o vão do cabo partido
            continue
        if s <= 34:  # a cabeça e o toco do cabo ficam no lugar
            out[y, x] = CONTORNO if s == 34 else a[y, x]
        else:  # o pedaço solto cai um pouco pra baixo
            ny, nx = y + 3, x + 1
            if ny < h and nx < w:
                out[ny, nx] = CONTORNO if s == 37 else a[y, x]
Image.fromarray(out, "RGBA").save(os.path.join(AQUI, "_cand", "sem_ferramenta", "quebrada.png"))
Image.fromarray(out, "RGBA").resize((w * 8, h * 8), Image.NEAREST).save(os.path.join(AQUI, "_cand", "_quebrada_8x.png"))
print("ok")
