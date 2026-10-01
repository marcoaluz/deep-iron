"""PROTÓTIPO: mapa montado com a arte nova (Prompt 27, passo 2).

  python monta.py  -> mapa_montado.png (tamanho real) e mapa_montado_meio.png (50%)

Layout = o esboço aprovado (esboco.py), em coordenadas do jogo ANTIGO × 1,5 (os prédios
continuam em escala real; × 2,1 deixava o mapa ralo). Tile = 32 no chão. Relevo:
floresta e terraço de cima = 3; terraço das oficinas (oeste) = 2; fundo da pedreira = 0.
As bocas de mina ficam no paredão de 3 degraus entre o terraço de cima e o fundo (a face
que olha pra câmera). Paredão de terra e rocha (4) nas bordas de trás (oeste).
Desenho: terreno coluna a coluna (tiles.py) + objetos ordenados pela frente da pegada.
"""
import sys, os, json, glob, math, random
from PIL import Image, ImageOps
sys.path.insert(0, "../relevo")
import tiles

FATOR = 1.5          # posições do esboço × 1,5 (prédios ficam no tamanho real; mapa mais denso)
T = 32
OX, OY = -760 * FATOR, -1040 * FATOR            # canto do mapa (mundo novo)
NI = int(1520 * FATOR / T)                        # 99
NJ = int(1480 * FATOR / T)                        # 97
REL = "../relevo/final"
TOPO_MOLDURA = 18    # a moldura é aparada no alto (i + j > -18): o topo fica na horizontal, na altura da serra pintada
MARGEM = 26          # moldura fora da área jogável (só decoração): morros com mata que sobem até a serra do cenário


def ruido(i, j, s):
    """relevo suave (soma de senos), -1..1."""
    return (math.sin(i * 0.21 + s) + math.sin(j * 0.17 + 2 * s) + math.sin((i + j) * 0.11 + 3 * s)
            + math.sin((i - j) * 0.09 + 0.5 * s)) / 4


def tile(xo, yo):
    """coordenada do jogo antigo -> tile (i, j) fracionário no mapa novo."""
    return (xo * FATOR - OX) / T, (yo * FATOR - OY) / T


def ld(p):
    return [Image.open(f).convert("RGBA") for f in sorted(glob.glob(p + "/chao_*.png"))]


# ---------------------------------------------------------------- relevo e tipo de chão
def zona(xo, yo):
    """zona e altura num ponto do jogo antigo."""
    if xo < -700:
        return "paredao", 4
    if yo < -470:
        return "floresta", 3
    if yo < -180:
        return "terraco_alto", 3
    if xo < 120 and yo < 160:
        return "terraco_meio", 2
    return "fundo", 0


def tipo_chao(xo, yo, z):
    rnd = (math.sin(xo * 0.013) + math.cos(yo * 0.017) + math.sin((xo + yo) * 0.007))
    if z == "floresta":
        return "grama_alta" if rnd > 1.2 or abs(xo) > 680 else "clareira"
    if z == "terraco_alto":
        if (xo + 300) ** 2 + (yo + 300) ** 2 < 120 ** 2:
            return "laje"
        if abs(xo) < 40 or (abs(yo + 230) < 22 and -500 < xo < 600):
            return "trilha"
        return "colonia"
    if z == "terraco_meio":
        if abs(yo - 10) < 22 or abs(xo + 80) < 20:
            return "trilha"
        return "cascalho" if rnd > 0.9 else "colonia"
    if z == "fundo":
        return "cascalho" if rnd > -0.4 else "colonia"
    return "grama_alta" if rnd > 0.6 else "colonia"


def monta():
    TEX = {"colonia": ld(REL + "/colonia"), "clareira": ld(REL + "/clareira"), "rocha": ld(REL + "/rocha")}
    for p in ("grama_alta", "trilha", "cascalho", "laje"):
        TEX[p] = ld(REL + "/superficie/" + p)
    ordem = ["rocha", "colonia", "cascalho", "trilha", "laje", "clareira", "grama_alta"]
    BL = {}
    for m in ("colonia", "rocha", "clareira"):
        b = [Image.open(f).convert("RGBA") for f in sorted(glob.glob(REL + "/%s/bloco.png" % m) + glob.glob(REL + "/%s/bloco_[0-9].png" % m))]
        s = [Image.open(f).convert("RGBA") for f in sorted(glob.glob(REL + "/%s/bloco_sem_beira*.png" % m))]
        BL[m] = (b, s)
    esc_pedra = Image.open(REL + "/superficie/escada_pedra_N.png").convert("RGBA")
    rampa = Image.open(REL + "/superficie/rampa_N.png").convert("RGBA")

    def antigo(i, j):
        return ((OX + (i + 0.5) * T) / FATOR, (OY + (j + 0.5) * T) / FATOR)

    alt, mat, tipo_v = {}, {}, {}
    for i in range(NI):
        for j in range(NJ):
            xo, yo = antigo(i, j)
            z, h = zona(xo, yo)
            alt[(i, j)] = h
            mat[(i, j)] = "clareira" if z == "floresta" else "colonia"
    for i in range(NI + 1):
        for j in range(NJ + 1):
            xo, yo = ((OX + i * T) / FATOR, (OY + j * T) / FATOR)
            z, _ = zona(xo, yo)
            tipo_v[(i, j)] = tipo_chao(xo, yo, z)
    # moldura: atrás (i < 0: atrás do paredão; j < 0: atrás da floresta) o chão continua e sobe em
    # morros; perto da frente ela afina pra altura da borda, pra o corte do relevo não virar um paredão
    longe = {}
    for i in range(-MARGEM, NI):
        for j in range(-MARGEM, NJ):
            if i >= 0 and j >= 0 or -(i + j) > TOPO_MOLDURA:
                continue
            d = max(-i, -j)
            h0 = alt[(max(i, 0), max(j, 0))]
            fr = 1.0
            if i < 0 <= j:
                fr = min(1.0, max(0.0, (NJ - 1 - j) / 16))
            if j < 0 <= i:
                fr = min(1.0, max(0.0, (NI - 1 - i) / 16))
            # morros largos (ruído lento) + ondulação; a subida geral é suave, pra as curvas de nível
            # serpentearem em vez de correrem paralelas à borda
            morro = 2.6 * ruido(i * 0.45, j * 0.45, 1.3) + 2.2 * ruido(i * 1.6, j * 1.4, 4.1) + 0.9 * ruido(i * 3.7, j * 3.3, 6.0)
            sobe = max(0, d - 3) * 0.30 + min(1.0, d / 3) * morro      # perto da borda: chão plano com morrinhos soltos
            alt[(i, j)] = h0 + int(round(max(0.0, sobe) * fr))
            mat[(i, j)] = "clareira"
            longe[(i, j)] = min(1.0, max(d / MARGEM, -(i + j) / TOPO_MOLDURA))
    for (i, j) in longe:     # encosta íngreme (2+ degraus) ou logo atrás do paredão = rocha exposta
        h = alt[(i, j)]
        if max(h - alt.get((i + 1, j), h), h - alt.get((i, j + 1), h)) >= 2:
            mat[(i, j)] = "colonia"      # barranco de terra (a rocha azulada lia como água)
    for i in range(-MARGEM, NI + 1):
        for j in range(-MARGEM, NJ + 1):
            if i < 0 or j < 0:
                tipo_v[(i, j)] = "grama_alta" if ruido(i * 1.7, j * 1.9, 2.2) > -0.25 else "clareira"
    # escadas e rampas (no tile de baixo, subindo pro norte): (x, y antigos)
    # subidas: (x, y antigos, imagem, quantos degraus abaixo do topo) - escada N sobe pro norte
    subidas = [(-80, -165, esc_pedra, 1), (-300, -165, esc_pedra, 1), (640, -160, esc_pedra, 3), (0, 172, rampa, 2), (-420, 172, esc_pedra, 2)]
    esc_tiles = {}
    for xo, yo, im, n in subidas:
        i, j = map(int, tile(xo, yo))
        h0 = alt[(i, j - 1)]          # topo de onde a escada desce
        for d in range(n):            # um lance por degrau, descendo pro sul
            for di in (0, 1):
                esc_tiles[(i + di, j + d)] = im
                alt[(i + di, j + d)] = h0 - 1 - d

    # bocas de mina: cavadas no paredão (as 2 colunas da borda do terraço de cima viram a boca)
    bocas = []
    for xo in (200, 380, 540):
        i, j = map(int, tile(xo, -181))
        while alt.get((i, j + 1), 0) >= 3:      # desce até a última fileira do terraço
            j += 1
        bocas.append((i, j))
    tiles_boca = {(i + d, j) for i, j in bocas for d in (0, 1)}

    def topo_fn(i, j):
        if mat[(i, j)] == "rocha":
            return tiles.escolhe(TEX["rocha"], i, j, 99)
        cant = (tipo_v[(i, j)], tipo_v[(i + 1, j)], tipo_v[(i + 1, j + 1)], tipo_v[(i, j + 1)])
        tex = {t: tiles.escolhe(TEX[t], i, j, 90 + k) for k, t in enumerate(ordem)}
        return tiles.topo_misto(i, j, cant, tex, ordem)

    def P(u, v, k):
        return ((u - v) * T + 32, (u + v) * 16 - k * 32)

    itens = []
    for (i, j), h in alt.items():
        if (i, j) in tiles_boca:
            continue
        com, sem = BL[mat[(i, j)]]
        # bordas da FRENTE do mapa (i ou j máximos): o terreno desce 4 degraus (corte do relevo
        # visto pela câmera) em vez de acabar no vazio; as de trás ficam escondidas
        CORTE = -4
        viz = [alt.get((i + a, j + b), CORTE if (i + a >= NI or j + b >= NJ) else h) for a in (-1, 0, 1) for b in (-1, 0, 1)]
        base = min(min(viz), h)
        if (i, j) in esc_tiles:
            for k in range(base + 1, h + 1):
                itens.append((i + j, k, 0, tiles.escolhe(sem, i, j, k, False), tiles.tela(i, j, k)))
            itens.append((i + j, h + 1, 0, esc_tiles[(i, j)], tiles.tela(i, j, h + 1)))
            continue
        nv = longe.get((i, j), 0)
        tp = topo_fn(i, j)
        if h == base:
            itens.append((i + j, base, 0, tp, tiles.tela(i, j, base), nv))
        for k in range(base + 1, h + 1):
            b = tiles.escolhe(com if k == h else sem, i, j, k, False).copy()
            if k == h:
                b.paste(tp, (0, 0), tp)
            if k < 0:      # o corte escurece pra baixo (vai sumir na névoa do cenário)
                b = tiles.escurece(b, 0.82 ** (-k))
            itens.append((i + j, k, 0, b, tiles.tela(i, j, k), nv))

    # ------------------------------------------------------------ objetos
    def obj(img, xo, yo, anc, pegada_tiles=(1, 1), h=None):
        u, v = tile(xo, yo)
        if h is None:
            h = alt.get((int(u), int(v)), 0)
        x, y = P(u, v, h)
        frente = u + v + (pegada_tiles[0] + pegada_tiles[1]) / 2.0
        itens.append((frente, h + 0.5, 1, img, (int(x - anc[0]), int(y - anc[1]))))

    def predio(pasta, arq, xo, yo):
        d = json.load(open("../%s/predio.json" % pasta))
        fw, fd = d["caixa_guia"][0], d["caixa_guia"][1]
        obj(Image.open("../%s/%s" % (pasta, arq)).convert("RGBA"), xo, yo, d["ancora"], (fw / T, fd / T))

    def solto(f, xo, yo, h=None, esc=1.0):
        im = Image.open(f).convert("RGBA")
        b = im.getbbox(); im = im.crop(b)
        if esc != 1.0:
            im = im.resize((int(im.width * esc), int(im.height * esc)), Image.NEAREST)
        obj(im, xo, yo, (im.width / 2, im.height - 3), (1, 1), h)

    casa = json.load(open("../casa/contrato_casa.json"))["ancora_no_quadro"]
    for k, (xo, yo) in enumerate([(-560, -380), (-620, -260), (-470, -240), (-140, -380), (-60, -260), (-200, -250)]):
        obj(Image.open("../casa/casa_v%d.png" % (k % 4)).convert("RGBA"), xo, yo, casa, (4, 3))
    predio("centro/estagio_3", "pronto.png", -300, -300)
    for pasta, xo, yo in [("taverna", 130, -370), ("enfermaria", 300, -380), ("parque", 470, -360), ("cozinha", 600, -290),
                          ("laboratorio", 420, -260), ("vestiario", 220, -260),
                          ("oficina", -560, -90), ("fundicao", -380, -60), ("arsenal", -200, -90), ("armazem", -20, 60),
                          ("campo_treino", -560, 90)]:
        predio(pasta, "pronto.png", xo, yo)
    predio("escavadeira", "pronto.png", -560, 330)
    predio("elevador", "pronto.png", 580, 320)
    predio("coletor_madeira", "quebrada.png", -620, -780)
    solto("../objetos/final/guindaste_pedreira.png", -280, 100)
    # portão (quebrado) da floresta e o portão do poço, + muro de paliçada ao longo da borda
    solto("../muro/final/portao_quebrado.png", 0, -455)
    solto("../muro/final/portao_quebrado.png", 430, 400)   # portão do poço, ao lado do elevador
    for xo in range(-740, 760, int(T / FATOR)):
        if abs(xo) > 50:
            solto("../muro/final/muro_1_reta_i.png" if (xo // 15) % 7 else "../muro/final/muro_1_danificada.png", xo, -462)
    # bocas de mina no paredão do fundo
    boca = Image.open("../relevo/final/superficie/boca_mina.png").convert("RGBA")
    for i, j in bocas:          # quadro da boca: canto N do topo em (34, 2) -> tela(i, j, 3) - (2, 2)
        x, y = tiles.tela(i, j, 3)
        itens.append((i + j + 1, 3.5, 0, boca, (x - 2, y - 2)))
        for d in (0, 1):        # o topo da boca = o chão do terraço
            itens.append((i + j + 2, 3.6, 0, topo_fn(i + d, j), tiles.tela(i + d, j, 3)))
    # trilho mina -> armazém (por cima do chão: peças retas ao longo do eixo j)
    tr = Image.open("../relevo/final/mina/trilhos/reto_j.png").convert("RGBA")
    for yo in range(-140, 60, int(T / FATOR)):
        u, v = tile(200, yo)
        h = alt.get((int(u), int(v)), 0)
        x, y = P(int(u) + 0.5, int(v) + 0.5, h)
        itens.append((int(u) + int(v) + 0.1, h + 0.05, 0, tr, (int(x - 32), int(y - 16))))
    solto("../objetos/final/vagonete_cheio_SE.png", 200, -60)
    # jazidas no fundo
    for k, (xo, yo) in enumerate([(-300, 300), (-120, 360), (60, 300), (300, 330), (420, 120), (640, 200)]):
        m = ["ferro", "cobre", "carvao", "prata", "ferro", "carvao"][k]
        solto("../jazidas/final/jazida_%s_cheia.png" % m, xo, yo)
    # floresta: árvores, tocas, horta, robô achado
    rnd = random.Random(7)
    arv = sorted(glob.glob("../vegetacao/final/arvore_*.png"))
    livres = [(-620, -780), (-380, -700), (180, -780), (560, -800), (-100, -690), (380, -700), (0, -520)]
    n = 0
    while n < 70:
        xo, yo = rnd.uniform(-690, 750), rnd.uniform(-1030, -520)
        if any((xo - a) ** 2 + (yo - b) ** 2 < 75 ** 2 for a, b in livres) or abs(xo) < 60 and yo > -620:
            continue
        solto(rnd.choice(arv), xo, yo); n += 1
    veg = sorted(glob.glob("../vegetacao/final/arbusto_*.png") + glob.glob("../vegetacao/final/capim_*.png")
                 + glob.glob("../vegetacao/final/flores_*.png") + glob.glob("../vegetacao/final/samambaia_*.png")
                 + glob.glob("../vegetacao/final/tronco_musgo_*.png") + glob.glob("../vegetacao/final/cogumelos_*.png"))
    for _ in range(90):
        xo, yo = rnd.uniform(-690, 750), rnd.uniform(-1030, -490)
        if abs(xo) < 50 and yo > -560:
            continue
        solto(rnd.choice(veg), xo, yo)
    for f, xo, yo in [("../animais/final/toca_coelho_fora.png", -380, -700), ("../animais/final/toca_coelho_orelhas.png", 180, -780),
                      ("../animais/final/toca_javali.png", 560, -800), ("../vegetacao/final/horta_pronto.png", -100, -700),
                      ("../vegetacao/final/horta_crescendo.png", -60, -680), ("../vegetacao/final/horta_espantalho.png", -140, -660),
                      ("../robo/estados/achado.png", 380, -700)]:
        solto(f, xo, yo)
    # decoração: rochas, arbustos, tochas, caixotes
    deco = [("../jazidas/final/rocha_musgo_%d.png" % (k % 6), xo, yo) for k, (xo, yo) in enumerate(
        [(-560, -900), (320, -1000), (680, -780), (-700, -560), (100, -900)])]
    deco += [("../vegetacao/final/arbusto_%d.png" % (k % 3), xo, yo) for k, (xo, yo) in enumerate(
        [(-480, -640), (200, -600), (480, -900), (-200, -820), (620, -620), (-330, -560)])]
    deco += [("../objetos/final/tocha_chao.png", xo, yo) for xo, yo in [(-40, -420), (40, -420), (-300, -220), (100, -120), (-200, 140), (380, 200)]]
    deco += [("../objetos/final/%s.png" % n, xo, yo) for n, xo, yo in [("caixotes_2", 170, -20), ("barris_2", 60, -20),
             ("pedra_g", -320, 120), ("tijolo_m", -230, 110), ("poco", -220, -400), ("banco", 500, -280),
             ("sacos", 180, -20), ("placa_caveira", -150, 360), ("caixote", -600, 160)]]
    deco += [("../jazidas/final/rocha_mina_%d.png" % (k % 3), xo, yo) for k, (xo, yo) in enumerate([(-450, 380), (150, 380), (520, 350)])]
    for f, xo, yo in deco:
        if os.path.exists(f):
            solto(f, xo, yo)
    # gente
    for nome, d_, xo, yo in [("minerador", "south-east", -120, 340), ("mineradora", "south-west", 40, 250), ("lenhador", "south-east", -560, -720),
                             ("cacador", "south-west", -330, -680), ("engenheiro", "south-east", -200, 0), ("guarda", "south-east", 40, -400),
                             ("cozinheira", "south-west", 520, -200), ("medico", "south-east", 330, -260), ("civil", "south-west", -280, -230),
                             ("pesquisadora", "south-east", 260, -60)]:
        im = Image.open("../%s/rotacoes/%s.png" % (nome, d_)).convert("RGBA")
        b = im.getbbox(); im = im.crop(b)
        obj(im, xo, yo, (im.width / 2, im.height - 2))
    # moldura: mata fechada (mais densa longe da área jogável), alguns arbustos
    cache = {}

    def recorte(f):
        if f not in cache:
            im = Image.open(f).convert("RGBA"); cache[f] = im.crop(im.getbbox())
        return cache[f]
    rm = random.Random(21)
    pinh = sorted(glob.glob("../vegetacao/final/arvore_pinheiro_*.png"))
    folh = sorted(glob.glob("../vegetacao/final/arvore_carvalho_*.png") + glob.glob("../vegetacao/final/arvore_betula_*.png"))
    arb = sorted(glob.glob("../vegetacao/final/arbusto_*.png") + glob.glob("../vegetacao/final/capim_*.png"))
    for (i, j), nv in longe.items():
        d = nv * MARGEM
        p = (0.05 if mat[(i, j)] != "clareira" else 0.24) + 0.22 * min(1.0, d / 10)     # a mata fecha logo na borda
        for _ in range(2):
            if rm.random() < p / 2 * 2 and rm.random() < 0.5:
                f = rm.choice(pinh) if rm.random() < 0.7 else rm.choice(folh)
            elif rm.random() < 0.06:
                f = rm.choice(arb)
            else:
                continue
            im = recorte(f)
            u, v = i + rm.uniform(0.15, 0.85), j + rm.uniform(0.15, 0.85)
            x, y = P(u, v, alt[(i, j)])
            itens.append((u + v + 1, alt[(i, j)] + 0.5, 1, im, (int(x - im.width / 2), int(y - im.height + 3)), nv))
    # ------------------------------------------------------------ desenha
    xs = [t[4][0] for t in itens]; ys = [t[4][1] for t in itens]
    ox, oy = -min(xs) + 20, -min(ys) + 20
    W = max(xs) - min(xs) + 400; H = max(ys) - min(ys) + 400
    c = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    nevoa = Image.new("L", (W, H), 0)        # distância da área jogável (0) até a borda da moldura (255)
    for t in sorted(itens, key=lambda t: (t[0], t[1], t[2])):
        img, (x, y) = t[3], t[4]
        c.alpha_composite(img, (x + ox, y + oy))
        nevoa.paste(int(255 * (t[5] if len(t) > 5 else 0)), (x + ox, y + oy, x + ox + img.width, y + oy + img.height), img.split()[3])
    caixa = c.getbbox()
    c = c.crop(caixa); nevoa = nevoa.crop(caixa)
    c.save("mapa_transparente.png")       # pro cenário (cenario.py)
    nevoa.save("mapa_nevoa.png")          # o cenário puxa a moldura pra cor da serra com isto
    fundo = Image.new("RGBA", c.size, (22, 20, 19, 255)); fundo.alpha_composite(c); c = fundo
    c.save("mapa_montado.png")
    c.resize((c.width // 2, c.height // 2), Image.LANCZOS).save("mapa_montado_meio.png")
    c.resize((c.width // 4, c.height // 4), Image.LANCZOS).save("mapa_montado_quarto.png")
    print(c.size, len(itens))


if __name__ == "__main__":
    monta()
