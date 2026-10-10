# Bloco 112 — Introdução e primeiro dia guiado (relatório)

Data: 2026-10-10. Branch `isometrico`. Pedido: "Prompt 4", a cena inicial e o tutorial, que viram o começo do Capítulo 1.
O plano foi APROVADO pelo Marco ("pode ser") com três decisões:
- os quadros 4 a 7 rodam **no mapa real**: a intro carrega a partida em modo cinema e entra direto na Fundação;
- o capataz usa o **retrato do minerador**, sem arte nova, com o nome "Capataz Bastião";
- usar sempre as skills do projeto.

O bloco foi pausado no meio por falta de luz e retomado nesta sessão.

- Teste: `tests/blocos/b112_intro_primeiro_dia.gd`, 59 verificações, **0 falhas**. Registrado no GUT (`test_b112_intro_primeiro_dia`, passou).
- Fotos: `docs/arte/bloco112/`, tiradas por `tests/capturas_bloco112.gd`.

## 1) O que entrou

| Item | Como ficou | Onde |
|---|---|---|
| **Quadros 1–3** (ilustrados) | Três ilustrações 640x360: o sol explode sobre a cidade mineira, as cidades em ruína, a caravana a caminho da pedreira. Cada uma tem um zoom lento e o texto aparece letra a letra. O primeiro clique completa o texto e o segundo passa o quadro. Esc ou Espaço pulam tudo. | `scenes/ui/intro.tscn`, `scripts/ui/intro.gd`, `assets/game/ui/intro/` |
| **Quadros 4–7** (no mapa) | A partida já carregada, sem HUD, sem os nomes dos prédios e sem balões. Quadro 4: a câmera atravessa a pedreira, da boca da mina até a vila. Quadro 5: o coletor de madeira em ruína na beira da floresta. Quadro 6: o corte da mina (`mapa_mundo.png`) descendo andar por andar. Quadro 7: a fogueira acesa no meio da vila, com a caravana em volta e o título DEEP IRON. O relógio **não** é mexido: voltar a hora disparava um "novo dia" falso. | `scripts/ui/intro_cinema.gd` (criado pelo `main.gd` quando `SaveManager.cinema != ""`) |
| **A fogueira** | É o efeito animado do mapa (a fogueira de 4 quadros que já existia virou fx), com luz e fumaça. Fica acesa até a Fundação: o Centro da vila, que tem o próprio fogo de acampamento, toma o lugar dela. | `World/FogueiraIntro`, `integra.py fx fogueira`, `assets/game/iso/fx/fogueira.png` + `fx.json` |
| **A pedreira vazia** | A pedreira aparece vazia já nos quadros do mapa: `founding.prepara()` tira o Centro, as casas, a cozinha e a horta do layout. | `founding.gd prepara()` |
| **Quando roda** | Na primeira partida nova (configuração `jogo/intro_vista`). Depois, só pelo botão **"Ver a introdução"** do menu, que roda numa partida que **não salva nada** (`so_vendo()`: sem save, backup nem autosave) e volta pro menu. Save carregado nunca passa pela intro. `--smoke` pula. | `save_manager.gd` (`cinema`, `ver_introducao`, `intro_terminou`, `cinema_terminou`, `so_vendo`) |
| **O guia (capataz)** | Um cartão no canto com o retrato do minerador, "Passo X de 6" e o botão "Pular o guia". Setas pulsantes, desenhadas por código, apontam o que clicar: o lugar no mapa onde fundar, o botão da função, e no Construir o botão → a aba → o cartão. Com o menu Construir aberto, o cartão some e ficam só as setas (senão ele cobriria as abas). No fim, a fala "pronto pro primeiro dia" com o botão Entendi. | `scripts/core/guia.gd` (grupo "guia", criado no `main.gd`) |
| **A missão do primeiro dia** | `cap1_primeiro_dia`, com os objetivos **em ordem** (cada um só conta depois do anterior): fundar, engenheiro, 6 com função, 3 casas, guarda e cozinha. Rende 50 cr. A **Cinzas** agora vem depois dela (pré-requisito). Quem pula ou desliga o guia continua com a missão no rastreador, só sem o capataz. | `data/missoes/cap1_primeiro_dia.tres`, `capitulo_1.txt`, `missao.gd em_ordem`, tipo de objetivo `funcoes` em `missoes.gd` |
| **Desligar** | Configurações > "Primeiro dia guiado (capataz e setas)", que vale pra todas as partidas (`jogo/guia_primeiro_dia`). | `settings_panel.gd` |
| **Sons** | Ganchos `Audio.intro(nome)` e `intro_tem(nome)`: tocam `assets/audio/intro/<nome>.ogg`, `.wav` ou `.mp3` se o arquivo existir. **Ainda não há arquivos**, então a intro roda em silêncio. Os nomes são explosao, vento, caravana, pedreira, mina, fogo e titulo. | `audio_manager.gd` |

## 2) Save

- Chaves novas:
  - `guia` = `{pulado, fim_visto}`;
  - `missoes.primeiro_dia: true`.
- Save **antigo** (sem `primeiro_dia`): a missão do primeiro dia vem cumprida, sem recompensa, e o guia não aparece. Nada se repete.
- Ficam no `settings.cfg`, não no save: a marca "intro vista" e o guia ligado ou desligado.
- As chaves estão documentadas no cabeçalho do `save_manager.gd`.

## 3) Achados e correções desta retomada (as 5 falhas que tinham ficado)

1. **"Vila fundada" contava antes da Fundação.** A primeira conferência das missões (o `_liga` adiado) via o `founded = true`, que é o padrão da cena, enquanto a partida ainda esperava a navegação. Assim o passo 1 do guia já nascia cumprido. Isso já acontecia com o objetivo "Fundar a vila" da Cinzas desde o Bloco 100, só que lá não aparecia. Correção: o `main.gd` põe `founded = false` na hora, antes do `await`.
2. **A câmera não chegava no coletor.** Ao pular um quadro, o passeio de câmera do quadro anterior (um tween de 9 s) continuava mexendo no foco e brigava com o novo. Correção: cada quadro mata o passeio anterior (`_tw_foco`).
3. **A fogueira não sumia na Fundação.** A ligação com o `founding.done` era uma função do próprio nó do cinema, e esse nó é apagado antes da Fundação acabar. O Godot desfaz a ligação junto. Correção: ligar direto no `queue_free` da fogueira.
4. **O teste do "guarda fora de ordem".** O guarda posto antes da vez conta quando chega o passo dele, e esse é o comportamento certo. O teste agora tira esse guarda antes de distribuir as funções, para medir a seta do passo 5.
5. Visto nas fotos e corrigido:
   - a legenda de 2 linhas era cortada embaixo (a faixa agora tem 112 px, nos quadros ilustrados e no mapa);
   - os balões de "sem trabalho" apareciam na caravana parada (`ipezinho.sem_baloes` durante o cinema);
   - um ipezinho tapava a fogueira (a roda agora fica dos lados e atrás do fogo, e a câmera termina com o fogo abaixo do título);
   - o cartão do capataz cobria as abas do Construir.
6. Arrumado também:
   - a imagem `Q1_sol.png` com maiúscula, renomeada para `q1_sol.png` (quebraria no Linux e no pacote exportado);
   - um comentário de documentação do `missoes.gd` que tinha ficado partido.

## 4) Arte

- **75 gerações**, saldo de ~5.562 para ~5.487. São as 3 ilustrações (`prototipos/camera/arte_iso/intro112.py`, com os comandos gera, galeria e integra), aprovadas pelo Marco ("ok").
- A fogueira é a que já existia (0 gerações).
- O capataz é o retrato do minerador (0 gerações).

## 5) Testes rodados (um por vez, em primeiro plano, APPDATA isolado; o save real conferido por md5)

| Teste | Resultado |
|---|---|
| `b112_intro_primeiro_dia` (direto e pelo GUT) | 0 falhas (59 OK) |
| `b100_missoes` | 0 falhas. Ajustado: a Cinzas depende do Primeiro dia (o `_base` marca o primeiro dia cumprido), e o save sem `primeiro_dia` é save antigo |
| `b37_fundacao_raio` | 0 falhas |
| `b95b_construir_abas` | 0 falhas |
| `b95_layout_v2` | 0 falhas |
| `p28_save` | 0 falhas |
| `hud_frostpunk` | 0 falhas |
| `b52_debug_telemetria` | 0 falhas |
| `b111_familias` | 0 falhas |

**Não conferidos:** o resto da bateria (seguindo a nota de memória, não rodei tudo).

## 6) Pendências

- **Sons da intro.** Os ganchos estão prontos, faltam os arquivos. Dá pra gerar com a skill de efeitos sonoros (ElevenLabs) se o Marco quiser.
- **Ver a intro rodando com os próprios olhos** (o ritmo dos quadros e o texto). As fotos cobrem cada quadro parado.
