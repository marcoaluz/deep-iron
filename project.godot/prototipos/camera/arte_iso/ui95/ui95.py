"""Bloco 95: a arte nova do layout v2 — ilustrações dos cartões do CONSTRUIR que não tinham desenho e os ícones
dos alertas e dos balões de motivo. PixelLab (create_image_pro) com a arte do jogo como estilo.

  python ui95.py gera [nomes]            -> candidatos em ui95/_cand/<nome>/cNN.png (+ grade _cand/<nome>.png)
  python ui95.py reaproveita             -> cartões dos sprites que já existem (decoração, vagonete), sem PixelLab
  python ui95.py escolhe nome=cNN ...    -> cartão: assets/game/ui/icones/cartoes/<nome>.png (96x64, como os
                                            prédios reduzidos); ícone: assets/game/ui/icones/<nome>.png (32 + p24)

Os candidatos (_cand/) ficam fora do repositório (.gitignore); os ids dos jobs ficam em ui95_jobs.json.
"""
import sys, os, base64, io, json
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import gen
import numpy as np
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
CAND = os.path.join(AQUI, "_cand")
RAIZ = os.path.normpath(os.path.join(AQUI, "..", "..", "..", ".."))
ISO = os.path.join(RAIZ, "assets", "game", "iso")
ICONES = os.path.join(RAIZ, "assets", "game", "ui", "icones")
CARTOES = os.path.join(ICONES, "cartoes")
CARTAO = (96, 64)  # o mesmo tamanho dos prédios reduzidos (icones/predios/*.png)

FIM = ("Only the object, centered, transparent background, no text, no frame, no people. ")
# nome: (largura, altura, descrição, acento, estilo, tipo)  — tipo "cartao" ou "icone"
PEDIDOS = {
    "escola": (128, 112, "Isometric 2:1 view (like the reference building): a SMALL ONE-ROOM VILLAGE SCHOOL of a poor mining "
               "colony: timber frame with dark plank walls, a slate roof with a tiny bell tower holding a little bronze bell, "
               "a wooden door the height of a man, a small chalkboard leaning by the door, patched planks and soot. Same "
               "scale and style as the reference house. " + FIM, "the little bronze bell", "casa", "cartao"),
    "ferrovia": (128, 112, "Isometric 2:1 view (like the reference building): a FREIGHT RAILWAY LOADING STATION inside a mine: "
                 "a short wooden plank platform on posts, a rusty iron mine cart full of ore on a short piece of rail in "
                 "front, and a tall timber TRESTLE (scaffold of crossed beams) rising behind it with the rail going up, "
                 "iron brackets, an oil lamp on a post. " + FIM, "warm oil lamp glow", "coletor_minerio", "cartao"),
    "cam_terra": (64, 48, "a small flat ISOMETRIC 2:1 diamond-shaped GROUND PATCH seen from above: packed BROWN DIRT path, "
                  "earthy brown soil with two faint wheel ruts, a few footprints and small grass tufts at the edges. Flat "
                  "on the ground, no walls, no wood. " + FIM, "a few green grass tufts", "coletor_minerio", "cartao"),
    "cam_cascalho": (64, 48, "a small flat ISOMETRIC 2:1 diamond-shaped GROUND PATCH seen from above: a GRAVEL path of small "
                     "grey and brown pebbles packed together, slightly darker worn edges. Flat on the ground, no walls. "
                     + FIM, "a few lighter pebbles", "coletor_minerio", "cartao"),
    "cam_pedra": (64, 48, "a small flat ISOMETRIC 2:1 diamond-shaped GROUND PATCH seen from above: a path of LAID GREY "
                  "FLAGSTONES, irregular cracked stones with dark moss in the joints. Flat on the ground, no walls. "
                  + FIM, "a little green moss", "coletor_minerio", "cartao"),
    "apagar_caminho": (96, 64, "Isometric 2:1 view: a worn iron SHOVEL with a wooden handle stuck diagonally into a small patch "
                       "of dirt path, a small pile of dug earth beside it. " + FIM, "rusty shovel blade", "coletor_minerio", "cartao"),
    "desbravar": (96, 64, "Isometric 2:1 view: an OLD FOLDED PARCHMENT MAP lying on a dark wooden plank, pinned with an iron "
                  "nail, with a hand-drawn forest and hills and a bold red ARROW pointing to the right (east). "
                  + FIM, "the red arrow", "coletor_minerio", "cartao"),
    "trilhas": (96, 64, "Isometric 2:1 view: a muddy brown leather WORK BOOT stepping on a beaten dirt trail with footprints "
                "and a small dust puff behind the heel. " + FIM, "the dust puff", "coletor_minerio", "cartao"),
    "remover_decor": (96, 64, "Isometric 2:1 view: an iron CROWBAR prying a small wooden fence stake out of the ground, a few "
                      "wood splinters and loose earth. " + FIM, "pale wood splinters", "coletor_minerio", "cartao"),
    "sem_ferramenta": (32, 32, "game UI icon: a BROKEN PICKAXE, the iron head snapped off and lying apart from the wooden handle",
                       "", "", "icone"),
    "armazem_cheio": (32, 32, "game UI icon: a wooden CRATE OVERFLOWING with ore rocks spilling over the top edge", "", "", "icone"),
    "caminho_bloqueado": (32, 32, "game UI icon: a small PILE OF ROCKS blocking a dirt path with a bold red X over it", "", "", "icone"),
    "pessoas": (32, 32, "game UI icon: TWO MINER HELMETS side by side, one slightly behind the other, each with a small lamp",
                "", "", "icone"),
    "missoes": (32, 32, "game UI icon: a rolled PARCHMENT SCROLL pinned to a plank with an iron nail, a little check mark on it",
                "", "", "icone"),
}
ESTILO_PREDIO = {"casa": os.path.join(ISO, "predios", "casa", "pronto_0.png"),
                 "coletor_minerio": os.path.join(ISO, "predios", "coletor_minerio", "pronto.png")}


def _data_url(path):
    b = io.BytesIO()
    Image.open(path).convert("RGBA").save(b, "PNG")
    return "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()


def gera(nomes):
    os.makedirs(CAND, exist_ok=True)
    eng = _data_url(os.path.join(ICONES, "engenheiro.png"))
    coz = _data_url(os.path.join(ICONES, "cozinheiro.png"))
    itens = []
    for nome, (w, h, desc, acento, estilo, tipo) in PEDIDOS.items():
        if nomes and nome not in nomes:
            continue
        if tipo == "icone":  # como os ícones do Bloco 92 (oficios92.icones)
            args = {"description": desc + ". Same style, size, outline and light as the reference icons of the same game: "
                                   "chunky readable pixel art, 1px near-black outline, warm muted palette, centered, "
                                   "transparent background, no text, no frame.",
                    "width": w, "height": h, "no_background": True,
                    "reference_images": [{"url": eng, "usage": "the engineer job icon of the same game: style and size"},
                                         {"url": coz, "usage": "the cook job icon of the same game: style and size"}],
                    "style_image_url": eng, "style_copy": ["color_palette", "outline", "detail", "shading"]}
        else:  # como os marcos do Bloco 78 (fundo78/marcos.py)
            args = {"description": desc + gen.ESTILO % acento, "width": w, "height": h, "no_background": True,
                    "style_image_url": _data_url(ESTILO_PREDIO[estilo]), "style_copy": ["color_palette", "outline", "shading"]}
        itens.append((nome, "create_image_pro", args, os.path.join(CAND, nome + ".png")))
    gen.lote(itens, registro=os.path.join(AQUI, "ui95_jobs.json"), espera=15)


def limpa(im):
    """Alfa duro (pixel art: sem meio-transparente) e corta no desenho."""
    a = np.array(im.convert("RGBA"))
    a[..., 3] = np.where(a[..., 3] >= 110, 255, 0)
    im = Image.fromarray(a, "RGBA")
    bb = im.getbbox()
    return im.crop(bb) if bb else im


def cabe(im, w, h):
    """Cabe no retângulo (reduz com reamostragem boa, sem ampliar) e centra — como o ui/icones.py."""
    im = limpa(im)
    k = min(w / im.width, h / im.height, 1.0)
    if k < 1.0:
        im = limpa(im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS))
    q = Image.new("RGBA", (w, h))
    q.alpha_composite(im, ((w - im.width) // 2, (h - im.height) // 2))
    return q


def salva_cartao(nome, im):
    os.makedirs(CARTOES, exist_ok=True)
    cabe(im, *CARTAO).save(os.path.join(CARTOES, nome + ".png"))
    print("cartão", nome)


def salva_icone(nome, im):
    im32 = cabe(im, 32, 32)
    im32.save(os.path.join(ICONES, nome + ".png"))
    cabe(im32, 24, 24).save(os.path.join(ICONES, "p24", nome + ".png"))
    lista = json.load(open(os.path.join(ICONES, "icones.json"), encoding="utf-8"))
    if nome not in lista["icones"]:
        lista["icones"].append(nome)
        json.dump(lista, open(os.path.join(ICONES, "icones.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("ícone", nome)


def escolhe(pares):
    for par in pares:
        nome, c = par.split("=")
        im = Image.open(os.path.join(CAND, nome, c + ".png")).convert("RGBA")
        (salva_icone if PEDIDOS[nome][5] == "icone" else salva_cartao)(nome, im)


## Cartão de sprite que já existe no jogo (nada novo do PixelLab): enquadrado e centrado no mesmo 96x64.
REAPROVEITA = {"decor_tocha": "props/tocha_chao_f0.png", "decor_lampiao": "props/decor_lampiao.png",
               "decor_banco": "props/banco.png", "decor_mesa": "props/mesa.png", "decor_cerca": "props/decor_cerca.png",
               "decor_canteiro_flores": "props/decor_canteiro_flores.png", "decor_bandeira": "props/decor_bandeira.png",
               "vagonete": "props/vagonete_cheio_SE.png",
               "armazem_ampliar": "predios/armazem/nivel_2.png"}  # Bloco 97


## Prédio pronto que não tinha o desenho reduzido do menu (icones/predios/, como o ui/icones.py faz).
PREDIOS_FALTANDO = {"coletor_minerio": "predios/coletor_minerio/pronto.png"}


def reaproveita():
    for nome, rel in REAPROVEITA.items():
        salva_cartao(nome, Image.open(os.path.join(ISO, rel)).convert("RGBA"))
    for nome, rel in PREDIOS_FALTANDO.items():
        cabe(Image.open(os.path.join(ISO, rel)).convert("RGBA"), *CARTAO).save(os.path.join(ICONES, "predios", nome + ".png"))
        print("prédio", nome)


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "gera":
        gera(sys.argv[2:])
    elif cmd == "reaproveita":
        reaproveita()
    elif cmd == "escolhe":
        escolhe(sys.argv[2:])
