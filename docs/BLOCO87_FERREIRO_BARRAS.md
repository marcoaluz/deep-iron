# Bloco 87 — o ferreiro e os custos em barras

O pedido veio como "Bloco 56" (teste b56). O número já existe no histórico, então ficou **Bloco 87**, teste `b87`.

**Skills usadas:**
- `godot-gdscript`
- `survival-crafting` (escada de progressão minério → barra)
- `godot-ui-control` (encomendas na janela da Oficina)
- `save-systems`
- `godot-gdscript-headless-testing`

## Levantamento: custos em minério bruto que viraram barras

O levantamento foi um grep nos campos de custo em minério de `defense.gd`, `barricada.gd`, `escavadeira.gd`,
`research.gd` e `centro_vila.gd`.

- **Ponto de partida:** **1 barra = 2 minérios**, arredondando pra cima. Fica em
  `Economy.minerios_por_barra` (`@export`).
- **Os campos continuam em minério,** como sempre. Um conversor único na Economia (`metal()`) pede **barras a
  partir do estágio da fornalha** e **minério bruto antes**, para não travar o começo.
- **Pra mudar um número:** basta trocar o campo de sempre ou o `minerios_por_barra`.

| O quê | Campo | Hoje (minério) | Com a fornalha (barras) |
|---|---|---|---|
| Lança de ferro | `defense.weapon_costs[1]` | 40 ferro | **20 barras de ferro** |
| Besta | `defense.weapon_costs[2]` | 40 cobre | **20 barras de cobre** |
| Lança de prata | `defense.weapon_costs[3]` | 60 prata | **30 barras de prata** |
| Consertar arma | `repair_cost` (fração do de cima) | proporcional | proporcional, em barras |
| Barricada nível 2 | `barricada.upgrade_costs[2]` | 120 ferro | **60 barras de ferro** |
| Barricada nível 3 | `barricada.upgrade_costs[3]` | 200 ferro | **100 barras de ferro** |
| Escavadeira: estrutura | `escavadeira.part_costs[0]` | 190 minério | **95 barras de ferro** |
| Escavadeira: motor | `part_costs[1]` | 310 | **155** |
| Escavadeira: hidráulica | `part_costs[2]` | 375 | **188** |
| Escavadeira: cabine | `part_costs[3]` | 250 | **125** |
| Escavadeira: broca | `part_costs[4]` | 625 | **313** |
| Reator diesel / solar / fusão | `escavadeira.reactor_costs` | 60 / 80 / 150 ferro | **30 / 40 / 75 barras** |
| Coletor de madeira (extra) | `centro_vila.coletor_ore` (× crescimento do Bloco 47) | 60 ferro | **30 barras** (o 2º: 45) |
| Coletor de minério | `centro_vila.coletor_min_ore` | 40 ferro | **20 barras** |
| Laboratório | `research.lab_iron` | 80 ferro | **40 barras de ferro** |

**Continuam só em minério bruto**, para não travar o começo:
- casas, cozinha, Centro da Vila e melhorias;
- Oficina, Vestiário, Arsenal (o prédio) e taverna;
- **a própria Fornalha**;
- a restauração do coletor em ruína (Bloco 81).

**Janelas e cartões** mostram o custo no formato novo ("150 cr + 20 barras de ferro + 20 madeira") e o que falta
("falta 20 barras de ferro"): Defesa (armas, consertos, barricadas), Escavadeira (peças e reatores), coletores
e laboratório.

## O ferreiro (função nova)

- **Na barra de funções:** botão **"Ferreiro"**, tecla **7**.
- **Opera a Oficina e o Arsenal.** Essas duas obras agora são **só do ferreiro**: a obra tem
  `oficio = "ferreiro"`, e o `_pick_obra` do ipezinho separa as obras de cada um. **O engenheiro fica só nas
  obras de construção.**
- **O que ele faz:**
  - **ferramentas** (Oficina);
  - **equipamentos** (casacos e trajes, a fila do Equipment);
  - **armas** (a fila da forja do Arsenal). **Fabricar e consertar** e o **desgaste** das armas continuam
    iguais: é a mesma fila, só mudou quem trabalha.
- **Pregos e ferragens** (novos, na Oficina), pelas **ordens de produção** do Bloco 86 (`production_queue.gd`),
  com as mesmas regras: só por ordem, quantidade do jogador, insumo pago quando a unidade começa, pausa se
  faltar, cancelar devolve. Produto vai pro armazém.
  - Pregos: 1 barra de ferro → 6 pregos (8 s).
  - Ferragem: 2 barras de ferro + 4 pregos → 1 ferragem (12 s).
  - Receitas em `oficina.receitas_ferreiro` (`@export`).
- **Janela da Oficina:** seção nova **"Encomendas do ferreiro"**, com quantidade (+/−), Encomendar, fila com
  progresso e Cancelar, e o aviso "PAUSADA: falta…".
- **Avisos:**
  - placa da Oficina e do Arsenal: "esperando ferreiro" / "forjando";
  - HUD: "FORJA: N encomendas esperando FERREIRO (tecla 7)";
  - ipezinho: "forjando: …".
- **Roupa provisória:** a do engenheiro com um **tom de aço** (azulado), também na vista isométrica.
- **Item novo no catálogo:** **ferragem** (peças), com ícone provisório.

## Save

- `oficina.gd` "encomendas": a fila de pregos e ferragens. Save antigo: nenhuma.
- O resto (forja, ferramentas, equipamento) já era salvo.
- Quem trabalha não vai pro save; é a função do ipezinho.

## Testes

- **`b87_ferreiro_barras.gd` (novo, passa):**
  - no estágio 1, minério;
  - no estágio da fornalha, barras (40 ferro → 20 barras; 35 cobre → 18): laboratório, coletores, lança e
    reator mostram barras;
  - prédios iniciais continuam em minério;
  - lança sem barra: "falta 20 barras de ferro";
  - **o engenheiro não forja** (Oficina parada, "esperando ferreiro"); **o ferreiro forja** a picareta;
  - pregos: 2 encomendas → exatamente 12 pregos com 2 barras;
  - ferragem sem barra: pausada, sem gastar;
  - Arsenal do ferreiro: forjar (paga em barras) + consertar → 2 lanças no cavalete;
  - barricada paga em barras;
  - coletor de minério pede barras;
  - save das encomendas.
- **Ajustados:**
  - quem fabricava com engenheiro passou a usar ferreiro: `b35` (forja), `b42` (casacos e trajes), `b31`
    (placa "esperando ferreiro");
  - quem estava no estágio 2 ganhou barras no estoque do teste: `b31`, `b31b`, `b32`, `b47`.
- **Passaram:** b87, b31, b31b, b32, b35, b39, b42, b44, b47, b57 e b58.
- **Não conferido:** `b51_engenheiro_estresse`, que é longo e ficou de fora por causa da memória.
