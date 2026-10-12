# Bloco 133 — Área da vila maior (estágios 4 e 5) e o som da noite refeito

Pedido do Marco: "aplicar a área maior nos estágios 4 e 5, **não realizar testes**, apenas aplicar os ajustes (eu vou
jogar e testar)" e "refazer a `floresta_noite` por algo melhor". Ao ouvir a primeira troca, ele avisou: "parece radiação
com interferência". **Por pedido dele, nenhum teste foi rodado e não há teste novo deste bloco.**

## 1. Área da vila

`environment.gd` `area_vila_meia` (meia largura x meia altura, px do chão):

| Estágio | Antes | Agora |
|---|---|---|
| 4 | 440 x 440 | **460 x 560** |
| 5 | 500 x 500 | **520 x 680** |

Os estágios 1 a 3 não mudaram. A área segue cortada pela paliçada a oeste e pela divisa do leste. Nos estágios 4 e 5
ela agora cobre o norte da vila: com o Centro da partida nova, o estágio 5 vai de y ≈ −870 a +490.

O que muda no jogo: a decoração removível sai de uma área maior quando a vila sobe pro estágio 4 e pro 5, e a grade de
construção é desenhada nela. Construir já era permitido na vila toda; isso não mudou. A medição do Bloco 132 indica que
a vila toda comporta 55 prédios médios e 91 casas, contra ~24 prédios e 8 a 10 casas do plano.

## 2. O som da noite (`ambiencia/floresta_noite`)

| | Original | 1ª troca (descartada) | **Agora** |
|---|---|---|---|
| O que era | grilo contínuo e afinado | vento com estática | vento grave e limpo nos pinheiros |
| Pico de frequência | 7–7,8 kHz | grave, com chiado | grave |
| Energia acima de 4 kHz / 8 kHz | 100% / 34% | 12% / 3% (depois do corte) | **6% / 1%** |
| Planura (baixa = tom fixo) | 0,05 | 0,44 | 0,50 (ruído de vento, sem tom) |
| Estática (saltos por segundo) | — | **1.165** | **1,3** (o vento do inverno tem 5,3; a mina, 0,5) |
| Sonoridade do arquivo | −11,8 LUFS | −19,9 | −16,7 |
| `db` do slot | −5 | −5 | **−7** |
| Efetivo (arquivo + slot) | −16,8 | −24,9 | **−23,7** (o dia é −23,1; a mina, −22,2) |
| Emenda do loop (estalo, limite 6) | 0,3 | 2,6 | 1,3 |

**Como chegou aqui:**

1. **1ª rodada (prompt "quiet forest... sparse distant insects"):** duas candidatas vieram quase em silêncio. A #2 precisou
   de +28 dB, e o ganho subiu junto o ruído de fundo: 1.165 saltos por segundo, a "radiação com interferência" que o
   Marco ouviu.
2. **2ª rodada:** o prompt passou a pedir vento limpo e contínuo, "clean smooth high quality recording, no static, no
   crackle, no hiss, no insects, no high-pitched tones", no estilo do vento do inverno. As três vieram limpas de estalos
   (0,1 a 58 saltos/s), mas com chiado de ruído branco (55% a 81% da energia acima de 4 kHz). Escolhi a **#0**: sem tom
   fixo, sem estalos e com o vento subindo e descendo (variação 0,25).
3. **Corte de agudos:** a #0 passou por um passa-baixa em **2,5 kHz** (`tools/elevenlabs/passa_baixa.py`). O filtro é
   circular, então a emenda do loop continua perfeita. O RMS de antes foi recuperado com o pico ≤ −2 dBFS. O chiado
   acima de 4 kHz caiu de 81% para 6%.
4. **Volume:** o slot foi de −5 para −7 dB, pra noite ficar um pouco mais calma que o dia.

**Gasto:** 2 rodadas de 3 candidatas (~1.890 créditos; o saldo ficou em ~90.200). Ferramenta nova
`tools/elevenlabs/estalos.py` (mede a estática: saltos por segundo e curtose). `docs/audio/DIAGNOSTICO_NOITE.md` foi
refeito, e a `floresta_noite` não aparece mais entre os suspeitos.

**Arquivos:** `assets/audio/ambiencia/floresta_noite.wav` (import da Godot feito), o slot em `data/audio/slots.json`
(prompt, `quando`, `db`), `data/audio/gerados.json` e os docs de áudio (`docs_audio.py`).

## Não verificado

- **Nenhum teste rodado** (pedido do Marco). Os testes de áudio que conferem esse slot são o `b116_audio_carga` (os
  arquivos carregam e não estão inaudíveis) e o `b55`/`b114`.
- **Ninguém ouviu o som novo.** Só os números foram conferidos (estática, agudos, tom, emenda, sonoridade). Quem decide se
  ficou bom é o Marco jogando. Se ainda incomodar, dá pra silenciar no F3 > Som e me dizer o que ouviu.
- **Outro suspeito da mesma família:** a `ambiencia/floresta_dia` também tem 92% da energia acima de 4 kHz (pássaros: é
  natural de dia) e o mesmo padrão de saltos. Não mexi.
