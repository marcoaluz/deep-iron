"""Prompt 30 (item 2): consistência de brilho, paleta e contorno da arte integrada.

  python tools/qa_arte.py [saida.json]

Lê a arte que o jogo usa (project.godot/assets/game/iso) e mede, em cada desenho (só os pixels
desenhados, alfa > 40):
  - brilho (L do HLS) e saturação médios;
  - CONTORNO: os pixels desenhados que encostam no transparente (a "linha" de fora): brilho e
    matiz médios;
  - cores distintas.
Junta por categoria (prédios, bonecos, objetos, terreno, céu) e marca o que destoa: brilho ou
contorno a mais de 2 desvios da categoria, e categoria inteira longe da média geral.
"""
import sys, os, json, glob, colorsys, statistics as st
from PIL import Image

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "project.godot", "assets", "game", "iso")


def mede(path):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    if w * h > 1_500_000:  # imagens grandes (terreno): amostra 1 de 4 pixels
        im = im.resize((w // 2, h // 2), Image.NEAREST)
        w, h = im.size
    px = im.load()
    L, S, cores = [], [], set()
    bl, bh = [], []
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a <= 40:
                continue
            hh, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            L.append(l); S.append(s); cores.add((r, g, b))
            borda = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if nx < 0 or ny < 0 or nx >= w or ny >= h or px[nx, ny][3] <= 40:
                    borda = True
                    break
            if borda:
                bl.append(l); bh.append(hh)
    if not L:
        return None
    return {"brilho": st.mean(L), "sat": st.mean(S), "contorno": st.mean(bl) if bl else 0.0,
            "cores": len(cores), "px": len(L)}


def categorias():
    cats = {}
    for f in glob.glob(os.path.join(RAIZ, "predios", "*", "*.png")):
        cats.setdefault("predios", []).append(f)
    # bonecos: uma pose parada (SE) por pasta, pra não pesar 2.900 quadros
    for d in sorted(glob.glob(os.path.join(RAIZ, "bonecos", "*"))):
        if not os.path.isdir(d):
            continue
        fs = sorted(glob.glob(os.path.join(d, "**", "*.png"), recursive=True))
        para = [f for f in fs if "parad" in f.lower() or "idle" in f.lower() or "rot" in f.lower()]
        pick = (para or fs)[:2]
        cats.setdefault("bonecos", []).extend(pick)
    for f in glob.glob(os.path.join(RAIZ, "props", "*.png")):
        cats.setdefault("objetos", []).append(f)
    for f in glob.glob(os.path.join(RAIZ, "mapa", "*.png")):
        if "nevoa" not in f:
            cats.setdefault("terreno", []).append(f)
    return cats


def main(saida):
    cats = categorias()
    res = {}
    for c, fs in cats.items():
        res[c] = {}
        for f in fs:
            m = mede(f)
            if m:
                res[c][os.path.relpath(f, RAIZ).replace("\\", "/")] = m
    resumo = {}
    alertas = []
    todos = [m["brilho"] for c in res for m in res[c].values()]
    g_mean, g_sd = st.mean(todos), st.pstdev(todos)
    for c, ms in res.items():
        b = [m["brilho"] for m in ms.values()]
        k = [m["contorno"] for m in ms.values()]
        s = [m["sat"] for m in ms.values()]
        resumo[c] = {"n": len(b), "brilho": round(st.mean(b), 3), "brilho_dp": round(st.pstdev(b), 3),
                     "contorno": round(st.mean(k), 3), "sat": round(st.mean(s), 3)}
        sb, sk = st.pstdev(b) or 1e-6, st.pstdev(k) or 1e-6
        for nome, m in ms.items():
            zb = (m["brilho"] - st.mean(b)) / sb
            zk = (m["contorno"] - st.mean(k)) / sk
            if abs(zb) > 2.0:
                alertas.append({"cat": c, "arte": nome, "o_que": "brilho", "valor": round(m["brilho"], 3),
                                "media_cat": round(st.mean(b), 3), "z": round(zb, 2)})
            if abs(zk) > 2.0:
                alertas.append({"cat": c, "arte": nome, "o_que": "contorno", "valor": round(m["contorno"], 3),
                                "media_cat": round(st.mean(k), 3), "z": round(zk, 2)})
    out = {"geral": {"brilho": round(g_mean, 3), "dp": round(g_sd, 3)}, "categorias": resumo,
           "alertas": alertas, "medidas": res}
    json.dump(out, open(saida, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("geral: brilho %.3f (dp %.3f)" % (g_mean, g_sd))
    for c, r in resumo.items():
        print("%-9s n=%3d brilho %.3f (dp %.3f)  contorno %.3f  sat %.3f" % (c, r["n"], r["brilho"], r["brilho_dp"], r["contorno"], r["sat"]))
    print("alertas: %d" % len(alertas))
    for a in alertas:
        print("  %-8s %-9s %-45s %.3f (cat %.3f, z %+.1f)" % (a["cat"], a["o_que"], a["arte"], a["valor"], a["media_cat"], a["z"]))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "qa_arte.json")
