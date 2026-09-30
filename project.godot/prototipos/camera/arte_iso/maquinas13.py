"""PROTÓTIPO: máquinas e grandes estruturas (Prompt 13).

  python maquinas13.py monta           -> final_maquinas/*.png e GIFs
  python maquinas13.py prancha <pasta> -> pranchas de entrega

Etapas sem gerar de novo: as peças entram por REGIÃO do desenho pronto, por cima da etapa
anterior (mesmo quadro, mesma âncora). A etapa inicial de cada uma veio da IA (esqueleto da
escavadeira; fundação do escudo por inpaint).
"""
import sys, os, json, subprocess
import numpy as np
from PIL import Image, ImageOps, ImageDraw
sys.path.insert(0, "relevo")
from superficie import escurece_hsv

OUT = "final_maquinas"
REATORES = {"vapor": 1, "diesel": 5, "cristal": 6, "solar": 10, "fusao": 13}
SATELITE = [1, 0, 3, 2]            # frente, esquerda, trás, direita (a antena girando)
HOLOFOTE = 4
ESCUDO = {  # regiões (x0, y0, x1, y1) no quadro 310x420
    "bobinas": [(38, 122, 78, 282), (232, 122, 268, 278), (163, 178, 207, 318)],   # a de trás entra com o núcleo
    "nucleo": [(82, 134, 238, 302), (112, 84, 142, 138)],
}
ELEVADOR_GAIOLA = (62, 180, 120, 268)


def regiao(a, rects):
    m = np.zeros(a.shape[:2], bool)
    for x0, y0, x1, y1 in rects:
        m[y0:y1, x0:x1] = True
    return m


def por_cima(base, pronto, mask):
    """a etapa seguinte = a anterior + os pixels do pronto dentro da região."""
    b = base.copy()
    sel = mask & (pronto[..., 3] > 40)
    b[sel] = pronto[sel]
    return b


def sem_migalha(a, minimo=25):
    """tira pedacinhos soltos (< minimo px) que o recorte por região deixou (sem scipy)."""
    from collections import deque
    op = a[..., 3] > 40; H, W = op.shape; vis = np.zeros_like(op)
    for y0 in range(H):
        for x0 in range(W):
            if op[y0, x0] and not vis[y0, x0]:
                q = deque([(y0, x0)]); vis[y0, x0] = True; comp = []
                while q:
                    y, x = q.popleft(); comp.append((y, x))
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            ny, nx = y + dy, x + dx
                            if 0 <= ny < H and 0 <= nx < W and op[ny, nx] and not vis[ny, nx]:
                                vis[ny, nx] = True; q.append((ny, nx))
                if len(comp) < minimo:
                    for y, x in comp:
                        a[y, x] = 0
    return a


def salva(im, nome):
    os.makedirs(OUT, exist_ok=True)
    (im if isinstance(im, Image.Image) else Image.fromarray(im)).save("%s/%s.png" % (OUT, nome))


def gif(frames, nome, dur=160):
    frames[0].save("%s/%s.gif" % (OUT, nome), save_all=True, append_images=frames[1:], duration=dur, loop=0, disposal=2)


def monta():
    # escudo: 4 etapas do jogo (fundacao, bobinas, nucleo, emissor)
    pr = np.array(Image.open("escudo/pronto.png").convert("RGBA"))
    e1 = np.array(Image.open("escudo/fundacao_inpaint.png").convert("RGBA").resize(pr.shape[1::-1]))
    # bobinas: dentro do retângulo, só a coluna de cobre (cor) + 1 px de contorno em volta
    import colorsys
    from PIL import ImageFilter
    cobre = np.zeros(pr.shape[:2], bool)
    for y, x in zip(*np.where(regiao(pr, ESCUDO["bobinas"]) & (pr[..., 3] > 40))):
        h, s_, v = colorsys.rgb_to_hsv(*(pr[y, x, :3] / 255))
        cobre[y, x] = 0.02 < h < 0.12 and s_ > 0.35
    # a coluna inteira: preenche na horizontal entre o primeiro e o último pixel de cobre de cada linha
    col = np.zeros_like(cobre)
    for x0, y0, x1, y1 in ESCUDO["bobinas"]:
        for y in range(y0, y1):
            xs = np.where(cobre[y, x0:x1])[0]
            if len(xs):
                col[y, x0 + xs[0]:x0 + xs[-1] + 1] = True
    col = np.array(Image.fromarray(col.astype(np.uint8) * 255).filter(ImageFilter.MaxFilter(3))) > 0
    e2 = por_cima(e1, pr, col & regiao(pr, ESCUDO["bobinas"]))
    e3 = por_cima(e2, pr, regiao(pr, ESCUDO["nucleo"]))
    for n, im in (("1_fundacao", e1), ("2_bobinas", e2), ("3_nucleo", e3), ("4_emissor", pr)):
        salva(sem_migalha(im.copy()), "escudo_%s" % n)
    # elevador: pronto, ruína, e o do abismo (mesmo desenho em basalto, mais escuro e frio)
    ep = Image.open("elevador/pronto.png").convert("RGBA")
    salva(ep, "elevador_pronto"); salva(Image.open("elevador/ruina.png").convert("RGBA"), "elevador_ruina")
    ab = escurece_hsv(ep, 0.72)
    salva(ab, "elevador_abismo_pronto")
    salva(escurece_hsv(Image.open("elevador/ruina.png").convert("RGBA"), 0.72), "elevador_abismo_ruina")
    salva(ep.crop(ELEVADOR_GAIOLA), "elevador_gaiola")
    # coletores
    salva(Image.open("coletor_madeira/quebrada.png").convert("RGBA"), "coletor_madeira_quebrado")
    salva(escurece_hsv(Image.open("coletor_madeira/consertada.png").convert("RGBA"), 0.72), "coletor_madeira_pronto")
    salva(Image.open("coletor_minerio/pronto.png").convert("RGBA"), "coletor_minerio_pronto")
    # reatores, satélite, holofote
    C = lambda p, i: Image.open("%s/candidatos/c%02d.png" % (p, i)).convert("RGBA")
    for n, i in REATORES.items():
        im = C("escavadeira/reatores", i); salva(im.crop(im.getbbox()), "reator_%s" % n)
    fr = []
    for k, i in enumerate(SATELITE):
        im = C("escudo/satelite_holofote", i); salva(im, "satelite_%d" % k); fr.append(im)
    gif([f.resize((f.width * 3, f.height * 3), Image.NEAREST) for f in fr], "satelite_girando", 250)
    salva(C("escudo/satelite_holofote", HOLOFOTE), "holofote")
    # escavadeira
    if os.path.exists("escavadeira/estrutura.png"):
        esc = np.array(Image.open("escavadeira/pronto.png").convert("RGBA"))
        est = np.array(Image.open("escavadeira/estrutura.png").convert("RGBA").resize(esc.shape[1::-1]))
        regs = json.load(open("escavadeira/regioes.json")) if os.path.exists("escavadeira/regioes.json") else {}
        salva(est, "escavadeira_1_estrutura")
        atual = est
        for k, parte in enumerate(("motor", "hidraulica", "cabine", "broca"), start=2):
            if parte in regs:
                atual = por_cima(atual, esc, regiao(esc, regs[parte]))
            salva(atual, "escavadeira_%d_%s" % (k, parte))
        salva(esc, "escavadeira_pronta")
        # broca girando: a região da broca sobe e desce 0-1-2-1 px e a hélice escurece em faixas
        if "broca" in regs:
            frames = []
            m = regiao(esc, regs["broca"])
            for f, dy in enumerate((0, 1, 2, 1)):
                b = esc.copy(); b[m] = 0
                s = np.roll(np.where(m[..., None], esc, 0), dy, 0)
                sel = s[..., 3] > 40
                b[sel] = s[sel]
                # listras da hélice: escurece uma faixa que desce (dá a ilusão de girar)
                ys, xs = np.where(np.roll(m, dy, 0) & (b[..., 3] > 40))
                band = ((ys + f * 3) // 3) % 4 == 0
                b[ys[band], xs[band], :3] = (b[ys[band], xs[band], :3] * 0.7).astype(np.uint8)
                frames.append(Image.fromarray(b))
            gif(frames, "escavadeira_perfurando", 110)
    print("ok")


def prancha(pasta):
    AM = (255, 230, 150)
    os.makedirs(pasta, exist_ok=True)

    def linha(nomes, rot, saida, esc=1.0):
        ims = [Image.open("%s/%s.png" % (OUT, n)).convert("RGBA") for n in nomes]
        ims = [i.resize((int(i.width * esc), int(i.height * esc)), Image.NEAREST) for i in ims]
        W = sum(i.width + 10 for i in ims) + 10; H = max(i.height for i in ims) + 20
        c = Image.new("RGB", (W, H), (62, 58, 54)); d = ImageDraw.Draw(c); x = 10
        for i, r in zip(ims, rot):
            c.paste(i, (x, H - i.height), i); d.text((x, 3), r, fill=AM); x += i.width + 10
        c.save(os.path.join(pasta, saida))
    linha(["escudo_1_fundacao", "escudo_2_bobinas", "escudo_3_nucleo", "escudo_4_emissor"],
          ["fundacao", "bobinas", "nucleo", "emissor (pronto)"], "prancha_escudo.png")
    linha(["elevador_ruina", "elevador_pronto", "elevador_abismo_ruina", "elevador_abismo_pronto", "elevador_gaiola"],
          ["elevador: ruina", "pronto", "abismo: ruina", "abismo: pronto", "gaiola (sprite)"], "prancha_elevadores.png")
    linha(["coletor_madeira_quebrado", "coletor_madeira_pronto", "coletor_minerio_pronto"],
          ["coletor de madeira: quebrado", "consertado", "coletor de minerio"], "prancha_coletores.png")
    linha(["reator_%s" % n for n in REATORES] + ["satelite_0", "satelite_1", "satelite_2", "satelite_3", "holofote"],
          list(REATORES) + ["satelite", "", "", "", "holofote"], "prancha_reatores_satelite.png", esc=2)
    esc = [n for n in ("escavadeira_1_estrutura", "escavadeira_2_motor", "escavadeira_3_hidraulica", "escavadeira_4_cabine",
                       "escavadeira_5_broca") if os.path.exists("%s/%s.png" % (OUT, n))]
    if esc:
        linha(esc, [n.split("_", 1)[1] for n in esc], "prancha_escavadeira.png", esc=0.6)
    for g in ("satelite_girando", "escavadeira_perfurando"):
        if os.path.exists("%s/%s.gif" % (OUT, g)):
            import shutil; shutil.copy("%s/%s.gif" % (OUT, g), os.path.join(pasta, g + ".gif"))
    print("ok")


if __name__ == "__main__":
    monta() if sys.argv[1] == "monta" else prancha(sys.argv[2])
