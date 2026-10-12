"""Bloco 133: corte suave de agudos (passa-baixa de Butterworth de 2a ordem em magnitude, fase zero) num loop WAV.
O filtro é feito por FFT do arquivo inteiro (circular): o fim continua emendando no começo. Depois volta o RMS de antes
(só sobe, com o pico <= -2 dBFS). Uso: python passa_baixa.py <wav> <fc_hz>"""
import sys, wave, math
import numpy as np

caminho, fc = sys.argv[1], float(sys.argv[2])
with wave.open(caminho) as w:
    ch, taxa, k, larg = w.getnchannels(), w.getframerate(), w.getnframes(), w.getsampwidth()
    x = np.frombuffer(w.readframes(k), dtype="<i2").astype(np.float64).reshape(-1, ch).T / 32768.0
rms0 = math.sqrt(float(np.mean(x ** 2)))
f = np.fft.rfftfreq(x.shape[1], 1.0 / taxa)
g = 1.0 / np.sqrt(1.0 + (f / fc) ** 4)
y = np.fft.irfft(np.fft.rfft(x, axis=1) * g, n=x.shape[1], axis=1)
rms1 = math.sqrt(float(np.mean(y ** 2)))
ganho = rms0 / max(rms1, 1e-12)
pico = float(np.max(np.abs(y))) * ganho
teto = 10 ** (-2.0 / 20.0)
if pico > teto:
    ganho *= teto / pico
y *= ganho
out = (np.clip(y, -1.0, 1.0) * 32767.0).round().astype("<i2").T.reshape(-1)
with wave.open(caminho, "wb") as o:
    o.setnchannels(ch)
    o.setsampwidth(2)
    o.setframerate(taxa)
    o.writeframes(out.tobytes())
print("ok: fc %.0f Hz, rms %.1f -> %.1f dBFS, pico %.1f dBFS" % (fc, 20 * math.log10(rms0), 20 * math.log10(math.sqrt(float(np.mean(y ** 2)))), 20 * math.log10(float(np.max(np.abs(y))))))
