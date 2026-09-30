"""PROTÓTIPO: terreno da mina (Prompt 7).

  python mina.py monta <lacrada> <abrindo>  -> final/mina/<zona>/chao_<k>.png, galeria_<estagio>.png, escora.png
  python mina.py brilho            -> brilho dos pisos novos contra os aprovados
  python mina.py cena <saida.png>  -> nível 1 (colônia na caverna) com galerias, trilhos, poço, zonas
  python mina.py fundo <saida.png> -> nível 2 e abismo com poço e trilho
  python mina.py prancha <saida.png> -> zonas ladrilhadas, escora, galeria nos 3 estágios, trilhos
Montagem igual à do relevo (tiles.py): coluna a coluna em (i + j), de baixo pra cima.
"""
import sys, os, glob
from PIL import Image
import tiles
from superficie import valor, escurece_hsv, recheia_borda

ZONAS = {  # zona: (candidatos, ajuste de brilho, refaz borda)
    "zona_gas":      ((2, 9, 13, 3, 7), 1.0, False),
    "zona_calor":    ((1, 2, 3, 7, 13), 1.0, False),
    "zona_radiacao": ((2, 6, 10, 12, 13), 1.0, False),
}
GALERIA = {"aberta": "galeria_aberta", "lacrada": "galeria_lacrada", "abrindo": "galeria_abrindo"}
ESC_GALERIA = 0.85     # a galeria veio mais clara que o bloco de rocha aprovado (0,295 x 0,25)
AJUSTE_GALERIA = {"lacrada": (0, -1)}   # a lacrada saiu 1 px abaixo da aberta (sobreposição 0,93 -> alinha)


def cand(pasta, i):
    return Image.open("mina/%s/candidatos/c%02d.png" % (pasta, i)).convert("RGBA")


def monta(escolha_galeria):
    for z, (idx, f, borda) in ZONAS.items():
        out = "final/mina/%s" % z
        os.makedirs(out, exist_ok=True)
        for k, i in enumerate(idx):
            t = tiles.topo_de(tiles.retifica(cand(z, i)))
            if borda:
                t = tiles.aplica(recheia_borda(t), tiles.mascara_topo())
            if f != 1.0:
                t = escurece_hsv(t, f)
            t.save("%s/chao_%d.png" % (out, k))
    for est, pasta in GALERIA.items():
        g = escurece_hsv(cand(pasta, escolha_galeria[est]), ESC_GALERIA)
        if est in AJUSTE_GALERIA:
            n = Image.new("RGBA", g.size, (0, 0, 0, 0)); n.alpha_composite(g, AJUSTE_GALERIA[est]); g = n
        g.save("final/mina/galeria_%s.png" % est)
    cand("escora", 1).save("final/mina/escora.png")
    print("ok")


def brilho():
    for amb in ("colonia", "rocha", "nivel2", "abismo"):
        vs = [valor(Image.open(f).convert("RGBA")) for f in sorted(glob.glob("final/%s/chao_*.png" % amb))]
        print("%-14s %.3f" % (amb, sum(vs) / len(vs)))
    for z in ZONAS:
        vs = [valor(Image.open(f).convert("RGBA")) for f in sorted(glob.glob("final/mina/%s/chao_*.png" % z))]
        print("%-14s %.3f" % (z, sum(vs) / len(vs)))


def ld(p):
    return [Image.open(f).convert("RGBA") for f in sorted(glob.glob(p + "/chao_*.png"))]


def blocos(amb):
    b = [Image.open(f).convert("RGBA") for f in sorted(glob.glob("final/%s/bloco.png" % amb) + glob.glob("final/%s/bloco_[0-9].png" % amb))]
    s = [Image.open(f).convert("RGBA") for f in sorted(glob.glob("final/%s/bloco_sem_beira*.png" % amb))]
    return b, s


def compoe(alt, mat, topo_fn, extras, trilhos=None, fundo=0.8):
    """alt: (i,j) -> degraus (negativo = buraco); mat: (i,j) -> ambiente dos blocos;
    extras: [(ordem, nivel, sub, img, (x, y))]; trilhos: (i,j) -> imagem sobre o topo."""
    B = {}
    itens = []
    base = min(min(alt.values()), 0)
    mi = max(i for i, _ in alt); mj = max(j for _, j in alt)
    for (i, j), h in alt.items():
        m = mat(i, j)
        if m not in B:
            B[m] = blocos(m)
        com, sem = B[m]
        tp = topo_fn(i, j)
        if trilhos and (i, j) in trilhos:
            tp = tp.copy(); tp.alpha_composite(trilhos[(i, j)])
        f = fundo ** max(0, -h)
        # a coluna só desce até o fundo mais baixo em volta (regra do buraco: o chão ao redor
        # do poço é coluna cheia desde o fundo; longe dele, não precisa desenhar nada embaixo)
        viz = [alt.get((i + a, j + b), h) for a in (-1, 0, 1) for b in (-1, 0, 1)]
        base_l = min(min(viz), h, 0)
        if i == mi or j == mj:     # borda da frente da cena: corte de maquete até o fundo
            base_l = base
        if h == base_l:
            itens.append((i + j, base_l, 0, tiles.escurece(tp, f), tiles.tela(i, j, base_l)))
        for k in range(base_l + 1, h + 1):
            b = tiles.escolhe(com if k == h else sem, i, j, k, False).copy()
            if k == h:
                b.paste(tp, (0, 0), tp)
            itens.append((i + j, k, 0, tiles.escurece(b, fundo ** max(0, -k)), tiles.tela(i, j, k)))
    itens += extras
    xs = [t[4][0] for t in itens]; ys = [t[4][1] for t in itens]
    ox, oy = -min(xs) + 10, -min(ys) + 10
    c = Image.new("RGBA", (max(xs) - min(xs) + 200, max(ys) - min(ys) + 200), (14, 13, 12, 255))
    for _, _, _, img, (x, y) in sorted(itens, key=lambda t: (t[0], t[1], t[2])):
        c.alpha_composite(img, (x + ox, y + oy))
    return c.crop(c.getbbox())


def pessoa(nome, d, i, j, k):
    im = Image.open("../%s/rotacoes/%s.png" % (nome, d)).convert("RGBA")
    bb = im.getbbox(); ax, ay = (bb[0] + bb[2]) // 2, bb[3] - 2
    x, y = tiles.tela(i, j, k)
    return (i + j + 0.5, k, 1, im, (x + 32 - ax, y + 16 - ay))


def parede(img, i, j, h):
    """galeria/boca de mina: caixa 2x1 tiles (i..i+1, j), h degraus; canto N do topo em (34, 2) do quadro."""
    x, y = tiles.tela(i, j, h)
    return (i + j + 1, h + 0.5, 0, img, (x - 2, y - 2))


def cena(saida):
    T = {"colonia": ld("final/colonia"), "rocha": ld("final/rocha")}
    for z in ZONAS:
        T[z] = ld("final/mina/%s" % z)
    R = {os.path.basename(f)[:-4]: Image.open(f).convert("RGBA") for f in glob.glob("final/mina/trilhos/*.png")}
    gal = {e: Image.open("final/mina/galeria_%s.png" % e).convert("RGBA") for e in GALERIA}
    esc = Image.open("final/mina/escora.png").convert("RGBA")
    NI, NJ, PAR = 18, 16, 3
    alt, parede_t = {}, set()
    for i in range(NI):
        for j in range(NJ):
            fundo_ = i == 0 or j <= 1
            frente = i == NI - 1 or j == NJ - 1
            alt[(i, j)] = PAR if fundo_ else (1 if frente else 0)
            if fundo_ or frente:
                parede_t.add((i, j))
    # as galerias ficam na face esquerda da parede do fundo (linha j = 1)
    gal_pos = {"lacrada": 3, "abrindo": 8, "aberta": 13}
    gal_t = {(i + d, 1) for i in gal_pos.values() for d in (0, 1)}
    for i in (13, 14):                        # poço do elevador: 2x2, 4 degraus
        for j in (10, 11):
            alt[(i, j)] = -4
    def tipo_v(vi, vj):
        if (vi - 4) ** 2 + (vj - 10) ** 2 < 8: return "zona_gas"
        if (vi - 8.5) ** 2 + (vj - 12.5) ** 2 < 5: return "zona_calor"
        if (vi - 16) ** 2 + (vj - 6) ** 2 < 4: return "zona_radiacao"
        return "colonia"
    ordem = ["colonia", "zona_gas", "zona_calor", "zona_radiacao"]
    def topo_fn(i, j):
        if (i, j) in parede_t:
            return tiles.escolhe(T["rocha"], i, j, 99)
        cant = (tipo_v(i, j), tipo_v(i + 1, j), tipo_v(i + 1, j + 1), tipo_v(i, j + 1))
        tex = {t: tiles.escolhe(T[t], i, j, 90 + k) for k, t in enumerate(ordem)}
        return tiles.topo_misto(i, j, cant, tex, ordem)
    mat = lambda i, j: "rocha" if (i, j) in parede_t else "colonia"
    # trilho: sai da galeria aberta e desce até perto do poço; um ramal cruza pro oeste
    tr = {(14, j): R["reto_j"] for j in range(2, 9)}
    tr[(14, 9)] = R["fim_SO"]
    tr[(14, 5)] = R["cruz"]
    for i in range(9, 14):
        tr[(i, 5)] = R["reto_i"]
    tr[(8, 5)] = R["fim_NO"]
    alt2 = {c: h for c, h in alt.items() if c not in gal_t}
    ex = [parede(gal[e], i, 1, PAR) for e, i in gal_pos.items()]
    for e, i in gal_pos.items():             # topo da galeria = topo da rocha
        for d in (0, 1):
            ex.append((i + 2, PAR + 0.6, 0, topo_fn(i + d, 1), tiles.tela(i + d, 1, PAR)))  # depois da galeria
    eb = esc.getbbox()
    for j in (3, 7):                          # escoras ao longo do trilho
        x, y = tiles.tela(14, j, 0)
        ex.append((14 + j + 0.4, 0, 1, esc, (x + 32 - (eb[0] + eb[2]) // 2, y + 16 - eb[3] + 2)))
    ex += [pessoa("minerador", "south-west", 14, 4, 0), pessoa("mineradora", "south-east", 9, 3, 0),
           pessoa("traje_gas_m", "south-east", 4, 10, 0), pessoa("traje_calor_f", "south-west", 8, 12, 0),
           pessoa("traje_radiacao_m", "south-west", 15, 6, 0), pessoa("engenheiro", "south-east", 5, 3, 0),
           pessoa("guarda", "south-east", 11, 13, 0)]
    c = compoe(alt2, mat, topo_fn, ex, tr)
    c.save(saida); c.resize((c.width * 2, c.height * 2), Image.NEAREST).save(saida.replace(".png", "_x2.png"))
    print(c.size)


def fundo(saida):
    R = {os.path.basename(f)[:-4]: Image.open(f).convert("RGBA") for f in glob.glob("final/mina/trilhos/*.png")}
    partes = []
    for amb, zona, gente in (("nivel2", None, ("minerador", "south-east", 3, 3)),
                             ("abismo", "zona_calor", ("traje_calor_m", "south-east", 3, 5))):
        T = {amb: ld("final/%s" % amb)}
        if zona:
            T[zona] = ld("final/mina/%s" % zona)
        NI, NJ = 10, 9
        alt = {(i, j): (2 if i == 0 or j == 0 else 0) for i in range(NI) for j in range(NJ)}
        for i in (6, 7):
            for j in (5, 6):
                alt[(i, j)] = -4
        ordem = [amb] + ([zona] if zona else [])
        def tipo_v(vi, vj, zona=zona, amb=amb):
            return zona if zona and (vi - 3) ** 2 + (vj - 6) ** 2 < 5 else amb
        def topo_fn(i, j, T=T, ordem=ordem, tipo_v=tipo_v):
            cant = (tipo_v(i, j), tipo_v(i + 1, j), tipo_v(i + 1, j + 1), tipo_v(i, j + 1))
            tex = {t: tiles.escolhe(T[t], i, j, 90 + k) for k, t in enumerate(ordem)}
            return tiles.topo_misto(i, j, cant, tex, ordem)
        tr = {(i, 3): R["reto_i"] for i in range(1, 6)}
        tr[(6, 3)] = R["fim_SE"]
        partes.append(compoe(alt, lambda i, j, a=amb: a, topo_fn, [pessoa(*gente, 0)], tr))
    W = sum(p.width for p in partes) + 30; H = max(p.height for p in partes)
    c = Image.new("RGBA", (W, H), (14, 13, 12, 255)); x = 0
    for p in partes:
        c.alpha_composite(p, (x, H - p.height)); x += p.width + 30
    c.save(saida); c.resize((c.width * 2, c.height * 2), Image.NEAREST).save(saida.replace(".png", "_x2.png"))
    print(c.size)


def prancha(saida):
    from PIL import ImageDraw
    from superficie import remendo
    c = Image.new("RGB", (1360, 700), (40, 38, 36)); d = ImageDraw.Draw(c)
    for k, z in enumerate(ZONAS):
        topos = ld("final/mina/%s" % z)
        r = remendo(topos); x = 10 + k * 340
        c.paste(r, (x, 26), r); d.text((x, 8), "%s (%d var.)" % (z, len(topos)), fill=(255, 230, 150))
    d.text((1030, 8), "escora", fill=(255, 230, 150))
    e = Image.open("final/mina/escora.png").convert("RGBA"); e = e.resize((e.width * 2, e.height * 2), Image.NEAREST)
    c.paste(e, (1030, 26), e)
    d.text((10, 240), "galeria na parede de rocha: lacrada -> abrindo -> aberta (mesmo quadro e ancora)", fill=(255, 230, 150))
    for k, est in enumerate(("lacrada", "abrindo", "aberta")):
        g = Image.open("final/mina/galeria_%s.png" % est).convert("RGBA"); g = g.resize((g.width * 2, g.height * 2), Image.NEAREST)
        c.paste(g, (10 + k * 220, 258), g)
    d.text((690, 240), "trilhos (encaixam tile com tile; juncao = reto + curva)", fill=(255, 230, 150))
    ns = ["reto_i", "reto_j", "curva_N", "curva_E", "curva_S", "curva_O", "cruz", "fim_NO", "fim_SE", "fim_NE", "fim_SO"]
    for k, n in enumerate(ns):
        t = Image.open("final/mina/trilhos/%s.png" % n).convert("RGBA").resize((128, 64), Image.NEAREST)
        x, y = 690 + (k % 4) * 166, 262 + (k // 4) * 96
        c.paste(t, (x, y + 14), t); d.text((x, y), n, fill=(200, 200, 200))
    c.save(saida)


if __name__ == "__main__":
    a = sys.argv[1]
    if a == "monta":
        monta({"aberta": 0, "lacrada": int(sys.argv[2]), "abrindo": int(sys.argv[3])})
    elif a == "brilho":
        brilho()
    elif a == "cena":
        cena(sys.argv[2])
    elif a == "fundo":
        fundo(sys.argv[2])
    elif a == "prancha":
        prancha(sys.argv[2])
