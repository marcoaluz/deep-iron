"""Bloco 124: as três criaturas novas — RATO-DE-CINZA, MORCEGO DE BRASA e SOMBRA SOLAR — com a receita das criaturas do projeto
(fundo.py do Bloco 70: personagem "pro" no estilo do Lumívoro, 4 animações em SE e NE; SO/NO são espelho no integra.py).

  python novas124.py cria          -> cria os 3 personagens (estilo = o Lumívoro); ids em novas124.json
  python novas124.py anima         -> pede caminhada, atacar, dano e morrer de cada
  python novas124.py baixa         -> rotações + animações em criaturas/<nome>/

Depois: python integra.py criaturas (CRIATURAS tem "rato", "morcego" e "sombra") e CRIATURA_PASTA no iso_bonecos.gd.
Os prompts (o plano está em docs/BLOCO124_PLANO.md) seguem o estilo grimy do jogo: contorno de 1 px, paleta suja, luz de cima-esquerda, sem gore.
"""
import sys, os, json, time, re
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import pl, gen, chars

AQUI = os.path.dirname(os.path.abspath(__file__))
REG = os.path.join(AQUI, "novas124.json")
LUMIVORO = "7a9f9a80-402f-4b49-8903-f356154e715e"
ESTILO = "dark gritty post-apocalyptic mining game, grimy desaturated earthy palette, crisp 1px near-black outline, pixel art"
BICHOS = {
    "rato": {
        "nome": "Rato de cinza",
        "tamanho": 56,
        "desc": ("Ash rat, a fat cat-sized rat of a ruined mining colony: soot-grey matted fur dusted with pale ash, a long bare pink-grey tail, "
                 "tiny red eyes, a torn ear, two yellowed gnawing teeth, hunched and scurrying low to the ground, a smudge of ash on its muzzle; " + ESTILO),
        "anims": [("caminhada", "scurries forward fast with a low bouncing run, the tail swaying behind", 6),
                  ("atacar", "lunges forward and snaps its yellow teeth", 6),
                  ("dano", "recoils hit, squeals and flinches", 4),
                  ("morrer", "flops onto its side, legs twitching, then lies still", 6)],
    },
    "morcego": {
        "nome": "Morcego de brasa",
        "tamanho": 72,
        "desc": ("Ember bat from a lava cavern: a bat the size of a crow, leathery charcoal-black wings edged with glowing orange ember veins, a small "
                 "furry body, big pointed ears, tiny glowing orange eyes, a few tiny embers drifting off the wing tips; flying with wings spread; " + ESTILO),
        "anims": [("caminhada", "hovers forward in a steady wing-flapping flight cycle, wings beating up and down", 6),
                  ("atacar", "dives forward with an open fanged mouth and the wings swept back", 6),
                  ("dano", "recoils hit, the wings flutter and the embers flicker", 4),
                  ("morrer", "the wings fold, it falls to the ground and lies still while the embers fade", 6)],
    },
    "sombra": {
        "nome": "Sombra solar",
        "tamanho": 96,
        "desc": ("Solar shadow: a tall thin humanoid silhouette of living darkness, a corona of thin white-gold sun flares around its edges, no face but "
                 "two pale white pinpoint eyes, ragged smoky edges trailing like heat haze, slightly translucent, long thin arms ending in sharp wisps, "
                 "burned out by the sun; eerie but sober; " + ESTILO),
        "anims": [("caminhada", "glides forward without stepping, the smoky edges trailing and the arms hanging", 6),
                  ("atacar", "stretches both long arms forward while a flare of white light pulses from its chest", 6),
                  ("dano", "flickers and distorts like a heat haze, recoiling", 4),
                  ("morrer", "dissolves into drifting ash and sun sparks until nothing is left", 6)],
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
        args = {"description": b["desc"], "name": b["nome"], "mode": "pro", "size": b["tamanho"]}
        if b["tamanho"] >= 78:  # o Lumívoro tem 72x78: o estilo dele só vale pra tela de 78 px ou mais (as menores seguem o texto do estilo)
            args["style_character_id"] = LUMIVORO
        t = gen._texto(pl.call("create_character", args))
        print(k, t[:300].replace("\n", " "))
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
        i = chars.info(d[k])
        tem = set(i.get("anims", []))
        for nome, acao, n in b["anims"]:
            if nome in tem:
                continue
            t = chars.anima(d[k], nome, acao, frames=n)
            print(k, nome, t[:200].replace("\n", " "), flush=True)
            time.sleep(5)


def baixa():
    d = reg()
    for k, b in BICHOS.items():
        espera(d[k])
        pasta = os.path.join(AQUI, k)
        chars.baixa_rotacoes(d[k], pasta)
        for nome, _a, _n in b["anims"]:
            print(k, nome, chars.baixa_anim(d[k], pasta, nome))


if __name__ == "__main__":
    {"cria": cria, "anima": anima, "baixa": baixa}[sys.argv[1]]()
