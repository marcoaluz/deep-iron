"""PROTÓTIPO: cenário de fundo do mapa (céu + montanhas) por hora do dia e chuva.

  python cenario.py   -> cenario_<hora>.png (manha, meio_dia, tarde, noite, chuva) + cenario_ciclo.gif

Camadas (de trás pra frente), como o jogo vai fazer com parallax:
  1. céu: degradê por hora (código), sol/lua, estrelas à noite;
  2. nuvens (IA, tingidas por hora);
  3. montanhas ao longe (IA, puxadas pra cor do horizonte = névoa);
  4. serra com floresta (IA, escurecida pela luz do ambiente), atrás da borda de trás do mapa;
  5. o mapa (monta.py, fundo transparente) com a luz do ambiente;
  6. névoa no pé do corte do terreno; chuva (código) por cima de tudo.
"""
import random, math
from PIL import Image, ImageDraw, ImageChops

HORAS = {   # céu topo, céu horizonte, luz do ambiente (multiplica), astro
    "manha":    ((96, 128, 170), (236, 190, 150), (1.00, 0.92, 0.84), ("sol", 0.18, 0.62)),
    "meio_dia": ((70, 122, 190), (176, 206, 226), (1.04, 1.04, 1.02), ("sol", 0.50, 0.12)),
    "tarde":    ((64, 56, 104), (244, 136, 72), (1.04, 0.80, 0.62), ("sol", 0.82, 0.60)),
    "noite":    ((6, 8, 20), (30, 36, 64), (0.34, 0.40, 0.62), ("lua", 0.70, 0.18)),
    "chuva":    ((64, 68, 78), (112, 118, 124), (0.70, 0.74, 0.80), (None, 0, 0)),
}


def L(f):
    return Image.open(f).convert("RGBA")


def tinge(im, cor, forca):
    """puxa a camada pra uma cor (névoa/atmosfera)."""
    r, g, b, a = im.split()
    base = Image.merge("RGB", (r, g, b))
    alvo = Image.new("RGB", im.size, cor)
    mix = Image.blend(base, alvo, forca)
    return Image.merge("RGBA", (*mix.split(), a))


def luz(im, mult):
    r, g, b, a = im.split()
    r = r.point(lambda v: min(255, int(v * mult[0])))
    g = g.point(lambda v: min(255, int(v * mult[1])))
    b = b.point(lambda v: min(255, int(v * mult[2])))
    return Image.merge("RGBA", (r, g, b, a))


def faixa(camada, W, esc, desloc=0):
    """repete a camada na horizontal (ela emenda) no tamanho da tela, ampliada por pixel inteiro."""
    c = camada.resize((camada.width * esc, camada.height * esc), Image.NEAREST)
    m = c.transpose(Image.FLIP_LEFT_RIGHT)      # normal, espelhada, normal...: a emenda sempre casa
    out = Image.new("RGBA", (W, c.height))
    x = -desloc; k = 0
    while x < W:
        out.alpha_composite(c if k % 2 == 0 else m, (x, 0)); x += c.width; k += 1
    return out


def recorta_nuvens(nuvens):
    """separa cada nuvem da camada (componente conexo do alfa); fica só com as grandes."""
    w, h = nuvens.size
    a = nuvens.split()[3].load()
    visto = set(); pecas = []
    for y0 in range(h):
        for x0 in range(w):
            if a[x0, y0] < 20 or (x0, y0) in visto:
                continue
            pilha = [(x0, y0)]; visto.add((x0, y0)); pts = []
            while pilha:
                x, y = pilha.pop(); pts.append((x, y))
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visto and a[nx, ny] >= 20:
                        visto.add((nx, ny)); pilha.append((nx, ny))
            if len(pts) < 300:
                continue
            xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
            if min(xs) == 0 or max(xs) == w - 1:      # cortada na borda
                continue
            pecas.append(nuvens.crop((min(xs), min(ys), max(xs) + 1, max(ys) + 1)))
    return pecas


def cor_media(im, y0=0.5):
    """cor média da parte de baixo (opaca) de uma camada."""
    px = [p for p in im.crop((0, int(im.height * y0), im.width, im.height)).get_flattened_data() if p[3] > 200]
    return tuple(sum(p[k] for p in px) // len(px) for k in range(3))


def nevoa_distancia(mapa, mascara, cor, forca):
    """puxa a moldura (o que é longe da área jogável) pra cor da serra: perspectiva atmosférica."""
    r, g, b, a = mapa.split()
    alvo = Image.new("RGB", mapa.size, cor)
    m = mascara.point(lambda v: int(min(255, (v / 255) ** 1.6 * 255 * forca)))
    mix = Image.composite(alvo, Image.merge("RGB", (r, g, b)), m)
    return Image.merge("RGBA", (*mix.split(), a))


def cena(hora, mapa, longe, serra, nuvens, mascara):
    topo, horiz, amb, astro = HORAS[hora]
    W = mapa.width + 400
    H = mapa.height + 1100
    c = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(c)
    horizonte = 1100
    for y in range(H):
        t = min(1.0, y / horizonte)
        cor = tuple(int(topo[k] + (horiz[k] - topo[k]) * t) for k in range(3))
        d.line([(0, y), (W, y)], fill=cor + (255,))
    rnd = random.Random(3)
    if hora == "noite":
        for _ in range(500):
            x, y = rnd.randrange(W), rnd.randrange(horizonte)
            v = rnd.randint(140, 255); d.point((x, y), fill=(v, v, min(255, v + 20), 255))
    if astro[0]:
        ax, ay = int(W * astro[1]), int(horizonte * astro[2])
        if astro[0] == "sol":
            raio = 60 if hora == "meio_dia" else 80
            cor = (255, 236, 170) if hora != "tarde" else (255, 170, 90)
            for k in range(6, 0, -1):     # halo em degraus (pixel art)
                rr = raio + k * 22
                halo = Image.new("RGBA", (rr * 2, rr * 2)); hd = ImageDraw.Draw(halo)
                hd.ellipse([0, 0, rr * 2, rr * 2], fill=cor + (12,))
                c.alpha_composite(halo, (ax - rr, ay - rr))
            d.ellipse([ax - raio, ay - raio, ax + raio, ay + raio], fill=cor + (255,))
        else:
            d.ellipse([ax - 46, ay - 46, ax + 46, ay + 46], fill=(226, 226, 210, 255))
            d.ellipse([ax - 20, ay - 50, ax + 66, ay + 36], fill=topo + (255,))
    # nuvens
    nv = nuvens
    if hora == "chuva":
        nv = luz(nuvens, (0.55, 0.58, 0.62))
    elif hora == "noite":
        nv = luz(nuvens, (0.25, 0.28, 0.40))
    elif hora == "tarde":
        nv = tinge(nuvens, (250, 150, 110), 0.35)
    elif hora == "manha":
        nv = tinge(nuvens, (250, 210, 190), 0.25)
    pecas = recorta_nuvens(nv)
    rn = random.Random(11)
    qtd = 22 if hora == "chuva" else 7               # céu limpo: poucas nuvens soltas
    for k in range(qtd):
        p = pecas[k % len(pecas)]
        esc = rn.choice((2, 3, 3, 4)) if hora != "chuva" else rn.choice((4, 5))
        if rn.random() < 0.5:
            p = p.transpose(Image.FLIP_LEFT_RIGHT)
        p = p.resize((p.width * esc, p.height * esc), Image.NEAREST)
        x = int((k + rn.random() * 0.6) * W / qtd) - p.width // 2
        y = rn.randint(40, 560) if hora != "chuva" else rn.randint(-60, 700)
        c.alpha_composite(p, (x, y))
    # montanhas ao longe (névoa = cor do horizonte) e serra com floresta
    mx, my = 200, horizonte - 150
    fl = faixa(tinge(longe, horiz, 0.45 if hora != "noite" else 0.65), W, 4, 700)
    c.alpha_composite(fl, (0, my + 560 - fl.height + 40))            # topo da moldura do mapa ~ no pé das montanhas ao longe
    serra_c = luz(tinge(serra, (40, 46, 38), 0.35), amb)      # serra mais suja, como o resto do jogo
    fs = faixa(serra_c, W, 5, 300)
    y_serra = my + 560 - fs.height // 2       # a serra fica atrás do topo da moldura; o pé dela, atrás dos lados
    c.alpha_composite(fs, (0, y_serra))
    # vale embaixo da serra (os lados do mapa): da cor do pé da serra até a névoa de baixo
    cor_serra = cor_media(serra_c, 0.45)
    cor_n = tuple(int(cor_serra[k] * 0.9 + horiz[k] * 0.1 * amb[k]) for k in range(3))
    cor_baixo = tuple(int(v * 0.6) for v in horiz)
    vale = Image.new("RGBA", (W, H)); vd = ImageDraw.Draw(vale)
    y1 = y_serra + fs.height - 4
    for y in range(y1 - 260, H):          # começa por cima do pé da serra, em degradê: sem linha reta
        t = min(1.0, max(0.0, (y - y1) / max(1, (H - y1) * 0.8)))
        a = min(255, max(0, int((y - (y1 - 260)) / 260 * 255)))
        vd.line([(0, y), (W, y)], fill=tuple(int(cor_n[k] * 0.8 * (1 - t) + cor_baixo[k] * t) for k in range(3)) + (a,))
    c.alpha_composite(vale)
    # o mapa: a moldura de morros some na cor da serra conforme se afasta da área jogável
    c.alpha_composite(nevoa_distancia(luz(mapa, amb), mascara, cor_n, 0.78), (mx, my))
    # névoa no pé do corte (embaixo), da cor do horizonte
    nevoa = Image.new("RGBA", (W, H))
    nd = ImageDraw.Draw(nevoa)
    y0 = my + int(mapa.height * 0.74)        # abaixo do fundo da pedreira
    for y in range(y0, H):
        a = min(235, int((y - y0) / (H - y0) * 300))
        nd.line([(0, y), (W, y)], fill=tuple(int(v * 0.6) for v in horiz) + (a,))
    c.alpha_composite(nevoa)
    if hora == "chuva":
        chuva = Image.new("RGBA", (W, H)); cd = ImageDraw.Draw(chuva)
        for _ in range(9000):
            x, y = rnd.randrange(W), rnd.randrange(H)
            cd.line([(x, y), (x - 6, y + 18)], fill=(170, 180, 196, 110), width=2)
        c.alpha_composite(chuva)
    return c


if __name__ == "__main__":
    mapa = L("mapa_transparente.png")
    longe, serra, nuvens = L("_fundo_longe.png"), L("_fundo_serra.png"), L("_fundo_nuvens.png")
    quadros = []
    for hora in HORAS:
        c = cena(hora, mapa, longe, serra, nuvens, Image.open("mapa_nevoa.png").convert("L"))
        c.save("cenario_%s.png" % hora)
        q = c.resize((c.width // 4, c.height // 4), Image.LANCZOS)
        q.save("cenario_%s_quarto.png" % hora)
        quadros.append(q.convert("RGB"))
        print(hora, c.size)
    quadros[0].save("cenario_ciclo.gif", save_all=True, append_images=quadros[1:], duration=1400, loop=0)
