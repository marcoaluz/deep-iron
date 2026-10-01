"""Prompt 29, parte 2: leva a arte aprovada dos PRÉDIOS pro jogo.

  python integra.py predios [nome ...]  -> assets/game/iso/predios/<nome>/<estado>.png + predios.json
                                          (com nomes: refaz só esses, o resto fica)

Cada estado (pronto, obra_1..3, variação, nível, estágio do Centro, etapa de máquina) sai com
a SUA âncora (px do quadro: o centro da pegada no chão) e a SUA caixa (pegada relativa à
âncora + altura, px de arte). A caixa vem do contrato.json da pasta quando ele tem; senão é
encaixada aqui com a mesma regra do predio.py (parede de trás fixa, <= 4 px fora).

O jogo (scripts/iso/iso_art.gd) lê o predios.json: a vista desenha o estado certo na mesma
âncora e usa a caixa na ordem e no clique; a pegada de navegação é a do pronto / escala.
Pastas e arquivos em minúsculas (sem problema de case no export).
"""
import sys, os, json, shutil
from multiprocessing import Pool
import numpy as np
from PIL import Image, ImageOps

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import predio

AQUI = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.normpath(os.path.join(AQUI, "../../../assets/game/iso/predios"))
MAQ = "final_maquinas"

# nome no jogo -> pasta da arte (predio.json/contrato.json) e estados: estado -> arquivo
PREDIOS = {
    "casa": ("casa", {"pronto_0": "casa_v0.png", "pronto_1": "casa_v1.png", "pronto_2": "casa_v2.png",
                      "pronto_3": "casa_v3.png", "obra_1": "obra_1.png", "obra_2": "obra_2.png", "obra_3": "obra_3.png",
                      "nivel_2": "nivel_2.png", "nivel_3": "nivel_3.png"}),
    "armazem": ("armazem", None),
    "oficina": ("oficina", None),
    "arsenal": ("arsenal", None),
    "taverna": ("taverna", {"nivel_2": "nivel_2.png"}),
    "enfermaria": ("enfermaria", {"nivel_2": "nivel_2.png"}),
    "laboratorio": ("laboratorio", None),
    "comedouro": ("cozinha", {"com_comida": "com_comida.png"}),
    "parque": ("parque", None),
    "campo_treino": ("campo_treino", None),
    "vestiario": ("vestiario", None),
    "coletor_madeira": ("coletor_madeira", {"pronto": "../%s/coletor_madeira_pronto.png" % MAQ,
                                            "quebrado": "../%s/coletor_madeira_quebrado.png" % MAQ}),
    "escudo": ("escudo", {"etapa_%d" % (k + 1): "../%s/escudo_%d_%s.png" % (MAQ, k + 1, n)
                          for k, n in enumerate(["fundacao", "bobinas", "nucleo", "emissor"])}),
    "escavadeira": ("escavadeira", {"estrutura": "../%s/escavadeira_1_estrutura.png" % MAQ,
                                    "pronto": "../%s/escavadeira_pronta.png" % MAQ}),
}
for k in range(1, 6):
    PREDIOS["centro_%d" % k] = ("centro/estagio_%d" % k, {"pronto": "pronto.png"} if k == 1 else
                                {"pronto": "pronto.png", "obra": "obra.png"})
# níveis gerados num quadro mais alto (o prédio aprovado embaixo, sobra em cima): a âncora desce
DESCE = {("casa", "nivel_2"): 72, ("casa", "nivel_3"): 72, ("taverna", "nivel_2"): 75, ("enfermaria", "nivel_2"): 75}
# o padrão (None ou faltando): pronto + obra_1..3 da própria pasta
PADRAO = {"pronto": "pronto.png", "obra_1": "obra_1.png", "obra_2": "obra_2.png", "obra_3": "obra_3.png"}

# portão (1 por nível, Prompt 12) e o trecho de paliçada: sem predio.json; guia declarada aqui.
# Âncora = centro da pegada no chão (o portão cobre 2 tiles; o trecho, 1 tile), no eixo i (a
# paliçada do mapa corre em x). O portão foi desenhado no eixo j: sai ESPELHADO (muro fino: a
# troca de luz quase não aparece, a mesma regra da reta_j do Prompt 12). A âncora dele vem da
# prancha do muro.py (portão na peça 3 do trecho, quadro deslocado (-10, -88)): pés dos 2 postes.
SOLTOS = {
    "portao": ({"quebrado": "muro/final/portao_quebrado.png", "nivel_1": "muro/final/portao_1.png",
                "nivel_2": "muro/final/portao_2.png", "nivel_3": "muro/final/portao_3.png"},
               (126.0 - 60.0, 172.0), (64.0, 16.0, 150.0), True),
    "palicada": ({"reta": "muro/final/muro_1_reta_i.png", "danificada": "muro/final/muro_1_danificada.png"},
                 (32.0, 95.0), (32.0, 8.0, 70.0), False),
}
# escavadeira: as peças instaladas por cima da estrutura (região do pronto, regioes.json)
PECAS = ["motor", "hidraulica", "cabine", "broca"]
REATORES = ["vapor", "diesel", "cristal", "solar", "fusao"]


def encaixa(args):
    """A menor caixa (parede de trás fixa) em que o desenho cabe com <= 4 px fora."""
    f, ax, ay, fw, fd, h0 = args
    a = np.array(Image.open(f).convert("RGBA"))
    ys, xs = np.nonzero(a[..., 3] > 40)
    sx, sy = xs + 0.5 - ax, ys + 0.5 - ay
    x0, y0 = -fw / 2.0, -fd / 2.0
    melhor = None
    passo = 2 if fw + fd > 60 else 1
    for x1 in np.arange(x0 + min(20, fw * 0.5), fw / 2 + 60, passo):
        for y1 in np.arange(y0 + min(20, fd * 0.5), fd / 2 + 60, passo):
            hs = np.arange(10, h0 + 160, 2)
            if predio._fora(sx, sy, x0, x1, y0, y1, hs[-1]) > 4:
                continue
            lo, hi = 0, len(hs) - 1
            while lo < hi:
                mid = (lo + hi) // 2
                if predio._fora(sx, sy, x0, x1, y0, y1, hs[mid]) <= 4:
                    hi = mid
                else:
                    lo = mid + 1
            v = (x1 - x0) * (y1 - y0) * hs[lo]
            if melhor is None or v < melhor[0]:
                melhor = (v, float(x1), float(y1), float(hs[lo]))
    if melhor is None:
        return f, None
    _, x1, y1, h = melhor
    return f, {"peg": [x0, y0, x1, y1], "h": h, "fora": predio._fora(sx, sy, x0, x1, y0, y1, h)}


def contrato_de(pasta):
    for nome in ("contrato.json", "contrato_%s.json" % os.path.basename(pasta)):
        p = os.path.join(AQUI, pasta, nome)
        if os.path.exists(p):
            return json.load(open(p))
    return {}


def predios(so=None):
    os.makedirs(DEST, exist_ok=True)
    velho = os.path.join(DEST, "predios.json")
    saida = {"_obs": "Prompt 29 parte 2 (integra.py predios): estado -> img, âncora no quadro, caixa "
                     "(pegada relativa à âncora, px de arte) e altura. 'base' = pegada do pronto (navegação).",
             "predios": {}}
    pendentes = []
    for nome, (pasta, estados) in PREDIOS.items():
        if so and nome not in so:
            continue
        pj = os.path.join(AQUI, pasta, "predio.json")
        # a casa (checkpoint 2) é anterior ao predio.py: a guia dela está no contrato_casa.json
        meta = json.load(open(pj)) if os.path.exists(pj) else {"ancora": contrato_de(pasta)["ancora_no_quadro"],
                                                               "caixa_guia": [130.0, 100.0, 150.0]}
        anc = meta["ancora"]
        fw, fd, h0 = meta["caixa_guia"]
        caixas = contrato_de(pasta).get("caixas", {})
        est = dict(PADRAO)
        if estados:
            est = dict(estados) if nome in ("casa", "coletor_madeira", "escudo", "escavadeira") or nome.startswith("centro_") else {**PADRAO, **estados}
        os.makedirs(os.path.join(DEST, nome), exist_ok=True)
        info = {"estados": {}}
        for e, arq in est.items():
            src = os.path.normpath(os.path.join(AQUI, pasta, arq))
            if not os.path.exists(src):
                print("  falta:", nome, e, src)
                continue
            dst = os.path.join(DEST, nome, e + ".png")
            shutil.copyfile(src, dst)
            cx = caixas.get(os.path.splitext(os.path.basename(arq))[0])
            ay = float(anc[1]) + DESCE.get((nome, e), 0)
            d = {"img": "%s/%s.png" % (nome, e), "ancora": [float(anc[0]), ay]}
            if cx and os.path.dirname(arq) == "":
                d["peg"] = [float(v) for v in cx["pegada_rel_ancora"]]
                d["h"] = float(cx["altura"])
            else:
                pendentes.append((nome, e, (src, anc[0], ay, fw, fd, h0 + DESCE.get((nome, e), 0))))
            info["estados"][e] = d
        saida["predios"][nome] = info
    for nome, (est, anc, (fw, fd, h0), espelha) in SOLTOS.items():
        if so and nome not in so:
            continue
        os.makedirs(os.path.join(DEST, nome), exist_ok=True)
        info = {"estados": {}}
        for e, arq in est.items():
            dst = os.path.join(DEST, nome, e + ".png")
            im = Image.open(os.path.join(AQUI, arq)).convert("RGBA")
            (ImageOps.mirror(im) if espelha else im).save(dst)
            info["estados"][e] = {"img": "%s/%s.png" % (nome, e), "ancora": list(anc)}
            pendentes.append((nome, e, (dst, anc[0], anc[1], fw, fd, h0)))
        saida["predios"][nome] = info
    if not so or "escavadeira" in so:
        pecas_escavadeira(saida)
    print("encaixando %d caixas..." % len(pendentes))
    with Pool() as pool:
        res = dict(pool.map(encaixa, [p[2] for p in pendentes]))
    for nome, e, args in pendentes:
        r = res[args[0]]
        if r is None:
            print("  SEM CAIXA:", nome, e)
            continue
        saida["predios"][nome]["estados"][e].update(r)
    if so and os.path.exists(velho):
        tudo = json.load(open(velho, encoding="utf-8"))
        tudo["predios"].update(saida["predios"])
        saida = tudo
    for nome, info in saida["predios"].items():
        if so and nome not in so:
            continue
        base = info["estados"].get("pronto") or info["estados"].get("pronto_0") or info["estados"].get("etapa_4") \
            or info["estados"].get("nivel_1") or info["estados"].get("reta")
        if base and "peg" in base:
            info["base"] = base["peg"]
        for e, d in info["estados"].items():
            if "peg" in d:
                p = d["peg"]
                print("%-16s %-10s pegada %4.0f x %4.0f  altura %4.0f  fora %s" % (nome, e, p[2] - p[0], p[3] - p[1], d["h"], d.get("fora", "-")))
    json.dump(saida, open(os.path.join(DEST, "predios.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("->", os.path.join(DEST, "predios.json"))


def pecas_escavadeira(saida):
    """As 4 peças da escavadeira como camadas (a região de cada uma recortada do pronto) e os
    5 reatores (Prompt 13) num quadro do mesmo tamanho, embaixo do convés à esquerda."""
    reg = json.load(open(os.path.join(AQUI, "escavadeira", "regioes.json")))
    pronto = Image.open(os.path.join(AQUI, MAQ, "escavadeira_pronta.png")).convert("RGBA")
    meta = json.load(open(os.path.join(AQUI, "escavadeira", "predio.json")))
    info = saida["predios"]["escavadeira"]
    info["camadas"] = {}
    for p in PECAS:
        c = Image.new("RGBA", pronto.size)
        for (x0, y0, x1, y1) in reg[p]:
            c.paste(pronto.crop((x0, y0, x1, y1)), (x0, y0))
        c.save(os.path.join(DEST, "escavadeira", "peca_%s.png" % p))
        info["camadas"][p] = {"img": "escavadeira/peca_%s.png" % p, "ancora": meta["ancora"]}
    for r in REATORES:
        im = Image.open(os.path.join(AQUI, MAQ, "reator_%s.png" % r)).convert("RGBA")
        im = im.crop(im.getbbox())
        im.save(os.path.join(DEST, "escavadeira", "reator_%s.png" % r))
        # pé do reator: no chão, na frente-esquerda da plataforma (px relativos à âncora)
        info["camadas"]["reator_" + r] = {"img": "escavadeira/reator_%s.png" % r,
                                          "ancora": [im.width / 2.0 + 70.0, im.height - 2.0 - 62.0]}


if __name__ == "__main__":
    if sys.argv[1:2] == ["predios"]:
        predios(sys.argv[2:] or None)
    else:
        print(__doc__)
