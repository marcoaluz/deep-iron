"""Bloco 80: o FERRUGENTO ROBÔ no PixelLab — um robô pequeno e enferrujado, estilo exterminador (substitui o
placeholder ferrugento_placeholder.py). Estilo = o Lumívoro do jogo (como fundo.py / chefe.py).

  python ferrugento_robo.py cria    -> cria o personagem (pro); id em ferrugento_robo.json
  python ferrugento_robo.py anima   -> as 5 animações, só na direção SE (a folha é uma direção; o jogo espelha)
  python ferrugento_robo.py baixa   -> rotações + animações em criaturas/ferrugento_robo/
  python ferrugento_robo.py folha   -> monta assets/game/ferrugento_robo.png no formato da folha de quadros
                                       (uma linha por animação) e imprime os campos visual_* pra cena

A folha segue creature.gd (visual_textura / visual_quadro / visual_anims / visual_quadros / visual_pe):
todas as animações recortadas na MESMA caixa (a união do desenho de todos os quadros), então o pé não pula.
"""
import sys, os, json, time, re, glob
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import pl, gen, chars

AQUI = os.path.dirname(os.path.abspath(__file__))
REG = os.path.join(AQUI, "ferrugento_robo.json")
PASTA = os.path.join(AQUI, "ferrugento_robo")
SAIDA = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "..", "assets", "game", "ferrugento_robo.png"))
LUMIVORO = "7a9f9a80-402f-4b49-8903-f356154e715e"
DESC = ("Ferrugento, a small killer robot from before the solar catastrophe, about knee-to-waist height of a man: a "
        "skeletal endoskeleton of corroded rusty-brown and dark grey metal, a metal skull head with a grinning steel "
        "jaw and two glowing red eyes, exposed piston joints and cables, thin ribbed metal torso, clawed metal hands, "
        "flaking orange rust and grime everywhere; menacing like a tiny terminator; dark gritty post-apocalyptic "
        "mining game, pixel art")
ANIMS = [("parado", "stands still, slight mechanical sway, the red eyes flicker", 4),
         ("caminhada", "stiff mechanical walk forward, pistons pumping, arms swinging", 6),
         ("atacar", "lunges and slashes forward with its metal claw", 6),
         ("dano", "jolts back when hit, sparks fly from its torso", 4),
         ("morrer", "collapses and falls apart into a pile of rusty scrap, the red eyes go dark", 6)]


def reg():
    return json.load(open(REG, encoding="utf-8")) if os.path.exists(REG) else {}


def salva(d):
    json.dump(d, open(REG, "w", encoding="utf-8"), indent=1)


def cria():
    d = reg()
    if d.get("id"):
        print("já existe", d["id"])
        return
    t = gen._texto(pl.call("create_character", {"description": DESC, "name": "Ferrugento robo", "mode": "pro",
                                                 "style_character_id": LUMIVORO, "size": 80}))
    print(t[:500])
    m = re.search(r"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})", t)
    d["id"] = m.group(1) if m else None
    salva(d)


def espera(cid, max_s=1800):
    t0 = time.time()
    while time.time() - t0 < max_s:
        i = chars.info(cid)
        pend = "pending jobs" in i["texto"]
        print("  status:", i["status"], "pendente" if pend else "", flush=True)
        if i["status"] in ("completed", "complete", "done", "ready") and not pend:
            return i
        time.sleep(30)
    return chars.info(cid)


def anima():
    cid = reg()["id"]
    espera(cid)
    for nome, acao, n in ANIMS:
        t = chars.anima(cid, nome, acao, dirs=("south-east",), frames=n)
        print(nome, t[:200].replace("\n", " "), flush=True)
        time.sleep(5)


def baixa():
    cid = reg()["id"]
    espera(cid)
    chars.baixa_rotacoes(cid, PASTA)
    for nome, _a, _n in ANIMS:
        print(nome, chars.baixa_anim(cid, PASTA, nome))


def folha():
    from PIL import Image
    quadros = {}
    for nome, _a, _n in ANIMS:
        fs = sorted(glob.glob(os.path.join(PASTA, nome, "SE", "*.png")), key=lambda f: int(os.path.basename(f)[:-4]))
        if not fs:  # (sem a animação: o parado vira a rotação SE)
            fs = [os.path.join(PASTA, "rotacoes", "south-east.png")]
        quadros[nome] = [Image.open(f).convert("RGBA") for f in fs]
    bb = None
    for ims in quadros.values():
        for im in ims:
            b = im.getbbox()
            if b:
                bb = b if bb is None else (min(bb[0], b[0]), min(bb[1], b[1]), max(bb[2], b[2]), max(bb[3], b[3]))
    x0, y0, x1, y1 = bb
    x0, y0, x1, y1 = max(0, x0 - 1), max(0, y0 - 1), x1 + 1, y1 + 1
    qw, qh = x1 - x0, y1 - y0
    largura = max(len(v) for v in quadros.values())
    out = Image.new("RGBA", (qw * largura, qh * len(ANIMS)))
    for row, (nome, _a, _n) in enumerate(ANIMS):
        for i, im in enumerate(quadros[nome]):
            out.alpha_composite(im.crop((x0, y0, x1, y1)), (i * qw, row * qh))
    out.save(SAIDA)
    # o pé: a última linha com desenho no quadro parado
    p0 = quadros["parado"][0].crop((x0, y0, x1, y1))
    pe = qh - p0.getbbox()[3]
    print("ok", SAIDA, out.size)
    print("visual_quadro = Vector2i(%d, %d)" % (qw, qh))
    print("visual_quadros = PackedInt32Array(%s)" % ", ".join(str(len(quadros[n])) for n, _a, _x in ANIMS))
    print("visual_pe = %.1f" % pe)


if __name__ == "__main__":
    {"cria": cria, "anima": anima, "baixa": baixa, "folha": folha}[sys.argv[1]]()
