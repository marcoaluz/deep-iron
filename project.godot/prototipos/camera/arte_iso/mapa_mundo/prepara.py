"""Bloco 72: a imagem B do PixelLab vira o mapa do mundo do jogo (corte F2): recorta no desenho e tira
o branco de fora (preenchimento a partir da borda). As regiões de cada nível (onde aparecem os
ipezinhos, clique) ficam no .tres de cada nível (NivelMina.mapa_regiao, em px desta imagem recortada).

  python prepara.py [regioes]   -> assets/game/ui/corte/mapa_mundo.png (+ mapa_regioes.png pra conferir)
"""
import os, sys
from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(AQUI, "..", "..", "..", "..", "assets", "game", "ui", "corte", "mapa_mundo.png")
CORTE = (112, 12, 412, 504)


def branco(p):
    return p[3] > 0 and p[0] > 228 and p[1] > 228 and p[2] > 228


def prepara():
    im = Image.open(os.path.join(AQUI, "quadrado.png")).convert("RGBA").crop(CORTE)
    px = im.load()
    W, H = im.size
    pilha = [(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)]
    visto = set()
    while pilha:
        x, y = pilha.pop()
        if (x, y) in visto or not (0 <= x < W and 0 <= y < H) or not branco(px[x, y]):
            continue
        visto.add((x, y))
        px[x, y] = (0, 0, 0, 0)
        pilha += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    for y in range(60):  # o céu preso entre a torre e o guindaste (branco cercado, no topo)
        for x in range(W):
            if px[x, y][3] > 0 and px[x, y][0] > 238 and px[x, y][1] > 238 and px[x, y][2] > 238:
                px[x, y] = (0, 0, 0, 0)
    im.save(DEST)
    print(DEST, im.size, "fundo tirado:", len(visto))
    return im


def regioes(im, regs):
    z = 3
    big = im.resize((im.width * z, im.height * z), Image.NEAREST)
    bg = Image.new("RGBA", big.size, (40, 38, 36, 255))
    bg.alpha_composite(big)
    d = ImageDraw.Draw(bg)
    for nome, (x, y, w, h) in regs.items():
        d.rectangle([x * z, y * z, (x + w) * z, (y + h) * z], outline=(255, 255, 0, 255), width=2)
        d.text((x * z + 4, y * z + 2), nome, fill=(255, 255, 0, 255))
    bg.save(os.path.join(AQUI, "mapa_regioes.png"))


if __name__ == "__main__":
    im = prepara()
    regioes(im, {"S0": (8, 12, 108, 76), "S1": (126, 34, 168, 78), "S2": (13, 192, 150, 52), "S3": (13, 256, 150, 54),
                 "S4": (13, 318, 150, 72), "S5": (40, 400, 180, 58)})
