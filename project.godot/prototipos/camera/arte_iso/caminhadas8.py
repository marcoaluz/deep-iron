"""Bloco 76: a CAMINHADA DE 8 QUADROS do elenco inteiro (o Marco: "verificar a movimentação dos personagens
todos"). A de antes era o modelo de 4 quadros do PixelLab (`walking-4-frames`): dura. Esta é o modelo
`walking-8-frames` no modo `skeleton-v3` — o esqueleto do modelo posto no próprio desenho do personagem (não
redesenha cada quadro: a roupa e o rosto ficam iguais em todos; o modo-modelo comum trocava o colete do
mineiro no meio do ciclo). Piloto aprovado no minerador (docs/arte/bloco76/).

  python caminhadas8.py pede [pasta ...]     pede as que faltam (SE e NE), em levas, e espera
  python caminhadas8.py baixa [pasta ...]    baixa em <pasta>/caminhada8/<D>/<i>.png (SO/NO = espelho)
  python caminhadas8.py troca [pasta ...]    caminhada -> caminhada4 (reserva), caminhada8 -> caminhada,
                                             grava caminhada/anim.json (âncora por direção) e refaz a
                                             caminhada com picareta do minerador
Depois: python integra.py caminhadas <pastas...>  (tiras, tons de pele, pé no chão, bonecos.json).
"""
import glob, json, os, sys, time
import numpy as np
from PIL import Image, ImageOps

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(AQUI, "..", "..", "..", "..", "tools", "pixellab"))
import chars, pl, gen  # noqa: E402

NOME = "caminhada8_esq"
LEVA = int(os.environ.get("LEVA", "10"))  # personagens por leva (2 direções cada; o PixelLab roda 20 jobs juntos)


def elenco():
    """[(pasta, id do personagem)] — as bases, os casacos e os trajes."""
    out = []
    for k, v in json.load(open(os.path.join(AQUI, "elenco.json"), encoding="utf-8")).items():
        if not k.startswith("_") and v.get("char"):
            out.append((k, v["char"]))
    for arq in ("casaco_ids.json", "trajes_ids.json"):
        for k, v in json.load(open(os.path.join(AQUI, arq), encoding="utf-8")).items():
            if not k.startswith("_") and isinstance(v, dict) and v.get("char"):
                out.append((k, v["char"]))
    return out


def tem(cid):
    i = chars.info(cid)
    a = i["anims"].get(NOME)
    return a is not None and len(a["dirs"]) >= 2, "pending jobs" in i["texto"]


def pede(alvos):
    fila = [(p, c) for p, c in alvos]
    while fila:
        leva, fila = fila[:LEVA], fila[LEVA:]
        enviados = []
        for pasta, cid in leva:
            pronto, pendente = tem(cid)
            if pronto or pendente:
                print("  %-26s já tem (ou está gerando)" % pasta)
                enviados.append((pasta, cid))
                continue
            for _ in range(60):  # sem vaga (20 jobs ao mesmo tempo): espera e tenta de novo
                t = gen._texto(pl.call("animate_character", {"character_id": cid, "template_animation_id": "walking-8-frames",
                                                              "mode": "skeleton-v3", "animation_name": NOME,
                                                              "directions": ["south-east", "north-east"]}))
                if "job slots" not in t:
                    break
                time.sleep(30)
            linha = [l for l in t.splitlines() if l.startswith(("directions", "status", "cost", "error", "Error"))]
            print("  %-26s pedido: %s" % (pasta, " | ".join(linha)[:150]))
            enviados.append((pasta, cid))
        for _ in range(80):  # espera a leva (até ~40 min)
            faltam = [p for p, c in enviados if not tem(c)[0]]
            if not faltam:
                break
            time.sleep(30)
        print("leva pronta:", [p for p, _ in enviados], "faltando:", [p for p, c in enviados if not tem(c)[0]], flush=True)


def baixa(alvos):
    for pasta, cid in alvos:
        dst = os.path.join(AQUI, pasta)
        n = chars.baixa_anim(cid, dst, NOME, "caminhada8")
        for de, para in (("SE", "SO"), ("NE", "NO")):
            fs = sorted(glob.glob(os.path.join(dst, "caminhada8", de, "*.png")), key=lambda f: int(os.path.basename(f)[:-4]))
            os.makedirs(os.path.join(dst, "caminhada8", para), exist_ok=True)
            for f in fs:
                ImageOps.mirror(Image.open(f).convert("RGBA")).save(os.path.join(dst, "caminhada8", para, os.path.basename(f)))
        print("  %-26s %d quadros baixados" % (pasta, n))


def ancora(fs):
    """a âncora da direção: o meio dos pés (mediana dos quadros) na beira de baixo do pé mais baixo."""
    xs, ys = [], []
    for f in fs:
        a = np.array(Image.open(f).convert("RGBA"))[..., 3] > 40
        lin = np.nonzero(a.sum(1) >= 2)[0]
        if not len(lin):
            continue
        yb = lin.max()
        _, cols = np.nonzero(a[yb - 2:yb + 1])
        xs.append(float(cols.mean()))
        ys.append(float(yb + 1))
    return [round(float(np.median(xs)), 1), max(ys)]


def troca(alvos):
    import shutil
    import picareta_overlay as po
    for pasta, _ in alvos:
        d = os.path.join(AQUI, pasta)
        novo = os.path.join(d, "caminhada8")
        if not os.path.isdir(novo):
            print("  %-26s sem caminhada8 (pula)" % pasta)
            continue
        velho = os.path.join(d, "caminhada")
        if os.path.isdir(velho) and not os.path.isdir(os.path.join(d, "caminhada4")):
            shutil.move(velho, os.path.join(d, "caminhada4"))
        elif os.path.isdir(velho):
            shutil.rmtree(velho)
        shutil.move(novo, velho)
        meta = {}
        for dr in ("SE", "NE", "SO", "NO"):
            fs = sorted(glob.glob(os.path.join(velho, dr, "*.png")), key=lambda f: int(os.path.basename(f)[:-4]))
            if fs:
                meta[dr] = {"ancora": ancora(fs)}
        meta["_obs"] = "Bloco 76: caminhada de 8 quadros (walking-8-frames, skeleton-v3); a de 4 está em caminhada4/"
        json.dump(meta, open(os.path.join(velho, "anim.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
        if os.path.isdir(os.path.join(d, "com_picareta")):  # a picareta colada nas costas, quadro a quadro
            for dr in ("SE", "NE"):
                fs = sorted(glob.glob(os.path.join(velho, dr, "*.png")), key=lambda f: int(os.path.basename(f)[:-4]))
                comp = [po.compose(Image.open(f).convert("RGBA"), po.CONFIG[dr]) for f in fs]
                for alvo, fr in ((dr, comp), ("SO" if dr == "SE" else "NO", [ImageOps.mirror(c) for c in comp])):
                    pd = os.path.join(d, "com_picareta", alvo)
                    for f in glob.glob(os.path.join(pd, "*.png")):
                        os.remove(f)
                    os.makedirs(pd, exist_ok=True)
                    for k, c in enumerate(fr):
                        c.save(os.path.join(pd, "%d.png" % k))
            meta2 = {dr: dict(meta[dr]) for dr in ("SE", "NE", "SO", "NO") if dr in meta}
            json.dump(meta2, open(os.path.join(d, "com_picareta", "anim.json"), "w", encoding="utf-8"), indent=1)
        print("  %-26s trocada (âncoras %s)" % (pasta, {k: v["ancora"] for k, v in meta.items() if not k.startswith("_")}))


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    todos = elenco()
    so = sys.argv[2:]
    alvos = [(p, c) for p, c in todos if not so or p in so]
    {"pede": pede, "baixa": baixa, "troca": troca}.get(cmd, lambda a: print(__doc__))(alvos)
