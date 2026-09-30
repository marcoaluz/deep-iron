"""PROTÓTIPO: regra de diversidade — o mesmo desenho em 3 tons de pele, por troca de PALETA.

Acha as cores de pele do sprite (tons quentes, saturação média, entre o rosa e o laranja) e
troca cada uma pela cor de mesma luminosidade relativa numa rampa de pele alvo. Não gera nada
no PixelLab: no jogo isso vira um shader/tabela de troca de cor por ipezinho.

  python tons_de_pele.py <sprite.png> <saida.png>
"""
import sys, colorsys
from PIL import Image

# rampas (escuro -> claro), no mesmo espírito "gasto" da paleta do jogo: fonte única em
# paletas_pele.json (o jogo lê o mesmo arquivo na integração)
import json as _json, os as _os
_P = _json.load(open(_os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "paletas_pele.json"), encoding="utf-8"))
RAMPAS = {k: [tuple(c) for c in v] for k, v in _P["rampas"].items()}
LUM_PELE = tuple(_P["luminosidade_da_pele"])   # faixa de luminosidade da pele (sombra -> luz)


def is_skin(r, g, b):
    h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    return 0.0 <= h <= 0.11 and 0.18 <= l <= 0.82 and 0.18 <= s <= 0.75 and r > g > b


def skin_colors(face_im):
    """As cores de pele saem do ROSTO (a faixa da cabeça abaixo do capacete/touca), não do
    corpo todo: capacete laranja, colete e luvas também são tons quentes."""
    im = face_im.convert("RGBA")
    bb = im.getbbox()
    px = im.load()
    h = bb[3] - bb[1]
    y0, y1 = bb[1] + int(h * 0.10), bb[1] + int(h * 0.30)
    cols = {}
    for y in range(y0, y1):
        for x in range(bb[0], bb[2]):
            p = px[x, y]
            if p[3] > 40 and is_skin(*p[:3]):
                hh, l, ss = colorsys.rgb_to_hls(*(v / 255 for v in p[:3]))
                if ss <= 0.6:
                    cols[p[:3]] = cols.get(p[:3], 0) + 1
    # roupa marrom pode ter o MESMO rgb da pele (colete, capa, xadrez, contorno escuro): a cor que
    # aparece mais no corpo (abaixo da faixa do rosto) do que no rosto é roupa, não pele.
    corpo = {}
    for y in range(y1, bb[3]):
        for x in range(bb[0], bb[2]):
            p = px[x, y]
            if p[3] > 40 and p[:3] in cols:
                corpo[p[:3]] = corpo.get(p[:3], 0) + 1
    solta = {c for c, n in cols.items() if n >= 2}
    return solta, {c for c in solta if corpo.get(c, 0) <= cols[c]}, y1


def recolor(im, rampa, skins_set=None):
    """Na faixa da cabeça (até o fim do rosto) troca todas as cores de pele achadas no rosto;
    abaixo dela só as que não são também cor de roupa (mãos, braço, pescoço)."""
    im = im.convert("RGBA")
    px = im.load()
    if skins_set is not None:
        solta, estrita, y_cab = skins_set, skins_set, im.height
    else:
        solta, estrita, y_cab = skin_colors(im)
    base = solta
    skins = sorted(base, key=lambda c: colorsys.rgb_to_hls(*(v / 255 for v in c))[1])
    if not skins:
        return im, 0
    lum = [colorsys.rgb_to_hls(*(v / 255 for v in c))[1] for c in skins]
    # luminosidade ABSOLUTA -> posição na rampa (com poucas cores, a escala relativa esticava o
    # contraste: a sombra da bochecha virava o tom mais escuro da rampa)
    lo, hi = LUM_PELE
    mapa = {}
    for c, l in zip(skins, lum):
        t = min(1.0, max(0.0, (l - lo) / (hi - lo)))
        i = t * (len(rampa) - 1)
        a, b = rampa[int(i)], rampa[min(int(i) + 1, len(rampa) - 1)]
        f = i - int(i)
        mapa[c] = tuple(round(a[k] + (b[k] - a[k]) * f) for k in range(3))
    out = im.copy()
    op = out.load()
    n = 0
    for y in range(im.height):
        for x in range(im.width):
            p = px[x, y]
            if p[3] > 40 and p[:3] in mapa and (y < y_cab or p[:3] in estrita):
                op[x, y] = mapa[p[:3]] + (p[3],)
                n += 1
    return out, n


def main():
    src = Image.open(sys.argv[1]).convert("RGBA")
    S = 4
    sheet = Image.new("RGBA", (4 * (src.width * S + 12), src.height * S + 24), (90, 90, 100, 255))
    from PIL import ImageDraw
    d = ImageDraw.Draw(sheet)
    items = [("original", src)] + [(k, recolor(src, r)[0]) for k, r in RAMPAS.items()]
    for i, (nome, im) in enumerate(items):
        big = im.resize((im.width * S, im.height * S), Image.NEAREST)
        sheet.paste(big, (i * (src.width * S + 12), 20), big)
        d.text((i * (src.width * S + 12) + 4, 4), nome, fill=(255, 230, 120))
    sheet.save(sys.argv[2])


if __name__ == "__main__":
    main()
