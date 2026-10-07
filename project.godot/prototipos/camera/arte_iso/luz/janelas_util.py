"""Prompt 19: achar o vidro das janelas no desenho dos prédios (sem scipy)."""
import numpy as np


def hsv(a):
    rgb = a[..., :3] / 255.0
    mx = rgb.max(-1); mn = rgb.min(-1); dl = mx - mn; dd = np.where(dl == 0, 1, dl)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    h = np.where(dl == 0, 0, np.where(mx == r, ((g - b) / dd) % 6, np.where(mx == g, (b - r) / dd + 2, (r - g) / dd + 4))) * 60
    s = np.where(mx == 0, 0, dl / np.where(mx == 0, 1, mx))
    return h, s, mx


def componentes(m):
    """Componentes 4-conectados de uma máscara booleana: lista de (ys, xs)."""
    m = m.copy(); H, W = m.shape; out = []
    for y0, x0 in zip(*np.nonzero(m)):
        if not m[y0, x0]:
            continue
        pilha = [(y0, x0)]; m[y0, x0] = False; ys = []; xs = []
        while pilha:
            y, x = pilha.pop(); ys.append(y); xs.append(x)
            for yy, xx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= yy < H and 0 <= xx < W and m[yy, xx]:
                    m[yy, xx] = False; pilha.append((yy, xx))
        out.append((np.array(ys), np.array(xs)))
    return out


def vidro_ambar(a, min_px=4, max_px=160, max_w=22, max_h=26, contraste=0.12):
    """Vidro de janela/lampião âmbar aceso: tom quente (25–42°), saturado, CLARO (v >= 0,48: a
    madeira de porta fica em ~0,38), em manchas pequenas e mais claras que a moldura em volta."""
    h, s, v = hsv(a.astype(float))
    m = (a[..., 3] > 40) & (h >= 25) & (h <= 42) & (s > 0.42) & (v >= 0.48) & (v < 0.9)
    keep = np.zeros(m.shape, bool)
    H, W = m.shape
    for ys, xs in componentes(m):
        w = xs.max() - xs.min() + 1; hh = ys.max() - ys.min() + 1
        if not (min_px <= len(ys) <= max_px and w <= max_w and hh <= max_h):
            continue
        y0, y1 = max(ys.min() - 2, 0), min(ys.max() + 3, H); x0, x1 = max(xs.min() - 2, 0), min(xs.max() + 3, W)
        caixa = np.zeros(m.shape, bool); caixa[y0:y1, x0:x1] = True
        dentro = np.zeros(m.shape, bool); dentro[ys, xs] = True
        anel = caixa & ~dentro & (a[..., 3] > 40)
        if anel.any() and v[dentro].mean() - v[anel].mean() >= contraste:
            keep[ys, xs] = True
    return keep
