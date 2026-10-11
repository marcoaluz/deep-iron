"""Bloco 125: a COMERCIANTE da caravana (uma só, mulher) com a receita do elenco (a mesma do oficios92.py; este script só
acrescenta o personagem e reaproveita as funções de lá, como o oficios105.py).

  python oficios125.py candidatos             -> comerciante/candidatos.png (16 candidatos, create_image_pro 48x84)
  python oficios125.py cria <idx>             -> o personagem v3 ("high top-down") do candidato idx
  python oficios125.py anima                  -> caminhada8 + comuns (comer, ferido, deitar, mancar) + o trabalho (negociar)
  python oficios125.py baixa                  -> rotações, caminhada ajustada e animações
  python oficios125.py retrato                -> retratos/base/comerciante.png (as 5 expressões: retratos.py)
Depois: python integra.py bonecos comerciante ; python retratos/retratos.py exporta comerciante
"""
import os, sys
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import oficios92 as o  # noqa: E402

NEGOCIAR = ("trading work loop: {he} holds a small brass balance scale in {his} left hand and drops a few coins one by one from "
            "{his} right hand into it, watches the scale tip, then nods with a little smile and starts again; feet planted, same "
            "body and outfit. Only the character and {his} balance scale and coins: no table, no goods, no ground, no motion "
            "trails, no white arcs, no effects.")
NOVOS = {
    "comerciante": ("m", "Adult WOMAN TRAVELLING MERCHANT of the caravan that visits a mining colony, for the same isometric mining colony "
                         "game, with subtle feminine curves (not exaggerated): a wide-brimmed sun-faded ochre hat with a dull red band, a "
                         "long dusty rust-brown travelling coat with many pockets over a patched indigo-blue dress, a big leather satchel "
                         "and a coiled rope across her back, a small brass balance scale hanging at her belt, fingerless leather gloves, "
                         "sturdy boots; confident, weathered, sharp-eyed face with a faint smile, grey streaks in her dark hair. She is NOT "
                         "a miner: NO helmet, NO headlamp, NO pickaxe, NO shovel, NO lantern; the wide ochre hat and the long rust-brown "
                         "coat with the brass scale at the belt are the key features.",
                    "faded ochre and rust red",
                    ("negociar", NEGOCIAR)),
}
o.OFICIOS.clear()
o.OFICIOS.update(NOVOS)
o.CASACO_MANTEM.update({"comerciante": "wide ochre hat, the satchel and the brass scale over the coat"})
_trabalho92 = o._trabalho


def _trabalho(nome):
    an, desc = _trabalho92(nome)
    return an, desc.format(**o._pron(nome))


o._trabalho = _trabalho

if __name__ == "__main__":
    cmd, resto = sys.argv[1], sys.argv[2:]
    alvos = ["comerciante"]
    if cmd == "candidatos":
        o.candidatos(alvos)
    elif cmd == "cria":
        o.cria("comerciante", int(resto[0]))
    elif cmd == "anima":
        o.anima(alvos)
    elif cmd == "baixa":
        o.baixa(alvos)
    elif cmd == "retrato":
        o.retrato(alvos)
