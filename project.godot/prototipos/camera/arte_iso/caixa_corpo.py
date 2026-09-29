"""PROTÓTIPO: grava em <pasta>/contrato.json a "caixa_corpo": a menor caixa que deixa até 0,5%
dos pixels da caminhada de fora. A "caixa" estrita (<= 4 px fora) cresce muito quando a
ferramenta sai do corpo (ponta do machado, aljava); pra ordenação, a de corpo basta: o que fica
fora é ponta fina de ferramenta.
  python caixa_corpo.py <pasta> [<pasta> ...]
"""
import sys, json
import numpy as np
from PIL import Image

TOL = 0.005
for p in sys.argv[1:]:
    c = json.load(open(p + "/contrato.json"))
    pts = []
    for d in ("SE", "NE", "SO", "NO"):
        ax, ay = c["direcoes"][d]["ancora"]
        for i in range(4):
            a = np.array(Image.open("%s/caminhada/%s/%d.png" % (p, d, i)).convert("RGBA"))
            ys, xs = np.nonzero(a[..., 3] > 40)
            pts.append((xs + .5 - ax, ys + .5 - ay))
    sx = np.concatenate([q[0] for q in pts]); sy = np.concatenate([q[1] for q in pts])

    def fora(L, H):
        umin = np.maximum(-L - sx, -L + sx); umax = np.minimum(L - sx, L + sx)
        lo = np.maximum(umin, 2 * sy); hi = np.minimum(umax, 2 * (sy + H))
        return int((lo > hi).sum())
    best = None
    for L in range(20, 60, 2):
        for H in range(50, 110, 2):
            if fora(L / 2, H) <= TOL * len(sx):
                if best is None or L * L * H < best[0] ** 2 * best[1]:
                    best = (L, H)
                break
    c["caixa_corpo"] = [best[0], best[0], best[1]]
    c["caixa_corpo_pixels_fora"] = fora(best[0] / 2, best[1])
    json.dump(c, open(p + "/contrato.json", "w"), indent=1)
    print("%-14s estrita %-12s corpo %s" % (p, "x".join(map(str, c["caixa"])), "x".join(map(str, c["caixa_corpo"]))))
