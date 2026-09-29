"""PROTÓTIPO: uma linha por personagem com os 4 quadros SE + 4 NE, recortados na âncora.
  python folha_caminhadas.py <saida.png> <pasta> [<pasta> ...]
"""
import sys, json
from PIL import Image, ImageDraw
S = 3
CW, CH = 44, 90          # recorte em volta da âncora (px do sprite)
out, pastas = sys.argv[1], sys.argv[2:]
g = Image.new("RGBA", (110 + 8 * CW * S, len(pastas) * CH * S), (90, 90, 100, 255))
d = ImageDraw.Draw(g)
for r, p in enumerate(pastas):
    c = json.load(open(p + "/contrato.json"))
    d.text((4, r * CH * S + 4), "%s\n%s" % (p, "x".join(map(str, c["caixa"]))), fill=(255, 230, 120))
    k = 0
    for dr in ("SE", "NE"):
        ax, ay = c["direcoes"][dr]["ancora"]
        for i in range(4):
            im = Image.open("%s/caminhada/%s/%d.png" % (p, dr, i)).convert("RGBA")
            im = im.crop((int(ax - CW / 2), int(ay - CH + 6), int(ax + CW / 2), int(ay + 6)))
            im = im.resize((CW * S, CH * S), Image.NEAREST)
            g.paste(im, (110 + k * CW * S, r * CH * S), im)
            k += 1
g.save(out)
