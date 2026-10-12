"""Bloco 133: mede ESTÁTICA/estalos num WAV: quantos saltos amostra-a-amostra passam de 8x a diferença típica (mediana), por segundo,
e a curtose (picos: ruído gaussiano = 3; estalos sobem muito). Uso: python estalos.py <wav> [...]"""
import sys, wave, math
import numpy as np

for caminho in sys.argv[1:]:
    with wave.open(caminho) as w:
        ch, taxa, k = w.getnchannels(), w.getframerate(), w.getnframes()
        x = np.frombuffer(w.readframes(k), dtype="<i2").astype(np.float64).reshape(-1, ch).T / 32768.0
    m = x.mean(0)
    # o "clique" fica no agudo: tira o grave (diferença) e olha os saltos
    d = np.abs(np.diff(m))
    tipica = float(np.median(d)) + 1e-9
    saltos = int(np.sum(d > 8.0 * tipica))
    # estalo isolado = salto grande cercado de calma (janela de 5 amostras)
    calmo = np.convolve(d, np.ones(9) / 9.0, mode="same")
    isolados = int(np.sum((d > 10.0 * tipica) & (d > 4.0 * calmo)))
    curt = float(np.mean((d - d.mean()) ** 4) / (np.var(d) ** 2 + 1e-20))
    print("%-60s %5.1f s  saltos/s %7.1f  estalos isolados/s %6.1f  curtose %6.1f" % (caminho[-60:], m.size / taxa, saltos / (m.size / taxa), isolados / (m.size / taxa), curt))
