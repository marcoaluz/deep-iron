"""PROTÓTIPO: GIF de uma animação comum nos 18 personagens (SE em cima, NE embaixo).
  python gifs_comuns.py <anim> [<anim> ...]   -> docs/arte/prompt02/<anim>_18.gif
"""
import sys, json
from PIL import Image, ImageDraw
OUT = "../../../../docs/arte/prompt02/"
ORDEM = ["minerador", "mineradora", "guarda", "guarda_mulher", "medico", "medica", "engenheiro", "engenheira",
         "cacador", "cacadora", "pesquisador", "pesquisadora", "lenhador", "lenhadora", "civil", "civil_mulher",
         "cozinheiro", "cozinheira"]
CW, CH, S = 90, 100, 2


def quadro(p, a, d, i):
    info = json.load(open("%s/%s/anim.json" % (p, a))); n = info[d]["quadros"]; ax, ay = info[d]["ancora"]
    im = Image.open("%s/%s/%s/%d.png" % (p, a, d, i % n)).convert("RGBA")
    return im.crop((int(ax - CW / 2), int(ay - CH + 8), int(ax + CW / 2), int(ay + 8))).resize((CW * S, CH * S), Image.NEAREST)


for a in sys.argv[1:]:
    fr = []
    for i in range(8):
        c = Image.new("RGB", (9 * CW * S, 4 * (CH * S + 14)), (62, 58, 54)); d = ImageDraw.Draw(c)
        for k, p in enumerate(ORDEM):
            col = k % 9; row = (k // 9) * 2
            for r, dr in enumerate(("SE", "NE")):
                y = (row + r) * (CH * S + 14); im = quadro(p, a, dr, i); c.paste(im, (col * CW * S, y + 14), im)
                if r == 0:
                    d.text((col * CW * S + 4, y + 2), p, fill=(255, 230, 150))
        fr.append(c)
    fr[0].save(OUT + "%s_18.gif" % a, save_all=True, append_images=fr[1:], duration=140, loop=0)
    fr[-1].save(OUT + "%s_18_ultimo_quadro.png" % a)
    print(a, "ok")
