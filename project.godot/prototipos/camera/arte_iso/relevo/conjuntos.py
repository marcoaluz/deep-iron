"""PROTÓTIPO: monta os conjuntos de relevo de cada ambiente (a partir dos candidatos
escolhidos) e as cenas de teste.  python conjuntos.py"""
import os
from PIL import Image
import tiles

# ambiente: (pasta, bloco das faces, topos de chão, pula_beira dos blocos de baixo)
ESCOLHA = {
    "colonia":  ("bloco",    (15, 13),            (15, 11, 1, 0),   0.30),
    "clareira": ("clareira", (0,),             (0, 9),           0.30),
    "nivel2":   ("nivel2",   (1,),             (15, 2, 6, 1),    0.25),
    "abismo":   ("abismo",   (7,),             (6, 14, 7, 0),    0.15),
    "rocha":    ("rocha",    (9, 13, 10, 8),   (9, 13, 10),      0.0),
}


def conjunto(nome):
    pasta, b, tops, pula = ESCOLHA[nome]
    c = lambda i: Image.open("%s/candidatos/c%02d.png" % (pasta, i)).convert("RGBA")
    out = "final/%s" % nome
    os.makedirs(out, exist_ok=True)
    topos = [tiles.topo_de(tiles.retifica(c(i))) for i in tops]
    blocos = [tiles.retifica(c(i)) for i in b]
    sems = [tiles.retifica(c(i), pula) for i in b]
    for k, i in enumerate(dict.fromkeys(tops)):
        topos[tops.index(i)].save("%s/chao_%d.png" % (out, k))
    for k, (bl, se) in enumerate(zip(blocos, sems)):
        bl.save(out + ("/bloco.png" if k == 0 else "/bloco_%d.png" % k))
        se.save(out + ("/bloco_sem_beira.png" if k == 0 else "/bloco_sem_beira_%d.png" % k))
    return topos, blocos, sems


if __name__ == "__main__":
    S = {n: conjunto(n) for n in ESCOLHA}
    esc = Image.open("final/escada_N.png").convert("RGBA")
    p = Image.open("../minerador/rotacoes/south-east.png").convert("RGBA")
    bb = p.getbbox(); ax, ay = (bb[0] + bb[2]) // 2, bb[3] - 2
    q = Image.open("../mineradora/rotacoes/south-west.png").convert("RGBA")

    # 1) nível 2 e abismo: platô + galeria + escada, cada um no seu material
    for n in ("nivel2", "abismo", "clareira"):
        topos, com, sem = S[n]
        alt = {(i, j): 0 for i in range(12) for j in range(10)}
        for i in range(1, 5):
            for j in range(1, 4): alt[(i, j)] = 1
        alt[(2, 4)] = ("escada", 0, "N")
        for i in range(6, 10):
            for j in range(4, 8): alt[(i, j)] = -1
        alt[(7, 4)] = ("escada", -1, "N")
        c = tiles.cena((com, sem), topos, alt, [(p, 3, 2, 1, ax, ay), (q, 8, 6, -1, ax, ay), (p, 4, 7, 0, ax, ay)],
                       escada=esc, fundo=0.8)
        c.save("final/cena_%s.png" % n)

    # 2) colônia na caverna: parede de rocha alta no fundo (N e O), baixa na frente (corte),
    #    transição terra -> grama da clareira num canto, platô e galeria
    col_t, col_b, col_s = S["colonia"]
    roc_t, roc_b, roc_s = S["rocha"]
    cla_t = S["clareira"][0]
    NI, NJ = 16, 14
    alt, tipo = {}, {}
    for i in range(NI):
        for j in range(NJ):
            borda_fundo = i == 0 or j == 0
            borda_frente = i == NI - 1 or j == NJ - 1
            alt[(i, j)] = 3 if borda_fundo else (1 if borda_frente else 0)
    for i in range(3, 7):
        for j in range(3, 6): alt[(i, j)] = 1
    alt[(4, 6)] = ("escada", 0, "N")
    for i in range(9, 13):
        for j in range(8, 11): alt[(i, j)] = -1
    alt[(10, 8)] = ("escada", -1, "N")
    parede = {c for c, h in alt.items() if not isinstance(h, tuple) and (c[0] in (0, NI - 1) or c[1] in (0, NJ - 1))}
    # tipo de chão nos vértices: clareira no canto de cima-direita (i grande, j pequeno)
    def tipo_v(vi, vj):
        return "clareira" if (vi - 11) ** 2 + (vj - 2) ** 2 < 16 else "colonia"
    def topo_fn(i, j):
        if (i, j) in parede:
            return tiles.escolhe(roc_t, i, j, 99)
        cant = (tipo_v(i, j), tipo_v(i + 1, j), tipo_v(i + 1, j + 1), tipo_v(i, j + 1))
        tex = {"colonia": tiles.escolhe(col_t, i, j, 99), "clareira": tiles.escolhe(cla_t, i, j, 98)}
        return tiles.topo_misto(i, j, cant, tex, ["colonia", "clareira"])
    # a parede usa os blocos de rocha: monta as colunas de parede à parte e o resto normal
    alt_chao = {c: h for c, h in alt.items() if c not in parede}
    alt_par = {c: h for c, h in alt.items() if c in parede}
    img_chao = tiles.cena((col_b, col_s), col_t, {**alt_chao, **{c: 0 for c in alt_par}},
                          [(p, 5, 4, 1, ax, ay), (q, 10, 9, -1, ax, ay), (p, 8, 6, 0, ax, ay), (q, 12, 3, 0, ax, ay)],
                          escada=esc, fundo=0.8, topo_fn=topo_fn)
    img_chao.save("final/_colonia_sem_parede.png")
    # versão com parede: cena única com um bloco por coluna escolhido pelo tipo
    def cena_mista():
        base = -1
        itens = []
        for (i, j), h in alt.items():
            is_par = (i, j) in parede
            blocos, baixos = (roc_b, roc_s) if is_par else (col_b, col_s)
            if isinstance(h, tuple):
                _, k0, lado = h
                for k in range(base + 1, k0 + 1):
                    itens.append((i + j, k, 0, tiles.escolhe(baixos, i, j, k, False), tiles.tela(i, j, k)))
                itens.append((i + j, k0 + 1, 0, esc, tiles.tela(i, j, k0 + 1)))
                continue
            tp = topo_fn(i, j)
            f = 0.8 ** max(0, -h)
            if h == base:
                itens.append((i + j, base, 0, tiles.escurece(tp, f), tiles.tela(i, j, base)))
            for k in range(base + 1, h + 1):
                b = tiles.escolhe(blocos if k == h else baixos, i, j, k, False).copy()
                if k == h:
                    b.paste(tp, (0, 0), tp)
                itens.append((i + j, k, 0, tiles.escurece(b, 0.8 ** max(0, -k)), tiles.tela(i, j, k)))
        for img, i, j, k in [(p, 5, 4, 1), (q, 10, 9, -1), (p, 8, 6, 0), (q, 12, 3, 0), (p, 3, 9, 0)]:
            x, y = tiles.tela(i, j, k)
            itens.append((i + j + 0.5, k, 1, img, (x + 32 - ax, y + 16 - ay)))
        xs = [t[4][0] for t in itens]; ys = [t[4][1] for t in itens]
        ox, oy = -min(xs) + 10, -min(ys) + 10
        c = Image.new("RGBA", (max(xs) - min(xs) + 84, max(ys) - min(ys) + 84), (20, 19, 18, 255))
        for _, _, _, img, (x, y) in sorted(itens, key=lambda t: (t[0], t[1], t[2])):
            c.alpha_composite(img, (x + ox, y + oy))
        return c
    m = cena_mista()
    m.save("final/cena_colonia_caverna.png")
    m.resize((m.width * 2, m.height * 2), Image.NEAREST).save("final/cena_colonia_caverna_x2.png")
    print("ok", m.size)
