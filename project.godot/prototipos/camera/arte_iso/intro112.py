"""Bloco 112: as 3 ilustrações da INTRODUÇÃO (quadros 1 a 3), 640x360, no estilo dos cartões de evento do Prompt 24
(referências: as próprias ilustrações e a key art do jogo). Um candidato por pedido (acima de 170 px o pro devolve 1).

  python intro112.py gera [nomes]   -> intro/<nome>.png (+ intro/jobs.json com o custo)
  python intro112.py galeria        -> intro/galeria.png (as 3 lado a lado, pra aprovar)
  python intro112.py integra        -> assets/game/ui/intro/<nome>.png (aprovadas pelo Marco em 2026-10-10)
"""
import base64, os, shutil, sys
AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.abspath(os.path.join(AQUI, "..", "..", ".."))
sys.path.insert(0, os.path.abspath(os.path.join(RAIZ, "..", "tools", "pixellab")))
from gen import lote  # noqa: E402

OUT = os.path.join(AQUI, "intro")
DESTINO = os.path.join(RAIZ, "assets", "game", "ui", "intro")
ILU = os.path.join(RAIZ, "assets", "game", "ui", "ilustracoes")
KEYART = os.path.join(RAIZ, "assets", "game", "ui", "titulo", "keyart_a.png")
W, H = 640, 360

ESTILO = ("Gritty dark pixel art illustration for a cinematic intro card of a colony survival game, the SAME art style, palette, "
          "pixel size and detail density as the reference event illustrations: earthy browns and charcoal greys, dirty and worn, "
          "fiery orange and red only where there is fire, crisp 1px near-black outline, hand-placed pixel clusters, no "
          "anti-aliasing. Wide 16:9 composition that reads at a glance. No text, no letters, no logo, no UI, no frame, no border, "
          "no signature, no gore, no blood.")

QUADROS = {
    "q1_sol": ("THE SUN EXPLODES. A gigantic solar flare bursting from a swollen orange-white sun that fills the upper sky, huge "
               "spiralling tongues of fire lashing outward, a shockwave ring of light; below, far away, a dark horizon of a small "
               "industrial town with smokestacks and water towers in black silhouette, the light hitting them from above. Awe and "
               "dread, the moment the world ends. "),
    "q2_cidades": ("SILENT CITIES. The morning after: a dead industrial city under a dull ash-grey sky with a pale, dimmed sun "
                   "behind thick haze, burnt-out brick buildings and collapsed roofs, broken streetlamps, rusted abandoned cars "
                   "and a stopped tram, power lines down, ash falling like snow and covering everything, a scorched billboard "
                   "frame with no words, no people at all, utter stillness. Desaturated greys and browns, small embers glowing "
                   "here and there. "),
    "q3_caravana": ("THE CARAVAN. A long line of small tired survivors in miner helmets and patched coats (the same little people "
                    "as in the reference illustrations) walking single file across a grey ash plain at dusk, pulling a "
                    "handcart loaded with bundles, pickaxes and a lantern, a mule with packs, one of them carrying a child on "
                    "the shoulders, a dead forest of bare black trees at the side; far ahead on the horizon, the dark rim of an "
                    "old stone quarry with a rusted mine headframe, a faint warm light there. Hope against the grey. "),
}


def _b64(p):
    return base64.b64encode(open(p, "rb").read()).decode()


def _args(nome):
    return {"description": QUADROS[nome] + ESTILO, "width": W, "height": H, "no_background": False,
            "reference_images": [
                {"base64": _b64(os.path.join(ILU, "onda_solar.png")), "usage": "art style, palette and pixel size of the event illustrations"},
                {"base64": _b64(os.path.join(ILU, "expulso_derrota.png")), "usage": "how the little miners (ipezinhos) look: helmets, patched coats, scale"},
                {"base64": _b64(KEYART), "usage": "the key art of the game: overall mood, palette and level of detail"}],
            "style_image_base64": _b64(os.path.join(ILU, "festa.png")),
            "style_copy": ["color_palette", "outline", "detail", "shading"]}


def gera(nomes):
    nomes = nomes or list(QUADROS)
    lote([(n, "create_image_pro", _args(n), os.path.join(OUT, n + ".png")) for n in nomes], registro=os.path.join(OUT, "jobs.json"))


def galeria():
    from PIL import Image
    ims = [Image.open(os.path.join(OUT, n + ".png")).convert("RGBA") for n in QUADROS if os.path.exists(os.path.join(OUT, n + ".png"))]
    g = Image.new("RGBA", (W, H * len(ims) + 8 * (len(ims) - 1)), (20, 16, 14, 255))
    for i, im in enumerate(ims):
        g.paste(im.resize((W, H), Image.NEAREST), (0, i * (H + 8)))
    g.save(os.path.join(OUT, "galeria.png"))
    print(os.path.join(OUT, "galeria.png"))


def integra():
    os.makedirs(DESTINO, exist_ok=True)
    for n in QUADROS:
        shutil.copyfile(os.path.join(OUT, n + ".png"), os.path.join(DESTINO, n + ".png"))
        print("integrado", n)
    # (a fogueira do acampamento, quadro 7, é um efeito do mapa: `integra.py fx fogueira`, quadros de objetos/final)


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "gera":
        gera(sys.argv[2:])
    elif cmd == "galeria":
        galeria()
    elif cmd == "integra":
        integra()
