"""Bloco 134: o CHÃO DA VILA com arte do PixelLab (piloto).

  python chao134.py estado            mostra o estado dos jobs (jobs.json)
  python chao134.py baixa             baixa as folhas e os ladrilhos prontos em fontes/<nome>/ (+ o texto do resultado)
  python chao134.py espera            espera os 3 jobs ficarem prontos (até 6 min) e baixa
  python chao134.py integra          grava o atlas do jogo (assets/game/iso/chao/chao134*.png + .json) e os cartões do CONSTRUIR
  python chao134.py monta             monta o TRECHO-PILOTO (piloto.png): terra com variação, fronteira orgânica pro mato
                                      (pela transição de cantos) e uma trilha com curva, T e ponta
"""
import json
import math
import os
import re
import sys
import time
import urllib.request

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.abspath(os.path.join(AQUI, "..", "..", "..", "..", "..", "tools", "pixellab")))
import pl  # noqa: E402

JOBS = os.path.join(AQUI, "jobs.json")
FONTES = os.path.join(AQUI, "fontes")
NOMES = ["cascalho_t", "pedra_t"]


def _id(nome, jobs):
    m = re.search(r"id: ([0-9a-f-]{36})", jobs.get(nome, ""))
    return m.group(1) if m else ""


def _texto(r):
    return "\n".join(c["text"] for msg in r for c in msg.get("result", {}).get("content", []) if c.get("type") == "text")


def estado():
    jobs = json.load(open(JOBS, encoding="utf-8"))
    out = {}
    for n in NOMES:
        t = _texto(pl.call("get_tiles_pro", {"tile_id": _id(n, jobs)}))
        out[n] = t
    return out


def _baixa_url(url, dest):
    req = urllib.request.Request(url, headers={"User-Agent": "deep-iron"})
    with urllib.request.urlopen(req, timeout=120) as r:
        open(dest, "wb").write(r.read())


def baixa(textos):
    for n, t in textos.items():
        d = os.path.join(FONTES, n)
        os.makedirs(d, exist_ok=True)
        open(os.path.join(d, "resultado.txt"), "w", encoding="utf-8").write(t)
        urls = re.findall(r"https?://\S+?\.png", t)
        for i, u in enumerate(urls):
            _baixa_url(u, os.path.join(d, "%02d.png" % i))
        print(n, len(urls), "png")


def espera():
    for _ in range(36):
        e = estado()
        if all(("processing" not in t.lower()) for t in e.values()):
            baixa(e)
            return
        time.sleep(10)
    print("ainda processando")


# ------------------------------------------------------------ o trecho-piloto
from PIL import Image  # noqa: E402

TRANSICAO = "transicao_a"
TRILHA = "trilha_t"
TERRA = "terra2"


def _tiles(nome):
    """Os ladrilhos de um conjunto, todos como o losango 64x32 (os de tela 64x64 trazem o losango no meio)."""
    import glob
    out = []
    for f in sorted(glob.glob(os.path.join(FONTES, nome, "*.png"))):
        im = Image.open(f).convert("RGBA")
        if im.size == (64, 64):
            im = im.crop((0, 16, 64, 48))
        out.append(im)
    return out


def _ruido(n, escala, rng):
    """Ruído suave (valor interpolado) n x n em 0..1."""
    import numpy as np
    g = rng.random((n // escala + 3, n // escala + 3))
    out = np.zeros((n, n))
    for y in range(n):
        for x in range(n):
            fx, fy = x / escala, y / escala
            x0, y0 = int(fx), int(fy)
            tx, ty = fx - x0, fy - y0
            tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
            a = g[y0, x0] * (1 - tx) + g[y0, x0 + 1] * tx
            b = g[y0 + 1, x0] * (1 - tx) + g[y0 + 1, x0 + 1] * tx
            out[y, x] = a * (1 - ty) + b * ty
    return out


def _detalhes(tiles, limiar=26.0):
    """Recorta de cada ladrilho só o DETALHE (o que foge do tom do fundo: rachadura, pedrinha, tufo), com fundo transparente."""
    import numpy as np
    out = []
    for t in tiles:
        a = np.asarray(t).astype(float)
        dentro = a[..., 3] > 0
        if not dentro.any():
            continue
        # longe da borda do losango (a borda traz contorno/sombra do ladrilho, não é detalhe)
        miolo = dentro.copy()
        for _ in range(4):
            miolo = miolo & np.roll(miolo, 1, 0) & np.roll(miolo, -1, 0) & np.roll(miolo, 1, 1) & np.roll(miolo, -1, 1)
        base = np.median(a[dentro][:, :3], axis=0)
        dif = np.abs(a[..., :3] - base).sum(axis=2)
        m = miolo & (dif > limiar)
        if m.sum() < 6:
            continue
        b = a.copy()
        b[..., 3] = np.where(m, 255, 0)
        im = Image.fromarray(b.astype("uint8"))
        bb = im.getbbox()
        if bb:
            out.append(im.crop(bb))
    return out


def monta():
    import numpy as np
    rng = np.random.default_rng(134)
    N = 30  # células por lado
    tr, tl, tt, tm = _tiles(TRANSICAO), _tiles(TRILHA), _tiles(TERRA), _tiles("mato")
    # vértices: terra (True) dentro de uma mancha com borda irregular, mato fora
    rv = _ruido(N + 1, 5, rng)
    c = N / 2.0
    terra_v = np.zeros((N + 1, N + 1), bool)
    for j in range(N + 1):
        for i in range(N + 1):
            d = math.hypot(i - c, (j - c) * 1.1)
            terra_v[j, i] = d < 10.5 + (rv[j, i] - 0.5) * 7.0
    # trilha: células pintadas (uma reta com curva, um T e uma ponta)
    trilha = set()
    for i in range(5, 26):
        trilha.add((i, 16))
    for j in range(8, 16):
        trilha.add((12, j))
    for i in range(12, 19):
        trilha.add((i, 8))
    for j in range(16, 23):
        trilha.add((20, j))
    trilha_v = np.zeros((N + 1, N + 1), bool)
    for (i, j) in trilha:
        for di in (0, 1):
            for dj in (0, 1):
                trilha_v[j + dj, i + di] = True
    dt, dm = _detalhes(tt), _detalhes(tm, 60.0)
    W, H = N * 64 + 64, N * 32 + 64
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ox, oy = N * 32, 16
    vr = rng.random((N, N))
    for s in range(2 * N):  # (losangos não se sobrepõem; a ordem é só por costume)
        for i in range(N):
            j = s - i
            if j < 0 or j >= N:
                continue
            nw, ne, sw, se = (i, j), (i + 1, j), (i, j + 1), (i + 1, j + 1)
            cantos = [nw, ne, sw, se]
            todos_terra = all(terra_v[y, x] for x, y in cantos)
            if todos_terra and any(trilha_v[y, x] for x, y in cantos):
                m = sum(b for b, (x, y) in zip((8, 4, 2, 1), cantos) if not trilha_v[y, x])
                t = tl[m]
            elif todos_terra:
                t = tr[15]  # (as variações inteiras deixavam a grade à mostra: a variação vem de detalhes soltos)
            else:
                m = sum(b for b, (x, y) in zip((8, 4, 2, 1), cantos) if terra_v[y, x])
                t = tr[m]
            sx, sy = ox + (i - j) * 32, oy + (i + j) * 16
            img.alpha_composite(t, (sx - 32, sy))
    # detalhes soltos (rachadura, pedrinha, tufo; no mato, talos e pedras), sorteados por célula e sem grade
    for j in range(N):
        for i in range(N):
            r = rng.random()
            todos_terra = terra_v[j, i] and terra_v[j, i + 1] and terra_v[j + 1, i] and terra_v[j + 1, i + 1]
            nenhum_terra = not (terra_v[j, i] or terra_v[j, i + 1] or terra_v[j + 1, i] or terra_v[j + 1, i + 1])
            trilha_aqui = trilha_v[j, i] or trilha_v[j + 1, i + 1]
            lista = dt if todos_terra and not trilha_aqui else (dm if nenhum_terra else None)
            if not lista or r > (0.22 if lista is dt else 0.30):
                continue
            d = lista[int(rng.random() * len(lista))]
            sx, sy = ox + (i - j) * 32 + int(rng.integers(-14, 15)), oy + (i + j) * 16 + 16 + int(rng.integers(-6, 7))
            img.alpha_composite(d, (sx - d.width // 2, sy - d.height // 2))
    # prédios por cima, na escala do jogo (arte = chão x 1,5): a casa e o Centro
    pred = os.path.abspath(os.path.join(AQUI, "..", "..", "..", "..", "assets", "game", "iso", "predios"))

    def poe(arq, ancora, ci, cj):
        p = Image.open(os.path.join(pred, arq)).convert("RGBA")
        sx, sy = ox + (ci - cj) * 32, oy + (ci + cj) * 16
        img.alpha_composite(p, (int(sx - ancora[0]), int(sy - ancora[1])))
    poe("centro_1/pronto.png", (95, 150), 15.5, 13.5)
    poe("casa/pronto_0.png", (120, 222), 9.5, 12.5)
    poe("casa/pronto_1.png", (120, 222), 9.5, 20.5)
    img = img.crop((ox - 15 * 64 // 2 - 200, 120, ox + 15 * 64 // 2 + 200, H - 140))
    dia = Image.new("RGBA", img.size, (24, 22, 20, 255))
    dia.alpha_composite(img)
    dia = dia.resize((dia.width * 2 // 2, dia.height * 2 // 2), Image.NEAREST)
    dia.save(os.path.join(AQUI, "piloto_dia.png"))
    noite = dia.copy()
    px = np.asarray(noite).astype(float)
    px[..., 0] *= 0.42
    px[..., 1] *= 0.46
    px[..., 2] *= 0.62
    Image.fromarray(px.clip(0, 255).astype("uint8")).save(os.path.join(AQUI, "piloto_noite.png"))
    print("piloto_dia.png e piloto_noite.png", dia.size)


# ------------------------------------------------------------ integração no jogo (aprovado pelo Marco)
RAIZ_PROJ = os.path.abspath(os.path.join(AQUI, "..", "..", "..", ".."))
DESTINO = os.path.join(RAIZ_PROJ, "assets", "game", "iso", "chao")
## as linhas do atlas: [nome no jogo, conjunto do PixelLab]. Em todas, o bit da máscara = o canto é TERRA (a 1ª terra do conjunto).
LINHAS = [["mato", "transicao_a"], ["terra", "trilha_t"], ["cascalho", "cascalho_t"], ["pedra", "pedra_t"]]


def integra():
    """Grava assets/game/iso/chao/chao134.png (16 máscaras x 4 conjuntos, losango 64x32), chao134_detalhes.png (os
    detalhes soltos de terra e de mato) e chao134.json; refaz os cartões do CONSTRUIR (cam_terra/cascalho/pedra)."""
    os.makedirs(DESTINO, exist_ok=True)
    atlas = Image.new("RGBA", (16 * 64, len(LINHAS) * 32), (0, 0, 0, 0))
    for r, (_nome, fonte) in enumerate(LINHAS):
        ts = _tiles(fonte)
        texto = open(os.path.join(FONTES, fonte, "resultado.txt"), encoding="utf-8").read()
        mascaras = {int(a): int(b) for a, b in re.findall(r"tile_(\d+): mask=(\d+)", texto)}
        for i, t in enumerate(ts[:16]):
            atlas.alpha_composite(t, (mascaras.get(i, i) * 64, r * 32))
    atlas.save(os.path.join(DESTINO, "chao134.png"))
    # detalhes soltos: empacotados numa fileira
    det = {"terra": _detalhes(_tiles(TERRA)), "mato": _detalhes(_tiles("mato"), 60.0)}
    larg = sum(d.width + 1 for ds in det.values() for d in ds)
    alt = max(d.height for ds in det.values() for d in ds)
    folha = Image.new("RGBA", (larg, alt), (0, 0, 0, 0))
    rects = {"terra": [], "mato": []}
    x = 0
    for k, ds in det.items():
        for d in ds:
            folha.alpha_composite(d, (x, 0))
            rects[k].append([x, 0, d.width, d.height])
            x += d.width + 1
    folha.save(os.path.join(DESTINO, "chao134_detalhes.png"))
    dados = {"_obs": "Bloco 134: o chão da vila (PixelLab, create_tiles_pro tileset isométrico 64x32). Cada linha tem 16 peças "
             "pela máscara dos cantos NW<<3 | NE<<2 | SW<<1 | SE (NW = ponta de cima, NE = direita, SW = esquerda, SE = de "
             "baixo); bit ligado = o canto é TERRA. Linha 'mato': terra x mato da vila; 'terra', 'cascalho', 'pedra': terra x "
             "caminho. Gerado por prototipos/camera/arte_iso/chao134/chao134.py integra.",
             "largura": 64, "altura": 32, "colunas": 16, "linhas": [l[0] for l in LINHAS], "detalhes": rects}
    json.dump(dados, open(os.path.join(DESTINO, "chao134.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("atlas", atlas.size, "detalhes", folha.size, {k: len(v) for k, v in rects.items()})
    cartoes(atlas)


def cartoes(atlas=None):
    if atlas is None:
        atlas = Image.open(os.path.join(DESTINO, "chao134.png")).convert("RGBA")
    cart = os.path.join(RAIZ_PROJ, "assets", "game", "ui", "icones", "cartoes")
    for r, (nome, _f) in enumerate(LINHAS):
        if nome == "mato":
            continue
        cheio = atlas.crop((0, r * 32, 64, r * 32 + 32))  # máscara 0: o caminho inteiro
        im = Image.new("RGBA", (96, 48), (0, 0, 0, 0))
        im.alpha_composite(cheio, (0, 0))
        im.alpha_composite(cheio, (32, 16))
        cartao = Image.new("RGBA", (96, 64), (0, 0, 0, 0))
        cartao.alpha_composite(im, (0, 8))
        cartao.save(os.path.join(cart, "cam_%s.png" % nome))
        print("cartão cam_%s.png" % nome)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "estado"
    if cmd == "estado":
        for n, t in estado().items():
            print("=====", n)
            print(t[:3000])
    elif cmd == "baixa":
        baixa(estado())
    elif cmd == "espera":
        espera()
    elif cmd == "monta":
        monta()
    elif cmd == "integra":
        integra()
    elif cmd == "cartoes":
        cartoes()
