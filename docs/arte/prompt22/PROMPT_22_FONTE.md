# Prompt 22: fonte pixel do jogo

Data: 2026-10-02. Branch `isometrico`. Geração: **50** (2 × Create Font). Checkpoint dispensado.

## Como testar

- **cabeçalhos** das janelas de prédio (CENTRO DA VILA, OFICINA, LABORATÓRIO...), o título do menu
  de construção e das configurações, as **faixas de aviso** (INVASÃO!, GREVE!...) e o **DEEP IRON** do
  menu inicial: fonte de título pesada, estêncil de ferro;
- **números do HUD** (créditos, minério, madeira, comida, camas, ânimo, "DIA 1" e os contadores da
  barra de funções): fonte de texto pixel com **números de largura fixa** (não "dançam" quando mudam);
- o resto do texto continua na fonte de antes (ver o critério abaixo).

`amostra_fontes.png` (textos reais do jogo, com todos os acentos), `fontes_no_jogo.png` e
`fontes_janela_evento.png`.

## O que foi feito

| Pedido | Feito |
|---|---|
| Fonte de texto com TODOS os caracteres do português | o Create Font só faz A–Z, a–z, 0–9 e pontuação: **á à â ã é ê í ó ô õ ú ü ç** (maiúsculas e minúsculas) compostos por script na mesma escala de pixel, e mais **• — – → … [ ] º ª × #** (o que a interface usa) |
| Números de largura fixa pro HUD | todos os dígitos com a largura do mais largo, centrados |
| Símbolos % + - / : $ | vieram do gerador |
| Fonte de título pesada/estilizada | "Deep Iron Titulo" (estêncil de ferro) |
| Formato que o Godot usa | `.ttf` montado por script (`fontes/monta_fonte.py`): cada pixel vira um quadradinho do contorno, sem suavização |
| Amostra com textos reais | `amostra_fontes.png` |

## O critério (onde a fonte pixel entrou)

Uma fonte pixel só fica nítida em múltiplos do tamanho dela (texto: 16/32 px; título: 32/64 px). O
texto corrido do jogo usa 11 a 14 px; trocar tudo pela pixel deixaria as letras tortas ou obrigaria
a aumentar todos os painéis. Então:

- **título** em 32 px (cabeçalhos de janela, que eram 20) e 64 px (faixas de aviso e logo);
- **texto pixel** em 16 px nos números e no "DIA";
- **texto corrido** (descrições, dicas, listas) na fonte de sempre. O que faltar na fonte pixel cai
  nela também (`fallbacks`).

Se quiser tudo em pixel, dá pra subir o texto corrido pra 16 px e ajustar os painéis.

## Mudanças por arquivo

| Arquivo | O quê |
|---|---|
| `assets/fonts/deep_iron_texto.ttf`, `deep_iron_titulo.ttf` (novos) | as fontes |
| `prototipos/camera/arte_iso/fontes/` | atlas gerados, `monta_fonte.py` |
| `scripts/ui/ui_skin.gd` | `fonte()` (sem suavização, com a fonte padrão de reserva), `usa_fonte()` |
| `scripts/core/hud.gd` | cabeçalhos e faixas na fonte de título; números do HUD na de texto |
| `scripts/ui/event_window.gd`, `start_menu.gd`, `settings_panel.gd` | títulos |
