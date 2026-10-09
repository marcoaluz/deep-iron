# Bloco 107 — Agricultor, estufa, carvoaria, curtume e cardápio

Data: 2026-10-09. Branch `isometrico`. Teste: `b107_agricultor_oficinas`. Pedido: o "Prompt W2". O plano e a tabela de custos estão em
`docs/BLOCO107_PLANO.md` (aprovado pelo Marco com as respostas abaixo).

**As decisões do Marco:**
- a horta passa pro agricultor, e o caçador só colhe se não houver um;
- **a horta e a estufa são construídas dentro da vila**, e a estufa libera no estágio 2 da vila;
- o carvão vegetal vale como o mineral na Fornalha (o vegetal primeiro) e fica no compartimento "madeira";
- o couro curtido substitui o cru em botas, mochila e trajes quando há curtume;
- os números do ensopado servem, e a ração é uma ordem que volta ao prato anterior;
- as animações de trabalho do lenhador e do caçador nas oficinas novas: gerar novas;
- a tecla do agricultor: `-`;
- **a estufa é uma construção de vidro de verdade** (pedido no meio do trabalho).

**Skills usadas:** `godot-gdscript`, `godot-ui-control`, `ai-behavior-trees-utility-ai` (o operador único, o fallback do caçador),
`survival-crafting` (carvão, couro, ração, a estação), `save-systems`, `godot-gdscript-headless-testing`, `deep-iron-arte`.

## 1) Como ficou

### Horta e estufa (dentro da vila)
- **A horta virou construção do jogador** (menu CONSTRUIR, aba Alimentação): 60 cr + 30 madeira, estágio 1, 20 s de engenheiro.
  Podem ser até 3 (as próximas custam ×1,5).
  - **Partida nova:** a horta da clareira sai, e o pacote da Fundação paga uma horta (400 → 460 cr, 80 → 110 madeira).
  - **Save antigo, sem a chave nova:** a horta da clareira continua onde estava, e nada some.
  - **Save novo:** a horta construída volta no lugar dela.
- **A estufa:** 220 cr + 50 ferro (barras a partir da fornalha) + 90 madeira + 20 pregos, estágio 2, 60 s de engenheiro. Até 2.
  - **As estações** (`sun.season_estufa_mult` = 0,8 · 0,8 · 0,9 · 1,0; a estufa regenera 0,30/s):

    | | Horta aberta | Estufa |
    |---|---|---|
    | Primavera | 0,455/s | 0,24/s |
    | Verão | 0,35/s | 0,24/s |
    | Outono | 0,28/s | 0,27/s |
    | Inverno | 0,175/s | **0,30/s** (+71%) |

  - A Hidroponia (o dobro da regeneração) vale pra todas as fontes de comida, estufa incluída.
- **O agricultor / a agricultora** (tecla `-`, em PRODUÇÃO): colhe a horta e a estufa e leva a fruta pro armazém.
  - Cuida da horta aberta: regenera ×1,25 (`cuidado_mult`).
  - **Com agricultor na vila o caçador só caça. Sem agricultor, o caçador colhe como sempre.**
  - O agricultor colhe mesmo que a horta esteja dentro de uma área de alimentos (as áreas continuam sendo do caçador).

### Carvoaria (lenhador) e Curtume (caçador)
- São oficinas de ordens (herdam da Fornalha), em obra por etapas, com o material levado pelo carregador.

  | | Custo | Estágio | Receita (por ordem) |
  |---|---|---|---|
  | Carvoaria | 150 cr + 30 ferro + 60 madeira, 35 s | 2 | 3 madeira → 1 carvão vegetal (15 s) |
  | Curtume | 160 cr + 40 ferro + 60 madeira + 15 pregos, 40 s | 2 | 1 couro + 2 madeira → 1 couro curtido (20 s) |

- **Nada é automático** (regra 9): sem ordem, o lenhador corta e o caçador caça.
- Com ordem, **UM** lenhador (ou caçador) deixa o trabalho, busca os insumos (ou o carregador traz), opera e leva o produto pro
  armazém. Os outros continuam no trabalho deles.
- **O carvão vegetal vale como o mineral** em todas as receitas da Fornalha, gastando o vegetal primeiro
  (`Items.EQUIVALENTES`, na fila de produção).
- **Com um curtume na vila**, botas, mochila e trajes pedem **couro curtido** no lugar do cru, com os mesmos números. Sem curtume,
  pedem o cru, como hoje. O casaco fica no cru.
  - A receita da mochila (Oficina) ganhou `"curtido": true`.
  - Em `equipment.gd`: `couro_de(id)`.

### O cardápio (clique na cozinha)
- **Prato da semana:**

  | | Refeição comum | Ensopado |
  |---|---|---|
  | Porção servida | 8 | **12** (×1,5) |
  | Fome que enche | 45 | **56** (×1,25) |
  | Ânimo por refeição | — | **+2** (até +6, some devagar) |
  | Preparo do cozinheiro | 1× | **1,3×** |

  O ânimo entra na lista de motivos do ipezinho ("comeu um ensopado").
- **Ração de expedição = ORDEM:** o jogador pede N rações (até 30); o cozinheiro prepara (16 de comida crua e ~40 s cada), elas
  viram o item `racao` no armazém e **a cozinha volta sozinha ao prato de antes**.
  - Só faz ração com pelo menos 40 de comida pronta na cozinha (reserva).
  - **As expedições gastam as rações prontas primeiro**, e o que sobra sai da comida da cozinha, como antes.
- No domingo, aparece o aviso "revise o cardápio da semana".

## 2) Arte (PixelLab, regra 11) — piloto do agricultor, esperando sua aprovação

- **O agricultor (homem) está completo:**
  - 16 candidatos, e o **c10** escolhido (a cesta de vime no quadril);
  - personagem v3 "high top-down";
  - caminhada de 8 quadros, comer, ferido, deitar e mancar;
  - o trabalho "colher" (8 quadros);
  - o casaco de inverno (caminhada + colher);
  - o retrato com as 5 expressões.
- **Conferência:**
  - `docs/arte/bloco107/agricultor_piloto.png` (as 8 poses, o casaco, o retrato);
  - `agricultor_trabalho.png` e os GIFs `agricultor_*_4dir.gif`.
- **Dois defeitos que vi:**
  1. No trabalho, o modelo desenhou **brotos e um cogumelo no chão** (a descrição pedia sem plantas). Dá pra refazer só a animação (~16
     gerações) ou deixar: com a cesta na mão, o desenho se explica.
  2. **Vista de costas (NE) do "colher":** o rosto e o chapéu escurecem nos quadros do meio (a cabeça vira uma mancha preta). Pede refazer
     essa animação.
- **O que NÃO foi feito ainda (esperam sua aprovação):**
  - a agricultora;
  - a estufa de vidro (com a obra 1 → 2 → 3 → pronto);
  - a carvoaria e o curtume;
  - as animações novas do lenhador e do caçador;
  - os ícones;
  - a integração no jogo (`integra.py bonecos agricultor`).
- **Provisórios até lá:**
  - o agricultor usa a roupa de civil na vista isométrica (`iso_bonecos.PROVISORIO`);
  - a carvoaria usa o desenho da fornalha e o curtume o da carpintaria;
  - a horta e a estufa usam o desenho da horta;
  - o ícone da barra é a cesta do jogo;
  - os itens novos usam ícones que já existem;
  - os cartões do menu usam o desenho dos prédios parecidos (a horta e a estufa têm um cartão de 96×64 feito do desenho da horta).

### Orçamento do PixelLab
| | Gerações | Tipo |
|---|---|---|
| Saldo no começo do bloco | 6.063 | confirmado |
| Gasto neste bloco (o agricultor completo) | 78 | real |
| Saldo agora | **5.985** | confirmado |
| A agricultora | ~78 | estimado |
| Estufa de vidro, carvoaria e curtume (obra 1 → 2 → 3 → pronto, ~80 cada) | ~240 | estimado |
| Animações de trabalho novas (lenhador/a e caçador/a) | ~128 | estimado |
| A ruína do vagonete (pedida pelo Marco no Bloco 106) | ~80 | estimado |
| Ícones (agricultor, estufa, 3 itens, cartões) | ~30 | estimado |
| Refazer o "colher" de costas (opcional) | ~16 | estimado |
| **Total previsto pro resto** | **~570** → saldo ~5.400 | estimado |

## 3) Os arquivos

- **Novos:**
  - `props/carvoaria.gd`, `props/curtume.gd` e as cenas `carvoaria.tscn`, `curtume.tscn`, `estufa.tscn`;
  - `core/carvoaria_panel.gd`, `core/curtume_panel.gd`, `core/cozinha_panel.gd`;
  - `tests/blocos/b107_agricultor_oficinas.gd`;
  - `prototipos/camera/arte_iso/oficios107.py`;
  - 2 cartões em `assets/game/ui/icones/predios/` (horta, estufa).
- **Alterados:**
  - **A IA:** `ipezinho.gd` (a função, o operador único, o fallback do caçador, o ânimo do prato, `_grupo_oficina`).
  - **Comida e cozinha:** `food_source.gd` (estufa, cuidado, `regen_por_segundo`), `comedouro.gd` (o cardápio e a ração),
    `sun.gd` (`season_estufa_mult`), `expedicoes.gd` (a ração pronta), `expedicoes_panel.gd`.
  - **Oficinas e itens:** `fornalha.gd` (`produzido`), `production_queue.gd` (carvão e couro curtido), `equipment.gd`, `oficina.gd`,
    `items.gd`, `armazem.gd` (as barras de oficina nova no compartimento certo).
  - **Construção:** `centro_vila.gd` (as 4 construções), `canteiro.gd`, `build_menu.gd`, `founding.gd`.
  - **Interface e teclas:** `hud.gd`, `teclas.gd`, `main.gd`, `icones.gd`, `iso_bonecos.gd`, `iso_art.gd`.
  - **Mapa e áreas:** `work_areas.gd`, `logistica.gd`, `environment.gd`, `caminhos.gd`.
  - **Dados:** `telemetria.gd`, `save_manager.gd` (o cabeçalho).

## 4) Os @export novos

| Onde | Parâmetro | Valor |
|---|---|---|
| `centro_vila.gd` | `horta_*` / `estufa_*` / `carvoaria_*` / `curtume_*` (créditos, ferro, madeira, pregos, segundos, estágio, máximo) | a tabela da seção 1 |
| `centro_vila.gd` | `founding_credits` / `founding_wood` | 460 (era 400) / 110 (era 80): paga a horta |
| `sun.gd` | `season_estufa_mult` | 0,8 · 0,8 · 0,9 · 1,0 |
| `food_source.gd` | `cuidado_mult` / `estufa` | 1,25 / falso (a estufa liga) |
| `comedouro.gd` | `ensopado_porcao_mult`, `ensopado_fome_mult`, `ensopado_animo`, `ensopado_animo_max`, `ensopado_preparo_mult` | 1,5 · 1,25 · 2 · 6 · 1,3 |
| `comedouro.gd` | `racao_cru`, `racao_preparo_mult`, `racao_reserva_minima`, `racao_max_pedido` | 16 · 3,1 · 40 · 30 |
| `ipezinho.gd` | `animo_prato_decai` | 0,01 /s |
| `carvoaria.gd` / `curtume.gd` | as receitas | a tabela da seção 1 |

## 5) Save

As chaves estão no cabeçalho do `save_manager.gd`.
- **Chaves novas:**
  - `centro_vila` com "hortas", "carvoarias" e "curtumes";
  - o comedouro com "prato", "racao_pedida" e "racao_acc";
  - a horta com "total_colhido";
  - a oficina com "produzido";
  - o ipezinho com "animo_prato".
- **Save antigo:**
  - sem estruturas novas;
  - a horta da clareira continua;
  - prato comum;
  - botas, mochila e trajes pedem couro cru;
  - ninguém é agricultor, então o caçador continua colhendo.

## 6) Telemetria

O CSV ganhou `hortas`, `estufas`, `colhido_horta`, `colhido_estufa`, `carvao_vegetal_feito`, `couro_curtido_feito`, `prato` e `racoes`.

## 7) Testes

- **`b107_agricultor_oficinas`** (novo): **0 falhas**. Confere:
  - os itens e os compartimentos;
  - o vegetal gasto antes do mineral;
  - a horta e a estufa (estágio, custo, obra com material, o máximo, a estação);
  - o agricultor, o fallback do caçador e o cuidado ×1,25;
  - a carvoaria e o curtume (um operador por vez, nada automático);
  - o couro curtido nas 3 receitas, com e sem curtume;
  - o cardápio, a ração e a expedição;
  - a tecla `-` e a barra;
  - o save e o save antigo.
- **A bateria completa:** ver a seção 8.

## 8) A bateria

Rodou um teste por vez, com a pasta `fake_appdata`: **os 89 testes de bloco** (b100–b106 e todos os antigos) **+ o b107**.
- **87 passaram de primeira.**
- **2 eram intermitentes e passaram ao repetir sozinhos:** `b101_migrantes` (os migrantes pela floresta) e `b77_areas` (a medição de
  madeira de 30 s oscila). Os dois já constavam como intermitentes nos relatórios anteriores.
- Nenhum teste antigo precisou de ajuste neste bloco (a horta da cena continua nos testes, que abrem o jogo sem a Fundação).
- **GUT `test_iso*`:** 12 de 12.

## 9) Pendências e riscos

- **A arte da estufa de vidro e da ruína do vagonete** esperam a aprovação do piloto.
- **A quem a área de alimentos serve:** ela continua dando a função caçador. Se o jogador quiser áreas de horta pro agricultor, é um
  tipo novo em `work_areas.TIPOS`. Não fiz.
- **O recibo de encomenda vale só no quadro do pagamento** (Bloco 96). Se uma unidade da Fornalha começa no MESMO quadro em que o jogador
  encomenda uma obra, os insumos dela entram na lista da obra. Já existia; a chance é minúscula. Anotado.
- **O carvão vegetal devolvido ao cancelar uma ordem** volta como carvão mineral (a quantidade é a mesma).
