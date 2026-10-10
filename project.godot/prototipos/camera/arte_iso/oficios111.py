"""Bloco 111: as CRIANÇAS (menino e menina) com a receita do elenco (a mesma do oficios92.py — este script só acrescenta os
dois e reaproveita as funções de lá, como o oficios107.py). Diferença: são CRIANÇAS, com ~2/3 da altura do adulto de
referência e proporção de criança (cabeça maior, pernas mais curtas), no mesmo quadro 48x84 (pé no mesmo chão), e no lugar
do trabalho a animação BRINCAR (o parque e a praça). O Marco liberou fazer o lote completo sem parar no piloto (Bloco 111).

  python oficios111.py candidatos crianca_m crianca_f   -> <pasta>/candidatos.png (16 candidatos, create_image_pro 48x84)
  python oficios111.py cria crianca_m <idx>             -> o personagem v3 ("high top-down") do candidato idx REDUZIDO a 2/3
  python oficios111.py anima crianca_m crianca_f        -> caminhada8 + comuns (comer, ferido, deitar, mancar) + brincar
  python oficios111.py baixa crianca_m crianca_f        -> rotações, caminhada ajustada e animações
  python oficios111.py retrato crianca_m crianca_f      -> retratos/base/<nome>.png (as 5 expressões: retratos.py)
"""
import os, sys
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import oficios92 as o  # noqa: E402

BRINCAR = ("playing loop: {he} hops and skips happily in place, swinging {his} arms, a small jump and land, turning a little "
           "and hopping again, like a child playing tag in a village square; feet return to the same spot, same body and outfit. "
           "Only the character: no toys, no ball, no ground drawn, no motion trails, no white arcs, no effects.")
NOVOS = {
    "crianca_m": ("h", "BOY CHILD of about 8 years old for the same isometric mining colony game: a CHILD, clearly much "
                       "smaller than an adult — about two thirds of the adult's height, child proportions with a bigger head, "
                       "shorter arms and legs and a slim body. Messy short brown hair under a too-big faded wool cap, a "
                       "patched oversized dull brown sweater with rolled sleeves, short dark trousers held by suspenders, "
                       "mended knee socks and small scuffed boots, a smudge of soot on one cheek, curious bright eyes. He is "
                       "NOT a miner or worker: NO helmet, NO headlamp, NO tools, NO apron, NO beard.",
                  "faded mustard yellow",
                  ("brincar", BRINCAR)),
    "crianca_f": ("m", "GIRL CHILD of about 8 years old for the same isometric mining colony game: a CHILD, clearly much "
                       "smaller than an adult — about two thirds of the adult's height, child proportions with a bigger head, "
                       "shorter arms and legs and a slim body. Two short braids tied with bits of string, a patched faded "
                       "blue-grey dress over a long-sleeved shirt, a small knitted shawl, mended stockings and small scuffed "
                       "boots, a smudge of soot on the nose, a cheerful face. She is NOT a miner or worker: NO helmet, NO "
                       "headlamp, NO tools, NO apron.",
                  "faded mustard yellow",
                  ("brincar", BRINCAR)),
}
# a 1ª leva trouxe vapor saindo da tigela (comer), arcos brancos e uma nuvem de poeira (ferido): descrições mais literais
o.REFAZ["comer"] = ("eating standing up: {he} holds a small wooden bowl in {his} left hand at chest height and brings a spoon from "
                    "the bowl to {his} mouth with {his} right hand, chews, repeats; keeps facing the same direction, feet planted, "
                    "same body and outfit. Only the character, the bowl and the spoon: NO steam, NO smoke, NO vapor, NO table, no "
                    "ground, no motion trails, no white arcs, no effects.")
o.REFAZ["ferido"] = ("badly injured: {he} slowly sits down on the ground and stays sitting, one leg stretched out in a wooden splint "
                     "wrapped with white bandages, leaning back on one hand, breathing with small chest movements; keeps facing the "
                     "same direction, same body and outfit. Only the character with the splint: NO dust, NO smoke, NO cloud, NO white "
                     "arcs, NO lines, NO circles, no blood, no ground drawn, no motion trails, no effects.")
o.OFICIOS.clear()
o.OFICIOS.update(NOVOS)
# a altura: criança (a régua continua sendo o minerador/a médica, mas ela é ~2/3 dele)
o.FIM = ("Draw a CHILD about two thirds of the height of the reference %s (the adult is only a size reference: the child is "
         "much shorter), with the feet on the ground diamond of the layout guide, figure inside the lower part of its box. "
         "Full body, standing still, facing straight toward the viewer (south), arms relaxed. Do not draw the guide lines. ")
_trabalho92 = o._trabalho


def _trabalho(nome):
    an, desc = _trabalho92(nome)
    return an, desc.format(**o._pron(nome))


o._trabalho = _trabalho


ESCALA = 0.68  # a criança = ~2/3 do adulto (o candidato veio do tamanho de um adulto no quadro 48x84)


def reduz(nome, idx):
    """o candidato idx reduzido a ESCALA da altura, no mesmo quadro 48x84 e com o pé na mesma linha de chão -> <nome>/ref_crianca.png"""
    import numpy as np
    from PIL import Image
    im = Image.open(os.path.join(AQUI, nome, "candidatos", "c%02d.png" % idx)).convert("RGBA")
    W, H = im.size
    bb = im.getbbox()
    fig = im.crop(bb)
    nw, nh = max(1, round(fig.width * ESCALA)), max(1, round(fig.height * ESCALA))
    r = fig.resize((nw, nh), Image.LANCZOS)
    a = np.array(r)
    a[..., 3] = np.where(a[..., 3] >= 110, 255, 0)
    r = Image.fromarray(a, "RGBA")
    out = Image.new("RGBA", (W, H))
    cx = (bb[0] + bb[2]) // 2
    out.alpha_composite(r, (cx - nw // 2, bb[3] - nh))  # o pé no mesmo chão do candidato
    dest = os.path.join(AQUI, nome, "ref_crianca.png")
    out.save(dest)
    print(nome, "figura", fig.size, "->", r.size, "no quadro", out.size)
    return dest


def cria_reduzida(nome, idx):
    """como o oficios92.cria, mas do candidato REDUZIDO (a criança do tamanho certo dentro do quadro do elenco)."""
    import base64, json, re
    d = o.elenco()
    if d.get(nome, {}).get("char"):
        print("já existe", d[nome]["char"])
        return
    ref = reduz(nome, idx)
    gen_, roupa, _a, _t = o.OFICIOS[nome]
    curto = roupa.split(": ", 1)[1] if ": " in roupa else roupa
    args = {"description": curto, "mode": "v3", "view": "high top-down", "name": "%s Deep Iron ISO" % nome.capitalize(),
            "reference_image_base64": base64.b64encode(open(ref, "rb").read()).decode()}
    t = o.gen._texto(o.pl.call("create_character", args))
    m = re.search(r"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})", t)
    print(t[:300])
    d[nome] = {"genero": gen_, "escolhido": idx, "reduzido": ESCALA, "char": m.group(1) if m else None, "estado": "gerando",
               "_obs": "Bloco 111 (criança: candidato reduzido a 2/3)"}
    o.salva_elenco(d)


if __name__ == "__main__":
    cmd, resto = sys.argv[1], sys.argv[2:]
    alvos = [a for a in resto if a in NOVOS]
    if cmd not in ("cria", "refaz") and not alvos:
        sys.exit("diga QUAIS: crianca_m / crianca_f")
    if cmd == "candidatos":
        o.candidatos(alvos)
    elif cmd == "cria":
        cria_reduzida(resto[0], int(resto[1]))
    elif cmd == "anima":
        o.anima(alvos)
    elif cmd == "baixa":
        o.baixa(alvos)
    elif cmd == "retrato":
        o.retrato(alvos)
    elif cmd == "refaz":
        o.refaz(resto)
