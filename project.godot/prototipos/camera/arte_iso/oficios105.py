"""Bloco 105: o CARREGADOR, a CARREGADORA, o MECÂNICO e a MECÂNICA com a receita do elenco (a mesma do oficios92.py —
este script só acrescenta os quatro ofícios e reaproveita as funções de lá, como o oficios94.py e o oficios104.py).
O Marco pediu em etapas: SÓ o carregador primeiro (piloto completo); os outros três e os ícones só depois da aprovação.

  python oficios105.py candidatos [nomes]   -> <pasta>/candidatos.png (16 candidatos, create_image_pro 48x84)
  python oficios105.py cria <nome> <idx>    -> o personagem v3 ("high top-down") do candidato idx
  python oficios105.py anima [nomes]        -> caminhada8 + comuns (comer, ferido, deitar, mancar) + o trabalho
  python oficios105.py baixa [nomes]        -> rotações, caminhada ajustada e animações
  python oficios105.py casaco [nomes]       -> estado "Casaco inverno" + caminhada + o trabalho
  python oficios105.py casaco_baixa [nomes]
  python oficios105.py retrato [nomes]      -> retratos/base/<nome>.png (as 5 expressões: retratos.py)
  python oficios105.py icones / icone_escolhe carregador=cNN   (SÓ depois da aprovação)
"""
import os, sys
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import oficios92 as o  # noqa: E402

CARREGAR = ("hauling work loop: {he} bends {his} knees and grabs a small closed burlap SACK from the ground in front of "
            "{him} with both hands, lifts it up onto {his} right shoulder, holds it there a moment, then lowers it back "
            "down to the ground in front of {him} and grabs it again; back straight, feet planted, same body and outfit. "
            "Only the character and the sack: no ground drawn, no crates, no shelves, no motion trails, no white arcs, "
            "no effects.")
CONSERTAR = ("mechanic work loop: {he} holds a big steel WRENCH in {his} right hand from the very first frame to the "
             "last and turns a bolt at chest height in front of {him} (the machine is NOT drawn) with short firm pulls, "
             "the left hand steadying, then gives the bolt a quick tap with the wrench and turns again; feet planted, "
             "same body and outfit. Only the character and the wrench: no machine, no gears, no sparks, no oil, no "
             "ground, no motion trails, no white arcs, no effects.")
NOVOS = {
    "carregador": ("h", "Adult MAN PORTER (hauler who carries materials from the storehouse to the building sites, the "
                        "furnace and the kitchen) for the same isometric mining colony game: a faded indigo-blue knitted "
                        "beanie, a sturdy empty WOODEN CARRYING FRAME (A-frame backpack) strapped on his back with rope, "
                        "a thick padded leather pad on the left shoulder, a faded indigo-blue work vest over a dull grey "
                        "shirt with rolled sleeves, a coiled rope sling across the chest, thick work gloves, a wide belt "
                        "with a hook, dark trousers with patched knees, heavy boots. Strong broad build, male face, short "
                        "dark beard, cheerful and tired. He is NOT a miner: NO helmet, NO headlamp, NO pickaxe, NO shovel, "
                        "NO lantern; the knitted beanie and the wooden carrying frame on his back are the key features.",
                   "faded indigo blue",
                   ("carregar", CARREGAR)),
    "carregadora": ("m", "Adult WOMAN PORTER (hauler who carries materials from the storehouse to the building sites, "
                         "the furnace and the kitchen) for the same isometric mining colony game, strong build with subtle "
                         "feminine curves (not exaggerated): hair in two short braids under a faded indigo-blue knitted "
                         "headband, a sturdy empty WOODEN CARRYING FRAME (A-frame backpack) strapped on her back with "
                         "rope, a thick padded leather pad on the left shoulder, a faded indigo-blue work vest over a dull "
                         "grey shirt with rolled sleeves, a coiled rope sling across the chest, thick work gloves, dark "
                         "trousers with patched knees, heavy boots. Clearly a woman: female face, freckles, determined. "
                         "She is NOT a miner: NO helmet, NO headlamp, NO pickaxe, NO shovel, NO lantern; the braids and "
                         "the wooden carrying frame are the key features.",
                    "faded indigo blue",
                    ("carregar", CARREGAR)),
    "mecanico": ("h", "Adult MAN MECHANIC (repairs the elevators, the rails, the drilling machine and the fans) for the "
                      "same isometric mining colony game: oil-stained dark teal coveralls with the top half tied at the "
                      "waist over a dirty white undershirt, a teal flat cap worn backwards, round clear safety goggles "
                      "hanging around the neck, a big steel wrench and a screwdriver in a leather tool belt, a red rag "
                      "hanging from the back pocket, grease smudges on the arms, heavy boots. Male face, thin moustache, "
                      "squinting and focused. He is NOT a miner: NO helmet, NO headlamp, NO pickaxe, NO shovel, NO "
                      "lantern; the teal coveralls and the wrench are the key features.",
                 "oily dark teal",
                 ("consertar", CONSERTAR)),
    "mecanica": ("m", "Adult WOMAN MECHANIC (repairs the elevators, the rails, the drilling machine and the fans) for the "
                      "same isometric mining colony game, with subtle feminine curves (not exaggerated): oil-stained dark "
                      "teal coveralls with the sleeves rolled up, short messy hair held by a red bandana, round clear "
                      "safety goggles pushed up on the forehead, a big steel wrench and a screwdriver in a leather tool "
                      "belt, grease smudges on the cheek and arms, heavy boots. Clearly a woman: female face, sharp eyes. "
                      "She is NOT a miner: NO helmet, NO headlamp, NO pickaxe, NO shovel, NO lantern; the teal coveralls, "
                      "the red bandana and the wrench are the key features.",
                 "oily dark teal",
                 ("consertar", CONSERTAR)),
}
o.OFICIOS.clear()
o.OFICIOS.update(NOVOS)
o.CASACO_MANTEM.update({"carregador": "knitted beanie and the wooden carrying frame on the back over the coat",
                        "carregadora": "braids and the wooden carrying frame on the back over the coat",
                        "mecanico": "backwards flat cap, goggles around the neck and the tool belt with the wrench over the coat",
                        "mecanica": "red bandana, goggles on the forehead and the tool belt with the wrench over the coat"})
_trabalho92 = o._trabalho


def _trabalho(nome):
    """o trabalho com ele/ela trocado (as descrições usam {he}/{his}/{him})."""
    an, desc = _trabalho92(nome)
    return an, desc.format(**o._pron(nome))


o._trabalho = _trabalho
o.ICONES.clear()
o.ICONES.update({"carregador": "game UI icon: a wooden A-frame carrying backpack loaded with a small burlap sack and a "
                               "couple of planks tied with rope",
                 "mecanico": "game UI icon: a big steel wrench crossed over a small brass gear",
                 "sem_material": "game UI icon: an EMPTY open wooden crate with a small red question mark above it",
                 "al_maquina": "game UI icon: a broken brass gear cracked in two with a small red warning triangle"})


if __name__ == "__main__":
    cmd, resto = sys.argv[1], sys.argv[2:]
    alvos = [a for a in resto if a in NOVOS]
    if cmd not in ("cria", "refaz", "icones", "icone_escolhe") and not alvos:
        sys.exit("diga QUAIS (o Marco aprova um por vez): carregador / carregadora / mecanico / mecanica")
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
