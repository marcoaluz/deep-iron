"""PROTÓTIPO: rastreio do Prompt 2 (animações comuns).
  python comuns.py enviado <personagem> <anim> [<anim> ...]   marca como enviado
  python comuns.py processa                                   baixa/processa o que já ficou pronto
  python comuns.py falta                                      lista o que falta enviar
"""
import sys, json, subprocess
ANIMS = ["comer", "ferido", "deitar", "mancar_esq"]
F = "comuns_ids.json"
t = json.load(open(F, encoding="utf-8"))
P = t["personagens"]
cmd = sys.argv[1]
if cmd == "enviado":
    p = P[sys.argv[2]]
    for a in sys.argv[3:]:
        if a not in p["enviado"]:
            p["enviado"].append(a)
elif cmd == "processa":
    for nome, p in P.items():
        pend = [a for a in p["enviado"] if a not in p["processado"] and "(" not in a]
        if not pend:
            continue
        ok = []
        for a in pend:
            args = ["python", "trabalho.py", nome, a, p["char"], "zip"] + (["claro"] if a == "ferido" else [])
            r = subprocess.run(args, capture_output=True)
            if r.returncode == 0:
                p["processado"].append(a); ok.append(a)
            else:
                break   # zip bloqueado (job rodando nesse personagem): tenta depois
        if ok:
            print(nome, "processado:", " ".join(ok))
elif cmd == "falta":
    for nome, p in P.items():
        f = [a for a in ANIMS if a not in p["enviado"]]
        if f:
            print(nome, p["genero"], " ".join(f))
json.dump(t, open(F, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
