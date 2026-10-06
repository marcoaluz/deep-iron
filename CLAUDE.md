# CLAUDE.md — DEEP IRON

## O jogo

**DEEP IRON** é uma colônia de mineração depois de uma explosão solar, em Godot **4.7.2**. Os **ipezinhos**
(os mineiros da colônia) fazem várias coisas:

- cavam uma pedreira e erguem a vila;
- descem pelos andares da mina (S2 ácido, S3 lava, S4 cachoeira, S5 lago);
- comem, dormem, se machucam e fazem greve;
- aguentam invasões de criaturas e ondas solares até construir o **escudo solar**, que é a vitória.

A lógica é 2D: o nó `World` e as posições ficam num plano. O jogador vê pela **vista isométrica** em pixel art
(`scripts/iso/`), que espelha o mundo. O jogador não controla cada ipezinho: dá a **função** (minerador,
lenhador, cozinheiro, guarda, fundidor, ferreiro…) ou marca **áreas de trabalho** com quantos trabalham em cada
uma, e a IA de cada um decide o resto, seguindo a **agenda do dia** (relógio de 24 h: café, trabalho, almoço,
hora social, dormir) e o **calendário** (missa de domingo, festivais).

O projeto Godot fica em **`project.godot/`**. A cena inicial é `scenes/ui/start_menu.tscn`, e a partida é
`scenes/game/main.tscn`. Os autoloads são `Audio`, `SaveManager` e `WindowManager`.

## Pastas

| Pasta | O quê |
|---|---|
| `project.godot/scripts/core` | Sistemas globais e janelas: economia, save, ânimo, defesa, sol, pesquisa, HUD, painéis, menu de construção. |
| `project.godot/scripts/props` | Prédios e objetos do mapa: estações de trabalho, casas, canteiros, jazidas, árvores, elevadores, vagonete. |
| `project.godot/scripts/workers` | `ipezinho.gd`: a IA (estados, funções, necessidades, ferimentos, save do ipezinho). |
| `project.godot/scripts/creatures` | `creature.gd` (invasores noturnos) e `animal.gd` (coelho e javali da floresta). |
| `project.godot/scripts/iso` | A vista isométrica: espelhos, ordem de desenho, arte nova, bonecos, luz, efeitos. |
| `project.godot/scripts/ui` | Pele da interface, ícones, retratos, menus, corte da mina (F2). |
| `project.godot/data/niveis` | Os níveis da mina por dados (`*.tres`, recurso `nivel_mina.gd`). |
| `project.godot/scenes` | Cenas: `game/main.tscn`, `props/`, `creatures/`, `characters/Ipezinho.tscn`, `ui/`. |
| `project.godot/assets/game` | Arte integrada (`iso/` prédios, bonecos, props, mapa; `ui/`). |
| `project.godot/prototipos/camera/arte_iso` | Pipeline de arte em Python (PixelLab → `integra.py` → `assets/game/iso`). Não é código do jogo. |
| `project.godot/tests` | `blocos/` (um teste por Bloco), `test_blocos.gd` (registro GUT), `test_iso*.gd` (GUT), `capturas_*.gd` (fotos, não são testes). |
| `docs/` | Um relatório por Bloco (`BLOCONN_*.md`), arte de conferência (`docs/arte/blocoNN/`), balanceamento. |
| `tools/` | `run_tests.sh` / `run_tests.ps1`, build do Windows, scripts do PixelLab, telemetria. |
| `CONTEXTO.md` | Estado atual e histórico pra retomar em outra sessão. Atualizar ao fim de cada entrega. |

### Sistemas principais

**`scripts/core`**

| Sistema | O que faz |
|---|---|
| `main.gd` | Entrada do jogador: seleção, ordens, atalhos (via `teclas.gd`, remapeável). Cria `house_placer`, `area_placer`, `WorkAreas`, `founding` e `weather`. |
| `environment.gd` | Monta o mapa: superfície, faixas dos andares, decoração, navegação, níveis por dados, lotes. |
| `economy.gd` | Créditos, vender (minério e itens), recrutar; `quantidade(id)`, `add_item`/`take_item`; custos em metal (`metal_falta`, `paga_metal`, `custo_metal_texto`: barra a partir do estágio da fornalha, Bloco 87). |
| `save_manager.gd` + `save_util.gd` | Save em JSON (`user://savegame.json`), backups, migração de versões, leitura tolerante. |
| `day_night.gd` | Relógio de 24 h (Bloco 83): `hora()`, `hora_texto()`, semana (o 7º dia é domingo), marcos (amanhecer, fim do expediente, anoitecer, dormir), `is_night()`, "Pular dia". `time` = segundos reais desde o amanhecer. |
| `schedule.gd` | A AGENDA dos ipezinhos (Bloco 84): `periodo(ipezinho)`, refeições (porção por refeição, refeição perdida), exceções (médico, guardas, cozinheiro), números da hora social (Bloco 85). |
| `calendario.gd` | Padre, igreja, missa de domingo, funeral, escolha do domingo à tarde e festivais por estação (Bloco 88). |
| `items.gd` | Catálogo de itens (Bloco 82): id, nome, categoria, ícone, preço e onde fica guardado (`stock` de minério ou `itens` processados). |
| `production_queue.gd` | Ordens de produção genéricas (Bloco 86): receita + quantidade, insumo pago quando a unidade começa, pausa sem insumo, cancelar devolve. |
| `caminhos.gd` + `caminho_placer.gd` | Caminhos pintados na grade (Bloco 89): bônus de velocidade, rota do passeio, save compacto. |
| `decor.gd` + `decoracoes.gd` | Decoração do jogador (Bloco 90): catálogo, pôr/remover, luz, beleza, rebuild agrupado. |
| `sun.gd` | Estações, ondas solares, escudo e vitória. |
| `morale.gd` | Ânimo, greve, festa, luto, taverna. |
| `defense.gd` | Muro, armas, campo de treino, ondas de criaturas e a **fila da forja** do Arsenal (só anda com engenheiro). |
| `equipment.gd` | Casacos e trajes, com a fila de fabricação na Oficina. |
| `research.gd` | Árvore de pesquisa do Laboratório. |
| `finds.gd` | Achados da escavação e o robô. |
| `niveis.gd` / `nivel_mina.gd` | Os níveis da mina por dados. |
| `fundo.gd` | Poças e ventiladores do S2 e do S3. |
| `work_areas.gd` / `work_panel.gd` / `area_placer.gd` | Áreas de trabalho com postos (Bloco 77). |
| `obra_site.gd` | O pedaço comum de toda obra feita por engenheiro. |
| `build_menu.gd` | O menu CONSTRUIR (cartões). |
| `house_placer.gd` | Posicionar prédio no mapa. |
| `hud.gd` | HUD montado por código. |
| `*_panel.gd` | As janelas, registradas em `hud._add_panel`. |

**`scripts/props`**

| Sistema | O que faz |
|---|---|
| `station.gd` | **Base de toda estação de trabalho.** Slots reservados, `is_usable`, `accepts_worker`, obstáculo da navegação. |
| `mineral_node.gd`, `tree_node.gd`, `food_source.gd`, `hunt_spot.gd` | Jazida, árvore, horta e toca: os recursos. |
| `armazem.gd`, `comedouro.gd`, `casa.gd`, `enfermaria.gd`, `taverna.gd`, `laboratorio.gd`, `arsenal.gd`, `oficina.gd`, `vestiario.gd` | Os prédios. |
| `centro_vila.gd` | Hub de progressão: estágios, melhorias, e quem ergue as construções encomendadas (`finish_build`). |
| `canteiro.gd` | Obra encomendada e já paga, esperando engenheiro. `KINDS` lista os tipos. |
| `estacao_vagonete.gd` + `trilho.gd` + `vagonete.gd` | Transporte de carga (Bloco 64) e ferrovia por andar (Bloco 79). |
| `deep_shaft.gd` / `abyss_shaft.gd` | Ligações entre andares (elevador e plataformas). |
| `escavadeira.gd` | Montada peça por peça; abre o S2. |
| `escudo.gd` | O projeto final. |
| `coletor_madeira.gd` | Coletor de madeira; o primeiro é a ruína da floresta, restaurada por etapas (Bloco 81). |
| `fornalha.gd` | Fornalha: barras por ordem do jogador, operada pelo fundidor (Bloco 86). |
| `igreja.gd` | Igreja: ponto social com bancos, missa e funerais (Bloco 88). |
| `social_spot.gd` | Ponto social (Bloco 85): componente com vagas em rodas (refeitório, praça, taverna, parque, igreja, banco, mesa). |
| `decoracao.gd` | Uma peça de decoração do jogador (Bloco 90). |

**`scripts/workers/ipezinho.gd`**

- `_choose_state()` decide o que fazer, por prioridade: **emergência** (caído, ferido, resgate, onda solar,
  invasão, greve) → **agenda** (`_agenda_estado`: refeições, voltar, hora social, dormir, missa; plantão do
  médico, vigília dos guardas, padre) → **necessidades** (comer com fome braba, taverna) → **função**.
- Funções: minerador, caçador, médico, engenheiro (só obras de construção), cozinheiro, lenhador, guarda,
  pesquisador, **fundidor** (Fornalha), **ferreiro** (Oficina e Arsenal) e o **padre** (um só, chega por evento,
  não recrutável).
- `_find_best_station(grupo)` escolhe a estação, filtrada por área de trabalho e por andar trancado.
- `set_job()` troca a função com segurança: ele entrega o que carrega antes.
- Tem também necessidades, ferimentos, humor e o save do ipezinho.

**`scripts/creatures`**

- `creature.gd`: invasores criados pela Defesa (lumívoro, ferrugento, magmante, gosma, chefes).
- `animal.gd`: bichos da floresta caçados pelo caçador.

## Regras fixas

1. **Português** no código, nos nomes novos e nos comentários. Indentação com **tabs** no GDScript. Seguir o
   estilo existente: comentário `##` no topo explicando o sistema e o Bloco, e comentários curtos dizendo o
   porquê.
2. **Cada entrega é um Bloco numerado.** O último existente é o **b91**; o próximo é o **b92**. (Pedido
   que chega com um número antigo, como "Bloco 50" ou "teste b51", vira o próximo livre, com o teste do mesmo
   número; explicar no relatório.)
   - Cada Bloco tem um teste novo em `tests/blocos/bNN_nome.gd`, no formato dos existentes:
     - script `SceneTree`;
     - aborta fora da pasta `fake_appdata`;
     - abre `main.tscn`;
     - usa `check(ok, msg)` imprimindo `OK` / `FALHOU`;
     - termina em `FALHAS: N`.
   - O teste fica registrado em `tests/test_blocos.gd` (`func test_bNN_nome(): run_bloco("bNN_nome.gd")`) e
     ganha uma linha em `TESTING.md`.
   - Costume do projeto: relatório em `docs/BLOCONN_*.md` e commit `bloco-NN: ...`.
3. **Tudo que entra no save passa por `save_manager.gd` e `save_util.gd`.**
   - Cada sistema tem `get_save_data()` / `load_save_data(d)`.
   - A leitura usa `SaveUtil.num/text/integer/boolean/array/dict/vec2`, sempre com valor padrão.
   - **Save antigo tem que continuar carregando**: chave ausente vira um padrão sensato, e quando precisar há
     migração em `_migrate`.
   - Documentar a chave nova no cabeçalho do `save_manager.gd`.
4. **Balanceamento é `@export` com comentário** (o que é e a unidade), nunca número mágico no meio da lógica.
   A lista fica em `docs/BALANCEAMENTO.md` (`python tools/lista_balanceamento.py`).
5. **Não mexer em `addons/`, `demo/` nem `godot_state_charts_examples/`.**
6. **Reaproveitar os padrões existentes** em vez de criar sistemas paralelos:

   | Pra… | Usar |
   |---|---|
   | Estação de trabalho | `station.gd` |
   | Obra paga que espera engenheiro | `Canteiro` + `ObraSite` (`canteiro.gd` `KINDS`, `obra_site.gd`) |
   | Escolher lugar no mapa | `house_placer.gd` |
   | Cartão no menu CONSTRUIR | `build_menu.gd` |
   | Fila de produção | `production_queue.gd` (Fornalha, encomendas da Oficina); a forja das armas é a fila do `defense.gd` (Arsenal) e a do equipamento é a do `equipment.gd` — todas feitas pelo ferreiro/fundidor |
   | Item, preço, onde guardar | `items.gd` + `Economy.quantidade/add_item/take_item` |
   | Custo em metal | `Economy.metal_falta` / `paga_metal` / `custo_metal_texto` (barra a partir do estágio da fornalha) |
   | Horário e agenda | `DayNight.hora()` / `tempo_da_hora()` / sinal `marco`; `Schedule.periodo(ipezinho)` |
   | Lugar pra conversar | `social_spot.gd` (`SocialSpot.criar(...)` no `_ready` do prédio) |
   | Janela | `hud._add_panel` (padrão `setup` / `refresh` / `button_text` / `has_available_action`) |

7. **Rodar os testes** (ver `TESTING.md`).
   - **Sempre** com `APPDATA` / `LOCALAPPDATA` / `XDG_DATA_HOME` numa pasta com `fake_appdata` no caminho.
     O save real do jogador nunca pode ser tocado.
   - Imagem nova precisa de `godot --headless --path project.godot --import` antes dos testes.
   - **Se o Godot não estiver disponível no ambiente, dizer claramente o que não deu para verificar**, em vez
     de afirmar que passou.
   - O Godot usado é `D:\DEV\Godot\Godot_v4.7.2-stable_win64.exe`.
8. **Antes de refatorações grandes**, mostrar um plano curto e esperar aprovação.
9. **Produção só por ORDEM explícita do jogador** (fornalha, ferreiro, forja, oficina etc.), nunca automática.
   O padrão é uma fila de encomendas que só anda com o trabalhador certo.
10. **Sempre usar as skills do projeto** (`.claude/skills/`) ao desenvolver ou ajustar, carregando as que
    servem para a tarefa antes de mexer:

    | Tarefa | Skill |
    |---|---|
    | Código GDScript | `godot-gdscript` |
    | Cenas e nós | `godot-nodes-scenes` |
    | Sinais e grupos | `godot-signals-groups` |
    | Save | `save-systems` |
    | Testes | `godot-gdscript-headless-testing` |
    | Interface | `godot-ui-control` |
    | IA dos ipezinhos e criaturas | `ai-behavior-trees-utility-ai` |
    | Sensação de jogo | `game-feel` |
    | Arte | `create-game-assets` |
    | Desempenho | `performance-optimization` |
    | Produção e recursos | `survival-crafting` |

    O objetivo é deixar o jogo melhor, não só cumprir o pedido.

## Notas práticas

- Imagens (PNG / JPG / GIF / WAV) ficam no **Git LFS**.
- `prototipos/.../integra.py` regrava PNGs: usar os subcomandos parciais (`integra.py props <nomes>`,
  `integra.py caminhadas <pastas>`) quando der.
- Arte nova vem do PixelLab (`tools/pixellab/`). Fazer um piloto antes de qualquer lote.
- Push só com o OK do jogador / dono do projeto.
- **Memória:** com o editor do Godot aberto, a bateria inteira de testes em segundo plano foi derrubada pelo
  sistema. Rodar os testes **um por vez, em primeiro plano**, e listar no relatório os que não foram conferidos.
- **Pra ver as coisas no jogo depressa (F3, build de editor):**
  - "Andares: abrir todos" e "Ir para: …";
  - "Criaturas: invasão com todos os tipos";
  - "Pular dia" (na barra de cima).
