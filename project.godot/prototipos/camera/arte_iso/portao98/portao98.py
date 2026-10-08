"""Bloco 98: o PORTÃO da paliçada ABERTO e a meia-abertura (PixelLab, create_image_pro), a partir do portão fechado
aprovado de cada nível (assets/game/iso/predios/portao/nivel_N.png, quadro 126x198, âncora 63,164).

  python portao98.py gera [nome ...]      -> candidatos em portao98/_cand/<nome>.png (um arquivo por pedido)
  python portao98.py escolhe nome=arq ... -> portao98/<nome>.png (quadro 126x198, o pé no mesmo lugar do fechado)

Nomes: aberto_1/2/3 (as folhas abertas, passagem livre no meio), meio_1/2/3 (folhas a meio caminho) e
quebrado_aberto (o portão em ruína com o vão aberto: nível 0 ou derrubado). Os candidatos não escolhidos ficam fora do
repositório (_cand/ tem .gitignore); os ids ficam em portao98_jobs.json. Depois: integra.py predios portao (estados
aberto_N / meio_N no predios.json).
"""
import sys, os, base64, io
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import gen
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
JOGO = os.path.join(AQUI, "..", "..", "..", "..", "assets", "game", "iso", "predios", "portao")
CAND = os.path.join(AQUI, "_cand")
QUADRO = (126, 198)
COMUM = ("Isometric 2:1 pixel art, the SAME camera angle, canvas, ground line and position as the reference gate (the "
         "closed gate set into a palisade wall that runs from lower-left to upper-right): keep the same two big posts, "
         "the same palisade stake wings on both sides, the same wood / iron / stone materials, colours, outline and "
         "scale. The base of the structure stays exactly where it is on the canvas. ")
ABERTO = ("The big double door leaves are swung WIDE OPEN and pushed back flat against the inner sides of the posts, "
          "leaving a completely EMPTY, clear passage between the two posts: through the opening you can see the bare "
          "ground and the background, no door in the middle. ")
MEIO = ("The big double door leaves are HALF OPEN: both leaves swung about 45 degrees away from each other, a narrow "
        "dark gap between them in the middle. ")
PEDIDOS = {
    "aberto_1": COMUM + "A wooden log-post gate with a picket door. " + ABERTO + "Only the gate, transparent background, no people, no text. ",
    "aberto_2": COMUM + "A heavy planked timber gate with a small shingled roof over the lintel. " + ABERTO + "Only the gate, transparent background, no people, no text. ",
    "aberto_3": COMUM + "A stone gatehouse arch with iron-banded doors. " + ABERTO + "Only the gate, transparent background, no people, no text. ",
    "meio_1": COMUM + "A wooden log-post gate with a picket door. " + MEIO + "Only the gate, transparent background, no people, no text. ",
    "meio_2": COMUM + "A heavy planked timber gate with a small shingled roof over the lintel. " + MEIO + "Only the gate, transparent background, no people, no text. ",
    "meio_3": COMUM + "A stone gatehouse arch with iron-banded doors. " + MEIO + "Only the gate, transparent background, no people, no text. ",
    "quebrado_aberto": COMUM + ("A RUINED, wrecked wooden gate: the door leaves are gone, only the two leaning broken posts, a cracked "
                        "crossbeam and splintered stakes remain at the sides, with some planks and debris on the ground "
                        "beside the posts, but a wide CLEAR open passage in the middle between them. "
                        "Only the gate, transparent background, no people, no text. "),
}
SEMCHAO = "NO ground patch, NO floor tile, NO dirt: the ground under the passage is fully transparent. "
for _v in "bcd":  # refações (o modelo é sorteado a cada pedido)
    PEDIDOS["aberto_1" + _v] = PEDIDOS["aberto_1"] + SEMCHAO
    PEDIDOS["meio_1" + _v] = COMUM + ("A wooden log-post gate with a picket door. The two picket door leaves are swung clearly OPEN "
                                     "about 45 degrees outward, leaving a visible dark gap in the middle between the leaves. "
                                     "Only the gate, transparent background, no people, no text. ")
    PEDIDOS["quebrado_aberto" + _v] = COMUM + ("A RUINED wooden palisade gate, wrecked: the door leaves are completely gone and the "
                        "middle between the two big posts is EMPTY and open (you can see the ground and background through it), "
                        "just the two tall posts, a cracked crossbeam, broken splintered stakes and a few planks on the ground "
                        "next to the posts. " + SEMCHAO + "Only the gate, transparent background, no people, no text. ")
BASE = {"aberto_1": "nivel_1", "meio_1": "nivel_1", "aberto_2": "nivel_2", "meio_2": "nivel_2",
        "aberto_3": "nivel_3", "meio_3": "nivel_3", "quebrado_aberto": "quebrado"}
for _v in "bcd":
    BASE.update({"aberto_1" + _v: "nivel_1", "meio_1" + _v: "nivel_1", "quebrado_aberto" + _v: "quebrado"})


def _data_url(im):
    b = io.BytesIO()
    im.save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def gera(nomes):
    os.makedirs(CAND, exist_ok=True)
    itens = []
    for nome, desc in PEDIDOS.items():
        if nomes and nome not in nomes and nome.split("#")[0] not in nomes:
            continue
        base = Image.open(os.path.join(JOGO, BASE[nome] + ".png")).convert("RGBA")
        ref = _data_url(base)
        args = {"description": desc + gen.ESTILO % "dull rusty iron bands (NO glowing lights, NO fire, NO embers)",
                "width": QUADRO[0], "height": QUADRO[1], "no_background": True,
                "reference_images": [{"url": ref, "usage": "the current closed gate: same structure, angle, size and "
                                      "position on the canvas; only change the state of the door leaves"}],
                "style_image_url": ref, "style_copy": ["color_palette", "outline", "shading", "detail"]}
        itens.append((nome, "create_image_pro", args, os.path.join(CAND, nome + ".png")))
    gen.lote(itens, registro=os.path.join(AQUI, "portao98_jobs.json"), espera=20)


def escolhe(pares):
    for par in pares:
        nome, arq = par.split("=")
        f = arq if os.path.isabs(arq) else os.path.join(CAND, arq)
        if os.path.isdir(f[:-4]) and not os.path.exists(f):
            f = os.path.join(f[:-4], "c00.png")
        im = Image.open(f).convert("RGBA")
        if im.size != QUADRO:
            q = Image.new("RGBA", QUADRO)
            q.alpha_composite(im.crop((0, 0, min(im.width, QUADRO[0]), min(im.height, QUADRO[1]))), (0, 0))
            im = q
        im.save(os.path.join(AQUI, nome + ".png"))
        print("ok", nome, im.size)



def integra():
    """Copia os escolhidos pra assets/game/iso/predios/portao/ e põe os estados no predios.json (a mesma âncora, caixa e
    altura do portão fechado do mesmo nível; o quebrado_aberto leva as do quebrado). Só mexe nesses arquivos."""
    import json, shutil
    pj = os.path.join(JOGO, "..", "predios.json")
    raw = open(pj, encoding="utf-8", newline="").read()
    nl = "\r\n" if "\r\n" in raw else "\n"
    d = json.loads(raw)
    est = d["predios"]["portao"]["estados"]
    for nome, base in [("aberto_1", "nivel_1"), ("meio_1", "nivel_1"), ("aberto_2", "nivel_2"), ("meio_2", "nivel_2"),
                       ("aberto_3", "nivel_3"), ("meio_3", "nivel_3"), ("quebrado_aberto", "quebrado")]:
        f = os.path.join(AQUI, nome + ".png")
        if not os.path.exists(f):
            print("falta", nome)
            continue
        shutil.copyfile(f, os.path.join(JOGO, nome + ".png"))
        e = dict(est[base])
        e["img"] = "portao/%s.png" % nome
        est[nome] = e
        print("ok", nome, "<-", base)
    out = json.dumps(d, indent=1, ensure_ascii=False)
    open(pj, "w", encoding="utf-8", newline="").write(out.replace("\n", nl))


if __name__ == "__main__":
    if sys.argv[1] == "integra":
        integra()
    elif sys.argv[1] == "gera":
        gera(sys.argv[2:])
    elif sys.argv[1] == "escolhe":
        escolhe(sys.argv[2:])
