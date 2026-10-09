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

## 2) Arte (PixelLab, regra 11) — tudo gerado e integrado depois do "aprovado" do Marco

O Marco aprovou o piloto do agricultor ("aprovado"), e eu fiz o resto na sequência.

- **Agricultor e agricultora** (completos, receita do elenco): candidatos, personagem v3, caminhada de 8 quadros, comer, ferido,
  deitar, mancar, o trabalho "colher", o casaco de inverno e o retrato com 5 expressões. Integrados (`integra.py bonecos`).
  - O "colher" do agricultor foi **refeito** (brotos no chão e a cabeça escura de costas): agora limpo. O da agricultora também.
- **Três estruturas, cada uma com a obra 1 → 2 → 3 → pronto** (`predios107.py`, a mesma receita da carpintaria):
  - **Estufa de vidro:** armação de madeira escura, paredes e telhado de painéis de vidro (alguns remendados), canteiros com plantas
    e cogumelos vistos pelo vidro. Na obra, os painéis chegam em caixotes e entram aos poucos.
  - **Carvoaria:** forno em cúpula de barro e pedra, escurecido pela fuligem, com a porta gradeada e um abrigo de tábuas com lenha e
    sacos de carvão.
  - **Curtume:** galpão aberto de madeira com telhado de chapa enferrujada, tinas redondas, varais de couro e a viga de raspar.
  - Cada uma tem o desenho do mapa antigo/fantasma (`assets/game/<nome>.png`) e o cartão do menu CONSTRUIR (96×64).
- **Animações novas de trabalho:** o lenhador/lenhadora **carvoejando** (empurra a lenha com a vara longa) e o caçador/caçadora **curtindo**
  (raspa o couro), nos personagens e nos casacos que já existiam. A vista isométrica troca pela animação certa pelo estado do ipezinho
  (`carvoejando` / `curtindo`).
  - O "curtir" foi refeito uma vez (a 1ª leva trouxe uma foice): saiu com a faca de raspar, mas **no casaco do caçador, de frente, ainda
    aparece uma ferramenta curva grande** (e na caçadora, em alguns quadros). Dá pra refazer (~16 gerações cada).
- **Ícones:** o agricultor, a estufa, o carvão vegetal, o couro curtido e a ração (32 px e 24 px), na barra e nos itens.
- **A ruína do vagonete** (pedida no Bloco 106): o carrinho velho e destruído, com mato e dormentes soltos, parado no trilho enquanto o
  vagonete da boca não foi restaurado (`vagonete107.py`, a partir do carrinho do jogo). Restaurado, volta o carrinho de verdade.
- **Conferência:**
  - `docs/arte/bloco107/agricultor_piloto.png`, `agricultora_piloto.png`;
  - `animacoes_novas.png`, `animacoes_refeitas.png`;
  - `estruturas_primeira.png` (as 3 estruturas em todos os estágios);
  - `icones_candidatos.png`;
  - `vagonete_ruina_candidatos.png`;
  - as fotos do jogo: `obras_*.png`, `prontas.png`, `lenhador_carvoejando.png`, `cacador_curtindo.png`, `agricultor_colhendo.png`,
    `cozinha_cardapio.png`, `menu_alimentacao.png`, `vagonete_ruina.png`, `vagonete_restaurado.png`.
- **Ainda provisório:**
  - o cartão da **horta** no menu usa o desenho da horta reduzido;
  - o desenho da horta construída é o da horta que já existia (só a estufa, a carvoaria e o curtume ganharam a obra por etapas).

### Orçamento do PixelLab
| | Gerações | Tipo |
|---|---|---|
| Saldo no começo do bloco | 6.063 | confirmado |
| Gasto neste bloco (tudo: agricultor, agricultora, 3 estruturas com obras, animações, ícones, ruína) | **332** | real |
| Saldo agora | **5.731** | confirmado |
| Previsto no plano | ~570 | estimado (foi bem menos: as estruturas custaram ~10 cada tentativa) |
| Opcional: refazer o "curtir" do casaco do caçador (e da caçadora) | ~16 cada | estimado |

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

Rodou um teste por vez, com a pasta `fake_appdata`: **os 90 testes de bloco, todos sem falha, no código final** (depois da arte).
- Nenhum teste antigo precisou de ajuste neste bloco.
- **O que a bateria achou no meio do caminho (e foi corrigido):**
  - O `b51_engenheiro_estresse` começou a falhar depois que o Centro da Vila passou a apagar e recriar as hortas a cada
    carregamento (50 carregamentos seguidos = 50 refeitas da malha de navegação). Agora o carregamento **reaproveita** o que já existe
    no mesmo lugar e só cria ou apaga a diferença.
  - Essa mesma troca quebrava o `p28_save` (14 mil erros): ao carregar, a cena velha ainda está nos grupos e a horta dela era reaproveitada.
    Agora só se reaproveita o que é da cena atual.
- Intermitentes de rodadas anteriores (`b101`, `b77`) passaram.
- **GUT `test_iso*`:** 12 de 12.

## 9) Pendências e riscos

- **O "curtir" do casaco do caçador** ainda mostra uma ferramenta curva grande (seção 2).
- **A quem a área de alimentos serve:** ela continua dando a função caçador. Se o jogador quiser áreas de horta pro agricultor, é um
  tipo novo em `work_areas.TIPOS`. Não fiz.
- **O recibo de encomenda vale só no quadro do pagamento** (Bloco 96). Se uma unidade da Fornalha começa no MESMO quadro em que o jogador
  encomenda uma obra, os insumos dela entram na lista da obra. Já existia; a chance é minúscula. Anotado.
- **O carvão vegetal devolvido ao cancelar uma ordem** volta como carvão mineral (a quantidade é a mesma).
