# Prompt 17: criaturas/inimigos (produção)

Data: 2026-10-01/02. Branch `isometrico`. Geração: **~142** (4 bases pro × 25, 4 personagens v3 × 1,
16 animações v3 ≈ 37, carga 1). Linhas escolhidas no Prompt 16: **A (mutados)** e **B (máquinas)**.

## Como testar

Jogue até uma noite de invasão (dia 3, ou `N` pra pular) e olhe os invasores chegando:

- **Lumívoro** (rastejante pálido de veias violeta) e **Ferrugento** (aranha enferrujada de olho
  vermelho com caçamba) andam, atacam, piscam ao levar golpe e **caem** (ficam no chão um pouco,
  levantam poeira e só então somem);
- ao amanhecer o Lumívoro foge e o Ferrugento **desliga** (a mesma queda);
- a partir da **onda 4**, 1 a cada 3 vem na **forma forte**: **Lumívoro bruto** (couraça de osso) e
  **Ferrugento carregador** (garras hidráulicas e esteira), com mais vida e dano;
- o Ferrugento que **roubou** minério do armazém sai com a caçamba cheia;
- a barra de vida fica em cima da arte nova.

`criaturas.gif` / `criaturas.png` (no jogo, de dia), `criaturas_noite.png`, `animacoes.gif` (as 4
animações dos 4 bichos lado a lado) e `prancha_criaturas.png`.

## O que o prompt pedia e o que foi feito

| Pedido | Feito |
|---|---|
| 4 direções: parado, andar, correr/investir, atacar, dano, derrubado/morto | SE e NE desenhadas, SO e NO espelhadas (regra do contrato): **parado, caminhada, atacar, dano, morrer**. Investir = a caminhada (a lógica não tem corrida separada). Sem gore: cai e vira poeira |
| Variante de nível/força | **bruto** e **carregador** (forma, tamanho e cor diferentes). O jogo só escalava a vida por onda; agora a Defesa manda a forma forte (`defense.gd`: `strong_from_wave` 4, `strong_every` 3, vida ×1,6, dano ×1,3; `strong_every = 0` desliga) |
| Roubo/carregar | caçamba cheia de minério por cima do Ferrugento que roubou (pela brecha ou no armazém) |
| Ícone de alerta e retrato | vão nos Prompts 21 (ícones) e 23 (retratos) |
| Matriarca/colosso (o "chefe") | só no conceito (Prompt 16): o jogo ainda não tem chefe |

## Defeitos da geração e o que fiz

- As rotações saíram **giradas 45°** em 2 bichos (a base não estava de frente). Cada bicho tem o
  mapa "direção desenhada → rótulo do PixelLab" (`integra.py`, `CRIATURAS`).
- O olho do Ferrugento virou verde-água em alguns quadros da caminhada: **corrigido por paleta** na
  exportação (`_olho_vermelho`).
- Carregador: o para-brisa fica rosado em 3 quadros da caminhada e há um brilho branco no vidro em
  outros. Ficou assim (só se nota parado e de perto); dá pra refazer a caminhada dele (~4 gerações).
- A morte do Ferrugento é discreta (as pernas dobram pouco); a poeira da queda ajuda.
- O brilho de todos ficou dentro da faixa do contrato (0,188–0,257).

## Mudanças por arquivo

| Arquivo | O quê |
|---|---|
| `scripts/creatures/creature.gd` | `variant`, `make_strong()`, quando atacou/levou golpe/caiu/foi embora (pra animação), `looted`; a queda fica 1,4 s no chão antes de sumir (só com o mapa novo) |
| `scripts/core/defense.gd` | forma forte nas ondas altas; o saque pela brecha marca a carga |
| `scripts/iso/iso_bonecos.gd` | `criatura_pose()` (animação pelo estado, direção, carga) |
| `scripts/iso/iso_billboard.gd` | criaturas com o desenho novo; poeira da queda; barra de vida acima da arte nova |
| `prototipos/camera/arte_iso/integra.py` | `criaturas` (exporta as 4 pastas pro `bonecos.json`, espelha, corrige o olho) |
| `prototipos/camera/arte_iso/criaturas/` | conceito, bases, personagens, animações, `carga_ferrugento.json` |
| `assets/game/iso/bonecos/criatura_*/` | as tiras |
| `tests/blocos/p17_criaturas.gd` (novo) | o teste (25 verificações) |
