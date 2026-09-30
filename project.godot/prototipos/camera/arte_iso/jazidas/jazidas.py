"""PROTÓTIPO: jazidas, minérios, rochas e achados (Prompt 8).

  python jazidas.py monta          -> final/ (jazidas por minério e estágio, pilhas, pedaços, rochas, ...)
  python jazidas.py prancha <png>  -> prancha de entrega

Jazidas, pilhas e pedaços foram gerados UMA vez com o minério em turquesa (cor de marcação,
bem separada da rocha). Aqui o turquesa vira a rampa de cada minério do jogo (Ores em
scripts/core/ores.gd): ferro, cobre, carvão, prata, solarita. Mesma leitura de desgaste
pros 5, custo de 1 geração em vez de 5.
"""
import sys, os, colorsys, math, random
from PIL import Image, ImageDraw

C = lambda pasta, i: Image.open("%s/candidatos/c%02d.png" % (pasta, i)).convert("RGBA")

# estágios da jazida (do mesmo lote): cheia, meia, quase vazia, esgotada (minério apagado)
JAZIDA = {"cheia": 3, "meia": 0, "quase": 4, "esgotada": 7}
PILHA = {"pequena": 1, "media": 13, "grande": 15}
PEDACO = (0, 3, 10, 16, 24, 36)
ROCHAS = (1, 0, 3, 15, 5, 11)                 # alta pontuda, larga, redonda, partida, blocos, com filhote
MUSGO = (0, 3, 8, 10, 2, 9)
ROCHAS_MINA = (5, 14, 11)                     # do lote de rochas (sem capim) -> recolor azul-rocha
PEDRAS = (0, 3, 5, 11, 17, 24, 29, 45)
CRISTAIS = {"ciano": (12, 0), "lima": (13, 9), "violeta": (10, 14), "brasa": (15, 7)}
ACHADOS = {"bobina": 5, "cristal": 2, "peca": 9, "painel_solar": 1}
ENTULHO = {"espalhado": 12, "pequeno": 1, "medio": 5, "grande": 13}

# rampas do minério (escuro -> brilho), a partir das cores do jogo
RAMPAS = {
    "ferro":    [(48, 24, 24), (98, 44, 40), (148, 76, 64), (190, 146, 134)],   # hematita: vermelho-ferrugem
    "cobre":    [(30, 72, 62), (58, 124, 102), (196, 116, 64), (238, 178, 112)], # pátina verde + brilho de cobre
    "carvao":   [(14, 14, 18), (30, 30, 38), (58, 60, 74), (118, 124, 150)],
    "prata":    [(78, 82, 94), (134, 140, 156), (192, 198, 214), (236, 240, 250)],
    "solarita": [(150, 92, 12), (228, 170, 32), (255, 214, 80), (255, 246, 190)],  # ouro luminoso
}
ROCHA_MINA = [(24, 28, 34), (44, 52, 62), (70, 82, 94), (104, 118, 130)]   # azul-rocha da caverna


def e_minerio(p):
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in p[:3]))
    return 0.40 < h < 0.58 and s > 0.30 and v > 0.25


def recolor(im, rampa, filtro=e_minerio):
    """troca os pixels que passam no filtro pela rampa, pelo brilho relativo (4 níveis)."""
    out = im.copy(); px = out.load()
    vs = sorted(colorsys.rgb_to_hsv(*(c / 255 for c in px[x, y][:3]))[2]
                for y in range(out.height) for x in range(out.width) if px[x, y][3] > 40 and filtro(px[x, y]))
    if not vs:
        return out
    q = [vs[int(len(vs) * f)] for f in (0.25, 0.5, 0.8)]
    for y in range(out.height):
        for x in range(out.width):
            p = px[x, y]
            if p[3] > 40 and filtro(p):
                v = colorsys.rgb_to_hsv(*(c / 255 for c in p[:3]))[2]
                k = sum(v > t for t in q)
                px[x, y] = rampa[k] + (p[3],)
    return out


def sem_minerio(im):
    """esgotada: o minério vira rocha (a cor de rocha mais parecida em brilho)."""
    out = im.copy(); px = out.load()
    rocha = [px[x, y][:3] for y in range(out.height) for x in range(out.width)
             if px[x, y][3] > 40 and not e_minerio(px[x, y])]
    rocha = sorted(set(rocha), key=lambda c: sum(c))
    for y in range(out.height):
        for x in range(out.width):
            p = px[x, y]
            if p[3] > 40 and e_minerio(p):
                v = sum(p[:3]) * 0.6
                px[x, y] = min(rocha, key=lambda c: abs(sum(c) - v)) + (p[3],)
    return out


def rocha_para_mina(im):
    """rocha marrom da superfície -> azul-rocha da caverna, pela luminância."""
    return recolor(im, ROCHA_MINA, filtro=lambda p: True)


def limpa_sombra_clara(im):
    """as pedrinhas vieram com uma linha clara embaixo (sombra desenhada ao contrário): tira."""
    out = im.copy(); px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            p = px[x, y]
            if p[3] > 40:
                h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in p[:3]))
                baixo = y + 1 >= out.height or px[x, y + 1][3] < 40
                if baixo and v > 0.55 and s < 0.2:
                    px[x, y] = (0, 0, 0, 0)
    return out


def lascas(rampa, n=6, seed=1):
    """folha de lascas do golpe: 7 pedrinhas (rocha e minério) saem do ponto e caem."""
    rnd = random.Random(seed)
    cores = [(62, 54, 48), (40, 34, 30)] + rampa[1:3]
    parts = [(rnd.uniform(-1, 1), rnd.uniform(-2.2, -0.8), rnd.choice(cores), rnd.choice((1, 2))) for _ in range(7)]
    W, H = 40, 32
    folha = Image.new("RGBA", (W * n, H), (0, 0, 0, 0)); d = ImageDraw.Draw(folha)
    for f in range(n):
        t = f + 0.5
        for vx, vy, c, s in parts:
            x = W / 2 + vx * 3.2 * t; y = H - 8 + vy * 3.0 * t + 0.45 * t * t
            if y < H - 2:
                d.rectangle([f * W + x, y, f * W + x + s - 1, y + s - 1], fill=c + (255,))
                d.point((f * W + x + s, y + s), fill=(12, 10, 9, 255))
    return folha


def salva(im, f):
    os.makedirs(os.path.dirname(f), exist_ok=True)
    b = im.getbbox()
    (im.crop(b) if b else im).save(f)


def monta():
    for est, i in JAZIDA.items():
        base = C("jazida_cheia", i)
        if est == "esgotada":
            salva(sem_minerio(base), "final/jazida_esgotada.png")
            continue
        for m, r in RAMPAS.items():
            salva(recolor(base, r), "final/jazida_%s_%s.png" % (m, est))
    for tam, i in PILHA.items():
        for m, r in RAMPAS.items():
            salva(recolor(C("pilha_minerio", i), r), "final/pilha_%s_%s.png" % (m, tam))
    for k, i in enumerate(PEDACO):
        for m, r in RAMPAS.items():
            salva(recolor(C("minerio_solto", i), r), "final/pedaco_%s_%d.png" % (m, k))
    for m, r in RAMPAS.items():
        lascas(r).save("final/lascas_%s.png" % m)
    for k, i in enumerate(ROCHAS):
        salva(C("rochas", i), "final/rocha_%d.png" % k)
    for k, i in enumerate(MUSGO):
        salva(C("rochas_musgo", i), "final/rocha_musgo_%d.png" % k)
    for k, i in enumerate(ROCHAS_MINA):
        salva(rocha_para_mina(C("rochas", i)), "final/rocha_mina_%d.png" % k)
    for k, i in enumerate(PEDRAS):
        salva(limpa_sombra_clara(C("pedras", i)), "final/pedras_%d.png" % k)
    for cor, ids in CRISTAIS.items():
        for k, i in enumerate(ids):
            salva(C("cristais", i), "final/cristal_%s_%d.png" % (cor, k))
    for nome, i in ACHADOS.items():
        salva(C("achado", i), "final/achado_%s.png" % nome)
    for nome, i in ENTULHO.items():
        salva(C("entulho", i), "final/entulho_%s.png" % nome)
    print("ok")


def prancha(saida):
    S = 2
    c = Image.new("RGB", (1640, 1180), (46, 42, 40)); d = ImageDraw.Draw(c)
    y = 6
    d.text((8, y), "JAZIDAS: cheia / meia / quase vazia (cor por minério) + esgotada (igual pra todos)", fill=(255, 230, 150)); y += 16
    for r_, m in enumerate(RAMPAS):
        x = 8
        d.text((x, y + 60), m, fill=(200, 200, 200))
        x = 80
        for est in ("cheia", "meia", "quase"):
            im = Image.open("final/jazida_%s_%s.png" % (m, est)).convert("RGBA"); im = im.resize((im.width * S, im.height * S), Image.NEAREST)
            c.paste(im, (x, y + 140 - im.height), im); x += 150
        im = Image.open("final/jazida_esgotada.png").convert("RGBA"); im = im.resize((im.width * S, im.height * S), Image.NEAREST)
        c.paste(im, (x, y + 140 - im.height), im); x += 160
        for tam in ("pequena", "media", "grande"):
            im = Image.open("final/pilha_%s_%s.png" % (m, tam)).convert("RGBA"); im = im.resize((im.width * S, im.height * S), Image.NEAREST)
            c.paste(im, (x, y + 140 - im.height), im); x += im.width + 12
        for k in range(3):
            im = Image.open("final/pedaco_%s_%d.png" % (m, k)).convert("RGBA"); im = im.resize((im.width * S, im.height * S), Image.NEAREST)
            c.paste(im, (x, y + 140 - im.height), im); x += im.width + 8
        la = Image.open("final/lascas_%s.png" % m).convert("RGBA"); la = la.resize((la.width * S, la.height * S), Image.NEAREST)
        c.paste(la, (x + 10, y + 140 - la.height), la)
        y += 150
    d.text((8, y), "ROCHAS (superficie) / COM MUSGO / DA MINA / PEDRINHAS", fill=(255, 230, 150)); y += 16
    x = 8
    for nome in ["rocha_%d" % k for k in range(4)] + ["rocha_musgo_%d" % k for k in range(4)] + ["rocha_mina_%d" % k for k in range(3)]:
        im = Image.open("final/%s.png" % nome).convert("RGBA"); im = im.resize((im.width * S, im.height * S), Image.NEAREST)
        c.paste(im, (x, y + 130 - im.height), im); x += im.width + 8
    for k in range(4):
        im = Image.open("final/pedras_%d.png" % k).convert("RGBA"); im = im.resize((im.width * S, im.height * S), Image.NEAREST)
        c.paste(im, (x, y + 130 - im.height), im); x += im.width + 6
    y += 140
    d.text((8, y), "CRISTAIS / ACHADOS (bobina, cristal, peca, painel solar) / ENTULHO", fill=(255, 230, 150)); y += 16
    x = 8
    for cor in CRISTAIS:
        for k in range(2):
            im = Image.open("final/cristal_%s_%d.png" % (cor, k)).convert("RGBA"); im = im.resize((im.width * S, im.height * S), Image.NEAREST)
            c.paste(im, (x, y + 130 - im.height), im); x += im.width + 6
    for nome in list(ACHADOS) :
        im = Image.open("final/achado_%s.png" % nome).convert("RGBA"); im = im.resize((im.width * S, im.height * S), Image.NEAREST)
        c.paste(im, (x, y + 130 - im.height), im); x += im.width + 6
    y += 140; x = 8
    for nome in ENTULHO:
        im = Image.open("final/entulho_%s.png" % nome).convert("RGBA"); im = im.resize((im.width * S, im.height * S), Image.NEAREST)
        c.paste(im, (x, y + 100 - im.height), im); x += im.width + 10
    c.save(saida)


if __name__ == "__main__":
    if sys.argv[1] == "monta":
        monta()
    else:
        prancha(sys.argv[2])
