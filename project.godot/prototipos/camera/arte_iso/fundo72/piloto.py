"""Bloco 72 — PILOTO de arte (pra aprovação do Marco antes de qualquer lote):
  - faixa do S4 (cachoeira e lava) e do S5 (lago azul) pro Corte da mina (F2), 512x128 como as do
    Prompt 25, com a faixa do abismo de referência de estilo (edit_image_pixen: mesma composição);
  - 1 peça de RIO DE LAVA (decalque deitado na laje, no losango), com o poço de lava aprovado de referência.

  python piloto.py gera      -> fundo72/<nome>.png (faixas: 2 candidatas cada; rio: 16 candidatos)
"""
import sys, os, base64, io
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import gen
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
UI = os.path.join(AQUI, "..", "..", "..", "..", "assets", "game", "ui", "corte")
CHAO = os.path.join(AQUI, "..", "..", "..", "..", "assets", "game", "iso", "chao")


def _url(path):
    b = io.BytesIO()
    Image.open(path).convert("RGBA").save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


FAIXAS = {
    "faixa_s4": ("Repaint this side-view cross-section strip of a mine level as the level BELOW it: a dark cave "
                 "where an underground WATERFALL pours down the back rock wall into shallow pools of water on the "
                 "left, while the right half has cracked basalt with glowing LAVA seams; white steam rising where "
                 "water meets the hot rock; wooden supports and a few crystals of several colours. Keep the exact "
                 "same size, framing, floor line and pixel-art style as the reference strip. ",
                 "cold blue water and orange lava"),
    "faixa_s5": ("Repaint this side-view cross-section strip of a mine level as the DEEPEST level: a calm "
                 "underground LAKE of deep blue water filling the lower half, faint reflections, blue gem crystals "
                 "glowing on the rock walls, two small abandoned stone huts on the shore at the left, dark blue "
                 "cave rock above. Keep the exact same size, framing, floor line and pixel-art style as the "
                 "reference strip. ", "glowing deep blue water and gems"),
}


def gera():
    ref = _url(os.path.join(UI, "faixa_abismo.png"))
    itens = []
    for nome, (desc, acento) in FAIXAS.items():
        for k in range(2):
            # (o edit_image_pixen só aceita até 256 de lado: a faixa sai do create_image_pixen, como no Prompt 25)
            itens.append(("%s_%d" % (nome, k), "create_image_pixen",
                          {"description": ("Side-view pixel-art cross-section strip of one underground mine level, a wide "
                                           "horizontal band: " + desc.split(": ", 1)[1].replace("Keep the exact same size, framing, "
                                           "floor line and pixel-art style as the reference strip. ", "") + "Dark, gritty, low colour count, "
                                           "no text, no frame, no sky.")[:2000],
                           "width": 512, "height": 128, "view": "side", "seed": 720 + k},
                          os.path.join(AQUI, "%s_%d.png" % (nome, k))))
    rio = ("Isometric 2:1 view: a winding RIVER OF MOLTEN LAVA lying FLAT on a dark basalt cave floor, flowing "
           "diagonally across the canvas from the top-left to the bottom-right, glowing orange-yellow molten "
           "center with darker red crust plates, a black cooled-rock bank on both sides; flat, no height, no "
           "shadow. Only the river, transparent background around it. ")
    itens.append(("rio_lava", "create_image_pro",
                  {"description": rio + gen.ESTILO % "glowing orange lava", "width": 160, "height": 84, "no_background": True,
                   "reference_images": '[{"url": "%s", "usage": "look and colours of the lava (redraw it as a long river)"}]'
                   % _url(os.path.join(CHAO, "poca_lava_0.png"))}, os.path.join(AQUI, "rio_lava.png")))
    gen.lote(itens, registro=os.path.join(AQUI, "jobs.json"), espera=12)


if __name__ == "__main__":
    gera()
