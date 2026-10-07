# Prompt 19: luz e noite

Data: 2026-10-01. Branch `isometrico`. **Sem geração** (tudo por código; saldo **1.359**).

## Como testar

Jogue até anoitecer (ou tecla N pra pular a fase) e olhe:

- **janelas acesas:** casa ocupada, taverna, laboratório, Centro (estágios 4 e 5) e oficina
  acendem as janelas à noite, claras mesmo com o ambiente escuro; de dia ou vazias, apagadas;
- **poças de luz no chão** em faixas (combina com pixel art): tocha, lampião do armazém, fogueira
  do Centro no estágio 1, forja da oficina e do arsenal, cabine e giroflex da escavadeira,
  lanterna do capacete dos mineradores, cristais (cada um na cor dele), lava nas fendas de calor
  do abismo;
- **cada luz no ponto certo do desenho** (a janela, a porta, o fogo), não mais "mais ou menos";
- **estações:** verão mais quente, outono dourado, inverno mais frio e azulado, e a noite de
  inverno um pouco mais escura;
- no **nível 2**, os cristais brilham (antes as luzes do subsolo ficavam apagadas, ver abaixo).

## Como ficou

`ciclo_dia_noite.gif` (amanhecer → madrugada, vila + mina), `janelas_acesas.png` (simulação da
noite em cada prédio com janela), `n1_vila_noite.png`, `n3_nivel2_cristais.png`,
`n4_abismo_lava.png`, `c05_entardecer.png`, `c07_noite.png`, `n5_inverno_noite.png` e
`n6_verao_noite.png`. Fotos geradas por `tests/ciclo_luz.gd`.

## O que o prompt pedia → o que foi feito

| Pedido | Feito |
|---|---|
| Texturas de luz pra tocha, lampião, fogueira, forja, lanterna, reator, cristais, lava | 11 texturas (+ janela, cabine, giroflex) em `assets/game/iso/luz/`, feitas por script (`python integra.py luz`): branca em **faixas**, as de fogo com a borda irregular. Cor, ganho e alcance de cada tipo em `scripts/iso/iso_luz.gd` |
| Máscara de janelas acesas por prédio, a partir da arte | `<estado>__janelas.png` em 10 desenhos. O vidro âmbar das janelas é achado sozinho (tom, saturação, brilho e contraste com a moldura, `luz/janelas_util.py`); as janelas de vidro escuro foram marcadas à mão em `luz/luzes.json`. Acende com a cor compensada pelo ambiente |
| Ponto de luz por peça (vem com a arte) | `luzes` no `predios.json` (19 desenhos anotados): janela, lampião, fogueira, forja, cabine, reator, giroflex. Cada luz do jogo vai pro ponto do tipo dela (`WindowLight` → janela/fogueira/lampião, `ForgeLight` → forja, `CabLight` → cabine...) |
| Cor/intensidade por período e estação, testada em vila + mina | período: as cores do DayNight (aprovadas no Prompt 27) continuam; **estação**: `season_tints` no `day_night.gd` (primavera neutra, verão quente, outono dourado, inverno frio) + noite de inverno 12% mais escura |
| GIF de um ciclo | `ciclo_dia_noite.gif` |

## Defeitos achados e corrigidos no caminho

| Defeito | Desde | Correção |
|---|---|---|
| **Luzes não alcançavam o terreno nem boa parte das coisas:** a ordem de desenho usa z de −4060 a 4096, e a luz só ilumina −1024..1024 por padrão | Prompt 28 | as luzes copiadas alcançam toda a faixa de z |
| **Tocha e cristal sem luz na vista iso:** o desenho antigo some quando a arte nova entra, e a luz era filha dele | Prompt 29 (parte 4) | some só o desenho do pai (alfa 0); os filhos continuam |
| Luz da tocha com raio ~3× maior (herdava a escala da peça antiga) e cortando em degraus | Prompt 29 | a escala global das luzes copiadas é 1 (o alcance vale em px de arte) |
| **Luzes do nível 2 e do abismo apagadas:** o jogo apaga as luzes fora da tela conferindo o chão da superfície; os andares de baixo ficam mais embaixo na tela | Prompt 29 (parte 1) | confere na tela iso (`to_screen` leva cada luz pro andar dela) |
| Terreno em imagens enormes (até 6.000 px): o Godot aplica um número limitado de luzes por item | Prompt 29 | o terreno é desenhado em blocos de 256 px (`iso_view.gd`, `_em_blocos`); a caixa, o z e os tons continuam do pedaço |

## Mudanças por arquivo

| Arquivo | O quê |
|---|---|
| `scripts/iso/iso_luz.gd` (novo) | tipos de luz (cor, ganho, alcance), tipo de cada luz do jogo, ponto anotado, cor das janelas |
| `scripts/iso/iso_billboard.gd` | luzes no ponto do desenho, com o tipo; janelas acesas; luz alcança todo o z; escala da luz 1; o desenho antigo some sem levar a luz junto; lanterna/olho do robô |
| `scripts/iso/iso_art.gd` | o estado traz `luzes` e `janelas` |
| `scripts/iso/iso_view.gd` | luz de lava nas fendas de calor; terreno em blocos de 256 px |
| `scripts/core/environment.gd` | apagar luz fora da tela confere na tela iso (andares de baixo) |
| `scripts/core/day_night.gd` | tom do ambiente por estação |
| `prototipos/camera/arte_iso/integra.py` | `luz` (texturas + janelas + pontos); o `predios` grava as luzes também |
| `prototipos/camera/arte_iso/luz/` (novo) | `luzes.json` (anotação), `janelas_util.py` |
| `assets/game/iso/luz/` (novo), `assets/game/iso/predios/*/*__janelas.png` | texturas e máscaras |
| `tests/blocos/p19_luz.gd` (novo), `tests/test_blocos.gd` | o teste |
| `tests/blocos/p29_predios.gd` | **mudado de propósito**: a camada de janelas acesas não conta como desenho do prédio |
| `tests/ciclo_luz.gd` (novo) | fotos e GIF do ciclo |

## Testes

| Bateria | Resultado |
|---|---|
| `p19_luz` (novo) | 11 texturas; casa com janelas e ponto de luz; escavadeira com 3 pontos; obra sem luz; janelas acesas só à noite e com a casa ocupada (vazia ou de dia: apagadas); cor compensada; armazém com a luz no ponto anotado e textura de lampião; luz alcança todo o z; força = jogo × ganho; lanterna do capacete; tocha com luz visível; cristal com a cor dele; lava em cada fenda de calor; inverno mais frio, verão mais quente, noite de inverno mais escura |
| GUT completo (33 blocos + 12 rápidos) | **45/45**; save real com o md5 igual antes e depois da bateria |

**Save real:** o `savegame.json` mudou às 21:39:53 (backup automático às 21:36:00), com o editor
do Godot aberto e antes da minha primeira execução desta rodada (21:38, na pasta isolada: a
pasta isolada ganhou o `gut_temp_directory` dela às 21:38:31; a real tem o das 21:34). Foi uma
partida rodada pelo editor, não um teste. Se não foste tu, me avisa.

## Limites

1. As janelas de vidro escuro (oficina, laboratório, Centro 4/5, casa 2) foram marcadas à mão; a
   máscara acende os pixels mais escuros do retângulo (o vidro), então em janelas com veneziana
   aparece um pouco da madeira.
2. Prédios sem janela visível no desenho (armazém, arsenal, enfermaria) acendem só a luz do ponto
   (porta, forja).
3. As texturas de luz são feitas por script, não geradas: são formas simples em faixas. Se quiser
   luzes desenhadas (fumaça, brilho do fogo), entra no Prompt 18 (efeitos).
