"""Prompt 23: retratos (painel do ipezinho selecionado e eventos).

  python retratos/retratos.py expressoes   -> pede as 4 expressões de cada retrato (edit_image_pixen, 1 cada)
  python retratos/retratos.py exporta      -> assets/game/ui/retratos/<pasta>/<expressão>__<tom>.png + retratos.json

base/<pasta>.png = o retrato neutro (create_portrait_character a partir do boneco de frente).
As 3 peles: a mesma regra de paleta dos bonecos (tons_de_pele.py), com a faixa do rosto do retrato.
"""
import os, sys, json, base64, io
import numpy as np
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(AQUI))
sys.path.insert(0, os.path.normpath(os.path.join(AQUI, "../../../../../tools/pixellab")))
BASE = os.path.join(AQUI, "base")
EXPR = os.path.join(AQUI, "expressoes")
DEST = os.path.normpath(os.path.join(AQUI, "../../../../assets/game/ui/retratos"))
EXPRESSOES = {
    "contente": "same character, now smiling warmly with a happy expression; keep the face, hair, helmet/hat, clothes, colors and framing identical",
    "cansado": "same character, tired and sad: droopy half-closed eyes, sad mouth, a drop of sweat; keep the face, hair, helmet/hat, clothes, colors and framing identical",
    "bravo": "same character, angry: furrowed brows, gritted teeth, shouting in protest; keep the face, hair, helmet/hat, clothes, colors and framing identical",
    "ferido": "same character, injured: a white bandage wrapped around the head and a small plaster on the cheek, pained expression; keep the face, hair, clothes, colors and framing identical",
}
CRIATURAS = ("lumivoro", "ferrugento")
## Bloco 92: nota por personagem somada à frase padrão (a frase fala em "helmet/hat" e o modelo INVENTAVA chapéu
## em quem não usa: o ferreiro careca ganhou capacete, o padre um solidéu)
NOTA = {"ferreiro": " He is BALD: no hat, no helmet, no cap on his bald head.",
        "padre": " He has short grey hair and round glasses: keep the glasses; no hat, no cap, no skullcap on his head.",
        # Bloco 94
        "carpinteiro": " He wears a flat brown cloth cap: keep exactly this flat cap; no helmet, no headlamp. He has a thick dark MOUSTACHE: keep the moustache exactly.",
        "carpinteira": " She wears a pale grey-brown cloth kerchief over her hair: keep exactly this kerchief and its pale grey-brown color; no helmet, no hat, no scarf around the neck.",
        # Bloco 104
        "batedor": " He wears a wide-brimmed brown leather bush hat and a dark green cloak: keep exactly this hat and the stubble; no helmet, no headlamp.",
        "batedora": " She has NO hat: dark brown hair and the dark green hood DOWN on her shoulders; keep the hood and the hair exactly; no helmet, no hat, no cap.",
        # Bloco 105
        "carregador": " He wears a faded indigo-blue knitted beanie and has a short dark beard: keep exactly this beanie and the beard; the wooden carrying frame on his back stays; no helmet, no headlamp."}


def expressoes():
    import gen
    gen.MAX = 6
    itens = []
    for f in sorted(os.listdir(BASE)):
        if not f.endswith(".png"):
            continue
        nome = f[:-4]
        if nome in CRIATURAS:
            continue
        raw = open(os.path.join(BASE, f), "rb").read()
        for e, d in EXPRESSOES.items():
            itens.append(("%s_%s" % (nome, e), "edit_image_pixen", {"image_base64": base64.b64encode(raw).decode(), "description": d + NOTA.get(nome, "")},
                          os.path.join(EXPR, nome, e + ".png")))
    gen.lote(itens, registro=os.path.join(EXPR, "jobs.json"))


# ---- pele por paleta (a regra do tons_de_pele.py; o rosto do retrato ocupa o meio do quadro)
import tons_de_pele as tp
from integra import _hls


def recolor(a, rampa):
    al = a[..., 3] > 40
    ys, xs = np.nonzero(al)
    if len(ys) == 0:
        return a
    h, l, s = _hls(a[..., :3].astype(float))
    r, g, b = [a[..., k].astype(int) for k in range(3)]
    H = a.shape[0]
    band = np.zeros_like(al)
    band[int(H * 0.12):int(H * 0.78), :] = True
    skin = al & band & (h <= 0.11) & (l >= 0.16) & (l <= 0.85) & (s >= 0.15) & (s <= 0.75) & (r > g) & (g > b)
    if not skin.any():
        return a
    lo, hi = tp.LUM_PELE
    out = a.copy()
    t = np.clip((l[skin] - lo) / (hi - lo), 0, 1)
    i = t * (len(rampa) - 1)
    i0 = np.floor(i).astype(int)
    i1 = np.minimum(i0 + 1, len(rampa) - 1)
    f = (i - i0)[:, None]
    R = np.array(rampa, float)
    out[skin, :3] = np.round(R[i0] + (R[i1] - R[i0]) * f).astype(np.uint8)
    return out


def exporta(so=None):
    """so (Bloco 92): só esses retratos, juntados ao retratos.json que já existe (sem regravar os outros)."""
    os.makedirs(DEST, exist_ok=True)
    info = {"_obs": "Prompt 23 (retratos/retratos.py): pasta -> expressão -> arquivo por tom de pele (tons_de_pele.RAMPAS); criaturas sem tom",
            "tons": list(tp.RAMPAS.keys()), "expressoes": ["neutro"] + list(EXPRESSOES), "retratos": {}}
    for f in sorted(os.listdir(BASE)):
        if not f.endswith(".png"):
            continue
        nome = f[:-4]
        if so and nome not in so:
            continue
        os.makedirs(os.path.join(DEST, nome), exist_ok=True)
        fontes = {"neutro": os.path.join(BASE, f)}
        for e in EXPRESSOES:
            p = os.path.join(EXPR, nome, e + ".png")
            if os.path.exists(p):
                fontes[e] = p
        d = {}
        for e, p in fontes.items():
            a = np.array(Image.open(p).convert("RGBA"))
            if nome in CRIATURAS:
                Image.fromarray(a, "RGBA").save(os.path.join(DEST, nome, e + ".png"))
                d[e] = "%s/%s.png" % (nome, e)
                continue
            for tom, rampa in tp.RAMPAS.items():
                Image.fromarray(recolor(a, rampa), "RGBA").save(os.path.join(DEST, nome, "%s__%s.png" % (e, tom)))
            d[e] = "%s/%s" % (nome, e)
        info["retratos"][nome] = d
    if so and os.path.exists(os.path.join(DEST, "retratos.json")):
        velho = json.load(open(os.path.join(DEST, "retratos.json"), encoding="utf-8"))
        velho["retratos"].update(info["retratos"])
        info = velho
    json.dump(info, open(os.path.join(DEST, "retratos.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("retratos:", len(info["retratos"]))


if __name__ == "__main__":
    if sys.argv[1] == "exporta" and len(sys.argv) > 2:
        exporta(sys.argv[2:])
    else:
        {"expressoes": expressoes, "exporta": exporta}[sys.argv[1]]()
