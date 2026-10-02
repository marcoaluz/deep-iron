"""Prompt 26: o LOGO "DEEP IRON" em pixel art, com a fonte de título do Prompt 22 como base:
letra de ferro em faixas (luz em cima), manchas de ferrugem, rebites, contorno escuro e um brilho
quente embaixo (o fogo da mina). Também copia as key arts pro jogo.
  python titulo/logo.py -> assets/game/ui/titulo/{logo.png, keyart_a.png, keyart_b.png}"""
import os, sys, shutil, random
import numpy as np
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(AQUI, "..", "fontes"))
DEST = os.path.normpath(os.path.join(AQUI, "../../../../assets/game/ui/titulo"))
os.makedirs(DEST, exist_ok=True)
ORDEM = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,!?:;'\"-+()0123456789/%*=_$"
at = np.array(Image.open(os.path.join(AQUI, "..", "fontes", "titulo_atlas.png")).convert("RGBA"))[..., 3] > 100
CEL = 32
cols = at.shape[1] // CEL


def glifo(ch):
    i = ORDEM.index(ch)
    m = at[(i // cols) * CEL:(i // cols + 1) * CEL, (i % cols) * CEL:(i % cols + 1) * CEL]
    xs = np.nonzero(m.any(0))[0]
    return m[:, xs.min():xs.max() + 1]


Z = 3  # 1 px da fonte = 3 px do logo (fica nítido em 1x e em 2x)
texto = "DEEP IRON"
partes = []
for ch in texto:
    if ch == " ":
        partes.append(np.zeros((CEL, 8), bool))
    else:
        partes.append(glifo(ch))
        partes.append(np.zeros((CEL, 2), bool))
m = np.concatenate(partes, axis=1)
ys = np.nonzero(m.any(1))[0]
m = m[ys.min():ys.max() + 1]
m = np.kron(m, np.ones((Z, Z), bool))
H, W = m.shape
pad = 8
canvas = np.zeros((H + pad * 2, W + pad * 2), bool)
canvas[pad:pad + H, pad:pad + W] = m
m = canvas
H, W = m.shape
img = np.zeros((H, W, 4), np.float32)
# ferro em faixas (de cima pra baixo: claro, aço, escuro, ferrugem)
faixas = [(236, 222, 200), (196, 186, 172), (150, 140, 130), (110, 96, 86), (122, 70, 40)]
ys, xs = np.nonzero(m)
y0, y1 = ys.min(), ys.max()
for y, x in zip(ys, xs):
    k = (y - y0) / max(1, (y1 - y0))
    img[y, x, :3] = faixas[min(int(k * len(faixas)), len(faixas) - 1)]
    img[y, x, 3] = 255
# ferrugem (manchas em blocos de Z px) e rebites nos cantos de cada letra
rnd = random.Random(7)
for _ in range(int(len(ys) / (Z * Z) * 0.09)):
    i = rnd.randrange(len(ys))
    by, bx = ys[i] // Z * Z, xs[i] // Z * Z
    cor = rnd.choice([(150, 72, 34), (120, 56, 28), (176, 96, 46)])
    for dy in range(Z):
        for dx in range(Z):
            if m[by + dy, bx + dx]:
                img[by + dy, bx + dx, :3] = cor
# borda: luz de 1 bloco em cima, sombra embaixo
up = np.zeros_like(m); up[Z:] = m[:-Z]
dn = np.zeros_like(m); dn[:-Z] = m[Z:]
topo = m & ~up
base = m & ~dn
img[topo, :3] = (255, 244, 220)
img[base, :3] = (70, 46, 34)
# contorno escuro (2 px) e brilho quente embaixo (o fogo da mina), fora da letra
viz = np.zeros_like(m)
for dy in (-2, -1, 0, 1, 2):
    for dx in (-2, -1, 0, 1, 2):
        viz |= np.roll(np.roll(m, dy, 0), dx, 1)
borda = viz & ~m
img[borda] = (22, 14, 10, 255)
brilho = np.zeros_like(m)
for dy in (3, 4, 5):
    brilho |= np.roll(m, dy, 0)
brilho &= ~viz
img[brilho] = (255, 120, 40, 150)
Image.fromarray(img.clip(0, 255).astype(np.uint8), "RGBA").save(os.path.join(DEST, "logo.png"))
for k in ("keyart_a", "keyart_b"):  # (sem pixel transparente nas bordas)
    ka = Image.open(os.path.join(AQUI, k + ".png")).convert("RGBA")
    fundo = Image.new("RGBA", ka.size, (16, 12, 10, 255))
    fundo.alpha_composite(ka)
    a = np.array(fundo.convert("RGB")).astype(int)
    claro = (a.mean(2) > 200).mean(0) > 0.6  # colunas quase brancas nas bordas (sobra do gerador)
    x0 = 0
    while x0 < a.shape[1] // 4 and claro[x0]:
        x0 += 1
    x1 = a.shape[1]
    while x1 > a.shape[1] * 3 // 4 and claro[x1 - 1]:
        x1 -= 1
    linhas = (a.mean(2) > 200).mean(1) > 0.6
    y1 = a.shape[0]
    while y1 > a.shape[0] * 3 // 4 and linhas[y1 - 1]:
        y1 -= 1
    fundo.convert("RGB").crop((x0, 0, x1, y1)).save(os.path.join(DEST, k + ".png"))
    print(" ", k, "corte", x0, x1, y1)
print("logo", W, "x", H)
