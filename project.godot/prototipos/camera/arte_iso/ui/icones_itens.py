"""Bloco 82: ícones PROVISÓRIOS dos itens que ainda não têm arte (32 x 32, como os de icones.py).

  python icones_itens.py   -> assets/game/ui/icones/it_<id>.png

Barras de metal (ferro, cobre, aço, prata), o lingote solar, prego, couro, peças raras e os cristais/gema
(a partir dos pedaços de minério do jogo). Desenho simples com contorno escuro e luz de cima, pra ler na grade
do armazém. Pra trocar por arte de verdade: gravar um PNG com o mesmo nome por cima (o jogo lê pelo nome).
"""
import os

from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(AQUI, "..", "..", "..", ".."))
DEST = os.path.join(RAIZ, "assets", "game", "ui", "icones")
GAME = os.path.join(RAIZ, "assets", "game")
CONTORNO = (22, 18, 16, 255)

# (claro, meio, escuro, brilho) de cada metal
METAIS = {
    "barra_ferro": ((168, 160, 156), (120, 112, 110), (78, 70, 70), (214, 208, 204)),
    "barra_cobre": ((232, 150, 92), (190, 104, 58), (126, 64, 36), (255, 204, 150)),
    "aco": ((176, 196, 214), (122, 142, 164), (78, 92, 112), (232, 242, 252)),
    "barra_prata": ((226, 230, 238), (178, 184, 198), (120, 126, 142), (255, 255, 255)),
    "lingote_solar": ((255, 196, 96), (238, 130, 44), (166, 70, 24), (255, 240, 180)),
}


def contorno(im):
    px = im.load()
    w, h = im.size
    cheio = [[px[x, y][3] > 0 for y in range(h)] for x in range(w)]
    for x in range(w):
        for y in range(h):
            if not cheio[x][y] and any(0 <= x + dx < w and 0 <= y + dy < h and cheio[x + dx][y + dy]
                                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = CONTORNO
    return im


def lingote(d, ox, oy, cores, marca=True):
    claro, meio, escuro, brilho = cores
    topo = [(ox + 5, oy), (ox + 17, oy), (ox + 20, oy + 4), (ox + 2, oy + 4)]
    frente = [(ox + 2, oy + 4), (ox + 20, oy + 4), (ox + 22, oy + 10), (ox, oy + 10)]
    d.polygon(frente, fill=meio)
    d.polygon(topo, fill=claro)
    d.line([(ox + 6, oy + 1), (ox + 15, oy + 1)], fill=brilho)  # luz na beira de cima
    d.line([(ox, oy + 10), (ox + 22, oy + 10)], fill=escuro)  # sombra embaixo
    d.line([(ox + 2, oy + 5), (ox + 19, oy + 5)], fill=claro)
    if marca:  # o carimbo da fundição
        d.rectangle([ox + 9, oy + 6, ox + 12, oy + 8], fill=escuro)


def barra(nome):
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = METAIS[nome]
    lingote(d, 8, 9, tuple(tuple(max(0, v - 26) for v in k) for k in c), marca=False)  # a de trás
    lingote(d, 4, 16, c)
    if nome == "lingote_solar":  # brilho da energia guardada
        for x, y in ((24, 7), (26, 5), (6, 13), (27, 14)):
            d.point((x, y), fill=(255, 236, 160))
    if nome == "aco":  # aço: veio azulado
        d.line([(9, 22), (14, 21)], fill=(214, 230, 246))
    return contorno(im)


def prego():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for k, (x, y) in enumerate(((6, 8), (12, 6), (18, 9))):
        d.line([(x + 3, y + 3), (x + 9, y + 19)], fill=(150, 150, 156), width=2)  # o corpo
        d.line([(x + 4, y + 3), (x + 10, y + 19)], fill=(210, 210, 216))
        d.ellipse([x, y, x + 6, y + 3], fill=(120, 120, 128))  # a cabeça
        d.line([(x + 1, y), (x + 5, y)], fill=(220, 220, 226))
    return contorno(im)


def couro():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    pele = [(6, 8), (12, 5), (20, 5), (26, 8), (24, 13), (27, 20), (22, 26), (16, 24), (10, 27), (5, 21), (8, 14)]
    d.polygon(pele, fill=(150, 98, 56))
    d.polygon([(9, 10), (20, 8), (23, 14), (14, 16)], fill=(178, 124, 74))
    d.line([(8, 20), (20, 22)], fill=(110, 70, 40))
    for x in range(9, 24, 3):  # a costura
        d.point((x, 11 + (x % 2)), fill=(230, 210, 170))
    return contorno(im)


def pecas_raras():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 13, 15
    for k in range(8):  # os dentes da engrenagem
        import math
        a = k * math.pi / 4
        x, y = cx + 9 * math.cos(a), cy + 9 * math.sin(a)
        d.rectangle([x - 2, y - 2, x + 1, y + 1], fill=(196, 158, 70))
    d.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(214, 176, 84))
    d.ellipse([cx - 6, cy - 7, cx + 4, cy - 1], fill=(240, 210, 120))
    d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(90, 70, 40))
    # um parafuso
    d.rectangle([21, 19, 27, 22], fill=(160, 166, 176))
    d.rectangle([23, 22, 25, 28], fill=(130, 136, 146))
    d.line([(21, 19), (27, 19)], fill=(220, 224, 232))
    return contorno(im)


def ferragem():
    """Bloco 87: uma dobradiça/cantoneira de ferro com pregos."""
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(6, 8), (24, 8), (24, 13), (11, 13), (11, 25), (6, 25)], fill=(118, 112, 110))
    d.line([(7, 9), (23, 9)], fill=(176, 170, 166))
    d.line([(7, 10), (7, 24)], fill=(150, 144, 140))
    for x, y in ((9, 11), (16, 11), (22, 11), (9, 17), (9, 23)):
        d.point((x, y), fill=(60, 56, 54))
    d.ellipse([18, 17, 26, 25], fill=(96, 90, 88))
    d.ellipse([20, 19, 24, 23], fill=(40, 36, 34))
    return contorno(im)


def de_pedaco(arq):
    """Cristais e gema: o pedaço de minério do jogo, ampliado sem borrar e centrado."""
    p = Image.open(os.path.join(GAME, arq)).convert("RGBA")
    caixa = p.getbbox() or (0, 0, p.width, p.height)
    p = p.crop(caixa)
    k = max(1, min(26 // p.width, 26 // p.height))
    p = p.resize((p.width * k, p.height * k), Image.NEAREST)
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    im.alpha_composite(p, ((32 - p.width) // 2, (32 - p.height) // 2))
    return im


def main():
    feitos = {}
    for nome in METAIS:
        feitos[nome] = barra(nome)
    feitos["prego"] = prego()
    feitos["couro"] = couro()
    feitos["pecas_raras"] = pecas_raras()
    feitos["ferragem"] = ferragem()
    for nome in ("cristal_verde", "cristal_rubro", "gema_azul"):
        feitos[nome] = de_pedaco("chunk_%s.png" % nome)
    for nome, im in feitos.items():
        im.save(os.path.join(DEST, "it_%s.png" % nome))
    print("ok", len(feitos), "ícones ->", DEST)


if __name__ == "__main__":
    main()
