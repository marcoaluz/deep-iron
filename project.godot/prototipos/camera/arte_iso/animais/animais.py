"""PROTÓTIPO: animais (Prompt 15).

  python animais.py monta          -> final/*.png, <animal>/<anim>/{SE,NE,SO,NO}/i.png, GIFs
  python animais.py prancha <png>  -> prancha de entrega

Coelho e javali: create_character v3 (rotações) + animações v3 SE e NE (SO/NO espelho).
Tocas, carcaças, carne, couro: um lote de 16. Fauna de ambiente: lote de 64, bater de asa =
dois candidatos alternando (o lote vazou pedaços do vizinho: fica só a peça principal).
"""
import sys, os, io, json, zipfile, subprocess
from PIL import Image, ImageOps, ImageDraw
sys.path.insert(0, "../vegetacao")
from vegetacao import so_o_maior

CHARS = {"coelho": "bb9a9938-7280-4299-a004-cc0f3c8deb7e", "javali": "546ebb6a-2544-4366-8557-6762f4545080"}
ANIMS = ("andar", "fugir", "abatido")
TOCAS = {"toca_coelho_vazia": 0, "toca_coelho_fora": 1, "toca_coelho_orelhas": 2, "toca_javali": 3, "ninho": 4,
         "carcaca_coelho": 5, "carcaca_javali": 6, "carne": 7, "couro": 8, "couro_enrolado": 9}
FAUNA = {"corvo": (3, 1), "pardal": (25, 30), "morcego": (32, 34), "rato": (40, 48), "mariposa": (56, 59)}
DIRS = {"south-east": "SE", "north-east": "NE"}


def salva(im, nome):
    os.makedirs("final", exist_ok=True)
    b = im.getbbox()
    (im.crop(b) if b else im).save("final/%s.png" % nome)


def baixa_anims(nome, cid):
    raw = subprocess.run(["curl", "-s", "-f", "-A", "curl/8", "https://api.pixellab.ai/mcp/characters/%s/download" % cid],
                         check=True, capture_output=True).stdout
    z = zipfile.ZipFile(io.BytesIO(raw))
    por = {}
    for nm in z.namelist():
        p = nm.split("/")
        if len(p) >= 4 and p[-4] == "animations" and p[-3] in ANIMS and p[-2] in DIRS:
            por.setdefault((p[-3], DIRS[p[-2]]), []).append(nm)
    for (anim, d), nms in por.items():
        for e in (d, {"SE": "SO", "NE": "NO"}[d]):
            os.makedirs("%s/%s/%s" % (nome, anim, e), exist_ok=True)
        for i, nm in enumerate(sorted(nms)):
            im = Image.open(io.BytesIO(z.read(nm))).convert("RGBA")
            im.save("%s/%s/%s/%d.png" % (nome, anim, d, i))
            ImageOps.mirror(im).save("%s/%s/%s/%d.png" % (nome, anim, {"SE": "SO", "NE": "NO"}[d], i))
    return sorted(por)


def monta():
    for nome, i in TOCAS.items():
        salva(Image.open("tocas_carne/candidatos/c%02d.png" % i).convert("RGBA"), nome)
    for nome, (a, b) in FAUNA.items():
        fr = []
        for k, i in enumerate((a, b)):
            im = so_o_maior(Image.open("fauna/candidatos/c%02d.png" % i).convert("RGBA"))
            salva(im, "%s_%d" % (nome, k)); fr.append(im)
        big = [Image.new("RGBA", (96, 96), (46, 44, 40, 255)) for _ in fr]
        for g, f in zip(big, fr):
            g.alpha_composite(f.resize((72, 72), Image.NEAREST), (12, 12))
        big[0].save("final/%s.gif" % nome, save_all=True, append_images=big[1:], duration=160, loop=0)
    for nome, cid in CHARS.items():
        feitos = baixa_anims(nome, cid)
        print(nome, feitos)
        for anim in ANIMS:
            if not os.path.isdir("%s/%s/SE" % (nome, anim)):
                continue
            n = len(os.listdir("%s/%s/SE" % (nome, anim)))
            fr = []
            for i in range(n):
                g = Image.new("RGBA", (4 * 64 * 2, 64 * 2 + 14), (46, 44, 40, 255))
                for k, d in enumerate(("NO", "NE", "SO", "SE")):
                    p = "%s/%s/%s/%d.png" % (nome, anim, d, i % len(os.listdir("%s/%s/%s" % (nome, anim, d))))
                    im = Image.open(p).convert("RGBA")
                    im = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
                    g.alpha_composite(im, (k * 128 + (128 - im.width) // 2, 14 + 128 - im.height))
                fr.append(g)
            fr[0].save("final/%s_%s.gif" % (nome, anim), save_all=True, append_images=fr[1:],
                       duration=140 if anim != "abatido" else 220, loop=0)
    print("ok")


def prancha(saida):
    AM = (255, 230, 150)
    c = Image.new("RGB", (1200, 560), (46, 44, 40)); d = ImageDraw.Draw(c)
    y = 6
    for nome in CHARS:
        d.text((8, y), "%s: rotacoes (8) + quadros de andar / fugir / abatido (SE)" % nome.upper(), fill=AM); y += 14
        x = 8
        for dr in ("south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"):
            im = Image.open("%s/rotacoes/%s.png" % (nome, dr)).convert("RGBA"); im = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
            c.paste(im, (x, y), im); x += im.width + 2
        x += 20
        for anim in ANIMS:
            p = "%s/%s/SE" % (nome, anim)
            if os.path.isdir(p):
                for i in range(len(os.listdir(p))):
                    im = Image.open("%s/%d.png" % (p, i)).convert("RGBA"); im = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
                    c.paste(im, (x, y), im); x += im.width - 20
                x += 30
        y += 110
    d.text((8, y), "TOCAS, NINHO, CARCACAS (sem sangue), CARNE, COURO", fill=AM); y += 14
    x = 8
    for nome in TOCAS:
        im = Image.open("final/%s.png" % nome).convert("RGBA"); im = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
        c.paste(im, (x, y), im); x += im.width + 6
    y += 110
    d.text((8, y), "FAUNA DE AMBIENTE (2 quadros cada): corvo, pardal, morcego, rato, mariposa", fill=AM); y += 14
    x = 8
    for nome in FAUNA:
        for k in range(2):
            im = Image.open("final/%s_%d.png" % (nome, k)).convert("RGBA"); im = im.resize((im.width * 3, im.height * 3), Image.NEAREST)
            c.paste(im, (x, y), im); x += im.width + 6
        x += 14
    c.save(saida)


if __name__ == "__main__":
    monta() if sys.argv[1] == "monta" else prancha(sys.argv[2])
