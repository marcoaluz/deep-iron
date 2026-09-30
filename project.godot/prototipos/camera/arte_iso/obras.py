"""PROTÓTIPO: obra 1 e obra 3 montadas por script a partir do esqueleto (obra 2, IA) e do pronto.

  python obras.py <predio> [<predio> ...]   -> <predio>/obra_1.png, obra_3.png (+ obra_2.png baixado)
  python obras.py entrega <pasta> <predio>...  -> prancha_<predio>.png e obra_<predio>.gif

Por que: cada estágio de obra pela IA custa 25 gerações por prédio. Com o esqueleto e o
pronto no MESMO quadro (a IA desenha o esqueleto por cima do pronto), dá pra cortar por
altura, na horizontal de tela:
- obra 1 = só a faixa de baixo do ESQUELETO (fundação e primeira fiada) + o material solto
  que a IA pôs no chão em volta;
- obra 3 = o PRONTO até ~65% da altura + o ESQUELETO acima disso (telhado ainda em caibros).
A linha de corte segue a inclinação do telhado 2:1 (não é reta), pra não cortar paredes no meio.
"""
import sys, os, json, subprocess
import numpy as np
from PIL import Image, ImageDraw


def baixa(p):
    t = json.load(open("%s/jobs.json" % p, encoding="utf-8"))
    f = "%s/obra_2.png" % p
    if not os.path.exists(f):
        subprocess.run(["curl", "-s", "-f", "-A", "curl/8", "-o", f,
                        "https://api.pixellab.ai/mcp/images/%s/download" % t["obra_2"]], check=True)


def corte(a, frac):
    """máscara (True = parte de BAIXO) por uma linha que acompanha a base 2:1 do prédio:
    y_corte(x) = y_base(x) - frac * altura, onde y_base é o pé da silhueta naquela coluna."""
    op = a[..., 3] > 40
    H, W = op.shape
    ys = np.where(op.any(1))[0]
    alt = ys[-1] - ys[0]
    pe = np.full(W, ys[-1])
    for x in range(W):
        col = np.where(op[:, x])[0]
        if len(col):
            pe[x] = col[-1]
    # suaviza o pé (mediana móvel) pra não pegar pedrinha solta
    k = 9
    pe_s = np.array([np.median(pe[max(0, x - k):x + k + 1]) for x in range(W)])
    yy = np.arange(H)[:, None]
    return yy >= (pe_s[None, :] - frac * alt)


def monta(p):
    baixa(p)
    pr = np.array(Image.open("%s/pronto.png" % p).convert("RGBA"))
    es_im = Image.open("%s/obra_2.png" % p).convert("RGBA")
    if es_im.size[::-1] != pr.shape[:2]:
        es_im = es_im.resize(pr.shape[1::-1], Image.NEAREST)
    es = np.array(es_im)
    # obra 1: fundação (faixa de baixo do esqueleto, ~18% da altura)
    m1 = corte(es, 0.18)
    o1 = es.copy(); o1[~m1] = 0
    # obra 3: pronto embaixo (~62%), esqueleto em cima
    m3 = corte(pr, 0.62)
    o3 = es.copy(); o3[m3] = 0
    baixo = pr.copy(); baixo[~m3] = 0
    o3 = np.where(baixo[..., 3:4] > 40, baixo, o3)
    Image.fromarray(o1).save("%s/obra_1.png" % p)
    Image.fromarray(o3).save("%s/obra_3.png" % p)
    print(p, "ok")


def entrega(pasta, nomes):
    AM = (255, 230, 150)
    os.makedirs(pasta, exist_ok=True)
    for p in nomes:
        fs = ["%s/obra_%d.png" % (p, i) for i in (1, 2, 3)] + ["%s/pronto.png" % p]
        ims = [Image.open(f).convert("RGBA") for f in fs]
        W, H = ims[-1].size
        c = Image.new("RGB", (4 * W + 10, H + 18), (62, 58, 54)); d = ImageDraw.Draw(c)
        fr = []
        for k, (im, r) in enumerate(zip(ims, ["obra 1", "obra 2", "obra 3", "pronto"])):
            im = im.resize((W, H), Image.NEAREST) if im.size != (W, H) else im
            c.paste(im, (5 + k * W, 18), im); d.text((8 + k * W, 3), r, fill=AM)
            g = Image.new("RGB", (W, H + 16), (62, 58, 54)); g.paste(im, (0, 16), im)
            ImageDraw.Draw(g).text((4, 2), "%s: %s" % (p, r), fill=AM); fr.append(g)
        c.save(os.path.join(pasta, "prancha_%s.png" % p))
        fr[0].save(os.path.join(pasta, "obra_%s.gif" % p), save_all=True, append_images=fr[1:], duration=900, loop=0)
    print("ok")


if __name__ == "__main__":
    if sys.argv[1] == "entrega":
        entrega(sys.argv[2], sys.argv[3:])
    else:
        for p in sys.argv[1:]:
            monta(p)
