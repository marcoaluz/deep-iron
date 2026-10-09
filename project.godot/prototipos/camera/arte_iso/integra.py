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
import sys, os, json, shutil, glob
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
    "armazem": ("armazem", {"nivel_2": "nivel_2.png", "nivel_3": "nivel_3.png"}),  # Bloco 97 (armazem/niveis97.py)
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
    "coletor_minerio": ("coletor_minerio", {"pronto": "../%s/coletor_minerio_pronto.png" % MAQ}),  # Bloco 57
    "fornalha": ("fundicao", None),  # Bloco 92: a Fundição do Prompt 12 (nunca tinha entrado no jogo)
    "igreja": ("igreja", None),  # Bloco 92 (predios92.py)
    "carpintaria": ("carpintaria", None),  # Bloco 94 (predios94.py)
    "estufa": ("estufa", None), "carvoaria": ("carvoaria", None), "curtume": ("curtume", None),  # Bloco 107 (predios107.py)
    "escudo": ("escudo", {"etapa_%d" % (k + 1): "../%s/escudo_%d_%s.png" % (MAQ, k + 1, n)
                          for k, n in enumerate(["fundacao", "bobinas", "nucleo", "emissor"])}),
    "escavadeira": ("escavadeira", {"estrutura": "../%s/escavadeira_1_estrutura.png" % MAQ,
                                    "pronto": "../%s/escavadeira_pronta.png" % MAQ}),
}
# elevadores (Prompt 13): a ponta de cima (ruína -> pronto); a de baixo é a gaiola (SOLTOS)
PREDIOS["elevador"] = ("elevador", {"ruina": "../%s/elevador_ruina.png" % MAQ, "pronto": "../%s/elevador_pronto.png" % MAQ})
PREDIOS["elevador_abismo"] = ("elevador", {"ruina": "../%s/elevador_abismo_ruina.png" % MAQ,
                                           "pronto": "../%s/elevador_abismo_pronto.png" % MAQ})
for k in range(1, 6):
    PREDIOS["centro_%d" % k] = ("centro/estagio_%d" % k, {"pronto": "pronto.png"} if k == 1 else
                                {"pronto": "pronto.png", "obra": "obra.png"})
# níveis gerados num quadro mais alto (o prédio aprovado embaixo, sobra em cima): a âncora desce
DESCE = {("casa", "nivel_2"): 72, ("casa", "nivel_3"): 72, ("taverna", "nivel_2"): 75, ("enfermaria", "nivel_2"): 75,
         ("armazem", "nivel_2"): 60, ("armazem", "nivel_3"): 60}  # Bloco 97
# o padrão (None ou faltando): pronto + obra_1..3 da própria pasta
PADRAO = {"pronto": "pronto.png", "obra_1": "obra_1.png", "obra_2": "obra_2.png", "obra_3": "obra_3.png"}

# portão (1 por nível, Prompt 12) e o trecho de paliçada: sem predio.json; guia declarada aqui.
# Âncora = centro da pegada no chão (o portão cobre 3 tiles; o trecho, 1 tile), no eixo i (a
# paliçada do mapa corre em x). O portão do Prompt 12 saiu no eixo j; foi REFEITO no eixo i no
# Prompt 29 (muro/final/portao_i_*.png, muro/jobs.json). Âncora e guia do Prompt 12
# (muro/portao/predio.json: 96×20, âncora 63,164).
SOLTOS = {
    "portao": ({"quebrado": "muro/final/portao_i_quebrado.png", "nivel_1": "muro/final/portao_i_nivel_1.png",
                "nivel_2": "muro/final/portao_i_nivel_2.png", "nivel_3": "muro/final/portao_i_nivel_3.png"},
               (63.0, 164.0), (96.0, 20.0, 150.0)),
    "palicada": ({"reta": "muro/final/muro_1_reta_i.png", "danificada": "muro/final/muro_1_danificada.png"},
                 (32.0, 95.0), (32.0, 8.0, 70.0)),
    # a gaiola de chegada (ponta de baixo dos elevadores): pé no meio da base
    "gaiola": ({"gaiola": "final_maquinas/elevador_gaiola.png"}, (29.0, 85.0), (36.0, 36.0, 80.0)),
}
# escavadeira: as peças instaladas por cima da estrutura (região do pronto, regioes.json)
PECAS = ["motor", "hidraulica", "cabine", "broca"]
REATORES = ["vapor", "diesel", "cristal", "solar", "fusao"]


# Prompt 30 (consistência): desenhos que ficaram escuros demais pra categoria deles (brilho médio
# abaixo da faixa 0,18–0,26 do contrato, sem motivo de material) sobem até o piso da faixa. O
# arquivo original no protótipo fica como está; só a cópia do jogo é ajustada.
BRILHO_MIN = 0.18
AJUSTA_BRILHO = {"elevador", "portao/nivel_1", "portao/nivel_2",
                 "achado_bobina", "achado_cristal", "achado_peca"}


def _brilho(a):
    m = a[..., 3] > 40
    return (a[..., :3].max(-1)[m] / 255.0).mean() if m.any() else 1.0


def ajusta_brilho(path, alvo=BRILHO_MIN, teto=1.45):
    """Multiplica o valor (HSV) dos pixels até o brilho médio chegar no alvo; o contorno quase
    preto fica como está. Devolve (antes, depois)."""
    a = np.array(Image.open(path).convert("RGBA")).astype(float)
    antes = _brilho(a)
    if antes >= alvo:
        return antes, antes
    k = min(teto, alvo / antes)
    for _ in range(4):  # o contorno não sobe: corrige o fator até bater o alvo
        b = a.copy()
        v = b[..., :3].max(-1)
        m = (b[..., 3] > 0) & (v > 0.12 * 255)
        b[..., :3][m] = np.clip(b[..., :3][m] * k, 0, 255)
        depois = _brilho(b)
        if depois >= alvo - 0.002 or k >= teto:
            break
        k = min(teto, k * alvo / depois)
    Image.fromarray(b.astype(np.uint8), "RGBA").save(path)
    return antes, depois


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
            est = dict(estados) if nome in ("casa", "coletor_madeira", "coletor_minerio", "escudo", "escavadeira") or nome.startswith(("centro_", "elevador")) else {**PADRAO, **estados}
        os.makedirs(os.path.join(DEST, nome), exist_ok=True)
        info = {"estados": {}}
        for e, arq in est.items():
            src = os.path.normpath(os.path.join(AQUI, pasta, arq))
            if not os.path.exists(src):
                print("  falta:", nome, e, src)
                continue
            dst = os.path.join(DEST, nome, e + ".png")
            shutil.copyfile(src, dst)
            if nome in AJUSTA_BRILHO or "%s/%s" % (nome, e) in AJUSTA_BRILHO:
                print("  brilho %s/%s: %.3f -> %.3f" % ((nome, e) + ajusta_brilho(dst)))
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
    for nome, (est, anc, (fw, fd, h0)) in SOLTOS.items():
        if so and nome not in so:
            continue
        os.makedirs(os.path.join(DEST, nome), exist_ok=True)
        info = {"estados": {}}
        for e, arq in est.items():
            dst = os.path.join(DEST, nome, e + ".png")
            shutil.copyfile(os.path.join(AQUI, arq), dst)
            if "%s/%s" % (nome, e) in AJUSTA_BRILHO:
                print("  brilho %s/%s: %.3f -> %.3f" % ((nome, e) + ajusta_brilho(dst)))
            info["estados"][e] = {"img": "%s/%s.png" % (nome, e), "ancora": list(anc)}
            pendentes.append((nome, e, (dst, anc[0], anc[1], fw, fd, h0)))
        saida["predios"][nome] = info
    if not so or "escavadeira" in so:
        pecas_escavadeira(saida)
    if (not so or "coletor_madeira" in so) and "coletor_madeira" in saida["predios"]:
        # Bloco 81: as camadas provisórias da ruína (folhas, entulho), geradas por coletor_ruina.py
        from coletor_ruina import camadas_json
        saida["predios"]["coletor_madeira"]["camadas"] = camadas_json()
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
            or info["estados"].get("nivel_1") or info["estados"].get("reta") or info["estados"].get("gaiola")
        if base and "peg" in base:
            info["base"] = base["peg"]
        for e, d in info["estados"].items():
            if "peg" in d:
                p = d["peg"]
                print("%-16s %-10s pegada %4.0f x %4.0f  altura %4.0f  fora %s" % (nome, e, p[2] - p[0], p[3] - p[1], d["h"], d.get("fora", "-")))
    luzes_dos_predios(saida)
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


# ------------------------------------------------------------ bonecos (Prompt 29, parte 3)
BON = os.path.normpath(os.path.join(AQUI, "../../../assets/game/iso/bonecos"))
DIRS = ["SE", "NE", "SO", "NO"]
ROT = {"SE": "south-east", "NE": "north-east", "SO": "south-west", "NO": "north-west"}
# função do jogo -> (pasta do homem, pasta da mulher, animação de trabalho)
FUNCOES = {"minerador": ("minerador", "mineradora", "minerar"), "guarda": ("guarda", "guarda_mulher", "atacar"),
           "medico": ("medico", "medica", "atender"), "engenheiro": ("engenheiro", "engenheira", "construir"),
           "cacador": ("cacador", "cacadora", "cacar"), "pesquisador": ("pesquisador", "pesquisadora", "pesquisar"),
           "lenhador": ("lenhador", "lenhadora", "cortar"), "civil": ("civil", "civil_mulher", None),
           "cozinheiro": ("cozinheiro", "cozinheira", "cozinhar"),
           # Bloco 92: os ofícios dos Blocos 86-88 com arte do PixelLab (oficios92.py); o padre é só homem
           "fundidor": ("fundidor", "fundidora", "fundir"), "ferreiro": ("ferreiro", "ferreira", "forjar"),
           "padre": ("padre", "padre", "pregar"),
           "carpinteiro": ("carpinteiro", "carpinteira", "serrar"),  # Bloco 94 (oficios94.py)
           "batedor": ("batedor", "batedora", "bater"),  # Bloco 104 (oficios104.py)
           "agricultor": ("agricultor", "agricultora", "colher")}  # Bloco 107 (oficios107.py)
COMUNS = ["caminhada", "comer", "ferido", "deitar", "mancar_esq", "com_picareta"]
# pendências dos Prompts 2 e 29: colher fruta (caçador sem arco), treinar no campo e o ataque com a
# arma de verdade do guarda (lança / besta; a lança de prata usa a da lança)
EXTRA = {"cacador": ["colher", "curtir"], "cacadora": ["colher", "curtir"],  # Bloco 107: curtir (curtume)
         "lenhador": ["carvoejar"], "lenhadora": ["carvoejar"],  # Bloco 107: carvoejar (carvoaria)
         "guarda": ["treinar", "atacar_lanca", "atacar_besta"], "guarda_mulher": ["treinar", "atacar_lanca", "atacar_besta"]}


def _pe(im):
    """Âncora calculada (quando não há anotação): centro dos pixels das 3 linhas de baixo, linha do pé."""
    a = np.array(im)[..., 3] > 40
    ys, xs = np.nonzero(a)
    if len(ys) == 0:
        return (im.width / 2.0, im.height - 1.0)
    yb = ys.max()
    m = ys >= yb - 2
    return (float(xs[m].mean()), float(yb + 1))


def _ancoras(pasta, anim, d, frames):
    """Âncora de cada quadro: verificacao.json (por quadro) > anim.json (por direção) >
    contrato.json (direções da caminhada) > calculada."""
    base = os.path.join(AQUI, pasta, anim)
    for vf in (os.path.join(base, d, "verificacao.json"), os.path.join(base, "verificacao.json")):
        if os.path.exists(vf):
            q = {os.path.normpath(x["arquivo"]): x["ancora"] for x in json.load(open(vf, encoding="utf-8")).get("quadros", [])}
            out = [q.get(os.path.normpath(os.path.join(d, os.path.basename(f))), q.get(os.path.basename(f))) for f in frames]
            if all(out):
                return [tuple(x) for x in out]
    aj = os.path.join(base, "anim.json")
    if os.path.exists(aj):
        a = json.load(open(aj, encoding="utf-8")).get(d, {}).get("ancora")
        if a:
            return [tuple(a)] * len(frames)
    cj = os.path.join(AQUI, pasta, "contrato.json")
    if anim == "caminhada" and os.path.exists(cj):
        a = json.load(open(cj, encoding="utf-8")).get("direcoes", {}).get(d, {}).get("ancora")
        if a:
            return [tuple(a)] * len(frames)
    return [_pe(Image.open(f).convert("RGBA")) for f in frames]


def _tira(frames, ancs):
    """Os quadros numa tira com a MESMA âncora (cada um deslocado pra o pé dele cair no mesmo
    ponto). Devolve (imagem, âncora, tamanho do quadro, topo por quadro [x, y] relativo à âncora)."""
    ims = [Image.open(f).convert("RGBA") for f in frames]
    ax = max(a[0] for a in ancs); ay = max(a[1] for a in ancs)
    w = int(np.ceil(max(ax + im.width - a[0] for im, a in zip(ims, ancs))))
    h = int(np.ceil(max(ay + im.height - a[1] for im, a in zip(ims, ancs))))
    tira = Image.new("RGBA", (w * len(ims), h))
    topos = []
    for k, (im, a) in enumerate(zip(ims, ancs)):
        ox, oy = int(round(ax - a[0])), int(round(ay - a[1]))
        tira.alpha_composite(im, (k * w + ox, oy))
        bb = im.getbbox() or (0, 0, im.width, im.height)
        topos.append([round((bb[0] + bb[2]) / 2.0 - a[0], 1), round(bb[1] - a[1], 1)])
    return tira, [round(ax, 1), round(ay, 1)], [w, h], topos


# ---- pele em 3 tons, quadro a quadro (a regra do tons_de_pele.py / skin_palette.gd, vetorizada)
import tons_de_pele as _tp


def _hls(rgb):
    r, g, b = [rgb[..., k] / 255.0 for k in range(3)]
    mx = np.maximum(np.maximum(r, g), b); mn = np.minimum(np.minimum(r, g), b)
    l = (mx + mn) / 2.0
    d = mx - mn
    s = np.where(d == 0, 0.0, np.where(l <= 0.5, d / np.where(mx + mn == 0, 1, mx + mn), d / np.where(2.0 - mx - mn == 0, 1, 2.0 - mx - mn)))
    dd = np.where(d == 0, 1, d)
    rc, gc, bc = (mx - r) / dd, (mx - g) / dd, (mx - b) / dd
    h = np.where(r == mx, bc - gc, np.where(g == mx, 2.0 + rc - bc, 4.0 + gc - rc))
    h = np.where(d == 0, 0.0, (h / 6.0) % 1.0)
    return h, l, s


def _recolor_quadro(a, rampa):
    """a: quadro RGBA (numpy, uint8). Troca a pele no lugar, igual ao tons_de_pele.recolor."""
    al = a[..., 3] > 40
    ys, xs = np.nonzero(al)
    if len(ys) == 0:
        return
    y0b, y1b, x0b, x1b = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    hh = y1b - y0b
    fy0, fy1 = y0b + int(hh * 0.10), y0b + int(hh * 0.30)
    rgb = a[..., :3].astype(np.int64)
    key = (rgb[..., 0] << 16) | (rgb[..., 1] << 8) | rgb[..., 2]
    h, l, sat = _hls(a[..., :3].astype(float))
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    skin = (h >= 0.0) & (h <= 0.11) & (l >= 0.18) & (l <= 0.82) & (sat >= 0.18) & (sat <= 0.75) & (r > g) & (g > b) & (sat <= 0.6)
    band = np.zeros_like(al); band[fy0:fy1, x0b:x1b] = True
    m = al & skin & band
    if not m.any():
        return
    ks, cnt = np.unique(key[m], return_counts=True)
    cols = dict(zip(ks.tolist(), cnt.tolist()))
    body = np.zeros_like(al); body[fy1:y1b, x0b:x1b] = True
    mb = al & body & np.isin(key, ks)
    kb, cb = np.unique(key[mb], return_counts=True)
    corpo = dict(zip(kb.tolist(), cb.tolist()))
    solta = [k for k, n in cols.items() if n >= 2]
    estrita = {k for k in solta if corpo.get(k, 0) <= cols[k]}
    if not solta:
        return
    lo, hi = _tp.LUM_PELE
    mapa = {}
    for k in solta:
        c = ((k >> 16) & 255, (k >> 8) & 255, k & 255)
        lum = _hls(np.array(c, dtype=float).reshape(1, 1, 3))[1][0, 0]
        t = min(1.0, max(0.0, (lum - lo) / (hi - lo)))
        i = t * (len(rampa) - 1)
        p0, p1 = rampa[int(i)], rampa[min(int(i) + 1, len(rampa) - 1)]
        f = i - int(i)
        mapa[k] = [round(p0[q] + (p1[q] - p0[q]) * f) for q in range(3)]
    rows = np.arange(a.shape[0])[:, None]
    for k, c in mapa.items():
        sel = al & (key == k) & ((rows < fy1) | (k in estrita))
        a[sel, 0], a[sel, 1], a[sel, 2] = c


def _tons(tira_path, n, w):
    """Grava <tira>__<tom>.png pros 3 tons (quadro a quadro)."""
    im = np.array(Image.open(tira_path).convert("RGBA"))
    for tom, rampa in _tp.RAMPAS.items():
        a = im.copy()
        for k in range(n):
            q = a[:, k * w:(k + 1) * w]
            _recolor_quadro(q, rampa)
            a[:, k * w:(k + 1) * w] = q
        Image.fromarray(a, "RGBA").save(tira_path[:-4] + "__%s.png" % tom)


def _tons_job(args):
    _tons(*args)
    return args[0]


def _exporta_boneco(pasta, anims):
    info = {"anims": {}}
    os.makedirs(os.path.join(BON, pasta), exist_ok=True)
    # parado: a pose de cada direção (rotações v3)
    par = {}
    for d in DIRS:
        f = os.path.join(AQUI, pasta, "rotacoes", ROT[d] + ".png")
        if os.path.exists(f):
            t, a, sz, top = _tira([f], [_pe(Image.open(f).convert("RGBA"))])
            t.save(os.path.join(BON, pasta, "parado_%s.png" % d))
            par[d] = {"img": "%s/parado_%s.png" % (pasta, d), "n": 1, "quadro": sz, "ancora": a, "topo": top}
    if par:
        info["anims"]["parado"] = par
    for anim in anims:
        dd = {}
        for d in DIRS:
            fr = sorted(glob.glob(os.path.join(AQUI, pasta, anim, d, "*.png")), key=lambda f: int(os.path.basename(f)[:-4]) if os.path.basename(f)[:-4].isdigit() else 0)
            fr = [f for f in fr if os.path.basename(f)[:-4].isdigit()]
            if not fr:
                continue
            t, a, sz, top = _tira(fr, _ancoras(pasta, anim, d, fr))
            t.save(os.path.join(BON, pasta, "%s_%s.png" % (anim, d)))
            dd[d] = {"img": "%s/%s_%s.png" % (pasta, anim, d), "n": len(fr), "quadro": sz, "ancora": a, "topo": top}
        if dd:
            info["anims"][anim] = dd
    return info


def bonecos():
    os.makedirs(BON, exist_ok=True)
    out = {"_obs": "Prompt 29 parte 3 (integra.py bonecos): pasta -> animação -> direção (SE/NE/SO/NO) -> tira "
                   "(n quadros de 'quadro' px), âncora (pé) comum na tira, topo da cabeça por quadro (relativo à âncora).",
           "funcoes": {k: list(v) for k, v in FUNCOES.items()}, "pastas": {}}
    for f, (h, m, trab) in FUNCOES.items():
        for pasta in (h, m):
            anims = COMUNS + ([trab] if trab else []) + EXTRA.get(pasta, [])
            out["pastas"][pasta] = _exporta_boneco(pasta, anims)
            print("%-14s %s" % (pasta, sorted(out["pastas"][pasta]["anims"])))
            cas = "casaco_" + pasta
            if os.path.isdir(os.path.join(AQUI, cas)):
                out["pastas"][cas] = _exporta_boneco(cas, ["caminhada"] + ([trab] if trab else [])
                                                     + [x for x in EXTRA.get(pasta, []) if x in ("carvoejar", "curtir")])  # Bloco 107
    for k in ("gas", "calor", "radiacao"):
        for g in ("m", "f"):
            p = "traje_%s_%s" % (k, g)
            if os.path.isdir(os.path.join(AQUI, p)):
                out["pastas"][p] = _exporta_boneco(p, ["caminhada", "minerar"])
    # os 3 tons de pele de cada tira (o jogo só escolhe o arquivo do tom)
    jobs = []
    for pasta, info in out["pastas"].items():
        for an, dd in info["anims"].items():
            for d, i in dd.items():
                jobs.append((os.path.join(BON, i["img"]), i["n"], i["quadro"][0]))
    with Pool() as pool:
        for _ in pool.imap_unordered(_tons_job, jobs, chunksize=8):
            pass
    out["tons"] = list(_tp.RAMPAS.keys())
    # Bloco 50: a paleta vai junto pro jogo (o executável não leva a pasta do protótipo)
    shutil.copyfile(os.path.join(AQUI, "paletas_pele.json"), os.path.join(BON, "..", "paletas_pele.json"))
    print("tons de pele:", len(jobs), "tiras x", len(_tp.RAMPAS))
    # robô (Prompt 5): animações de 4 direções + os estados parados no chão (mesmo quadro e âncora)
    out["pastas"]["robo"] = _exporta_boneco("robo", ["caminhada", "atacar", "dano", "desligar"])
    rc = json.load(open(os.path.join(AQUI, "robo", "contrato.json"), encoding="utf-8"))["estados_parados"]
    out["robo_parado"] = {"ancora": rc["ancora_no_quadro"], "estados": {}}
    for st in ("achado", "arrastado", "conserto_1", "conserto_2", "conserto_3"):
        shutil.copyfile(os.path.join(AQUI, "robo", "estados", st + ".png"), os.path.join(BON, "robo", "parado_%s.png" % st))
        out["robo_parado"]["estados"][st] = "robo/parado_%s.png" % st
    print("robo", sorted(out["pastas"]["robo"]["anims"]))
    # saco nas costas (carregar = caminhada + saco por cima) e as ferramentas nas costas
    shutil.copyfile(os.path.join(AQUI, "itens", "saco_costas.png"), os.path.join(BON, "saco_costas.png"))
    out["saco"] = dict(json.load(open(os.path.join(AQUI, "itens", "saco_costas.json"), encoding="utf-8")), img="saco_costas.png")
    out["ferramentas"] = {}
    for it in ("picareta", "picareta_aco", "machado", "martelo", "porrete", "lanca", "lanca_prata", "besta", "arco"):
        f = os.path.join(AQUI, "itens", it + ".png")
        if os.path.exists(f):
            im = Image.open(f).convert("RGBA")
            im = im.crop(im.getbbox())
            im.save(os.path.join(BON, "item_%s.png" % it))
            out["ferramentas"][it] = "item_%s.png" % it
    criaturas(out)
    pes_no_chao(out)
    json.dump(out, open(os.path.join(BON, "bonecos.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("->", os.path.join(BON, "bonecos.json"), len(out["pastas"]), "pastas")


# ------------------------------------------------------------ criaturas (Prompt 17)
# pasta em criaturas/ -> rótulo do PixelLab de cada direção desenhada (a base não era de frente,
# então as rotações saíram giradas; criaturas/base/chars.json tem os ids)
CRIATURAS = {"lumivoro": {"SE": "east", "NE": "north-east"}, "lumivoro_bruto": {"SE": "south-east", "NE": "north-east"},
             "ferrugento": {"SE": "east", "NE": "north-east"}, "ferrugento_carregador": {"SE": "south-east", "NE": "east"},
             "lumivoro_matriarca": {"SE": "south-east", "NE": "north-east"},  # Bloco 62: o chefe
             "gosma": {"SE": "south-east", "NE": "north-east"},  # Bloco 70: criaturas do fundo (criaturas/fundo.py)
             "magmante": {"SE": "south-east", "NE": "north-east"}}
ANIMS_CRIATURA = ["caminhada", "atacar", "dano", "morrer"]


def _olho_vermelho(im):
    """Ferrugento: o PixelLab trocou o olho vermelho por verde-água em alguns quadros; volta pro
    vermelho mantendo o brilho de cada pixel (só os pixels saturados de tom 150-200 graus)."""
    a = np.array(im).astype(np.float32)
    h, l, sat = _hls(a[..., :3])
    m = (a[..., 3] > 40) & (h > 150 / 360.0) & (h < 200 / 360.0) & (sat > 0.35) & (l > 0.25)
    if m.any():
        v = a[..., :3].max(-1)
        a[..., 0] = np.where(m, v, a[..., 0])
        a[..., 1] = np.where(m, v * 0.18, a[..., 1])
        a[..., 2] = np.where(m, v * 0.15, a[..., 2])
    return Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA")


def _gosma_turva(im):
    """Bloco 70: a Gosma veio neon (brilho 0,56; as outras criaturas 0,17-0,21). Curva no valor (2,2:
    escurece os meios e guarda os realces das bolhas), x0,85 e um pouco menos de saturação -> ~0,31,
    ácido turvo que ainda é o acento do nível."""
    a = np.array(im).astype(np.float32) / 255.0
    rgb = a[..., :3]
    m = a[..., 3] > 0.15
    v = rgb.max(-1)
    k = np.where(v > 0, (v ** 2.2) * 0.85 / np.maximum(v, 1e-6), 0.0)
    out = rgb * k[..., None]
    cinza = out.max(-1, keepdims=True)
    out = cinza + (out - cinza) * 0.8
    a[..., :3] = np.where(m[..., None], out, rgb)
    return Image.fromarray((a * 255.0).clip(0, 255).astype(np.uint8), "RGBA")


CORRIGE = {"ferrugento": _olho_vermelho, "gosma": _gosma_turva}


def _criatura_tira(frames, mirror=False, fix=None):
    """Quadros de uma direção numa tira com UMA âncora (a criatura não sai do lugar no quadro do
    PixelLab): x = mediana do centro, y = o pé mais baixo. SO/NO = espelho de SE/NE."""
    ims = [Image.open(f).convert("RGBA") for f in frames]
    if fix:
        ims = [fix(i) for i in ims]
    if mirror:
        ims = [ImageOps.mirror(i) for i in ims]
    bbs = [i.getbbox() or (0, 0, i.width, i.height) for i in ims]
    ax = float(np.median([(b[0] + b[2]) / 2.0 for b in bbs]))
    ay = float(max(b[3] for b in bbs))
    w, h = ims[0].size
    tira = Image.new("RGBA", (w * len(ims), h))
    topos = []
    for k, (im, b) in enumerate(zip(ims, bbs)):
        tira.alpha_composite(im, (k * w, 0))
        topos.append([round((b[0] + b[2]) / 2.0 - ax, 1), round(b[1] - ay, 1)])
    return tira, [round(ax, 1), round(ay, 1)], [w, h], topos


def criaturas(out):
    """Os 4 invasores (Prompt 17) no bonecos.json: pasta criatura_<nome>, parado + 4 animações,
    SE/NE desenhadas e SO/NO espelhadas; e a carga do Ferrugento que roubou."""
    for nome, mapa in CRIATURAS.items():
        src = os.path.join(AQUI, "criaturas", nome)
        pasta = "criatura_" + nome
        os.makedirs(os.path.join(BON, pasta), exist_ok=True)
        info = {"anims": {}}
        lista = {"parado": {d: [os.path.join(src, "rotacoes", mapa[d] + ".png")] for d in ("SE", "NE")}}
        for an in ANIMS_CRIATURA:
            dd = {}
            for d in ("SE", "NE"):
                fr = sorted(glob.glob(os.path.join(src, an, d, "*.png")), key=lambda f: int(os.path.basename(f)[:-4]))
                if fr:
                    dd[d] = fr
            if dd:
                lista[an] = dd
        for an, dd in lista.items():
            info["anims"][an] = {}
            for d, fr in dd.items():
                for dest, mir in ((d, False), ({"SE": "SO", "NE": "NO"}[d], True)):
                    t, a, sz, top = _criatura_tira(fr, mir, CORRIGE.get(nome))
                    t.save(os.path.join(BON, pasta, "%s_%s.png" % (an, dest)))
                    info["anims"][an][dest] = {"img": "%s/%s_%s.png" % (pasta, an, dest), "n": len(fr), "quadro": sz,
                                               "ancora": a, "topo": top}
        out["pastas"][pasta] = info
        print("%-30s %s" % (pasta, sorted(info["anims"])))
    cf = os.path.join(AQUI, "criaturas", "carga_ferrugento.json")
    if os.path.exists(cf):
        c = json.load(open(cf, encoding="utf-8"))
        shutil.copyfile(os.path.join(AQUI, "criaturas", c["img"]), os.path.join(BON, "criatura_ferrugento", "carga.png"))
        out["carga_ferrugento"] = dict(c, img="criatura_ferrugento/carga.png")


def so_criaturas():
    f = os.path.join(BON, "bonecos.json")
    out = json.load(open(f, encoding="utf-8"))
    criaturas(out)
    pes_no_chao(out)
    json.dump(out, open(f, "w", encoding="utf-8"), indent=1, ensure_ascii=False)


# ------------------------------------------------------------ só as caminhadas (Bloco 76)
def so_caminhadas(pastas):
    """Refaz só a caminhada (e a caminhada com picareta) das pastas — tira, tons de pele, pé no chão — no
    bonecos.json que já existe (sem regravar os outros PNGs). Pra a caminhada de 8 quadros (caminhadas8.py)."""
    f = os.path.join(BON, "bonecos.json")
    out = json.load(open(f, encoding="utf-8"))
    jobs = []
    for pasta in pastas:
        if pasta not in out["pastas"]:
            print("  %s: não está no bonecos.json (pula)" % pasta)
            continue
        for anim in ("caminhada", "com_picareta"):
            if not os.path.isdir(os.path.join(AQUI, pasta, anim)):
                continue
            dd = {}
            for d in DIRS:
                fr = sorted(glob.glob(os.path.join(AQUI, pasta, anim, d, "*.png")), key=lambda x: int(os.path.basename(x)[:-4]) if os.path.basename(x)[:-4].isdigit() else 0)
                fr = [x for x in fr if os.path.basename(x)[:-4].isdigit()]
                if not fr:
                    continue
                t, a, sz, top = _tira(fr, _ancoras(pasta, anim, d, fr))
                t.save(os.path.join(BON, pasta, "%s_%s.png" % (anim, d)))
                dd[d] = {"img": "%s/%s_%s.png" % (pasta, anim, d), "n": len(fr), "quadro": sz, "ancora": a, "topo": top}
                jobs.append((os.path.join(BON, dd[d]["img"]), len(fr), sz[0]))
            if dd:
                out["pastas"][pasta]["anims"][anim] = dd
                print("  %-26s %s: %s quadros" % (pasta, anim, sorted({v["n"] for v in dd.values()})))
    with Pool() as pool:
        for _ in pool.imap_unordered(_tons_job, jobs, chunksize=4):
            pass
    pes_no_chao(out)
    json.dump(out, open(f, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("tiras refeitas:", len(jobs), "(+ 3 tons cada)")


# ------------------------------------------------------------ só algumas funções (Bloco 92)
def so_bonecos(funcoes):
    """Exporta só as pastas dessas funções (base, mulher e casaco) — tiras, tons de pele, pé no chão — no
    bonecos.json que já existe, sem regravar os PNGs do resto do elenco."""
    f = os.path.join(BON, "bonecos.json")
    out = json.load(open(f, encoding="utf-8"))
    out["funcoes"] = {k: list(v) for k, v in FUNCOES.items()}
    jobs = []
    feitas = set()
    for fn in funcoes:
        h, m, trab = FUNCOES[fn]
        for pasta in (h, m):
            if pasta in feitas:
                continue
            feitas.add(pasta)
            anims = COMUNS + ([trab] if trab else []) + EXTRA.get(pasta, [])
            novas = {pasta: anims}
            if os.path.isdir(os.path.join(AQUI, "casaco_" + pasta)):
                novas["casaco_" + pasta] = ["caminhada"] + ([trab] if trab else [])                     + [x for x in EXTRA.get(pasta, []) if x in ("carvoejar", "curtir")]  # Bloco 107
            for pz, an in novas.items():
                out["pastas"][pz] = _exporta_boneco(pz, an)
                print("%-18s %s" % (pz, sorted(out["pastas"][pz]["anims"])))
                for anim, dd in out["pastas"][pz]["anims"].items():
                    for d, i in dd.items():
                        jobs.append((os.path.join(BON, i["img"]), i["n"], i["quadro"][0]))
    with Pool() as pool:
        for _ in pool.imap_unordered(_tons_job, jobs, chunksize=4):
            pass
    pes_no_chao(out)
    json.dump(out, open(f, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("tiras:", len(jobs), "(+ 3 tons cada)")


# ------------------------------------------------------------ pé no chão (Bloco 73)
## Animações de andar: os quadros vieram do PixelLab cada um numa altura (na caminhada o pé ficava
## em média 6 px, até 13 no robô, acima da linha da âncora) e o boneco subia e descia como se
## flutuasse. A gosma pula de propósito: fica de fora.
ANDAR = ("caminhada", "com_picareta", "mancar_esq")
CABECA_FIXA = ("caminhada", "com_picareta")


def pes_no_chao(out):
    """Ajuste por quadro `aj` = [dx, dy] (px de arte, somado ao desenho) nas animações de andar: o pé
    mais baixo de cada quadro encosta na linha da âncora e, na caminhada de gente, a cabeça fica na
    mesma vertical em todos os quadros (sem o tranco pra frente e pra trás). O jogo
    (iso_bonecos.gd) desloca o quadro; os PNGs não mudam."""
    n_aj = 0
    for pasta, info in out["pastas"].items():
        pula = pasta.startswith("criatura_gosma")  # (a gosma pula de propósito: só o ciclo, sem ajuste)
        gente = not pasta.startswith("criatura") and pasta != "robo"
        for anim, dd in info["anims"].items():
            if anim not in ANDAR:
                continue
            for d, i in dd.items():
                i.pop("aj", None)
                if i["n"] < 2:
                    continue
                a = np.array(Image.open(os.path.join(BON, i["img"])).convert("RGBA"))[..., 3] > 40
                w = int(i["quadro"][0])
                ay = float(i["ancora"][1])
                baixo, cabeca = [], []
                for k in range(i["n"]):
                    q = a[:, k * w:(k + 1) * w]
                    ys, xs = np.nonzero(q)
                    linhas = np.nonzero(q.sum(1) >= 2)[0]
                    if len(ys) == 0 or len(linhas) == 0:
                        baixo.append(ay)
                        cabeca.append(None)
                        continue
                    baixo.append(float(linhas.max() + 1))  # a beira de baixo do pé mais baixo
                    cabeca.append(float(xs[ys <= ys.min() + 10].mean()))
                xs_ok = [c for c in cabeca if c is not None]
                meio = float(np.median(xs_ok)) if xs_ok else 0.0
                # Bloco 76: o ciclo (2 passos) em px de arte = ~2,2 x a maior abertura dos pés (o quanto o
                # corpo avança enquanto o pé fica plantado); o jogo troca de quadro pela distância andada
                abre = 0
                for k in range(i["n"]):
                    q = a[:, k * w:(k + 1) * w]
                    linhas = np.nonzero(q.sum(1) >= 2)[0]
                    if len(linhas) == 0:
                        continue
                    ys, xs = np.nonzero(q[linhas.max() - 3:linhas.max() + 1])
                    if len(xs):
                        abre = max(abre, int(xs.max() - xs.min()))
                i["ciclo"] = int(min(160, max(36, round(2.2 * abre))))
                aj = []
                for b, c in zip(baixo, cabeca):
                    dx = int(round(meio - c)) if gente and anim in CABECA_FIXA and c is not None else 0
                    aj.append([dx, int(round(ay - b))])
                if any(v != [0, 0] for v in aj) and not pula:
                    i["aj"] = aj
                    n_aj += 1
            # Bloco 76: o ciclo é o mesmo nas 4 direções (de lado as pernas se sobrepõem na tela e a
            # medida sai curta): fica o maior
            cs = [i["ciclo"] for i in dd.values() if "ciclo" in i]
            for i in dd.values():
                if cs:
                    i["ciclo"] = max(cs)
    print("pé no chão:", n_aj, "tiras ajustadas")


# ------------------------------------------------------------ natureza e objetos (Prompt 29, parte 4)
PROPS_DEST = os.path.normpath(os.path.join(AQUI, "../../../assets/game/iso/props"))
# nome no jogo -> arquivo da arte (Prompts 7, 8, 9, 14, 15)
PROPS = {}
for esp, n in (("pinheiro", 2), ("carvalho", 3), ("betula", 2)):
    for k in range(n):
        PROPS["arvore_%s_%d" % (esp, k)] = "vegetacao/final/arvore_%s_%d.png" % (esp, k)
    PROPS["toco_" + esp] = "vegetacao/final/toco_%s.png" % esp
    PROPS["muda_" + esp] = "vegetacao/final/muda_%s.png" % esp
PROPS["arvore_seca"] = "vegetacao/final/arvore_seca.png"
for st in ("pronto", "crescendo", "colhido"):
    PROPS["horta_" + st] = "vegetacao/final/horta_%s.png" % st
for st in ("fora", "orelhas", "vazia"):
    PROPS["toca_coelho_" + st] = "animais/final/toca_coelho_%s.png" % st
PROPS["toca_javali"] = "animais/final/toca_javali.png"
for m in ("ferro", "cobre", "carvao", "prata", "solarita"):
    for st in ("cheia", "meia", "quase"):
        PROPS["jazida_%s_%s" % (m, st)] = "jazidas/final/jazida_%s_%s.png" % (m, st)
PROPS["jazida_esgotada"] = "jazidas/final/jazida_esgotada.png"
for k in range(6):
    PROPS["rocha_musgo_%d" % k] = "jazidas/final/rocha_musgo_%d.png" % k
for k in range(3):
    PROPS["rocha_mina_%d" % k] = "jazidas/final/rocha_mina_%d.png" % k
for cor in ("violeta", "ciano", "lima", "brasa"):
    for k in range(2):
        PROPS["cristal_%s_%d" % (cor, k)] = "jazidas/final/cristal_%s_%d.png" % (cor, k)
for a in ("bobina", "cristal", "peca", "painel_solar"):
    PROPS["achado_" + a] = "jazidas/final/achado_%s.png" % a
PROPS["entulho_medio"] = "jazidas/final/entulho_medio.png"
PROPS["placa_perigo"] = "objetos/final/placa_perigo.png"
PROPS["tocha_apagada"] = "objetos/final/tocha_apagada.png"
for k in range(4):
    PROPS["tocha_chao_f%d" % k] = "objetos/final/tocha_chao_f%d.png" % k
PROPS["escora"] = "relevo/final/mina/escora.png"
# Prompt 30: a decoração da montagem aprovada (mapa/monta.py) que faltava no jogo
for base, n in (("capim", 4), ("flores", 4), ("arbusto", 3), ("samambaia", 2), ("cogumelos", 3), ("tronco_musgo", 3), ("moita", 3)):
    for k in range(n):
        PROPS["%s_%d" % (base, k)] = "vegetacao/final/%s_%d.png" % (base, k)
PROPS["horta_espantalho"] = "vegetacao/final/horta_espantalho.png"
for nome in ("guindaste_pedreira", "vagonete_cheio_SE", "caixotes_2", "barris_2", "sacos", "pedra_g", "tijolo_m",
             "poco", "banco", "placa_caveira", "caixote"):
    PROPS[nome] = "objetos/final/%s.png" % nome

# Bloco 70: jazidas de cristal verde (S2) e rubro (S3) e o ventilador do nível 2 (fundo70/)
for m in ("cristal_verde", "cristal_rubro"):
    for st in ("cheia", "meia", "quase"):
        PROPS["jazida_%s_%s" % (m, st)] = "fundo70/jazida_%s_%s.png" % (m, st)
PROPS["ventilador"] = "fundo70/ventilador.png"
# Bloco 71: gema azul (S5), casinhas de pedra da vila antiga do lago (fundo71/)
for st in ("cheia", "meia", "quase"):
    PROPS["jazida_gema_azul_%s" % st] = "fundo70/jazida_gema_azul_%s.png" % st
for k in range(2):
    PROPS["casa_pedra_%d" % k] = "fundo71/casa_pedra_%d.png" % k
# Bloco 72: o resto dos objetos do Prompt 14 (prontos desde então, nunca registrados) — densidade de
# decoração nos andares e na superfície. Tochas, fogueiras e lampiões ficam de fora (acesos sem luz).
for nome in ("aco_m", "aco_p", "andaime", "barril", "barril_vazando", "bigorna", "bloco_concreto", "braco_robo",
             "caixa_ferramentas", "caixas_metal", "caixote_palha", "cano", "carcaca_maquina", "carvao_m", "carvao_p",
             "chapa_enterrada", "corda", "corrente", "corrente_enferrujada", "costelas", "escada_mao", "ferramentas_caixote",
             "ferramentas_encostadas", "furadeira_velha", "mesa", "ossos_cranio", "painel_listrado", "palete", "pedra_m",
             "pedra_p", "placa_direcao", "placa_gas", "placa_raio", "pneus", "porta_carro", "poste", "poste_caido",
             "poste_cruzado", "roda_carroca", "saco", "sucata", "tabuas", "tambor_oleo", "tijolo_g", "tijolo_p",
             "trilho_quebrado", "vagonete_cheio_SO", "vagonete_vazio_SE", "vagonete_vazio_SO", "vagonete_velho", "varal"):
    PROPS[nome] = "objetos/final/%s.png" % nome
# Itens de arte do documento de melhorias (decoração): a vila antiga do leste, passarelas, ponte de
# corda e as peças da rampa em espiral (fundo71/itens.py)
for nome, n in (("igreja", 1), ("torre", 1), ("enxaimel", 3), ("passarela", 2), ("ponte", 1), ("rampa", 3)):
    for k in range(n):
        PROPS["%s_%d" % (nome, k)] = "fundo71/%s_%d.png" % (nome, k)

# Prompts 14 e 18: cova (cemitério), explosivos (pesquisa), antena do satélite, cesto e placa de greve
for nome in ("cova", "explosivos", "antena", "cesto", "placa_greve"):
    PROPS[nome] = "efeitos/bases/%s.png" % nome
# Bloco 76: a boca da escada em espiral na superfície (fundo76/espiral.py)
PROPS["boca_espiral"] = "fundo76/boca_espiral.png"
# Bloco 93: o cemitério MODULAR (predios93.py): cerca, poste e portão em volta do retângulo do jogador; cruzes
# e lápides que aparecem a cada enterro; o corpo na mortalha
# (cem_cerca = o trecho em "\", ao longo do x do mundo; cem_cerca_y = o espelho, em "/", ao longo do y)
for jogo, arq in (("cem_cerca", "cerca_cem"), ("cem_cerca_y", "cerca_cem_y"), ("cem_poste", "poste_cem"),
                  ("cem_portao", "portao_cem"), ("corpo", "corpo")):
    PROPS[jogo] = "cemiterio/%s.png" % arq
for k in range(3):
    PROPS["cem_cruz_%d" % k] = "cemiterio/cruz_%d.png" % k
    PROPS["cem_lapide_%d" % k] = "cemiterio/lapide_%d.png" % k
# Bloco 92: a decoração do jogador que faltava (predios92.py; banco, mesa e tocha já existiam)
for nome in ("lampiao", "cerca", "canteiro_flores", "bandeira"):
    PROPS["decor_" + nome] = "decor92/%s.png" % nome
# Bloco 78: os marcos de cada andar (fundo78/marcos.py)
for nome in ("fossil_gigante", "bica_vapor", "lampiao_cristal", "cabana_mina", "boca_tunel"):
    PROPS[nome] = "fundo78/%s.png" % nome


## Bloco 93: peças em diagonal emendadas pelo jogo (a cerca do cemitério): âncora no meio da linha do pé.
ANCORA_NA_LINHA = ("cem_cerca", "cem_cerca_y", "cem_portao")


def props(so=None):
    """Cada peça: recortada no desenho, âncora = (meio, base - 3) como o `solto` do mapa aprovado
    (mapa/monta.py), caixa encaixada com uma guia pequena (pegada ~1/3 da largura: tronco, pé).
    `so` (Bloco 76): só essas peças, mescladas no props.json que já existe (sem regravar as outras)."""
    os.makedirs(PROPS_DEST, exist_ok=True)
    out = {"_obs": "Prompt 29 parte 4 (integra.py props): peça -> img, âncora (pé), caixa (px de arte)", "props": {}}
    if so:
        out = json.load(open(os.path.join(PROPS_DEST, "props.json"), encoding="utf-8"))
    pend = []
    for nome, arq in PROPS.items():
        if so and nome not in so:
            continue
        src = os.path.join(AQUI, arq)
        if not os.path.exists(src):
            print("  falta:", nome, arq)
            continue
        im = Image.open(src).convert("RGBA")
        im = im.crop(im.getbbox())
        dst = os.path.join(PROPS_DEST, nome + ".png")
        im.save(dst)
        if nome in AJUSTA_BRILHO:
            print("  brilho %s: %.3f -> %.3f" % ((nome,) + ajusta_brilho(dst)))
        anc = (im.width / 2.0, im.height - 3.0)
        if nome in ANCORA_NA_LINHA:  # Bloco 93: peça comprida em diagonal (cerca): o nó fica no meio da linha do pé
            al = np.array(im)[..., 3] > 40
            pes = [int(np.nonzero(al[:, x])[0].max()) for x in range(im.width) if al[:, x].any()]
            anc = (im.width / 2.0, (pes[0] + pes[-1]) / 2.0 + 1.0)
        g = max(8.0, min(64.0, im.width * 0.35))
        out["props"][nome] = {"img": nome + ".png", "ancora": list(anc)}
        pend.append((nome, (dst, anc[0], anc[1], g, g * 0.8, float(im.height))))
    with Pool() as pool:
        res = dict(pool.map(encaixa, [p[1] for p in pend]))
    for nome, args in pend:
        r = res[args[0]]
        if r:
            out["props"][nome].update(r)
        else:
            print("  SEM CAIXA:", nome)
    json.dump(out, open(os.path.join(PROPS_DEST, "props.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("->", len(out["props"]), "peças")


# ------------------------------------------------------------ efeitos (Prompt 18)
FX_DEST = os.path.normpath(os.path.join(AQUI, "../../../assets/game/iso/fx"))
# efeito animado (efeitos/anim/<nome>/c01..c08, animate_image; c00 = o desenho de entrada)
FX_ANIM = ["chama_p", "chama_g", "barril_fogo", "bandeirinhas", "cachoeira"]  # (Bloco 71: a cachoeira do S4, por script)


def fx():
    """Texturas de partícula (efeitos/particulas.py) + tiras dos efeitos animados, recortadas na
    caixa que cabe todos os quadros; âncora = meio da base (o fogo nasce do chão)."""
    import runpy
    runpy.run_path(os.path.join(AQUI, "efeitos", "particulas.py"))
    out = {"_obs": "Prompt 18 (integra.py fx): efeito -> tira (n quadros de 'quadro' px), âncora (base)", "anim": {}}
    for nome in FX_ANIM:
        fr = sorted(glob.glob(os.path.join(AQUI, "efeitos", "anim", nome, "c*.png")))[1:]
        ims = [Image.open(f).convert("RGBA") for f in fr]
        bb = [i.getbbox() for i in ims if i.getbbox()]
        x0, y0 = min(b[0] for b in bb), min(b[1] for b in bb)
        x1, y1 = max(b[2] for b in bb), max(b[3] for b in bb)
        w, h = x1 - x0, y1 - y0
        tira = Image.new("RGBA", (w * len(ims), h))
        for k, im in enumerate(ims):
            tira.alpha_composite(im.crop((x0, y0, x1, y1)), (k * w, 0))
        tira.save(os.path.join(FX_DEST, nome + ".png"))
        out["anim"][nome] = {"img": nome + ".png", "n": len(ims), "quadro": [w, h], "ancora": [w / 2.0, h - 1.0]}
        # caixa (ordem de desenho/clique): a mesma regra das peças, na soma dos quadros
        uni = Image.new("RGBA", (w, h))
        for im in ims:
            uni = Image.alpha_composite(uni, im.crop((x0, y0, x1, y1)))
        tmp = os.path.join(FX_DEST, "_uniao.png")
        uni.save(tmp)
        g = max(8.0, min(64.0, w * 0.35))
        r = encaixa((tmp, w / 2.0, h - 1.0, g, g * 0.8, float(h)))[1]
        os.remove(tmp)
        if r:
            out["anim"][nome].update(r)
        print("  %-14s %d quadros de %dx%d" % (nome, len(ims), w, h))
    json.dump(out, open(os.path.join(FX_DEST, "fx.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)


# ------------------------------------------------------------ luz e noite (Prompt 19)
LUZ_DEST = os.path.normpath(os.path.join(AQUI, "../../../assets/game/iso/luz"))
# textura de cada tipo de luz: (raio relativo do núcleo, nº de faixas, irregular?) — branca em
# faixas (combina com pixel art); a COR vem do código (iso_luz.gd)
TIPOS_LUZ = {"tocha": (0.18, 5, True), "lampiao": (0.22, 5, False), "fogueira": (0.15, 6, True),
             "forja": (0.20, 5, True), "lanterna": (0.30, 4, False), "reator": (0.25, 5, False),
             "cristal": (0.20, 5, False), "lava": (0.10, 6, True), "janela": (0.30, 4, False),
             "cabine": (0.30, 4, False), "giroflex": (0.35, 3, False)}


def texturas_de_luz(lado=128):
    """Uma textura por tipo: disco claro no meio e o resto caindo em FAIXAS (sem degradê liso);
    as de fogo têm a borda irregular (a chama não é um círculo)."""
    os.makedirs(LUZ_DEST, exist_ok=True)
    yy, xx = np.mgrid[0:lado, 0:lado]
    c = (lado - 1) / 2.0
    ang = np.arctan2(yy - c, xx - c)
    for nome, (nucleo, faixas, irregular) in TIPOS_LUZ.items():
        r = np.hypot(xx - c, yy - c) / c
        if irregular:  # borda que oscila com o ângulo (estável: a mesma semente por tipo)
            rng = np.random.RandomState(sum(map(ord, nome)))
            fases = rng.uniform(0, 2 * np.pi, 3)
            r = r * (1.0 + 0.06 * np.sin(5 * ang + fases[0]) + 0.04 * np.sin(9 * ang + fases[1]) + 0.03 * np.sin(13 * ang + fases[2]))
        t = np.clip((r - nucleo) / max(1.0 - nucleo, 0.01), 0.0, 1.0)
        a = (1.0 - t) ** 1.6
        a = np.ceil(a * faixas) / faixas  # faixas
        a[r >= 1.0] = 0.0
        img = np.zeros((lado, lado, 4), np.uint8)
        img[..., :3] = 255
        img[..., 3] = (a * 255).astype(np.uint8)
        Image.fromarray(img, "RGBA").save(os.path.join(LUZ_DEST, nome + ".png"))
    print("texturas de luz:", len(TIPOS_LUZ))


def _janela_acesa(a, mask):
    """O vidro aceso: âmbar quente, mais claro onde o vidro já era mais claro (mantém o desenho)."""
    out = np.zeros_like(a)
    v = a[..., :3].max(-1) / 255.0
    rampa = np.array([[150, 82, 30], [214, 134, 52], [246, 186, 92], [255, 222, 150]], float)
    vv = v[mask]
    t = (vv - vv.min()) / max(vv.max() - vv.min(), 1e-6) if vv.size else vv
    i = np.clip(t * (len(rampa) - 1), 0, len(rampa) - 1)
    lo = np.floor(i).astype(int); hi = np.minimum(lo + 1, len(rampa) - 1); f = (i - lo)[:, None]
    out[mask, :3] = (rampa[lo] * (1 - f) + rampa[hi] * f).astype(np.uint8)
    out[mask, 3] = 255
    return out


def luzes_dos_predios(saida):
    """Prompt 19: pra cada estado anotado em luz/luzes.json, a máscara de janelas acesas
    (<estado>__janelas.png) e os pontos de luz (relativos à âncora, px de arte) no predios.json."""
    sys.path.insert(0, os.path.join(AQUI, "luz"))
    from janelas_util import vidro_ambar
    anot = json.load(open(os.path.join(AQUI, "luz", "luzes.json"), encoding="utf-8"))
    n = 0
    for chave, cfg in anot.items():
        if chave.startswith("_"):
            continue
        nome, est = chave.split("/")
        d = saida["predios"].get(nome, {}).get("estados", {}).get(est)
        if d is None:
            continue
        a = np.array(Image.open(os.path.join(DEST, d["img"])).convert("RGBA"))
        mask = np.zeros(a.shape[:2], bool)
        if cfg.get("ambar"):
            mask |= vidro_ambar(a)
        v = a[..., :3].max(-1).astype(float)
        for x0, y0, x1, y1 in cfg.get("janelas", []):
            sub = (slice(y0, y1), slice(x0, x1))
            vis = a[sub][..., 3] > 40
            if vis.any():
                med = np.median(v[sub][vis])
                mask[sub] |= vis & (v[sub] <= med)  # os vidros (mais escuros que a moldura)
        ax, ay = d["ancora"]
        d.pop("janelas", None); d.pop("luzes", None)
        if mask.any():
            arq = d["img"][:-4] + "__janelas.png"
            Image.fromarray(_janela_acesa(a, mask), "RGBA").save(os.path.join(DEST, arq))
            d["janelas"] = arq
        pts = cfg.get("pontos")
        if not pts and mask.any():
            ys, xs = np.nonzero(mask)
            pts = [{"tipo": "janela", "xy": [float(xs.mean()), float(ys.mean())]}]
        if pts:
            d["luzes"] = [{"tipo": p["tipo"], "pos": [round(p["xy"][0] - ax, 1), round(p["xy"][1] - ay, 1)]} for p in pts]
        n += 1
        print("  luz %-22s janelas %4d px, pontos %s" % (chave, int(mask.sum()), [p["tipo"] for p in (pts or [])]))
    print("luzes anotadas:", n)


def luz():
    """Só a parte de luz, por cima do predios.json que já existe."""
    texturas_de_luz()
    f = os.path.join(DEST, "predios.json")
    saida = json.load(open(f, encoding="utf-8"))
    luzes_dos_predios(saida)
    json.dump(saida, open(f, "w", encoding="utf-8"), indent=1, ensure_ascii=False)


def contorno():
    """Prompt 30: o contorno de 1 px nos desenhos que vieram sem ele (tools/contorno.py)."""
    sys.path.insert(0, os.path.normpath(os.path.join(AQUI, "../../../../tools")))
    import contorno as _c
    print("contorno: %d px" % _c.aplica())


if __name__ == "__main__":
    if sys.argv[1:2] == ["predios"]:
        predios(sys.argv[2:] or None)
        contorno()
    elif sys.argv[1:2] == ["bonecos"] and len(sys.argv) > 2:  # Bloco 92: só essas funções
        so_bonecos(sys.argv[2:])
    elif sys.argv[1:2] == ["bonecos"]:
        bonecos()
        contorno()
    elif sys.argv[1:2] == ["props"] and len(sys.argv) > 2:  # Bloco 76: só algumas peças
        props(sys.argv[2:])
    elif sys.argv[1:2] == ["props"]:
        props()
        contorno()
    elif sys.argv[1:2] == ["fx"]:  # Prompt 18: partículas e efeitos animados
        fx()
    elif sys.argv[1:2] == ["criaturas"]:  # Prompt 17: só os invasores (sem refazer os bonecos)
        so_criaturas()
    elif sys.argv[1:2] == ["luz"]:  # Prompt 19: texturas de luz + janelas acesas + pontos de luz
        luz()
    elif sys.argv[1:2] == ["caminhadas"]:  # Bloco 76: só as caminhadas (8 quadros) dessas pastas
        so_caminhadas(sys.argv[2:])
    elif sys.argv[1:2] == ["pes"]:  # Bloco 73: só o pé no chão das animações de andar (bonecos.json)
        f = os.path.join(BON, "bonecos.json")
        out = json.load(open(f, encoding="utf-8"))
        pes_no_chao(out)
        json.dump(out, open(f, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    else:
        print(__doc__)
