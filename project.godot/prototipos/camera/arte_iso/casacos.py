"""PROTÓTIPO: rastreio das animações dos casacos (andar + trabalho da função).
  python casacos.py enviado <personagem> <anim> [...]
  python casacos.py processa      (baixa/processa o que ficou pronto; variante Casaco_inverno)
  python casacos.py falta
  python casacos.py entrega <pasta_docs>   (casaco_por_funcao.png e casaco_animacoes.gif dos 18)
"""
import sys, json, subprocess
F = "casaco_ids.json"
t = json.load(open(F, encoding="utf-8"))
P = {k: v for k, v in t.items() if not k.startswith("_")}
cmd = sys.argv[1]
if cmd == "enviado":
    for a in sys.argv[3:]:
        if a not in P[sys.argv[2]]["enviado"]:
            P[sys.argv[2]]["enviado"].append(a)
elif cmd == "refaz":   # python casacos.py refaz <personagem> <anim>: processa de novo
    P[sys.argv[2]]["processado"].remove(sys.argv[3])
elif cmd == "processa":
    for nome, p in P.items():
        for a in [a for a in p["enviado"] if a not in p["processado"]]:
            extra = ["soltos"] if a == "cortar" else []
            extra += ["atras=" + x for x in [p.get("atras", {}).get(a)] if x]
            extra += ["de=" + x for x in p.get("de", {}).get(a, [])]
            extra += ["troca=" + x for x in p.get("troca", {}).get(a, [])]
            extra += p.get("opcoes", {}).get(a, [])
            r = subprocess.run(["python", "trabalho.py", nome, a, p["char"], "zip", "estado=Casaco_inverno"] + extra,
                               capture_output=True)
            if r.returncode == 0:
                p["processado"].append(a); print(nome, a, "ok")
            else:
                break
elif cmd == "entrega":
    import os, statistics
    from PIL import Image, ImageDraw
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    import verifica_arte as v
    out = sys.argv[2]
    nomes = list(P)
    CW, CH, S = 70, 96, 2

    def recorte(f, anc):
        im = Image.open(f).convert("RGBA")
        return im.crop((int(anc[0] - CW / 2), int(anc[1] - CH + 6), int(anc[0] + CW / 2), int(anc[1] + 6)))

    def ancora(pasta, anim, d, n):
        pes = [v.feet(v.opaque(Image.open("%s/%s/%s/%d.png" % (pasta, anim, d, i)))) for i in range(n)]
        return statistics.median(p[0] for p in pes), max(p[1] for p in pes)

    # prancha: sem casaco (1o quadro da caminhada da base) x com casaco, SE
    cols = 9
    c = Image.new("RGB", (cols * 2 * CW * S, 2 * (CH * S + 14)), (62, 58, 54)); d = ImageDraw.Draw(c)
    for k, nome in enumerate(nomes):
        x = (k % cols) * 2 * CW * S; y = (k // cols) * (CH * S + 14)
        for j, pasta in enumerate((P[nome]["base"], nome)):
            r = recorte("%s/caminhada/SE/0.png" % pasta, ancora(pasta, "caminhada", "SE", 4)).resize((CW * S, CH * S), Image.NEAREST)
            c.paste(r, (x + j * CW * S, y + 14), r)
        d.text((x + 4, y + 2), P[nome]["base"], fill=(255, 230, 150))
    c.save(os.path.join(out, "casaco_por_funcao.png"))
    # GIF: andar (linha de cima) e trabalho (de baixo; o civil repete o andar), SE, 8 quadros
    quadros = []
    for i in range(8):
        c = Image.new("RGB", (cols * CW * S, 4 * (CH * S) + 20), (62, 58, 54)); d = ImageDraw.Draw(c)
        for k, nome in enumerate(nomes):
            anims = ["caminhada"] + ([P[nome]["trabalho"]] if P[nome]["trabalho"] else [])
            # linha de cima: andar; de baixo: trabalho (ou andar, pro civil)
            for lin, anim in enumerate((anims[0], anims[-1])):
                js = json.load(open("%s/%s/anim.json" % (nome, anim)))
                n = js["SE"]["quadros"]; anc = js["SE"]["ancora"]
                im = recorte("%s/%s/SE/%d.png" % (nome, anim, i % n), anc).resize((CW * S, CH * S), Image.NEAREST)
                c.paste(im, ((k % cols) * CW * S, 20 + ((k // cols) * 2 + lin) * CH * S), im)
        quadros.append(c)
    quadros[0].save(os.path.join(out, "casaco_animacoes.gif"), save_all=True, append_images=quadros[1:], duration=140, loop=0)
    quadros[0].save(os.path.join(out, "casaco_animacoes_q0.png"))
elif cmd == "falta":
    for nome, p in P.items():
        quer = ["caminhada"] + ([p["trabalho"]] if p["trabalho"] else [])
        f = [a for a in quer if a not in p["enviado"]]
        if f:
            print(nome, p["base"], " ".join(f))
json.dump(t, open(F, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
