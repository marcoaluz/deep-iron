"""Bloco 72: a ESCADA EM ESPIRAL da referência — um poço próprio cortado na face de terra, à direita da
coluna dos andares, da superfície até o fundo: túnel escuro, poste central, degraus em hélice e um
patamar de madeira na altura de cada andar, ligando na quina da direita do chão dele. Desenho por script
(pixel art em blocos de 2 px), chamado pelo andares.py: devolve a imagem e a posição na tela do python.
"""
import math, random
from PIL import Image, ImageDraw

MADEIRA = [(92, 64, 40), (74, 50, 32), (58, 40, 26)]
CONTORNO = (22, 16, 12)
ROCHA = [(22, 20, 20), (17, 16, 16), (27, 24, 23)]
BORDA = [(78, 68, 60), (64, 56, 50)]
LAMPIAO = [(255, 210, 120), (230, 150, 60)]


def desenha(topo_y, fundo_y, x_centro, andares, largura=280, raio=94, passo=9.0):
    """andares: [(y do chão, x da quina do chão)] de cima pra baixo. Devolve (imagem, (x0, y0))."""
    rnd = random.Random(72)
    x0 = int(x_centro - largura / 2) - 160          # folga à esquerda pros patamares
    y0 = int(topo_y)
    W = largura + 160 + 20
    H = int(fundo_y - topo_y) + 40
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = x_centro - x0
    # o túnel: recorte escuro com borda irregular (em degraus de 2 px)
    for y in range(0, H, 2):
        e = 6 + int(4 * math.sin(y * 0.05) + rnd.random() * 3)
        dd = 6 + int(4 * math.sin(y * 0.043 + 1.0) + rnd.random() * 3)
        xa, xb = int(cx - largura / 2 + e), int(cx + largura / 2 - dd)
        for x in range(xa, xb, 2):
            c = ROCHA[(x // 2 + y // 2 * 3 + rnd.randrange(3)) % 3]
            k = 0.65 + 0.35 * abs((x - cx) / (largura / 2))  # mais escuro no meio (fundo do poço)
            d.rectangle([x, y, x + 1, y + 1], fill=(int(c[0] * k), int(c[1] * k), int(c[2] * k), 255))
        for (xx, cc) in ((xa, BORDA[0]), (xa + 2, BORDA[1]), (xb - 4, BORDA[1]), (xb - 2, BORDA[0])):
            d.rectangle([xx, y, xx + 1, y + 1], fill=cc + (255,))
        d.rectangle([xa - 2, y, xa - 1, y + 1], fill=CONTORNO + (255,))
        d.rectangle([xb, y, xb + 1, y + 1], fill=CONTORNO + (255,))
    # escoras: vigas atravessando o poço (atrás da escada), a cada 190 px
    for y in range(60, H - 40, 190):
        d.rectangle([int(cx - largura / 2 + 10), y, int(cx + largura / 2 - 10), y + 7], fill=(50, 36, 24, 255), outline=CONTORNO)
        d.line([(int(cx - largura / 2 + 12), y + 2), (int(cx + largura / 2 - 12), y + 2)], fill=(66, 48, 32))

    def degrau(t, frente):
        a = t * 0.42
        s = math.sin(a)
        if (s > 0) != frente:
            return
        x = cx + math.cos(a) * raio
        y = 8 + t * passo
        luz = 1.0 if frente else 0.5
        cor = tuple(int(c * luz) for c in MADEIRA[int(t) % 2])
        borda = tuple(int(c * luz) for c in MADEIRA[2])
        # tábua: do poste até a ponta (inclina com o ângulo)
        xa, xb = (cx, x) if x > cx else (x, cx)
        d.polygon([(xa, y), (xb, y + 4 * math.cos(a)), (xb, y + 4 * math.cos(a) + 8), (xa, y + 8)], fill=cor, outline=CONTORNO)
        d.line([(xa + 1, y + 2), (xb - 1, y + 4 * math.cos(a) + 2)], fill=tuple(min(255, int(c * 1.25)) for c in cor))
        d.line([(xa + 1, y + 6), (xb - 1, y + 4 * math.cos(a) + 6)], fill=borda)
        if frente:  # corrimão: um pino na ponta
            d.rectangle([x - 1, y - 14, x + 1, y], fill=MADEIRA[2], outline=CONTORNO)

    n = int((H - 30) / passo)
    for t in range(n):
        degrau(t, False)
    # o poste central
    d.rectangle([cx - 7, 0, cx + 6, H - 20], fill=MADEIRA[1], outline=CONTORNO)
    d.line([(cx - 3, 0), (cx - 3, H - 20)], fill=MADEIRA[0])
    d.line([(cx + 3, 0), (cx + 3, H - 20)], fill=MADEIRA[2])
    for t in range(n):
        degrau(t, True)
    # corrimão da frente: corda ligando os pinos
    pts = [(cx + math.cos(t * 0.42) * raio, 8 + t * passo - 14) for t in range(n) if math.sin(t * 0.42) > 0]
    for a, b in zip(pts, pts[1:]):
        if abs(a[1] - b[1]) < passo * 4:
            d.line([a, b], fill=(140, 110, 70))
    # patamar em cada andar: passarela de tábuas do poço até a quina do chão
    for (yf, xq) in andares:
        y = yf - y0
        xa = int(xq - x0)
        xb = int(cx + raio * 0.6)
        if xb <= xa:
            continue
        d.rectangle([xa, y - 6, xb, y + 6], fill=MADEIRA[0], outline=CONTORNO)
        for x in range(xa + 6, xb, 10):
            d.line([(x, y - 5), (x, y + 5)], fill=MADEIRA[2])
        for x in (xa + 4, xb - 4):  # esteios
            d.rectangle([x - 2, y + 6, x + 2, y + 34], fill=MADEIRA[1], outline=CONTORNO)
        d.line([(xa, y - 16), (xb, y - 16)], fill=(140, 110, 70))  # corrimão de corda
        for x in range(xa, xb, 24):
            d.rectangle([x - 1, y - 18, x + 1, y - 6], fill=MADEIRA[2])
        # lampião pendurado no meio do patamar
        lx = (xa + xb) // 2
        d.line([(lx, y - 30), (lx, y - 22)], fill=CONTORNO)
        d.rectangle([lx - 3, y - 22, lx + 3, y - 14], fill=LAMPIAO[1], outline=CONTORNO)
        d.rectangle([lx - 1, y - 20, lx + 1, y - 16], fill=LAMPIAO[0])
    return img, (x0, y0)
