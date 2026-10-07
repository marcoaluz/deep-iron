"""Bloco 55: os sons novos do passe de áudio (obra, colheita, equipamento, festa, interface,
criatura derrubada, broca do coletor de minério) e os loops por contexto (superfície de dia, de
noite, chuva, fundo da mina) e a música de perigo.

Uso:  python tools/gen_audio_novos.py      (precisa de numpy)

Usa os mesmos ajudantes do gen_audio.py, mas cada som com o seu gerador (seed própria): rodar este
script não muda nenhum som antigo. WAV mono 16-bit, 22050 Hz, em project.godot/assets/audio/.
"""
import numpy as np

from gen_audio import SR, t_axis, fft_filter, padded_filter, place, fade, save, midi


def _r(seed):
    return np.random.default_rng(seed)


def _norm(x):
    m = np.max(np.abs(x))
    return x / m if m > 0 else x


def build_hit(i):
    """Obra: martelada em madeira (toc seco) + prego vibrando curto."""
    r = _r(5500 + i)
    dur = 0.32
    t = t_axis(dur)
    f = 180 + 30 * i
    body = np.sin(2 * np.pi * f * t) * np.exp(-t * 38)
    knock = padded_filter(r.standard_normal(len(t)), lo=600, hi=3200) * np.exp(-t * 70)
    nail = np.sin(2 * np.pi * (1900 + 140 * i) * t) * np.exp(-t * 26) * 0.18
    save("build_hit_%d.wav" % i, fade(body * 0.8 + _norm(knock) * 0.7 + nail), 0.85)


def build_done():
    """Obra pronta: pancada grave de assentar + duas notas de madeira subindo."""
    r = _r(5510)
    dur = 1.1
    buf = np.zeros(int(dur * SR))
    t = t_axis(0.35)
    thud = np.sin(2 * np.pi * 70 * t) * np.exp(-t * 14) + padded_filter(r.standard_normal(len(t)), hi=400) * np.exp(-t * 30) * 0.4
    place(buf, 0.0, thud)
    for k, n in enumerate((67, 74)):
        tt = t_axis(0.6)
        f = midi(n)
        tone = (np.sin(2 * np.pi * f * tt) + 0.35 * np.sin(2 * np.pi * 2.76 * f * tt)) * np.exp(-tt * 7)
        place(buf, 0.28 + k * 0.17, tone * 0.55)
    save("build_done.wav", fade(buf, fout=0.08), 0.85)


def harvest(i):
    """Colheita: folhas farfalhando + "ploc" de fruta soltando."""
    r = _r(5520 + i)
    dur = 0.45
    t = t_axis(dur)
    rustle = padded_filter(r.standard_normal(len(t)), lo=1800, hi=6500) * (np.sin(np.pi * t / dur) ** 2)
    rustle *= 0.6 + 0.4 * np.sin(2 * np.pi * (19 + 4 * i) * t)
    tt = t_axis(0.12)
    f = 420 + 60 * i
    plop = np.sin(2 * np.pi * f * (1 + 0.6 * np.exp(-tt * 40)) * tt) * np.exp(-tt * 35)
    buf = _norm(rustle) * 0.55
    place(buf, 0.18 + 0.03 * i, plop * 0.8)
    save("harvest_%d.wav" % i, fade(buf, fout=0.05), 0.8)


def equip():
    """Vestiário: pano jogado nos ombros + fivela fechando (dois cliques metálicos)."""
    r = _r(5530)
    dur = 0.6
    buf = np.zeros(int(dur * SR))
    t = t_axis(0.3)
    cloth = padded_filter(r.standard_normal(len(t)), lo=500, hi=3500) * np.sin(np.pi * t / 0.3) ** 1.5
    place(buf, 0.0, _norm(cloth) * 0.6)
    for k in range(2):
        tt = t_axis(0.06)
        clk = (np.sin(2 * np.pi * 3100 * tt) + 0.5 * np.sin(2 * np.pi * 4700 * tt)) * np.exp(-tt * 90)
        place(buf, 0.33 + k * 0.09, clk * 0.5)
    save("equip.wav", fade(buf, fout=0.05), 0.8)


def party():
    """Festa na vila: palmas no ritmo + sanfoninha (acordes maiores alternando)."""
    r = _r(5540)
    bpm = 132
    beat = 60 / bpm
    dur = beat * 8
    buf = np.zeros(int(dur * SR))
    for b in range(8):
        tt = t_axis(0.09)
        clap = padded_filter(r.standard_normal(len(tt)), lo=900, hi=5000) * np.exp(-tt * 55)
        place(buf, b * beat + (beat / 2 if b % 2 else 0), _norm(clap) * 0.5)
    for k, triad in enumerate(((60, 64, 67), (65, 69, 72), (67, 71, 74), (60, 64, 67))):
        tt = t_axis(beat * 2)
        ch = np.zeros(len(tt))
        for n in triad:
            f = midi(n)
            for h in range(1, 6):
                ch += np.sign(np.sin(2 * np.pi * f * h * tt)) / (h * h * 2.5)  # palheta
        ch = padded_filter(ch, hi=2600) * np.minimum(1, tt / 0.03) * np.exp(-tt * 1.2)
        place(buf, k * beat * 2, ch * 0.35)
    save("party.wav", fade(buf, fout=0.2), 0.8)


def ui_open():
    """Janela abrindo: deslizar de madeira curto, subindo."""
    r = _r(5550)
    dur = 0.16
    t = t_axis(dur)
    sw = padded_filter(r.standard_normal(len(t)), lo=700, hi=2600) * np.sin(np.pi * t / dur)
    tick = np.sin(2 * np.pi * 1400 * t) * np.exp(-((t - 0.12) * 120) ** 2) * 0.4
    save("ui_open.wav", fade(_norm(sw) * 0.5 + tick), 0.6)


def ui_close():
    """Janela fechando: o mesmo deslizar, descendo, com batidinha no fim."""
    r = _r(5551)
    dur = 0.16
    t = t_axis(dur)
    sw = padded_filter(r.standard_normal(len(t)), lo=500, hi=1800) * np.sin(np.pi * t / dur)
    tick = np.sin(2 * np.pi * 900 * t) * np.exp(-((t - 0.13) * 120) ** 2) * 0.5
    save("ui_close.wav", fade(_norm(sw) * 0.5 + tick), 0.6)


def place_sound():
    """Canteiro marcado no chão: estaca batendo na terra."""
    r = _r(5560)
    dur = 0.3
    t = t_axis(dur)
    thud = np.sin(2 * np.pi * 95 * t) * np.exp(-t * 22)
    dirt = padded_filter(r.standard_normal(len(t)), lo=200, hi=1500) * np.exp(-t * 18)
    save("place.wav", fade(thud + _norm(dirt) * 0.45), 0.8)


def creature_down():
    """Criatura derrubada: baque pesado + chiado sumindo."""
    r = _r(5570)
    dur = 0.8
    t = t_axis(dur)
    thud = np.sin(2 * np.pi * 58 * t) * np.exp(-t * 9)
    hiss = padded_filter(r.standard_normal(len(t)), lo=2500, hi=7000) * np.exp(-t * 5) * 0.25
    save("creature_down.wav", fade(thud + hiss, fout=0.1), 0.8)


def drill():
    """Coletor de minério: broca girando e mordendo a rocha (curto, pra repetir)."""
    r = _r(5580)
    dur = 0.9
    t = t_axis(dur)
    f = 110 + 15 * np.sin(2 * np.pi * 3 * t)
    motor = np.sign(np.sin(2 * np.pi * np.cumsum(f) / SR)) * 0.25
    grind = padded_filter(r.standard_normal(len(t)), lo=900, hi=4000) * (0.6 + 0.4 * np.sin(2 * np.pi * 11 * t))
    env = np.minimum(1, t / 0.05) * np.minimum(1, (dur - t) / 0.12)
    save("drill.wav", (padded_filter(motor, hi=1500) + _norm(grind) * 0.5) * env, 0.75)


def _loop_noise(r, n, lo, hi, order=2):
    return _norm(fft_filter(r.standard_normal(n), lo=lo, hi=hi, order=order))


def rain_loop():
    """Chuva na superfície (loop): chiado largo + pingos em telhado de lata."""
    r = _r(5600)
    dur = 16.0
    n = int(dur * SR)
    t = np.arange(n) / SR
    wash = _loop_noise(r, n, 700, 5500, 1) * (0.85 + 0.15 * np.sin(2 * np.pi * t / dur * 2))
    drops = np.zeros(n)
    for _ in range(260):
        tt = t_axis(0.03)
        f = r.uniform(2200, 4800)
        place(drops, r.uniform(0, dur), np.sin(2 * np.pi * f * tt) * np.exp(-tt * 160) * r.uniform(0.2, 0.7), wrap=True)
    save("rain_loop.wav", wash * 0.6 + _norm(drops) * 0.35, 0.75)


def surface_day_loop():
    """Superfície de dia (loop): vento nas árvores secas + corvos ao longe."""
    r = _r(5610)
    dur = 20.0
    n = int(dur * SR)
    t = np.arange(n) / SR
    wind = _loop_noise(r, n, 150, 900, 2) * (0.6 + 0.4 * np.sin(2 * np.pi * t / dur * 3 + 0.7))
    caws = np.zeros(n)
    for k in range(4):
        tt = t_axis(0.32)
        f = 520 + 60 * k
        caw = np.sign(np.sin(2 * np.pi * f * (1 - 0.25 * tt) * tt)) * np.sin(np.pi * tt / 0.32) ** 2
        caw = padded_filter(caw, lo=400, hi=2200)
        start = 2.0 + k * 4.6 + r.uniform(0, 1.2)
        place(caws, start, caw * 0.25, wrap=True)
        place(caws, start + 0.42, caw * 0.18, wrap=True)
    save("surface_day_loop.wav", wind * 0.7 + caws, 0.7)


def surface_night_loop():
    """Superfície de noite (loop): grilos em pulsos + vento baixo + coruja ao longe."""
    r = _r(5620)
    dur = 20.0
    n = int(dur * SR)
    t = np.arange(n) / SR
    wind = _loop_noise(r, n, 100, 500, 2) * 0.5
    gate = (np.sin(2 * np.pi * 4.0 * t) > 0.6).astype(float)  # 4 pulsos/s: emenda certa no loop
    gate = fft_filter(gate, hi=60)
    crickets = np.sin(2 * np.pi * 4300 * t) * gate * 0.3 + np.sin(2 * np.pi * 4720 * t) * np.roll(gate, int(0.11 * SR)) * 0.2
    owl = np.zeros(n)
    for start in (6.0, 15.5):
        for k, (f, d) in enumerate(((410, 0.35), (380, 0.6))):
            tt = t_axis(d)
            hoot = np.sin(2 * np.pi * f * tt) * np.sin(np.pi * tt / d) ** 2
            place(owl, start + k * 0.5, hoot * 0.3, wrap=True)
    save("surface_night_loop.wav", wind + crickets + owl, 0.7)


def deep_loop():
    """Fundo da mina (nível 2/abismo, loop): ronco mais grave, bolhas de lava e chiado de vapor."""
    r = _r(5630)
    dur = 24.0
    n = int(dur * SR)
    t = np.arange(n) / SR
    rumble = _loop_noise(r, n, 18, 70, 2) * (0.7 + 0.3 * np.sin(2 * np.pi * t / dur * 2))
    bubbles = np.zeros(n)
    for _ in range(40):
        tt = t_axis(0.18)
        f0 = r.uniform(90, 160)
        b = np.sin(2 * np.pi * f0 * (1 + 1.2 * tt) * tt) * np.exp(-tt * 18) * r.uniform(0.3, 0.8)
        place(bubbles, r.uniform(0, dur), b, wrap=True)
    steam = np.zeros(n)
    for k in range(3):
        d = 2.2
        tt = t_axis(d)
        hiss = padded_filter(r.standard_normal(len(tt)), lo=2000, hi=6000) * np.sin(np.pi * tt / d) ** 3
        place(steam, 3.0 + k * 7.5, hiss * 0.18, wrap=True)
    save("deep_loop.wav", rumble * 0.7 + _norm(bubbles) * 0.3 + steam, 0.8)


def music_danger():
    """Música de perigo (invasão, loop): tambores + baixo pulsando + metais graves em lá menor."""
    r = _r(5640)
    bpm = 100
    beat = 60 / bpm
    bar = beat * 4
    bars = 8
    dur = bar * bars
    n = int(dur * SR)
    drums = np.zeros(n)
    bass = np.zeros(n)
    brass = np.zeros(n)
    pattern = [0, 0.75, 1.5, 2, 2.75, 3.25, 3.5]
    for b in range(bars):
        for k, pos in enumerate(pattern):
            tt = t_axis(0.35)
            f = 62 if k in (0, 3) else 95
            hit_ = np.sin(2 * np.pi * f * (1 + 0.8 * np.exp(-tt * 30)) * tt) * np.exp(-tt * (9 if k in (0, 3) else 16))
            skin = padded_filter(r.standard_normal(len(tt)), lo=150, hi=1200) * np.exp(-tt * 40) * 0.3
            place(drums, b * bar + pos * beat, hit_ + skin, wrap=True)
    roots = [45, 45, 41, 43, 45, 45, 40, 40]  # lá lá fá sol lá lá mi mi
    for b, root in enumerate(roots):
        for q in range(8):
            tt = t_axis(beat / 2)
            f = midi(root - 12)
            tone = (np.sin(2 * np.pi * f * tt) + 0.4 * np.sin(2 * np.pi * 2 * f * tt)) * np.exp(-tt * 7)
            place(bass, b * bar + q * beat / 2, tone, wrap=True)
        if b % 2 == 0:
            tt = t_axis(bar * 2)
            chord = np.zeros(len(tt))
            for nn in (root, root + 3, root + 7):
                f = midi(nn)
                for h in range(1, 8):
                    chord += np.sin(2 * np.pi * f * h * tt + h * 0.3) / h ** 1.3
            env = np.minimum(1, tt / 0.6) * np.minimum(1, (bar * 2 - tt) / 0.5)
            place(brass, b * bar, padded_filter(chord, hi=1100) * env, wrap=True)
    save("music_danger.wav", _norm(drums) * 0.55 + _norm(bass) * 0.35 + _norm(brass) * 0.3, 0.8)


if __name__ == "__main__":
    for i in range(3):
        build_hit(i)
        harvest(i)
    build_done()
    equip()
    party()
    ui_open()
    ui_close()
    place_sound()
    creature_down()
    drill()
    rain_loop()
    surface_day_loop()
    surface_night_loop()
    deep_loop()
    music_danger()
