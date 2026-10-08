"""Bloco 97: o ARMAZÉM nos níveis 2 e 3 (PixelLab, create_image_pro), a partir do armazém pronto aprovado.

  python niveis97.py gera [nivel_2] [nivel_3]   -> candidatos em armazem/_cand97/<nome>/cNN.png
  python niveis97.py escolhe nivel_2=c00 ...   -> armazem/<nome>.png (quadro 270x350: o pé no mesmo lugar do pronto,
                                                60 px mais abaixo, como a casa/enfermaria nível 2; ver integra.py DESCE)

O quadro é o do pronto (270x290) com 60 px a mais em cima (o que cresce é pra cima: sobrado, guindaste). Os
candidatos não escolhidos ficam fora do repositório (_cand97/ tem .gitignore); os ids ficam em niveis97_jobs.json.
"""
import sys, os, base64, io
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import gen
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
CAND = os.path.join(AQUI, "_cand97")
QUADRO = (270, 350)
DESCE = 60
COMUM = ("Isometric 2:1 view, the SAME angle, footprint, ground line and position as the reference warehouse (the "
         "current level-1 building, shown at the bottom of the canvas): keep its dark weathered plank walls, rusty "
         "iron bands, slate roof colours and the big front door; the base stays exactly where it is and the building "
         "grows UPWARD and a little to the sides, never past the reference footprint by more than a few pixels. ")
PEDIDOS = {
    "nivel_2": COMUM + ("LEVEL 2 of a mining-colony WAREHOUSE: add a timber upper loft (second floor) with a small "
               "hayloft door and a wooden hoist beam with a rope and pulley over the front, a lean-to shed on the side "
               "with stacked crates and barrels, fresh planks patched over the old ones. Only the building, transparent "
               "background, no people, no text. "),
    "nivel_3": COMUM + ("LEVEL 3 of a mining-colony WAREHOUSE, the biggest: a sturdy stone ground floor reinforced with "
               "iron plates and rivets, a tall timber upper floor, a corrugated iron roof, a small iron crane arm with a "
               "chain over the loading door, a covered loading dock with crates and ore sacks. Grim industrial, sooty. "
               "Only the building, transparent background, no people, no text. "),
}


def _data_url(im):
    b = io.BytesIO()
    im.save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def _base():
    """O pronto no quadro novo (60 px mais abaixo): a referência de lugar e de estilo."""
    q = Image.new("RGBA", QUADRO)
    q.alpha_composite(Image.open(os.path.join(AQUI, "pronto.png")).convert("RGBA"), (0, DESCE))
    return q


def gera(nomes):
    os.makedirs(CAND, exist_ok=True)
    base = _data_url(_base())
    estilo = _data_url(Image.open(os.path.join(AQUI, "pronto.png")).convert("RGBA"))
    itens = []
    for nome, desc in PEDIDOS.items():
        if nomes and nome not in nomes:
            continue
        args = {"description": desc + gen.ESTILO % "warm lamp light at the loading door",
                "width": QUADRO[0], "height": QUADRO[1], "no_background": True,
                "reference_images": [{"url": base, "usage": "the current level-1 warehouse: same building, angle, "
                                      "footprint and position on the canvas; grow it upward"}],
                "style_image_url": estilo, "style_copy": ["color_palette", "outline", "shading", "detail"]}
        itens.append((nome, "create_image_pro", args, os.path.join(CAND, nome + ".png")))
    gen.lote(itens, registro=os.path.join(AQUI, "niveis97_jobs.json"), espera=20)


def escolhe(pares):
    for par in pares:
        nome, c = par.split("=")
        f = os.path.join(CAND, nome, c + ".png")
        if not os.path.exists(f):
            f = os.path.join(CAND, nome + ".png")  # (1 candidato só: o arquivo é o próprio)
        im = Image.open(f).convert("RGBA")
        if im.size != QUADRO:
            q = Image.new("RGBA", QUADRO)
            q.alpha_composite(im, ((QUADRO[0] - im.width) // 2, QUADRO[1] - im.height))
            im = q
        dx, dy = _alinha(im)
        q = Image.new("RGBA", QUADRO)
        q.alpha_composite(im, (dx, dy)) if dx >= 0 and dy >= 0 else q.paste(im, (dx, dy), im)
        q.save(os.path.join(AQUI, nome + ".png"))
        print("ok", nome, c, im.size, "alinhado", dx, dy)


def _alinha(im):
    """O melhor deslocamento pra base do nível encostar na base do pronto (a faixa de baixo da silhueta), como o
    predios10.py faz com as obras: a troca de nível acontece no mesmo lugar."""
    import numpy as np
    ref = (np.array(_base())[..., 3] > 40).astype(float)
    m = (np.array(im)[..., 3] > 40).astype(float)

    def faixa(a):
        ys = np.where(a.any(1))[0]
        b = a.copy()
        b[: int(ys[-1] - (ys[-1] - ys[0]) * 0.3)] = 0
        return b
    rb, mb = faixa(ref), faixa(m)
    melhor = (-1.0, 0, 0)
    for dx in range(-20, 21):
        for dy in range(-10, 51):
            s = np.roll(np.roll(mb, dy, 0), dx, 1)
            v = (s * rb).sum() / max(rb.sum(), 1)
            if v > melhor[0]:
                melhor = (v, dx, dy)
    return melhor[1], melhor[2]


if __name__ == "__main__":
    if sys.argv[1] == "gera":
        gera(sys.argv[2:])
    elif sys.argv[1] == "escolhe":
        escolhe(sys.argv[2:])
