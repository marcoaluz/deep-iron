"""Bloco 70: VENTILADOR do nível 2 (prop iso) e as POÇAS de ácido e de lava (textura vista de cima: o
jogo desenha a poça no chão e a vista iso entorta pro losango, como as manchas das zonas de perigo).
create_image_pro (16 candidatos por chamada) com o estilo de uma máquina aprovada.

  python objetos.py gera     -> fundo70/<nome>/cNN.png + grade <nome>.png
  python objetos.py escolhe ventilador=c02 poca_acido=c06,c13 poca_lava=c03,c11
                              -> fundo70/ventilador.png, poca_acido_0.png...
  python objetos.py instala  -> poças em assets/game/iso/chao/, ícone do ventilador no menu
  python objetos.py grandes  -> poças no losango, no tamanho da tela (referência = a escolhida)
"""
import sys, os, base64, io
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import gen
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
ISO = os.path.join(AQUI, "..", "..", "..", "..", "assets", "game", "iso")
ESTILO_IMG = os.path.join(ISO, "predios", "coletor_minerio", "pronto.png")
PEDIDOS = {
    "ventilador": (64, 80, "Isometric 2:1 view (like the reference machine), a small industrial mine VENTILATION FAN "
                   "standing on the ground: a big round riveted iron fan housing with a protective grille and four "
                   "visible blades, mounted upright on a squat rusty iron frame with short legs and a small motor box "
                   "with a cable; worn, soot-stained, dented. Only the object, transparent background. ",
                   "faded green paint on the fan blades"),
    "poca_acido": (84, 52, "Seen from DIRECTLY ABOVE (top-down, flat on the floor), an irregular wide flat PUDDLE of "
                   "bubbling toxic acid on a dark rock cave floor: murky toxic green liquid with brighter lime bubbles "
                   "and foam at the rim, a dark corroded edge of wet rock around it; flat, no height, no shadow. Only "
                   "the puddle, transparent background around it. ", "toxic lime-green acid"),
    "poca_lava": (84, 52, "Seen from DIRECTLY ABOVE (top-down, flat on the floor), an irregular wide flat POOL of "
                  "molten lava in the dark basalt cave floor: glowing orange-yellow molten center, darker red crust "
                  "plates floating, a black cooled-rock rim around it; flat, no height, no shadow. Only the pool, "
                  "transparent background around it. ", "glowing orange lava"),
}


def _data_url(path):
    b = io.BytesIO()
    Image.open(path).convert("RGBA").save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def gera():
    estilo = _data_url(ESTILO_IMG)
    itens = []
    for nome, (w, h, desc, acento) in PEDIDOS.items():
        args = {"description": desc + gen.ESTILO % acento, "width": w, "height": h, "no_background": True,
                "style_image_url": estilo, "style_copy": ["color_palette", "outline", "shading"]}
        itens.append((nome, "create_image_pro", args, os.path.join(AQUI, nome + ".png")))
    gen.lote(itens, registro=os.path.join(AQUI, "jobs.json"), espera=15)


def escolhe(args):
    for a in args:
        nome, cs = a.split("=")
        for k, c in enumerate(cs.split(",")):
            im = Image.open(os.path.join(AQUI, nome, c + ".png")).convert("RGBA")
            im = im.crop(im.getbbox())
            dst = os.path.join(AQUI, nome + (".png" if nome == "ventilador" else "_%d.png" % k))
            im.save(dst)
            print(dst, im.size)


def instala():
    """Poças -> assets/game/iso/chao/ (decalque deitado na laje, iso_view._poca_add); ícone do ventilador
    pro menu de construção (render reduzido como o ui/icones.py faz com os prédios)."""
    from PIL import ImageFilter
    chao = os.path.join(ISO, "chao")
    os.makedirs(chao, exist_ok=True)
    for k in ("acido", "lava"):
        for v in range(2):
            Image.open(os.path.join(AQUI, "poca_%s_iso_%d.png" % (k, v))).save(os.path.join(chao, "poca_%s_%d.png" % (k, v)))
    im = Image.open(os.path.join(AQUI, "ventilador.png")).convert("RGBA")
    f = min(96 / im.width, 64 / im.height)
    r = im.resize((max(1, round(im.width * f)), max(1, round(im.height * f))), Image.LANCZOS)
    r = r.filter(ImageFilter.UnsharpMask(radius=1, percent=60, threshold=2))
    q = Image.new("RGBA", (96, 64))
    q.alpha_composite(r, ((96 - r.width) // 2, 64 - r.height))
    q.save(os.path.join(ISO, "..", "ui", "icones", "predios", "ventilador.png"))
    print("instalado: chao/poca_*.png, ícone predios/ventilador.png")


def _main():
    if sys.argv[1] == "instala":
        instala()
    elif sys.argv[1] == "gera":
        gera()
    elif sys.argv[1] == "escolhe":
        escolhe(sys.argv[2:])


# ------------------------------------------------------------ poças grandes, já no losango (iso)
## A área de jogo da poça na tela é ~160x80 (raio ~46 da lógica): a textura de cima ficaria com pixel
## dobrado. Aqui a poça é desenhada já deitada no losango 2:1, no tamanho da tela, com a escolhida
## de cima como referência de aparência.
GRANDES = {
    "poca_acido_iso": ("poca_acido_0.png", "toxic lime-green acid", "bubbling toxic green acid with lime bubbles and "
                       "foam at the rim and a dark corroded wet-rock edge"),
    "poca_lava_iso": ("poca_lava_0.png", "glowing orange lava", "molten glowing orange-yellow lava with dark red "
                      "crust plates and a black cooled-rock rim"),
}


def gera_grandes():
    itens = []
    for nome, (ref, acento, o_que) in GRANDES.items():
        desc = ("Isometric 2:1 view: a wide flat irregular PUDDLE of %s lying FLAT on a dark cave floor, seen at the "
                "same angle as an isometric floor tile (a wide flattened oval twice as wide as tall); flat, no height, "
                "no walls, no shadow. Only the puddle, transparent background around it. " % o_que)
        args = {"description": desc + gen.ESTILO % acento, "width": 160, "height": 84, "no_background": True,
                "reference_images": '[{"url": "%s", "usage": "look, colours and details of the puddle (redraw it '
                                    'lying flat in isometric view, wider)"}]' % _data_url(os.path.join(AQUI, ref))}
        itens.append((nome, "create_image_pro", args, os.path.join(AQUI, nome + ".png")))
    gen.lote(itens, registro=os.path.join(AQUI, "jobs.json"), espera=15)


if __name__ == "__main__":
    gera_grandes() if sys.argv[1] == "grandes" else _main()
