"""Bloco 75 (rodado uma vez): leva os dados dos andares de baixo pro formato de FAIXA.

  python faixas_remapeia.py [--aplica]   (sem --aplica: só mostra o que mudaria)

Cada ponto que estava no retângulo ANTIGO de um andar vai pro mesmo lugar relativo no retângulo novo
(andares.novo), em data/niveis/S2..S5 (decoração, perigos, jazidas, decalques, obstáculos, ligações, rect)
e em scenes/game/main.tscn (jazidas, zonas, elevadores). As GAIOLAS de chegada vão exatamente pro ponto da
gaiola de cada faixa (andares.json "gaiola": a vertical do poço), não pela regra de três.
"""
import json, os, re, sys
import andares as A

RAIZ = A.RAIZ
APLICA = "--aplica" in sys.argv


def gaiola(nome):
    an = A.Andar(nome, A.ANDARES[nome], 0)
    return (round(an.gaiola[0], 1), round(an.gaiola[1], 1))


def num(v):
    return int(round(v)) if abs(v - round(v)) < 0.05 else round(v, 1)


def remapeia_tres(arquivo, nome, fundo_gaiola):
    p = os.path.join(RAIZ, "data", "niveis", arquivo)
    s = open(p, encoding="utf-8").read()
    mudou = []

    def lista(campo, xy):
        nonlocal s
        m = re.search(r"^%s = (\[.*\])$" % campo, s, re.M)
        if not m:
            return
        dados = json.loads(m.group(1))
        for item in dados:
            ix, iy = xy
            novo = A.novo((item[ix], item[iy]))
            if novo != (item[ix], item[iy]):
                item[ix], item[iy] = num(novo[0]), num(novo[1])
        txt = json.dumps(dados, ensure_ascii=False).replace("true", "true")
        s = s[:m.start(1)] + txt + s[m.end(1):]
        mudou.append(campo)

    lista("decoracao", (1, 2))
    lista("perigos", (1, 2))
    lista("jazidas", (1, 2))
    lista("decalques", (1, 2))
    m = re.search(r"^obstaculos = (\[.*\])$", s, re.M)
    if m:
        obs = [list(map(num, A.obst_novo(o))) for o in json.loads(m.group(1))]
        s = s[:m.start(1)] + json.dumps(obs) + s[m.end(1):]
        mudou.append("obstaculos")
    m = re.search(r"^ligacao_topo = Vector2\(([-\d.]+), ([-\d.]+)\)$", s, re.M)
    if m:
        n = A.novo((float(m.group(1)), float(m.group(2))))
        s = s[:m.start()] + "ligacao_topo = Vector2(%s, %s)" % (num(n[0]), num(n[1])) + s[m.end():]
        mudou.append("ligacao_topo")
    m = re.search(r"^ligacao_fundo = Vector2\(([-\d.]+), ([-\d.]+)\)$", s, re.M)
    if m:
        s = s[:m.start()] + "ligacao_fundo = Vector2(%s, %s)" % fundo_gaiola + s[m.end():]
        mudou.append("ligacao_fundo")
    m = re.search(r"^rect = Rect2\(([-\d., ]+)\)$", s, re.M)
    if m:
        s = s[:m.start()] + "rect = Rect2(%d, %d, %d, %d)" % A.ANDARES[nome]["rect"] + s[m.end():]
        mudou.append("rect")
    print("%-18s %s" % (arquivo, ", ".join(mudou)))
    if APLICA:
        open(p, "w", encoding="utf-8", newline="").write(s)


def remapeia_cena():
    p = os.path.join(RAIZ, "scenes", "game", "main.tscn")
    s = open(p, encoding="utf-8").read()
    blocos = re.split(r"\n(?=\[node )", s)
    gaiolas = {"Elevador": gaiola("nivel2"), "ElevadorAbismo": gaiola("abismo")}
    out = []
    for b in blocos:
        m = re.match(r'\[node name="([^"]+)"', b)
        nome = m.group(1) if m else ""
        def troca(mm):
            x, y = float(mm.group(2)), float(mm.group(3))
            n = A.novo((x, y))
            if n != (x, y):
                print("  %-20s %s (%g, %g) -> (%s, %s)" % (nome, mm.group(1), x, y, num(n[0]), num(n[1])))
            return "%s = Vector2(%s, %s)" % (mm.group(1), num(n[0]), num(n[1]))
        b = re.sub(r"^(position) = Vector2\(([-\d.]+), ([-\d.]+)\)", troca, b, flags=re.M)
        if nome in gaiolas:
            g = gaiolas[nome]
            b, k = re.subn(r"^bottom_position = Vector2\([-\d., ]+\)", "bottom_position = Vector2(%s, %s)" % g, b, flags=re.M)
            if k:
                print("  %-20s bottom_position -> %s (a gaiola da faixa)" % (nome, g))
        out.append(b)
    if APLICA:
        open(p, "w", encoding="utf-8", newline="").write("\n".join(out))


if __name__ == "__main__":
    remapeia_tres("S2_acido.tres", "nivel2", None)
    remapeia_tres("S3_lava.tres", "abismo", None)
    remapeia_tres("S4_cachoeira.tres", "s4", gaiola("s4"))
    remapeia_tres("S5_lago.tres", "s5", gaiola("s5"))
    print("main.tscn:")
    remapeia_cena()
    print("APLICADO" if APLICA else "(só mostrando; --aplica grava)")
