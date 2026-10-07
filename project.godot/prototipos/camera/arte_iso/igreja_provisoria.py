"""Bloco 88: desenho PROVISÓRIO da Igreja (até a arte do PixelLab): capela de pedra com campanário e cruz.

  python igreja_provisoria.py   -> assets/game/igreja.png (1 quadro)

Mesmo jeito dos prédios antigos da vista de cima (escala 2 na cena): a vista isométrica espelha este desenho
em pé enquanto não houver "igreja" no predios.json.
"""
import os

from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
SAIDA = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", "igreja.png"))
W, H = 56, 62
CONT = (24, 20, 20, 255)
PAREDE = [(176, 166, 150, 255), (156, 146, 132, 255), (196, 186, 170, 255)]
PAREDE_E = (118, 110, 100, 255)
TELHA = (124, 64, 48, 255)
TELHA_E = (92, 46, 36, 255)
MADEIRA = (104, 70, 44, 255)
VITRAL = [(90, 140, 210, 255), (220, 180, 80, 255), (200, 80, 70, 255)]


def main():
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # nave (corpo)
    d.rectangle([4, 30, 51, 60], fill=CONT)
    d.rectangle([5, 31, 50, 59], fill=PAREDE[0])
    k = 0
    for y in range(33, 58, 4):
        off = 0 if (y // 4) % 2 == 0 else 3
        for x in range(6 + off, 49, 8):
            d.rectangle([x, y, x + 6, y + 2], fill=PAREDE[k % 3])
            d.line([(x, y + 3), (x + 6, y + 3)], fill=PAREDE_E)
            k += 1
    # telhado da nave
    d.polygon([(2, 31), (28, 18), (53, 31)], fill=CONT)
    d.polygon([(5, 30), (28, 20), (50, 30)], fill=TELHA)
    for i in range(3):
        d.line([(8 + i * 6, 29 - i * 3), (48 - i * 6, 29 - i * 3)], fill=TELHA_E)
    # campanário
    d.rectangle([22, 6, 34, 31], fill=CONT)
    d.rectangle([23, 7, 33, 31], fill=PAREDE[2])
    d.rectangle([25, 11, 31, 17], fill=CONT)  # a janela do sino
    d.rectangle([26, 12, 30, 16], fill=(60, 48, 40, 255))
    d.ellipse([26, 13, 30, 17], fill=(214, 176, 80, 255))  # o sino
    d.polygon([(21, 7), (28, 1), (35, 7)], fill=TELHA)
    # cruz
    d.line([(28, 0), (28, 4)], fill=(230, 210, 150, 255))
    d.line([(26, 1), (30, 1)], fill=(230, 210, 150, 255))
    # porta e vitrais
    d.rounded_rectangle([23, 44, 33, 60], radius=4, fill=CONT)
    d.rounded_rectangle([24, 45, 32, 60], radius=3, fill=MADEIRA)
    d.line([(28, 46), (28, 59)], fill=(70, 46, 30, 255))
    for x0 in (9, 39):
        d.rounded_rectangle([x0, 38, x0 + 7, 50], radius=3, fill=CONT)
        for j, cor in enumerate(VITRAL):
            d.rectangle([x0 + 1, 40 + j * 3, x0 + 6, 42 + j * 3], fill=cor)
    d.rectangle([2, 59, 53, 61], fill=PAREDE_E)
    im.save(SAIDA)
    print("ok", SAIDA, im.size)


if __name__ == "__main__":
    main()
