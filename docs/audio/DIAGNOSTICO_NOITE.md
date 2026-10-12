# Diagnóstico dos sons da noite (Bloco 131)

Gerado por `python tools/elevenlabs/analisa_noite.py` (mede os ARQUIVOS; não mexe em nada). LUFS = sonoridade integrada (BS.1770) do arquivo; o jogo ainda soma o `db` do slot e o volume do bus. Agudos = fração da energia acima de 4 kHz / 8 kHz. CV = o quanto essa fração muda de 0,4 s em 0,4 s (baixo = contínuo). Planura 3–9 kHz: perto de 1 = ruído; baixa = afinado.

Limiares: agudo contínuo >= 25% com CV < 0.35; tonal com planura < 0.25; repete >= 3.0/min (ou >= 1,5/min com 1 variação); estalo do loop > 6.0.

| slot | por que toca à noite | arquivo | dur (s) | LUFS | db do slot | pico dBFS | >4 kHz | >8 kHz | CV | planura | estalo | vezes/min | SUSPEITO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `ambiencia/mina` | ambiência (à noite na floresta: floresta_noite; nos andares, a do andar) | `assets/audio/ambiencia/mina.wav` | 29.6 | -22.2 | 0.0 | -6.2 | 0% | 0% | 1.35 | 0.86 | 0.7 | — |  |
| `ambiencia/floresta_noite` | ambiência (à noite na floresta: floresta_noite; nos andares, a do andar) | `assets/audio/ambiencia/floresta_noite.wav` | 30.0 | -16.7 | -7.0 | -2.4 | 6% | 1% | 0.51 | 0.50 | 1.3 | — |  |
| `ambiencia/vento_inverno` | ambiência (à noite na floresta: floresta_noite; nos andares, a do andar) | `assets/audio/ambiencia/vento_inverno.wav` | 30.0 | -18.2 | -8.0 | -4.4 | 0% | 0% | 0.53 | 0.28 | 0.1 | — |  |
| `ambiencia/chuva` | ambiência (à noite na floresta: floresta_noite; nos andares, a do andar) | `assets/audio/ambiencia/chuva.wav` | 30.0 | -26.4 | -6.0 | -2.3 | 19% | 3% | 0.08 | 0.44 | 0.7 | — |  |
| `ambiencia/s2_acido` | ambiência (à noite na floresta: floresta_noite; nos andares, a do andar) | `assets/audio/ambiencia/s2_acido.wav` | 30.0 | -12.6 | -1.0 | -3.5 | 97% | 55% | 0.01 | 0.24 | 0.1 | — | **AGUDO CONTÍNUO (97% acima de 4 kHz, varia pouco); TONAL nos agudos (planura 0.24: um apito/grilo afinado)** |
| `ambiencia/s3_lava` | ambiência (à noite na floresta: floresta_noite; nos andares, a do andar) | `assets/audio/ambiencia/s3_lava.wav` | 29.6 | -15.4 | -1.0 | -1.6 | 0% | 0% | 1.33 | 0.86 | 0.4 | — |  |
| `ambiencia/s4_cachoeira` | ambiência (à noite na floresta: floresta_noite; nos andares, a do andar) | `assets/audio/ambiencia/s4_cachoeira.wav` | 30.0 | -13.9 | -1.0 | -2.9 | 10% | 3% | 0.06 | 0.51 | 0.6 | — |  |
| `ambiencia/s5_lago` | ambiência (à noite na floresta: floresta_noite; nos andares, a do andar) | `assets/audio/ambiencia/s5_lago.wav` | 30.0 | -26.1 | -1.0 | -2.0 | 4% | 1% | 0.55 | 0.44 | 0.9 | — |  |
| `ambiencia/onda_solar` | ambiência (à noite na floresta: floresta_noite; nos andares, a do andar) | `assets/audio/ambiencia/onda_solar.wav` | 29.6 | -13.2 | -4.0 | -0.4 | 0% | 0% | 1.39 | 0.86 | 1.6 | — |  |
| `predios/fornalha` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/fornalha.wav` | 25.0 | -22.6 | -12.0 | 0.0 | 9% | 4% | 0.75 | 0.53 | 0.3 | — |  |
| `predios/carpintaria` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/carpintaria.wav` | 25.0 | -14.0 | -12.0 | 0.0 | 17% | 3% | 0.26 | 0.37 | 1.3 | — |  |
| `predios/taverna` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/taverna.wav` | 30.0 | -21.0 | -12.0 | -2.0 | 0% | 0% | 0.91 | 0.30 | 0.0 | — |  |
| `predios/cemiterio` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/cemiterio.wav` | 29.6 | -37.5 | -14.0 | -7.7 | 0% | 0% | 1.06 | 0.69 | 0.3 | — |  |
| `predios/vagonete` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/vagonete.wav` | 20.0 | -24.2 | -10.0 | -2.0 | 1% | 0% | 1.00 | 0.27 | 0.8 | — |  |
| `predios/coletor_madeira` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/coletor_madeira.wav` | 25.0 | -17.2 | -12.0 | -2.3 | 28% | 7% | 0.15 | 0.29 | 2.9 | — | **AGUDO CONTÍNUO (28% acima de 4 kHz, varia pouco)** |
| `predios/coletor_minerio` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/coletor_minerio.wav` | 25.0 | -12.7 | -12.0 | -1.2 | 43% | 7% | 0.10 | 0.36 | 0.3 | — | **AGUDO CONTÍNUO (43% acima de 4 kHz, varia pouco)** |
| `predios/poca_perigo` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/poca_perigo.wav` | 20.0 | -18.2 | -16.0 | -2.5 | 26% | 11% | 0.15 | 0.55 | 0.4 | — | **AGUDO CONTÍNUO (26% acima de 4 kHz, varia pouco)** |
| `predios/ventilador` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/ventilador.wav` | 19.6 | -22.6 | -14.0 | -7.6 | 0% | 0% | 1.47 | 0.87 | 0.4 | — |  |
| `predios/tocha` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/tocha.wav` | 20.0 | -36.8 | -8.0 | -0.0 | 23% | 10% | 1.31 | 0.53 | 1.1 | — |  |
| `predios/conversa` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/conversa.wav` | 30.0 | -22.9 | -14.0 | -2.0 | 2% | 0% | 2.75 | 0.40 | 0.5 | — |  |
| `predios/oficina` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/oficina.wav` | 25.0 | -23.4 | -12.0 | 0.0 | 39% | 14% | 0.91 | 0.24 | 0.8 | — | **TONAL nos agudos (planura 0.24: um apito/grilo afinado)** |
| `predios/arsenal` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/arsenal.wav` | 25.0 | -17.1 | -12.0 | 0.0 | 42% | 13% | 0.34 | 0.41 | 0.2 | — | **AGUDO CONTÍNUO (42% acima de 4 kHz, varia pouco)** |
| `predios/laboratorio` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/laboratorio.wav` | 25.0 | -23.6 | -14.0 | -2.0 | 0% | 0% | 0.90 | 0.32 | 1.5 | — |  |
| `predios/escavadeira` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/escavadeira.wav` | 25.0 | -17.8 | -10.0 | -4.0 | 24% | 7% | 0.70 | 0.35 | 0.1 | — |  |
| `predios/escola` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/escola.wav` | 30.0 | -27.0 | -14.0 | -3.7 | 0% | 0% | 2.20 | 0.42 | 0.8 | — |  |
| `predios/cozinha` | loop de prédio (toca se o prédio está ativo, de noite também) | `assets/audio/predios/cozinha.wav` | 25.0 | -30.8 | -9.0 | -2.0 | 24% | 16% | 0.69 | 0.40 | 0.1 | — |  |
| `pontuais/coruja` | som solto (noite) | `assets/audio/pontuais/coruja_0.wav` | 3.0 | -12.8 | -14.0 | -2.1 | 0% | 0% | 1.59 | 0.33 | — | 2.4 |  |
| `pontuais/coruja` | som solto (noite) | `assets/audio/pontuais/coruja_1.wav` | 3.0 | -11.8 | -14.0 | -1.8 | 0% | 0% | 1.30 | 0.66 | — | 2.4 |  |
| `pontuais/lobo_uivo` | som solto (noite) | `assets/audio/pontuais/lobo_uivo_0.wav` | 5.0 | -14.5 | -16.0 | -2.3 | 0% | 0% | 1.80 | 0.77 | — | 0.9 |  |
| `pontuais/lobo_uivo` | som solto (noite) | `assets/audio/pontuais/lobo_uivo_1.wav` | 5.0 | -11.1 | -16.0 | -0.9 | 0% | 0% | 1.54 | 0.65 | — | 0.9 |  |
| `pontuais/sapo` | som solto (noite) | `assets/audio/pontuais/sapo_0.wav` | 3.0 | -13.1 | -14.0 | 0.0 | 0% | 0% | 0.38 | 0.13 | — | 2.9 |  |
| `pontuais/sapo` | som solto (noite) | `assets/audio/pontuais/sapo_1.wav` | 3.0 | -17.7 | -14.0 | -1.1 | 0% | 0% | 0.47 | 0.05 | — | 2.9 |  |
| `pontuais/trovao` | som solto (chuva) | `assets/audio/pontuais/trovao_0.wav` | 6.0 | -18.1 | -8.0 | -1.1 | 0% | 0% | 1.27 | 0.70 | — | 1.7 |  |
| `pontuais/trovao` | som solto (chuva) | `assets/audio/pontuais/trovao_1.wav` | 6.0 | -17.8 | -8.0 | -0.5 | 0% | 0% | 1.82 | 0.79 | — | 1.7 |  |
| `pontuais/trovao` | som solto (chuva) | `assets/audio/pontuais/trovao_2.wav` | 6.0 | -18.4 | -8.0 | -0.8 | 0% | 0% | 1.07 | 0.54 | — | 1.7 |  |
| `pontuais/vento_rajada` | som solto (vento) | `assets/audio/pontuais/vento_rajada_0.wav` | 4.0 | -12.6 | -12.0 | -0.5 | 0% | 0% | 1.15 | 0.82 | — | 3.4 | **REPETE muito (3.4 vezes/min, 2 variações)** |
| `pontuais/vento_rajada` | som solto (vento) | `assets/audio/pontuais/vento_rajada_1.wav` | 4.0 | -14.7 | -12.0 | -0.6 | 0% | 0% | 2.37 | 0.53 | — | 3.4 | **REPETE muito (3.4 vezes/min, 2 variações)** |
| `pontuais/pedra_cai` | som solto (mina) | `assets/audio/pontuais/pedra_cai_0.wav` | 2.0 | -26.6 | -14.0 | -3.0 | 94% | 56% | 0.39 | 0.52 | — | 1.4 |  |
| `pontuais/pedra_cai` | som solto (mina) | `assets/audio/pontuais/pedra_cai_1.wav` | 2.0 | -23.0 | -14.0 | -3.0 | 97% | 65% | 0.50 | 0.47 | — | 1.4 |  |
| `pontuais/pedra_cai` | som solto (mina) | `assets/audio/pontuais/pedra_cai_2.wav` | 2.0 | -24.3 | -14.0 | -3.0 | 96% | 54% | 0.24 | 0.38 | — | 1.4 |  |
| `pontuais/gotejar` | som solto (mina, s2) | `assets/audio/pontuais/gotejar_0.wav` | 1.5 | -27.6 | -16.0 | -3.0 | 2% | 1% | 0.68 | 0.21 | — | 4.3 | **REPETE muito (4.3 vezes/min, 3 variações)** |
| `pontuais/gotejar` | som solto (mina, s2) | `assets/audio/pontuais/gotejar_1.wav` | 1.5 | -20.5 | -16.0 | -3.0 | 0% | 0% | 0.83 | 0.28 | — | 4.3 | **REPETE muito (4.3 vezes/min, 3 variações)** |
| `pontuais/gotejar` | som solto (mina, s2) | `assets/audio/pontuais/gotejar_2.wav` | 1.5 | -28.6 | -16.0 | -3.0 | 4% | 0% | 0.69 | 0.17 | — | 4.3 | **REPETE muito (4.3 vezes/min, 3 variações)** |
| `pontuais/acido_borbulha` | som solto (s2) | `assets/audio/pontuais/acido_borbulha_0.wav` | 1.5 | -18.8 | -14.0 | -3.0 | 96% | 64% | 0.03 | 0.37 | — | 5.7 | **REPETE muito (5.7 vezes/min, 3 variações)** |
| `pontuais/acido_borbulha` | som solto (s2) | `assets/audio/pontuais/acido_borbulha_1.wav` | 1.5 | -20.8 | -14.0 | -3.0 | 89% | 61% | 0.02 | 0.53 | — | 5.7 | **REPETE muito (5.7 vezes/min, 3 variações)** |
| `pontuais/acido_borbulha` | som solto (s2) | `assets/audio/pontuais/acido_borbulha_2.wav` | 1.5 | -18.0 | -14.0 | -3.0 | 95% | 57% | 0.01 | 0.36 | — | 5.7 | **REPETE muito (5.7 vezes/min, 3 variações)** |
| `pontuais/lava_estalo` | som solto (s3) | `assets/audio/pontuais/lava_estalo_0.wav` | 1.5 | -12.3 | -14.0 | 0.0 | 20% | 8% | 0.51 | 0.51 | — | 6.3 | **REPETE muito (6.3 vezes/min, 3 variações)** |
| `pontuais/lava_estalo` | som solto (s3) | `assets/audio/pontuais/lava_estalo_1.wav` | 1.5 | -23.9 | -14.0 | -1.4 | 33% | 23% | 0.37 | 0.44 | — | 6.3 | **REPETE muito (6.3 vezes/min, 3 variações)** |
| `pontuais/lava_estalo` | som solto (s3) | `assets/audio/pontuais/lava_estalo_2.wav` | 1.5 | -26.3 | -14.0 | 0.0 | 8% | 4% | 0.10 | 0.48 | — | 6.3 | **REPETE muito (6.3 vezes/min, 3 variações)** |
| `pontuais/gota_eco` | som solto (s5) | `assets/audio/pontuais/gota_eco_0.wav` | 3.0 | -22.7 | -16.0 | -0.0 | 4% | 3% | 0.91 | 0.16 | — | 4.8 | **REPETE muito (4.8 vezes/min, 3 variações)** |
| `pontuais/gota_eco` | som solto (s5) | `assets/audio/pontuais/gota_eco_1.wav` | 3.0 | -26.1 | -16.0 | -3.0 | 0% | 0% | 2.28 | 0.15 | — | 4.8 | **REPETE muito (4.8 vezes/min, 3 variações)** |
| `pontuais/gota_eco` | som solto (s5) | `assets/audio/pontuais/gota_eco_2.wav` | 3.0 | -28.3 | -16.0 | -3.0 | 1% | 1% | 0.93 | 0.16 | — | 4.8 | **REPETE muito (4.8 vezes/min, 3 variações)** |
| `musica/jogo` | música de antes (sem as camadas) | `assets/audio/musica/jogo.wav` | 117.0 | -16.0 | 0.0 | -4.8 | 0% | 0% | 0.62 | 0.45 | 0.2 | — |  |
| `musica/perigo` | música de antes (sem as camadas) | `assets/audio/musica/perigo.wav` | 57.0 | -17.3 | 0.0 | -7.5 | 0% | 0% | 0.92 | 0.14 | 0.3 | — |  |
| `musica/primavera_noite` | música: camada da noite (pad) / de perigo | `assets/audio/musica/primavera_noite.wav` | 117.0 | -15.4 | 0.0 | -5.0 | 8% | 2% | 0.50 | 0.20 | 3.7 | — |  |
| `musica/primavera_perigo` | música: camada da noite (pad) / de perigo | `assets/audio/musica/primavera_perigo.wav` | 117.0 | -16.5 | 0.0 | -5.9 | 4% | 2% | 1.14 | 0.19 | 4.7 | — |  |
| `musica/verao_noite` | música: camada da noite (pad) / de perigo | `assets/audio/musica/verao_noite.wav` | 117.0 | -16.1 | 0.0 | -5.7 | 2% | 1% | 1.04 | 0.33 | 0.7 | — |  |
| `musica/verao_perigo` | música: camada da noite (pad) / de perigo | `assets/audio/musica/verao_perigo.wav` | 117.0 | -16.7 | 0.0 | -5.2 | 3% | 1% | 1.10 | 0.37 | 2.1 | — |  |
| `musica/outono_noite` | música: camada da noite (pad) / de perigo | `assets/audio/musica/outono_noite.wav` | 117.0 | -16.1 | 0.0 | -4.2 | 3% | 1% | 1.45 | 0.22 | 0.9 | — |  |
| `musica/outono_perigo` | música: camada da noite (pad) / de perigo | `assets/audio/musica/outono_perigo.wav` | 117.0 | -14.6 | 0.0 | -3.5 | 27% | 9% | 0.42 | 0.26 | 1.3 | — |  |
| `musica/inverno_noite` | música: camada da noite (pad) / de perigo | `assets/audio/musica/inverno_noite.wav` | 117.0 | -16.4 | 0.0 | -6.6 | 2% | 1% | 2.01 | 0.41 | 2.7 | — |  |
| `musica/inverno_perigo` | música: camada da noite (pad) / de perigo | `assets/audio/musica/inverno_perigo.wav` | 117.0 | -16.7 | 0.0 | -6.4 | 2% | 1% | 0.93 | 0.28 | 0.9 | — |  |

## Suspeitos

- `ambiencia/s2_acido` (`assets/audio/ambiencia/s2_acido.wav`): AGUDO CONTÍNUO (97% acima de 4 kHz, varia pouco); TONAL nos agudos (planura 0.24: um apito/grilo afinado)
- `predios/coletor_madeira` (`assets/audio/predios/coletor_madeira.wav`): AGUDO CONTÍNUO (28% acima de 4 kHz, varia pouco)
- `predios/coletor_minerio` (`assets/audio/predios/coletor_minerio.wav`): AGUDO CONTÍNUO (43% acima de 4 kHz, varia pouco)
- `predios/poca_perigo` (`assets/audio/predios/poca_perigo.wav`): AGUDO CONTÍNUO (26% acima de 4 kHz, varia pouco)
- `predios/oficina` (`assets/audio/predios/oficina.wav`): TONAL nos agudos (planura 0.24: um apito/grilo afinado)
- `predios/arsenal` (`assets/audio/predios/arsenal.wav`): AGUDO CONTÍNUO (42% acima de 4 kHz, varia pouco)
- `pontuais/vento_rajada` (`assets/audio/pontuais/vento_rajada_0.wav`): REPETE muito (3.4 vezes/min, 2 variações)
- `pontuais/vento_rajada` (`assets/audio/pontuais/vento_rajada_1.wav`): REPETE muito (3.4 vezes/min, 2 variações)
- `pontuais/gotejar` (`assets/audio/pontuais/gotejar_0.wav`): REPETE muito (4.3 vezes/min, 3 variações)
- `pontuais/gotejar` (`assets/audio/pontuais/gotejar_1.wav`): REPETE muito (4.3 vezes/min, 3 variações)
- `pontuais/gotejar` (`assets/audio/pontuais/gotejar_2.wav`): REPETE muito (4.3 vezes/min, 3 variações)
- `pontuais/acido_borbulha` (`assets/audio/pontuais/acido_borbulha_0.wav`): REPETE muito (5.7 vezes/min, 3 variações)
- `pontuais/acido_borbulha` (`assets/audio/pontuais/acido_borbulha_1.wav`): REPETE muito (5.7 vezes/min, 3 variações)
- `pontuais/acido_borbulha` (`assets/audio/pontuais/acido_borbulha_2.wav`): REPETE muito (5.7 vezes/min, 3 variações)
- `pontuais/lava_estalo` (`assets/audio/pontuais/lava_estalo_0.wav`): REPETE muito (6.3 vezes/min, 3 variações)
- `pontuais/lava_estalo` (`assets/audio/pontuais/lava_estalo_1.wav`): REPETE muito (6.3 vezes/min, 3 variações)
- `pontuais/lava_estalo` (`assets/audio/pontuais/lava_estalo_2.wav`): REPETE muito (6.3 vezes/min, 3 variações)
- `pontuais/gota_eco` (`assets/audio/pontuais/gota_eco_0.wav`): REPETE muito (4.8 vezes/min, 3 variações)
- `pontuais/gota_eco` (`assets/audio/pontuais/gota_eco_1.wav`): REPETE muito (4.8 vezes/min, 3 variações)
- `pontuais/gota_eco` (`assets/audio/pontuais/gota_eco_2.wav`): REPETE muito (4.8 vezes/min, 3 variações)

Pra confirmar ouvindo: F3 > Som: o que está tocando agora > Silenciar, um por um, até o incômodo sumir.
