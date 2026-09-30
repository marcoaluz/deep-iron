"""PROTÓTIPO: prédios isométricos no contrato de 7 regras (guia 2:1, caixa declarada, âncora).

  python predio.py guia <pasta> <largura_x> <fundo_y> <altura> [sobra_topo] [porta_larg porta_alt]
      -> <pasta>/predio.json (quadro, âncora, caixa declarada) e imprime a receita do desenho
         da guia pro pixelart_workbench (linhas cinza da caixa + porta amarela na parede SO)
  python predio.py caixa <pasta> <img> [<img> ...]
      -> encaixa a caixa de cada desenho com a PAREDE DE TRÁS FIXA (a da guia) e grava em
         <pasta>/contrato.json; imprime pegada, altura e pixels fora

Convenções (as mesmas da casa, checkpoint 2):
- mundo: x desce pra direita, y desce pra esquerda; iso(x, y, z) = (x - y, (x + y)/2 - z)
- a pegada é centrada na âncora; a parede SO (y máximo) é a comprida da frente-esquerda,
  a SE (x máximo) é a da frente-direita; a porta fica na SO
- quadro = (largura + fundo + 2m) x ((largura + fundo)/2 + altura + sobra + 2m), m = 5
"""
import sys, os, json
import numpy as np
from PIL import Image

M = 5


def iso(x, y, z=0.0):
    return (x - y, (x + y) / 2.0 - z)


def geometria(fw, fd, h, sobra=0):
    W = int(round(fw + fd + 2 * M))
    H = int(round((fw + fd) / 2 + h + sobra + 2 * M))
    ax = M + (fw + fd) / 2.0
    ay = M + sobra + h + (fw + fd) / 4.0
    return W, H, ax, ay


def guia(pasta, fw, fd, h, sobra=0, porta=None):
    W, H, ax, ay = geometria(fw, fd, h, sobra)
    P = lambda x, y, z: [int(round(ax + iso(x, y, z)[0])), int(round(ay + iso(x, y, z)[1]))]
    x0, x1, y0, y1 = -fw / 2, fw / 2, -fd / 2, fd / 2
    base = [P(x0, y0, 0), P(x1, y0, 0), P(x1, y1, 0), P(x0, y1, 0), P(x0, y0, 0)]
    topo = [P(x0, y0, h), P(x1, y0, h), P(x1, y1, h), P(x0, y1, h), P(x0, y0, h)]
    draw = [{"op": "path", "points": base, "color": "guide"},
            {"op": "path", "points": topo, "color": "guide"}]
    for (x, y) in ((x0, y0), (x1, y0), (x1, y1), (x0, y1)):
        draw.append({"op": "path", "points": [P(x, y, 0), P(x, y, h)], "color": "guide"})
    if porta:
        pl, ph = porta
        cx = -fw / 4.0
        draw.append({"op": "path", "color": "door", "points": [
            P(cx - pl / 2, y1, 0), P(cx - pl / 2, y1, ph), P(cx + pl / 2, y1, ph), P(cx + pl / 2, y1, 0)]})
    receita = {"job": {"canvas": [W, H], "frame_count": 1, "views": [{"id": "south", "offset": [0, 0]}],
                       "source_bookends_exact": False},
               "scene": {"palette": {"guide": "#c8c8d2", "door": "#ffc850"},
                         "layers": [{"id": "g", "name": "Guide"}],
                         "views": {"south": {"nodes": {"root": {"layer": "g", "at": [0, 0], "draw": draw}}}}}}
    os.makedirs(pasta, exist_ok=True)
    json.dump({"quadro": [W, H], "ancora": [ax, ay], "caixa_guia": [fw, fd, h], "sobra_topo": sobra,
               "porta": porta}, open(os.path.join(pasta, "predio.json"), "w"), indent=1)
    print(json.dumps(receita, separators=(",", ":")))


def _fora(sx, sy, x0, x1, y0, y1, h):
    """pixels (coordenadas relativas à âncora) fora da silhueta da caixa: o hexágono convexo
    dos 8 cantos projetados. Testa pelos 6 semiplanos."""
    cantos = [iso(x, y, z) for x in (x0, x1) for y in (y0, y1) for z in (0, h)]
    pts = np.array(cantos)
    # casco convexo (monotone chain)
    p = sorted(set(map(tuple, pts)))
    def cr(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo, up = [], []
    for q in p:
        while len(lo) >= 2 and cr(lo[-2], lo[-1], q) <= 0:
            lo.pop()
        lo.append(q)
    for q in reversed(p):
        while len(up) >= 2 and cr(up[-2], up[-1], q) <= 0:
            up.pop()
        up.append(q)
    hull = lo[:-1] + up[:-1]
    dentro = np.ones_like(sx, dtype=bool)
    for k in range(len(hull)):
        a, b = hull[k], hull[(k + 1) % len(hull)]
        dentro &= ((b[0] - a[0]) * (sy - a[1]) - (b[1] - a[1]) * (sx - a[0])) >= -0.5
    return int((~dentro).sum())


def caixa(pasta, imgs):
    meta = json.load(open(os.path.join(pasta, "predio.json")))
    ax, ay = meta["ancora"]
    fw, fd, h0 = meta["caixa_guia"]
    x0, y0 = -fw / 2.0, -fd / 2.0          # parede de trás fixa (os 2 lados do fundo)
    cpath = os.path.join(pasta, "contrato.json")
    contrato = json.load(open(cpath)) if os.path.exists(cpath) else {"ancora_no_quadro": [ax, ay], "caixas": {}}
    for f in imgs:
        a = np.array(Image.open(f).convert("RGBA"))
        ys, xs = np.nonzero(a[..., 3] > 40)
        sx, sy = xs + 0.5 - ax, ys + 0.5 - ay
        melhor = None
        for x1 in np.arange(x0 + 20, fw / 2 + 60, 2):
            for y1 in np.arange(y0 + 20, fd / 2 + 60, 2):
                # pixels fora só diminui quando a altura cresce: busca binária da menor altura
                # (antes era linear, ~19 min por prédio)
                hs = np.arange(10, h0 + 160, 2)
                if _fora(sx, sy, x0, x1, y0, y1, hs[-1]) > 4:
                    continue
                lo, hi = 0, len(hs) - 1
                while lo < hi:
                    mid = (lo + hi) // 2
                    if _fora(sx, sy, x0, x1, y0, y1, hs[mid]) <= 4:
                        hi = mid
                    else:
                        lo = mid + 1
                h = hs[lo]
                v = (x1 - x0) * (y1 - y0) * h
                if melhor is None or v < melhor[0]:
                    melhor = (v, x1, y1, h)
        v, x1, y1, h = melhor
        nome = os.path.splitext(os.path.basename(f))[0]
        contrato["caixas"][nome] = {"pegada_rel_ancora": [x0, y0, float(x1), float(y1)], "altura": float(h),
                                    "pegada": [float(x1 - x0), float(y1 - y0)],
                                    "fora": _fora(sx, sy, x0, x1, y0, y1, h)}
        print("%-14s pegada %4.0f x %4.0f  altura %4.0f  fora %d" % (nome, x1 - x0, y1 - y0, h,
                                                                     contrato["caixas"][nome]["fora"]))
    json.dump(contrato, open(cpath, "w"), indent=1)


if __name__ == "__main__":
    if sys.argv[1] == "guia":
        a = sys.argv[2:]
        porta = (float(a[5]), float(a[6])) if len(a) > 6 else None
        guia(a[0], float(a[1]), float(a[2]), float(a[3]), float(a[4]) if len(a) > 4 else 0, porta)
    elif sys.argv[1] == "caixa":
        caixa(sys.argv[2], sys.argv[3:])
