# Prompt 23: retratos de personagens e expressões

Data: 2026-10-02. Branch `isometrico`. Geração: **~498** (teste 26; 20 retratos pro: 18 × 20 + 2
× 20 = 400; 72 expressões × 1).

## Como testar

Selecione **um** ipezinho: aparece o **cartão com o retrato** no canto de baixo à esquerda (nome,
função e como ele está). O retrato é da mesma pasta do boneco (função × gênero), no **tom de pele
dele**, com a **expressão pelo estado**:

| Estado | Expressão |
|---|---|
| machucado ou caído | **ferido** (curativo na cabeça) |
| em greve ou furioso | **bravo** |
| ânimo abaixo de 35 ou com fome | **cansado** (choroso) |
| ânimo 70 ou mais | **contente** |
| o resto | neutro |

`prancha_retratos.png` (as 18 funções nos 3 tons + as 5 expressões de 2 deles) e
`retrato_no_jogo.png` (o Lalo machucado, no save real).

## O que foi feito

| Pedido | Feito |
|---|---|
| Retrato por função, masculino e feminino | 18, gerados pelo conversor de retrato do PixelLab **a partir do próprio boneco** (mesma roupa, cabelo e rosto) |
| Compatível com as 3 paletas de pele | a mesma regra de paleta dos bonecos (`tons_de_pele.py`), com a faixa do rosto do retrato: 3 arquivos por expressão |
| Expressões: neutro, contente, cansado/triste, bravo, ferido | 4 por retrato (edição barata do retrato neutro, 1 geração cada) |
| Robô antigo e invasores | o robô já tinha retrato (Prompt 5); Lumívoro e Ferrugento novos (pros eventos) |
| Animação de fala | não fiz: o jogo não tem evento com diálogo (ficou pra quando tiver) |
| Uso: painel de seleção e janelas de evento | cartão do selecionado; `Retratos.de_nome()` pros eventos |

## Teste do caminho mais barato

Comparei no minerador: o conversor de retrato (25 gerações em 64 px) contra uma edição do busto
ampliado (1 geração). O conversor ficou bem mais rico (barba, rugas, roupa); usei ele em 48 px
(20 gerações) pra caber no saldo. As expressões saíram boas pela edição barata.

## Limites

1. Em 2 ou 3 retratos o tom mais escuro pega só parte do rosto (a regra de paleta acha menos pixel
   de pele quando o rosto é muito sombreado).
2. O retrato do Lumívoro ganhou chifres que o boneco não tem.

## Arquivos

`prototipos/camera/arte_iso/retratos/` (base, expressões, `retratos.py`), `assets/game/ui/retratos/`,
`scripts/ui/retratos.gd` (novo), `scripts/core/hud.gd` (cartão do selecionado).
