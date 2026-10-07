"""Bloco 76: o cassetete do guarda e o machado do lenhador aparecem NA MÃO só em alguns quadros da caminhada de 8
(a geração desenha o item numa passada e não na outra). O jogo já desenha a ferramenta/arma NAS COSTAS
(iso_bonecos._item), então o certo é a mão vazia em todos: cada quadro com o item vai pro edit_image_pixen
("tira o item da mão") e volta no lugar; SO/NO são o espelho de SE/NE.

  python itens_mao.py piloto                  -> 2 quadros em fundo76/itens_mao/piloto/
  python itens_mao.py lote [pastas]           -> todos os quadros SE/NE (edita, compõe só a região do item,
                                                refaz o espelho SO/NO; os originais ficam em itens_mao/antes)
  python itens_mao.py recompoe                -> refaz a composição (a ESCOLHA por quadro) das edições salvas, sem gerar
"""
import sys, os, base64, io, time
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "tools", "pixellab"))
import pl, gen
from PIL import Image, ImageOps

AQUI = os.path.dirname(os.path.abspath(__file__))
ARTE = os.path.join(AQUI, "..")
PEDIDO = {"guarda": "Remove the wooden club / baton from the character's hand: the hand is EMPTY and relaxed. "
                    "Keep everything else exactly the same (pose, coat, helmet, colors, outline).",
          "lenhador": "Remove the axe from the character's hand: the hand is EMPTY and relaxed. "
                      "Keep everything else exactly the same (pose, clothes, colors, outline)."}


def _b64(im):
    b = io.BytesIO()
    im.save(b, "PNG")
    return base64.b64encode(b.getvalue()).decode()


def edita(png, pedido):
    im = Image.open(png).convert("RGBA")
    w, h = im.size
    W, H = (w + 3) // 4 * 4, (h + 3) // 4 * 4
    if (W, H) != (w, h):
        pad = Image.new("RGBA", (W, H))
        pad.paste(im, (0, 0))
        im = pad
    t = gen._texto(pl.call("edit_image_pixen", {"image_base64": _b64(im), "description": pedido}))
    job = [l.split(":", 1)[1].strip() for l in t.splitlines() if l.lower().startswith("job")]
    if not job:
        raise RuntimeError(t[:400])
    for _ in range(60):
        time.sleep(6)
        r = pl.call("get_image", {"job_id": job[0]})
        txt = gen._texto(r)
        if "completed" in txt:
            for msg in r:
                for c in msg.get("result", {}).get("content", []):
                    if c.get("type") == "image":
                        out = Image.open(io.BytesIO(base64.b64decode(c["data"]))).convert("RGBA")
                        return out.crop((0, 0, w, h))
        if "failed" in txt.lower() or "error:" in txt.lower():
            raise RuntimeError(txt[:400])
    raise RuntimeError("demorou")


def compoe(orig, edit, folga=8, minimo=12):
    """Só a região do item vem do quadro editado (o resto do original fica intacto): o que tinha no original e
    sumiu no editado (o item pra fora do corpo, pedaços de >= `minimo` px) + `folga` px em volta; nessa região
    as cores do editado vão pra cor mais perto da paleta do próprio original (o pixen às vezes clareia tudo)."""
    import numpy as np
    O = np.array(orig.convert("RGBA")).astype(int)
    E = np.array(edit.convert("RGBA")).astype(int)
    sumiu = (O[..., 3] > 40) & (E[..., 3] <= 40)
    item = np.zeros_like(sumiu)
    visto = np.zeros_like(sumiu)
    H, W = sumiu.shape
    for y0, x0 in zip(*np.nonzero(sumiu)):  # pedaços ligados (vizinhança 8)
        if visto[y0, x0]:
            continue
        pilha, comp = [(y0, x0)], []
        visto[y0, x0] = True
        while pilha:
            y, x = pilha.pop()
            comp.append((y, x))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < H and 0 <= xx < W and sumiu[yy, xx] and not visto[yy, xx]:
                        visto[yy, xx] = True
                        pilha.append((yy, xx))
        if len(comp) >= minimo:
            for y, x in comp:
                item[y, x] = True
    if not item.any():
        return orig, 0
    regiao = item.copy()
    for _ in range(folga):  # dilata 1 px por volta (vizinhança 4)
        r = regiao.copy()
        r[1:, :] |= regiao[:-1, :]
        r[:-1, :] |= regiao[1:, :]
        r[:, 1:] |= regiao[:, :-1]
        r[:, :-1] |= regiao[:, 1:]
        regiao = r
    pal = np.unique(O[O[..., 3] > 40][:, :3], axis=0)
    R = O.copy()
    ys, xs = np.nonzero(regiao)
    for y, x in zip(ys, xs):
        if E[y, x, 3] > 40:
            c = E[y, x, :3]
            R[y, x, :3] = pal[np.argmin(((pal - c) ** 2).sum(1))]
            R[y, x, 3] = 255
        else:
            R[y, x, 3] = 0
    return Image.fromarray(R.astype("uint8")), int(item.sum())


def _manchas(mask, minimo):
    """pedaços ligados (vizinhança 8) com >= minimo px."""
    import numpy as np
    out = np.zeros_like(mask)
    visto = np.zeros_like(mask)
    H, W = mask.shape
    for y0, x0 in zip(*np.nonzero(mask)):
        if visto[y0, x0]:
            continue
        pilha, comp = [(y0, x0)], []
        visto[y0, x0] = True
        while pilha:
            y, x = pilha.pop()
            comp.append((y, x))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < H and 0 <= xx < W and mask[yy, xx] and not visto[yy, xx]:
                        visto[yy, xx] = True
                        pilha.append((yy, xx))
        if len(comp) >= minimo:
            for y, x in comp:
                out[y, x] = True
    return out


def _dilata(m, n):
    for _ in range(n):
        r = m.copy()
        r[1:, :] |= m[:-1, :]
        r[:-1, :] |= m[1:, :]
        r[:, 1:] |= m[:, :-1]
        r[:, :-1] |= m[:, 1:]
        m = r
    return m


def compoe2(orig, edit, limiar=60, minimo=14, folga=2):
    """Versão 2: o editado inteiro vai pra paleta do original (tira o desvio de cor do pixen); a região trocada
    são as MANCHAS grandes de diferença (o item, por cima ou pra fora do corpo) — o resto (redesenho miúdo do
    pixen, pontos soltos) fica o original. Só entra mancha que encosta na metade de baixo do boneco (mãos e
    pernas: onde o item fica), pra não mexer em cabeça e ombros."""
    import numpy as np
    O = np.array(orig.convert("RGBA")).astype(int)
    E = np.array(edit.convert("RGBA")).astype(int)
    pal = np.unique(O[O[..., 3] > 40][:, :3], axis=0)
    Em = E.copy()
    vis = E[..., 3] > 40
    cores = E[vis][:, :3]
    idx = np.argmin(((cores[:, None, :] - pal[None, :, :]) ** 2).sum(2), axis=1)
    Em[vis, :3] = pal[idx]
    ao, ae = O[..., 3] > 40, E[..., 3] > 40
    # só o que SAI (item pra fora do corpo) ou TROCA por dentro; pixel novo fora do contorno original nunca entra
    # (o pixen às vezes devolve o boneco com uma borda laranja, ou desenha um braço a mais)
    # a borda do boneco (2 px pra dentro) só muda quando o pixel SAI (o item): o pixen redesenha o contorno
    # com outra cor e isso não é o item
    miolo = ~_dilata(~ao, 2)
    dif = (ao & ~ae) | (miolo & ae & (np.abs(Em[..., :3] - O[..., :3]).sum(2) > limiar))
    ys = np.nonzero(ao)[0]
    corte = ys.min() + (ys.max() - ys.min()) * 0.38
    dif[: int(corte), :] = False
    m = _manchas(dif, minimo)
    if not m.any():
        return orig, 0
    regiao = _dilata(m, folga)
    regiao &= ao & (miolo | (ao & ~ae))  # (nada fora do contorno original; na borda, só o que sai)
    R = O.copy()
    R[regiao] = Em[regiao]
    R[regiao & ~ae, 3] = 0
    R[regiao & ae, 3] = 255
    return Image.fromarray(R.astype("uint8")), int(m.sum())


def tipo(pasta):
    return "guarda" if "guarda" in pasta else "lenhador"


def piloto():
    d = os.path.join(AQUI, "itens_mao", "piloto")
    os.makedirs(d, exist_ok=True)
    for pasta, dr, i in (("casaco_guarda", "NE", 1), ("lenhador", "SE", 6)):
        src = os.path.join(ARTE, pasta, "caminhada", dr, "%d.png" % i)
        out = edita(src, PEDIDO[tipo(pasta)])
        Image.open(src).save(os.path.join(d, "%s_%s_%d_antes.png" % (pasta, dr, i)))
        out.save(os.path.join(d, "%s_%s_%d_depois.png" % (pasta, dr, i)))
        print("ok", pasta, dr, i)


PASTAS = ["guarda", "guarda_mulher", "casaco_guarda", "casaco_guarda_mulher",
          "lenhador", "lenhadora", "casaco_lenhador", "casaco_lenhadora"]


def _um(args):
    pasta, dr, i = args
    src = os.path.join(ARTE, pasta, "caminhada", dr, "%d.png" % i)
    bak_dir = os.path.join(AQUI, "itens_mao", "antes", pasta, dr)
    os.makedirs(bak_dir, exist_ok=True)
    bak = os.path.join(bak_dir, "%d.png" % i)
    if not os.path.exists(bak):
        Image.open(src).save(bak)
    orig = Image.open(bak).convert("RGBA")  # sempre a partir do original (rodar de novo não acumula)
    for tentativa in range(3):
        try:
            ed = edita(bak, PEDIDO[tipo(pasta)])
            break
        except Exception as e:
            print("  repete", pasta, dr, i, str(e)[:120], flush=True)
            time.sleep(20)
    else:
        return pasta, dr, i, -1
    ed.save(os.path.join(bak_dir, "%d_pixen.png" % i))
    out, k = _escolhe(pasta, dr, i, orig, ed)
    out.save(src)
    esp = {"SE": "SO", "NE": "NO"}[dr]
    ImageOps.mirror(out).save(os.path.join(ARTE, pasta, "caminhada", esp, "%d.png" % i))
    return pasta, dr, i, k


def lote(pastas):
    """todos os quadros (SE/NE) dessas pastas; o quadro sem item na mão volta igual."""
    from concurrent.futures import ThreadPoolExecutor
    tarefas = [(p, d, i) for p in (pastas or PASTAS) for d in ("SE", "NE") for i in range(8)]
    with ThreadPoolExecutor(8) as ex:
        for pasta, dr, i, k in ex.map(_um, tarefas):
            print("%-22s %s %d  item: %s px" % (pasta, dr, i, k), flush=True)


## Por quadro (conferido um a um nas folhas antes/v1/v2): "o" = o original (sem item na mão — o editor às vezes
## inventa um braço), "1" = compoe (só o que sai do contorno: limpo quando o item fica pra fora do corpo),
## "2" = compoe2 (as manchas por dentro também: quando o item fica na frente do corpo).
ESCOLHA = {
    ("guarda", "SE"): "oooooooo", ("guarda", "NE"): "o1211ooo",
    ("guarda_mulher", "SE"): "22222111", ("guarda_mulher", "NE"): "11211111",
    ("casaco_guarda", "SE"): "o11ooo1o", ("casaco_guarda", "NE"): "1111o22o",
    ("casaco_guarda_mulher", "SE"): "22222222", ("casaco_guarda_mulher", "NE"): "11111121",
    ("lenhador", "SE"): "22222112", ("lenhador", "NE"): "11111111",
    ("lenhadora", "SE"): "22221111", ("lenhadora", "NE"): "22222222",
    ("casaco_lenhador", "SE"): "22222222", ("casaco_lenhador", "NE"): "11111111",
    ("casaco_lenhadora", "SE"): "22222222", ("casaco_lenhadora", "NE"): "22222222",
}
SEM_ITEM = {k: tuple(i for i, c in enumerate(v) if c == "o") for k, v in ESCOLHA.items()}


def _escolhe(pasta, dr, i, orig, ed):
    c = ESCOLHA.get((pasta, dr), "22222222")[i]
    if c == "o":
        return orig, 0
    return compoe(orig, ed) if c == "1" else compoe2(orig, ed)


def recompoe():
    """refaz todos os quadros a partir do original e da edição salvos (sem gerar de novo), com o compoe2."""
    for pasta in PASTAS:
        for dr in ("SE", "NE"):
            base = os.path.join(AQUI, "itens_mao", "antes", pasta, dr)
            for i in range(8):
                orig = Image.open(os.path.join(base, "%d.png" % i)).convert("RGBA")
                out, k = _escolhe(pasta, dr, i, orig, Image.open(os.path.join(base, "%d_pixen.png" % i)).convert("RGBA"))
                out.save(os.path.join(ARTE, pasta, "caminhada", dr, "%d.png" % i))
                ImageOps.mirror(out).save(os.path.join(ARTE, pasta, "caminhada", {"SE": "SO", "NE": "NO"}[dr], "%d.png" % i))
                print("%-22s %s %d  item: %d px" % (pasta, dr, i, k))


if __name__ == "__main__":
    if sys.argv[1] == "piloto":
        piloto()
    elif sys.argv[1] == "recompoe":
        recompoe()
    else:
        lote(sys.argv[2:])
