"""PROTÓTIPO: rastreio das animações dos casacos (andar + trabalho da função).
  python casacos.py enviado <personagem> <anim> [...]
  python casacos.py processa      (baixa/processa o que ficou pronto; variante Casaco_inverno)
  python casacos.py falta
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
elif cmd == "falta":
    for nome, p in P.items():
        quer = ["caminhada"] + ([p["trabalho"]] if p["trabalho"] else [])
        f = [a for a in quer if a not in p["enviado"]]
        if f:
            print(nome, p["base"], " ".join(f))
json.dump(t, open(F, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
