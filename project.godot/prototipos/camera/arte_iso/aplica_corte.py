"""PROTÓTIPO: aplica o corte de altura (encolhe.CORTE) num personagem já processado.
Guarda os originais em <pasta>/_original/ (e não aplica duas vezes).

  python aplica_corte.py <pasta> [<pasta> ...]
"""
import sys, os, json, shutil, math
from PIL import Image, ImageOps, ImageDraw
import encolhe


def corta_pasta_quadros(pasta_q, pe_y, ls):
    for f in sorted(os.listdir(pasta_q)):
        if f.endswith(".png"):
            p = os.path.join(pasta_q, f)
            encolhe.encolhe(Image.open(p), pe_y, ls).save(p)


def aplica(pasta):
    n = encolhe.CORTE[pasta]
    ls = encolhe.linhas(n)
    orig = os.path.join(pasta, "_original")
    if os.path.exists(orig):
        print(pasta, "já cortado"); return
    os.makedirs(orig)
    for item in ("rotacoes", "caminhada", "contrato.json", "prancha_8_direcoes_iso.png", "caminhada_4dir.gif", "tons_de_pele.png"):
        src = os.path.join(pasta, item)
        if os.path.isdir(src):
            shutil.copytree(src, os.path.join(orig, item))
        elif os.path.exists(src):
            shutil.copy2(src, os.path.join(orig, item))
    # paradas: pé = base do desenho de cada pose
    for f in os.listdir(os.path.join(pasta, "rotacoes")):
        if f.endswith(".png"):
            p = os.path.join(pasta, "rotacoes", f)
            im = Image.open(p)
            encolhe.encolhe(im, encolhe.pe_de(im), ls).save(p)
    # caminhada: pé = âncora da direção (a mesma nos 4 quadros)
    c = json.load(open(os.path.join(pasta, "contrato.json")))
    for d in ("SE", "NE", "SO", "NO"):
        corta_pasta_quadros(os.path.join(pasta, "caminhada", d), int(c["direcoes"][d]["ancora"][1]), ls)
    c["caixa"][2] -= n
    c["corte_altura"] = {"linhas": n, "acima_do_pe": ls}
    json.dump(c, open(os.path.join(pasta, "contrato.json"), "w"), indent=1)
    # prancha e gif de novo
    DIRS = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
    S = 4; W = 48 * S + 30
    g = Image.new("RGBA", (8 * W, 84 * S + 60), (90, 90, 100, 255)); dd = ImageDraw.Draw(g)
    for i, nm in enumerate(DIRS):
        im = Image.open(os.path.join(pasta, "rotacoes", nm + ".png")).convert("RGBA")
        b = im.resize((im.width * S, im.height * S), Image.NEAREST); g.paste(b, (i * W + 15, 40), b)
        dd.text((i * W + 15, 8), nm, fill=(255, 255, 0))
    g.save(os.path.join(pasta, "prancha_8_direcoes_iso.png"))
    gif = []
    for i in range(4):
        cv = Image.new("RGB", (4 * 336, 356), (80, 80, 92)); d2 = ImageDraw.Draw(cv)
        for k, nm in enumerate(("NO", "NE", "SO", "SE")):
            f = Image.open(os.path.join(pasta, "caminhada", nm, "%d.png" % i)).convert("RGBA").resize((336, 336), Image.NEAREST)
            cv.paste(f, (k * 336, 20), f); d2.text((k * 336 + 6, 4), nm, fill=(255, 230, 120))
        gif.append(cv)
    gif[0].save(os.path.join(pasta, "caminhada_4dir.gif"), save_all=True, append_images=gif[1:], duration=160, loop=0)
    print(pasta, "cortado", n, "linhas")


if __name__ == "__main__":
    for p in sys.argv[1:]:
        aplica(p)
