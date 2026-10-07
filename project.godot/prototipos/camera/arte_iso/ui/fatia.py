"""Prompt 20: recorta o kit de interface gerado (kit_a.png, create_ui_asset) em peças 9-slice e
estados de botão, e grava em assets/game/ui/ com o ui.json (margens de cada peça).

  python ui/fatia.py

Peças (px do kit; achadas por componente do alfa):
  painel (janela, sem a plaquinha do título), titulo (a plaquinha), dica (couro com borda de ferro),
  cartao (+ cadeado recortado do cartão trancado), barra (viga de madeira com cintas de ferro:
  ponta + meio liso + ponta), barra_topo (a viga mais baixa), botao (4 estados), botao_icone
  (5 estados: + "on" = aceso), aba (3 estados), progresso, caixa (marcada/vazia), trilho e pino.
Os estados são feitos daqui (brilho/escurecer/dessaturar), na mesma arte.
"""
import os, json
import numpy as np
from PIL import Image, ImageOps

AQUI = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.normpath(os.path.join(AQUI, "../../../../assets/game/ui"))
os.makedirs(DEST, exist_ok=True)
KIT = Image.open(os.path.join(AQUI, "kit_a.png")).convert("RGBA")
BOX = {"janela": (9, 9, 362, 268), "dica": (375, 9, 592, 116), "cartao": (375, 129, 479, 268),
       "cartao_bloq": (484, 129, 596, 268), "barra": (9, 278, 592, 336), "botao_icone": (450, 340, 498, 388),
       "botao": (305, 342, 437, 386), "progresso": (9, 347, 292, 374), "aba": (509, 347, 592, 383),
       "caixa": (9, 387, 43, 421), "trilho": (58, 391, 337, 416), "pino": (460, 397, 487, 425)}
AMBAR = np.array([255, 196, 92], np.float32)
out = {"_obs": "Prompt 20 (ui/fatia.py): peça -> arquivo e margens do 9-slice [esq, cima, dir, baixo] (px da textura)", "pecas": {}}


def peca(nome):
    return KIT.crop(BOX[nome])


def salva(nome, im, margens=None, conteudo=None):
    im.save(os.path.join(DEST, nome + ".png"))
    d = {"img": nome + ".png", "tam": list(im.size)}
    if margens:
        d["margens"] = margens
    if conteudo:
        d["conteudo"] = conteudo
    out["pecas"][nome] = d


def arr(im):
    return np.array(im).astype(np.float32)


def img(a):
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")


def brilho(im, k, tinta=0.0):
    a = arr(im)
    a[..., :3] = a[..., :3] * k + AMBAR * tinta * (a[..., 3:4] > 0)
    return img(a)


def cinza(im, sat=0.25, k=0.7):
    a = arr(im)
    l = a[..., :3].mean(-1, keepdims=True)
    a[..., :3] = (l + (a[..., :3] - l) * sat) * k
    return img(a)


def borda_ambar(im, m):
    """Contorno âmbar de 1 px por dentro da borda (o botão "aceso")."""
    a = arr(im)
    h, w = a.shape[:2]
    for (y0, y1, x0, x1) in [(m, m + 1, m, w - m), (h - m - 1, h - m, m, w - m), (m, h - m, m, m + 1), (m, h - m, w - m - 1, w - m)]:
        a[y0:y1, x0:x1, :3] = AMBAR
        a[y0:y1, x0:x1, 3] = 255
    return img(a)


# ---- janela: tira a plaquinha do título (repete a barra lisa por cima) e guarda a plaquinha
j = peca("janela")
ja = arr(j)
liso = ja[:, 36:76].copy()
x = 76
while x < j.width - 76:
    w = min(40, j.width - 76 - x)
    ja[:56, x:x + w] = liso[:56, :w]
    x += w
salva("painel", img(ja), [34, 34, 34, 34], [18, 16, 18, 16])
salva("titulo", j.crop((78, 2, 284, 31)), [10, 6, 10, 6], [12, 4, 12, 4])
# ---- dica (tooltip, faixa de aviso)
salva("dica", peca("dica"), [16, 16, 16, 16], [12, 10, 12, 10])
# ---- cartão do menu de construção + o cadeado do trancado
c = peca("cartao")
salva("cartao", c, [18, 18, 18, 18], [10, 10, 10, 10])
salva("cartao_bloq", cinza(c, 0.2, 0.55), [18, 18, 18, 18], [10, 10, 10, 10])
salva("cartao_breve", cinza(c, 0.0, 0.75), [18, 18, 18, 18], [10, 10, 10, 10])
cb = peca("cartao_bloq")
cad = cb.crop((cb.width // 2 - 16, cb.height // 2 + 6, cb.width // 2 + 16, cb.height // 2 + 44))
salva("cadeado", cad.crop(cad.getbbox()))
# ---- viga (barra de baixo) e a viga baixa (barra de recursos do topo)
b = peca("barra")
ponta = 30
meio = b.crop((150, 0, 440, b.height))
viga = Image.new("RGBA", (ponta * 2 + meio.width, b.height))
viga.alpha_composite(b.crop((0, 0, ponta, b.height)), (0, 0))
viga.alpha_composite(meio, (ponta, 0))
viga.alpha_composite(b.crop((b.width - ponta, 0, b.width, b.height)), (ponta + meio.width, 0))
salva("barra", viga, [ponta, 14, ponta, 14], [16, 10, 16, 10])
ba = arr(viga)
baixa = np.concatenate([ba[:16], ba[viga.height // 2 - 4:viga.height // 2 + 4], ba[-16:]], axis=0)
salva("barra_topo", img(baixa), [ponta, 12, ponta, 12], [14, 6, 14, 6])
# ---- botão (4 estados) e botão de ícone (5: + aceso)
bt = peca("botao")
for st, im in [("normal", bt), ("hover", brilho(bt, 1.12, 0.10)), ("pressed", brilho(bt, 0.78)), ("disabled", cinza(bt))]:
    salva("botao_" + st, im, [8, 8, 8, 8], [10, 5, 10, 5])
bi = peca("botao_icone")
for st, im in [("normal", bi), ("hover", brilho(bi, 1.12, 0.10)), ("pressed", brilho(bi, 0.78)), ("disabled", cinza(bi)),
               ("on", borda_ambar(brilho(bi, 1.05, 0.12), 3))]:
    salva("botao_icone_" + st, im, [10, 10, 10, 10], [8, 6, 8, 6])
# ---- aba (escolhida = clara; as outras mais escuras)
ab = peca("aba")
for st, im in [("normal", brilho(ab, 0.72)), ("hover", brilho(ab, 0.9, 0.05)), ("pressed", brilho(ab, 1.1, 0.10))]:
    salva("aba_" + st, im, [8, 8, 8, 8], [10, 4, 10, 4])
# ---- barra de progresso (o recheio colorido vem do código, por dentro da moldura)
salva("progresso", peca("progresso"), [7, 7, 7, 7], [4, 4, 4, 4])
# ---- caixa de marcar (metade do tamanho: 2 px viram 1, pixel inteiro) e o "V" âmbar
cx = peca("caixa").resize((17, 17), Image.NEAREST)
salva("caixa_off", cx)
ca = arr(cx)
for (y, x) in [(8, 4), (9, 5), (10, 6), (9, 7), (8, 8), (7, 9), (6, 10), (5, 11), (4, 12)]:
    ca[y, x, :3] = AMBAR; ca[y, x, 3] = 255
    ca[y + 1, x, :3] = AMBAR * 0.55; ca[y + 1, x, 3] = 255
salva("caixa_on", img(ca))
# ---- slider: trilho sem o pino no meio (repete um pedaço liso por cima) e o pino
tr = arr(peca("trilho"))
mid = tr.shape[1] // 2
pedaco = tr[:, 20:60].copy()
x = mid - 30
while x < mid + 30:
    w = min(40, mid + 30 - x)
    tr[:, x:x + w] = pedaco[:, :w]
    x += w
salva("trilho", img(tr), [8, 6, 8, 6])
pn = peca("pino")
salva("pino", pn.crop(pn.getbbox()))
json.dump(out, open(os.path.join(DEST, "ui.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
print("ui:", len(out["pecas"]), "peças em", DEST)
