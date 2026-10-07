"""Bloco 94: o CARPINTEIRO e a CARPINTEIRA com a receita do elenco (a mesma do oficios92.py — este script só
acrescenta os dois ofícios e reaproveita as funções de lá):

  python oficios94.py candidatos [nomes]   -> <pasta>/candidatos.png (16 candidatos, create_image_pro 48x84)
  python oficios94.py cria <nome> <idx>    -> o personagem v3 ("high top-down") do candidato idx
  python oficios94.py anima [nomes]        -> caminhada8 + comuns (comer, ferido, deitar, mancar) + serrar
  python oficios94.py baixa [nomes]        -> rotações, caminhada ajustada (caminhadas8 baixa/troca) e animações
  python oficios94.py casaco [nomes]       -> estado "Casaco inverno" + caminhada + serrar
  python oficios94.py casaco_baixa [nomes]
  python oficios94.py retrato [nomes]      -> retratos/base/<nome>.png (as 5 expressões: retratos.py)
  python oficios94.py icones / icone_escolhe carpinteiro=cNN
"""
import os, sys
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import oficios92 as o  # noqa: E402

NOVOS = {
    "carpinteiro": ("h", "Adult MAN CARPENTER (woodworker who saws planks and builds beds and furniture) for the same "
                         "isometric mining colony game: a faded brown flat cap, rolled-up sleeves of a dull ochre work "
                         "shirt, a worn tan canvas carpenter's apron with pockets holding a folding ruler and a flat "
                         "carpenter's pencil, a wide leather tool belt with a claw hammer and a pouch of nails, sawdust on "
                         "the clothes, dark trousers, heavy boots. Male face, short moustache, calm and focused. He is NOT a miner: NO helmet, NO headlamp, NO pickaxe, NO "
                         "shovel, NO lantern; the flat cap and the apron are the key features.",
                    "dull ochre shirt",
                    ("serrar", "carpentry work loop: {he} holds a hand saw with a wooden handle in {his} right hand from "
                               "the very first frame to the last, leaning forward with {his} left hand pressing down at "
                               "waist height as if holding a plank on a sawhorse that is NOT drawn, and pushes and pulls "
                               "the saw back and forth in short strokes at waist height in front of {him}; feet planted, "
                               "same body and outfit. Only the character and the saw: no plank, no sawhorse, no table, no "
                               "sawdust, no ground, no motion trails, no white arcs, no effects.")),
    "carpinteira": ("m", "Adult WOMAN CARPENTER (woodworker who saws planks and builds beds and furniture) for the same "
                         "isometric mining colony game, with subtle feminine curves (not exaggerated): hair tied in a low "
                         "bun under a faded brown kerchief, rolled-up sleeves of a dull ochre work shirt, a worn tan canvas "
                         "carpenter's apron with pockets holding a folding ruler and a flat carpenter's pencil, a wide "
                         "leather tool belt with a claw hammer and a pouch of nails, sawdust on the clothes, dark trousers, "
                         "heavy boots. Clearly a woman: female face, calm and focused. She is NOT a miner: NO helmet, NO headlamp, NO "
                         "pickaxe, NO shovel, NO lantern; the kerchief and the apron are the key features.",
                    "dull ochre shirt",
                    ("serrar", "carpentry work loop: {he} holds a hand saw with a wooden handle in {his} right hand from "
                               "the very first frame to the last, leaning forward with {his} left hand pressing down at "
                               "waist height as if holding a plank on a sawhorse that is NOT drawn, and pushes and pulls "
                               "the saw back and forth in short strokes at waist height in front of {him}; feet planted, "
                               "same body and outfit. Only the character and the saw: no plank, no sawhorse, no table, no "
                               "sawdust, no ground, no motion trails, no white arcs, no effects.")),
}
o.OFICIOS.clear()
o.OFICIOS.update(NOVOS)
o.CASACO_MANTEM.update({"carpinteiro": "flat cap, tool belt with the hammer over the coat",
                        "carpinteira": "kerchief, tool belt with the hammer over the coat"})
_trabalho92 = o._trabalho


def _trabalho(nome):
    """o trabalho com ele/ela já trocado (no 92 as descrições do OFICIOS vinham escritas por extenso)."""
    an, desc = _trabalho92(nome)
    return an, desc.format(**o._pron(nome))


o._trabalho = _trabalho
# a 1ª leva do serrar saiu com o serrote quase invisível e o braço parado: descrição mais literal
o.REFAZ["serrar"] = ("carpentry sawing loop: {he} holds a LONG hand saw in {his} right hand from the very first frame to "
                     "the last (wooden handle, a long light grey steel blade with teeth, as long as {his} arm, clearly "
                     "visible), the blade pointing forward and slightly down in front of {him} at waist height; {his} "
                     "left hand rests flat at waist height as if pressing a plank on a sawhorse that is NOT drawn; {he} "
                     "pushes the saw far forward and pulls it far back in long strokes, the right arm and shoulder "
                     "moving a lot, leaning {his} upper body into each stroke; feet planted, same body and outfit. Only "
                     "the character and the long saw: no plank, no sawhorse, no table, no sawdust, no ground, no motion "
                     "trails, no white arcs, no effects.")


def refaz_casaco(nomes):
    """o serrar do casaco de novo (a 1ª leva foi com {he} sem trocar): apaga e pede com o REFAZ."""
    import json as _j
    ids = _j.load(open(o.CASACO_IDS, encoding="utf-8"))
    for nome in nomes:
        cid = ids["casaco_" + nome]["char"]
        i = o.chars.info(cid)
        if "serrar" in i["anims"]:
            print("  apagou", nome, o.gen._texto(o.pl.call("delete_animation", {"character_id": cid, "animation_group_id": i["anims"]["serrar"]["group"]}))[:60])
        a = {"character_id": cid, "mode": "v3", "directions": ["south-east", "north-east"],
             "action_description": o.REFAZ["serrar"].format(**o._pron(nome)), "frame_count": 8, "keep_first_frame": False,
             "animation_name": "serrar"}
        print("  casaco_%s serrar %s" % (nome, " | ".join(o._pede(a).splitlines()[:2])[:100]), flush=True)
o.ICONES.clear()
o.ICONES.update({"carpinteiro": "game UI icon: a single carpenter's HAND SAW, diagonal, with a dark wooden handle and "
                                "a wide toothed grey steel blade",
                 # os itens novos (armazém e Oficina)
                 "it_tabua": "game UI item icon: a small neat stack of three pale fresh-cut sawn wooden planks",
                 "it_cama_boa": "game UI item icon: a small simple WOODEN BED seen from the side, plank headboard, grey "
                                "blanket and a white pillow",
                 "it_mochila": "game UI item icon: a brown leather BACKPACK (rucksack) with a flap and a buckle",
                 "it_botas": "game UI item icon: a pair of tall worn brown leather winter boots with nailed soles and "
                             "laces",
                 "it_picareta_de_aco": "game UI item icon: a steel pickaxe with a bright grey forged steel head and a dark "
                                       "wooden handle"})


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
    elif cmd == "refaz_casaco":
        refaz_casaco(alvos)
    elif cmd == "icones":
        o.icones([n for n in resto if n in o.ICONES] or list(o.ICONES))
    elif cmd == "icone_escolhe":
        o.icone_escolhe(resto)
