"""Bloco 71: os pisos dos níveis novos — S4 (rocha molhada da cachoeira), S5 (rocha azulada do lago) e a
ÁGUA rasa do lago — no mesmo bloco 64x64 dos pisos aprovados (Prompt 7: candidatos de bloco inteiro,
`tiles.retifica` e `tiles.topo_de`).

  python fundo71.py gera                      -> <pasta>/candidatos/cNN.png + <pasta>_candidatos.png
  python fundo71.py monta umido=2,5,9,11,0 lago=1,4,7,12,3 zona_agua=0,3,6,9
                                               -> final/<pasta>/chao_<k>.png (o 1º vira também bloco.png)
"""
import sys, os, base64, io
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import gen
from PIL import Image
import tiles

AQUI = os.path.dirname(os.path.abspath(__file__))
REF = os.path.join(AQUI, "final", "nivel2", "bloco.png")
PEDIDOS = {
    "umido": ("dark wet slate rock: glistening wet stone, thin trickles and small shallow puddles of water "
              "reflecting a cold blue light, a little dark green slime in the cracks", "cold blue water glints"),
    "lago": ("blue-grey cave stone near an underground lake: smooth worn rock with small pale blue crystal "
             "specks and a fine layer of damp blue mineral dust", "pale blue crystal specks"),
    # itens de arte do documento: a rocha com ácido (S2) e a borda do lago (S5)
    "zona_acido": ("dark slate rock with corroded pale-green ACID STAINS, etched pits and a few tiny shallow "
                   "puddles of glowing toxic green liquid in the cracks", "toxic lime-green stains"),
    "zona_borda": ("a wet lake SHORE: dark blue-grey pebbles and coarse wet sand, a thin film of water at the "
                   "edges, a few smooth stones", "wet blue-grey pebbles"),
    "zona_agua": ("SHALLOW CLEAR WATER covering the top face: calm dark blue-green water over submerged rocks, "
                  "small soft ripples and faint light reflections; the side faces are the same wet dark rock",
                  "deep calm blue water"),
}


def _data_url(path):
    b = io.BytesIO()
    Image.open(path).convert("RGBA").save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def gera():
    ref = _data_url(REF)
    itens = []
    for nome, (o_que, acento) in PEDIDOS.items():
        desc = ("One isometric 2:1 ground BLOCK exactly like the reference block (same shape and size: a 64x32 "
                "diamond top face and two side faces 32 px tall, light from the top-left), but made of %s. "
                "Flat top, no objects standing on it, transparent background. " % o_que)
        args = {"description": desc + gen.ESTILO % acento, "width": 64, "height": 64, "no_background": True,
                "reference_images": '[{"url": "%s", "usage": "exact block shape, size and angle (copy the geometry)"}]' % ref}
        os.makedirs(os.path.join(AQUI, nome), exist_ok=True)
        itens.append((nome, "create_image_pro", args, os.path.join(AQUI, nome, "candidatos.png")))
    gen.lote(itens, registro=os.path.join(AQUI, "fundo71_jobs.json"), espera=15)


def monta(args):
    for a in args:
        nome, idx = a.split("=")
        dest = os.path.join(AQUI, "final", os.path.join("mina", nome) if nome.startswith("zona_") else nome)
        os.makedirs(dest, exist_ok=True)
        for k, i in enumerate(int(x) for x in idx.split(",")):
            src = Image.open(os.path.join(AQUI, nome, "candidatos", "c%02d.png" % i)).convert("RGBA")
            bloco = tiles.retifica(src)
            tiles.topo_de(bloco).save(os.path.join(dest, "chao_%d.png" % k))
            if k == 0:
                bloco.save(os.path.join(dest, "bloco.png"))
        print(nome, "->", dest)


if __name__ == "__main__":
    gera() if sys.argv[1] == "gera" else monta(sys.argv[2:])
