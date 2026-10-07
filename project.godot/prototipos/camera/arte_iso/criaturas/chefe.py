"""Bloco 62: o CHEFE das invasões — a Matriarca dos Lumívoros — no estilo do Lumívoro do jogo.

  python chefe.py cria        -> cria o personagem (pro, estilo = o Lumívoro) e grava o id em chefe.json
  python chefe.py anima       -> pede as 4 animações (SE e NE; SO/NO são espelho no integra.py)
  python chefe.py baixa       -> rotações + animações em criaturas/lumivoro_matriarca/

Depois: python integra.py criaturas (CRIATURAS tem "lumivoro_matriarca").
"""
import sys, os, json, time
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import pl, gen, chars

AQUI = os.path.dirname(os.path.abspath(__file__))
REG = os.path.join(AQUI, "chefe.json")
PASTA = os.path.join(AQUI, "lumivoro_matriarca")
LUMIVORO = "7a9f9a80-402f-4b49-8903-f356154e715e"
DESC = ("Lumivoro Matriarch, the boss of the pale cave creatures: a huge gaunt hunched pale beast twice the size of a "
        "lumivoro, long bony clawed arms, glowing purple veins, a crown of purple crystal spikes growing from its back "
        "and skull, eyeless head with a wide maw; dark gritty post-apocalyptic mining game, pixel art")
ANIMS = [("caminhada", "slow heavy menacing walk, claws dragging", 6),
         ("atacar", "rears up and slams both clawed arms down", 6),
         ("dano", "recoils hit, flinches back", 4),
         ("morrer", "collapses to the ground and the crystal glow fades out", 6)]


def reg():
    return json.load(open(REG, encoding="utf-8")) if os.path.exists(REG) else {}


def salva(d):
    json.dump(d, open(REG, "w", encoding="utf-8"), indent=1)


def cria():
    t = gen._texto(pl.call("create_character", {"description": DESC, "name": "Matriarca dos Lumivoros", "mode": "pro",
                                                 "style_character_id": LUMIVORO, "size": 128}))
    print(t[:600])
    import re
    m = re.search(r"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})", t)
    d = reg()
    d["char"] = m.group(1) if m else None
    salva(d)


def espera(cid, max_s=1800):
    t0 = time.time()
    while time.time() - t0 < max_s:
        i = chars.info(cid)
        print("  status:", i["status"])
        if i["status"] in ("completed", "complete", "done", "ready"):
            return i
        time.sleep(30)
    return chars.info(cid)


def anima():
    cid = reg()["char"]
    espera(cid)
    for nome, acao, n in ANIMS:
        t = chars.anima(cid, nome, acao, frames=n)
        print(nome, t[:200].replace("\n", " "))
        time.sleep(5)


def baixa():
    cid = reg()["char"]
    chars.baixa_rotacoes(cid, PASTA)
    for nome, _a, _n in ANIMS:
        print(nome, chars.baixa_anim(cid, PASTA, nome))


if __name__ == "__main__":
    {"cria": cria, "anima": anima, "baixa": baixa, "espera": lambda: espera(reg()["char"])}[sys.argv[1]]()
