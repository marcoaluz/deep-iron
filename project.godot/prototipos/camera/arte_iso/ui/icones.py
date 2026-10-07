"""Prompt 21: junta os ícones do jogo em assets/game/ui/icones/ (32 px, o tamanho base) e as
versões de 24 px (barra de recursos do topo), os botões de velocidade (por script), os ícones
de ferramenta/arma/traje que já existiam (itens/icones, Prompt 3-4) e os prédios do menu de
construção como RENDER REDUZIDO da arte pronta (sem gerar de novo).

  python ui/icones.py   -> assets/game/ui/icones/*.png + icones.json + folha_icones.png (docs)
"""
import os, json, glob, shutil
import numpy as np
from PIL import Image, ImageFilter, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(AQUI, "../../../.."))
DEST = os.path.join(RAIZ, "assets/game/ui/icones")
os.makedirs(DEST, exist_ok=True)
os.makedirs(os.path.join(DEST, "p24"), exist_ok=True)
os.makedirs(os.path.join(DEST, "predios"), exist_ok=True)
GER = os.path.join(AQUI, "icones")
ITENS = os.path.join(AQUI, "../itens/icones")
AMBAR = (255, 196, 92, 255)
ESCURO = (40, 26, 12, 255)
out = {"_obs": "Prompt 21 (ui/icones.py): nome -> arquivo (32 px) | p24/<nome> (24 px) | predios/<nome> (render reduzido)",
       "icones": [], "predios": []}


def limpa(im):
    """Alfa duro (pixel art: sem meio-transparente) e corta no desenho."""
    a = np.array(im.convert("RGBA"))
    a[..., 3] = np.where(a[..., 3] >= 110, 255, 0)
    im = Image.fromarray(a, "RGBA")
    bb = im.getbbox()
    return im.crop(bb) if bb else im


def quadrado(im, lado):
    """Cabe no quadrado (sem ampliar mais que inteiro; reduz com reamostragem boa) e centra."""
    w, h = im.size
    if max(w, h) > lado:
        k = lado / max(w, h)
        im = im.resize((max(1, round(w * k)), max(1, round(h * k))), Image.LANCZOS)
        im = limpa(im)
    q = Image.new("RGBA", (lado, lado))
    q.alpha_composite(im, ((lado - im.width) // 2, (lado - im.height) // 2))
    return q


def salva(nome, im):
    im32 = quadrado(limpa(im), 32)
    im32.save(os.path.join(DEST, nome + ".png"))
    im24 = quadrado(limpa(im32), 24)
    im24.save(os.path.join(DEST, "p24", nome + ".png"))
    out["icones"].append(nome)


# 1) os gerados (pixen), menos os 16 px (vão como estão: ícone sobre a cabeça)
for f in sorted(glob.glob(os.path.join(GER, "*.png"))):
    nome = os.path.basename(f)[:-4]
    if nome.startswith("p_"):
        im = limpa(Image.open(f))
        q = Image.new("RGBA", (16, 16)); q.alpha_composite(im, ((16 - im.width) // 2, (16 - im.height) // 2))
        q.save(os.path.join(DEST, nome + ".png"))
        out["icones"].append(nome)
        continue
    salva(nome, Image.open(f))
# 2) ferramentas, armas, trajes e o robô (já existiam: Prompts 3, 4, 5)
def clareia(im, k=2.0):
    """As ferramentas são cinza-escuro (feitas pro chão): no painel escuro precisam de mais luz."""
    a = np.array(im.convert("RGBA")).astype(np.float32)
    a[..., :3] = np.clip(a[..., :3] * k + 10, 0, 255)
    return Image.fromarray(a.astype(np.uint8), "RGBA")


for f in sorted(glob.glob(os.path.join(ITENS, "*.png"))):
    nome = "it_" + os.path.basename(f)[:-4]
    im = Image.open(f)
    salva(nome, im if "traje" in nome or "casaco" in nome or "robo" in nome else clareia(im))
shutil.copyfile(os.path.join(DEST, "it_arco.png"), os.path.join(DEST, "cacador.png"))  # caçador = o arco (o gerado era um bonequinho)
shutil.copyfile(os.path.join(DEST, "p24", "it_arco.png"), os.path.join(DEST, "p24", "cacador.png"))
# 3) zanga pequena e velocidade (por script)
# a "veia de zanga" (4 cantinhos curvos virados pra dentro), pixel a pixel
z = np.zeros((16, 16, 4), np.uint8)
canto = [(1, 4), (1, 5), (2, 3), (2, 5), (3, 2), (3, 5), (4, 1), (4, 2), (4, 3), (4, 4), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5)]
for (y, x) in canto:
    for (yy, xx) in [(y, x), (y, 15 - x), (15 - y, x), (15 - y, 15 - x)]:
        z[yy, xx] = (225, 55, 40, 255)
for y in range(16):
    for x in range(16):
        if z[y, x, 3] == 0 and any(0 <= y + dy < 16 and 0 <= x + dx < 16 and z[y + dy, x + dx, 0] == 225 for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            z[y, x] = (50, 10, 8, 255)
Image.fromarray(z, "RGBA").save(os.path.join(DEST, "p_zanga.png"))


def velocidade(n, pausa=False):
    im = Image.new("RGBA", (24, 24)); d = ImageDraw.Draw(im)
    if pausa:
        for x in (7, 14):
            d.rectangle((x, 6, x + 3, 17), fill=ESCURO); d.rectangle((x - 1, 5, x + 2, 16), fill=AMBAR)
    else:
        w = 7 if n > 1 else 9
        x0 = 12 - (w * n + 1 * (n - 1)) // 2
        for k in range(n):
            x = x0 + k * (w + 1)
            d.polygon([(x + 1, 6), (x + 1, 18), (x + w + 1, 12)], fill=ESCURO)
            d.polygon([(x, 5), (x, 17), (x + w, 11)], fill=AMBAR)
    return im


for nome, im in [("vel_pausa", velocidade(0, True)), ("vel_1", velocidade(1)), ("vel_2", velocidade(2)), ("vel_3", velocidade(3))]:
    im.save(os.path.join(DEST, nome + ".png"))
    out["icones"].append(nome)
# 4) prédios do menu de construção: render reduzido do desenho pronto (cabe em 96 x 64)
P = os.path.join(RAIZ, "assets/game/iso/predios")
pj = json.load(open(os.path.join(P, "predios.json"), encoding="utf-8"))["predios"]
MENU = {"casa": "casa/pronto_0", "comedouro": "comedouro/pronto", "enfermaria": "enfermaria/pronto", "taverna": "taverna/pronto",
        "parque": "parque/pronto", "laboratorio": "laboratorio/pronto", "arsenal": "arsenal/pronto", "campo_treino": "campo_treino/pronto",
        "vestiario": "vestiario/pronto", "oficina": "oficina/pronto", "coletor_madeira": "coletor_madeira/pronto",
        "centro_vila": "centro_3/pronto", "escudo": "escudo/etapa_4", "armazem": "armazem/pronto", "escavadeira": "escavadeira/pronto",
        "fornalha": "fornalha/pronto", "igreja": "igreja/pronto",  # Bloco 92 (o cemitério, Bloco 93: o desenho de referência)
        "carpintaria": "carpintaria/pronto"}  # Bloco 94
for nome, st in MENU.items():
    pr, e = st.split("/")
    info = pj.get(pr, {}).get("estados", {}).get(e)
    if not info:
        print("  sem desenho:", nome, st)
        continue
    im = limpa(Image.open(os.path.join(P, info["img"])))
    k = min(96 / im.width, 64 / im.height)
    r = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
    r = r.filter(ImageFilter.UnsharpMask(radius=1, percent=60, threshold=2))
    r = limpa(r)
    q = Image.new("RGBA", (96, 64)); q.alpha_composite(r, ((96 - r.width) // 2, 64 - r.height))
    q.save(os.path.join(DEST, "predios", nome + ".png"))
    out["predios"].append(nome)
json.dump(out, open(os.path.join(DEST, "icones.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
# 5) a folha de ícones (docs)
nomes = [n for n in out["icones"]]
Z = 2; C = 32 * Z + 10; cols = 12
rows = (len(nomes) + cols - 1) // cols
folha = Image.new("RGBA", (cols * C, rows * (C + 12) + 150), (46, 42, 38, 255)); dr = ImageDraw.Draw(folha)
for i, n in enumerate(nomes):
    im = Image.open(os.path.join(DEST, n + ".png")).convert("RGBA")
    z = Z * (2 if im.width == 16 else 1) if im.width <= 32 else Z
    im = im.resize((im.width * z, im.height * z), Image.NEAREST)
    x, y = (i % cols) * C, (i // cols) * (C + 12)
    folha.alpha_composite(im, (x + 5, y + 12)); dr.text((x + 2, y), n[:12], fill=(255, 230, 140, 255))
y0 = rows * (C + 12) + 6
for i, n in enumerate(out["predios"]):
    im = Image.open(os.path.join(DEST, "predios", n + ".png")).convert("RGBA")
    folha.alpha_composite(im, (6 + (i % 8) * 100, y0 + (i // 8) * 72))
docs = os.path.join(RAIZ, "..", "docs", "arte", "prompt21")
os.makedirs(docs, exist_ok=True)
folha.save(os.path.join(docs, "folha_icones.png"))
print("ícones:", len(out["icones"]), "| prédios:", len(out["predios"]))
