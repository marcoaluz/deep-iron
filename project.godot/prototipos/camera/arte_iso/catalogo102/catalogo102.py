"""Bloco 102: a arte da PEDRA DESCONHECIDA e do MINÉRIO DESCONHECIDO, reaproveitando a arte aprovada (regra 12:
primeiro reaproveitar um sprite do jogo).

As jazidas do jogo saíram de UM lote do PixelLab com o minério numa cor de marcação, depois recolorido pela rampa de
cada minério (jazidas/jazidas.py). A jazida de ferro guarda a rampa do ferro com as cores exatas: aqui ela vira a rampa
da pedra desconhecida (areia apagada, um brilho pálido: "tem alguma coisa nessa rocha"), nos 3 estados. O ícone do
minério desconhecido (interface e o pedaço carregado) é o do ferro, apagado pra cinza de pedra.

  python catalogo102.py monta     -> os PNGs direto nos assets + o props.json + a prancha de conferência
"""
import os, json, colorsys
from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.join(AQUI, "..", "..", "..", "..", "assets", "game")
ISO = os.path.join(GAME, "iso", "props")
FERRO = [(48, 24, 24), (98, 44, 40), (148, 76, 64), (190, 146, 134)]  # jazidas.py RAMPAS["ferro"]
DESCONHECIDA = [(50, 47, 42), (88, 82, 70), (132, 124, 104), (214, 206, 172)]  # areia apagada + brilho pálido


def recolor_rampa(im, de, para):
    out = im.copy()
    px = out.load()
    troca = dict(zip(de, para))
    for y in range(out.height):
        for x in range(out.width):
            p = px[x, y]
            if p[3] > 0 and p[:3] in troca:
                px[x, y] = troca[p[:3]] + (p[3],)
    return out


def apaga(im, sat=0.12, quente=0.06):
    """tira a cor do metal: fica a pedra (um tico de areia pra não virar a prata)."""
    out = im.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            r2, g2, b2 = colorsys.hsv_to_rgb(quente, min(s, sat), v)
            px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
    return out


def _salva_json(path, d):
    raw = open(path, encoding="utf-8", newline="").read()
    nl = "\r\n" if "\r\n" in raw else "\n"
    open(path, "w", encoding="utf-8", newline="").write(json.dumps(d, indent=1, ensure_ascii=False).replace("\n", nl))


def monta():
    pj = os.path.join(ISO, "props.json")
    d = json.load(open(pj, encoding="utf-8"))
    pr = d["props"]
    feitos = []
    for est in ("cheia", "meia", "quase"):
        base = Image.open(os.path.join(ISO, "jazida_ferro_%s.png" % est)).convert("RGBA")
        nome = "jazida_desconhecida_%s" % est
        recolor_rampa(base, FERRO, DESCONHECIDA).save(os.path.join(ISO, nome + ".png"))
        e = dict(pr["jazida_ferro_%s" % est])  # a mesma âncora, caixa e altura
        e["img"] = nome + ".png"
        pr[nome] = e
        feitos.append(nome)
    _salva_json(pj, d)
    for sub in ("", "p24"):
        f = os.path.join(GAME, "ui", "icones", sub, "ferro.png")
        apaga(Image.open(f).convert("RGBA")).save(os.path.join(GAME, "ui", "icones", sub, "desconhecido.png"))
    apaga(Image.open(os.path.join(GAME, "ore_chunk.png")).convert("RGBA")).save(os.path.join(GAME, "chunk_desconhecido.png"))
    # prancha: ferro x desconhecida, os 3 estados, e os ícones
    S = 3
    c = Image.new("RGB", (780, 420), (46, 42, 40))
    dr = ImageDraw.Draw(c)
    dr.text((8, 6), "Bloco 102: jazida de ferro (em cima) -> pedra desconhecida (embaixo); icones do minerio desconhecido", fill=(255, 230, 150))
    for lin, pref in enumerate(("jazida_ferro_", "jazida_desconhecida_")):
        x = 10
        for est in ("cheia", "meia", "quase"):
            im = Image.open(os.path.join(ISO, pref + est + ".png")).convert("RGBA")
            im = im.resize((im.width * S, im.height * S), Image.NEAREST)
            c.paste(im, (x, 24 + lin * 190 + 185 - im.height), im)
            x += im.width + 12
    x = 660
    for k, f in enumerate([os.path.join(GAME, "ui", "icones", "desconhecido.png"), os.path.join(GAME, "chunk_desconhecido.png")]):
        im = Image.open(f).convert("RGBA")
        im = im.resize((im.width * S, im.height * S), Image.NEAREST)
        c.paste(im, (x, 40 + k * 120), im)
    destino = os.path.join(AQUI, "..", "..", "..", "..", "..", "docs", "arte", "bloco102")
    os.makedirs(destino, exist_ok=True)
    c.save(os.path.join(destino, "pedra_desconhecida.png"))
    print("ok", feitos)


if __name__ == "__main__":
    monta()
