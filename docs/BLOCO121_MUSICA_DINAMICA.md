# Bloco 121 — Música dinâmica: camadas por estação, temas e fallback (relatório)

Data: 2026-10-11. Branch `isometrico`. Pedido: Prompt 7, parte do **sistema** (guia seção 23): `AudioStreamSynchronized` (camadas: base, percussão que entra com o perigo, melodia de dia, "pad" à noite) e `AudioStreamInteractive`
(troca de trechos no tempo certo), variações por estação, temas de menu, vitória e derrota, as 2 músicas de antes como fallback, volumes por camada nos `@export`, controle nas Configurações, teste de carga e de transição.
As faixas e o veredito de sincronia são do Bloco 120 (as 4 estações ficaram sincronizadas, `docs/audio/SINCRONIA_MUSICA.md`).
Teste: `tests/blocos/b121_musica_dinamica.gd`, **0 falhas**, registrado no GUT. **Nada foi ouvido por mim.**

## 1) Como funciona (`scripts/core/musica_dinamica.gd`, filho do `Audio`)

- **Camadas** (um `AudioStreamSynchronized` por estação, 3 faixas do mesmo BPM e tom que tocam juntas): o **pad** (`<estação>_noite`: drones, a base que nunca para), a **melodia** (`_dia`: violão e sanfona) e a **percussão** (`_perigo`: metal e correntes).
  O jogo só mexe no volume de cada camada (`set_sync_stream_volume`, que muda ao vivo, medido):

| Situação | Melodia | Pad | Percussão |
|---|---|---|---|
| Dia | -3 dB | -9 dB | muda |
| Noite | muda | -2 dB | muda |
| Perigo (invasão) | -11 dB (cede) | como o resto | -3 dB |
| Fundo da mina (S2 a S5) | -14 dB a mais (menos melodia) | +3 dB a mais (mais drone) | — |

  Os valores são `@export` (`melodia_dia_db`, `melodia_noite_db`, `melodia_fundo_db`, `melodia_perigo_db`, `pad_dia_db`, `pad_noite_db`, `pad_fundo_db`, `percussao_perigo_db`) e as camadas sobem e descem aos poucos (`camada_fade_s` = 2,5 s), nunca de uma vez.
- **Clipes** (um `AudioStreamInteractive`): 4 estações (primavera, verão, outono, inverno pela `sun.season_index()`) + 3 temas (menu, vitória, derrota). Trocar de clipe é um **crossfade de 3 s** (`crossfade_s`). Estação → estação continua **do mesmo ponto** (as faixas têm o mesmo tamanho: 117 s = 39 compassos);
  tema entra e sai **do começo**.
- **No tempo certo:** os WAV não têm BPM, e sem BPM o Godot trata `NEXT_BAR` como troca imediata (medido). Por isso o `MusicaDinamica` **conta os compassos** (80 BPM, 3,0 s cada, a partir do começo do clipe) e só pede a troca de estação na **virada do compasso**
  (se faltar menos de 0,15 s espera o seguinte). Também sem BPM o Godot conta **1 batida = 1 s** no `fade_beats`, então `crossfade_s` vai direto como `fade_beats`.
- **Temas:** o **menu** (`tema_menu`) toca na tela inicial no lugar da abertura de antes (`Audio.tema("abertura")`); **vitória** e **derrota** entram depois do stinger (`Audio.stinger`) e, passados 60 s (`tema_fim_segundos`), a música do jogo volta.
- **Configurações:** caixa **"Música em camadas (estação, dia, noite, perigo)"** e três sliders (**Melodia**, **Base e pad**, **Percussão**, 0 a 100%: 100% = o `@export`; 0 cala a camada). Salvos em `settings.cfg` (`musica_dinamica`, `mix_melodia`, `mix_pad`, `mix_percussao`); não mexe no save da partida.

## 2) O fallback (o jogo continua como hoje)

`ativa()` só é verdadeiro com a opção ligada, a música ligada e **pelo menos uma estação completa** (as 3 faixas). Sem isso (arquivos faltando, opção desligada) o `Audio` toca as 2 músicas de antes (`musica/jogo` e `musica/perigo`, com a reserva do loop antigo), como no Bloco 117,
e o perigo troca as duas de antes. Estação incompleta usa a completa mais perto. Quem toca a música do jogo é **só uma por vez** (`_reconcilia_musica`). Em **headless** (testes) a dinâmica fica desligada para os outros testes seguirem como antes (`MusicaDinamica.forcar = true` liga).

## 3) Testes (`b121_musica_dinamica`)

(A) a carga (15 faixas em ~1,4 s): 4 estações completas e 3 temas, o Interactive com 7 clipes e transições entre todos, as 3 camadas do mesmo tamanho; (B) os volumes por situação (dia, noite, perigo, fundo, mix 50% e 0); (C) tocando de verdade (o bus Music tem som, a música antiga fica muda);
(D) trocas: estação nova só na virada do compasso (103000 ms a 3,0 s; quase em cima da virada espera a seguinte), vitória entra e a música volta depois de 60 s, tema do menu e a volta pra partida; (E) fallback: sem arquivos, desligada, headless sem forçar; (F) o `set_danger` não liga a música de perigo antiga,
desligar a opção devolve as 2 músicas de antes e ligar volta; o painel e o save. Vizinhos: b114, b115, b116, b117, b118, b120, b55, b54, hud_frostpunk (0 falhas, save real conferido por md5).

## 4) O que NÃO foi verificado

- **Nada foi ouvido.** Os valores de dB, o tempo de 2,5 s das camadas e o crossfade de 3 s são palpite: ajuste os `@export` do `MusicaDinamica` depois de ouvir (o `Audio` tem um nó filho `MusicaDinamica`).
- O alinhamento de **compasso** entre as camadas (a "batida 1") não dá para medir por números; se uma estação soar fora, `gerar_musica.py --so <id> --candidatos 3` gera outras versões.
- Os testes trocam os clipes no mixer headless; não conferi o crossfade de 3 s no ouvido nem numa partida (a vitória e a derrota só foram disparadas por `toca_tema`/`stinger`, não jogando até o fim).
- Memória: as 15 faixas (QOA) ocupam ~55 MB depois de carregadas (só quando a dinâmica liga; o carregamento leva ~1,4 s na primeira vez em partida).
- O ícone do slider/volume do menu de pausa não tem arte própria (usa os controles padrão).
