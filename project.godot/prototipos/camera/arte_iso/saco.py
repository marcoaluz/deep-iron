"""PROTÓTIPO: carregar = caminhada + saco nas costas em sobreposição (Prompt 2).
O saco sai do quadro bom do "carregar" v3 do minerador; na caminhada de cada personagem
ele acompanha o balanço do passo (topo da cabeça) e fica ATRÁS do corpo de frente pra
câmera (SE/SO) e NA FRENTE de costas (NE/NO), como a picareta.

  python saco.py recorta        -> itens/saco_costas.png + itens/saco_costas.json
  python saco.py demo <saida.gif> <personagem> [<personagem> ...]
"""
import sys, os, json, statistics
from collections import Counter
from PIL import Image, ImageDraw, ImageOps
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import verifica_arte as v


def paleta(p):
    c = Counter()
    for f in os.listdir(p + "/rotacoes"):
        if f.endswith(".png"):
            c.update(q[:3] for q in Image.open(p + "/rotacoes/" + f).convert("RGBA").get_flattened_data() if q[3] > 40)
    return c


def recorta():
    im = Image.open("minerador/carregar/SE/5.png").convert("RGBA"); px = im.load()
    pal = paleta("minerador")
    tan = {(x, y) for y in range(im.height) for x in range(im.width) if px[x, y][3] > 40 and px[x, y][:3] not in pal}
    # só a maior mancha (o saco) e ela alargada 2 px dentro do desenho (pega o contorno)
    xs = sorted(x for x, _ in tan); ys = sorted(y for _, y in tan)
    cx, cy = xs[len(xs) // 2], ys[len(ys) // 2]
    tan = {(x, y) for x, y in tan if abs(x - cx) < 16 and abs(y - cy) < 16}
    mask = set(tan)
    for _ in range(2):
        mask |= {(x + dx, y + dy) for x, y in mask for dx in (-1, 0, 1) for dy in (-1, 0, 1)
                 if 0 <= x + dx < im.width and 0 <= y + dy < im.height and px[x + dx, y + dy][3] > 40}
    out = Image.new("RGBA", im.size, (0, 0, 0, 0)); op = out.load()
    for x, y in mask:
        op[x, y] = px[x, y]
    bb = out.getbbox(); out = out.crop(bb)
    out.save("itens/saco_costas.png")
    info = json.load(open("minerador/carregar/anim.json"))
    ax, ay = info["SE"]["ancora"]
    # posição do saco em relação ao pé e ao topo da cabeça do minerador naquele quadro
    topo = v.opaque(im); topo_y = min(p[1] for p in topo)
    json.dump({"offset_do_pe": [bb[0] - ax, bb[1] - ay], "altura_ref": ay - topo_y,
               "obs": "SE: atrás do corpo; SO: espelho; NE/NO: na frente (costas pra câmera)"},
              open("itens/saco_costas.json", "w"), indent=1)
    print("saco", out.size, bb)


def demo(saida, nomes):
    saco = Image.open("itens/saco_costas.png").convert("RGBA")
    meta = json.load(open("itens/saco_costas.json"))
    ox, oy = meta["offset_do_pe"]; href = meta["altura_ref"]
    S, CW, CH = 2, 64, 100
    quadros = []
    for i in range(4):
        c = Image.new("RGB", (len(nomes) * CW * S, 2 * CH * S), (62, 58, 54))
        for k, p in enumerate(nomes):
            for r, d in enumerate(("SE", "NE")):
                f = Image.open("%s/caminhada/%s/%d.png" % (p, d, i)).convert("RGBA")
                pes = [v.feet(v.opaque(Image.open("%s/caminhada/%s/%d.png" % (p, d, j)))) for j in range(4)]
                ax = statistics.median(a[0] for a in pes); ay = max(a[1] for a in pes)
                pts = v.opaque(f); topo_y = min(q[1] for q in pts)
                esc = (ay - topo_y) / href      # personagem mais alto/baixo: o saco sobe/desce junto
                s = saco if d == "SE" else ImageOps.mirror(saco)
                sx = int(ax + (ox if d == "SE" else -ox - s.width)); sy = int(ay + oy * esc)
                base = Image.new("RGBA", f.size, (0, 0, 0, 0))
                if d == "SE":
                    base.alpha_composite(s, (sx, sy)); base.alpha_composite(f)
                else:
                    base.alpha_composite(f); base.alpha_composite(s, (sx, sy))
                cr = base.crop((int(ax - CW / 2), int(ay - CH + 6), int(ax + CW / 2), int(ay + 6))).resize((CW * S, CH * S), Image.NEAREST)
                c.paste(cr, (k * CW * S, r * CH * S), cr)
        quadros.append(c)
    quadros[0].save(saida, save_all=True, append_images=quadros[1:], duration=160, loop=0)
    quadros[0].save(saida.replace(".gif", "_q0.png"))


if __name__ == "__main__":
    if sys.argv[1] == "recorta":
        recorta()
    else:
        demo(sys.argv[2], sys.argv[3:])
