"""Bloco 111: tira os traços de "efeito" que o v3 desenha soltos do corpo (arcos e rabiscos brancos, fumaça): em cada quadro
fica só a maior mancha conectada (o boneco) e as manchas grudadas nela; o que está solto e é pequeno sai.

  python limpa_soltos.py <pasta da animação> <direções...>     ex.: python limpa_soltos.py crianca_m/ferido NE NO
"""
import os, sys
import numpy as np
from PIL import Image
from collections import deque


def limpa(path, min_frac=0.08):
    im = Image.open(path).convert("RGBA")
    a = np.array(im)
    ok = a[..., 3] > 0
    H, W = ok.shape
    lab = np.zeros((H, W), int)
    comps = []
    n = 0
    for y in range(H):
        for x in range(W):
            if ok[y, x] and not lab[y, x]:
                n += 1
                q = deque([(y, x)])
                lab[y, x] = n
                tam = 0
                while q:
                    cy, cx = q.popleft()
                    tam += 1
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < H and 0 <= nx < W and ok[ny, nx] and not lab[ny, nx]:
                                lab[ny, nx] = n
                                q.append((ny, nx))
                comps.append((tam, n))
    if not comps:
        return 0
    comps.sort(reverse=True)
    maior = comps[0][0]
    tirou = 0
    for tam, c in comps[1:]:
        if tam < maior * min_frac:
            a[lab == c, 3] = 0
            tirou += tam
    Image.fromarray(a).save(path)
    return tirou


if __name__ == "__main__":
    pasta, dirs = sys.argv[1], sys.argv[2:]
    for d in dirs:
        p = os.path.join(pasta, d)
        t = 0
        for f in sorted(os.listdir(p)):
            if f.endswith(".png"):
                t += limpa(os.path.join(p, f))
        print(pasta, d, "pixels soltos tirados:", t)
