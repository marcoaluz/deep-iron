"""Bloco 70: jazidas de CRISTAL VERDE (S2) e CRISTAL RUBRO (S3), editando a jazida de prata (cheia, meia,
quase numa chamada só do edit_image pro: as 3 saem coerentes). O quadro e a âncora são os da prata.

  python jazidas.py gera     -> edita (2 chamadas) e baixa em fundo70/<cristal>/c00..c02.png
  python jazidas.py corta    -> recorta no tamanho da prata: fundo70/jazida_<cristal>_<estado>.png
"""
import sys, os, json, base64, io
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import gen
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
PROPS = os.path.join(AQUI, "..", "..", "..", "..", "assets", "game", "iso", "props")
ESTADOS = ["cheia", "meia", "quase"]
W, H = 64, 68
CRISTAIS = {
    "cristal_verde": ("Replace every grey silver ore nugget embedded in the dark rock with small clusters of sharp "
                      "translucent acid-green crystal shards growing out of the rock: bright lime highlights, darker "
                      "green shadows, a faint inner glow. Keep the dark rock block exactly the same shape, size, "
                      "position, outline and lighting; transparent background. ", "acid green crystals"),
    "cristal_rubro": ("Replace every grey silver ore nugget embedded in the dark rock with small clusters of sharp "
                      "translucent deep crimson-red crystal shards growing out of the rock: hot orange-red highlights, "
                      "dark blood-red shadows, a faint ember glow. Keep the dark rock block exactly the same shape, "
                      "size, position, outline and lighting; transparent background. ", "crimson red crystals"),
    # Bloco 71: a gema azul do S5 (a beira do lago)
    "gema_azul": ("Replace every grey silver ore nugget embedded in the dark rock with small clusters of faceted "
                  "deep blue sapphire gems growing out of the rock: bright icy-blue highlights, dark navy shadows, "
                  "a faint cold inner glow. Keep the dark rock block exactly the same shape, size, position, outline "
                  "and lighting; transparent background. ", "deep blue gems"),
}


def _quadro(estado):
    im = Image.open(os.path.join(PROPS, "jazida_prata_%s.png" % estado)).convert("RGBA")
    q = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    q.paste(im, (0, H - im.height))
    return q, im.size


def _data_url(im):
    b = io.BytesIO()
    im.save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def gera():
    itens = []
    urls = [_data_url(_quadro(e)[0]) for e in ESTADOS]
    for nome, (desc, acento) in CRISTAIS.items():
        args = {"image_urls": urls, "description": desc + gen.ESTILO % acento, "no_background": True}
        itens.append((nome, "edit_image", args, os.path.join(AQUI, nome + ".png")))
    gen.lote(itens, registro=os.path.join(AQUI, "jobs.json"), espera=10)


def corta():
    for nome in CRISTAIS:
        for i, e in enumerate(ESTADOS):
            src = os.path.join(AQUI, nome, "c%02d.png" % i)
            if not os.path.exists(src):
                print("falta", src)
                continue
            im = Image.open(src).convert("RGBA")
            _q, (w, h) = _quadro(e)
            out = im.crop((0, H - h, w, H))
            out.save(os.path.join(AQUI, "jazida_%s_%s.png" % (nome, e)))
            print("jazida_%s_%s.png" % (nome, e), out.size)


if __name__ == "__main__":
    {"gera": gera, "corta": corta}[sys.argv[1]]()
