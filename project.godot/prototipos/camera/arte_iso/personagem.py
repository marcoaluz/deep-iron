"""PROTÓTIPO: junta um personagem do PixelLab no padrão do contrato (4 direções de losango).

  python personagem.py <pasta> <character_id>

- baixa as 8 poses paradas (rotacoes/) e a caminhada SE/NE (caminhada/SE, caminhada/NE)
- SO e NO = espelho de SE e NE (contrato: 2 desenhos + espelho; parado TAMBÉM por espelho)
- âncora fixa por direção (pés), caixa mínima e pixels fora de 28x28x70 (a caixa do minerador)
- prancha_8_direcoes_iso.png, caminhada_4dir.gif e contrato.json
Precisa de curl (os links do Backblaze recusam o User-Agent do Python).
"""
import sys, os, json, subprocess, statistics, math
from PIL import Image, ImageOps, ImageDraw
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import verifica_arte as v

API = "https://api.pixellab.ai/mcp/characters/%s"
DIRS = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]


def curl(url, dest):
    subprocess.run(["curl", "-s", "-A", "curl/8", "-o", dest, url], check=True)


def info(cid):
    """Os links vêm do get_character; aqui eles são passados num JSON salvo pela sessão."""
    return json.load(open(os.path.join(PASTA, "links.json"), encoding="utf-8"))


def main():
    global PASTA
    PASTA = sys.argv[1]
    links = info(sys.argv[2])
    os.makedirs(os.path.join(PASTA, "rotacoes"), exist_ok=True)
    for d, url in links["rotacoes"].items():
        curl(url, os.path.join(PASTA, "rotacoes", d + ".png"))
    for d, urls in links["caminhada"].items():
        os.makedirs(os.path.join(PASTA, "caminhada", d), exist_ok=True)
        for i, u in enumerate(urls):
            curl(u, os.path.join(PASTA, "caminhada", d, "%d.png" % i))
    for s, t in (("SE", "SO"), ("NE", "NO")):
        os.makedirs(os.path.join(PASTA, "caminhada", t), exist_ok=True)
        for i in range(4):
            ImageOps.mirror(Image.open(os.path.join(PASTA, "caminhada", s, "%d.png" % i))).save(
                os.path.join(PASTA, "caminhada", t, "%d.png" % i))
    rel = {}
    for d in ("SE", "NE", "SO", "NO"):
        fr = [v.opaque(Image.open(os.path.join(PASTA, "caminhada", d, "%d.png" % i))) for i in range(4)]
        feet = [v.feet(p) for p in fr]
        anc = (statistics.median([a[0] for a in feet]), max(a[1] for a in feet))
        out = sum(v.outside_count(p, anc, (28, 28, 70), 1.0) for p in fr)
        cx = [sum(x for x, _ in p) / len(p) for p in fr]
        rel[d] = {"ancora": [round(anc[0], 1), anc[1]], "fora_28x28x70": out, "pixels": sum(len(p) for p in fr),
                  "corpo_varia_px": round(max(cx) - min(cx), 1)}
    # caixa do PERSONAGEM (quadrada, âncora fixa por direção): a menor que contém os 16 quadros
    import numpy as np
    pts = []
    for d in ("SE", "NE", "SO", "NO"):
        ax, ay = rel[d]["ancora"]
        for i in range(4):
            arr = np.array(Image.open(os.path.join(PASTA, "caminhada", d, "%d.png" % i)).convert("RGBA"))
            ys, xs = np.nonzero(arr[..., 3] > 40)
            pts.append((xs + 0.5 - ax, ys + 0.5 - ay))
    sx = np.concatenate([p[0] for p in pts]); sy = np.concatenate([p[1] for p in pts])

    def fora(L, H):
        umin = np.maximum(-L - sx, -L + sx); umax = np.minimum(L - sx, L + sx)
        lo = np.maximum(umin, 2 * sy); hi = np.minimum(umax, 2 * (sy + H))
        return int((lo > hi).sum())
    caixa = None
    for L in range(20, 60, 2):
        for H in range(50, 110, 2):
            if fora(L / 2, H) <= 4:
                if caixa is None or L * L * H < caixa[0] * caixa[0] * caixa[1]:
                    caixa = (L, H)
                break
    json.dump({"caixa": [caixa[0], caixa[0], caixa[1]], "pixels_fora": fora(caixa[0] / 2, caixa[1]), "direcoes": rel},
              open(os.path.join(PASTA, "contrato.json"), "w"), indent=1)
    print("caixa do personagem: %d x %d x %d" % (caixa[0], caixa[0], caixa[1]))
    # prancha das 8 poses com o losango 2:1 e a direção esperada
    S = 4
    W = 48 * S + 30
    g = Image.new("RGBA", (8 * W, 84 * S + 120), (90, 90, 100, 255))
    d = ImageDraw.Draw(g)
    ang = {"south": 90, "south-east": 26.57, "east": 0, "north-east": -26.57, "north": -90, "north-west": -153.43,
           "west": 180, "south-west": 153.43}
    for i, n in enumerate(DIRS):
        im = Image.open(os.path.join(PASTA, "rotacoes", n + ".png")).convert("RGBA")
        x, y = i * W + 15, 40
        fx, fy = x + 24 * S, y + 84 * S - 4
        L = 18 * S
        d.polygon([(fx - L, fy), (fx, fy - L / 2), (fx + L, fy), (fx, fy + L / 2)], outline=(255, 210, 90))
        d.line([(fx, fy), (fx + math.cos(math.radians(ang[n])) * L * 1.2, fy + math.sin(math.radians(ang[n])) * L * 1.2)],
               fill=(80, 255, 120), width=2)
        big = im.resize((im.width * S, im.height * S), Image.NEAREST)
        g.paste(big, (x, y), big)
        d.text((x, 8), n, fill=(255, 255, 0))
    g.save(os.path.join(PASTA, "prancha_8_direcoes_iso.png"))
    # caminhada nas 4 direções
    gif = []
    for i in range(4):
        c = Image.new("RGB", (4 * 336, 356), (80, 80, 92))
        dd = ImageDraw.Draw(c)
        for k, n in enumerate(("NO", "NE", "SO", "SE")):
            f = Image.open(os.path.join(PASTA, "caminhada", n, "%d.png" % i)).convert("RGBA").resize((336, 336), Image.NEAREST)
            c.paste(f, (k * 336, 20), f)
            dd.text((k * 336 + 6, 4), n, fill=(255, 230, 120))
        gif.append(c)
    gif[0].save(os.path.join(PASTA, "caminhada_4dir.gif"), save_all=True, append_images=gif[1:], duration=160, loop=0)
    print(json.dumps(rel, indent=1))


if __name__ == "__main__":
    main()
