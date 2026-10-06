"""Bloco 86: desenho PROVISÓRIO da Fornalha (até a arte do PixelLab): forno de pedra com chaminé e boca.

  python fornalha_provisoria.py   -> assets/game/fornalha.png (2 quadros lado a lado: apagada, acesa)

Mesmo jeito dos prédios antigos da vista de cima (quadros lado a lado, escala 2 na cena): a vista isométrica
espelha este desenho em pé enquanto não houver "fornalha" no predios.json.
"""
import os

from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
SAIDA = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", "fornalha.png"))
W, H = 46, 40
CONT = (26, 20, 18, 255)
PEDRA = [(112, 104, 98, 255), (92, 86, 80, 255), (132, 124, 116, 255)]
PEDRA_E = (70, 64, 60, 255)
TIJOLO = (150, 82, 56, 255)
TIJOLO_E = (112, 58, 40, 255)


def quadro(acesa: bool) -> Image.Image:
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # chaminé de tijolo
    d.rectangle([30, 2, 37, 18], fill=CONT)
    d.rectangle([31, 3, 36, 18], fill=TIJOLO)
    for y in range(5, 18, 3):
        d.line([(31, y), (36, y)], fill=TIJOLO_E)
    # corpo de pedra (cúpula)
    d.rounded_rectangle([4, 14, 41, 38], radius=8, fill=CONT)
    d.rounded_rectangle([5, 15, 40, 37], radius=7, fill=PEDRA[0])
    k = 0
    for y in range(17, 36, 4):
        off = 0 if (y // 4) % 2 == 0 else 3
        for x in range(6 + off, 39, 7):
            d.rectangle([x, y, x + 5, y + 2], fill=PEDRA[(k % 3)])
            d.line([(x, y + 3), (x + 5, y + 3)], fill=PEDRA_E)
            k += 1
    # boca
    d.rounded_rectangle([14, 24, 31, 37], radius=5, fill=CONT)
    if acesa:
        d.rounded_rectangle([15, 25, 30, 37], radius=4, fill=(255, 132, 36, 255))
        d.rounded_rectangle([17, 28, 28, 37], radius=3, fill=(255, 206, 92, 255))
        d.rectangle([20, 31, 25, 37], fill=(255, 246, 196, 255))
    else:
        d.rounded_rectangle([15, 25, 30, 37], radius=4, fill=(40, 30, 28, 255))
        d.rectangle([17, 33, 28, 36], fill=(84, 40, 30, 255))  # brasa apagada
    # base
    d.rectangle([3, 37, 42, 39], fill=PEDRA_E)
    return im


def main():
    folha = Image.new("RGBA", (W * 2, H), (0, 0, 0, 0))
    folha.alpha_composite(quadro(False), (0, 0))
    folha.alpha_composite(quadro(True), (W, 0))
    folha.save(SAIDA)
    print("ok", SAIDA, folha.size)


if __name__ == "__main__":
    main()
