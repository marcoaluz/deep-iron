# Bloco 107 — Agricultor, estufa, carvoaria, curtume e cardápio (PLANO — espera aprovação)

Data: 2026-10-09. Branch `isometrico`. Pedido: "Prompt W2". Teste futuro: `b107_agricultor_oficinas`.

**Nada foi implementado.** Este documento é só o plano e a tabela de custos e receitas. Os números marcados *(calculado)*
saem de contas sobre valores que já existem no código; **vou medir tudo na etapa B**, como nos Blocos 105 e 106.

## 1) O que já existe (conferido no código, não na documentação)

| Assunto | Hoje |
|---|---|
| **A horta** (`food_source.gd`) | 150 de comida, regenera 0,35/s e colhe 3/s. A estação multiplica: primavera 1,3 · verão 1,0 · outono 0,8 · **inverno 0,5** (`sun.season_garden_mult`). |
| **Quem colhe a horta** | **Só o caçador** (`coleta_comida`, estados `foraging`). O cozinheiro **não** colhe: ele busca no armazém e prepara. O prompt fala "cozinheiro e caçador"; o código diz só o caçador. |
| **A cozinha** (`comedouro.gd`) | Cada refeição serve UMA porção de 8 unidades (`Schedule.porcao`) que enche 45 de fome (`refeicao_fome`). O cozinheiro leva 12 de matéria-prima por leva e prepara. |
| **A ração das expedições** (`expedicoes.gd`) | Hoje tira comida PRONTA do estoque da cozinha na hora da partida: 2 porções por pessoa por dia (`racao_porcoes_dia`). Sem ração, o risco dobra. |
| **O couro** | O caçador traz 0,5 por unidade de caça (`leather_per_game`). Vai pro compartimento "manufaturados". Gasta: casaco 3, botas 2 + 4 pregos, mochila 3 + 2 pregos, trajes 1/2/2. |
| **O carvão** | Só mineral (minério `carvao`). A Fornalha pede 1 por barra de ferro/cobre e por aço. Com a mineração mais lenta (Bloco 106), o combustível ficou escasso. |
| **Oficinas de ordens** | O padrão é `fornalha.gd` (herdado pela `carpintaria.gd`): fila de encomendas, operador por função, insumo levado pelo carregador (Bloco 105). |

## 2) A proposta

### 2.1 Agricultor e agricultora (função nova, tecla `-`)
- **Função nova** (`ROLE_FARMER`), com os dois gêneros e a receita do elenco (regra 11): colhe a horta aberta e a estufa.
- **A decisão que muda o jogo atual:** quando a vila tem agricultor, **a horta é dele** e o caçador só caça. **Sem agricultor, o
  caçador continua colhendo**, como hoje (o mesmo fallback do carregador): ninguém passa fome por falta de função.
- **O cuidado:** a horta aberta com um agricultor designado regenera × `cuidado_mult` = **1,25**. Isso paga a função.
- Aparece na barra, em PRODUÇÃO. Entra nas áreas de trabalho de alimentos (a área "alimentos" hoje põe caçador).

### 2.2 Estufa (estrutura nova)
- **Horta coberta.** O agricultor colhe nela do mesmo jeito (estação com slots, `food_source.gd` com `estufa = true`).
- **Rende mais no inverno que a horta aberta**, e menos no resto do ano (senão ninguém usaria a horta):

  | Estação | Horta aberta (0,35 × estação) | Estufa (0,30 × `season_estufa_mult`) |
  |---|---|---|
  | Primavera | 0,455/s | 0,24/s (0,8) |
  | Verão | 0,35/s | 0,24/s (0,8) |
  | Outono | 0,28/s | 0,27/s (0,9) |
  | **Inverno** | **0,175/s** | **0,30/s (1,0)** *(+71%)* |

  *(calculado, em comida por segundo real; um dia de jogo = 540 s)*
- **Sem aquecimento nem combustível** nesta versão (não está no prompt). Fica como ideia: carvão vegetal esquentando a estufa.
- Até 2 estufas; a 2ª custa ×1,5 (`extra_building_cost_growth`, como as outras construções repetíveis).

### 2.3 Carvoaria (estrutura nova, operada pelo lenhador)
- **Por ordem do jogador** (regra 9), na fila de produção, só anda com o lenhador. É uma oficina de ordens: herda de `fornalha.gd`.
- **O item novo "carvão vegetal"** (`carvao_vegetal`), combustível alternativo da Fornalha.
- **Na Fornalha, "carvão" passa a aceitar os dois**, gastando **o vegetal primeiro** (o que o jogador mandou fazer), e o mineral
  quando acaba. O mesmo padrão de "barra no lugar de ferro" (`itens_efetivos`).
- O carregador leva a madeira (e o carvão pronto) como as outras oficinas.

### 2.4 Curtume (estrutura nova, operada pelo caçador)
- **Por ordem**, só anda com o caçador. Mesma base de oficina de ordens.
- **O item novo "couro curtido"** (`couro_curtido`).
- **A ligação com os usos do couro:** **com um curtume na vila, botas, mochila e trajes passam a pedir couro curtido** no lugar do
  cru, com os mesmos números. **Sem curtume, continuam pedindo cru, como hoje** (o mesmo fallback das barras antes da fornalha).
  O casaco fica no couro cru (é a peça simples). Nada trava a progressão e os saves antigos continuam iguais.

### 2.5 Cardápio do cozinheiro (na janela da cozinha)
O jogador escolhe o **prato da semana** (a escolha vale até ele mudar; no domingo sai um aviso pedindo pra revisar).

| Prato | Porção servida | Fome que enche | Ânimo | Preparo |
|---|---|---|---|---|
| **Refeição comum** (padrão: o de hoje) | 8 | 45 | 0 | 1× |
| **Ensopado** | **12** *(×1,5: gasta mais comida)* | **56** *(×1,25: rende menos por unidade)* | **+2 por refeição** *(via `morale.gd`)* | 1,3× |
| **Ração de expedição** | **ordem de N rações** (quantidade na janela) | — | — | 40 s por ração |

- **A ração é uma ORDEM, não um prato da semana.** Se ela substituísse o prato de verdade, a vila passaria fome. Então: o jogador
  pede N rações, o cozinheiro faz (16 de comida crua cada = 1 pessoa por 1 dia, o mesmo que as expedições gastam hoje) e a cozinha
  **volta sozinha ao prato anterior**. As rações ficam no armazém (compartimento alimentos).
- **O Prompt E passa a gastar a ração pronta primeiro**; sem ração em estoque, cai no comportamento de hoje (comida da cozinha).
  O risco "sem ração" (×2) continua igual.
- Teto: o cozinheiro só faz ração se a cozinha tiver comida mínima de reserva (`racao_reserva_minima`), pra não esvaziar a vila.

## 3) A tabela de custos e receitas

Todos os números ficam em `@export` com comentário e entram no `docs/BALANCEAMENTO.md`.

### Estruturas (cada uma em obra por etapas 1 → 2 → 3 → pronto; o engenheiro constrói, o carregador leva o material)
| Estrutura | Estágio da vila | Créditos | Ferro* | Madeira | Pregos* | Segundos de engenheiro |
|---|---|---|---|---|---|---|
| **Estufa** | 2 | 220 | 50 | 90 | 20 | 60 |
| **Carvoaria** | 2 | 150 | 30 | 60 | — | 35 |
| **Curtume** | 2 | 160 | 40 | 60 | 15 | 40 |

\* O ferro e os pregos viram barras a partir do estágio da fornalha (`Economy.custo_metal_texto`), como no resto do jogo.

### Receitas (por ordem do jogador)
| Onde | Receita | Insumo | Produto | Segundos de operador por unidade |
|---|---|---|---|---|
| **Carvoaria** (lenhador) | Carvão vegetal | 3 madeira | 1 carvão vegetal | 15 |
| **Curtume** (caçador) | Couro curtido | 1 couro + 2 madeira | 1 couro curtido | 20 |
| **Cozinha** (cozinheiro) | Ração de expedição | 16 comida crua | 1 ração | 40 |

- Lote por viagem, fila máxima e ritmo: os mesmos `max_fila = 4` e `lote = 2` da Fornalha.
- **Preços de venda:** carvão vegetal e couro curtido **não vendem** (são insumo, como a madeira e o couro).

### Itens novos (`items.gd`)
| Item | Categoria | Onde guarda | Compartimento (Bloco 106) |
|---|---|---|---|
| `carvao_vegetal` | combustível | `itens` | **madeira** (350 no nível 1: tem folga) |
| `couro_curtido` | peças | `itens` | manufaturados (100 no nível 1) |
| `racao` | comida | `itens` | alimentos (150 no nível 1) |

## 4) Arte (PixelLab, regra 11) — em etapas, um por vez

| Item | O que é | Estimativa |
|---|---|---|
| **Agricultor e agricultora** | personagens completos (receita do elenco: candidatos, v3, caminhada, comer/ferido/deitar/mancar, o trabalho "colher", casaco, retrato com 5 expressões) | ~78 cada = **~156** |
| **Estufa, Carvoaria, Curtume** | estrutura nova: evolução da obra (obra 1 → 2 → 3 → pronto), guia 2:1 | ~80 cada = **~240** |
| **Animações de trabalho novas** (carvoejar, curtir) pro lenhador/lenhadora e pro caçador/caçadora | v3, 8 quadros, e a versão de casaco | ~32 por pessoa = **~128** *(ver decisão 5)* |
| **Ícones** (agricultor, estufa, carvão vegetal, couro curtido, ração, os 3 cartões) | 32 px; os cartões reaproveitam o prédio pronto reduzido (regra 12) | **~30** |
| **Total previsto** | | **~554 gerações** |

- **Piloto antes do lote:** gero **só o agricultor (homem) completo**, mostro e espero a aprovação, como no carregador (W1). Depois a
  agricultora, depois uma estrutura-piloto, depois o resto.
- **Saldo hoje:** 6.063 (confirmado). Ainda esperam sua aprovação os ~290–310 do Bloco 105. Os dois somam ~860 e ficam folgados.
- Estas estimativas vêm do custo real do piloto do carregador (78) e do armazém nível 2/3 (80); **é estimativa, não gasto**.

## 5) Código, save, telemetria e teste

**Arquivos novos:** `scripts/props/estufa.gd` (a horta coberta), `carvoaria.gd` e `curtume.gd` (oficinas de ordens, herdam
de `fornalha.gd`) e os painéis delas (herdam de `fornalha_panel.gd`).

**Alterados (previsão):**
- `ipezinho.gd` (a função, os estados, o fallback do caçador);
- `food_source.gd` (estufa e cuidado);
- `comedouro.gd` + `comedouro_panel` (o cardápio);
- `schedule.gd` (a porção do ensopado);
- `items.gd`;
- `fornalha.gd` / `economy.gd` (o carvão que aceita os dois);
- `equipment.gd` (o couro curtido);
- `expedicoes.gd` (a ração);
- `logistica.gd` (as entregas das oficinas novas);
- `centro_vila.gd` + `canteiro.gd` (as construções);
- `build_menu.gd` (3 cartões com imagem);
- `hud.gd`, `teclas.gd`, `main.gd`;
- `telemetria.gd`, `missoes.gd`, `save_manager.gd`.

**Save (cabeçalho do `save_manager.gd`):**
- as 3 estruturas (posição, etapa, fila);
- o prato e a fila de ração da cozinha;
- a função `agricultor`.
- **Save antigo:** sem as estruturas, prato comum, ninguém agricultor (o caçador continua colhendo), receitas de couro como hoje.

**Telemetria (CSV):** estufa e horta colhidas por dia, carvão vegetal e couro curtido feitos, prato da semana, rações em estoque.

**Teste `b107_agricultor_oficinas`:**
- o agricultor colhe e o caçador só caça (com agricultor), e o fallback (sem agricultor);
- a estufa rende mais no inverno e menos no verão;
- as 3 obras por etapas (material levado pelo carregador) e as ordens (nada automático);
- o carvão vegetal na Fornalha (vegetal primeiro), o couro curtido nas 3 receitas (com e sem curtume);
- o cardápio (ensopado: porção, fome, ânimo) e a ração (volta sozinha ao prato; a expedição gasta a ração);
- o save e o save antigo.

Rodo também os testes de obras, entregas, produção, agenda, expedições, equipamento e o `b106` (o armazém por compartimento).

## 6) Decisões pra você

1. **A horta passa pro agricultor** (o caçador só caça; **sem agricultor, o caçador colhe**). Pode?
   *(Corrijo o prompt: hoje só o caçador colhe, não o cozinheiro.)*
2. **O carvão vegetal vale como o mineral na Fornalha, gastando o vegetal primeiro**, e fica no compartimento "madeira". Pode?
3. **O couro curtido substitui o cru em botas, mochila e trajes quando há um curtume na vila** (sem curtume, cru como hoje). O casaco
   fica cru. Pode?
4. **O cardápio:** ensopado com porção ×1,5, fome ×1,25, ânimo +2 por refeição; e a **ração como ORDEM que volta sozinha ao prato
   anterior** (em vez de prato da semana). Os números servem?
5. **As animações de trabalho de quem opera as oficinas** (lenhador na carvoaria, caçador no curtume): geramos animações novas
   (~128 gerações) **ou** reaproveitamos as que existem (cortar madeira e a colheita)? Eu recomendo gerar, pela regra 11.
6. **A tecla do agricultor:** as letras acabaram; proponho a tecla física **`-`** (`KEY_MINUS`). Valido no seu teclado ABNT2 antes
   de fechar (e dá pra remapear).

**Fora do escopo (só se você pedir):** aquecer a estufa com carvão, "pedra" como recurso, o Prompt R (habilidades).
