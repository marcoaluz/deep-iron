"""Bloco 81: camadas PROVISÓRIAS da ruína do coletor de madeira (por cima do desenho "quebrado").

  python coletor_ruina.py   -> assets/game/iso/predios/coletor_madeira/ruina_folhas.png e ruina_entulho.png
                               + as "camadas" no predios.json (o integra.py refaz pela camadas_coletor())

As duas camadas têm o MESMO quadro e a mesma âncora do quebrado.png (270 x 270, âncora 135, 200): o jogo
só as empilha por cima (iso_art._coletor_madeira) e tira cada uma numa etapa da restauração:
  - folhas: folhas secas e verdes caídas em cima da máquina e no chão em volta (sai em "Limpar folhas e entulho");
  - entulho: galhos, tábuas e pedras em volta das esteiras (sai junto).
O tom de ferrugem é só uma cor (mod) no jogo. Pra trocar por desenhos de verdade: pôr os estados
"ruina_0".."ruina_3" (0..3 etapas feitas) no predios.json; o jogo usa eles no lugar destas camadas.
"""
import json
import math
import os
import random

from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "assets", "game", "iso", "predios"))
BASE = os.path.join(DEST, "coletor_madeira", "quebrado.png")

FOLHAS = [(58, 92, 40), (84, 120, 48), (122, 138, 54), (176, 126, 44), (156, 86, 34), (112, 64, 30), (190, 150, 70)]
CONTORNO_F = (34, 36, 20)
GALHO = [(70, 48, 30), (96, 66, 40), (122, 88, 54)]
PEDRA = [(118, 114, 104), (88, 84, 78), (64, 62, 58)]


def folha(px, w, h, x, y, cor, rnd):
    """Uma folhinha: 2-3 px de cor e 1 px de contorno embaixo."""
    forma = rnd.choice([[(0, 0), (1, 0)], [(0, 0), (1, 0), (1, -1)], [(0, 0), (0, -1), (1, -1)], [(0, 0), (1, 0), (2, -1)]])
    for dx, dy in forma:
        if 0 <= x + dx < w and 0 <= y + dy < h:
            px[x + dx, y + dy] = cor + (255,)
    for dx, _ in forma:
        if 0 <= x + dx < w and 0 <= y + 1 < h and px[x + dx, y + 1][3] == 0:
            px[x + dx, y + 1] = CONTORNO_F + (200,)


def monte(px, w, h, a, cx, cy, rx, ry, n, rnd, so_vazio, so_cheio=False):
    """Um monte de folhas: n folhinhas numa elipse (mais denso no meio)."""
    for _ in range(n):
        ang = rnd.uniform(0, 6.2832)
        r = min(abs(rnd.gauss(0, 0.5)), 1.0)
        x = int(cx + rx * r * math.cos(ang))
        y = int(cy + ry * r * math.sin(ang))
        if not (0 <= x < w and 0 <= y < h):
            continue
        if so_vazio and a[x, y] > 0:
            continue
        if so_cheio and a[x, y] == 0:
            continue
        folha(px, w, h, x, y, rnd.choice(FOLHAS), rnd)


def camada_folhas(base, rnd):
    w, h = base.size
    a = base.split()[3].load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = out.load()
    # em cima da máquina: montes no topo da silhueta (o teto da cabine e a tampa do motor) e uns no braço
    topos = []
    for x in range(0, w, 3):
        topo = next((y for y in range(h) if a[x, y] > 0), None)
        if topo is not None and topo < 190:
            topos.append((x, topo))
    for x, topo in topos:
        braco = x < 118
        if rnd.random() < (0.15 if braco else 0.75):
            monte(px, w, h, a, x, topo + rnd.randint(3, 14 if not braco else 5), rnd.randint(4, 9), rnd.randint(2, 5),
                  rnd.randint(14, 30) if not braco else rnd.randint(3, 7), rnd, False, True)
    # montes no chão encostados nas esteiras (só onde a máquina não cobre) e umas folhas soltas
    for cx, cy in [(40, 222), (95, 246), (170, 252), (232, 230), (252, 196), (20, 190), (128, 262)]:
        monte(px, w, h, a, cx + rnd.randint(-6, 6), cy + rnd.randint(-4, 4), rnd.randint(16, 24), rnd.randint(6, 10),
              rnd.randint(80, 130), rnd, True)
    for _ in range(90):
        x = rnd.randint(0, w - 3)
        y = rnd.randint(175, h - 3)
        if a[x, y] == 0:
            folha(px, w, h, x, y, rnd.choice(FOLHAS), rnd)
    return out


def tora(px, w, h, a, x0, y0, comp, larg, rnd):
    """Tora/tábua/galho deitado, na diagonal da vista iso (2:1), com a ponta clara."""
    sx = rnd.choice([1, -1])
    cor = rnd.choice(GALHO)
    for i in range(comp):
        x = x0 + sx * i
        y = y0 + i // 2
        for k in range(larg):
            yy = y + k
            if 0 <= x < w and 0 <= yy < h and a[x, yy] == 0:
                px[x, yy] = (GALHO[0] if k == larg - 1 else cor) + (255,)
    xe, ye = x0 + sx * (comp - 1), y0 + (comp - 1) // 2
    for k in range(larg - 1):
        if 0 <= xe < w and 0 <= ye + k < h and a[xe, ye + k] == 0:
            px[xe, ye + k] = (196, 160, 104, 255)  # o corte da madeira


def camada_entulho(base, rnd):
    w, h = base.size
    a = base.split()[3].load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = out.load()
    montes = [(52, 238), (210, 242), (244, 214), (24, 206), (150, 258)]
    for mx, my in montes:
        for _ in range(rnd.randint(2, 3)):  # toras e tábuas
            tora(px, w, h, a, mx + rnd.randint(-12, 8), my + rnd.randint(-6, 4), rnd.randint(10, 20), rnd.randint(2, 3), rnd)
        for _ in range(rnd.randint(3, 5)):  # galhos finos
            tora(px, w, h, a, mx + rnd.randint(-14, 10), my + rnd.randint(-6, 6), rnd.randint(5, 11), 1, rnd)
        for _ in range(rnd.randint(2, 4)):  # pedras
            sx, sy = mx + rnd.randint(-12, 12), my + rnd.randint(-2, 7)
            lw = rnd.randint(3, 6)
            for yy in range(3):
                for xx in range(lw - (yy == 0)):
                    x, y = sx + xx + (yy == 0), sy + yy
                    if 0 <= x < w and 0 <= y < h and a[x, y] == 0:
                        px[x, y] = PEDRA[min(yy, 2)] + (255,)
    return out


def camadas_json():
    return {"folhas": {"img": "coletor_madeira/ruina_folhas.png", "ancora": [135.0, 200.0]},
            "entulho": {"img": "coletor_madeira/ruina_entulho.png", "ancora": [135.0, 200.0]}}


def main():
    base = Image.open(BASE).convert("RGBA")
    rnd = random.Random(81)
    camada_folhas(base, rnd).save(os.path.join(DEST, "coletor_madeira", "ruina_folhas.png"))
    camada_entulho(base, rnd).save(os.path.join(DEST, "coletor_madeira", "ruina_entulho.png"))
    pj = os.path.join(DEST, "predios.json")
    d = json.load(open(pj, encoding="utf-8"))
    d["predios"]["coletor_madeira"]["camadas"] = camadas_json()
    json.dump(d, open(pj, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("ok ->", os.path.join(DEST, "coletor_madeira"))


if __name__ == "__main__":
    main()
