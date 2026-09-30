"""PROTÓTIPO: folha de revisão e GIF das animações do robô gigante (Prompt 5).
  python folha_robo.py <anim> [<anim> ...]
-> <anim>_folha.png (SE em cima, NE embaixo, recortado na âncora) e <anim>_4dir.gif
O trabalho.py faz a limpeza/espelho/anim.json; as folhas dele são do tamanho de um humano.
"""
import sys, json
from PIL import Image, ImageDraw

CW, CH = 220, 250          # caixa de recorte: o robô tem ~218 px em pé


def quadro(anim, d, i, anc):
    im = Image.open("%s/%s/%d.png" % (anim, d, i)).convert("RGBA")
    return im.crop((int(anc[0] - CW / 2), int(anc[1] - CH + 8), int(anc[0] + CW / 2), int(anc[1] + 8)))


for anim in sys.argv[1:]:
    js = json.load(open("%s/anim.json" % anim))
    n = js["SE"]["quadros"]
    folha = Image.new("RGB", (n * CW, 2 * CH), (74, 74, 86))
    for r, d in enumerate(("SE", "NE")):
        for i in range(n):
            q = quadro(anim, d, i, js[d]["ancora"]); folha.paste(q, (i * CW, r * CH), q)
    folha.save("%s_folha.png" % anim)
    quadros = []
    for i in range(n):
        c = Image.new("RGB", (4 * CW, CH + 14), (74, 74, 86)); dr = ImageDraw.Draw(c)
        for k, d in enumerate(("NO", "NE", "SO", "SE")):
            q = quadro(anim, d, i % js[d]["quadros"], js[d]["ancora"]); c.paste(q, (k * CW, 14), q)
            dr.text((k * CW + 4, 2), d, fill=(255, 230, 150))
        quadros.append(c)
    quadros[0].save("%s_4dir.gif" % anim, save_all=True, append_images=quadros[1:], duration=130, loop=0)
    print(anim, n)
