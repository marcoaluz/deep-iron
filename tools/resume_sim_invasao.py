#!/usr/bin/env python3
"""Bloco 127: resume as linhas "SIM ..." de tools/sim_invasao.gd (várias repetições por cenário) numa tabela em markdown.
Uso: python tools/resume_sim_invasao.py <arquivo_antes> <arquivo_depois> [mais arquivos...]
Cada arquivo pode ter as linhas de vários modelos; o resumo agrupa por (arma, guardas, habilidade, onda) e por modelo."""
import re
import sys
from collections import OrderedDict


def le(path):
    linhas = []
    with open(path, encoding="utf-8") as f:
        for ln in f:
            if not ln.startswith("SIM "):
                continue
            modelo, resto = ln[4:].strip().split(";", 1)
            d = {"modelo": modelo}
            for par in resto.split(";"):
                k, _, v = par.partition("=")
                d[k] = v
            linhas.append(d)
    return linhas


def num(d, k):
    m = re.match(r"-?\d+(\.\d+)?", d.get(k, "0"))
    return float(m.group(0)) if m else 0.0


def main():
    todas = []
    for p in sys.argv[1:]:
        todas += le(p)
    grupos = OrderedDict()
    for d in todas:
        chave = (d.get("arma", "porrete"), int(d["guardas"]), float(d["hab"]), int(d["onda"]))
        grupos.setdefault(chave, {}).setdefault(d["modelo"], []).append(d)
    print("| arma | guardas | hab. | onda | modelo | runs | limpou | guardas caídos (média) | portão % (média) | minério perdido | créditos perdidos | prédios feridos | s até limpar |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for chave, porm in grupos.items():
        for modelo in ("antes", "depois"):
            rs = porm.get(modelo)
            if not rs:
                continue
            n = len(rs)
            limpou = [r for r in rs if r.get("fim") == "limpou"]
            seg = (sum(num(r, "segundos") for r in limpou) / len(limpou)) if limpou else float("nan")
            print("| %s | %d | %.1f | %d | %s | %d | %d/%d | %.1f | %.0f | %.0f | %.0f | %.1f | %s |" % (
                chave[0], chave[1], chave[2], chave[3], modelo, n, len(limpou), n,
                sum(num(r, "guardas_caidos") for r in rs) / n, sum(num(r, "portao_pct") for r in rs) / n,
                sum(num(r, "minerio_perdido") for r in rs) / n, sum(num(r, "creditos_perdidos") for r in rs) / n,
                sum(num(r, "predios_feridos") for r in rs) / n, ("%.0f" % seg) if limpou else "—"))


if __name__ == "__main__":
    main()
