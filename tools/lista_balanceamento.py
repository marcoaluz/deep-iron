"""Bloco 52: gera docs/BALANCEAMENTO.md — onde mexer em cada valor de balanceamento.

  python tools/lista_balanceamento.py

Os valores do jogo são `@export` espalhados nos scripts (agrupados por `@export_group`), editáveis
no Inspector do Godot na cena de cada sistema. Este script lista todos, com o comentário `##` que
vem logo acima de cada um, por arquivo e grupo, e o valor que uma cena .tscn põe no lugar do padrão
(no jogo vale o da cena).
"""
import os, re, glob

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
PROJ = os.path.join(RAIZ, "project.godot")
SCRIPTS = os.path.join(PROJ, "scripts")
SAIDA = os.path.join(RAIZ, "docs", "BALANCEAMENTO.md")
PASTAS = ["core", "workers", "props", "creatures"]
NAO_BALANCO = {"script", "position", "scale", "rotation", "z_index", "y_sort_enabled", "metadata/_edit_group_"}


def le(path):
    itens = []
    grupo = "(sem grupo)"
    comentario = []
    for linha in open(path, encoding="utf-8"):
        s = linha.strip()
        m = re.match(r'@export_group\("([^"]*)"', s)
        if m:
            grupo = m.group(1) or "(sem grupo)"
            comentario = []
            continue
        if s.startswith("##"):
            comentario.append(s[2:].strip())
            continue
        m = re.match(r"@export(?:_range\([^)]*\)|_enum\([^)]*\))?\s+var\s+(\w+)\s*(?::\s*([\w\[\]]+))?\s*(?::?=\s*(.+))?", s)
        if m:
            valor = (m.group(3) or "").split("#")[0].strip()
            itens.append((grupo, m.group(1), m.group(2) or "", valor, " ".join(comentario)))
        comentario = []
    return itens


def sobrescritos():
    """res://script -> {valor: [(cena, nó, valor na cena)]}."""
    out = {}
    for cena in glob.glob(os.path.join(PROJ, "scenes", "**", "*.tscn"), recursive=True):
        txt = open(cena, encoding="utf-8").read()
        ext = {}
        for m in re.finditer(r'\[ext_resource ([^\]]*)\]', txt):
            attrs = dict(re.findall(r'(\w+)="([^"]*)"', m.group(1)))
            if attrs.get("type") == "Script":
                ext[attrs.get("id")] = attrs.get("path")
        rel_cena = os.path.relpath(cena, PROJ).replace(os.sep, "/")
        for bloco in re.split(r"\n(?=\[node )", txt):
            m = re.match(r'\[node name="([^"]+)"', bloco)
            sm = re.search(r'^script = ExtResource\("([^"]+)"\)', bloco, re.M)
            if not m or not sm or sm.group(1) not in ext:
                continue
            for pm in re.finditer(r"^([\w/]+) = (.+)$", bloco, re.M):
                if pm.group(1) in NAO_BALANCO:
                    continue
                out.setdefault(ext[sm.group(1)], {}).setdefault(pm.group(1), []).append((rel_cena, m.group(1), pm.group(2)))
    return out


def esc(t):
    return t.replace("|", "\\|")


def main():
    sob = sobrescritos()
    out = ["# Balanceamento: onde mexer em cada valor", "",
           "Gerado por `python tools/lista_balanceamento.py` (Bloco 52). Os valores são `@export` nos scripts: dá",
           "pra mudar no Inspector do Godot (na cena do sistema: `scenes/game/main.tscn` e as cenas dos prédios) ou",
           "direto no script. **Mudar valor é decisão do Marco**; aqui só está onde fica cada um.", "",
           "Pra medir: painel de debug (F3, só em build de editor) e a telemetria (`user://telemetria/`,",
           "resumo com `python tools/resumo_telemetria.py`).", "",
           "A coluna **na cena** aparece quando uma cena `.tscn` troca o padrão do script: no jogo vale o da cena.", ""]
    total = 0
    n_cena = 0
    for pasta in PASTAS:
        for f in sorted(glob.glob(os.path.join(SCRIPTS, pasta, "*.gd"))):
            itens = le(f)
            if not itens:
                continue
            rel = os.path.relpath(f, PROJ).replace(os.sep, "/")
            cena_vals = sob.get("res://" + rel, {})
            out.append("## `%s` (%d)" % (rel, len(itens)))
            out.append("")
            g_atual = None
            for grupo, nome, tipo, valor, com in itens:
                if grupo != g_atual:
                    if g_atual is not None:
                        out.append("")
                    out.append("**%s**" % grupo)
                    out.append("")
                    out.append("| valor | padrão | na cena | o quê |")
                    out.append("|---|---|---|---|")
                    g_atual = grupo
                na_cena = "; ".join("**%s** (%s)" % ("(recurso)" if "Resource(" in v else v, os.path.basename(c))
                                    for c, _n, v in cena_vals.get(nome, []))
                n_cena += 1 if na_cena else 0
                out.append("| `%s` | %s | %s | %s |" % (nome, esc(valor) or "—", esc(na_cena), esc(com)))
                total += 1
            out.append("")
    out.insert(11, "Total: **%d valores** em %d pastas de scripts (%d trocados por alguma cena)." % (total, len(PASTAS), n_cena))
    out.insert(12, "")
    open(SAIDA, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")
    print(total, "valores,", n_cena, "trocados na cena ->", SAIDA)


if __name__ == "__main__":
    main()
