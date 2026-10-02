"""Prompt 25: peças da tela "Corte da mina" -> assets/game/ui/corte/.
  faixas (superfície, mina/vila, nível 2, abismo; pixen), escavadeira e gaiola de lado, e os
  mini-bonecos (o boneco parado de frente de cada pasta, reduzido à metade)."""
import os, json
import numpy as np
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(AQUI, "../../../.."))
DEST = os.path.join(RAIZ, "assets/game/ui/corte")
os.makedirs(DEST, exist_ok=True)
for f in ["faixa_superficie", "faixa_mina", "faixa_nivel2", "faixa_abismo", "escavadeira_lado", "gaiola_lado"]:
    im = Image.open(os.path.join(AQUI, f + ".png")).convert("RGBA")
    if f.startswith("faixa"):  # sem buraco transparente (o abismo veio com um canto vazio)
        bg = Image.new("RGBA", im.size, (12, 10, 10, 255))
        bg.alpha_composite(im)
        im = bg
    else:
        im = im.crop(im.getbbox())
    im.save(os.path.join(DEST, f + ".png"))
bj = json.load(open(os.path.join(RAIZ, "assets/game/iso/bonecos/bonecos.json"), encoding="utf-8"))
n = 0
for pasta, info in bj["pastas"].items():
    p = info["anims"].get("parado", {}).get("SE")
    if not p or pasta.startswith(("casaco_", "traje_")):
        continue
    w, h = p["quadro"]
    for tom in [""] + ["__" + t for t in bj.get("tons", [])]:
        f = os.path.join(RAIZ, "assets/game/iso/bonecos", p["img"][:-4] + tom + ".png")
        if not os.path.exists(f):
            continue
        q = Image.open(f).convert("RGBA").crop((0, 0, w, h))
        q = q.crop(q.getbbox())
        r = q.resize((max(1, q.width // 2), max(1, q.height // 2)), Image.LANCZOS)
        a = np.array(r); a[..., 3] = np.where(a[..., 3] > 100, 255, 0)
        Image.fromarray(a, "RGBA").save(os.path.join(DEST, "mini_%s%s.png" % (pasta, tom)))
        n += 1
print("corte:", n, "mini-bonecos")
