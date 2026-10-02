"""Prompt 29: os ANDARES DE BAIXO empilhados embaixo da superfície (corte vertical).

  python andares.py [pasta]   -> (padrão: assets/game/iso/mapa) andar_nivel2.png, andar_abismo.png,
                                 coluna_rocha.png e andares.json (lido pela vista iso do jogo)

O jogo já tem 2 andares de baixo (nível 2 e abismo), na lógica como áreas separadas ligadas
pelos elevadores. Aqui eles viram LAJES empilhadas embaixo da superfície, no formato do
"Layers Exploded View" (as camadas separadas, uma embaixo da outra): chão do andar, paredes de
trás, a laje cortada na frente, e as zonas (gás, calor, radiação) pintadas com o chão delas.
O vão entre as camadas é o bastante pra uma não cobrir a outra na tela (os andares do jogo
são grandes no chão: num corte colado, quase só se veria a borda de cada um).
Nada novo é gerado: usa os blocos e chãos do Prompt 7 (relevo/final/nivel2, abismo, mina).

Coordenadas: a mesma grade da superfície (monta.py: tile de 32, origem OX/OY, 1,5 px de arte
por px do mundo). Cada andar alinha o canto da FRENTE (x e y máximos) do retângulo dele na
lógica com o canto da frente do mapa: vista(px de arte) = (lógica - fim_do_retângulo)*1,5 +
canto_da_frente; altura do chão = K_CHAO*32.
"""
import sys, os, glob, json, math
from PIL import Image
sys.path.insert(0, "../relevo")
import tiles
from monta import OX, OY, NI, NJ, T, FATOR

REL = "../relevo/final"
# andar: retângulo na lógica (environment.gd: deep_rect / abyss_rect), degrau do chão, altura das
# paredes (degraus), espessura da laje (degraus), pasta dos blocos/chão
ANDARES = {
    "nivel2": {"rect": (-560, 700, 1120, 620), "k_chao": -53, "paredes": 4, "laje": 3, "pasta": "nivel2"},
    "abismo": {"rect": (-480, 1420, 960, 560), "k_chao": -100, "paredes": 4, "laje": 3, "pasta": "abismo"},
    # Bloco 71: os níveis novos (data/niveis/S4_cachoeira.tres e S5_lago.tres: o mesmo `rect`)
    "s4": {"rect": (-440, 2120, 880, 520), "k_chao": -147, "paredes": 5, "laje": 3, "pasta": "umido"},
    "s5": {"rect": (-400, 2760, 800, 480), "k_chao": -194, "paredes": 4, "laje": 3, "pasta": "lago"},
}


def _dos_dados(arquivo, campo):
    """Lista JSON de um campo do .tres do nível (data/niveis): a posição das poças e do lago vem de lá."""
    import re
    t = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "data", "niveis", arquivo),
             encoding="utf-8").read()
    m = re.search(r"^%s = (\[.*\])$" % campo, t, re.M)
    return json.loads(m.group(1)) if m else []


# Bloco 71: o lago do S5 (`obstaculos` no .tres, a elipse dentro do retângulo): chão de água rasa, com a
# borda de seixos num anel em volta (itens de arte do documento)
AGUA = [tuple(o) for o in _dos_dados("S5_lago.tres", "obstaculos")]
BORDA = 1.25   # o anel da borda: até 1,25x a elipse
# itens de arte: a rocha com ácido em volta das poças de ácido do S2 (`perigos` no .tres)
ACIDO = [((p[1], p[2]), p[3] * 1.3) for p in _dos_dados("S2_acido.tres", "perigos") if p[0] == "acido"]
K_CORTE = -4          # o corte da superfície desce até aqui (monta.py CORTE)
# zonas de perigo da cena (main.tscn): centro na lógica, raio, tipo
ZONAS = [((455, 1240), 85, "gas"), ((-470, 770), 80, "radiacao"), ((390, 1895), 80, "calor")]


def ld(p):
    return [Image.open(f).convert("RGBA") for f in sorted(glob.glob(p))]


def sala(a):
    """tiles da sala (i0..NI-1, j0..NJ-1) que cobrem o retângulo do andar, no canto da frente."""
    x, y, w, h = a["rect"]
    ni = math.ceil(w * FATOR / T)
    nj = math.ceil(h * FATOR / T)
    return NI - ni, NJ - nj


def logica(a, i, j):
    """centro do tile (i, j) da vista -> ponto da lógica do andar."""
    x, y, w, h = a["rect"]
    ax = OX + (i + 0.5) * T
    ay = OY + (j + 0.5) * T
    fim = (OX + NI * T, OY + NJ * T)
    return ((ax - fim[0]) / FATOR + x + w, (ay - fim[1]) / FATOR + y + h)


def zona_em(p):
    for x, y, w, h in AGUA:  # o lago é a elipse dentro do retângulo (o jogo usa a mesma no obstáculo)
        dx, dy = (p[0] - (x + w / 2)) / (w / 2), (p[1] - (y + h / 2)) / (h / 2)
        if dx * dx + dy * dy <= 1.0:
            return "agua"
        if dx * dx + dy * dy <= BORDA * BORDA:
            return "borda"
    for (cx, cy), r in ACIDO:
        dx, dy = p[0] - cx, p[1] - cy
        if (dx * dx) / (r * r) + (dy * dy) / (r * r * 0.36) <= 1.0:
            return "acido"
    for (cx, cy), r, kind in ZONAS:
        dx, dy = p[0] - cx, p[1] - cy
        if (dx * dx) / (r * r) + (dy * dy) / (r * r * 0.36) <= 1.0:
            return kind
    return None


def compoe(itens):
    itens.sort(key=lambda t: (t[0], t[1]))
    x0 = min(t[3][0] for t in itens); y0 = min(t[3][1] for t in itens)
    x1 = max(t[3][0] + t[2].width for t in itens); y1 = max(t[3][1] + t[2].height for t in itens)
    c = Image.new("RGBA", (x1 - x0, y1 - y0))
    for t in itens:
        c.alpha_composite(t[2], (t[3][0] - x0, t[3][1] - y0))
    bb = c.getbbox()
    return c.crop(bb), (x0 + bb[0], y0 + bb[1])


def main(pasta):
    os.makedirs(pasta, exist_ok=True)
    oxy = (OX - OY - 32, (OX + OY) / 2.0)        # tela do python -> tela do jogo (monta.exporta)
    rocha = ld(REL + "/rocha/bloco.png") + ld(REL + "/rocha/bloco_[0-9].png")
    meta = {"fator": FATOR, "canto_frente_arte": [OX + NI * T, OY + NJ * T], "nivel_arte": 32, "andares": {}}
    salas = {}
    for nome, a in ANDARES.items():
        i0, j0 = sala(a)
        salas[nome] = (i0, j0)
        chao = ld(REL + "/%s/chao_*.png" % a["pasta"])
        bloco = ld(REL + "/%s/bloco.png" % a["pasta"])
        zchao = {k: ld(REL + "/mina/zona_%s/chao_*.png" % k) for k in ("gas", "calor", "radiacao", "agua", "acido", "borda")}
        kc = a["k_chao"]
        itens = []
        for i in range(i0 - 1, NI):
            for j in range(j0 - 1, NJ):
                parede = i == i0 - 1 or j == j0 - 1      # paredes de trás (norte e oeste)
                frente = i == NI - 1 or j == NJ - 1      # bordas da frente: a laje cortada aparece
                if parede:
                    for k in range(kc - (a["laje"] if frente else 0) + 1, kc + a["paredes"] + 1):
                        b = tiles.escolhe(bloco, i, j, k, False)
                        itens.append((i + j, k, tiles.escurece(b, 0.78 if k > kc else 0.6), tiles.tela(i, j, k)))
                    continue
                if frente:              # a laje embaixo do chão, vista pelo corte
                    for k in range(kc - a["laje"] + 1, kc):
                        b = tiles.escolhe(bloco, i, j, k, False)
                        itens.append((i + j, k, tiles.escurece(b, 0.82 ** (kc - k)), tiles.tela(i, j, k)))
                kind = zona_em(logica(a, i, j))
                tex = zchao[kind] if kind and zchao.get(kind) else chao
                top = tiles.escolhe(tex, i, j, 3)
                b = tiles.escolhe(bloco, i, j, kc, False).copy()
                b.paste(top, (0, 0), top)
                itens.append((i + j, kc, b, tiles.tela(i, j, kc)))
        img, (tx, ty) = compoe(itens)
        img.save(os.path.join(pasta, "andar_%s.png" % nome))
        x, y, w, h = a["rect"]
        meta["andares"][nome] = {
            "img": "andar_%s.png" % nome, "tela": [tx + oxy[0], ty + oxy[1]],
            "rect": [x, y, w, h], "z_chao": kc * 32,
            # caixa (na vista, px de arte): a sala inteira, da laje até o chão
            "caixa": [OX + i0 * T, OY + j0 * T, (NI - i0) * T, (NJ - j0) * T],
            "z": [(kc - a["laje"]) * 32, kc * 32]}
        print("%-7s sala tiles %d..%d x %d..%d  chão k=%d  imagem %dx%d" % (nome, i0, NI - 1, j0, NJ - 1, kc, img.width, img.height))
    json.dump(meta, open(os.path.join(pasta, "andares.json"), "w"), indent=1)
    print("andares.json")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "../../../../assets/game/iso/mapa")
