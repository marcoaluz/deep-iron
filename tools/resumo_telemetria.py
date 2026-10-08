"""Bloco 52: resumo da TELEMETRIA de balanceamento (CSV que o jogo grava em user://telemetria/).

  python tools/resumo_telemetria.py <arquivo.csv ou pasta>     (sem argumento: a pasta do save real)

Mostra, por partida: a curva de créditos e de minério (mínimo, máximo, final e uma linha de
"tendência" em texto), os dias sem lucro, picos de morte, ânimo, invasões e greves.
"""
import csv, glob, os, sys

BARRAS = " ▁▂▃▄▅▆▇█"


def linha(valores, largura=40):
    if not valores:
        return ""
    passo = max(1, len(valores) // largura)
    amostra = valores[::passo]
    lo, hi = min(amostra), max(amostra)
    if hi == lo:
        return BARRAS[4] * len(amostra)
    return "".join(BARRAS[int((v - lo) / (hi - lo) * (len(BARRAS) - 1))] for v in amostra)


def num(r, k):
    try:
        return float(r.get(k, 0) or 0)
    except ValueError:
        return 0.0


def resumo(path):
    rows = list(csv.DictReader(open(path, encoding="utf-8")))
    print("== %s (%d dias registrados)" % (os.path.basename(path), len(rows)))
    if not rows:
        return
    cr = [num(r, "creditos") for r in rows]
    minerio = [sum(num(r, k) for k in ("ferro", "cobre", "carvao", "prata", "solarita")) for r in rows]
    pop = [num(r, "populacao") for r in rows]
    animo = [num(r, "animo_medio") for r in rows]
    mortes = [num(r, "mortes") for r in rows]
    print("  créditos   min %6d  máx %6d  final %6d   %s" % (min(cr), max(cr), cr[-1], linha(cr)))
    print("  minério    min %6d  máx %6d  final %6d   %s" % (min(minerio), max(minerio), minerio[-1], linha(minerio)))
    print("  população  min %6d  máx %6d  final %6d   %s" % (min(pop), max(pop), pop[-1], linha(pop)))
    print("  ânimo      min %6.1f  máx %6.1f  final %6.1f   %s" % (min(animo), max(animo), animo[-1], linha(animo)))
    sem_lucro = [rows[i]["dia"] for i in range(1, len(rows)) if cr[i] <= cr[i - 1]]
    print("  dias sem lucro (créditos não subiram): %d %s" % (len(sem_lucro), ("— " + ", ".join(sem_lucro[:15])) if sem_lucro else ""))
    picos = [(rows[i]["dia"], int(mortes[i] - mortes[i - 1])) for i in range(1, len(rows)) if mortes[i] - mortes[i - 1] >= 2]
    print("  mortes no total: %d   picos (2+ num dia): %s" % (mortes[-1], picos or "nenhum"))
    ondas = max(num(r, "onda") for r in rows)
    greves = sum(1 for i in range(1, len(rows)) if num(rows[i], "greve") and not num(rows[i - 1], "greve"))
    print("  invasões até agora: %d   greves começadas: %d   pesquisas: %d   estágio da vila: %d" % (
        ondas, greves, num(rows[-1], "pesquisas"), num(rows[-1], "estagio_vila")))
    if "minerio_entrou_dia" in rows[0]:  # Bloco 99: o minério que entrou por dia (e quanto de vagonete)
        entrou = [num(r, "minerio_entrou_dia") for r in rows[1:]] or [0.0]
        vag = sum(num(r, "minerio_vagonete_dia") for r in rows[1:])
        print("  minério que entrou por dia: média %d  máx %d   %s   (de vagonete: %d%%)" % (
            sum(entrou) / len(entrou), max(entrou), linha(entrou), 100.0 * vag / max(sum(entrou), 1.0)))
    print("  tempo real: %.1f min" % (num(rows[-1], "tempo_real_s") / 60.0))


def main():
    alvo = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.environ.get("APPDATA", os.path.expanduser("~/.local/share")),
                                                              "Godot", "app_userdata", "project.godot", "telemetria")
    fs = [alvo] if os.path.isfile(alvo) else sorted(glob.glob(os.path.join(alvo, "*.csv")))
    if not fs:
        print("nenhum CSV em", alvo)
        return
    for f in fs:
        resumo(f)


if __name__ == "__main__":
    main()
