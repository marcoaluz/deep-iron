"""Bloco 131: DIAGNÓSTICO DOS SONS DA NOITE (o "som chato à noite").

Lista os slots que podem tocar à noite (a ambiência da floresta à noite e as dos andares, as camadas de chuva/vento/onda, os
sons soltos de noite, os loops de prédio, a radiação, a música da noite e a de perigo) e mede cada ARQUIVO:
  - duração, pico e RMS (dBFS) e a sonoridade integrada (LUFS, BS.1770: filtro K e as duas comportas, no domínio da frequência);
  - quanto da energia está nos AGUDOS (acima de 4 kHz e de 8 kHz) e se é CONTÍNUO (a fração aguda varia pouco de bloco em bloco:
    o "grilo" que não para) e TONAL (a planura espectral na faixa de 3 a 9 kHz: baixa = um apito, um chiado afinado);
  - nos loops, o ESTALO da emenda (posprocessa.razao_estalo; > LIMITE_ESTALO = audível);
  - nos sons soltos, quantas vezes por minuto tocam (o intervalo do slot) e quantas variações têm.
Sinaliza os SUSPEITOS e grava docs/audio/DIAGNOSTICO_NOITE.md. Não gera nem muda áudio.

Uso:  python tools/elevenlabs/analisa_noite.py [--md <arquivo>]
"""
import json
import math
import os
import sys
import wave

import numpy as np

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import posprocessa as pos  # noqa: E402

RAIZ = os.path.abspath(os.path.join(AQUI, "..", ".."))
PROJ = os.path.join(RAIZ, "project.godot")
SLOTS = os.path.join(PROJ, "data", "audio", "slots.json")
MUSICA = os.path.join(PROJ, "data", "audio", "musica.json")
AUDIO = os.path.join(PROJ, "assets", "audio")
MD = os.path.join(RAIZ, "docs", "audio", "DIAGNOSTICO_NOITE.md")

# Os limiares dos suspeitos (ajuste aqui).
AGUDO_SUSPEITO = 0.25  # fração da energia acima de 4 kHz
CONTINUO_CV = 0.35  # coeficiente de variação da fração aguda entre blocos de 400 ms (abaixo = contínuo)
TONAL_PLANURA = 0.25  # planura espectral de 3 a 9 kHz (abaixo = tonal, afinado)
REPETE_POR_MIN = 3.0  # som solto tocando mais que isso por minuto


def le(caminho):
    with wave.open(caminho) as w:
        ch, taxa, k, larg = w.getnchannels(), w.getframerate(), w.getnframes(), w.getsampwidth()
        bruto = w.readframes(k)
    if larg != 2:
        return None
    x = np.frombuffer(bruto, dtype="<i2").astype(np.float64) / 32768.0
    return x.reshape(-1, ch).T, taxa  # (canais, amostras)


def _biquad(b, a, w):
    z = np.exp(-1j * w)
    return (b[0] + b[1] * z + b[2] * z * z) / (a[0] + a[1] * z + a[2] * z * z)


def k_weighting(freqs, taxa):
    """Magnitude do filtro K (BS.1770) nas frequências dadas: a prateleira de +4 dB em 1,5 kHz e o passa-alta RLB em 38 Hz
    (as fórmulas do pyloudnorm, pra qualquer taxa de amostragem)."""
    w = 2.0 * np.pi * freqs / taxa
    # prateleira alta
    G, Q, fc = 4.0, 1.0 / math.sqrt(2.0), 1500.0
    A = 10 ** (G / 40.0)
    w0 = 2.0 * math.pi * fc / taxa
    alpha = math.sin(w0) / (2.0 * Q)
    b = [A * ((A + 1) + (A - 1) * math.cos(w0) + 2 * math.sqrt(A) * alpha), -2 * A * ((A - 1) + (A + 1) * math.cos(w0)),
         A * ((A + 1) + (A - 1) * math.cos(w0) - 2 * math.sqrt(A) * alpha)]
    a = [(A + 1) - (A - 1) * math.cos(w0) + 2 * math.sqrt(A) * alpha, 2 * ((A - 1) - (A + 1) * math.cos(w0)),
         (A + 1) - (A - 1) * math.cos(w0) - 2 * math.sqrt(A) * alpha]
    h1 = _biquad(b, a, w)
    # passa-alta
    Q, fc = 0.5, 38.0
    w0 = 2.0 * math.pi * fc / taxa
    alpha = math.sin(w0) / (2.0 * Q)
    b = [(1 + math.cos(w0)) / 2, -(1 + math.cos(w0)), (1 + math.cos(w0)) / 2]
    a = [1 + alpha, -2 * math.cos(w0), 1 - alpha]
    h2 = _biquad(b, a, w)
    return np.abs(h1 * h2)


def lufs(x, taxa):
    n = x.shape[1]
    if n < int(0.4 * taxa):
        return float("nan")
    f = np.fft.rfftfreq(n, 1.0 / taxa)
    kw = k_weighting(f, taxa)
    y = np.fft.irfft(np.fft.rfft(x, axis=1) * kw, n=n, axis=1)
    bloco = int(0.4 * taxa)
    passo = int(0.1 * taxa)
    pot = []
    for i in range(0, n - bloco + 1, passo):
        pot.append(np.sum(np.mean(y[:, i:i + bloco] ** 2, axis=1)))
    pot = np.array(pot)
    with np.errstate(divide="ignore"):
        l = -0.691 + 10 * np.log10(pot)
    pot = pot[l > -70.0]
    if pot.size == 0:
        return float("-inf")
    rel = -0.691 + 10 * np.log10(np.mean(pot)) - 10.0
    with np.errstate(divide="ignore"):
        l2 = -0.691 + 10 * np.log10(pot)
    pot = pot[l2 > rel]
    return float(-0.691 + 10 * np.log10(np.mean(pot))) if pot.size else float("-inf")


def agudos(x, taxa):
    """(fração > 4 kHz, fração > 8 kHz, CV da fração aguda por bloco, planura 3–9 kHz)"""
    m = np.mean(x, axis=0)
    n = m.size
    espec = np.abs(np.fft.rfft(m)) ** 2
    f = np.fft.rfftfreq(n, 1.0 / taxa)
    tot = np.sum(espec) + 1e-20
    f4 = float(np.sum(espec[f >= 4000.0]) / tot)
    f8 = float(np.sum(espec[f >= 8000.0]) / tot)
    banda = espec[(f >= 3000.0) & (f <= min(9000.0, taxa / 2 - 1))]
    planura = float(np.exp(np.mean(np.log(banda + 1e-20))) / (np.mean(banda) + 1e-20)) if banda.size else 1.0
    bloco = int(0.4 * taxa)
    fracs = []
    for i in range(0, n - bloco + 1, bloco):
        e = np.abs(np.fft.rfft(m[i:i + bloco])) ** 2
        fb = np.fft.rfftfreq(bloco, 1.0 / taxa)
        t = np.sum(e) + 1e-20
        if t > 1e-8:
            fracs.append(np.sum(e[fb >= 4000.0]) / t)
    cv = float(np.std(fracs) / (np.mean(fracs) + 1e-12)) if len(fracs) >= 3 else float("nan")
    # a planura espectral num espectro longo é baixa pra quase tudo; vale a média por bloco
    planuras = []
    for i in range(0, n - bloco + 1, bloco):
        e = np.abs(np.fft.rfft(m[i:i + bloco])) ** 2
        fb = np.fft.rfftfreq(bloco, 1.0 / taxa)
        bb = e[(fb >= 3000.0) & (fb <= min(9000.0, taxa / 2 - 1))]
        if bb.size and np.mean(bb) > 1e-12:
            planuras.append(np.exp(np.mean(np.log(bb + 1e-20))) / np.mean(bb))
    if planuras:
        planura = float(np.median(planuras))
    return f4, f8, cv, planura


def arquivos_do(id_):
    base = os.path.join(AUDIO, *id_.split("/"))
    out = []
    for ext in (".wav",):
        if os.path.exists(base + ext):
            out.append(base + ext)
    i = 0
    while os.path.exists("%s_%d.wav" % (base, i)):
        out.append("%s_%d.wav" % (base, i))
        i += 1
    return out


def slots_da_noite():
    d = json.load(open(SLOTS, encoding="utf-8"))
    lista = d if isinstance(d, list) else d.get("slots", [])
    out = []
    for s in lista:
        id_ = s["id"]
        tipo = s.get("tipo", "")
        ctx = [str(c) for c in s.get("ctx", [])]
        motivo = ""
        if id_.startswith("ambiencia/") and not id_.endswith("_dia"):
            motivo = "ambiência (à noite na floresta: floresta_noite; nos andares, a do andar)"
        elif tipo == "pontual" and "dia" not in ctx:
            motivo = "som solto (%s)" % (", ".join(ctx) or "sempre")
        elif tipo == "loop_predio":
            motivo = "loop de prédio (toca se o prédio está ativo, de noite também)"
        elif id_.startswith("camadas/") or id_ in ("sfx/radiacao", "ambiencia/radiacao"):
            motivo = "camada por cima / radiação"
        elif "radiacao" in id_:
            motivo = "radiação (Geiger)"
        elif id_ in ("musica/jogo", "musica/perigo"):
            motivo = "música de antes (sem as camadas)"
        if motivo:
            out.append((id_, s, motivo))
    m = json.load(open(MUSICA, encoding="utf-8"))
    for f in m.get("faixas", []):
        fid = f.get("id", "")
        if fid.endswith("_noite") or fid.endswith("_perigo"):
            out.append((fid, {"tipo": "musica", "bus": "Music", "db": 0.0}, "música: camada da noite (pad) / de perigo"))
    return out


def main():
    md = MD
    if "--md" in sys.argv:
        md = sys.argv[sys.argv.index("--md") + 1]
    linhas = []
    suspeitos = []
    for id_, s, motivo in slots_da_noite():
        arqs = arquivos_do(id_)
        if not arqs:
            linhas.append((id_, motivo, s, None, "sem arquivo (toca a reserva sintetizada ou nada)"))
            continue
        for a in arqs:
            r = le(a)
            if r is None:
                continue
            x, taxa = r
            dur = x.shape[1] / taxa
            pico = 20 * math.log10(max(np.max(np.abs(x)), 1e-9))
            rms = 10 * math.log10(max(float(np.mean(x ** 2)), 1e-12))
            lu = lufs(x, taxa)
            f4, f8, cv, plan = agudos(x, taxa)
            estalo = None
            e_loop = s.get("tipo") in ("loop", "loop_predio") or id_.startswith("ambiencia/") or id_.startswith("musica/")
            if e_loop:
                xi = [int(v * 32767) for v in x.T.reshape(-1)[: 2 * 60 * taxa * x.shape[0]]] if x.shape[1] > 0 else []
                ch = x.shape[0]
                xi_full = (np.clip(x.T.reshape(-1), -1, 1) * 32767).astype(int).tolist()
                estalo = pos.razao_estalo(xi_full, ch)
            inter = s.get("intervalo")
            por_min = (60.0 / (sum(inter) / 2.0)) if inter else None
            mot = []
            if f4 >= AGUDO_SUSPEITO and (math.isnan(cv) or cv < CONTINUO_CV) and dur >= 3.0:
                mot.append("AGUDO CONTÍNUO (%.0f%% acima de 4 kHz, varia pouco)" % (f4 * 100))
            if plan < TONAL_PLANURA and f4 >= 0.10 and dur >= 3.0:
                mot.append("TONAL nos agudos (planura %.2f: um apito/grilo afinado)" % plan)
            if estalo is not None and estalo > pos.LIMITE_ESTALO:
                mot.append("EMENDA do loop audível (estalo %.1f)" % estalo)
            if por_min is not None and (por_min >= REPETE_POR_MIN or (por_min >= 1.5 and len(arqs) <= 1)):
                mot.append("REPETE muito (%.1f vezes/min, %d %s)" % (por_min, len(arqs), "variação" if len(arqs) == 1 else "variações"))
            info = {"arq": os.path.relpath(a, PROJ).replace("\\", "/"), "dur": dur, "pico": pico, "rms": rms, "lufs": lu,
                    "f4": f4, "f8": f8, "cv": cv, "plan": plan, "estalo": estalo, "por_min": por_min, "db": s.get("db", 0.0)}
            linhas.append((id_, motivo, s, info, "; ".join(mot)))
            if mot:
                suspeitos.append((id_, info, mot))
    # relatório
    out = ["# Diagnóstico dos sons da noite (Bloco 131)", "",
           "Gerado por `python tools/elevenlabs/analisa_noite.py` (mede os ARQUIVOS; não mexe em nada). LUFS = sonoridade integrada "
           "(BS.1770) do arquivo; o jogo ainda soma o `db` do slot e o volume do bus. Agudos = fração da energia acima de 4 kHz / 8 kHz. "
           "CV = o quanto essa fração muda de 0,4 s em 0,4 s (baixo = contínuo). Planura 3–9 kHz: perto de 1 = ruído; baixa = afinado.",
           "",
           "Limiares: agudo contínuo >= %.0f%% com CV < %.2f; tonal com planura < %.2f; repete >= %.1f/min (ou >= 1,5/min com 1 variação); "
           "estalo do loop > %.1f." % (AGUDO_SUSPEITO * 100, CONTINUO_CV, TONAL_PLANURA, REPETE_POR_MIN, pos.LIMITE_ESTALO), "",
           "| slot | por que toca à noite | arquivo | dur (s) | LUFS | db do slot | pico dBFS | >4 kHz | >8 kHz | CV | planura | estalo | vezes/min | SUSPEITO |",
           "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for id_, motivo, s, info, mot in linhas:
        if info is None:
            out.append("| `%s` | %s | — | | | %s | | | | | | | | %s |" % (id_, motivo, s.get("db", ""), mot))
            continue
        out.append("| `%s` | %s | `%s` | %.1f | %.1f | %s | %.1f | %.0f%% | %.0f%% | %s | %.2f | %s | %s | %s |" % (
            id_, motivo, info["arq"], info["dur"], info["lufs"], info["db"], info["pico"], info["f4"] * 100, info["f8"] * 100,
            "—" if math.isnan(info["cv"]) else "%.2f" % info["cv"], info["plan"],
            "—" if info["estalo"] is None else "%.1f" % info["estalo"],
            "—" if info["por_min"] is None else "%.1f" % info["por_min"], ("**%s**" % mot) if mot else ""))
    out += ["", "## Suspeitos", ""]
    if not suspeitos:
        out.append("Nenhum arquivo passou dos limiares.")
    for id_, info, mot in suspeitos:
        out.append("- `%s` (`%s`): %s" % (id_, info["arq"], "; ".join(mot)))
    out += ["", "Pra confirmar ouvindo: F3 > Som: o que está tocando agora > Silenciar, um por um, até o incômodo sumir.", ""]
    os.makedirs(os.path.dirname(md), exist_ok=True)
    open(md, "w", encoding="utf-8").write("\n".join(out))
    print("\n".join(out[-(len(suspeitos) + 4):]))
    print("gravado:", md)


if __name__ == "__main__":
    main()
