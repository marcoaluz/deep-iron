"""PROTÓTIPO: ferramentas e armas (Prompt 4) a partir das folhas 2x2 geradas.

  python itens.py corta <folha.png> <nome_q1> <nome_q2> <nome_q3> <nome_q4>
      -> itens/<nome>.png (item na diagonal, como veio) e as variantes:
         itens/<nome>_chao.png    largado no chão: achatado 1/2 na vertical = a diagonal de 45°
                                  vira o eixo 2:1 do chão (26,57°), + sombra leve
         itens/icones/<nome>.png  ícone de UI (quadrado, tamanho nativo; a UI escolhe a escala)
         itens/<nome>_gasta.png   desgaste: mais escuro, dessaturado, pontos de ferrugem
         itens/<nome>_quebrada.png partido ao meio (só armas e ferramentas de cabo)
  python itens.py demo <saida.gif>   -> ferramentas nas costas/na mão dos personagens (regra da
                                        picareta: de frente pra câmera ATRÁS do corpo, de costas NA FRENTE)
"""
import sys, os, json, random, statistics
from PIL import Image, ImageOps, ImageDraw
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import verifica_arte as v

os.makedirs("itens/icones", exist_ok=True)


def trim(im):
    b = im.getbbox()
    return im.crop(b) if b else im


def quadrantes(folha):
    im = Image.open(folha).convert("RGBA")
    h = im.width // 2
    return [trim(im.crop((x, y, x + h, y + h))) for y in (0, h) for x in (0, h)]


def chao(it):
    """achata 1/2 na vertical (vizinho mais próximo: uma linha sim, outra não) + sombra."""
    w, h = it.size
    ach = it.resize((w, max(1, h // 2)), Image.NEAREST)
    out = Image.new("RGBA", (w + 2, ach.height + 3), (0, 0, 0, 0))
    sombra = Image.new("RGBA", ach.size, (0, 0, 0, 0))
    a = ach.split()[3].point(lambda p: 70 if p > 40 else 0)
    sombra.putalpha(a)
    out.alpha_composite(sombra, (2, 2))
    out.alpha_composite(ach, (0, 0))
    return out


def gasta(it, seed=1):
    rnd = random.Random(seed)
    out = it.copy(); px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a < 40:
                continue
            m = (r + g + b) / 3
            r, g, b = [int(0.78 * (0.6 * c + 0.4 * m)) for c in (r, g, b)]   # escurece e dessatura
            if rnd.random() < 0.10:                                           # ponto de ferrugem
                r, g, b = int(r * 0.7 + 60), int(g * 0.6 + 18), int(b * 0.5 + 6)
            px[x, y] = (r, g, b, a)
    return out


def quebrada(it):
    """parte no meio, perpendicular à diagonal (cabo de baixo-esquerda pra cima-direita), e afasta 2 px."""
    w, h = it.size
    a = Image.new("RGBA", it.size, (0, 0, 0, 0)); b = Image.new("RGBA", it.size, (0, 0, 0, 0))
    pa, pb, pi = a.load(), b.load(), it.load()
    for y in range(h):
        for x in range(w):
            if pi[x, y][3] < 40:
                continue
            # coordenada ao longo da diagonal: x + (h - y)
            (pa if x + (h - 1 - y) < (w + h) / 2 - 1 else pb)[x, y] = pi[x, y]
    out = Image.new("RGBA", (w + 4, h + 4), (0, 0, 0, 0))
    out.alpha_composite(a, (0, 3))
    out.alpha_composite(b, (3, 0))
    return trim(out)


def corta(folha, nomes):
    for nome, it in zip(nomes, quadrantes(folha)):
        if nome == "-":
            continue
        it.save("itens/%s.png" % nome)
        chao(it).save("itens/%s_chao.png" % nome)
        s = max(it.size)
        ic = Image.new("RGBA", (s, s), (0, 0, 0, 0)); ic.alpha_composite(it, ((s - it.width) // 2, (s - it.height) // 2))
        ic.save("itens/icones/%s.png" % nome)
        gasta(it).save("itens/%s_gasta.png" % nome)
        quebrada(it).save("itens/%s_quebrada.png" % nome)
        print(nome, it.size)


# ------------------------------------------------------------------ nas costas / na mão
# dx, dy: em relação ao topo da cabeça e ao centro do corpo; rot: graus (o item vem a 45°);
# mirror: espelha no SE; front: desenha na frente do corpo (de costas pra câmera)
CONFIG = {
    "costas_cabo_longo": {"SE": {"dx": -1, "dy": 2, "rot": -28, "mirror": True, "front": False},
                          "NE": {"dx": -2, "dy": 8, "rot": 20, "mirror": False, "front": True}},
    "cinto": {"SE": {"dx": 6, "dy": 34, "rot": -30, "mirror": False, "front": True},
              "NE": {"dx": -8, "dy": 34, "rot": -30, "mirror": True, "front": False}},
}
DEMO = [("lenhador", "machado", "costas_cabo_longo"), ("guarda", "lanca", "costas_cabo_longo"),
        ("guarda_mulher", "besta", "costas_cabo_longo"), ("cacador", "arco", "costas_cabo_longo"),
        ("minerador", "picareta_aco", "costas_cabo_longo"), ("engenheiro", "martelo", "cinto"),
        ("mineradora", "broca", "costas_cabo_longo"), ("guarda", "lanca_prata", "costas_cabo_longo")]


def compoe(body, item, cfg):
    bb = body.getbbox(); top = bb[1]; cx = (bb[0] + bb[2]) / 2
    it = ImageOps.mirror(item) if cfg["mirror"] else item
    if cfg["rot"]:
        it = it.rotate(cfg["rot"], resample=Image.NEAREST, expand=True)
    x = int(round(cx + cfg["dx"] - it.width / 2)); y = int(round(top + cfg["dy"]))
    out = Image.new("RGBA", body.size, (0, 0, 0, 0))
    if cfg["front"]:
        out.alpha_composite(body); out.alpha_composite(it, (x, y))
    else:
        out.alpha_composite(it, (x, y)); out.alpha_composite(body)
    return out


def demo(saida):
    S, CW, CH = 2, 90, 104
    fr = []
    for i in range(4):
        c = Image.new("RGB", (len(DEMO) * CW * S, 2 * CH * S + 14), (62, 58, 54)); d = ImageDraw.Draw(c)
        for k, (p, nome, tipo) in enumerate(DEMO):
            item = Image.open("itens/%s.png" % nome).convert("RGBA")
            for r, dr in enumerate(("SE", "NE")):
                f = Image.open("%s/caminhada/%s/%d.png" % (p, dr, i)).convert("RGBA")
                pes = [v.feet(v.opaque(Image.open("%s/caminhada/%s/%d.png" % (p, dr, j)))) for j in range(4)]
                ax = statistics.median(q[0] for q in pes); ay = max(q[1] for q in pes)
                o = compoe(f, item, CONFIG[tipo][dr])
                cr = o.crop((int(ax - CW / 2), int(ay - CH + 6), int(ax + CW / 2), int(ay + 6))).resize((CW * S, CH * S), Image.NEAREST)
                c.paste(cr, (k * CW * S, 14 + r * CH * S), cr)
            d.text((k * CW * S + 4, 2), "%s+%s" % (p[:8], nome), fill=(255, 230, 150))
        fr.append(c)
    fr[0].save(saida, save_all=True, append_images=fr[1:], duration=160, loop=0)
    fr[0].save(saida.replace(".gif", "_q0.png"))


def item(arquivo, nome, lado, corta_cabo=0.0):
    """um item por candidato (o modelo entregou assim): reduz pro tamanho do jogo e faz as variantes.
    corta_cabo: fração da diagonal a remover na ponta do cabo (o porrete veio com uma mão)."""
    import reduz
    im = Image.open(arquivo).convert("RGBA")
    if corta_cabo:
        im = trim(im); px = im.load(); w, h = im.size
        for y in range(h):
            for x in range(w):
                if x + (h - 1 - y) < corta_cabo * (w + h):
                    px[x, y] = (0, 0, 0, 0)
    it = trim(reduz.reduz(im, lado))
    it.save("itens/%s.png" % nome)
    chao(it).save("itens/%s_chao.png" % nome)
    s = max(it.size)
    ic = Image.new("RGBA", (s, s), (0, 0, 0, 0)); ic.alpha_composite(it, ((s - it.width) // 2, (s - it.height) // 2))
    ic.save("itens/icones/%s.png" % nome)
    gasta(it).save("itens/%s_gasta.png" % nome)
    quebrada(it).save("itens/%s_quebrada.png" % nome)
    print(nome, it.size)


if __name__ == "__main__":
    if sys.argv[1] == "corta":
        corta(sys.argv[2], sys.argv[3:7])
    elif sys.argv[1] == "item":
        item(sys.argv[2], sys.argv[3], int(sys.argv[4]), float(sys.argv[5]) if len(sys.argv) > 5 else 0.0)
    else:
        demo(sys.argv[2])
