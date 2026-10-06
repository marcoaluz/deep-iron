# Bloco 82 — catálogo de itens e a janela do armazém em grade

O pedido veio como "Bloco 51" (teste b51). O número já existe no histórico, então ficou **Bloco 82**, teste `b82`.

**Skills usadas:**
- `godot-gdscript`
- `godot-ui-control` (a grade)
- `save-systems`
- `survival-crafting` (itens e receitas como dados)
- `create-game-assets` (ícones provisórios)
- `godot-gdscript-headless-testing`

## Investigação: como os armazéns guardam (Bloco 47)

- **Cada Armazém tem o próprio estoque:**
  - `stock` (minério bruto, uma chave por tipo do `ores.gd`);
  - colunas separadas para madeira (`wood_stored`), matéria-prima (`raw_stored`) e couro (`leather_stored`).
- **As peças raras** são um número só da vila, em `Finds.rare_parts`.
- **A Economia** soma todos os armazéns do grupo "armazens" para mostrar, vender e gastar. Gastar tira de um
  armazém atrás do outro.

**O risco de pôr os itens novos no `stock`:**
- a soma do `stock` (`total_stored`) é tratada como "minério" em vários lugares: a pilha, os marcos da vila, o
  `stored_ore("")` dos custos em "minério qualquer" e o `sell_all`;
- o load do armazém só lê as chaves de minério, então as barras sumiriam ao carregar.

## O plano escolhido (o menos arriscado)

- **Um dicionário novo `itens` em cada armazém** (id → quantidade), só para os itens **processados**: barras,
  aço, lingote, prego e os que vierem da Fornalha e do Ferreiro.
  - O `stock` de minério **não mudou**.
  - Chave nova `itens` no save do armazém. Save antigo: vazio.
- **O catálogo `scripts/core/items.gd`** diz onde cada item mora: `stock`, `madeira`, `materia_prima`, `couro`,
  `pecas_raras` ou `itens`. O código que mostra ou vende não precisa saber os detalhes.
- **A Economia ganhou funções genéricas:**
  - `quantidade(id)`: qualquer item, somando os armazéns;
  - `add_item(id, n, perto)`: guarda no armazém mais perto (a Fornalha vai usar);
  - `take_item(id, n)`: tira de todos os armazéns;
  - `sell(id)`: agora vende minério **ou** processado;
  - `sell_categoria(cat)`;
  - `pode_vender(id)` e `valor_de(id)`.
  - **"Vender tudo" continua sendo só o minério**, para não vender sem querer as barras que as obras vão pedir.

## O catálogo (`items.gd`)

Cada item tem `nome`, `cat`, `icone`, `preco` (base) e `onde`.

| Categoria | Itens |
|---|---|
| Minério | ferro, carvão, cobre, prata, cristal verde, solarita, cristal rubro, gema azul |
| Metal | barra de ferro (8 cr), barra de cobre (13), aço (18), barra de prata (20), lingote solar (36) |
| Madeira | madeira (não se vende) |
| Comida | comida crua: fruta e caça (não se vende) |
| Peças e materiais | prego (1 cr), couro e peças raras (não se vendem) |
| Equipamento | vazia por enquanto: entra com o Ferreiro (Bloco 87) |

- **Preço dos minérios:** continua nos `@export` da Economia, como antes.
- **Preço dos outros:** troca no `@export precos_itens` da Economia, por exemplo `{"barra_ferro": 10}`.
  Vazio usa o preço base do catálogo; 0 = não se vende.
- **Preço de partida das barras:** cerca de 2 minérios mais o carvão, com um pouco de lucro por processar.
  Assim vale mais a pena fundir do que vender o minério bruto.

## Ícones provisórios

`prototipos/camera/arte_iso/ui/icones_itens.py` gera `assets/game/ui/icones/it_<id>.png` (32 px):
- as barras (ferro, cobre, aço, prata, lingote solar com brilho);
- prego, couro e peças raras (engrenagem e parafuso);
- os cristais e a gema, a partir dos pedaços de minério do jogo.

Para trocar por arte de verdade, basta gravar outro PNG com o mesmo nome.

## A janela do armazém

Foto: `docs/arte/bloco82/janela_armazem.png`.

- **Grade de 4 colunas por categoria**, com rolagem. Cada célula mostra:
  - ícone e quantidade;
  - nome;
  - preço ("x cr cada (= total)") ou "não se vende";
  - botão Vender.
- **Quantidade zero fica esmaecida** e com o Vender desligado.
- **O título da categoria tem o "vender a categoria"**. No minério, é o "Vender tudo" de sempre.
- **Os números somam todos os armazéns.**
- **Minério ainda travado pela Oficina e sem estoque fica escondido**, como antes.

## Testes

- **`b82_itens_armazem.gd` (novo, passa).** Confere:
  - o catálogo completo, com ícone para todo item;
  - processados guardados fora do `stock`, divididos em dois armazéns e somados;
  - barra não conta como minério;
  - tirar de vários armazéns;
  - `quantidade()` de madeira, comida, couro, peças raras e minério;
  - a grade: célula por item, seções, zero esmaecido, madeira sem Vender, botões;
  - vender por tipo e por categoria;
  - "Vender tudo" só minério;
  - preço trocado;
  - save e save antigo sem `itens`.
- **Passaram também:** `b39_economia` (usa `_rows["ferro"].label` e `_sell_all` da janela), `b42_equipamento` (couro) e `b27_cacador_cozinheiro` (matéria-prima).
