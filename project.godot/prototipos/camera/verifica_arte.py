"""PROTÓTIPO ROTA A — verificador de ARTE contra o contrato (ENDURECIMENTO_rota_A.md, seção 7).

Confere, sem Godot, o que a ordenação por caixas precisa da arte:
  regra 2  o desenho cabe na CAIXA declarada (pegada L x P no chão + altura A), vista em
           isométrico 2:1 com a âncora no centro da pegada
  regra 3  âncora: onde estão os pés (base) em cada quadro, e quanto ela treme
  regra 4  espelho: a direção gerada do outro lado bate com o espelho (ou não precisa dela)

Uso:
  python verifica_arte.py <pasta com PNGs> [--caixa L,P,A] [--escala 1.0]
  (sem --caixa, ele sugere a menor caixa quadrada que contém todos os quadros)

A caixa é em unidades de CHÃO; --escala = unidades de chão por pixel da arte.
"""
import sys, os, glob, json, math
from PIL import Image


def opaque(im):
    im = im.convert("RGBA")
    px = im.load()
    return [(x, y) for y in range(im.height) for x in range(im.width) if px[x, y][3] > 40]


def feet(pts):
    """Âncora = ponto do chão embaixo dos pés: linha mais baixa + centro das 3 linhas de baixo."""
    ymax = max(y for _, y in pts)
    low = [x for x, y in pts if y >= ymax - 2]
    return (sum(low) / len(low), ymax + 1)


def iso(x, y, z=0.0):
    return (x - y, (x + y) * 0.5 - z)


def hexagon(L, P, A):
    """Contorno na tela da caixa com a pegada centrada na âncora (0, 0)."""
    c = [(-L / 2, -P / 2), (L / 2, -P / 2), (L / 2, P / 2), (-L / 2, P / 2)]
    pts = [iso(x, y, 0) for x, y in c] + [iso(x, y, A) for x, y in c]
    return convex_hull(pts)


def convex_hull(pts):
    pts = sorted(set(pts))
    if len(pts) < 3:
        return pts
    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def inside(poly, p):
    # polígono convexo, sentido anti-horário (monotone chain)
    n = len(poly)
    for i in range(n):
        a, b = poly[i], poly[(i + 1) % n]
        if (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0]) < -1e-9:
            return False
    return True


def outside_count(pts, anchor, box, scale):
    L, P, A = box
    poly = hexagon(L, P, A)
    out = 0
    for x, y in pts:
        # centro do pixel, relativo à âncora, em unidades de chão-tela
        sx = (x + 0.5 - anchor[0]) * scale
        sy = (y + 0.5 - anchor[1]) * scale
        if not inside(poly, (sx, sy)):
            out += 1
    return out


def smallest_box(frames, scale):
    """Menor caixa QUADRADA (L = P) e a altura A que contêm todos os quadros."""
    best = None
    for L in range(4, 200, 2):
        # altura mínima pra esse L (busca binária)
        lo, hi = 0.0, 400.0
        if any(outside_count(p, a, (L, L, hi), scale) for p, a in frames):
            continue
        for _ in range(20):
            mid = (lo + hi) / 2
            if any(outside_count(p, a, (L, L, mid), scale) for p, a in frames):
                lo = mid
            else:
                hi = mid
        vol = L * L * hi
        if best is None or vol < best[3]:
            best = (L, L, math.ceil(hi), vol)
        if best and L > best[0] + 20:
            break
    return best[:3] if best else None


def main():
    args = sys.argv[1:]
    folder = args[0]
    box = None
    scale = 1.0
    if "--caixa" in args:
        box = tuple(float(v) for v in args[args.index("--caixa") + 1].split(","))
    if "--escala" in args:
        scale = float(args[args.index("--escala") + 1])
    files = sorted(glob.glob(os.path.join(folder, "**", "*.png"), recursive=True))
    frames = []
    report = {"quadros": [], "caixa": None}
    for f in files:
        pts = opaque(Image.open(f))
        if not pts:
            continue
        a = feet(pts)
        frames.append((pts, a))
        report["quadros"].append({"arquivo": os.path.relpath(f, folder), "ancora": [round(a[0], 1), a[1]],
                                  "pixels": len(pts)})
    if not frames:
        print("nenhum quadro")
        return
    ax = [a[0] for _, a in frames]
    ay = [a[1] for _, a in frames]
    print("=== %s: %d quadros ===" % (folder, len(frames)))
    print("regra 3  âncora (pés): x %.1f..%.1f  y %d..%d  -> treme %.1f px na horizontal, %d na vertical" % (
        min(ax), max(ax), min(ay), max(ay), max(ax) - min(ax), max(ay) - min(ay)))
    sug = smallest_box(frames, scale)
    print("regra 2  menor caixa que contém tudo (L x P x A, em unidades de chão): %s" % (sug,))
    if box:
        tot = sum(len(p) for p, _ in frames)
        out = sum(outside_count(p, a, box, scale) for p, a in frames)
        worst = max((outside_count(p, a, box, scale), f["arquivo"]) for (p, a), f in zip(frames, report["quadros"]))
        print("regra 2  caixa declarada %s: %d de %d pixels FORA (%.2f%%); pior quadro: %s (%d px)" % (
            box, out, tot, 100.0 * out / tot, worst[1], worst[0]))
        report["caixa"] = {"declarada": box, "fora": out, "total": tot}
    report["sugerida"] = sug
    json.dump(report, open(os.path.join(folder, "verificacao.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
