"""Bloco 104: o BATEDOR e a BATEDORA com a receita do elenco (a mesma do oficios92.py — este script só acrescenta os dois
ofícios e reaproveita as funções de lá, como o oficios94.py):

  python oficios104.py candidatos [nomes]   -> <pasta>/candidatos.png (16 candidatos, create_image_pro 48x84)
  python oficios104.py cria <nome> <idx>    -> o personagem v3 ("high top-down") do candidato idx
  python oficios104.py anima [nomes]        -> caminhada8 + comuns (comer, ferido, deitar, mancar) + bater (a luneta)
  python oficios104.py baixa [nomes]        -> rotações, caminhada ajustada e animações
  python oficios104.py casaco [nomes]       -> estado "Casaco inverno" + caminhada + bater
  python oficios104.py casaco_baixa [nomes]
  python oficios104.py retrato [nomes]      -> retratos/base/<nome>.png (as 5 expressões: retratos.py)
  python oficios104.py icones / icone_escolhe batedor=cNN
"""
import os, sys
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import oficios92 as o  # noqa: E402

BATER = ("scouting work loop: {he} raises a short brass SPYGLASS (telescope) to {his} right eye with both hands from the "
         "very first frame, looks far away through it and slowly turns {his} head and upper body from left to right and "
         "back, scanning the horizon, then lowers it a little and raises it again; feet planted, same body and outfit. "
         "Only the character and the spyglass: no ground, no trees, no motion trails, no white arcs, no effects.")
NOVOS = {
    "batedor": ("h", "Adult MAN SCOUT (pathfinder who leads expeditions into the burned forest and the old ruins) for the "
                     "same isometric mining colony game: a weathered dark green hooded cloak with the hood DOWN on the "
                     "shoulders, a wide-brimmed brown leather bush hat, a moss-green padded vest over a dull grey shirt, a "
                     "coil of rope over one shoulder, a rolled map and a short brass spyglass tucked in the belt, a "
                     "machete in a leather sheath on the hip, a small travel pack, wrapped forearms, dark trousers tucked "
                     "into muddy tall boots. Male face, stubble, alert eyes, weathered by the sun. He is NOT a miner: NO "
                     "helmet, NO headlamp, NO pickaxe, NO shovel, NO lantern; the bush hat and the green cloak are the key "
                     "features.",
                "moss green cloak",
                ("bater", BATER)),
    "batedora": ("m", "Adult WOMAN SCOUT (pathfinder who leads expeditions into the burned forest and the old ruins) for "
                      "the same isometric mining colony game, with subtle feminine curves (not exaggerated): hair in a long "
                      "braid over one shoulder, a weathered dark green hooded cloak with the hood DOWN on the shoulders, a "
                      "moss-green padded vest over a dull grey shirt, a coil of rope over one shoulder, a rolled map and a "
                      "short brass spyglass tucked in the belt, a machete in a leather sheath on the hip, a small travel "
                      "pack, wrapped forearms, dark trousers tucked into muddy tall boots. Clearly a woman: female face, "
                      "alert eyes, a thin scar on the cheek. She is NOT a miner: NO helmet, NO headlamp, NO pickaxe, NO "
                      "shovel, NO lantern; the braid and the green cloak are the key features.",
                 "moss green cloak",
                 ("bater", BATER)),
}
o.OFICIOS.clear()
o.OFICIOS.update(NOVOS)
o.CASACO_MANTEM.update({"batedor": "bush hat, rope coil and the spyglass in the belt over the coat",
                        "batedora": "long braid, rope coil and the spyglass in the belt over the coat"})
_trabalho92 = o._trabalho


def _trabalho(nome):
    """o trabalho com ele/ela trocado (as descrições usam {he}/{his})."""
    an, desc = _trabalho92(nome)
    return an, desc.format(**o._pron(nome))


o._trabalho = _trabalho
o.ICONES.clear()
o.ICONES.update({"batedor": "game UI icon: a short brass SPYGLASS (telescope) lying diagonally over a small rolled "
                            "parchment map",
                 "expedicao": "game UI icon: a small worn leather travel BACKPACK with a coil of rope and a rolled map "
                              "strapped on top",
                 "it_antena": "game UI item icon: an improvised RADIO ANTENNA: a short wooden mast with coils of copper wire "
                              "wrapped around it and a small round dish made of scrap metal on top"})


if __name__ == "__main__":
    cmd, resto = sys.argv[1], sys.argv[2:]
    alvos = [a for a in resto if a in NOVOS] or list(NOVOS)
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
        o.icones([n for n in resto if n in o.ICONES] or list(o.ICONES))
    elif cmd == "icone_escolhe":
        o.icone_escolhe(resto)
