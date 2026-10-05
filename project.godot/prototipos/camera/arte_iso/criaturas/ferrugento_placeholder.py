"""(Substituído pela arte do PixelLab: ferrugento_robo.py -> assets/game/ferrugento_robo.png. Fica como
referência do formato da folha e pra testes rápidos.)

Bloco 80: PLACEHOLDER do Ferrugento — um robô pequeno e enferrujado (esqueleto de metal, crânio com olhos
vermelhos, estilo exterminador). Desenhado por código até chegarem os sprites do PixelLab.

Folha de quadros: UMA LINHA POR ANIMAÇÃO, na ordem de creature.gd `visual_anims`
(parado, caminhada, atacar, dano, morrer), quadros da esquerda pra direita, cada um QUADRO x QUADRO px,
virado pra DIREITA (o jogo espelha pra esquerda). O pé fica na linha PE (a cena acerta o offset).

  python ferrugento_placeholder.py   -> assets/game/ferrugento_placeholder.png

Pra trocar pela arte do PixelLab: montar uma folha no mesmo formato (ou outro tamanho de quadro / outra
quantidade de quadros) e ajustar na cena scenes/creatures/ferrugento.tscn os campos visual_* do nó raiz.
"""
import os
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
SAIDA = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "..", "assets", "game", "ferrugento_placeholder.png"))
QW, QH = 24, 32
PE = 30
ANIMS = [("parado", 2), ("caminhada", 4), ("atacar", 3), ("dano", 2), ("morrer", 4)]

CONTORNO = (26, 16, 12, 255)
FERRUGEM_E = (84, 40, 22, 255)
FERRUGEM = (138, 70, 34, 255)
FERRUGEM_C = (188, 112, 56, 255)
METAL_E = (62, 58, 56, 255)
METAL = (108, 102, 96, 255)
OLHO = (255, 52, 30, 255)
OLHO_C = (255, 170, 120, 255)


class Q:
    def __init__(self):
        self.im = Image.new("RGBA", (QW, QH), (0, 0, 0, 0))
        self.px = self.im.load()

    def p(self, x, y, c):
        if 0 <= x < QW and 0 <= y < QH:
            self.px[x, y] = c

    def r(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.p(x, y, c)

    def linha(self, a, b, c, larg=1):
        (x0, y0), (x1, y1) = a, b
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(n + 1):
            x = round(x0 + (x1 - x0) * i / n)
            y = round(y0 + (y1 - y0) * i / n)
            for dx in range(larg):
                self.p(x + dx, y, c)

    def contorno(self):
        cheio = [[self.px[x, y][3] > 0 for y in range(QH)] for x in range(QW)]
        for x in range(QW):
            for y in range(QH):
                if cheio[x][y]:
                    continue
                if any(0 <= x + dx < QW and 0 <= y + dy < QH and cheio[x + dx][y + dy]
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    self.px[x, y] = CONTORNO
        return self.im


def perna(q, quadril, pe_x, joelho_dx=1):
    jx = (quadril[0] + pe_x) // 2 + joelho_dx
    jy = (quadril[1] + PE) // 2
    q.linha(quadril, (jx, jy), FERRUGEM, 2)
    q.linha((jx, jy), (pe_x, PE - 1), METAL, 2)
    q.r(pe_x - 1, PE - 1, pe_x + 2, PE, FERRUGEM_E)  # o pé
    q.p(jx, jy, METAL_E)


def braco(q, ombro, mao, c=FERRUGEM, garra=False):
    cx = (ombro[0] + mao[0]) // 2
    cy = (ombro[1] + mao[1]) // 2 + 1
    q.linha(ombro, (cx, cy), c, 2)
    q.linha((cx, cy), mao, METAL, 2)
    if garra:
        q.p(mao[0] + 2, mao[1] - 1, METAL)
        q.p(mao[0] + 2, mao[1] + 1, METAL)


def robo(dy=0, pe_frente=14, pe_tras=10, braco_frente="baixo", olho=OLHO, susto=False):
    q = Q()
    y0 = dy
    # braço de trás e perna de trás (mais escuros, atrás do corpo)
    braco(q, (10, 13 + y0), (8, 20 + y0), FERRUGEM_E)
    perna(q, (11, 21 + y0), pe_tras, -1)
    # tronco: costelas de metal
    q.r(8, 12 + y0, 16, 13 + y0, FERRUGEM_C)  # ombros
    for k, yy in enumerate(range(14, 20)):
        q.r(9, yy + y0, 15, yy + y0, FERRUGEM if k % 2 == 0 else FERRUGEM_E)
    q.r(12, 12 + y0, 12, 21 + y0, METAL)  # coluna
    q.r(10, 20 + y0, 14, 21 + y0, METAL_E)  # quadril
    # cabeça: crânio, olhos vermelhos, maxilar
    q.r(10, 3 + y0, 16, 9 + y0, METAL)
    q.r(11, 2 + y0, 15, 2 + y0, METAL)
    q.r(10, 3 + y0, 11, 4 + y0, FERRUGEM_C)  # ferrugem na testa
    q.r(13, 5 + y0, 14, 6 + y0, olho)
    q.r(16, 5 + y0, 16, 6 + y0, olho)
    q.p(13, 5 + y0, OLHO_C)
    q.r(11, 8 + y0, 16, 9 + y0, METAL_E)  # maxilar
    for xx in (12, 14, 16):
        q.p(xx, 8 + y0, METAL)  # dentes
    q.r(12, 10 + y0, 13, 11 + y0, METAL_E)  # pescoço
    # perna da frente e braço da frente
    perna(q, (13, 21 + y0), pe_frente, 1)
    if braco_frente == "baixo":
        braco(q, (14, 13 + y0), (16, 20 + y0))
    elif braco_frente == "atras":
        braco(q, (14, 13 + y0), (9, 16 + y0))
    elif braco_frente == "soco":
        braco(q, (14, 13 + y0), (21, 13 + y0), garra=True)
    im = q.contorno()
    if susto:  # levou golpe: clareia
        px = im.load()
        for x in range(QW):
            for y in range(QH):
                r, g, b, a = px[x, y]
                if a:
                    px[x, y] = (min(255, r + 90), min(255, g + 90), min(255, b + 90), a)
    return im


def caido(etapa):
    """morrer / desligar: o robô cede e vira um monte de sucata com o olho apagando."""
    if etapa == 0:
        return robo(dy=3, pe_frente=15, pe_tras=9, braco_frente="baixo")
    q = Q()
    if etapa == 1:  # de joelhos, tombando
        q.r(7, 18, 15, 24, FERRUGEM)
        q.r(9, 13, 15, 18, METAL)
        q.r(12, 15, 13, 16, OLHO)
        q.r(8, 25, 17, 27, FERRUGEM_E)
        q.linha((7, 28), (17, 28), METAL, 1)
    else:  # no chão: crânio de lado, costelas e canos espalhados
        apaga = (150, 40, 26, 255) if etapa == 2 else (70, 30, 24, 255)
        q.r(4, 25, 19, 27, FERRUGEM_E)
        q.r(6, 23, 14, 25, FERRUGEM)
        for xx in range(7, 14, 2):
            q.r(xx, 22, xx, 23, FERRUGEM_C)
        q.r(15, 22, 20, 26, METAL)
        q.r(17, 23, 18, 24, apaga)
        q.linha((2, 28), (8, 26), METAL, 1)
        q.linha((19, 28), (22, 26), METAL_E, 1)
    return q.contorno()


def main():
    quadros = {
        "parado": [robo(), robo(dy=1, olho=OLHO_C)],
        "caminhada": [robo(dy=0, pe_frente=17, pe_tras=8), robo(dy=-1, pe_frente=14, pe_tras=11),
                      robo(dy=0, pe_frente=10, pe_tras=15), robo(dy=-1, pe_frente=13, pe_tras=12)],
        "atacar": [robo(braco_frente="atras", dy=1), robo(braco_frente="soco", pe_frente=16), robo(braco_frente="baixo")],
        "dano": [robo(dy=1, pe_frente=12, susto=True), robo(dy=1, pe_frente=13)],
        "morrer": [caido(0), caido(1), caido(2), caido(3)],
    }
    largura = max(n for _, n in ANIMS)
    folha = Image.new("RGBA", (QW * largura, QH * len(ANIMS)), (0, 0, 0, 0))
    for row, (nome, n) in enumerate(ANIMS):
        assert len(quadros[nome]) == n, nome
        for i, im in enumerate(quadros[nome]):
            folha.alpha_composite(im, (i * QW, row * QH))
    folha.save(SAIDA)
    print("ok", SAIDA, folha.size)


if __name__ == "__main__":
    main()
