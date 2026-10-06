# Bloco 89 — caminhos pintados

O pedido veio como "Bloco 58" (teste b58). O número já existe no histórico, então ficou **Bloco 89**, teste `b89`.

**Skills usadas:**
- `godot-gdscript`
- `godot-ui-control` (ferramenta e menu)
- `performance-optimization` (desenho só quando muda; sem rebuild de navegação)
- `save-systems`
- `godot-gdscript-headless-testing`

## Como funciona

- **Menu CONSTRUIR, aba Vila:** "Caminho: terra batida", "Caminho: cascalho", "Caminho: pedra" e "Apagar
  caminhos".
- **Pintar:** escolhendo um, o jogador **segura e arrasta** o botão esquerdo no mapa e pinta as células por
  onde o mouse passa, sem pular célula.
  - Cada célula é paga na hora.
  - Solta e pinta outro trecho; **Esc ou o botão direito** termina.
  - O aviso em cima mostra o custo por célula, quantas já foram e o motivo quando não dá (sem recurso, ou
    prédio embaixo).
- **Apagar:** do mesmo jeito, **sem devolver** o que custou.
- **Grade:** células de **20 px** do chão (`caminhos.tamanho`).

| Tipo | Custo por célula | Bônus de velocidade |
|---|---|---|
| Terra batida | 2 cr | +12% |
| Cascalho | 3 cr + 1 ferro | +20% |
| Pedra | 5 cr + 2 ferro | +30% |

Os valores ficam em `@export` no `caminhos.gd`: `custos` e `bonus`.

### Velocidade e a melhoria Trilhas

- **Quem anda sobre um caminho** ganha o bônus do tipo (`ipezinho._speed_bonus()`).
- **"Trilhas batidas"** (Centro da Vila) **não acelera mais todo mundo.** Agora aumenta o bônus dos caminhos em
  `trilhas_bonus_por_nivel` (+50% do bônus por nível). Com nível 2, a terra vai de +12% para +24%.
- O `speed_mult()` do Centro ficou 1.0 e o texto da melhoria foi atualizado.

### Navegação e prédios

- **Caminhos não bloqueiam a navegação nem pedem `rebuild_navigation`.** São só dados e desenho.
- **Prédio construído por cima apaga o trecho:** o `environment.clear_decor_under_extras()`, chamado em toda
  construção, chama `caminhos.remover_sob_predios()`.
- **Não dá pra pintar embaixo de prédio.**

### O passeio segue os caminhos

Quando o ipezinho troca de ponto social (Bloco 85), se há caminho pintado começando perto dele e chegando perto
do destino (até `rota_entrada`, 140 px), o passeio **segue o caminho**.

- A rota sai de uma busca em largura na grade dos caminhos (`caminhos.rota()`), com um waypoint a cada 3
  células.
- Sem caminho que sirva, usa o waypoint de antes: outro ponto social no meio.

### Desenho

- **Camada própria no chão da vista isométrica** (`iso_view._draw_caminhos`, abaixo das áreas de trabalho e dos
  personagens).
- **Refaz só quando os caminhos mudam** (`versao`), não a cada quadro.
- **Visual provisório:** cada célula é o losango do chão na cor do tipo; o cascalho tem pedrinhas, a pedra tem
  juntas, e a borda do trecho escurece. É só trocar `COR_CAMINHO` e o desenho por arte depois.

Foto: `docs/arte/bloco89/caminhos.png` (terra, cascalho e pedra perto do Centro).

## Save

- `caminhos` = `{tamanho, terra: [[x, y], ...], cascalho: [...], pedra: [...]}`, a lista de células por tipo.
- **Save antigo:** sem caminhos.

## Etapa futura (proposta, não implementada): rota preferencial na navegação

Hoje o caminho só **acelera** quem passa por ele. O Godot não faz o agente **escolher** o caminho de propósito,
e só o passeio social segue os caminhos.

**É viável no Godot 4:**
- `NavigationRegion2D` tem `travel_cost` e `enter_cost`.
- Dá pra ter uma **segunda região de navegação** só com os polígonos dos caminhos, com `travel_cost` < 1. O
  `NavigationServer2D` então prefere atravessar por ela.

**Custo:** essa região precisaria ser refeita ao pintar (com debounce, como o Bloco 90 vai fazer com a
decoração) e conectada à malha principal (`edge_connection_margin`).

**Proposta:**
1. Juntar as células em polígonos (retângulos por linha).
2. Fazer o bake só dessa região com debounce de ~1 s depois de parar de pintar.
3. `travel_cost` = 1 / (1 + bônus).

Fica como um próximo Bloco, se você quiser.

## Testes

- **`b89_caminhos.gd` (novo, passa):**
  - menu (aba Vila);
  - arrastar pinta 11 células sem pular, 2 cr cada;
  - **pintar não refaz a navegação**;
  - terra x1,12 e fora x1,00; Trilhas nível 2 x1,24, e o `speed_mult` global é 1;
  - pedra custa ferro e é a mais rápida (x1,30);
  - apagar sem devolução;
  - **parque construído por cima apaga o trecho**; não dá pra pintar embaixo de prédio;
  - **a rota segue o cascalho e o passeio social usa esses pontos**;
  - save com a lista por tipo, load e save antigo.
- **Passaram também:** `b71_s4_s5` (usa a velocidade) e `b85_hora_social` (passeio).
