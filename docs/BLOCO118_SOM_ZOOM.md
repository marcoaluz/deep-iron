# Bloco 118 — O som segue o zoom (modelo Frostpunk) (relatório)

Data: 2026-10-10. Branch `isometrico`. Pedido do Marco: "queria que o jogo tivesse os sons igual Frostpunk, meio que só fazer barulho quando clica em cima da área ou quando dá zoom;
analise jogos que têm som e deixe no mesmo sistema". Teste: `tests/blocos/b118_audio_zoom.gd`, **0 falhas**, registrado no GUT (`test_b118_audio_zoom`).
Nada foi ouvido por mim (só números e comportamento).

## 1) O que os jogos fazem (a análise)

| Jogo | Regra de som |
|---|---|
| **Frostpunk** | Um fundo constante (vento, música) em qualquer zoom. Os detalhes (geradores, operários, martelo, passos) só aparecem quando a câmera está perto; clicar num prédio toca o som dele e um toque de confirmação. Alertas e música são sempre ouvidos. |
| **RimWorld** | Cada som tem uma faixa de zoom: com a câmera longe o som do trabalho some; só toca o que está perto da câmera. |
| **Cities: Skylines / Manor Lords** | Sons de rua e de oficina só com a câmera perto; o fundo geral sobe e desce com a altura. |
| **Banished / Against the Storm** | Vila silenciosa na visão ampla; o detalhe (machado, fogo, vozes) entra ao aproximar. |

O que se repete: (1) **fundo e música sempre**; (2) **detalhe só com a câmera perto**, entrando suave; (3) **acontecimentos grandes** (alarme, criatura, sino) se ouvem de mais longe;
(4) **clicar mostra o som** do que foi clicado; (5) **interface sempre**.

## 2) Como ficou no DEEP IRON

Cada slot ganhou uma **classe de zoom** (`audio_slots.gd zoom_de`: campo `zoom` do slot, senão a exceção por id, senão o padrão da pasta):

| Classe | O que é | Exemplos |
|---|---|---|
| `perto` | detalhe | passos, voz, picareta, machadada, martelo, bichos, loops de prédio (fornalha, taverna, cozinha...) |
| `medio` | acontecimento | grito da criatura, portão, máquina quebrada, trovão, escavadeira, cemitério, vagonete |
| `global` | sempre | interface, stingers, alarme, solar, fanfarra, sinos, vitória, ambiência de fundo, música |

A medida é `cam.art_pixel_screen` (quantos pixels de tela 1 pixel de arte ocupa; não depende do tamanho da janela). As paradas do zoom são 0,5 (vista "longe"), 1 (a vista de sempre), 2 e 3 (bem perto).
O volume vai de **mudo a inteiro numa curva suave** (`smoothstep`), configurável em `@export` do `Audio` (grupo "Zoom (Bloco 118)"):

| Vista | `perto` | `medio` | fundo (ambiência) |
|---|---|---|---|
| 0,5 (longe) | mudo | mudo | −9 dB |
| 1 (a de sempre) | ~42% (mais baixo) | inteiro | normal |
| 2 ou mais (perto) | inteiro | inteiro | normal |

- **Efeitos posicionais, passos, voz e sons soltos** (pássaro, gota...) não tocam abaixo do mínimo e tocam mais baixo no meio do caminho (`play_at(..., classe)`).
- **Loops de prédio** (`sons_predios.gd`): a câmera longe = o prédio fica mudo; o volume acompanha o zoom (suave, a cada 0,25 s).
- **O fundo** (bus Ambience) desce 9 dB na vista longe e sobe de volta (até 12 dB por segundo): é um efeito `Amplify` ("zoom") no bus, então o slider de Ambiência não é mexido.
- **Música, interface, stingers e alarme não mudam** com o zoom.
- **Clicar mostra o som:** `hud.open_panel_for` chama `Audio.selecionar_predio(no)`: o som do prédio clicado se ouve **de qualquer zoom por 4 s** (`destaque_segundos`) e toca um toque curto
  (`ui/selecionar_predio`, 3 variações geradas agora no ElevenLabs, 16 créditos). Clicar num ipezinho (`main.gd`, mapa e vista iso) faz ele **responder** com a voz curta (`Audio.selecionar_gente`, sem a regra de zoom).
- Em **headless** (testes) o zoom é 99 (tudo se ouve): os outros testes não mudaram.

## 3) Testes

`b118_audio_zoom` (0 falhas): classes e curva; efeitos/passos/voz/loops mudos longe e audíveis perto; fundo desce e volta; música sem efeito de zoom; destaque do clique (dura 4 s e acaba);
o toque de selecionar tem 3 variações; ganchos no `hud` e no `main`. Vizinhos: b114, b115, b116, b117, b55, hud_frostpunk, b95_layout_v2 (0 falhas), save real conferido por md5.

## 4) O que NÃO foi verificado

- **Como soa de verdade.** Os limiares (0,6 / 1,5 para `perto`; 0,5 / 1 para `medio`; −9 dB de fundo) são um palpite calibrado nas paradas do zoom; ajuste os `@export` `zoom_*` do `Audio` depois de ouvir.
  Se na vista de sempre (1) o trabalho ainda estiver baixo demais, baixe `zoom_perto_mudo`/`zoom_perto_cheio`.
- Não conferi o valor real de `art_pixel_screen` numa janela de verdade (em headless o zoom é 99); as paradas 0,5/1/2/3 vêm do código da câmera (`camera_controller.gd`).
- Os cliques foram testados pelos ganchos (`open_panel_for`, `select`), não com o mouse numa partida.
