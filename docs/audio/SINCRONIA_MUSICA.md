# Sincronia das camadas de música (Bloco 120)

Medido por `python tools/elevenlabs/gerar_musica.py --sincronia <estacao>`: tempo de cada camada (autocorrelação do envelope de ataques) e atraso entre elas ao longo da faixa.

### primavera

| camada | tempo estimado | força do compasso | tom estimado |
|---|---|---|---|
| dia | 80.20 BPM | 0.22 | D minor (0.87) |
| noite | 80.28 BPM | 0.34 | A major (0.51) |
| perigo | 80.00 BPM | 0.54 | A major (0.76) |

| par | desvio de batidas | fase média | deriva (variação entre janelas) | janelas |
|---|---|---|---|---|
| dia x noite | -1 batida(s) | -365 ms | 0 ms | 2 |
| dia x perigo | -3 batida(s) | 9 ms | 0 ms | 2 |
| noite x perigo | +3 batida(s) | -369 ms | 0 ms | 3 |

**Veredito:** SINCRONIZADAS o bastante (deriva dos ataques até 0 ms, tempos a 0.28 BPM de diferença, tons compatíveis com D minor): dá para tocar juntas (AudioStreamSynchronized).

### verao

| camada | tempo estimado | força do compasso | tom estimado |
|---|---|---|---|
| dia | 80.01 BPM | 0.62 | A major (0.72) |
| noite | 79.94 BPM | 0.66 | D major (0.76) |
| perigo | 79.88 BPM | 0.68 | D major (0.76) |

| par | desvio de batidas | fase média | deriva (variação entre janelas) | janelas |
|---|---|---|---|---|
| dia x noite | -1 batida(s) | 367 ms | 0 ms | 2 |
| dia x perigo | +2 batida(s) | 9 ms | 0 ms | 3 |
| noite x perigo | +4 batida(s) | -365 ms | 0 ms | 3 |

**Veredito:** SINCRONIZADAS o bastante (deriva dos ataques até 0 ms, tempos a 0.13 BPM de diferença, tons compatíveis com D minor): dá para tocar juntas (AudioStreamSynchronized).

### outono

| camada | tempo estimado | força do compasso | tom estimado |
|---|---|---|---|
| dia | 79.95 BPM | 0.81 | D major (0.81) |
| noite | 80.53 BPM | 0.09 | D major (0.68) |
| perigo | 80.09 BPM | 0.19 | A major (0.70) |

| par | desvio de batidas | fase média | deriva (variação entre janelas) | janelas |
|---|---|---|---|---|
| dia x noite | +1 batida(s) | 5 ms | 0 ms | 3 |
| dia x perigo | -2 batida(s) | -369 ms | 0 ms | 2 |
| noite x perigo | +0 batida(s) | -302 ms | 0 ms | 2 |

**Veredito:** SINCRONIZADAS o bastante (deriva dos ataques até 0 ms, tempos a 0.58 BPM de diferença, tons compatíveis com D minor): dá para tocar juntas (AudioStreamSynchronized).

### inverno

| camada | tempo estimado | força do compasso | tom estimado |
|---|---|---|---|
| dia | 79.62 BPM | 0.17 | A major (0.76) |
| noite | 79.69 BPM | 0.43 | A major (0.77) |
| perigo | 80.21 BPM | 0.55 | D major (0.73) |

| par | desvio de batidas | fase média | deriva (variação entre janelas) | janelas |
|---|---|---|---|---|
| dia x noite | +1 batida(s) | -355 ms | 0 ms | 3 |
| dia x perigo | +0 batida(s) | 0 ms | 0 ms | 2 |
| noite x perigo | +2 batida(s) | 346 ms | 0 ms | 3 |

**Veredito:** SINCRONIZADAS o bastante (deriva dos ataques até 0 ms, tempos a 0.59 BPM de diferença, tons compatíveis com D minor): dá para tocar juntas (AudioStreamSynchronized).

