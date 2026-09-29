"""PROTÓTIPO: picareta híbrida (sobreposta nas costas) nas 4 direções de losango.

Regra (ENDURECIMENTO_rota_A.md §5): de frente pra câmera (SE/SO) a picareta fica ATRÁS do
corpo; de costas (NE/NO) fica NA FRENTE. Só 2 configurações (SE e NE); SO/NO são espelho.
A posição segue o balanço do tronco em cada quadro (topo do capacete).
Gera: minerador/picareta_4dir.gif e minerador/picareta_4dir.png
"""
from PIL import Image, ImageOps, ImageDraw
import os

HERE = os.path.dirname(os.path.abspath(__file__))
M = os.path.join(HERE, "minerador")
PICK = Image.open(os.path.join(HERE, "..", "..", "..", "..", "docs", "pixellab_teste", "gerado_v2", "fase1",
                               "picareta_teste_escolhida_c10.png")).convert("RGBA")

## As 2 configurações: deslocamento (relativo ao topo do capacete e ao lado de trás do corpo),
## rotação em graus e se desenha na frente do corpo.
CONFIG = {
    "SE": {"dx": -3, "dy": 6, "rot": 0, "mirror": True, "front": False},  # de frente: atrás; a lâmina sai por cima do ombro de trás
    "NE": {"dx": -2, "dy": 8, "rot": 0, "mirror": False, "front": True},  # de costas: na frente, cruzando as costas na alça
}


def compose(body, cfg):
    bbox = body.getbbox()
    top = bbox[1]
    cx = (bbox[0] + bbox[2]) / 2
    pick = ImageOps.mirror(PICK) if cfg.get("mirror") else PICK
    if cfg["rot"]:
        pick = pick.rotate(cfg["rot"], resample=Image.NEAREST, expand=True)
    x = int(round(cx + cfg["dx"] - pick.width / 2))
    y = int(round(top + cfg["dy"]))
    out = Image.new("RGBA", body.size, (0, 0, 0, 0))
    if cfg["front"]:
        out.alpha_composite(body)
        out.alpha_composite(pick, (x, y))
    else:
        out.alpha_composite(pick, (x, y))
        out.alpha_composite(body)
    return out


def main():
    frames = {}
    for d in ["SE", "NE"]:
        frames[d] = [compose(Image.open(os.path.join(M, "caminhada", d, "%d.png" % i)).convert("RGBA"), CONFIG[d])
                     for i in range(4)]
        frames["SO" if d == "SE" else "NO"] = [ImageOps.mirror(f) for f in frames[d]]
    for name, fs in frames.items():  # quadros compostos (pra cena de teste e o verificador)
        os.makedirs(os.path.join(M, "com_picareta", name), exist_ok=True)
        for i, f in enumerate(fs):
            f.save(os.path.join(M, "com_picareta", name, "%d.png" % i))
    order = ["NO", "NE", "SO", "SE"]
    S = 3
    W = 112 * S
    gif = []
    for i in range(4):
        canvas = Image.new("RGBA", (4 * W, W + 20), (80, 80, 92, 255))
        d = ImageDraw.Draw(canvas)
        for k, name in enumerate(order):
            f = frames[name][i].resize((W, W), Image.NEAREST)
            canvas.alpha_composite(f, (k * W, 20))
            d.text((k * W + 6, 4), name + (" (picareta NA FRENTE)" if name[0] == "N" else " (picareta ATRAS)"), fill=(255, 230, 120))
        gif.append(canvas.convert("RGB"))
    gif[0].save(os.path.join(M, "picareta_4dir.gif"), save_all=True, append_images=gif[1:], duration=160, loop=0)
    sheet = Image.new("RGB", (4 * W, 4 * (W + 20)), (80, 80, 92))
    for i, g in enumerate(gif):
        sheet.paste(g, (0, i * (W + 20)))
    sheet.save(os.path.join(M, "picareta_4dir.png"))
    print("ok")


if __name__ == "__main__":
    main()
