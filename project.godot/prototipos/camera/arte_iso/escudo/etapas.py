"""PROTÓTIPO: as 4 etapas do Escudo solar (escudo.gd: fundacao, bobinas, nucleo, emissor)
recortadas do desenho pronto por regiões (retângulos em pixels do quadro 310x420).

  python etapas.py   -> etapa_1_fundacao.png ... etapa_4_emissor.png (= pronto)

Sem geração: cada etapa acrescenta as peças da seguinte, no mesmo lugar (mesma âncora).
"""
from PIL import Image
import numpy as np

EMISSOR = [(112, 0, 200, 142)]                                   # prato + mastro
BOBINAS = [(38, 122, 78, 282), (112, 84, 142, 138), (232, 122, 268, 278), (163, 178, 207, 318)]
NUCLEO = [(82, 134, 238, 302)]                                   # gaiola do núcleo, cabos, escadas


def mascara(shape, rects):
    m = np.zeros(shape[:2], bool)
    for x0, y0, x1, y1 in rects:
        m[y0:y1, x0:x1] = True
    return m


a = np.array(Image.open("pronto.png").convert("RGBA"))
bob, nuc, emi = mascara(a.shape, BOBINAS), mascara(a.shape, NUCLEO), mascara(a.shape, EMISSOR)
etapas = {
    "1_fundacao": ~(bob | nuc | emi),
    "2_bobinas": ~((nuc & ~bob) | emi),
    "3_nucleo": ~(emi & ~bob),
    "4_emissor": np.ones(a.shape[:2], bool),
}
# o topo da plataforma (elipse) fica à mostra onde a peça saiu: preenche com a pedra da própria
# plataforma, tirada da mesma linha 110 px pro lado (onde não tem peça)
CX, CY, RX, RY = 155, 292, 146, 72


def tapa(b, keep):
    H, W = keep.shape
    for y in range(H):
        for x in range(W):
            if keep[y, x] or ((x - CX) / RX) ** 2 + ((y - CY) / RY) ** 2 > 1:
                continue
            for dx in sorted(range(-150, 151, 2), key=lambda d: (abs(abs(d) - 110), d)):
                sx = x + dx
                if 0 <= sx < W and keep[y, sx] and a[y, sx, 3] > 40 and ((sx - CX) / RX) ** 2 + ((y - CY) / RY) ** 2 <= 1:
                    b[y, x] = a[y, sx]; break
    return b


for nome, keep in etapas.items():
    b = a.copy(); b[~keep] = 0
    if nome != "4_emissor":
        b = tapa(b, keep)
    # tira pedacinhos soltos (corrimão cortado pela região)
    from PIL import Image as _I
    Image.fromarray(b).save("etapa_%s.png" % nome)
print("ok")
