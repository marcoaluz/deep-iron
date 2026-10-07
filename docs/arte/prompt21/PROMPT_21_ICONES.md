# Prompt 21: ícones do jogo

Data: 2026-10-02. Branch `isometrico`. Geração: **66** (55 pixen + 11 refeitos). Tamanho base:
**32 px** (24 px na barra de recursos, 16 px os que ficam sobre a cabeça).

## Como testar

- **barra de cima:** créditos, minério, madeira, matéria-prima, comida (vira o **alerta de falta**
  quando acaba), camas, ânimo, saúde e a **estação** (flor/sol/folha/floco; na onda solar, o alerta);
- **barra de funções:** construir e as 9 funções (picareta, arco, maleta, chave+martelo, panela,
  machado, lança+escudo, frasco), sem função (luva), turno extra (lua + lampião);
- **laboratório:** cada tecnologia com o ícone dela (11);
- **menu de construção:** cada prédio é o **render reduzido do desenho pronto** (sem gerar de novo);
- **faixas de aviso** com ícone: invasão, roubo, onda solar, greve, pane do reator, robô, achado,
  morte/guarda caído, festa, pesquisa...;
- **sobre a cabeça** (vista iso): curativo e zanga novos; "**!**" em cima da criatura que está
  caçando alguém (ícone de alerta pedido no Prompt 17);
- **obra parada** (sem engenheiro): ícone do lado da barrinha da obra.

Folha: `folha_icones.png`.

## O que o prompt pedia e o que foi feito

| Pedido | Feito |
|---|---|
| Recursos | créditos, minério, ferro, cobre, carvão, prata, solarita, madeira, matéria-prima, comida, camas, ânimo, saúde (couro e "pedra" não existem na economia: a pedra é o ferro) |
| Necessidades e status | fome, frio, cansaço, ferido leve, ferido grave (tala + muleta), greve, zanga (doença não existe no jogo) |
| Funções (9), equipamentos, ferramentas e armas | 9 funções + sem função + turno extra + construir; casaco, 3 trajes, 9 ferramentas/armas, arma quebrada, broca, lampião e robô **reaproveitados** da arte dos Prompts 3–5 (clareados pra ler no painel escuro) |
| Pesquisa (um por tecnologia) | os 11 |
| Alertas | invasão, onda solar, falta de comida, obra parada, reator |
| Prédios pro menu de construção | 15 renders reduzidos |
| Estações e velocidade | 4 estações; pausa/1x/2x/3x feitos por script |

## Geração que não serviu

12 dos 55 vieram errados (rosto de bicho no lugar de tigela, novelo no lugar de curativo, bonequinho
no lugar do arco...). Refiz 11 com descrição mais literal (11 gerações) e o caçador usa o arco do
Prompt 4.

## Mudanças por arquivo

| Arquivo | O quê |
|---|---|
| `scripts/ui/icones.gd` (novo) | `tex(nome, pequeno)`, `predio(nome)`, função e estação → ícone |
| `scripts/core/hud.gd` | ícones da barra de cima e da barra de funções, estação/onda solar, falta de comida, ícone nas faixas de aviso, controle de velocidade |
| `scripts/core/lab_panel.gd` | ícone por tecnologia |
| `scripts/core/build_menu.gd` | prédio pelo render reduzido |
| `scripts/iso/iso_billboard.gd` | ícones novos sobre a cabeça; "!" da criatura; obra parada |
| `prototipos/camera/arte_iso/ui/icones.py` | monta tudo (32/24/16 px, prédios, folha) |
| `assets/game/ui/icones/` | os ícones |
