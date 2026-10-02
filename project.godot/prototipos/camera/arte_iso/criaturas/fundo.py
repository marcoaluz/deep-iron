"""Bloco 70: as criaturas do FUNDO — Gosma ácida (S2) e Magmante (S3) — no estilo do Lumívoro do jogo
(mesmo caminho do chefe.py do Bloco 62).

  python fundo.py cria          -> cria os 2 personagens (pro, estilo = o Lumívoro); ids em fundo.json
  python fundo.py anima         -> pede as 4 animações de cada (SE e NE; SO/NO são espelho no integra.py)
  python fundo.py baixa         -> rotações + animações em criaturas/gosma/ e criaturas/magmante/

Depois: python integra.py criaturas (CRIATURAS tem "gosma" e "magmante").
"""
import sys, os, json, time, re
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import pl, gen, chars

AQUI = os.path.dirname(os.path.abspath(__file__))
REG = os.path.join(AQUI, "fundo.json")
LUMIVORO = "7a9f9a80-402f-4b49-8903-f356154e715e"
BICHOS = {
    "gosma": {
        "nome": "Gosma acida",
        "desc": ("Acid slime creature from a flooded mine gallery: a low wobbling blob of translucent toxic green acid "
                 "the size of a large dog, a darker murky core with half-dissolved rusty bolts and pebbles floating "
                 "inside, two small dim yellow eye-spots, dripping acid pseudopod arms, a small puddle under it; dark "
                 "gritty post-apocalyptic mining game, pixel art"),
        "anims": [("caminhada", "oozes forward, the blob squashes and stretches as it creeps", 6),
                  ("atacar", "rears up tall and slaps down a dripping acid pseudopod", 6),
                  ("dano", "recoils hit, the blob wobbles and flattens", 4),
                  ("morrer", "melts down into a flat bubbling puddle that stops moving", 6)],
    },
    "magmante": {
        "nome": "Magmante",
        "desc": ("Magmante, a hulking lava rock creature from the deep abyss: a hunched heavy body of cracked black "
                 "basalt plates, glowing orange molten cracks between the plates, thick stone arms with blunt fists, "
                 "a small head sunk between the shoulders with two ember eyes, wisps of smoke; slow and heavy, "
                 "about as tall as a man; dark gritty post-apocalyptic mining game, pixel art"),
        "anims": [("caminhada", "slow heavy stomping walk, shoulders swaying", 6),
                  ("atacar", "raises both stone fists and smashes them down", 6),
                  ("dano", "recoils hit, the glow in the cracks flickers", 4),
                  ("morrer", "crumbles down into a pile of dark rocks and the glow fades out", 6)],
    },
}


def reg():
    return json.load(open(REG, encoding="utf-8")) if os.path.exists(REG) else {}


def salva(d):
    json.dump(d, open(REG, "w", encoding="utf-8"), indent=1)


def cria():
    d = reg()
    for k, b in BICHOS.items():
        if d.get(k):
            continue
        t = gen._texto(pl.call("create_character", {"description": b["desc"], "name": b["nome"], "mode": "pro",
                                                     "style_character_id": LUMIVORO, "size": 96}))
        print(k, t[:400].replace("\n", " "))
        m = re.search(r"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})", t)
        d[k] = m.group(1) if m else None
        salva(d)


def espera(cid, max_s=1800):
    t0 = time.time()
    while time.time() - t0 < max_s:
        i = chars.info(cid)
        print("  status:", i["status"], flush=True)
        if i["status"] in ("completed", "complete", "done", "ready"):
            return i
        time.sleep(30)
    return chars.info(cid)


def anima():
    d = reg()
    for k, b in BICHOS.items():
        espera(d[k])
        for nome, acao, n in b["anims"]:
            t = chars.anima(d[k], nome, acao, frames=n)
            print(k, nome, t[:200].replace("\n", " "), flush=True)
            time.sleep(5)


def baixa():
    d = reg()
    for k, b in BICHOS.items():
        pasta = os.path.join(AQUI, k)
        chars.baixa_rotacoes(d[k], pasta)
        for nome, _a, _n in b["anims"]:
            print(k, nome, chars.baixa_anim(d[k], pasta, nome))


if __name__ == "__main__":
    {"cria": cria, "anima": anima, "baixa": baixa}[sys.argv[1]]()
