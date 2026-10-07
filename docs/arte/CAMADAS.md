# Camadas de desenho (Bloco 69)

A vista isométrica (`scripts/iso/iso_view.gd`) desenha o mundo em 5 camadas, de trás pra frente. Dentro do
mundo a ordem é o `z_index` (absoluto, `z_as_relative = false`); as faixas abaixo são as que o código usa.
`Order.BASE = -4000` (`scripts/iso/iso_order.gd`): as coisas ordenadas pelas caixas recebem
`BASE + rank × 8`.

| camada | o quê | onde / z |
|---|---|---|
| **0 — fundo e céu** | céu e nuvens (CanvasLayer −3), montanhas e serra (`BASE − 90/−80`), moldura de morros (`BASE − 60`, pedaços `moldura_lN`), fundo da pedreira (`BASE − 50`, pedaços `fundo_lN`), trilho do vagonete (`BASE − 45`) | `iso_sky.gd`, `iso_view._build_terrain`, `_sync_trilhos` |
| **1 — terreno** | terraços, paredão, escadas/rampas, lajes dos andares de baixo | caixas na ordem (`_terrain`), `BASE + rank×8` |
| **2 — detalhes** | prédios, árvores, rochas, cristais, jazidas, tocas, decoração (`Deco_*`, `nivel_deco`) | caixas na ordem (fixas): mesma faixa do terreno, ordenadas entre si pela caixa |
| **3 — dinâmicos** | ipezinhos, criaturas, robô, bichos, vagonete | `Order.dynamic_z` (o espaço de cada um entre as fixas) |
| **4 — efeitos e luz** | atmosfera dos níveis (`3700`), névoa do leste (`3800`), ar do calor (`4000`), clima (`4080`), marcador/fantasma (`4090`); onda solar (CanvasLayer 1); luzes 2D (`PointLight2D`, máscara `LIGHT_ISO`) e a luz ambiente (`CanvasModulate` do dia/noite) | `iso_view`, `iso_fx`, `iso_sky`, `day_night` |

Composição A→D da referência: **A base** = camadas 0–1, **B detalhes** = 2, **C ativos** = 3, **D efeitos** = 4.

## Regras

- Nada novo usa `z_index` relativo dentro do mundo iso: ou entra na ordem por caixa (terreno, detalhes,
  dinâmicos), ou recebe um z fixo de uma faixa acima.
- Efeito que cobre a tela (névoa, atmosfera, clima) fica na camada 4 e respeita **Reduzir efeitos**
  (`scripts/core/efeitos.gd`) e, se for de nível, a **Atmosfera dos níveis** (Configurações).
- Luzes: cada luz nova entra no grupo `cullable_lights` (o ambiente apaga as fora da tela) e usa
  `range_item_cull_mask = LIGHT_ISO`. Luz que a vista põe **direto na tela iso** (filha do `Terreno`,
  posição já em `to_screen`: lava, brilho das zonas) leva `set_meta("tela_iso", true)` — sem isso o
  corte converte a posição de novo e apaga a luz no lugar errado.

## Atmosfera por nível (dados)

Cada nível (`data/niveis/*.tres`, `scripts/core/nivel_mina.gd`) declara `cor_ambiente` (tom da laje do
andar), `cor_nevoa` (névoa por cima, camada 4), `particulas` (`poeira`, `acido`, `calor`, `gotas`,
`bolhas`) e `decoracao` (`[prop, x, y]` na lógica: o ambiente põe esses props quando o nível existe).
As zonas de perigo do nível ganham luz pulsando (calor laranja, gás verde, radiação ciano).
Mudar a atmosfera de um nível = editar o `.tres`.

Custo medido (`tools/bench_cena.ps1 -Rapido`, vila cheia, cenário C): atmosfera ligada 19,9 ms / 50 FPS,
desligada 19,1 ms / 52 FPS (~0,8 ms; `docs/bench/bench_2026-10-02_bloco69_*.txt`). Fotos de conferência:
`tests/capturas_atmosfera.gd` (S1, S2, S3, reduzido, sem atmosfera, de longe).
