"""PROTÓTIPO: muro modular e portão (Prompt 12).

  python muro.py monta           -> final/muro_<nivel>_<peca>.png, final/portao_<estado>.png
  python muro.py prancha <png>   -> prancha + trecho de muro montado com o portão

Peças por nível (1 paliçada, 2 madeira reforçada, 3 pedra), 1 tile cada (quadro 64x112, o
losango do chão embaixo, âncora = centro do losango (32, 95)):
- reta_i (IA), reta_j (espelho da i: o muro é fino, a troca de luz quase não aparece),
- danificada (IA: o mesmo lote já trouxe uma com rombo),
- brecha (script: tira o meio do segmento e põe entulho do Prompt 8) = a "brecha" do roubo,
- ponta (script: meia reta, a outra metade vazia), canto (script: meia i + meia j).
"""
import sys, os
import numpy as np
from PIL import Image, ImageOps, ImageDraw

LOTE = {1: ("n1_i", 0, 3), 2: ("n2v2", 0, 3), 3: ("n3v2", 0, 2)}   # pasta, reta, danificada (v2: orientação da paliçada)
ENTULHO = "../jazidas/final/entulho_pequeno.png"
ANC = (32, 95)


def C(p, i):
    return Image.open("%s/candidatos/c%02d.png" % (p, i)).convert("RGBA")


def metade(im, lado):
    """metade do segmento ao longo do eixo i: 'N' (lado de cima-esquerda) ou 'S'."""
    a = np.array(im)
    H, W = a.shape[:2]
    xs = np.arange(W)[None, :]
    keep = xs < ANC[0] if lado == "N" else xs >= ANC[0]
    a[~np.broadcast_to(keep, (H, W))] = 0
    return Image.fromarray(a)


def brecha(im):
    a = np.array(im)
    H, W = a.shape[:2]
    xs = np.arange(W)
    a[:, (xs > ANC[0] - 10) & (xs < ANC[0] + 10)] = 0
    out = Image.fromarray(a)
    e = Image.open(ENTULHO).convert("RGBA")
    out.alpha_composite(e, (ANC[0] - e.width // 2, ANC[1] - e.height + 4))
    return out


def monta():
    os.makedirs("final", exist_ok=True)
    for n, (p, ir, idn) in LOTE.items():
        reta = C(p, ir)
        reta_j = ImageOps.mirror(reta)
        dano = C(p, idn)
        pecas = {"reta_i": reta, "reta_j": reta_j, "danificada": dano, "brecha": brecha(reta),
                 "ponta": metade(reta, "N"), "canto": None}
        # canto: o muro vem da borda NO até o centro (metade de cima-esquerda do eixo i) e vira
        # pra borda NE (metade da direita do eixo j)
        c = metade(reta_j, "S").copy(); c.alpha_composite(metade(reta, "N")); pecas["canto"] = c
        for k, im in pecas.items():
            im.save("final/muro_%d_%s.png" % (n, k))
    for k in ("portao_quebrado", "portao_1", "portao_2", "portao_3"):
        Image.open("%s.png" % k).convert("RGBA").save("final/%s.png" % k)
    print("ok")


def prancha(saida):
    AM = (255, 230, 150)
    c = Image.new("RGB", (1420, 720), (62, 58, 54)); d = ImageDraw.Draw(c)
    y = 6
    for n in (1, 2, 3):
        d.text((8, y), "MURO NIVEL %d: reta i / reta j / canto / ponta / danificada / brecha" % n, fill=AM); y += 14
        for k, pc in enumerate(("reta_i", "reta_j", "canto", "ponta", "danificada", "brecha")):
            im = Image.open("final/muro_%d_%s.png" % (n, pc)).convert("RGBA"); im = im.crop((0, 20, 64, 112))
            im = im.resize((128, 184), Image.NEAREST)
            c.paste(im, (8 + k * 136, y), im)
        y += 220
    # trecho montado: 3 segmentos de cada lado do portão (nível 2), ao longo do eixo i
    d.text((840, 6), "TRECHO MONTADO (nivel 2): muro + portao + danificada + brecha", fill=AM)
    tela = lambda i: (i * 32, i * 16)
    seq = ["reta_i", "reta_i", "danificada", None, None, "reta_i", "brecha", "reta_i"]
    base = Image.new("RGBA", (460, 420))
    ox, oy = 20, 120
    for i, pc in enumerate(seq):
        if pc:
            im = Image.open("final/muro_2_%s.png" % pc).convert("RGBA"); x, y2 = tela(i)
            base.alpha_composite(im, (ox + x, oy + y2))
    g = Image.open("final/portao_2.png").convert("RGBA")
    gx, gy = tela(3)
    base.alpha_composite(g, (ox + gx - 10, oy + gy - 88))
    c.paste(base, (840, 20), base)
    # portões
    d.text((840, 450), "PORTAO: quebrado / nivel 1 / nivel 2 / nivel 3", fill=AM)
    x = 840
    for k in ("portao_quebrado", "portao_1", "portao_2", "portao_3"):
        im = Image.open("final/%s.png" % k).convert("RGBA"); im = im.crop(im.getbbox())
        c.paste(im, (x, 690 - im.height), im); x += im.width + 8
    c.save(saida)


if __name__ == "__main__":
    monta() if sys.argv[1] == "monta" else prancha(sys.argv[2])
