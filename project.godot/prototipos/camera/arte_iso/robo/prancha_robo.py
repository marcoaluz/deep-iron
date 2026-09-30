"""PROTÓTIPO: entregas do Prompt 5 (robô gigante).
  python prancha_robo.py <pasta_docs>
-> prancha_robo.png  (escala com a casa e o minerador; 8 direções; estados parados; retrato e ícone)
   robo_estados.gif  (achado -> arrastado -> conserto 1-3 -> em pé, no mesmo lugar)
   robo_animacoes.gif (andar, atacar, dano, desligar: SE e NE)
"""
import sys, os, json
from PIL import Image, ImageDraw

out = sys.argv[1]
FUNDO = (62, 58, 54)
AMAR = (255, 230, 150)


def t(p):
    i = Image.open(p).convert("RGBA"); return i.crop(i.getbbox())


def cola(c, im, x, y_base):
    c.paste(im, (x, y_base - im.height), im)


# ---------------------------------------------------------------- prancha
W = 1500
c = Image.new("RGB", (W, 850), FUNDO); d = ImageDraw.Draw(c)
d.text((10, 6), "ESCALA: casa 270 px | robo 218 px | minerador 74 px", fill=AMAR)
x = 10
for p in ("../casa/casa_v0.png", "../minerador/rotacoes/south-east.png", "rotacoes/south-east.png"):
    im = t(p); cola(c, im, x, 300); x += im.width + 20
d.text((x + 10, 6), "8 DIRECOES (no jogo: SE e NE desenhadas, SO/NO espelho)", fill=AMAR)
for k, dr in enumerate(("south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west")):
    im = t("rotacoes/%s.png" % dr)
    im = im.resize((im.width // 2, im.height // 2), Image.NEAREST)
    cola(c, im, x + 10 + k * 96, 150)
    d.text((x + 10 + k * 96, 154), dr, fill=(200, 200, 200))
d.text((x + 10, 170), "RETRATO (96 px, aqui 1,5x) e ICONE (32 px, 3x e 1x)", fill=AMAR)
r = Image.open("retrato.png").convert("RGBA").resize((144, 144), Image.NEAREST); c.paste(r, (x + 10, 186), r)
ic = Image.open("icone.png").convert("RGBA").resize((96, 96), Image.NEAREST); c.paste(ic, (x + 170, 186), ic)
ic1 = Image.open("icone.png").convert("RGBA"); c.paste(ic1, (x + 280, 186), ic1)
d.text((10, 316), "ESTADOS PARADOS (mesmo quadro 288x216 e mesma ancora; aqui a 5/6 do tamanho)", fill=AMAR)
for k, (f, rot) in enumerate((("achado", "achado (exploracao)"), ("arrastado", "arrastado (5 NPCs)"), ("conserto_1", "estagio 1"), ("conserto_2", "estagio 2"), ("conserto_3", "estagio 3"))):
    im = Image.open("estados/%s.png" % f).convert("RGBA")
    im = im.resize((im.width * 5 // 6, im.height * 5 // 6), Image.NEAREST)  # só na prancha
    c.paste(im, (10 + k * 244, 336), im); d.text((10 + k * 244, 556), rot, fill=(200, 200, 200))
d.text((10, 580), "ANIMACOES (um quadro de cada, SE)", fill=AMAR)
for k, a in enumerate(("caminhada", "atacar", "dano", "desligar")):
    js = json.load(open("%s/anim.json" % a)); n = js["SE"]["quadros"]
    im = t("%s/SE/%d.png" % (a, n // 2 if a != "desligar" else n - 1))
    cola(c, im, 10 + k * 260, 840); d.text((10 + k * 260, 600), "%s (%d quadros)" % (a, n), fill=(200, 200, 200))
c.save(os.path.join(out, "prancha_robo.png"))

# ---------------------------------------------------------------- GIF dos estados
fr = []
for f in ("achado", "arrastado", "conserto_1", "conserto_2", "conserto_3"):
    g = Image.new("RGB", (288 * 2, 216 * 2 + 20), FUNDO); dd = ImageDraw.Draw(g)
    im = Image.open("estados/%s.png" % f).convert("RGBA").resize((576, 432), Image.NEAREST)
    g.paste(im, (0, 20), im); dd.text((6, 4), f, fill=AMAR); fr.append(g)
g = Image.new("RGB", (576, 452), FUNDO); dd = ImageDraw.Draw(g)
im = t("rotacoes/south-east.png")
g.paste(im, ((576 - im.width) // 2, 440 - im.height), im); dd.text((6, 4), "ativo (em pe)", fill=AMAR); fr.append(g)
fr[0].save(os.path.join(out, "robo_estados.gif"), save_all=True, append_images=fr[1:], duration=900, loop=0)

# ---------------------------------------------------------------- GIF das animações
CW, CH = 220, 250
anims = ("caminhada", "atacar", "dano", "desligar")
js = {a: json.load(open("%s/anim.json" % a)) for a in anims}
n = max(v["SE"]["quadros"] for v in js.values())
fr = []
for i in range(n):
    g = Image.new("RGB", (len(anims) * CW, 2 * CH + 16), FUNDO); dd = ImageDraw.Draw(g)
    for k, a in enumerate(anims):
        dd.text((k * CW + 4, 2), a, fill=AMAR)
        for r_, dr in enumerate(("SE", "NE")):
            q = js[a][dr]; ax, ay = q["ancora"]
            # desligar não repete: fica no último quadro
            j = min(i, q["quadros"] - 1) if a == "desligar" else i % q["quadros"]
            im = Image.open("%s/%s/%d.png" % (a, dr, j)).convert("RGBA")
            im = im.crop((int(ax - CW / 2), int(ay - CH + 8), int(ax + CW / 2), int(ay + 8)))
            g.paste(im, (k * CW, 16 + r_ * CH), im)
    fr.append(g)
fr[0].save(os.path.join(out, "robo_animacoes.gif"), save_all=True, append_images=fr[1:], duration=150, loop=0)
print("ok")
