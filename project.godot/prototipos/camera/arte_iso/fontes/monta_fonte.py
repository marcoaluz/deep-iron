"""Prompt 22: monta as fontes do jogo (.ttf) a partir do atlas gerado (create_font do PixelLab),
com TODOS os acentos do português compostos por script (o gerador só faz A-Z, a-z, 0-9 e
pontuação) e números de largura fixa (HUD).

  python fontes/monta_fonte.py   -> assets/fonts/deep_iron_texto.ttf, deep_iron_titulo.ttf + amostra

Cada pixel do atlas vira um quadradinho do contorno (pixel art de verdade: fica nítida em
múltiplos do tamanho nativo: 16/32 px a de texto, 32/64 px a de título).
"""
import os
import numpy as np
from PIL import Image, ImageDraw
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

AQUI = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.normpath(os.path.join(AQUI, "../../../../assets/fonts"))
os.makedirs(DEST, exist_ok=True)
ORDEM = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,!?:;'\"-+()0123456789/%*=_$"
# acentos: letra -> (base, sinal)
ACENTOS = {}
for base, lista in {"a": "áàâã", "e": "éê", "i": "í", "o": "óôõ", "u": "úü", "A": "ÁÀÂÃ", "E": "ÉÊ", "I": "Í", "O": "ÓÔÕ", "U": "ÚÜ"}.items():
    for ch, s in zip(lista, ["agudo", "grave", "circ", "til"] if base in "aA" else
                     (["agudo", "circ"] if base in "eE" else (["agudo"] if base in "iI" else (["agudo", "circ", "til"] if base in "oO" else ["agudo", "trema"])))):
        ACENTOS[ch] = (base, s)
ACENTOS["ç"] = ("c", "cedilha")
ACENTOS["Ç"] = ("C", "cedilha")


def sinal(nome, esc):
    """O sinal em pixels (lista de (x, y) a partir do canto de cima-esquerdo), na escala da fonte."""
    m = {"agudo": [(1, 0), (0, 1)], "grave": [(0, 0), (1, 1)], "circ": [(1, 0), (0, 1), (2, 1)],
         "til": [(1, 0), (0, 1), (3, 0), (2, 1)], "trema": [(0, 0), (2, 0)]}[nome]
    out = []
    for (x, y) in m:
        for dy in range(esc):
            for dx in range(esc):
                out.append((x * esc + dx, y * esc + dy))
    return out


def glifos(atlas_path, cel):
    a = np.array(Image.open(atlas_path).convert("RGBA"))[..., 3] > 100
    cols = a.shape[1] // cel
    g = {}
    for i, ch in enumerate(ORDEM):
        cx, cy = (i % cols) * cel, (i // cols) * cel
        g[ch] = a[cy:cy + cel, cx:cx + cel].copy()
    return g


def monta(nome, atlas, cel, familia, estilo, esc_sinal):
    g = glifos(os.path.join(AQUI, atlas), cel)
    # linha de base: o fundo do "H"; altura de x: o topo do "x"; topo das maiúsculas: o topo do "H"
    ys = np.nonzero(g["H"].any(1))[0]
    base, topo_cap = ys.max() + 1, ys.min()
    topo_x = np.nonzero(g["x"].any(1))[0].min()
    # acentuadas: o sinal acima da letra (maiúscula: em cima da altura de maiúscula, a fonte cresce pra cima)
    for ch, (b, s) in ACENTOS.items():
        m = g[b].copy()
        if s == "cedilha":
            xs = np.nonzero(m.any(0))[0]
            cx = (xs.min() + xs.max()) // 2
            for (x, y) in [(0, 0), (1, 1), (0, 2)]:
                for dy in range(esc_sinal):
                    for dx in range(esc_sinal):
                        yy, xx = base + y * esc_sinal + dy, cx + x * esc_sinal + dx
                        if yy < cel:
                            m[yy, xx] = True
        else:
            pts = sinal(s, esc_sinal)
            w = max(p[0] for p in pts) + 1
            h = max(p[1] for p in pts) + 1
            xs = np.nonzero(m.any(0))[0]
            x0 = (xs.min() + xs.max() + 1) // 2 - w // 2
            topo = topo_cap if b.isupper() else topo_x
            y0 = topo - h - esc_sinal
            pad = max(0, -y0)
            if pad:  # sobe a célula (as maiúsculas acentuadas passam do topo)
                m = np.vstack([np.zeros((pad, cel), bool), m])
                y0 += pad
            mm = m.copy()
            if b in "ij":  # tira o pingo do i
                mm[:topo_x, :] = False
            for (x, y) in pts:
                mm[y0 + y, x0 + x] = True
            m = mm
            m = m[pad:] if False else m
            g[ch] = (m, pad)
            continue
        g[ch] = (m, 0)
    for ch in list(g):
        if not isinstance(g[ch], tuple):
            g[ch] = (g[ch], 0)
    # símbolos que a interface usa e o gerador não fez (desenhados na escala da fonte)
    k = esc_sinal
    meio = (topo_x + base) // 2

    def novo(pts, larg):
        m = np.zeros((cel, cel), bool)
        for (x, y) in pts:
            for dy in range(k):
                for dx in range(k):
                    if 0 <= y * k + dy < cel and 0 <= x * k + dx < cel:
                        m[y * k + dy, x * k + dx] = True
        return (m, 0)
    yb = base // k - 1  # última linha (em unidades de k) acima da linha de base
    ym = meio // k
    yt = topo_cap // k
    g["•"] = novo([(1, ym - 1), (2, ym - 1), (1, ym), (2, ym)], 4)
    g["—"] = novo([(x, ym) for x in range(0, 9)], 9)
    g["–"] = novo([(x, ym) for x in range(0, 6)], 6)
    g["→"] = novo([(x, ym) for x in range(0, 7)] + [(5, ym - 1), (4, ym - 2), (5, ym + 1), (4, ym + 2)], 7)
    g["…"] = novo([(0, yb), (2, yb), (4, yb)], 5)
    g["["] = novo([(0, y) for y in range(yt, yb + 2)] + [(1, yt), (1, yb + 1)], 2)
    g["]"] = novo([(1, y) for y in range(yt, yb + 2)] + [(0, yt), (0, yb + 1)], 2)
    g["º"] = novo([(0, yt), (1, yt), (0, yt + 1), (1, yt + 1), (0, yt + 3), (1, yt + 3)], 2)
    g["ª"] = g["º"]
    g["×"] = novo([(0, ym - 2), (1, ym - 1), (2, ym), (3, ym + 1), (4, ym + 2), (4, ym - 2), (3, ym - 1), (1, ym + 1), (0, ym + 2)], 5)
    g["#"] = novo([(1, y) for y in range(ym - 3, ym + 4)] + [(3, y) for y in range(ym - 3, ym + 4)] + [(x, ym - 1) for x in range(5)] + [(x, ym + 2) for x in range(5)], 5)
    # métrica: 1 pixel = 64 unidades
    U = 64
    upm = cel * U
    larg_digito = max(np.nonzero(g[d][0].any(0))[0].max() - np.nonzero(g[d][0].any(0))[0].min() + 1 for d in "0123456789")
    fb = FontBuilder(upm, isTTF=True)
    nomes = [".notdef", "space"] + ["u%04X" % ord(c) for c in g]
    fb.setupGlyphOrder(nomes)
    cmap = {32: "space"}
    for c in g:
        cmap[ord(c)] = "u%04X" % ord(c)
    fb.setupCharacterMap(cmap)
    contornos = {}
    metr = {}
    vazio = TTGlyphPen(None).glyph()
    contornos[".notdef"] = vazio
    contornos["space"] = vazio
    espaco = max(2, cel // 4) * U
    metr[".notdef"] = (espaco, 0)
    metr["space"] = (espaco, 0)
    for c, (m, pad) in g.items():
        xs = np.nonzero(m.any(0))[0]
        if len(xs) == 0:
            contornos["u%04X" % ord(c)] = vazio
            metr["u%04X" % ord(c)] = (espaco, 0)
            continue
        x0, x1 = xs.min(), xs.max()
        digito = c in "0123456789"
        w = larg_digito if digito else (x1 - x0 + 1)
        off = x0 - ((larg_digito - (x1 - x0 + 1)) // 2 if digito else 0)
        pen = TTGlyphPen(None)
        H = m.shape[0]
        for y in range(H):
            x = 0
            row = m[y]
            while x < cel:
                if row[x]:
                    s = x
                    while x < cel and row[x]:
                        x += 1
                    # y da fonte: pra cima a partir da linha de base
                    yt = (base + pad - y) * U
                    yb = yt - U
                    xl, xr = (s - off + 1) * U, (x - off + 1) * U
                    pen.moveTo((xl, yb)); pen.lineTo((xl, yt)); pen.lineTo((xr, yt)); pen.lineTo((xr, yb)); pen.closePath()
                else:
                    x += 1
        contornos["u%04X" % ord(c)] = pen.glyph()
        metr["u%04X" % ord(c)] = ((w + 2) * U, U)
    fb.setupGlyf(contornos)
    fb.setupHorizontalMetrics(metr)
    asc = (base + esc_sinal * 4) * U
    desc = -(cel - base) * U
    fb.setupHorizontalHeader(ascent=asc, descent=desc)
    fb.setupNameTable({"familyName": familia, "styleName": estilo})
    fb.setupOS2(sTypoAscender=asc, sTypoDescender=desc, usWinAscent=asc, usWinDescent=-desc)
    fb.setupPost()
    path = os.path.join(DEST, nome + ".ttf")
    fb.save(path)
    print(nome, "->", path, len(g), "glifos")
    return g, base, cel


tx = monta("deep_iron_texto", "texto_atlas.png", 16, "Deep Iron Texto", "Regular", 1)
ti = monta("deep_iron_titulo", "titulo_atlas.png", 32, "Deep Iron Titulo", "Bold", 2)


# amostra com textos de verdade do jogo (desenhada pelos mesmos glifos)
def escreve(img, xy, texto, fonte, cor, z=1):
    g, base, cel = fonte
    x, y = xy
    for c in texto:
        if c == " ":
            x += max(2, cel // 4) * z
            continue
        if c not in g:
            x += cel // 2 * z
            continue
        m, pad = g[c]
        xs = np.nonzero(m.any(0))[0]
        x0, x1 = xs.min(), xs.max()
        for yy, xx in zip(*np.nonzero(m)):
            for dy in range(z):
                for dx in range(z):
                    img.putpixel((x + (xx - x0) * z + dx, y + (yy - pad) * z + dy), cor)
        x += (x1 - x0 + 2) * z
    return x


A = Image.new("RGBA", (900, 560), (24, 20, 18, 255))
amb = (255, 204, 90, 255); tx_c = (235, 225, 205, 255); dim = (165, 153, 140, 255)
escreve(A, (16, 12), "DEEP IRON", ti, amb, 2)
escreve(A, (16, 110), "CENTRO DA VILA  •  OFICINA  •  LABORATÓRIO", ti, amb, 1)
linhas = [("Casa (Moradias): +4 no limite de ipezinhos e 4 camas.", tx_c), ("Só em volta do Centro da Vila.", dim),
          ("190 cr + 40 pedra (ferro) + 20 madeira", amb), ("Ação, coração, pão, maçã, ônibus, você, avó, à noite, üé", tx_c),
          ("ÁÀÂÃ ÉÊ Í ÓÔÕ ÚÜ Ç  áàâã éê í óôõ úü ç", tx_c), ("HUD: 0123456789  12/12  85%  +40  -3  $150  10:45", tx_c), ("limite 8 → limite 12  •  sem função — esperando…  [Espaço]", dim),
          ("INVASÃO! (onda 4)  3 Lumívoros e 1 Ferrugento.", (240, 110, 90, 255)),
          ("Aguentem até o amanhecer. Ânimo da vila: 68.", dim)]
y = 160
for t, c in linhas:
    escreve(A, (16, y), t, tx, c, 2 if y < 400 else 1)
    y += 40 if y < 400 else 22
docs = os.path.normpath(os.path.join(AQUI, "../../../../../docs/arte/prompt22"))
os.makedirs(docs, exist_ok=True)
A.save(os.path.join(docs, "amostra_fontes.png"))
print("amostra ->", docs)
