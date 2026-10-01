"""PROTÓTIPO: objetos e props (Prompt 14).

  python objetos.py monta          -> final/*.png, final/fogo_*.gif (chama animada por script)
  python objetos.py prancha <png>  -> prancha de entrega

Cada lote de 16 candidatos veio com um objeto diferente por candidato (o pedido listava os
objetos). Aqui cada candidato ganha nome. Fogo: os pixels de chama (laranja/amarelo
claros) tremem em 4 quadros (brilho sorteado + a ponta da chama sobe e desce 1 px).
"""
import sys, os, random, colorsys
from PIL import Image, ImageOps, ImageDraw

NOMES = {
    "armazenagem": ["caixote", "caixotes_2", "caixote_palha", "barril", "tambor_oleo", "barris_2", "saco", "sacos",
                    "tabuas", "sucata", "pneus", "roda_carroca", "corrente", "corda", "palete", "caixa_ferramentas"],
    "luzes": ["tocha_parede", "tocha_chao", "tocha_apagada", "lampiao_gancho", "lampiao_poste", "fogueira",
              "fogueira_apagada", "braseiro", "poste_rua", "tocha_parede_2", "tocha_apagada_2", "lampiao_caixote",
              "fogueira_2", "braseiro_apagado", "lampioes_mesa", "lampiao_pequeno"],
    "placas_estruturas": ["placa_caveira", "placa_raio", "placa_gas", "placa_perigo", "poste", "andaime", "escada_mao",
                          "varal", "poco", "banco", "mesa", "bigorna", "ferramentas_caixote", "placa_direcao",
                          "poste_cruzado", "ferramentas_encostadas"],
    "pilhas_recurso": ["pedra_p", "tijolo_p", "comida_p", "couro_p", "pedra_m", "tijolo_m", "comida_m", "couro_m",
                       "carvao_p", "aco_p", "carvao_m", "aco_m", "pedra_g", "tijolo_g", "comida_g", "couro_g"],
    "destrocos": ["chapa_enterrada", "carcaca_maquina", "porta_carro", "poste_caido", "bloco_concreto", "ossos_cranio",
                  "costelas", "braco_robo", "painel_listrado", "barril_vazando", "cano", "trilho_quebrado",
                  "corrente_enferrujada", "furadeira_velha", "caixas_metal", "vagonete_velho"],
}
VAGONETE = {"vazio": 4, "cheio": 3}
FOGO = ["tocha_parede", "tocha_chao", "fogueira", "braseiro", "tocha_parede_2", "fogueira_2"]


def C(p, i):
    return Image.open("%s/candidatos/c%02d.png" % (p, i)).convert("RGBA")


def sem_base_clara(im):
    """sombra desenhada ao contrário (mancha clara cinza na base): some."""
    out = im.copy(); px = out.load(); H = out.height
    for y in range(int(H * 0.55), H):
        for x in range(out.width):
            p = px[x, y]
            if p[3] > 40:
                h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in p[:3]))
                if v > 0.62 and s < 0.12:
                    px[x, y] = (0, 0, 0, 0)
    return out


def salva(im, nome):
    os.makedirs("final", exist_ok=True)
    im = sem_base_clara(im)
    b = im.getbbox()
    (im.crop(b) if b else im).save("final/%s.png" % nome)


def e_chama(p):
    if p[3] < 40:
        return False
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in p[:3]))
    return 0.02 < h < 0.17 and s > 0.45 and v > 0.7


def fogo(im, seed=0):
    rnd = random.Random(seed)
    fr = []
    W, H = im.size
    for f in range(4):
        out = im.copy(); px = out.load(); src = im.load()
        for y in range(H):
            for x in range(W):
                if e_chama(src[x, y]):
                    r, g, b, a = src[x, y]
                    k = rnd.uniform(0.82, 1.12)
                    px[x, y] = (min(255, int(r * k)), min(255, int(g * k)), min(255, int(b * k)), a)
        # a ponta da chama: sobe 1 px nos quadros 1 e 3, some 1 px no 2
        for x in range(W):
            ys = [y for y in range(H) if e_chama(src[x, y])]
            if ys:
                y0 = min(ys)
                if f in (1, 3) and y0 > 0 and rnd.random() < 0.6:
                    px[x, y0 - 1] = src[x, y0]
                elif f == 2 and rnd.random() < 0.5:
                    px[x, y0] = (0, 0, 0, 0)
        fr.append(out)
    return fr


def monta():
    for lote, nomes in NOMES.items():
        for i, n in enumerate(nomes):
            salva(C(lote, i), n)
    for n, i in VAGONETE.items():
        v = C("vagonete", i); salva(v, "vagonete_%s_SE" % n); salva(ImageOps.mirror(v), "vagonete_%s_SO" % n)
    g = Image.open("guindaste/candidatos/c00.png").convert("RGBA"); salva(g, "guindaste_pedreira")
    for n in FOGO:
        im = Image.open("final/%s.png" % n).convert("RGBA")
        fr = fogo(im, hash(n) % 1000)
        for k, f in enumerate(fr):
            f.save("final/%s_f%d.png" % (n, k))
        big = [f.resize((f.width * 4, f.height * 4), Image.NEAREST) for f in fr]
        bg = [Image.new("RGBA", big[0].size, (40, 36, 34, 255)) for _ in big]
        for b_, f in zip(bg, big):
            b_.alpha_composite(f)
        bg[0].save("final/fogo_%s.gif" % n, save_all=True, append_images=bg[1:], duration=120, loop=0)
    print("ok")


def prancha(saida):
    AM = (255, 230, 150)
    secoes = [("ARMAZENAGEM", NOMES["armazenagem"]), ("LUZES (as chamas animam por script)", NOMES["luzes"]),
              ("PLACAS, CERCAS, MOBILIA", NOMES["placas_estruturas"]), ("PILHAS DE RECURSO (P/M/G)", NOMES["pilhas_recurso"]),
              ("DESTROCOS PRE-COLAPSO E OSSOS", NOMES["destrocos"]),
              ("VAGONETE vazio/cheio (SE e espelho SO)", ["vagonete_vazio_SE", "vagonete_vazio_SO", "vagonete_cheio_SE", "vagonete_cheio_SO"])]
    c = Image.new("RGB", (1520, 1180), (46, 44, 40)); d = ImageDraw.Draw(c)
    y = 6
    for tit, nomes in secoes:
        d.text((8, y), tit, fill=AM); y += 14
        x = 8; hmax = 0
        for n in nomes:
            im = Image.open("final/%s.png" % n).convert("RGBA"); im = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
            if x + im.width > 1240:
                break
            c.paste(im, (x, y), im); x += im.width + 6; hmax = max(hmax, im.height)
        y += hmax + 10
    g = Image.open("final/guindaste_pedreira.png").convert("RGBA")
    d.text((1250, 6), "GUINDASTE DA PEDREIRA", fill=AM); c.paste(g, (1260, 24), g)
    c.save(saida)


if __name__ == "__main__":
    monta() if sys.argv[1] == "monta" else prancha(sys.argv[2])
