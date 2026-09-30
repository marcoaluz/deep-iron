"""PROTÓTIPO: animação de trabalho de um personagem (qualquer número de quadros).

  python trabalho.py <pasta> <nome> <character_id> SE:<anim_id>:<n> NE:<anim_id>:<n>
  (em vez de NE pode vir NO:<anim_id>:<n>: a de trás sai da NO e a NE é espelho)
  python trabalho.py <pasta> <nome> <character_id> zip
  (baixa o zip do personagem e pega a animação chamada <nome>, nas direções que ela tiver)

- baixa os quadros em <pasta>/<nome>/{SE,NE}/i.png e espelha SO/NO (contrato: 2 desenhos +
  espelho por animação)
- âncora por direção = pé (mediana dos quadros), igual à caminhada
- <pasta>/<nome>_4dir.gif (NO, NE, SO, SE) e <pasta>/<nome>_folha.png (SE e NE lado a lado)
"""
import sys, os, json, subprocess, statistics
from PIL import Image, ImageOps, ImageDraw
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import verifica_arte as v
import encolhe

B = "https://backblaze.pixellab.ai/file/pixellab-characters/731c5e37-851f-4127-aec6-b6ac884bc069/%s/animations/%s/%s/%d.png"
NOMES = {"SE": "south-east", "NE": "north-east", "NO": "north-west", "SO": "south-west"}
PAR = {"SE": "SO", "NE": "NO", "NO": "NE", "SO": "SE"}
BRANCO = 230   # rastro de movimento que o v3 desenha mesmo pedindo pra não: quase branco puro


PALETA = {}   # cor -> maior contagem numa pose parada do personagem (preenchida no main)
MANTER_CLARO = False   # opção "claro": não apaga branco/claro (tipoia, tala, curativo)
SOLTO_MAX = 6    # pedaço solto menor que isso some (com a opção "soltos", até 45: cavacos e tocos soltos)


def limpa(caminho):
    """apaga o rastro/sopro de efeito que o v3 desenha mesmo pedindo pra não: branco puro, e
    cor muito clara (luminosidade >= 0,80) que não existe nas poses paradas do personagem. O
    metal mais claro das ferramentas fica abaixo de ~0,78."""
    im = Image.open(caminho).convert("RGBA")
    px = im.load()
    n = 0
    from collections import Counter
    conta = Counter(px[x, y][:3] for y in range(im.height) for x in range(im.width) if px[x, y][3] > 40)
    for y in range(im.height):
        for x in range(im.width):
            p = px[x, y]
            if p[3] == 0:
                continue
            c = p[:3]
            l = (max(c) + min(c)) / 510.0
            # cor clara que aparece muito mais aqui do que em qualquer pose parada = rastro
            # (o brilho da lanterna tem essa cor em 1-2 px; o rastro, em dezenas)
            demais = conta[c] > max(3 * PALETA.get(c, 0), 12)
            claro = min(c) >= BRANCO or (l >= 0.80 and (c not in PALETA or demais))
            # vermelho vivo que o personagem não tem = parece sangue (contrato: sem gore)
            sangue = c[0] > 60 and c[0] > 2.5 * max(c[1], c[2], 1) and c not in PALETA
            if (claro and not MANTER_CLARO) or sangue:
                px[x, y] = (0, 0, 0, 0)
                n += 1
    # manchas claras soltas (sopro/poeira de efeito): componente que não encosta no corpo
    import numpy as np
    a = np.array(im)
    op = a[..., 3] > 40
    H, W = op.shape
    rot = -np.ones((H, W), int)
    comps = []
    for y0 in range(H):
        for x0 in range(W):
            if op[y0, x0] and rot[y0, x0] < 0:
                pilha, pts = [(y0, x0)], []
                rot[y0, x0] = len(comps)
                while pilha:
                    y, x = pilha.pop(); pts.append((y, x))
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            yy, xx = y + dy, x + dx
                            if 0 <= yy < H and 0 <= xx < W and op[yy, xx] and rot[yy, xx] < 0:
                                rot[yy, xx] = len(comps); pilha.append((yy, xx))
                comps.append(pts)
    if comps:
        maior = max(range(len(comps)), key=lambda k: len(comps[k]))
        for k, pts in enumerate(comps):
            if k == maior:
                continue
            ys, xs = zip(*pts)
            cor = a[list(ys), list(xs), :3].astype(float)
            lum = (0.299 * cor[:, 0] + 0.587 * cor[:, 1] + 0.114 * cor[:, 2]).mean()
            if (lum > 140 and not MANTER_CLARO) or len(pts) < SOLTO_MAX:
                a[list(ys), list(xs), 3] = 0
                n += len(pts)
        im = Image.fromarray(a)
    im.save(caminho)
    return n


def main():
    global SOLTO_MAX, MANTER_CLARO
    estado = None   # opção estado=<Pasta>: o zip de um "state" traz todos os states do grupo
    for a in list(sys.argv):
        if a.startswith("estado="):
            estado = a.split("=", 1)[1]
            sys.argv.remove(a)
    if "claro" in sys.argv:
        sys.argv.remove("claro")
        MANTER_CLARO = True
    if "soltos" in sys.argv:
        sys.argv.remove("soltos")
        SOLTO_MAX = 45
    pasta, nome, cid = sys.argv[1:4]
    base = os.path.join(pasta, nome)
    rot = os.path.join(pasta, "_original", "rotacoes") if os.path.isdir(os.path.join(pasta, "_original")) else os.path.join(pasta, "rotacoes")
    for f in (os.listdir(rot) if os.path.isdir(rot) else []):
        if f.endswith(".png"):
            from collections import Counter
            cc = Counter(q[:3] for q in Image.open(os.path.join(rot, f)).convert("RGBA").get_flattened_data() if q[3] > 40)
            for k, v2 in cc.items():
                PALETA[k] = max(PALETA.get(k, 0), v2)
    feitos = {}
    if sys.argv[4] == "zip":
        import zipfile, io
        raw = subprocess.run(["curl", "-s", "-f", "-A", "curl/8",
                              "https://api.pixellab.ai/mcp/characters/%s/download" % cid],
                             check=True, capture_output=True).stdout
        z = zipfile.ZipFile(io.BytesIO(raw))
        inv = {v2: k for k, v2 in NOMES.items()}
        por_dir = {}
        for nm in z.namelist():
            partes = nm.split("/")
            if estado and (len(partes) < 5 or partes[-5] != estado):
                continue
            if len(partes) >= 4 and partes[-4] == "animations" and partes[-3] == nome and partes[-2] in inv:
                por_dir.setdefault(inv[partes[-2]], []).append(nm)
        for d, nms in por_dir.items():
            os.makedirs(os.path.join(base, d), exist_ok=True)
            for i, nm in enumerate(sorted(nms)):
                f = os.path.join(base, d, "%d.png" % i)
                open(f, "wb").write(z.read(nm))
                limpa(f)
            feitos[d] = len(nms)
    for arg in (sys.argv[4:] if sys.argv[4] != "zip" else []):
        d, aid, n = arg.split(":")
        n = int(n)
        os.makedirs(os.path.join(base, d), exist_ok=True)
        for i in range(n):
            f = os.path.join(base, d, "%d.png" % i)
            subprocess.run(["curl", "-s", "-f", "-A", "curl/8", "-o", f, B % (cid, aid, NOMES[d], i)], check=True)
            limpa(f)
        feitos[d] = n
    # corte de altura aprovado (encolhe.CORTE): as mesmas linhas acima do pé, antes do espelho
    corte = encolhe.CORTE.get(os.path.basename(os.path.normpath(pasta)), 0)
    if corte:
        for d, n in feitos.items():
            fs = [os.path.join(base, d, "%d.png" % i) for i in range(n)]
            pe_y = max(v.feet(v.opaque(Image.open(f)))[1] for f in fs)
            for f in fs:
                encolhe.encolhe(Image.open(f), pe_y, encolhe.linhas(corte)).save(f)
    for d, n in list(feitos.items()):
        e = PAR[d]
        os.makedirs(os.path.join(base, e), exist_ok=True)
        for i in range(n):
            ImageOps.mirror(Image.open(os.path.join(base, d, "%d.png" % i))).save(os.path.join(base, e, "%d.png" % i))
        feitos[e] = n
    info = {}
    for d in ("SE", "NE", "SO", "NO"):
        fr = [v.opaque(Image.open(os.path.join(base, d, "%d.png" % i))) for i in range(feitos[d])]
        pes = [v.feet(p) for p in fr]
        info[d] = {"quadros": feitos[d], "ancora": [round(statistics.median(a[0] for a in pes), 1), max(a[1] for a in pes)],
                   "quadro_px": list(Image.open(os.path.join(base, d, "0.png")).size)}
    json.dump(info, open(os.path.join(base, "anim.json"), "w"), indent=1)
    # GIF: as 4 direções alinhadas pela âncora
    n = max(feitos.values())
    S = 3
    cw, ch = 104, 110
    quadros = []
    for i in range(n):
        c = Image.new("RGB", (4 * cw * S, ch * S + 16), (80, 80, 92))
        dd = ImageDraw.Draw(c)
        for k, d in enumerate(("NO", "NE", "SO", "SE")):
            im = Image.open(os.path.join(base, d, "%d.png" % (i % feitos[d]))).convert("RGBA")
            ax, ay = info[d]["ancora"]
            im = im.crop((int(ax - cw / 2), int(ay - ch + 8), int(ax + cw / 2), int(ay + 8))).resize((cw * S, ch * S), Image.NEAREST)
            c.paste(im, (k * cw * S, 16), im)
            dd.text((k * cw * S + 4, 2), d, fill=(255, 230, 120))
        quadros.append(c)
    quadros[0].save(os.path.join(pasta, nome + "_4dir.gif"), save_all=True, append_images=quadros[1:], duration=120, loop=0)
    # folha: SE em cima, NE embaixo
    S = 3
    g = Image.new("RGBA", (n * cw * S, 2 * ch * S), (80, 80, 92, 255))
    for r, d in enumerate(("SE", "NE")):
        ax, ay = info[d]["ancora"]
        for i in range(feitos[d]):
            im = Image.open(os.path.join(base, d, "%d.png" % i)).convert("RGBA")
            im = im.crop((int(ax - cw / 2), int(ay - ch + 8), int(ax + cw / 2), int(ay + 8))).resize((cw * S, ch * S), Image.NEAREST)
            g.paste(im, (i * cw * S, r * ch * S), im)
    g.save(os.path.join(pasta, nome + "_folha.png"))
    print(json.dumps(info))


if __name__ == "__main__":
    main()
