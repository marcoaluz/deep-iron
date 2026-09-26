"""Sintetiza todos os sons do DEEP IRON em project.godot/assets/audio/.

Uso:  python tools/gen_audio.py   (precisa de numpy: pip install numpy)

Tudo é gerado do zero (sem samples de terceiros), então não há questão de
direitos autorais. WAV mono 16-bit, 22050 Hz. Os loops (música e ambiente)
são gerados de forma circular (filtros por FFT e ecos com np.roll), então
emendam o fim com o começo sem clique.
"""
from pathlib import Path
import wave

import numpy as np

SR = 22050
OUT = Path(__file__).resolve().parent.parent / "project.godot" / "assets" / "audio"
OUT.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(42)


# ----------------------------------------------------------------- helpers
def t_axis(seconds):
    return np.arange(int(seconds * SR)) / SR


def fft_filter(x, lo=None, hi=None, order=2):
    """Filtro passa-faixa suave via FFT (circular: ótimo pra loops)."""
    n = len(x)
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(n, 1 / SR)
    h = np.ones_like(f)
    if hi:
        h *= 1 / np.sqrt(1 + (f / hi) ** (2 * order))
    if lo:
        with np.errstate(divide="ignore"):
            h *= 1 / np.sqrt(1 + (lo / np.maximum(f, 1e-3)) ** (2 * order))
    return np.fft.irfft(spec * h, n)


def padded_filter(x, lo=None, hi=None, order=2):
    """Filtro para sons curtos (com padding pra não 'vazar' o fim no começo)."""
    pad = np.zeros(len(x) + SR // 4)
    pad[: len(x)] = x
    return fft_filter(pad, lo, hi, order)[: len(x)]


def noise(seconds):
    return rng.standard_normal(int(seconds * SR))


def exp_env(seconds, decay, attack=0.002):
    t = t_axis(seconds)
    env = np.exp(-t * decay)
    a = int(attack * SR)
    if a > 0:
        env[:a] *= np.linspace(0, 1, a)
    return env


def place(buf, start_s, sig, wrap=False):
    i = int(start_s * SR)
    if wrap:
        idx = (np.arange(len(sig)) + i) % len(buf)
        np.add.at(buf, idx, sig)
    else:
        end = min(len(buf), i + len(sig))
        buf[i:end] += sig[: end - i]


def fade(x, fin=0.002, fout=0.01):
    a, b = int(fin * SR), int(fout * SR)
    if a:
        x[:a] *= np.linspace(0, 1, a)
    if b:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def save(name, x, peak=0.9):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x))
    if m > 0:
        x = x / m * peak
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("ok", name, f"{len(x) / SR:.2f}s")


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


# ----------------------------------------------------------------- SFX
def pick_hit(i):
    dur = 0.4
    t = t_axis(dur)
    f0 = rng.uniform(850, 1150)
    ring = sum(a * np.sin(2 * np.pi * f0 * r * t) * np.exp(-t * k)
               for r, a, k in ((1.0, 1.0, 22), (2.76, 0.55, 30), (5.40, 0.3, 45), (8.93, 0.15, 60)))
    click = padded_filter(noise(dur), lo=2500) * exp_env(dur, 140, 0.0005)
    thud = padded_filter(noise(dur), hi=400) * exp_env(dur, 35, 0.001) * 2.5
    thud += np.sin(2 * np.pi * rng.uniform(90, 130) * t) * np.exp(-t * 28) * 0.6
    grit = padded_filter(noise(dur), lo=800, hi=4000) * exp_env(dur, 25, 0.003) * 0.25
    save(f"pick_{i}.wav", fade(0.3 * ring + 0.5 * click + 0.7 * thud + grit), 0.85)


def step(i):
    dur = 0.11
    crunch = padded_filter(noise(dur), lo=300, hi=rng.uniform(1600, 2600)) * exp_env(dur, 45, 0.004)
    crackle = np.zeros(int(dur * SR))
    for _ in range(rng.integers(4, 9)):
        place(crackle, rng.uniform(0, 0.05), padded_filter(noise(0.006), lo=2000) * exp_env(0.006, 400))
    save(f"step_{i}.wav", fade(crunch + crackle * 0.6), 0.6)


def deposit(i):
    dur = 0.55
    out = np.zeros(int(dur * SR))
    times = np.sort(rng.uniform(0, 0.32, rng.integers(6, 10)))
    for k, s in enumerate(times):
        amp = 1.0 - 0.6 * k / len(times)
        tt = t_axis(0.05)
        tick = padded_filter(noise(0.05), lo=600, hi=5000) * np.exp(-tt * 90)
        tick += np.sin(2 * np.pi * rng.uniform(300, 800) * tt) * np.exp(-tt * 70) * 0.5
        place(out, s, tick * amp * rng.uniform(0.5, 1.0))
    tt = t_axis(0.3)
    place(out, 0.0, padded_filter(noise(0.3), hi=300) * np.exp(-tt * 18) * 1.8)
    save(f"deposit_{i}.wav", fade(out), 0.8)


def eat(i):
    dur = 0.45
    out = np.zeros(int(dur * SR))
    for b in range(rng.integers(2, 4)):
        start = b * rng.uniform(0.13, 0.17)
        bd = 0.1
        tt = t_axis(bd)
        env = np.sin(np.pi * np.clip(tt / bd, 0, 1)) ** 2
        crackle = np.repeat(rng.random(int(bd * SR) // 40 + 1) > 0.55, 40)[: len(tt)].astype(float)
        bite = padded_filter(noise(bd), lo=250, hi=1800) * env * (0.35 + crackle)
        place(out, start, bite * rng.uniform(0.7, 1.0))
    save(f"eat_{i}.wav", fade(out), 0.7)


def sell():
    dur = 0.9
    out = np.zeros(int(dur * SR))
    for k, n in enumerate((88, 93, 100)):  # E6 A6 E7
        tt = t_axis(dur - k * 0.07)
        f = midi(n)
        ping = (np.sin(2 * np.pi * f * tt) + 0.4 * np.sin(2 * np.pi * f * 2.02 * tt)) * np.exp(-tt * 9)
        place(out, k * 0.07, ping * (1 - k * 0.15))
    save("sell.wav", fade(out), 0.7)


def recruit():
    dur = 1.1
    out = np.zeros(int(dur * SR))
    for k, n in enumerate((72, 76, 79, 84)):  # C E G C
        tt = t_axis(dur - k * 0.09)
        f = midi(n)
        tri = 2 / np.pi * np.arcsin(np.sin(2 * np.pi * f * tt))
        place(out, k * 0.09, tri * np.exp(-tt * 6) * (0.8 if k < 3 else 1.0))
    save("recruit.wav", fade(out), 0.7)


def click():
    tt = t_axis(0.04)
    x = np.sin(2 * np.pi * 1800 * tt) * np.exp(-tt * 150) + padded_filter(noise(0.04), lo=3000) * np.exp(-tt * 300) * 0.3
    save("click.wav", fade(x), 0.5)


def error():
    tt = t_axis(0.22)
    x = np.sign(np.sin(2 * np.pi * 150 * tt)) * np.exp(-tt * 12)
    save("error.wav", fade(padded_filter(x, hi=1200)), 0.4)


def hurt():
    """Ipezinho se machucando: pedrinha caindo + um "uff!" curto (voz sintética)."""
    dur = 0.42
    out = np.zeros(int(dur * SR))
    tt = t_axis(0.3)
    # "uff": pulso glotal (dente de serra) com pitch caindo, filtrado nos formantes de "ó"
    f = np.linspace(260, 150, len(tt))
    saw = 2 * ((np.cumsum(f) / SR) % 1.0) - 1
    env = np.sin(np.pi * np.clip(tt / 0.26, 0, 1)) ** 0.6 * np.exp(-tt * 4)
    voice = padded_filter(saw, lo=350, hi=700) + 0.5 * padded_filter(saw, lo=900, hi=1300)
    place(out, 0.06, voice * env * 1.4)
    # pancada de pedra no começo
    td = t_axis(0.12)
    thud = padded_filter(noise(0.12), hi=500) * np.exp(-td * 40) * 2.0
    thud += padded_filter(noise(0.12), lo=1500) * np.exp(-td * 120) * 0.4
    place(out, 0.0, thud)
    save("hurt.wav", fade(out), 0.75)


def heal():
    """Curado: duas notas suaves subindo (sino abafado)."""
    dur = 0.8
    out = np.zeros(int(dur * SR))
    for k, n in enumerate((79, 84)):  # G5 C6
        tt = t_axis(dur - k * 0.12)
        fq = midi(n)
        bell = (np.sin(2 * np.pi * fq * tt) + 0.25 * np.sin(2 * np.pi * fq * 3.01 * tt)) * np.exp(-tt * 7)
        place(out, k * 0.12, bell * (0.8 if k == 0 else 1.0))
    save("heal.wav", fade(padded_filter(out, hi=3500)), 0.55)


def forge():
    """Martelada na bigorna (fabricação de peça da escavadeira)."""
    dur = 0.6
    t = t_axis(dur)
    f0 = 620.0
    ring = sum(a * np.sin(2 * np.pi * f0 * r * t) * np.exp(-t * k)
               for r, a, k in ((1.0, 1.0, 9), (2.32, 0.6, 12), (3.91, 0.4, 16), (5.8, 0.25, 22)))
    hit = padded_filter(noise(dur), lo=1800) * exp_env(dur, 90, 0.0005) * 0.8
    body = padded_filter(noise(dur), hi=350) * exp_env(dur, 40, 0.001) * 1.2
    save("forge.wav", fade(0.35 * ring + hit + body), 0.75)


def fanfare():
    """Fanfarra de conquista (escavadeira pronta): arpejo de metais + acorde final."""
    dur = 2.6
    out = np.zeros(int(dur * SR))

    def brass(freq, length):
        tt = t_axis(length)
        env = np.minimum(1.0, tt / 0.04) * np.exp(-tt * 1.2)
        saw = sum(np.sin(2 * np.pi * freq * h * tt) / h for h in range(1, 7))
        return padded_filter(saw, hi=2400) * env

    for k, n in enumerate((60, 64, 67)):  # C E G
        place(out, k * 0.16, brass(midi(n), 0.3) * 0.8)
    for n in (60, 64, 67, 72):  # acorde final segurado
        place(out, 0.5, brass(midi(n), 2.0) * 0.5)
    tt = t_axis(0.4)
    place(out, 0.5, padded_filter(noise(0.4), hi=200) * np.exp(-tt * 8) * 1.5)  # bumbo
    save("fanfare.wav", fade(out, fout=0.2), 0.8)


# ----------------------------------------------------------------- loops
def cave_ambience():
    dur = 24.0
    n = int(dur * SR)
    # ronco grave (ruído marrom filtrado), com "respiração" lenta
    rumble = fft_filter(rng.standard_normal(n), lo=25, hi=110, order=2)
    rumble /= np.max(np.abs(rumble))
    t = np.arange(n) / SR
    rumble *= 0.75 + 0.25 * np.sin(2 * np.pi * t / dur * 3)
    # ar/vento bem baixinho
    air = fft_filter(rng.standard_normal(n), lo=300, hi=1200, order=1)
    air /= np.max(np.abs(air))
    air *= 0.12 * (0.5 + 0.5 * np.sin(2 * np.pi * t / dur * 2 + 1.3))
    # gotas d'água com eco
    drips = np.zeros(n)
    for _ in range(16):
        dd = 0.09
        tt = t_axis(dd)
        f_start = rng.uniform(700, 1100)
        freq = f_start * (1 + 1.6 * (1 - np.exp(-tt * 60)))
        phase = 2 * np.pi * np.cumsum(freq) / SR
        drop = np.sin(phase) * np.exp(-tt * 45) * rng.uniform(0.4, 1.0)
        place(drips, rng.uniform(0, dur), drop, wrap=True)
    echo = np.zeros(n)
    for delay, gain in ((0.19, 0.5), (0.43, 0.35), (0.71, 0.25), (1.13, 0.16), (1.6, 0.1)):
        echo += np.roll(drips, int(delay * SR)) * gain
    drips = drips + fft_filter(echo, hi=2500)
    drips /= np.max(np.abs(drips))
    save("cave_ambience.wav", rumble * 0.55 + air + drips * 0.35, 0.8)


def music():
    bpm = 70
    beat = 60 / bpm
    bar = beat * 4
    progression = [  # (fundamental MIDI, tríade)
        (57, (57, 60, 64)),  # Am
        (53, (53, 57, 60)),  # F
        (48, (55, 60, 64)),  # C
        (55, (55, 59, 62)),  # G
        (57, (57, 60, 64)),  # Am
        (53, (53, 57, 60)),  # F
        (50, (53, 57, 62)),  # Dm
        (52, (52, 56, 59)),  # E
    ]
    dur = bar * len(progression)
    n = int(dur * SR)
    pad = np.zeros(n)
    bass = np.zeros(n)
    bell = np.zeros(n)

    for i, (root, triad) in enumerate(progression):
        start = i * bar
        length = bar + 1.6  # release entra no próximo acorde
        tt = t_axis(length)
        env = np.minimum(1, tt / 0.8) * np.where(tt < bar, 1.0, np.exp(-(tt - bar) * 3))
        chord = np.zeros(len(tt))
        for note in triad:
            for detune in (-0.12, 0.12):
                f = midi(note) * 2 ** (detune / 12)
                for k in range(1, 7):
                    chord += np.sin(2 * np.pi * f * k * tt + k) / k ** 1.6
        chord *= env * (0.85 + 0.15 * np.sin(2 * np.pi * tt * 0.25))
        place(pad, start, chord, wrap=True)

        # baixo: duas notas por compasso
        for b in (0, 2):
            bt = t_axis(beat * 2.2)
            f = midi(root - 12)
            tone = np.sin(2 * np.pi * f * bt) + 0.3 * np.sin(2 * np.pi * 2 * f * bt)
            place(bass, start + b * beat, tone * np.exp(-bt * 1.6) * np.minimum(1, bt / 0.01), wrap=True)

    # melodia "kalimba" em pentatônica de lá menor, esparsa e determinística
    scale = [69, 72, 74, 76, 79, 81, 84]
    mrng = np.random.default_rng(7)
    idx = 3
    for step8 in range(len(progression) * 8):
        if mrng.random() < 0.42:
            idx = int(np.clip(idx + mrng.integers(-2, 3), 0, len(scale) - 1))
            f = midi(scale[idx])
            bt = t_axis(1.4)
            tone = (np.sin(2 * np.pi * f * bt) * np.exp(-bt * 3.2)
                    + 0.25 * np.sin(2 * np.pi * f * 4.07 * bt) * np.exp(-bt * 9))
            place(bell, step8 * beat / 2, tone * np.minimum(1, bt / 0.004) * mrng.uniform(0.5, 0.9), wrap=True)
    echo = np.zeros(n)
    for k, gain in enumerate((0.4, 0.22, 0.12), start=1):
        echo += np.roll(bell, int(beat * 0.75 * k * SR)) * gain
    bell = bell + echo

    pad = fft_filter(pad, hi=1400, order=1)
    for part in (pad, bass, bell):
        part /= np.max(np.abs(part))
    save("music_loop.wav", pad * 0.45 + bass * 0.35 + bell * 0.3, 0.8)


if __name__ == "__main__":
    for i in range(3):
        pick_hit(i)
        deposit(i)
        eat(i)
    for i in range(4):
        step(i)
    sell()
    recruit()
    click()
    error()
    cave_ambience()
    music()
    # sons novos entram sempre no fim: o rng tem seed fixa, então os anteriores não mudam
    hurt()
    heal()
    forge()
    fanfare()
