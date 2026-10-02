"""Ajudante de geração no PixelLab (via pl.py): manda em lote (até 8 de cada vez), espera e baixa.

  from gen import lote
  lote([("nome", "create_image_pixen", {...}, "D:/saida/nome.png"), ...], registro="D:/.../jobs.json")
"""
import json, os, re, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pl

MAX = 6  # o PixelLab aceita 10 de uma vez (personagens e animações contam junto)
FORCA = False  # True = refaz mesmo se o arquivo já existe


def _texto(msgs):
    out = []
    for m in msgs:
        r = m.get("result", m.get("error"))
        if isinstance(r, dict) and "content" in r:
            out += [c.get("text", "") for c in r["content"] if c.get("type") == "text"]
        else:
            out.append(json.dumps(r))
    return "\n".join(out)


def submete(tool, args):
    t = _texto(pl.call(tool, args))
    m = re.search(r"job_id:\s*([0-9a-f-]{36})", t) or re.search(r"\bid:\s*([0-9a-f-]{36})", t)
    custo = re.search(r"cost:\s*(\d+)", t)
    if not m:
        raise RuntimeError("sem job_id: " + t[:500])
    return m.group(1), int(custo.group(1)) if custo else None


def baixa(url, dest):
    req = urllib.request.Request(url, headers={"User-Agent": "curl/8.0"})
    with urllib.request.urlopen(req, timeout=120) as r:
        data = r.read()
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    open(dest, "wb").write(data)
    return len(data)


def baixa_candidatos(job, n, dest):
    """Baixa os n candidatos em <dest sem .png>/cNN.png e monta a grade em dest."""
    from PIL import Image, ImageDraw
    pasta = dest[:-4]
    os.makedirs(pasta, exist_ok=True)
    ims = []
    for i in range(n):
        f = os.path.join(pasta, "c%02d.png" % i)
        baixa("https://api.pixellab.ai/mcp/images/%s/download?index=%d" % (job, i), f)
        ims.append(Image.open(f).convert("RGBA"))
    w, h = ims[0].size
    cols = 8 if n > 8 else n
    rows = (n + cols - 1) // cols
    z = 2
    g = Image.new("RGBA", (cols * (w * z + 6), rows * (h * z + 16)), (58, 56, 52, 255))
    d = ImageDraw.Draw(g)
    for i, im in enumerate(ims):
        x, y = (i % cols) * (w * z + 6), (i // cols) * (h * z + 16)
        g.alpha_composite(im.resize((w * z, h * z), Image.NEAREST), (x, y + 14))
        d.text((x + 2, y), "c%02d" % i, fill=(255, 230, 140, 255))
    g.save(dest)


def estado(job):
    t = _texto(pl.call("get_image", {"job_id": job}))
    st = re.search(r"status:\s*(\w+)", t)
    return (st.group(1) if st else "?"), t


def lote(itens, registro=None, espera=8):
    """itens: [(nome, tool, args, destino)]. Devolve {nome: {job, custo, ok, destino}}."""
    res = {}
    pend = list(itens)
    ativos = {}
    while pend or ativos:
        while pend and len(ativos) < MAX:
            nome, tool, args, dest = pend.pop(0)
            if os.path.exists(dest) and not FORCA:
                res[nome] = {"ok": True, "pulado": True, "destino": dest}  # já existe: não gasta de novo
                continue
            try:
                job, custo = submete(tool, args)
                ativos[job] = (nome, dest)
                res[nome] = {"job": job, "custo": custo, "destino": dest, "ok": False}
                print("  mandou %-28s %s custo %s" % (nome, job[:8], custo), flush=True)
            except Exception as e:
                if "rate limit" in str(e):  # limite de pedidos ao mesmo tempo: espera e tenta de novo
                    pend.insert(0, (nome, tool, args, dest))
                    time.sleep(20)
                    break
                print("  ERRO ao mandar", nome, str(e)[:300], flush=True)
                res[nome] = {"erro": str(e)[:300]}
        time.sleep(espera)
        for job in list(ativos):
            st, t = estado(job)
            if st == "completed":
                nome, dest = ativos.pop(job)
                try:
                    fr = re.search(r"frames:\s*(\d+)", t)
                    n = int(fr.group(1)) if fr else 1
                    if n > 1:  # vários candidatos (create_image_pro): pasta com cNN.png + grade
                        baixa_candidatos(job, n, dest)
                    else:
                        baixa("https://api.pixellab.ai/mcp/images/%s/download" % job, dest)
                    res[nome]["ok"] = True
                    res[nome]["candidatos"] = n
                    print("  pronto %-29s -> %s" % (nome, os.path.basename(dest)), flush=True)
                except Exception as e:
                    print("  ERRO ao baixar", nome, e, flush=True)
            elif st in ("failed", "error"):
                nome, dest = ativos.pop(job)
                res[nome]["erro"] = t[:300]
                print("  FALHOU", nome, t[:200], flush=True)
    if registro:
        old = json.load(open(registro, encoding="utf-8")) if os.path.exists(registro) else {}
        old.update(res)
        json.dump(old, open(registro, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    return res


ESTILO = ("Grimy, dark, desaturated earthy palette: dark browns, rust, lead grey, soot black; one accent: %s. "
          "Darker and dirtier than the references. Crisp 1px near-black outline around the silhouette like the "
          "references; interior detail drawn with darker shades of the local color rather than black lines. Clear "
          "form shading with light from top-left, low color count, clean readable pixel clusters.")
