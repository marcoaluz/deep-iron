"""PROTÓTIPO: entregas do Prompt 10 (prédios da vila e moradia).

  python predios10.py confere          -> sobreposição de cada obra/estágio com o pronto (deslocamento)
  python predios10.py entrega <pasta>  -> prancha_<predio>.png e obra_<predio>.gif, prancha do Centro

Regra do contrato: obra e pronto trocam NO MESMO LUGAR (mesma âncora = centro da pegada).
Quando a IA desloca um estágio uns pixels, o alinhamento corrige pelo melhor encaixe da
silhueta de baixo (a base do prédio), não da silhueta toda (andaime e telhado mudam muito).
"""
import sys, os, json
import numpy as np
from PIL import Image, ImageDraw

SERIES = {
    "armazem": ["armazem/obra_1.png", "armazem/obra_2.png", "armazem/obra_3.png", "armazem/pronto.png"],
    "oficina": ["oficina/obra_1.png", "oficina/obra_2.png", "oficina/obra_3.png", "oficina/pronto.png"],
    "casa_niveis": ["casa/_casa_v0_360.png", "casa/nivel_2.png", "casa/nivel_3.png"],
    "centro": ["centro/estagio_1/pronto.png"] + sum([["centro/estagio_%d/obra.png" % i, "centro/estagio_%d/pronto.png" % i] for i in range(2, 6)], []),
}
AJUSTE_F = "predios10_ajuste.json"


def alpha(f, size=None):
    im = Image.open(f).convert("RGBA")
    if size and im.size != size:
        c = Image.new("RGBA", size); c.paste(im, (0, 0)); im = c
    return (np.array(im)[..., 3] > 40).astype(float), im


def base(a, frac=0.35):
    """só a faixa de baixo da silhueta (pé do prédio)."""
    ys = np.where(a.any(1))[0]
    if not len(ys):
        return a
    y0 = int(ys[-1] - (ys[-1] - ys[0]) * frac)
    b = a.copy(); b[:y0] = 0
    return b


def melhor(ref, m, r=10):
    rb, mb = base(ref), base(m)
    best = None
    for dx in range(-r, r + 1):
        for dy in range(-r, r + 1):
            s = np.roll(np.roll(mb, dy, 0), dx, 1)
            v = (s * rb).sum() / max(rb.sum(), 1)
            if not best or v > best[0]:
                best = (v, dx, dy)
    return best


def prepara_casa():
    """a casa aprovada (240x288) no quadro dos níveis (240x360), 72 px abaixo."""
    c = Image.new("RGBA", (240, 360)); c.paste(Image.open("casa/casa_v0.png").convert("RGBA"), (0, 72))
    c.save("casa/_casa_v0_360.png")


def confere():
    prepara_casa()
    aj = {}
    for nome, fs in SERIES.items():
        ref = fs[-1] if nome in ("armazem", "oficina") else fs[0]
        ra, rim = alpha(ref)
        for f in fs:
            if f == ref:
                continue
            ma, _ = alpha(f, rim.size)
            v, dx, dy = melhor(ra, ma)
            # só corrige quando o pé encaixa bem (>= 0,85) e o desvio é pequeno: fundação e
            # andaime mudam a silhueta de baixo, e aí o encaixe não é confiável
            aj[f] = [-dx, -dy] if nome != "centro" and v >= 0.85 and max(abs(dx), abs(dy)) <= 8 else [0, 0]
            print("%-32s base encaixa %.2f  desloc (%d, %d)" % (f, v, dx, dy))
    json.dump(aj, open(AJUSTE_F, "w"), indent=1)


def carrega(f, size=None):
    im = Image.open(f).convert("RGBA")
    aj = json.load(open(AJUSTE_F)).get(f, [0, 0]) if os.path.exists(AJUSTE_F) else [0, 0]
    size = size or im.size
    c = Image.new("RGBA", size); c.paste(im, tuple(aj)); return c


def entrega(pasta):
    os.makedirs(pasta, exist_ok=True)
    AM = (255, 230, 150)
    for nome, rot in (("armazem", ["obra 1", "obra 2", "obra 3", "pronto"]), ("oficina", ["obra 1", "obra 2", "obra 3", "pronto"]),
                      ("casa_niveis", ["nivel 1 (aprovada)", "nivel 2", "nivel 3"])):
        fs = SERIES[nome]; size = Image.open(fs[-1]).size
        ims = [carrega(f, size) for f in fs]
        c = Image.new("RGB", (len(ims) * size[0] + 10, size[1] + 18), (62, 58, 54)); d = ImageDraw.Draw(c)
        for k, (im, r) in enumerate(zip(ims, rot)):
            c.paste(im, (5 + k * size[0], 18), im); d.text((8 + k * size[0], 3), r, fill=AM)
        c.save(os.path.join(pasta, "prancha_%s.png" % nome))
        fr = []
        for im, r in zip(ims, rot):
            g = Image.new("RGB", (size[0], size[1] + 16), (62, 58, 54)); g.paste(im, (0, 16), im)
            ImageDraw.Draw(g).text((4, 2), r, fill=AM); fr.append(g)
        fr[0].save(os.path.join(pasta, "obra_%s.gif" % nome), save_all=True, append_images=fr[1:], duration=900, loop=0)
    # Centro: 5 estágios + obras entre eles, alinhados pelo PÉ (centro de baixo) num quadro comum
    fs = SERIES["centro"]
    W, H = 360, 460
    fr = []; ims = []
    rot = ["1 Acampamento"] + sum([["obra -> %d" % i, "%d %s" % (i, n)] for i, n in zip(range(2, 6), ["Vilarejo", "Vila", "Vila Mineira", "Cidade Mineira"])], [])
    for f, r in zip(fs, rot):
        im = Image.open(f).convert("RGBA"); b = im.getbbox()
        # âncora de cada quadro = centro da pegada (predio.py: ax, ay); aqui pelo pé da silhueta
        cx = (b[0] + b[2]) // 2; by = b[3]
        g = Image.new("RGBA", (W, H)); g.paste(im, (W // 2 - cx, H - 10 - by)); ims.append((g, r))
        gg = Image.new("RGB", (W, H + 16), (62, 58, 54)); gg.paste(g, (0, 16), g)
        ImageDraw.Draw(gg).text((4, 2), r, fill=AM); fr.append(gg)
    fr[0].save(os.path.join(pasta, "obra_centro.gif"), save_all=True, append_images=fr[1:], duration=900, loop=0)
    esc = 0.5
    c = Image.new("RGB", (len(ims) * int(W * esc) + 10, int(H * esc) + 18), (62, 58, 54)); d = ImageDraw.Draw(c)
    for k, (g, r) in enumerate(ims):
        gs = g.resize((int(W * esc), int(H * esc)), Image.NEAREST)
        c.paste(gs, (5 + k * int(W * esc), 18), gs); d.text((8 + k * int(W * esc), 3), r, fill=AM)
    c.save(os.path.join(pasta, "prancha_centro.png"))
    # Centro em tamanho real, só os 5 prontos, com o minerador
    m = Image.open("minerador/rotacoes/south-east.png").convert("RGBA"); m = m.crop(m.getbbox())
    prontos = [g for g, r in ims if "obra" not in r]
    c = Image.new("RGB", (5 * 300 + 60, H), (62, 58, 54))
    for k, g in enumerate(prontos):
        c.paste(g, (k * 300 - 30, 0), g)
    c.paste(m, (5 * 300 + 10, H - 10 - m.height), m)
    c.save(os.path.join(pasta, "centro_5_estagios.png"))
    print("ok")


# lotação do Armazém: pilhas de estoque (Prompts 8 e 9) em frente, sobrepostas no código
# posições em pixels do quadro do Armazém (âncora (135, 220)), pé de cada pilha
LOTACAO = {
    "vazio": [],
    "medio": [("jazidas/final/pilha_ferro_media.png", (205, 262)), ("vegetacao/final/madeira_toras_m.png", (92, 270))],
    "cheio": [("jazidas/final/pilha_ferro_grande.png", (212, 262)), ("jazidas/final/pilha_carvao_media.png", (168, 280)),
              ("vegetacao/final/madeira_toras_g.png", (88, 268)), ("vegetacao/final/madeira_tabuas_m.png", (130, 286))],
}


def lotacao(pasta):
    base = Image.open("armazem/pronto.png").convert("RGBA")
    AM = (255, 230, 150); W, H = base.size
    c = Image.new("RGB", (3 * (W + 20), H + 60), (62, 58, 54)); d = ImageDraw.Draw(c)
    for k, (nome, pilhas) in enumerate(LOTACAO.items()):
        q = Image.new("RGBA", (W + 20, H + 40)); q.alpha_composite(base, (0, 0))
        for f, (px, py) in sorted(pilhas, key=lambda t: t[1][1]):
            im = Image.open(f).convert("RGBA")
            q.alpha_composite(im, (px - im.width // 2, py - im.height))
        c.paste(q, (k * (W + 20), 16), q); d.text((k * (W + 20) + 4, 2), "armazem " + nome, fill=AM)
    c.save(os.path.join(pasta, "armazem_lotacao.png"))


if __name__ == "__main__":
    if sys.argv[1] == "lotacao":
        lotacao(sys.argv[2]); sys.exit()
    confere() if sys.argv[1] == "confere" else entrega(sys.argv[2])
