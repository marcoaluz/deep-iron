# Prompt 16: conceito das criaturas e inimigos

Data: 2026-10-01. Branch `isometrico`. Geração: **18** (pixen, 1 cada). Saldo 1.359 → 1.341.

## O que o jogo tem hoje (código)

- **2 invasores** (`scripts/creatures/creature.gd`, `defense.gd`):
  - **Lumívoro** — come luz e calor; vem da floresta pelo portão; ataca quem está acordado lá
    fora e, nos prédios acesos, assusta quem está dentro (ânimo cai). Foge da luz ao amanhecer.
  - **Ferrugento** — máquina de antes da explosão; sobe pelo poço do elevador (depois que o nível
    2 abre); ataca quem está perto e rouba minério do armazém. Desliga ao amanhecer.
- Ondas: a cada invasão vem mais (lumívoros por onda, ferrugentos depois do nível 2) e a vida
  cresce **15% por onda**. Não há tipos/níveis separados nem chefe.
- Estados que a lógica usa: andar (2 quadros), atacar (golpe), levar golpe (pisca), morrer
  (some), fugir/desligar ao amanhecer; o ferrugento rouba minério pela brecha (Bloco 36).

## As 3 linhas (prancha: `prancha_conceito.png`, com o minerador e o guarda pra escala)

| Linha | Fraco | Médio | Forte |
|---|---|---|---|
| **A — mutados pela radiação** (Lumívoro) | rastejante pálido, veias violeta, olhos pretos | "bruto": couraça de osso, rachaduras violeta | "matriarca": muitos olhos, coroa de cristal violeta |
| **B — máquinas de antes** (Ferrugento) | aranha enferrujada, olho vermelho, caçamba de minério | "carregador": garras hidráulicas, esteira, lâmpada de alerta | "colosso": broca e garra, vários olhos, fumaça |
| C — saqueadores humanos | maltrapilho com máscara de gás e porrete | blindado com sucata e lança | chefe com máscara de solda e marreta |

Arquivos: `prototipos/camera/arte_iso/criaturas/conceito/` (2 variações de cada; ids em `jobs.json`).

## Escolha (o Marco liberou seguir sem checkpoint)

- **Linhas A e B**: batem com o que o jogo já conta (a criatura que come luz; a máquina antiga
  que rouba minério). A linha C (humanos) ficou só no conceito.
- **Lumívoro = A1 v1** (rastejante pálido) e **Ferrugento = B1 v1** (aranha com caçamba).
- **Variante forte** (o jogo escala a vida por onda): **bruto (A2)** e **carregador (B2)**
  aparecem a partir da onda 4.
- **Matriarca (A3) e colosso (B3)**: a "criatura mestre" pedida pelo Marco. O jogo ainda não tem
  chefe: ficam no conceito pra quando o gameplay existir (Prompt 31).
