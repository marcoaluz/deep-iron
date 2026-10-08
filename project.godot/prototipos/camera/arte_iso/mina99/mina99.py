"""Bloco 99: a arte da ENTRADA DA MINA (PixelLab, create_image_pro), a partir da arte aprovada que já existe.

  python mina99.py gera [nome ...]       -> candidatos em mina99/_cand/<nome>.png
  python mina99.py escolhe nome=arq ...  -> mina99/<nome>.png (no quadro da referência)
  python mina99.py integra               -> copia pros assets e põe os estados no predios.json / props.json

Pedidos:
  elev_obra_1 / elev_obra_2 — a torre do elevador do S2 entre a ruína e o pronto (a evolução da restauração: limpar o
                              poço; guincho e cabos), quadro 210x320 com a mesma âncora (105, 265) da ruína e do pronto;
  cabine_vazia / cabine_cheia — a cabine que anda pelo poço (a gaiola de 58x88, âncora 29,85), vazia e com mineiros;
  vagonete_grande_SE / _SO  — o vagonete com a carga grande (o monte de minério), 40x41, âncora 20,38;
  lanterna_boca             — o lampião pendurado num poste com as picaretas encostadas, na boca da mina quando tem
                              gente lá dentro (40x64, âncora 20,60).
Os candidatos não escolhidos ficam fora do repositório (_cand/ tem .gitignore); os ids ficam em mina99_jobs.json.
"""
import sys, os, base64, io, json, shutil
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import gen
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
ISO = os.path.join(AQUI, "..", "..", "..", "..", "assets", "game", "iso")
CAND = os.path.join(AQUI, "_cand")
SO = "Only the object, transparent background, no people unless asked, no text. "
PEDIDOS = {
    "elev_obra_1": ((210, 320), ["predios/elevador/ruina.png", "predios/elevador/pronto.png"],
        "Isometric 2:1 pixel art, the SAME mine elevator headframe tower as the references, same camera angle, canvas, "
        "base position and footprint. RESTORATION STAGE 1 of 3: the ruined wooden headframe has been CLEANED: the rubble, "
        "fallen planks and weeds are gone, the square shaft opening in the ground is clear with a new plank railing, a few "
        "new beams are propped and tied with rope on the old tower, a pile of fresh planks on the ground; there is NO cage "
        "and NO winch yet, the top pulley wheel is still missing. Weathered dark wood, rusty iron brackets. " + SO),
    "elev_obra_2": ((210, 320), ["predios/elevador/pronto.png", "predios/elevador/ruina.png"],
        "Isometric 2:1 pixel art, the SAME mine elevator headframe tower as the references, same camera angle, canvas, "
        "base position and footprint. RESTORATION STAGE 2 of 3: the tower is repaired with new beams and iron braces, the "
        "big pulley wheel is back on top and the WINCH machine with its cable drum stands beside the shaft, steel cables "
        "run from the drum over the wheel down into the shaft opening, but there is NO elevator cage yet (the shaft is "
        "open and dark). A railing around the shaft. Weathered dark wood, rusty iron. " + SO),
    "cabine_vazia": ((58, 88), ["predios/gaiola/gaiola.png"],
        "Isometric 2:1 pixel art, the SAME small mine elevator cage as the reference (same angle, size, canvas and base), "
        "an iron-barred cage with a wooden floor and a roof hook for the cable, the cable going up out of the top of the "
        "canvas, a small lit lantern hanging inside, EMPTY (nobody inside). Dark rusty iron. " + SO),
    "cabine_cheia": ((58, 88), ["predios/gaiola/gaiola.png"],
        "Isometric 2:1 pixel art, the SAME small mine elevator cage as the reference (same angle, size, canvas and base), "
        "an iron-barred cage with a wooden floor, the cable going up out of the top of the canvas, a small lit lantern, "
        "with THREE tiny miners standing inside behind the bars (helmets with head lamps, seen as small dark figures). "
        "Dark rusty iron. Only the cage and the miners inside, transparent background, no text. "),
    "vagonete_grande_SE": ((40, 41), ["props/vagonete_cheio_SE.png"],
        "Isometric 2:1 pixel art, the SAME mine cart as the reference (same angle, size, wheels and position on the "
        "canvas), loaded with a BIG HEAPED PILE of ore chunks overflowing above the rim (iron ore, a few copper bits). " + SO),
    "vagonete_grande_SO": ((40, 41), ["props/vagonete_cheio_SO.png"],
        "Isometric 2:1 pixel art, the SAME mine cart as the reference (same angle, size, wheels and position on the "
        "canvas), loaded with a BIG HEAPED PILE of ore chunks overflowing above the rim (iron ore, a few copper bits). " + SO),
    "lanterna_boca": ((40, 64), ["props/boca_tunel.png", "props/vagonete_cheio_SE.png"],
        "Isometric 2:1 pixel art in the style of the references: a short wooden post with an iron hook and a LIT miner's "
        "oil lantern hanging from it (warm orange glow), two pickaxes leaning against the post and a small sack of ore at "
        "its foot. Small prop that stands at a mine entrance. Weathered dark wood. " + SO),
}
for _v in "bc":  # refações (o modelo é sorteado a cada pedido)
    for _n in ["elev_obra_1", "elev_obra_2", "cabine_cheia"]:
        PEDIDOS[_n + _v] = PEDIDOS[_n]


def _data_url(im):
    b = io.BytesIO()
    im.save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def gera(nomes):
    os.makedirs(CAND, exist_ok=True)
    itens = []
    for nome, (quadro, refs, desc) in PEDIDOS.items():
        if nomes and nome not in nomes:
            continue
        ims = [Image.open(os.path.join(ISO, r)).convert("RGBA") for r in refs]
        args = {"description": desc + gen.ESTILO % "a warm lantern glow",
                "width": quadro[0], "height": quadro[1], "no_background": True,
                "reference_images": [{"url": _data_url(im), "usage": "the approved art: same object, angle, size and "
                                      "position on the canvas" if i == 0 else "how it looks when finished / the style"}
                                     for i, im in enumerate(ims)],
                "style_image_url": _data_url(ims[0]), "style_copy": ["color_palette", "outline", "shading", "detail"]}
        itens.append((nome, "create_image_pro", args, os.path.join(CAND, nome + ".png")))
    gen.lote(itens, registro=os.path.join(AQUI, "mina99_jobs.json"), espera=20)


def escolhe(pares):
    for par in pares:
        nome, arq = par.split("=")
        f = os.path.join(CAND, arq)
        quadro = PEDIDOS[nome][0]
        im = Image.open(f).convert("RGBA")
        if im.size != quadro:
            q = Image.new("RGBA", quadro)
            q.alpha_composite(im.crop((0, 0, min(im.width, quadro[0]), min(im.height, quadro[1]))), (0, 0))
            im = q
        im.save(os.path.join(AQUI, nome + ".png"))
        print("ok", nome, im.size)


def _salva_json(path, d):
    raw = open(path, encoding="utf-8", newline="").read()
    nl = "\r\n" if "\r\n" in raw else "\n"
    open(path, "w", encoding="utf-8", newline="").write(json.dumps(d, indent=1, ensure_ascii=False).replace("\n", nl))


def integra():
    """Os estados novos herdam a âncora, a caixa e a altura do desenho que eles continuam."""
    pj = os.path.join(ISO, "predios", "predios.json")
    d = json.load(open(pj, encoding="utf-8"))
    pr = d["predios"]
    for nome, estado, base in [("elev_obra_1", "obra_1", "ruina"), ("elev_obra_2", "obra_2", "pronto")]:
        f = os.path.join(AQUI, nome + ".png")
        if os.path.exists(f):
            shutil.copyfile(f, os.path.join(ISO, "predios", "elevador", estado + ".png"))
            e = dict(pr["elevador"]["estados"][base])
            e["img"] = "elevador/%s.png" % estado
            e.pop("luzes", None)
            e.pop("janelas", None)
            pr["elevador"]["estados"][estado] = e
            print("ok elevador", estado)
    cab = {"estados": {}, "base": pr["gaiola"]["base"]}
    for nome, estado in [("cabine_vazia", "vazia"), ("cabine_cheia", "cheia")]:
        f = os.path.join(AQUI, nome + ".png")
        if os.path.exists(f):
            os.makedirs(os.path.join(ISO, "predios", "cabine"), exist_ok=True)
            shutil.copyfile(f, os.path.join(ISO, "predios", "cabine", estado + ".png"))
            e = dict(pr["gaiola"]["estados"]["gaiola"])
            e["img"] = "cabine/%s.png" % estado
            cab["estados"][estado] = e
            print("ok cabine", estado)
    if cab["estados"]:
        pr["cabine"] = cab
    _salva_json(pj, d)
    pp = os.path.join(ISO, "props", "props.json")
    p = json.load(open(pp, encoding="utf-8"))
    for nome, base in [("vagonete_grande_SE", "vagonete_cheio_SE"), ("vagonete_grande_SO", "vagonete_cheio_SO"), ("lanterna_boca", None)]:
        f = os.path.join(AQUI, nome + ".png")
        if not os.path.exists(f):
            continue
        shutil.copyfile(f, os.path.join(ISO, "props", nome + ".png"))
        if base:
            e = dict(p["props"][base])
        else:
            e = {"ancora": [20.0, 60.0], "peg": [-6.0, -5.0, 8.0, 6.0], "h": 56.0, "fora": 0}
        e["img"] = nome + ".png"
        p["props"][nome] = e
        print("ok prop", nome)
    _salva_json(pp, p)


if __name__ == "__main__":
    if sys.argv[1] == "gera":
        gera(sys.argv[2:])
    elif sys.argv[1] == "escolhe":
        escolhe(sys.argv[2:])
    elif sys.argv[1] == "integra":
        integra()
