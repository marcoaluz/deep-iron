"""Bloco 90: desenhos PROVISÓRIOS da decoração construída pelo jogador (até a arte do PixelLab).

  python decor_provisoria.py   -> assets/game/decor/<id>.png (tocha, lampiao, banco, mesa, cerca, canteiro_flores, bandeira)

Mesmo jeito dos props antigos da vista de cima (desenho de frente, pé na borda de baixo, escala 2 no jogo): a
vista isométrica espelha o desenho em pé. Pra trocar por arte de verdade: gravar outro PNG com o mesmo nome
(o catálogo decor.gd aponta pro arquivo).
"""
import os

from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", "decor"))
CONT = (26, 20, 16, 255)
MAD = (122, 84, 50, 255)
MAD_E = (86, 58, 34, 255)
MAD_C = (160, 116, 72, 255)
FERRO = (90, 88, 92, 255)
FERRO_C = (150, 148, 152, 255)


def tela(w, h):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def tocha():
    im, d = tela(8, 22)
    d.rectangle([3, 8, 4, 21], fill=MAD_E)
    d.line([(3, 8), (3, 21)], fill=MAD)
    d.rectangle([2, 6, 5, 8], fill=FERRO)
    d.polygon([(4, 0), (6, 4), (5, 6), (2, 6), (1, 4)], fill=(255, 150, 40, 255))
    d.polygon([(4, 2), (5, 4), (4, 5), (3, 4)], fill=(255, 236, 140, 255))
    return im


def lampiao():
    im, d = tela(12, 30)
    d.rectangle([5, 10, 6, 29], fill=FERRO)
    d.line([(5, 10), (5, 29)], fill=FERRO_C)
    d.rectangle([3, 28, 8, 29], fill=CONT)
    d.rectangle([2, 2, 9, 3], fill=CONT)  # o chapéu
    d.rectangle([3, 4, 8, 10], fill=CONT)
    d.rectangle([4, 5, 7, 9], fill=(255, 220, 120, 255))
    d.point((5, 6), fill=(255, 250, 210, 255))
    return im


def banco():
    im, d = tela(28, 14)
    d.rectangle([1, 4, 26, 6], fill=MAD)  # assento
    d.line([(1, 4), (26, 4)], fill=MAD_C)
    d.rectangle([1, 0, 26, 2], fill=MAD_E)  # encosto
    d.line([(1, 0), (26, 0)], fill=MAD)
    for x in (3, 23):
        d.rectangle([x, 7, x + 1, 13], fill=MAD_E)
        d.rectangle([x, 2, x + 1, 4], fill=MAD_E)
    return im


def mesa():
    im, d = tela(26, 16)
    d.polygon([(2, 4), (24, 4), (25, 8), (1, 8)], fill=MAD_C)  # tampo
    d.line([(1, 8), (25, 8)], fill=MAD_E)
    d.rectangle([1, 8, 25, 9], fill=MAD)
    for x in (3, 21):
        d.rectangle([x, 10, x + 1, 15], fill=MAD_E)
    d.rectangle([11, 2, 14, 4], fill=(200, 196, 188, 255))  # caneca
    return im


def cerca():
    im, d = tela(40, 16)
    for x in range(1, 40, 7):
        d.rectangle([x, 2, x + 2, 15], fill=MAD)
        d.line([(x, 2), (x, 15)], fill=MAD_C)
        d.point((x + 1, 1), fill=MAD_E)
    d.rectangle([0, 5, 39, 6], fill=MAD_E)
    d.rectangle([0, 10, 39, 11], fill=MAD_E)
    return im


def canteiro_flores():
    im, d = tela(22, 14)
    d.rectangle([1, 7, 20, 13], fill=MAD_E)
    d.rectangle([2, 8, 19, 12], fill=(84, 58, 38, 255))
    d.line([(1, 7), (20, 7)], fill=MAD)
    cores = [(232, 90, 90), (250, 210, 80), (200, 120, 230), (250, 250, 240), (240, 140, 60)]
    for i, x in enumerate(range(3, 20, 3)):
        d.line([(x, 8), (x, 4)], fill=(70, 130, 60, 255))
        c = cores[i % len(cores)] + (255,)
        d.rectangle([x - 1, 2 + (i % 2), x + 1, 4 + (i % 2)], fill=c)
        d.point((x, 3 + (i % 2)), fill=(255, 240, 160, 255))
    return im


def bandeira():
    im, d = tela(16, 34)
    d.rectangle([2, 2, 3, 33], fill=FERRO)
    d.line([(2, 2), (2, 33)], fill=FERRO_C)
    d.rectangle([1, 31, 4, 33], fill=CONT)
    d.polygon([(4, 3), (15, 5), (14, 9), (15, 13), (4, 12)], fill=(176, 48, 44, 255))
    d.polygon([(4, 6), (13, 7), (13, 10), (4, 9)], fill=(230, 196, 90, 255))  # a faixa da vila
    return im


def main():
    os.makedirs(DEST, exist_ok=True)
    feitos = {"tocha": tocha(), "lampiao": lampiao(), "banco": banco(), "mesa": mesa(), "cerca": cerca(),
              "canteiro_flores": canteiro_flores(), "bandeira": bandeira()}
    for nome, im in feitos.items():
        im.save(os.path.join(DEST, nome + ".png"))
    print("ok", len(feitos), "->", DEST)


if __name__ == "__main__":
    main()
