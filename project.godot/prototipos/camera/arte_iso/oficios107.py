"""Bloco 107: o AGRICULTOR e a AGRICULTORA com a receita do elenco (a mesma do oficios92.py — este script só acrescenta os
dois ofícios e reaproveita as funções de lá, como o oficios94/104/105.py). Em etapas (pedido do Marco): SÓ o agricultor
(homem) primeiro, completo, pra aprovação; a agricultora, as 3 estruturas, as animações de trabalho do lenhador e do caçador
(carvoaria e curtume) e os ícones só depois.

  python oficios107.py candidatos agricultor   -> <pasta>/candidatos.png (16 candidatos, create_image_pro 48x84)
  python oficios107.py cria agricultor <idx>   -> o personagem v3 ("high top-down") do candidato idx
  python oficios107.py anima agricultor        -> caminhada8 + comuns (comer, ferido, deitar, mancar) + colher
  python oficios107.py baixa agricultor        -> rotações, caminhada ajustada e animações
  python oficios107.py casaco agricultor       -> estado "Casaco inverno" + caminhada + colher
  python oficios107.py casaco_baixa agricultor
  python oficios107.py retrato agricultor      -> retratos/base/<nome>.png (as 5 expressões: retratos.py)
  python oficios107.py icones / icone_escolhe  (SÓ depois da aprovação)
"""
import os, sys
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import oficios92 as o  # noqa: E402

COLHER = ("harvesting work loop: {he} bends forward at the waist and picks vegetables and mushrooms from low plants on the "
          "ground in front of {him} with the right hand, drops them into a round wicker basket held on {his} left forearm, "
          "straightens up a little and bends again; feet planted, same body and outfit. Only the character and the basket: "
          "no plants, no soil, no garden, no ground drawn, no motion trails, no white arcs, no effects.")
NOVOS = {
    "agricultor": ("h", "Adult MAN FARMER (grows vegetables and cave mushrooms in the village garden and greenhouse) for the "
                        "same isometric mining colony game: a wide-brimmed faded straw hat with a torn brim, a worn "
                        "olive-green canvas apron with big pockets over a dull grey shirt with rolled-up sleeves, a small hand "
                        "trowel and a pruning knife in the belt, a round wicker basket hanging from the belt on one hip, "
                        "knee-high muddy rubber boots, dirt on the hands and forearms, patched dark trousers. Male face, "
                        "weathered, short grey-brown beard, kind tired eyes. He is NOT a miner: NO helmet, NO headlamp, NO "
                        "pickaxe, NO shovel, NO lantern; the wide straw hat and the olive-green apron are the key features.",
                   "olive green",
                   ("colher", COLHER)),
    "agricultora": ("m", "Adult WOMAN FARMER (grows vegetables and cave mushrooms in the village garden and greenhouse) for the "
                         "same isometric mining colony game, with subtle feminine curves (not exaggerated): a wide-brimmed "
                         "faded straw hat tied under the chin with a cloth, a long braid over one shoulder, a worn olive-green "
                         "canvas apron with big pockets over a dull grey shirt with rolled-up sleeves, a small hand trowel in "
                         "the belt, a round wicker basket hanging from the belt on one hip, knee-high muddy rubber boots, dirt "
                         "on the hands, patched dark trousers. Clearly a woman: female face, freckles, calm eyes. She is NOT a "
                         "miner: NO helmet, NO headlamp, NO pickaxe, NO shovel, NO lantern; the wide straw hat and the "
                         "olive-green apron are the key features.",
                    "olive green",
                    ("colher", COLHER)),
}
o.OFICIOS.clear()
o.OFICIOS.update(NOVOS)
o.CASACO_MANTEM.update({"agricultor": "wide straw hat and the wicker basket at the belt over the coat",
                        "agricultora": "wide straw hat, the braid and the wicker basket at the belt over the coat"})
_trabalho92 = o._trabalho


def _trabalho(nome):
    """o trabalho com ele/ela trocado (as descrições usam {he}/{his}/{him})."""
    an, desc = _trabalho92(nome)
    return an, desc.format(**o._pron(nome))


o._trabalho = _trabalho
o.ICONES.clear()
o.ICONES.update({"agricultor": "game UI icon: a round wicker basket full of vegetables and cave mushrooms with a small hand trowel "
                               "leaning on it",
                 "estufa": "game UI icon: a small glass greenhouse with a wooden frame and green plants inside",
                 "carvao_vegetal": "game UI item icon: a small pile of black charcoal sticks from wood, slightly glowing at one end",
                 "couro_curtido": "game UI item icon: a folded sheet of tanned reddish-brown leather tied with a thin cord",
                 "racao": "game UI item icon: a small cloth bundle of travel rations tied with a cord, with a piece of hard bread "
                          "sticking out"})


if __name__ == "__main__":
    cmd, resto = sys.argv[1], sys.argv[2:]
    alvos = [a for a in resto if a in NOVOS]
    if cmd not in ("cria", "refaz", "icones", "icone_escolhe") and not alvos:
        sys.exit("diga QUAIS (o Marco aprova um por vez): agricultor / agricultora")
    if cmd == "candidatos":
        o.candidatos(alvos)
    elif cmd == "cria":
        o.cria(resto[0], int(resto[1]))
    elif cmd == "anima":
        o.anima(alvos)
    elif cmd == "baixa":
        o.baixa(alvos)
    elif cmd == "casaco":
        o.casaco(alvos)
    elif cmd == "casaco_baixa":
        o.casaco_baixa(alvos)
    elif cmd == "retrato":
        o.retrato(alvos)
    elif cmd == "refaz":
        o.refaz(resto)
    elif cmd == "icones":
        if not [n for n in resto if n in o.ICONES]:
            sys.exit("diga QUAIS ícones (só depois da aprovação do Marco)")
        o.icones([n for n in resto if n in o.ICONES])
    elif cmd == "icone_escolhe":
        o.icone_escolhe(resto)
