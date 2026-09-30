"""PROTÓTIPO: reduz um item de pixel art grande pro tamanho do jogo sem virar borrão:
reduz com filtro, volta cada cor pra paleta do próprio item (cores com >= 4 px) e refaz o
contorno escuro de 1 px (o contorno escuro mais comum do original).

  python reduz.py <entrada.png> <saida.png> <lado_maior_px>
"""
import sys
from collections import Counter
from PIL import Image


def reduz(im, lado):
    im = im.convert("RGBA")
    b = im.getbbox(); im = im.crop(b)
    f = lado / max(im.size)
    w, h = max(1, round(im.width * f)), max(1, round(im.height * f))
    pal = [c for c, n in Counter(p[:3] for p in im.get_flattened_data() if p[3] > 200).items() if n >= 4]
    esc = sorted(pal, key=lambda c: sum(c))[:3]
    contorno = min(esc, key=lambda c: sum(c)) if esc else (20, 16, 14)
    peq = im.resize((w, h), Image.LANCZOS)
    px = peq.load()
    out = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0)); op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, bb, a = px[x, y]
            if a < 110:
                continue
            c = min(pal, key=lambda q: (q[0] - r) ** 2 + (q[1] - g) ** 2 + (q[2] - bb) ** 2)
            op[x + 1, y + 1] = c + (255,)
    # contorno: pixel vazio encostado (4-vizinho) num cheio
    cheio = {(x, y) for y in range(h + 2) for x in range(w + 2) if op[x, y][3] > 0}
    for x, y in list(cheio):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy)
            if q not in cheio and 0 <= q[0] < w + 2 and 0 <= q[1] < h + 2:
                op[q] = contorno + (255,)
    return out


if __name__ == "__main__":
    reduz(Image.open(sys.argv[1]), int(sys.argv[3])).save(sys.argv[2])
