# Balanceamento: onde mexer em cada valor

Gerado por `python tools/lista_balanceamento.py` (Bloco 52). Os valores são `@export` nos scripts: dá
pra mudar no Inspector do Godot (na cena do sistema: `scenes/game/main.tscn` e as cenas dos prédios) ou
direto no script. **Mudar valor é decisão do Marco**; aqui só está onde fica cada um.

Pra medir: painel de debug (F3, só em build de editor) e a telemetria (`user://telemetria/`,
resumo com `python tools/resumo_telemetria.py`).

A coluna **na cena** aparece quando uma cena `.tscn` troca o padrão do script: no jogo vale o da cena.

Total: **867 valores** em 4 pastas de scripts (77 trocados por alguma cena).

## `scripts/core/audio_manager.gd` (78)

**Volumes (0 a 1)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `master_volume` | 1.0 |  |  |
| `music_volume` | 0.35 |  |  |
| `ambience_volume` | 0.55 |  |  |
| `sfx_volume` | 0.8 |  |  |
| `music_enabled` | true |  |  |
| `fade_in_time` | 3.0 |  | Segundos de fade-in da música e do ambiente ao iniciar. |

**Trilhas**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `music` | — | **(recurso)** (audio_manager.tscn) |  |
| `ambience` | — | **(recurso)** (audio_manager.tscn) |  |

**Efeitos**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `pick_sounds` | [] | **(recurso)** (audio_manager.tscn) |  |
| `step_sounds` | [] | **(recurso)** (audio_manager.tscn) |  |
| `deposit_sounds` | [] | **(recurso)** (audio_manager.tscn) |  |
| `eat_sounds` | [] | **(recurso)** (audio_manager.tscn) |  |
| `sell_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `recruit_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `click_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `error_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `hurt_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `heal_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `forge_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `fanfare_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `chop_sounds` | [] | **(recurso)** (audio_manager.tscn) |  |
| `elevator_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `branch_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `toll_sound` | — | **(recurso)** (audio_manager.tscn) | Sino fúnebre: um ipezinho morreu. |
| `cheers_sound` | — | **(recurso)** (audio_manager.tscn) | Brinde na taverna / batucada da greve. |
| `protest_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `find_sound` | — | **(recurso)** (audio_manager.tscn) | Achado na mina / robô ligando / pane do reator. |
| `robot_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `boom_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `alarm_sound` | — | **(recurso)** (audio_manager.tscn) | Invasão: berrante, Lumívoro, Ferrugento, golpe, barricada quebrando. |
| `screech_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `clank_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `hit_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `gate_break_sound` | — | **(recurso)** (audio_manager.tscn) |  |
| `solar_sound` | — | **(recurso)** (audio_manager.tscn) | Onda solar chegando. |

**Mixagem dos efeitos (dB)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `pick_db` | -7.0 |  |  |
| `step_db` | -22.0 |  |  |
| `deposit_db` | -9.0 |  |  |
| `eat_db` | -11.0 |  |  |
| `hurt_db` | -4.0 |  |  |
| `heal_db` | -8.0 |  |  |
| `forge_db` | -10.0 |  |  |
| `fanfare_db` | -4.0 |  |  |
| `chop_db` | -9.0 |  |  |
| `elevator_db` | -8.0 |  |  |
| `branch_db` | -5.0 |  |  |
| `toll_db` | -5.0 |  |  |
| `cheers_db` | -12.0 |  |  |
| `protest_db` | -9.0 |  |  |
| `find_db` | -8.0 |  |  |
| `robot_db` | -6.0 |  |  |
| `boom_db` | -2.0 |  |  |
| `alarm_db` | -4.0 |  |  |
| `screech_db` | -12.0 |  |  |
| `clank_db` | -10.0 |  |  |
| `hit_db` | -9.0 |  |  |
| `gate_break_db` | -4.0 |  |  |
| `solar_db` | -3.0 |  |  |
| `ui_db` | -6.0 |  |  |
| `pitch_variation` | 0.08 |  | Variação aleatória de pitch (0.08 = ±8%), pra não soar repetitivo. |

**Bloco 55: sons novos, ambiência e música**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `build_db` | -12.0 |  |  |
| `build_done_db` | -6.0 |  |  |
| `harvest_db` | -12.0 |  |  |
| `equip_db` | -10.0 |  |  |
| `party_db` | -8.0 |  |  |
| `place_db` | -8.0 |  |  |
| `creature_down_db` | -8.0 |  |  |
| `drill_db` | -14.0 |  |  |
| `ui_panel_db` | -14.0 |  |  |
| `max_same_voice` | 4 |  | Quantas vozes do MESMO som ao mesmo tempo (15 mineradores batendo não viram um muro de som). |
| `music_crossfade` | 2.5 |  | Segundos da troca de música (calma <-> perigo) e de ambiência (mina, superfície, fundo). |
| `ambience_crossfade` | 2.0 |  |  |
| `ambience_db` | {"mina": 0.0, "dia": -4.0, "noite": -5.0, "fundo": -1.0} |  | Volume de cada ambiência (dB) e da chuva por cima. |
| `rain_db` | -6.0 |  |  |
| `limiter_ceiling_db` | -0.5 |  | Teto do limitador no Master (dB): nada passa disso, nem com tudo tocando junto. |

**Limites**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `max_voices` | 24 |  |  |
| `max_steps_per_second` | 8.0 |  | Máximo de passos tocando por segundo somando todos os ipezinhos. |
| `sfx_max_distance` | 900.0 |  | Distância (em pixels do mundo) além da qual efeitos posicionais não tocam. |

## `scripts/core/build_menu.gd` (7)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `janela_tamanho` | Vector2(872, 560) |  | Tamanho MÁXIMO da janela (px lógicos). Ela usa o que couber entre a barra de cima e a de baixo (a 125% em 1280x720 a área é 1024x576), igual em todas as abas: só muda com a escala da interface ou a janela do jogo. |
| `janela_folga` | 8.0 |  | Folga mínima entre a janela e as barras / as bordas (px lógicos). |
| `cartao_tamanho` | Vector2(196, 238) |  | Tamanho de cada cartão (px lógicos). A altura cresce até caber a estrutura fixa na fonte de agora (_altura_cartao): todo cartão fica com a MESMA altura, e o botão no mesmo lugar. |
| `colunas` | 4 |  | Cartões por linha da grade. |
| `abas_por_linha` | 6 |  | Abas por linha (11 abas = 2 linhas). |
| `desc_linhas` | 3 |  | Linhas da descrição no cartão (o resto vai na dica). |
| `imagem_area` | Vector2(180, 70) |  | Área da imagem no topo do cartão (px lógicos; a imagem é 96x64 e fica 1:1 no meio). |

## `scripts/core/calendario.gd` (16)

**Padre**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `padre_estagio` | 2 |  | Estágio da vila em que o padre chega (2 = Vilarejo). |
| `padre_nome` | "Padre Bento" |  | Nome dele. |

**Missa (domingo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `missa_inicio` | 9.0 |  |  |
| `missa_fim` | 11.0 |  |  |
| `missa_animo` | 6.0 |  | Ânimo de quem foi à missa (fator "foi à missa"), que some aos poucos (por segundo). |
| `missa_decai` | 0.012 |  |  |
| `aconselhamento_por_segundo` | 0.6 |  | Zanga a menos por segundo de quem está na igreja (o padre lá dobra). |

**Funeral**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `funeral_horas` | 1.0 |  | Horas de funeral na igreja, começando na hora social depois da morte. |
| `funeral_alivio` | 12.0 |  | Quanto o luto da vila cai com cada funeral. |

**Cemitério (Bloco 93)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `enterro_tempo` | 8.0 |  | Segundos que o padre leva enterrando, na vaga. |
| `enterro_alcance` | 14.0 |  | Distância (px) em que o padre alcança o corpo / a vaga. |

**Domingo à tarde**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `tarde_inicio` | 13.0 |  | A tarde do domingo começa (até o fim do expediente). |
| `aviso_escolha` | 12.0 |  | A janela da escolha abre sozinha a esta hora do domingo. |
| `domingo_trabalho_zanga` | 20.0 |  | Trabalhar no domingo: zanga a mais de uma vez pra cada um (hora extra). |
| `festival_mult` | 1.5 |  | Festival do dia de festa da estação: o ânimo da festa x isto. |

**Calendário**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `festivais` | PackedStringArray(["Festa das Flores", "Festa do Sol", "Festa da Colheita", "Festa das Lanternas"]) |  | Nome do festival de cada estação (primavera, verão, outono, inverno). |

## `scripts/core/camera_controller.gd` (16)

**Zoom**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `zoom_min` | 0.5 |  | Bloco 48: 0,6 -> 0,5 (em 720p a parada nítida mais afastada é 0,5: 1 px de arte = 1 px de tela). |
| `zoom_max` | 3.0 |  |  |
| `start_zoom` | 1.3 |  | Zoom ao abrir (assenta na parada nítida mais perto). |
| `zoom_step` | 1.15 |  | Multiplicador por "clique" da roda do mouse (só com crisp_zoom desligado). |
| `zoom_smoothing` | 12.0 |  |  |
| `crisp_zoom` | true |  | Bloco 48: a roda anda de parada nítida em parada nítida (pixel de arte inteiro na tela). Desligado: zoom livre como antes (zoom_step por clique). |
| `art_pixel_world` | 2.0 |  | Pixels de MUNDO por pixel de ARTE. Hoje a arte é desenhada pequena e mostrada em escala 2; se a densidade da arte mudar (ver docs/escala_visual), é só trocar aqui. |
| `iso_art_pixel_world` | 1.0 |  | Prompt 29: na vista iso com a arte nova, 1 px de arte = 1 unidade da tela isométrica (a arte nova é desenhada no tamanho real). As paradas usam essa densidade, e ganham uma parada "longe" de meio pixel de tela por pixel de arte (o mapa novo tem ~6.000 px de largura: sem ela, não dá pra ver a vila inteira). Abaixo de 1:1 o pixel não tem como ser inteiro: fica nítido (filtro mais próximo), com algum serrilhado. |
| `iso_overview_stop` | 0.5 |  |  |
| `iso_zoom_min` | 0.3 |  |  |

**Pan**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `pan_speed` | 650.0 |  |  |
| `pan_smoothing` | 10.0 |  |  |
| `edge_scroll` | false |  |  |
| `edge_margin` | 10.0 |  |  |

**Limites**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `bounds` | Rect2() |  | Área onde o centro da câmera pode ficar (normalmente o mapa). Tamanho zero = sem limite. |
| `bounds_margin` | 80.0 |  |  |

## `scripts/core/caminhos.gd` (5)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `tamanho` | 20.0 |  | Lado de uma célula da grade (px do chão). |
| `custos` | {"terra": Vector3i(2, 0, 0), "cascalho": Vector3i(3, 1, 0), "pedra": Vector3i(5, 2, 0)} |  | Custo por célula: x = créditos, y = ferro (pedra/cascalho), z = madeira. |
| `bonus` | {"terra": 0.12, "cascalho": 0.2, "pedra": 0.3} |  | Bônus de velocidade de quem anda sobre o caminho (0.15 = +15%), por tipo. |
| `rota_entrada` | 140.0 |  | Rota do passeio: só usa caminho que comece/termine até esta distância (px) de quem sai e do destino. |
| `rota_passo` | 3 |  | Rota do passeio: um waypoint a cada tantas células. |

## `scripts/core/day_night.gd` (22)

**Relógio de 24 horas (Bloco 83)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `duracao_dia_real` | 540.0 |  | Segundos REAIS de um dia inteiro (24 h de jogo). 540 = 9 minutos; 1 hora de jogo = 22,5 s. |
| `hora_amanhecer` | 5.0 |  | Hora em que amanhece (o turno começa, o dia do jogo vira). 5.0 = 05:00. |
| `hora_fim_expediente` | 18.0 |  | Hora do fim do expediente (a agenda manda voltar e largar a carga). 18.0 = 18:00. |
| `hora_anoitecer` | 18.5 |  | Hora em que anoitece (is_night: todo mundo pra casa). 18.5 = 18:30. |
| `hora_dormir` | 21.5 |  | Hora de dormir (a hora social acaba). 21.5 = 21:30. |
| `time_scale` | 1.0 |  | Acelera o relógio (2 = passa 2x mais rápido). Útil pra testar. |
| `start_time` | 0.0 |  | Em que ponto do dia o jogo começa (segundos desde o amanhecer). |

**Pular dia (Bloco 83)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `pular_velocidade` | 8.0 |  | Velocidade do jogo enquanto pula o dia (Engine.time_scale): a simulação roda de verdade, só mais rápida. |

**Horários da luz (segundos em volta da virada)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `dusk_starts_before` | 25.0 |  | Começa a escurecer esses segundos ANTES de anoitecer (os ipezinhos ainda trabalham). |
| `dusk_ends_after` | 8.0 |  | Termina de escurecer esses segundos DEPOIS de anoitecer. |
| `dawn_starts_before` | 8.0 |  | Começa a clarear esses segundos ANTES de amanhecer. |
| `dawn_ends_after` | 20.0 |  | Termina de clarear esses segundos DEPOIS de amanhecer. |
| `light_fade_speed` | 0.5 |  | Mudança brusca (tecla N, pular fase) vira um fade: quanto da escuridão muda por segundo. |

**Cores do ambiente**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `ambient_path` | ^"../Ambient" |  |  |
| `day_color` | Color(0.78, 0.72, 0.56) | **Color(1, 0.99, 0.96, 1)** (main.tscn) | Dia: luz quente do sol entrando pela boca da mina (valores > 1 clareiam além do normal). |
| `dusk_color` | Color(0.52, 0.34, 0.34) | **Color(1, 0.8, 0.62, 1)** (main.tscn) | Meio do entardecer (quente, alaranjado/roxo). |
| `night_color` | Color(0.07, 0.08, 0.18) | **Color(0.34, 0.4, 0.62, 1)** (main.tscn) | Noite: bem mais escura que antes; tochas, cristais e lanternas seguram o mapa. |
| `dawn_color` | Color(0.42, 0.4, 0.5) | **Color(1, 0.92, 0.84, 1)** (main.tscn) | Meio do amanhecer (mais frio que o entardecer). |

**Estações (Prompt 19)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `season_tints` | [Color(1, 1, 1), Color(1.04, 1.0, 0.92), Color(1.02, 0.95, 0.86), Color(0.9, 0.95, 1.06)] |  | A luz ambiente de cada estação multiplica a do horário: primavera neutra, verão quente e claro, outono dourado, inverno frio e azulado. As noites de inverno ficam um pouco mais escuras. |
| `winter_night_darker` | 0.88 |  |  |

**Tochas**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `torch_on_at` | 0.25 |  | Escuridão (0 = dia, 1 = noite) em que as tochas começam a acender... |
| `torch_full_at` | 0.6 |  | ...e em que ficam totalmente acesas. |

## `scripts/core/decoracoes.gd` (4)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `reembolso` | 0.5 |  | Fração do custo devolvida ao remover uma peça. |
| `beleza_raio` | 110.0 |  | Distância (px do chão) em que a decoração enfeita uma casa. |
| `beleza_teto` | 6.0 |  | Teto do ânimo de "casa enfeitada". |
| `nav_espera` | 0.6 |  | Segundos sem pôr/tirar peça grande até refazer a navegação (uma vez só pra várias). |

## `scripts/core/defense.gd` (60)

**Armas (na ordem de WEAPON_IDS)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `weapon_damage` | [3.0, 6.0, 7.0, 11.0] |  |  |
| `weapon_range` | [18.0, 18.0, 110.0, 18.0] |  |  |
| `weapon_vs_ferrugento` | [1.0, 1.0, 1.0, 1.6] |  | Multiplicador do dano contra Ferrugentos. |
| `weapon_costs` | [Vector3i.ZERO, Vector3i(150, 40, 20), Vector3i(350, 40, 40), Vector3i(600, 48, 20)] |  | x = créditos, y = minério, z = madeira. Bloco 94: a lança de prata baixou de 60 pra 48 prata (24 barras): o resto do metal é o aço da ponta. |
| `weapon_ore` | ["", "ferro", "cobre", "prata"] |  |  |
| `weapon_itens` | [{}, {}, {}, {"aco": 6}] |  | Bloco 94: itens a mais de cada arma ({item: qtd}); o conserto paga a fração repair_cost_mult (pra cima). |
| `weapon_time` | [0.0, 40.0, 60.0, 80.0] |  | Segundos de ENGENHEIRO no Arsenal pra forjar cada arma (Bloco 35: só anda com engenheiro). |
| `weapon_durability` | [30, 45, 55, 70] |  | Bloco 35: golpes que cada arma aguenta antes de quebrar (cada ataque numa invasão gasta 1). |
| `repair_cost_mult` | 0.4 |  | Consertar custa essa fração do custo de forjar (créditos, minério e madeira)... |
| `repair_time_mult` | 0.5 |  | ...e essa fração do tempo de forja. |
| `unarmed_damage` | 1.5 |  | Desarmado (a arma quebrou): luta no soco. |
| `unarmed_range` | 16.0 |  |  |

**Brecha na defesa (Bloco 36)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `raid_ore_percent` | 0.12 |  | Guarda caído abre brecha no portão dele: o primeiro invasor dali que chega no armazém leva essa fração do MINÉRIO guardado (de cada tipo)... |
| `raid_credit_percent` | 0.12 |  | ...e essa fração dos CRÉDITOS. (Uma vez por portão por invasão.) |

**Arsenal (Bloco 35)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `arsenal_credits` | 150 |  |  |
| `arsenal_ore` | 40 |  | Pedra (minério de ferro) e madeira pra erguer o Arsenal. |
| `arsenal_wood` | 60 |  |  |
| `arsenal_build_time` | 40.0 |  | Segundos de engenheiro pra erguer o Arsenal. |
| `forge_queue_max` | 4 |  | Máximo de encomendas na fila da forja. |
| `poco_post_dist` | 40.0 |  | Bloco 80: distância (px) da boca do poço até o posto dos guardas, pro lado da vila. |

**Campo de treino**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `campo_credits` | 120 |  |  |
| `campo_wood` | 50 |  |  |
| `campo_build_time` | 30.0 |  | Bloco 31b: segundos de engenheiro pra erguer o campo de treino. |

**Invasões**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `first_invasion_day` | 3 |  |  |
| `invasion_every` | 2 |  |  |
| `lumi_base` | 2 |  |  |
| `lumi_per_wave` | 1 |  |  |
| `lumi_max` | 10 |  |  |
| `ferr_per_wave` | 1 |  |  |
| `ferr_max` | 6 |  |  |
| `gosma_from_wave` | 2 |  | Bloco 70: Gosma ácida (com o S2 aberto) e Magmante (com o S3 aberto), a partir da onda indicada. |
| `gosma_per_wave` | 1 |  |  |
| `gosma_max` | 4 |  |  |
| `magmante_from_wave` | 3 |  |  |
| `magmante_per_wave` | 1 |  |  |
| `magmante_max` | 3 |  |  |
| `hp_growth` | 0.15 |  | Vida das criaturas cresce essa fração por onda. |
| `hora_aviso_invasao` | 21.0 |  | Bloco 83: numa noite de invasão o aviso toca a esta hora do relógio (o rádio adianta research.radio_warning_bonus segundos)... |
| `hora_invasao` | 22.0 |  | ...e a invasão começa a esta hora (todo mundo já em casa, os guardas nos postos). Acaba no amanhecer. |
| `spawn_spread` | 20.0 |  | As criaturas vão chegando ao longo desses segundos do começo da invasão. |
| `strong_from_wave` | 4 |  | Prompt 17: a partir dessa onda, 1 a cada `strong_every` criaturas vem na forma FORTE (Lumívoro bruto, Ferrugento carregador), com mais vida e dano. 0 = nunca. |
| `strong_every` | 3 |  |  |
| `strong_hp_mult` | 1.6 |  |  |
| `strong_damage_mult` | 1.3 |  |  |

**Tiers e chefe (Bloco 62)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `tier_every_waves` | 3 |  | Tier da onda = 1 + onda / tier_every_waves + pesquisas feitas / tier_research_step. |
| `tier_research_step` | 4 |  |  |
| `tier_hp_bonus` | 0.12 |  | Por tier acima do 1: vida extra e o forte vem mais vezes (strong_every - 1 por tier, mínimo 2). |
| `elite_from_tier` | 3 |  | A partir deste tier, os fortes viram ELITE (ancião/blindado): mais vida e dano. |
| `elite_hp_mult` | 1.35 |  |  |
| `elite_damage_mult` | 1.2 |  |  |
| `boss_from_season` | 1 |  | O CHEFE (Matriarca dos Lumívoros): uma vez por estação, a partir desta estação da partida (0 = 1ª primavera, 1 = 1º verão...), na 1ª invasão dela. |
| `boss_hp_mult` | 10.0 |  |  |
| `boss_damage_mult` | 2.0 |  |  |
| `boss_call_every` | 9.0 |  | Grito: a cada tantos segundos chama mais Lumívoros perto dela (até boss_call_max no total). |
| `boss_call_count` | 2 |  |  |
| `boss_call_max` | 8 |  |  |
| `boss_weapon_corrode` | 4.0 |  | Golpe dela num guarda armado gasta a arma (pontos de durabilidade a mais). |
| `boss_reward_solarita` | 40 |  | Recompensa: solarita, peças raras e pontos na pesquisa em andamento. |
| `boss_reward_parts` | 2 |  |  |
| `boss_reward_research` | 80.0 |  |  |

## `scripts/core/economy.gd` (23)

**Venda**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `ore_price` | 2.0 |  | Créditos por unidade de ferro. |
| `copper_price` | 4.0 |  | Créditos por unidade de cobre. |
| `coal_price` | 3.0 |  | Créditos por unidade de carvão. |
| `silver_price` | 8.0 |  | Créditos por unidade de prata (nível 2: mais perigoso, paga mais). |
| `solarita_price` | 14.0 |  | Créditos por unidade de solarita (nível 3, o abismo). |
| `cristal_verde_price` | 10.0 |  | Bloco 70: cristal verde (S2, galerias de ácido) e cristal rubro (S3, poços de lava). |
| `cristal_rubro_price` | 18.0 |  |  |
| `gema_azul_price` | 30.0 |  | Bloco 71: gema azul (S5, a beira do lago). |
| `precos_itens` | {} |  | Bloco 82: troca o preço de venda (créditos por unidade) de itens do catálogo que não são minério, ex.: {"barra_ferro": 10.0}. Vazio = o preço base do items.gd. Preço 0 = não se vende. |
| `starting_credits` | 0.0 |  |  |

**Metal: custos em barra (Bloco 87)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `minerios_por_barra` | 2.0 |  | Nos custos MIGRADOS pra barra (armas, ampliação das barricadas, peças da Escavadeira, reatores, coletores, laboratório): quantos minérios valem UMA barra. Os campos de custo continuam em minério; a partir do estágio da fornalha (centro_vila.fornalha_estagio) o jogo pede ceil(minério / isto) barras do tipo. |

**Peças nos custos (Bloco 94)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `ferro_por_prego` | 0.34 |  | Pregos e ferragens só entram nos custos A PARTIR do estágio da fornalha (é o ferreiro que faz). Antes, cada peça vira o minério (ferro) que ela custaria — o custo fica como era e nada trava no começo. Ferro por prego (1 barra = 2 ferro dá 6 pregos). |
| `ferro_por_ferragem` | 6.7 |  | Ferro por ferragem (2 barras + 4 pregos). |
| `auto_sell` | false |  | Vende sozinho o que estiver no armazém a cada auto_sell_interval segundos. |
| `auto_sell_interval` | 4.0 |  |  |

**Recrutamento**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `worker_scene` | — | **(recurso)** (main.tscn) |  |
| `recruit_base_cost` | 150.0 |  |  |
| `recruit_cost_growth` | 1.5 |  | Multiplica o custo a cada ipezinho recrutado (1.5 = +50%). |
| `max_workers` | 8 |  | Limite inicial; a melhoria "Moradias" do Centro da Vila aumenta. |
| `spawn_parent` | ^"../World" |  | Nó onde os novos ipezinhos são criados (precisa ser o nó com y-sort). |
| `recruit_needs_bed` | true |  | Bloco 39: só recruta se tiver cama livre numa casa pronta (sem cama = sem lugar pra morar). |

**Prédios extras (Bloco 47)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `extra_building_cost_growth` | 1.5 |  | Cada unidade a mais do mesmo prédio custa isso vezes a anterior (1.5 = +50%; 1.0 = sempre o mesmo preço). Vale pra Laboratório, Arsenal, Campo de treino, Taverna, Coletor de madeira e Enfermaria extra. (Casas, comedouros e parques seguem com o preço de sempre.) |

**Obras com material (Bloco 96)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `obras_com_material` | true |  | Liga as obras com material: na encomenda o material fica RESERVADO no armazém e o engenheiro leva (desligado = como antes: tudo sai do armazém na hora). Serve também pra medir o antes e o depois (tests/bench_obras.gd). |

## `scripts/core/environment.gd` (55)

**Mapa**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `map_rect` | Rect2(-720, -440, 1440, 880) | **Rect2(-700, -454, 1452, 884)** (main.tscn) |  |
| `map_seed` | 1337 |  |  |
| `pixel_scale` | 2.0 |  | Escala dos pixels (os personagens usam 2x). |
| `floor_texture` | — | **(recurso)** (main.tscn) |  |
| `wall_texture` | — | **(recurso)** (main.tscn) |  |

**Clareira (superfície)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `clearing_rect` | Rect2(-300, -900, 600, 420) | **Rect2(-700, -1040, 1452, 570)** (main.tscn) | Área a céu aberto ao norte da mina, onde ficam as árvores (madeira). |
| `tunnel_x` | 0.0 |  | Túnel que liga a borda de cima da mina à clareira (centro x e largura). |
| `tunnel_width` | 88.0 |  |  |
| `clearing_floor_texture` | — | **(recurso)** (main.tscn) |  |
| `clearing_tree_texture` | — | **(recurso)** (main.tscn) | Árvores de enfeite na borda da clareira (usa o quadro 0 da árvore). |
| `clearing_tree_count` | 16 |  |  |
| `sun_color` | Color(1.0, 0.92, 0.72) |  | Luz do sol na clareira (some à noite, junto com a escuridão do DayNight). |
| `sun_energy` | 0.9 |  |  |

**Nível 2 (fundo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `deep_rect` | Rect2(-700, 3600, 1400, 260) |  | Área do nível 2, abaixo (ao sul) da mina; a descida é o elevador da escavadeira. |
| `deep_floor_texture` | — | **(recurso)** (main.tscn) |  |
| `deep_injury_mult` | 2.5 |  | Chance de acidente multiplicada por isso minerando no nível 2 (acumula com a zanga). |
| `deep_boulder_count` | 12 |  |  |
| `deep_crystal_count` | 7 |  |  |
| `deep_pebble_count` | 40 |  |  |
| `deep_tint` | Color(0.7, 0.72, 0.88) |  | Tom da decoração do fundo (mais escuro e frio que a mina). |

**Nível 3 (abismo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `abyss_rect` | Rect2(-700, 4000, 1400, 260) |  | Área do nível 3, abaixo do nível 2; a descida é a plataforma do abismo (conserto). |
| `abyss_floor_texture` | — | **(recurso)** (main.tscn) |  |
| `abyss_injury_mult` | 4.0 |  | Chance de acidente multiplicada por isso minerando no abismo (no lugar da do nível 2). |
| `abyss_boulder_count` | 10 |  |  |
| `abyss_pebble_count` | 34 |  |  |
| `abyss_tint` | Color(0.72, 0.52, 0.48) |  | Tom da decoração do abismo (escuro e avermelhado). |

**Decoração**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `boulder_count` | 14 |  |  |
| `pebble_count` | 70 |  |  |
| `crystal_count` | 7 |  |  |
| `torch_count` | 10 |  |  |
| `edge_boulder_spacing` | 44.0 |  | Espaço entre as pedras grandes que contornam a borda do mapa. |
| `keep_clear_radius` | 70.0 |  | Distância livre ao redor das estações (minério, comedouro, armazém). |
| `boulder_textures` | [] | **(recurso)** (main.tscn) |  |
| `pebble_textures` | [] | **(recurso)** (main.tscn) |  |
| `crystal_textures` | [] | **(recurso)** (main.tscn) |  |
| `torch_texture` | — | **(recurso)** (main.tscn) | Tocha acesa (a chama é desenhada por cima da apagada e some de dia). |
| `torch_unlit_texture` | — | **(recurso)** (main.tscn) | Tocha apagada (base). Sem ela, a tocha fica sempre com a chama. |
| `support_texture` | — | **(recurso)** (main.tscn) |  |
| `shadow_texture` | — | **(recurso)** (main.tscn) | Sombra projetada no chão (elipse com borda em xadrez) posta sob pedras, cristais, tochas e escoras. |

**Navegação**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `nav_agent_radius` | 7.0 |  | Raio usado pra afastar o caminho das paredes/obstáculos (≈ raio do ipezinho). |
| `nav_edge_inset` | 36.0 |  | Quanto a área andável fica pra dentro da borda do mapa (cobre a base das pedras da borda). |
| `decorations_block` | true |  | Pedras e cristais bloqueiam a passagem. |

**Luz**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `light_texture` | — | **(recurso)** (main.tscn) |  |
| `torch_light_color` | Color(1.0, 0.6, 0.26) |  |  |
| `torch_light_energy` | 1.25 |  |  |
| `torch_light_scale` | 1.4 |  |  |
| `crystal_light_color` | Color(0.45, 0.75, 1.0) |  |  |
| `crystal_light_energy` | 0.7 |  |  |
| `flicker_amount` | 0.15 |  |  |
| `cull_lights` | true |  | Liga/desliga luzes conforme estejam perto da área visível da câmera. |
| `light_cull_margin` | 260.0 |  | Folga (px do mundo) além da tela antes de desligar uma luz — ~ raio da luz. |
| `light_cull_interval` | 0.2 |  |  |

**Mapa isométrico (Prompt 29)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `palisade_y` | -462.0 |  | Paliçada entre a floresta e a vila: y da linha e meia largura da abertura do portão. (Bloco 74: com o mapa da maquete v3 a paliçada corre de norte a sul — ver palisade_x; o y fica sendo a beira da floresta do leste.) |
| `gate_half_width` | 40.0 |  |  |
| `cliff_thickness` | 6.0 |  | Espessura (px do mundo) da "parede" que a navegação vê na beira de um penhasco. |

## `scripts/core/equipment.gd` (28)

**Casaco de inverno**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `coat_credits` | 30 |  |  |
| `coat_leather` | 3 |  |  |
| `coat_wood` | 6 |  |  |
| `coat_batch` | 3 |  | Cada encomenda faz tantos casacos de uma vez. |
| `coat_time` | 15.0 |  | Segundos de engenheiro por encomenda. |
| `coat_durability` | 240.0 |  | Segundos de uso no frio até rasgar. |
| `cold_work_mult` | 0.55 |  | Sem casaco, no inverno, no nível da mina/clareira: o trabalho rende isso (0.55 = 45% mais lento). |

**Botas de couro (Bloco 94)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `botas_credits` | 20 |  |  |
| `botas_leather` | 2 |  |  |
| `botas_pregos` | 4 |  | Pregos da sola (vêm do ferreiro). |
| `botas_time` | 15.0 |  | Segundos de ferreiro por par. |
| `botas_durability` | 300.0 |  | Segundos andando na neve até furar. |
| `neve_speed_mult` | 0.85 |  | Sem botas, no inverno, na superfície: anda nessa fração da velocidade (0.85 = 15% mais lento). |

**Trajes de perigo (gás, calor, radiação)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `suit_credits` | [80, 90, 120] |  |  |
| `suit_ore` | [20, 25, 15] |  |  |
| `suit_ore_type` | ["carvao", "ferro", "prata"] |  | Filtro de carvão na máscara, ferro no traje térmico, prata no antirradiação. |
| `suit_leather` | [1, 2, 2] |  |  |
| `suit_time` | [25.0, 30.0, 35.0] |  |  |
| `suit_durability` | [180.0, 150.0, 120.0] |  | Segundos de exposição que cada traje aguenta... |
| `suit_wear_rate` | [1.0, 1.3, 1.6] |  | ...gastos nessa taxa por segundo lá dentro (o calor e a radiação comem mais rápido). |
| `suit_research` | "trajes" |  | Pesquisa que libera os trajes ("" = sem pesquisa). |

**Vestiário (Bloco 44)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `vestiario_credits` | 120 |  |  |
| `vestiario_ore` | 30 |  | Pedra (ferro) e madeira pra erguer o Vestiário. |
| `vestiario_wood` | 50 |  |  |
| `vestiario_build_time` | 30.0 |  |  |

**Conserto e fila**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `repair_cost_mult` | 0.4 |  |  |
| `repair_time_mult` | 0.5 |  |  |
| `queue_max` | 6 |  |  |

## `scripts/core/finds.gd` (8)

**Chances (por ciclo de mineração)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `find_chance_surface` | 0.05 |  |  |
| `find_chance_deep` | 0.12 |  |  |
| `abyss_find_mult` | 1.5 |  | No abismo (nível 3) a chance do fundo é multiplicada por isso. |
| `cristal_chance` | 0.25 |  | Dentro de um achado no fundo: chance de ser cada item raro (se ainda não achado). |
| `solar_chance` | 0.12 |  |  |
| `bobina_chance` | 0.08 |  |  |
| `robot_chance` | 0.1 |  |  |
| `robot_guarantee_after` | 6 |  | Achados no fundo até o robô aparecer com certeza. |

## `scripts/core/fundo.gd` (22)

**Poça de ácido (S2)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `acido_lentidao` | 0.6 |  | Velocidade de quem está dentro sem máscara (0.6 = 60%). |
| `acido_exposicao` | 5.0 |  | Segundos dentro sem máscara até queimar (machucado leve). |
| `acido_grave` | 0.0 |  | Chance da queimadura de ácido ser grave. |

**Poço de lava (S3)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `lava_lentidao` | 0.5 |  |  |
| `lava_exposicao` | 2.5 |  |  |
| `lava_grave` | 0.3 |  |  |

**Água (S4)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `agua_lentidao` | 0.8 |  | Bloco 71: a água do S4 não pede traje: atrasa um pouco e molha; molhado, a lava queima x molhado_lava. |
| `agua_molhado` | 20.0 |  |  |
| `molhado_lava` | 0.3 |  |  |

**Ventilador (S2)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `ventilador_credits` | 400 |  |  |
| `ventilador_ore` | 60 |  |  |
| `ventilador_ore_type` | "prata" |  |  |
| `ventilador_wood` | 40 |  |  |
| `ventilador_build_time` | 45.0 |  | Segundos de engenheiro pra montar. |
| `ventilador_max` | 4 |  |  |
| `ventilador_alcance` | 260.0 |  | Alcance (px da lógica) e quanto ele corta: a máscara gasta e o ácido queima x (1 - redução). |
| `ventilador_reducao` | 0.5 |  |  |
| `ventilador_nevoa` | 0.2 |  | Cada ventilador tira essa fração da névoa verde do S2 (no máximo ventilador_nevoa_max). |
| `ventilador_nevoa_max` | 0.6 |  |  |

**Escavadeira no fundo**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `broca_cristal_verde` | 0.12 |  | Chance de cada minério da broca virar cristal (S2 aberto: verde; S3 aberto: rubro). |
| `broca_cristal_rubro` | 0.08 |  |  |
| `broca_s3_mult` | 1.25 |  | Com o S3 aberto a broca rende mais (o fundo do abismo é mais quente e mais mole). |

## `scripts/core/hud.gd` (4)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `ore_icon` | — | **(recurso)** (main.tscn) |  |
| `coin_icon` | — | **(recurso)** (main.tscn) |  |
| `worker_list_max_height` | 300.0 |  | Altura máxima da lista de ipezinhos antes de virar rolagem. |
| `refresh_rate` | 10.0 |  | Atualizações do HUD por segundo. |

## `scripts/core/main.gd` (1)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `founding_on_new_game` | true |  | Bloco 37: partida nova começa com a FUNDAÇÃO (o jogador escolhe onde ficam o Centro da Vila e o Armazém; ver founding.gd). false = começa com o layout da cena (testes). |

## `scripts/core/morale.gd` (36)

**Greve**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `unhappy_warn_below` | 40.0 |  | Abaixo disso a vila avisa que está insatisfeita. |
| `strike_below` | 30.0 |  | Ânimo médio abaixo disso por strike_grace segundos começa a greve... |
| `strike_grace` | 60.0 |  |  |
| `strike_end_at` | 45.0 |  | ...que só acaba quando a média chega aqui. |
| `strike_ultimatum` | 300.0 |  | Segundos de greve até expulsarem o jogador. |
| `last_warning_at` | 60.0 |  | Faixa de "último aviso" quando faltar isso. |
| `min_ultimatum_on_load` | 90.0 |  | Save carregado no meio da greve: o ultimato nunca volta com menos que isso. |
| `drum_interval` | 3.2 |  | Segundos entre as batucadas da greve. |

**Festa**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `festa_credits` | 150 |  |  |
| `festa_food` | 30.0 |  |  |
| `festa_boost` | 20.0 |  | Felicidade dada na hora pra todo mundo. |
| `festa_bonus` | 10.0 |  | E somada no alvo por festa_duration segundos. |
| `festa_duration` | 240.0 |  |  |

**Luto**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `grief_per_death` | 20.0 |  |  |
| `grief_max` | 40.0 |  |  |
| `grief_time` | 300.0 |  | Segundos pra um luto de grief_per_death sumir. |

**Funeral (Bloco 93)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `funeral_bonus` | 5.0 |  | Ânimo a mais pra vila toda depois de um funeral digno (pesquisa "Ritos fúnebres"), e por quantos segundos. |
| `funeral_bonus_tempo` | 240.0 |  |  |

**Vila**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `stage_bonus` | 3.0 |  | Felicidade no alvo de todos por estágio da vila acima do 1. |

**Taverna**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `taverna_credits` | 120 |  | Construir: créditos, madeira. Ampliar (nível 2): créditos, madeira e pedra (ferro). |
| `taverna_wood` | 40 |  |  |
| `taverna_up_credits` | 350 |  |  |
| `taverna_up_wood` | 60 |  |  |
| `taverna_up_ore` | 40 |  |  |
| `taverna_up_ore_type` | "ferro" |  |  |
| `taverna_build_time` | 45.0 |  | Bloco 31b: segundos de engenheiro pra erguer / ampliar a taverna. |
| `taverna_up_build_time` | 40.0 |  |  |
| `taverna_bonus` | [5.0, 8.0] |  | Alvo de felicidade de todos por ter taverna (nível 1 / 2). |

**Parque (Bloco 41)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `park_credits` | 100 |  | Construir: créditos, minério (tipo abaixo) e madeira; segundos de engenheiro. |
| `park_ore` | 20 |  |  |
| `park_ore_type` | "ferro" |  |  |
| `park_wood` | 40 |  |  |
| `park_build_time` | 30.0 |  |  |
| `park_radius` | 120.0 |  | Até onde o parque alegra (px do mundo, a partir do parque). |
| `park_rate` | 0.5 |  | Ânimo ganho por segundo por quem está no raio (ao ar livre). |
| `park_cap` | 100.0 |  | O parque só leva o ânimo até aqui (o teto geral é 100). |

## `scripts/core/nivel_mina.gd` (33)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `id` | "S1" |  | Identificador (S1, S2...) e nome na tela. |
| `nome` | "Mina" |  |  |
| `profundidade` | 1 |  | Profundidade (0 = superfície; 1, 2, 3...). Ordem no corte da mina. |
| `area` | "mapa" |  | Onde fica na lógica: "mapa" (a pedreira/vila), "deep" (deep_rect), "abyss" (abyss_rect), um nome próprio com `rect` (Bloco 71: "s4", "s5") ou "" (ainda não existe). |
| `rect` | Rect2() |  | Bloco 71: o retângulo na lógica dos níveis novos (os antigos usam deep_rect/abyss_rect do ambiente). |
| `perigo` | "" |  | Perigo principal: "" (nenhum), "poeira", "gas", "calor", "radiacao", "acido", "agua". |
| `traje` | "" |  | Traje que o perigo pede (equipment.gd: "gas", "calor", "radiacao"; "" = nenhum). |
| `pesquisa` | "" |  | Pesquisa que libera a descida ("" = nenhuma) e o grupo da ligação (elevador) que chega aqui. |
| `ligacao` | "" |  |  |
| `em_breve` | false |  | Declarado mas ainda não jogável (aparece como "em breve"). |
| `minerios` | PackedStringArray() |  | Minérios e criaturas típicos (informativo + conteúdo do Bloco 70). |
| `criaturas` | PackedStringArray() |  |  |
| `cor_ambiente` | Color(1, 1, 1) |  | Atmosfera (Bloco 69): luz ambiente, cor da névoa, partículas ("", "poeira", "acido", "calor", "bolhas", "gotas"). |
| `cor_nevoa` | Color(0, 0, 0, 0) |  |  |
| `particulas` | "" |  |  |
| `mapa_regiao` | Rect2() |  | Bloco 72: onde o nível fica no MAPA DO MUNDO (assets/game/ui/corte/mapa_mundo.png, px da imagem): é ali que aparecem os ipezinhos, as jazidas e o clique do nível. |
| `faixa` | "" |  | Faixa do corte da mina (assets/game/ui/corte/<faixa>.png; "" = cor lisa) e a cor da faixa sem arte. |
| `cor_faixa` | Color(0.2, 0.18, 0.16) |  |  |
| `decoracao` | [] |  | Decoração por dados (Bloco 69): [prop, x, y] na lógica, colocada pelo ambiente quando o nível existe. |
| `decoracao_sorteada` | [] |  | Bloco 72: decoração SORTEADA por dados: [quantas, [props...]] — o ambiente espalha em lugar livre do nível (longe de jazida, poça, gaiola e uma da outra), com sorteio fixo por nível (a mesma em todo jogo). |
| `decalques` | [] |  | Bloco 72: decalques deitados no chão da laje (só visual): [imagem em assets/game/iso/chao, x, y]. Os de nome "rio_lava*" brilham como lava. |
| `perigos` | [] |  | Bloco 70: poças de perigo do chão (props/poca_perigo.gd): [tipo ("acido"/"lava"), x, y, raio]. |
| `jazidas` | [] |  | Bloco 70: jazidas do nível: [minério, x, y] ou [minério, x, y, total, ritmo, regeneração]. Nome fixo no save: Jazida<id>_<n> (JazidaS2_1...). |
| `ligacao_topo` | Vector2.ZERO |  | Bloco 71: a ligação que chega aqui, montada pelo ambiente quando não está na cena (grupo = `ligacao`): a plataforma arruinada fica no nível de cima (`ligacao_topo`), a gaiola de chegada aqui (`ligacao_fundo`); o conserto custa créditos (x), peças raras (y), minério (z, do tipo `conserto_minerio`) e segundos (w), com a vila no estágio `conserto_estagio`. `ligacao_acima` = o grupo da ligação que tem que estar aberta antes. |
| `ligacao_fundo` | Vector2.ZERO |  |  |
| `ligacao_acima` | "" |  |  |
| `conserto` | Vector4i(2000, 14, 150, 120) |  |  |
| `conserto_minerio` | "solarita" |  |  |
| `conserto_estagio` | 5 |  |  |
| `obstaculos` | [] |  | Bloco 71: áreas não andáveis do nível: a ELIPSE dentro de [x, y, w, h] (na lógica: o lago). |
| `animo` | 0.0 |  | Bloco 71: soma no alvo de ânimo de quem está no nível (o lago azul acalma; negativo = pesa), com o motivo que aparece na janela do ipezinho. |
| `animo_motivo` | "" |  |  |
| `titulo_abertura` | "" |  | Bloco 71: a faixa que aparece quando a ligação abre (título; o texto é a descrição). |

## `scripts/core/research.gd` (27)

**Laboratório**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `lab_credits` | 300 |  |  |
| `lab_wood` | 60 |  |  |
| `lab_build_time` | 60.0 |  | Bloco 31b: segundos de engenheiro pra erguer o laboratório. |
| `lab_iron` | 80 |  |  |
| `lab_min_stage` | 2 |  |  |
| `points_per_researcher` | 1.0 |  | Pontos por segundo que cada pesquisador gera no laboratório. |

**Efeitos**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `cargo_bonus` | 0.25 |  |  |
| `explosive_speed` | 1.3 |  |  |
| `explosive_accidents` | 1.25 |  |  |
| `shoring_accidents` | 0.6 |  |  |
| `medicine_heal` | 0.7 |  |  |
| `medicine_untreated` | 1.5 |  |  |
| `radio_joy` | 6.0 |  |  |
| `hydro_regen` | 2.0 |  |  |
| `hydro_food_capacity` | 60.0 |  |  |
| `floodlight_slow` | 0.7 |  |  |
| `floodlight_damage` | 1.3 |  |  |
| `satellite_every_days` | 2 |  |  |

**Dinamite e rádio (Bloco 60)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `dynamite_credits` | 40 |  | Custo de uma dinamite (créditos e carvão) e quantas cabem no paiol. |
| `dynamite_coal` | 15 |  |  |
| `dynamite_max` | 5 |  |  |
| `dynamite_risk_miner` | 0.04 |  | Chance de acidente ao explodir: minerador (sabe mexer) e qualquer outro. |
| `dynamite_risk_untrained` | 0.2 |  |  |
| `dynamite_fuse` | 2.5 |  | Segundos do pavio depois de chegar no entulho; desiste (devolve a dinamite) depois deste tempo andando. |
| `dynamite_walk_timeout` | 60.0 |  |  |
| `radio_warning_bonus` | 60.0 |  | Rádio: o aviso de invasão vem estes segundos antes do normal; com satélite, um colono a cada N dias. |
| `radio_satellite_every_days` | 1 |  |  |

## `scripts/core/save_manager.gd` (3)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `autosave_interval` | 180.0 |  | Segundos entre autosaves (0 = desligado). Padrão: 3 minutos. |
| `save_on_quit` | true |  | Salva sozinho ao fechar a janela. |
| `max_backups` | 5 |  | Quantos backups com data/hora manter em user://backups (o mais antigo, por data, sai). |

## `scripts/core/schedule.gd` (20)

**Agenda (horas do relógio; os marcos ficam no DayNight)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `cafe_fim` | 7.0 |  | Fim do café (o trabalho da manhã começa). 7.0 = 07:00. |
| `almoco_inicio` | 12.0 |  | Almoço: começo e fim. |
| `almoco_fim` | 13.0 |  |  |

**Exceções**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `cozinheiro_inicio` | 4.0 |  | O cozinheiro acorda e começa a cozinhar (o café) a esta hora. |
| `jantar_preparo` | 16.0 |  | Daqui até o anoitecer o cozinheiro prepara o jantar (sem o "voltar" das 18:00). |
| `medico_turno` | 0.5 |  | Horas de cada turno de refeição do médico (o 2º médico come depois do 1º, e assim por diante). |
| `vigilia_fracao` | 0.5 |  | Fração dos guardas de vigia numa noite comum (gira a cada dia; pelo menos 1). Noite de invasão: todos. |

**Refeições**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `porcao` | 8.0 |  | Unidades de comida do comedouro que uma refeição gasta (uma porção). |
| `refeicao_fome` | 45.0 |  | Fome que uma refeição restaura (a fome vai até 100). |
| `refeicao_dispensa` | 0.9 |  | Acima desta fração da fome máxima ele pula a refeição (sem fome; não conta como perdida). |
| `perda_por_refeicao` | 0.12 |  | Quanto o trabalho rende a menos por refeição perdida (0.12 = -12%)... |
| `perda_max` | 3 |  | ...até este tanto de refeições perdidas seguidas. |

**Hora social (Bloco 85)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `conversa_min` | 10.0 |  | Segundos REAIS que ele fica em cada ponto antes de trocar (sorteado entre os dois). |
| `conversa_max` | 22.0 |  |  |
| `animo_por_segundo` | 0.5 |  | Ânimo por segundo conversando com alguém na roda (x animo_mult do ponto)... |
| `animo_max` | 8.0 |  | ...até este tanto (fator "conversou com os amigos" no ânimo)... |
| `animo_decai` | 0.01 |  | ...que vai sumindo devagar depois (por segundo). |
| `balao_min` | 2.0 |  | Intervalo (s) entre um balão e outro de quem está numa roda (sorteado entre os dois). |
| `balao_max` | 4.5 |  |  |
| `passeio_desvio` | 160.0 |  | Passeio: passa por outro ponto no caminho se o desvio for até isto (px do chão). |

## `scripts/core/sun.gd` (17)

**Estações (índice 0 = Primavera)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `semanas_por_estacao` | 2 |  | Bloco 83: semanas (de 7 dias) por estação. |
| `season_wave_chance` | [0.25, 0.5, 0.25, 0.12] |  | Chance POR DIA de ter onda solar, em cada estação (Bloco 83: com estações de 14 dias e dias de 9 min, um pouco menor que antes, pra não virar onda todo dia no verão). |
| `season_hunger_mult` | [1.0, 1.0, 1.0, 1.25] |  |  |
| `season_garden_mult` | [1.3, 1.0, 0.8, 0.5] |  |  |
| `winter_joy` | -3.0 |  | Ânimo no inverno (frio). |

**Ondas solares**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `first_wave_day` | 2 |  |  |
| `onda_hora_min` | 8.0 |  | Bloco 83: a onda chega numa hora sorteada entre estas (horas do relógio; 8.0 = 08:00). |
| `onda_hora_max` | 16.0 |  |  |
| `wave_duration` | 35.0 |  |  |
| `wave_growth` | 0.08 |  | Intensidade cresce isso por dia (o sol está piorando). |
| `warn_time_studied` | 60.0 |  | Aviso antes da onda: com o Estudo da explosão solar / sem. |
| `warn_time_blind` | 10.0 |  |  |
| `rad_per_sec` | 1.0 |  | Radiação por segundo exposto (x intensidade) e quanto acumula até machucar. |
| `rad_hurt_at` | 10.0 |  |  |
| `rad_grave_chance` | 0.25 |  |  |
| `garden_wilt` | 0.3 |  | Fração da comida da horta que murcha em cada onda. |

**Escudo**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `shield_min_stage` | 4 |  | Estágio mínimo da vila pra começar o gerador. |

## `scripts/core/weather.gd` (12)

**Transição**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `fade_speed` | 0.12 |  | Quanto a intensidade de cada efeito anda por segundo (0.12 = de 0 a 1 em ~8 s). |

**Outono: folhas**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `leaf_amount` | 45 |  |  |
| `leaf_fall_speed` | 26.0 |  |  |
| `leaf_drift` | 18.0 |  | Quanto as folhas vão de lado (vento). |

**Inverno: neve**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `snow_amount` | 240 |  |  |
| `snow_fall_speed` | 38.0 |  |  |
| `frost_alpha` | 0.22 |  | Geada no chão da clareira (0 = sem). |

**Chuva**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `rain_amount` | 260 |  |  |
| `rain_fall_speed` | 430.0 |  |  |
| `rain_chance` | [0.5, 0.1, 0.35, 0.0] |  | Chance de um dia ter pancada de chuva, por estação (primavera, verão, outono, inverno). |
| `rain_duration` | Vector2(0.12, 0.3) |  | Duração da pancada (fração do ciclo dia+noite: mínimo, máximo). |

**Verão: pólen**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `pollen_amount` | 18 |  |  |

## `scripts/workers/ipezinho.gd` (74)

**Obras (Bloco 51)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `obra_watchdog_time` | 12.0 |  | Vigia do engenheiro: indo pra obra sem chegar nem 16 px mais perto por esse tempo (s de jogo), procura outro ponto de acesso alcançável (ou o chão andável mais perto da obra) e segue. |

**Movimento**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `speed` | 120.0 |  |  |
| `loaded_speed_penalty` | 0.35 |  |  |
| `starving_speed_mult` | 0.5 |  | Multiplicador de velocidade quando a fome chega a zero. |
| `arrive_distance` | 4.0 |  |  |

**Navegação**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `avoidance_enabled` | true |  | Desvio entre ipezinhos (RVO do NavigationAgent2D). Desligado = atravessam uns aos outros. |
| `avoidance_radius` | 7.0 |  | Raio do ipezinho para o desvio entre agentes. |

**Fome**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `hunger_max` | 100.0 |  |  |
| `hunger_decay` | 0.2 |  | Fome gasta por segundo REAL. Bloco 84 (fome controlada): devagar — 0,2/s = 4,5 por hora de jogo; quem enche são as 3 refeições da agenda (Schedule). (Era 0.8 com o comer contínuo.) |
| `hunger_threshold` | 30.0 |  | Abaixo disso come FORA da hora das refeições (fome braba: uma porção). |
| `eat_until_ratio` | 0.95 |  | Come até atingir essa fração da fome máxima. |

**Turno / casa**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `sleep_hunger_mult` | 0.2 |  | Fração do gasto normal de fome enquanto dorme (0.2 = gasta 20%). Andando pra casa gasta normal. |
| `phase_react_delay` | 1.5 |  | Atraso máximo (s) pra reagir ao anoitecer/amanhecer, pra não saírem todos no mesmo frame. |

**Acidentes**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `injury_chance` | 0.04 |  | Chance de se machucar a cada ciclo de mineração (0.04 = 4%). |
| `mining_cycle_amount` | 16.0 |  | Minério extraído que conta como um "ciclo de mineração" (16 = uma carga cheia). |
| `recovery_time` | 30.0 |  | Só sem Enfermaria na cena (fallback antigo): segundos descansando em casa até curar. Com enfermaria, o tempo de leito vem dela (heal_time_leve / heal_time_grave). |
| `injured_speed_mult` | 0.73 |  | Multiplicador de velocidade enquanto está machucado (mancando). 0.73 -> pior caso (machucado + carga cheia) ≈ 120 x 0.65 x 0.73 ≈ 57 px/s. |
| `branch_injury_chance` | 0.05 |  | Clareira: chance de um galho cair no lenhador a cada ciclo de corte (0.05 = 5%). |
| `chop_cycle_amount` | 8.0 |  | Madeira cortada que conta como um "ciclo de corte" (8 = uma carga cheia do lenhador). |
| `night_chop_injury_mult` | 2.0 |  | Cortar de noite (turno extra, clareira escura) multiplica a chance da queda de galho. |

**Gravidade / enfermaria**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `grave_chance_mine` | 0.2 |  | Chance do acidente ser GRAVE: na mina / queda de galho... |
| `grave_chance_branch` | 0.4 |  |  |
| `deep_grave_bonus` | 0.3 |  | ...e quanto soma no nível 2 (mais fundo, mais feio). |
| `abyss_grave_bonus` | 0.2 |  | No abismo (nível 3) soma mais essa em cima da do nível 2. |
| `leve_untreated_time` | 150.0 |  | Segundos SEM LEITO até o machucado LEVE piorar pra grave... |
| `grave_untreated_time` | 75.0 |  | ...e até o GRAVE morrer. (O relógio pausa enquanto está deitado num leito.) |
| `death_warning_time` | 25.0 |  | Aviso no HUD quando faltar isso pro grave morrer. |

**Equipamento (Bloco 42)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `leather_per_game` | 0.5 |  | Couro que cada unidade de CAÇA rende (fruta não dá couro). Vai pro armazém com a carne. |

**Caído em combate (Bloco 36)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `downed_untreated_time` | 150.0 |  | Guarda que perde a luta cai GRAVE no lugar e não anda. Sem resgate, morre depois de tantos segundos no chão (o relógio PAUSA enquanto o médico carrega: primeiros socorros). |
| `carry_patient_speed_mult` | 0.6 |  | Médico carregando alguém nas costas anda nessa fração da velocidade. |

**Turno extra / zanga**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `anger_gain_per_sec` | 0.8 |  | Zanga ganha por segundo trabalhando à noite em turno extra (0.8 -> ~+48 por noite). |
| `anger_decay_per_sec` | 1.5 |  | Zanga perdida por segundo DORMINDO (em casa, ao relento ou curando). De dia acordado não muda. |
| `anger_irritated_at` | 40.0 |  | A partir dessa zanga fica "irritado"... |
| `anger_furious_at` | 75.0 |  | ...e a partir dessa, "furioso". |
| `irritated_injury_mult` | 2.0 |  | Multiplica a chance de acidente (injury_chance) quando irritado / furioso. |
| `furious_injury_mult` | 4.0 |  |  |
| `irritated_work_mult` | 0.8 |  | Multiplica quanto ele minera por segundo quando irritado / furioso. |
| `furious_work_mult` | 0.55 |  |  |
| `irritated_speed_mult` | 0.95 |  | Multiplica a velocidade de caminhada (acumula com carga, fome e lesão). |
| `furious_speed_mult` | 0.85 |  |  |

**Felicidade**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `happiness_start` | 70.0 |  | Felicidade de quem nasce (jogo novo / recrutado). |
| `happiness_base` | 60.0 |  | Ponto de partida do alvo, antes de somar os motivos (cama, fome, zanga...). |
| `happiness_drift` | 0.25 |  | Quanto a felicidade anda por segundo em direção ao alvo. |
| `leisure_below` | 40.0 |  | Abaixo disso vai pra taverna (se existir) e fica lá até leisure_until. |
| `leisure_until` | 85.0 |  |  |
| `happy_at` | 75.0 |  | Faixas: feliz >= happy_at; triste < sad_below; revoltado < miserable_below. |
| `sad_below` | 40.0 |  |  |
| `miserable_below` | 25.0 |  |  |
| `happy_work_mult` | 1.1 |  | Multiplica a produção (minerar/cortar) em cada faixa. |
| `sad_work_mult` | 0.8 |  |  |
| `miserable_work_mult` | 0.6 |  |  |

**Guarda**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `guard_base_hp` | 30.0 |  | Vida na luta = base + por_habilidade x habilidade (0..1). Zerou: machuca e sai da luta. |
| `guard_hp_per_skill` | 20.0 |  |  |
| `guard_aggro` | 200.0 |  | Distância em que o guarda vê uma criatura e parte pra cima. |
| `guard_attack_interval` | 1.0 |  |  |
| `untrained_damage_mult` | 0.5 |  | Sem treino o guarda bate com metade da força (habilidade 0 -> x0.5, 100% -> x1). |

**Robô antigo**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `carry_robot_speed_mult` | 0.6 |  | Carregando o robô anda nessa fração da velocidade. |

**Cozinheiro**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `cook_carry` | 12.0 |  | Matéria-prima que o cozinheiro carrega por viagem (armazém -> comedouro). Bloco 27. |
| `prep_time_per_raw` | 0.8 |  | Segundos de preparo por unidade de matéria-prima (12 unidades x 0.8 = ~10 s por leva). |
| `food_per_raw` | 1.25 |  | Comida pronta que cada unidade de matéria-prima rende no comedouro. Bloco 33: cozinhar RENDE — 1.25 = 10 de matéria-prima viram 12,5 de ração (era 1.0, sem ganho nenhum). |

**Caçador**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `hunter_carry` | 10.0 |  | Quantas unidades (fruta ou caça) o caçador carrega por viagem. Cada unidade de caça vale mais matéria-prima (meat_raw_value da toca), por isso caçar rende mais por viagem. |

**Lenhador**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `lumber_carry` | 8.0 |  | Madeira que o lenhador carrega por viagem (árvore -> armazém). |

**Carga**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `cargo_capacity` | 16.0 |  | Minério por viagem (ritmo: era 20). |
| `mochila_carga` | 4.0 |  | Bloco 94: minério a mais por viagem com a MOCHILA de couro (o minerador pega uma no armazém). |

**IA**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `auto_mode` | true |  |  |
| `decision_interval` | 1.0 |  |  |
| `manual_override_time` | 6.0 |  | Segundos que a IA espera depois de uma ordem manual antes de voltar a decidir. Só começa a contar quando ele CHEGA no destino (a caminhada não gasta esse tempo). |
| `idle_wander_radius` | 50.0 |  | Distância máxima de um passeio aleatório quando está ocioso. |

**Visual**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `walk_anim_fps` | 13.0 |  | Bloco 73: 13 quadros/s na velocidade normal = o passo da vista iso (IsoBillboard.PASSO_CICLO: 4 quadros a cada 56 px de arte = ~37 px daqui); o som do passo cai junto com o pé. |
| `head_lamp_enabled` | true |  |  |
| `motivo_espera` | 2.0 |  | Segundos parado pelo MESMO motivo antes de o balão aparecer (não pisca a cada troca de tarefa). |
| `motivo_intervalo` | 0.5 |  | A cada quantos segundos o motivo é conferido (barato: só olha o estado que a IA já decidiu). |
| `carga_material` | 10.0 |  | Quanto o engenheiro leva por viagem (unidades de material: madeira, minério, barras, tábuas, pregos...). |
| `material_alcance` | 40.0 |  | Distância (px) em que ele "chegou" no armazém pra pegar o material. |

## `scripts/props/abyss_shaft.gd` (13)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `bottom_position` | Vector2(-360, 1500) |  | Onde fica a gaiola de chegada lá embaixo (coordenadas do mundo, dentro do abismo). |
| `link_travel_cost` | 0.05 |  |  |

**Andar (Bloco 71)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `grupo` | "elevador_abismo" |  | A mesma plataforma serve de ligação pros níveis novos (montada pelo ambiente a partir do .tres): grupo próprio, o nível que ela abre e a ligação de cima que tem que estar aberta antes. |
| `nivel_id` | "S3" |  |  |
| `requer_grupo` | "elevador" |  |  |
| `repair_ore` | "prata" |  | Minério gasto no conserto (o do abismo é prata). |

**Conserto**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `repair_parts` | 12 |  |  |
| `repair_credits` | 1500 |  |  |
| `repair_silver` | 150 |  |  |
| `repair_time` | 120.0 |  |  |
| `repair_min_stage` | 4 |  | Estágio mínimo da vila pra começar o conserto. |

**Viagem (Bloco 68)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `travel_time` | 1.6 |  | Segundos na gaiola por viagem e quantos cabem nela de uma vez (mais gente = espera a próxima). |
| `capacity` | 4 |  |  |

## `scripts/props/armazem.gd` (4)

**Ritmo**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `DEPOSIT_RATE` | 8.0 |  | Minério descarregado por segundo por ipezinho (era 10.0). |

**Visual e som**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `pile_thresholds` | [1.0, 60.0, 200.0] |  | Quantidade armazenada para cada estágio da pilha de minério (1, 2, 3). |
| `popup_interval` | 0.8 |  | Intervalo entre os textos flutuantes "+N". |
| `deposit_sound_interval` | 0.5 |  | Intervalo entre os sons de minério caindo na pilha enquanto alguém deposita. |

## `scripts/props/arsenal.gd` (1)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `forge_sound_interval` | 0.9 |  | Intervalo entre as marteladas enquanto forja. |

## `scripts/props/barricada.gd` (11)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `gate_id` | "tunel" |  |  |
| `vertical` | false |  | Bloco 74: o portão numa paliçada de norte a sul (a vila fica a leste): a arte vira de lado. |
| `display_name` | "Portão do túnel" |  |  |
| `hp_per_level` | [0.0, 120.0, 260.0, 450.0] |  | Vida por nível (índice = nível). |
| `upgrade_costs` | [Vector3i.ZERO, Vector3i(80, 0, 60), Vector3i(250, 120, 40), Vector3i(500, 170, 30)] |  | Ampliar pro nível i: x = créditos, y = minério, z = madeira. (índice 0 não usado) Bloco 94: o nível 3 baixou de 200 pra 170 ferro (85 barras) e pede pregos e ferragens (upgrade_itens). |
| `upgrade_ore` | ["", "", "ferro", "ferro"] |  | Minério gasto em cada nível ("" = qualquer). |
| `upgrade_itens` | [{}, {}, {}, {"prego": 12, "ferragem": 4}] |  | Bloco 94: itens a mais de cada nível ({item: qtd}); antes da fornalha, pregos e ferragens viram ferro (Economy). |
| `repair_wood_per_hp` | 0.25 |  | Madeira gasta por ponto de vida consertado. |
| `upgrade_tempos` | [0.0, 30.0, 45.0, 60.0] |  | Bloco 96: segundos de engenheiro pra subir pro nível i (índice 0 não usado). |
| `conserto_na_hora` | 10.0 |  | Bloco 96: conserto de até esta madeira é feito NA HORA (pequeno); acima, vira obra de engenheiro. |
| `conserto_segundos_por_madeira` | 0.8 |  | Bloco 96: segundos de engenheiro por unidade de madeira do conserto grande. |

## `scripts/props/campo_treino.gd` (1)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `train_rate` | 0.009 |  | Habilidade ganha por segundo treinando (1.0 = 100%). 0.009 -> ~110 s pra ficar pronto. |

## `scripts/props/carpintaria.gd` (1)

**Receitas da carpintaria (Bloco 94)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `receitas_carpintaria` | [ |  | {id, nome, insumos {item: qtd}, produto {item: qtd}, segundos (de carpinteiro por unidade), estagio}. |

## `scripts/props/casa.gd` (16)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `built` | true |  | false = lote vazio (formato antigo; hoje as casas novas são posicionadas pelo jogador). |
| `placed_by_player` | false |  | true = casa nova que o jogador posicionou (a posição vai pro save; as 3 iniciais são fixas). |
| `starter_house` | false |  | Bloco 37: casa inicial da fundação (não soma no limite de ipezinhos quando fica pronta). |

**Níveis (Bloco 56)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `max_nivel` | 3 |  |  |
| `beds_by_level` | [4, 6, 8] |  | Camas e conforto (ânimo de quem mora) por nível: [nível 1, nível 2, nível 3]. |
| `comfort_by_level` | [0.0, 4.0, 8.0] |  |  |
| `upgrade_credits` | [0, 220, 420] |  | Custo pra CHEGAR em cada nível [nível 1 (não usado), nível 2, nível 3]: créditos, ferro, madeira, segundos de engenheiro. |
| `upgrade_ore` | [0, 40, 70] |  | Bloco 94: o nível 3 baixou de 90 pra 70 ferro (o resto vai em pregos e ferragens: upgrade_pregos/upgrade_ferragens). |
| `upgrade_wood` | [0, 40, 70] |  |  |
| `upgrade_seconds` | [0.0, 40.0, 60.0] |  |  |
| `upgrade_pregos` | [0, 0, 24] |  | Bloco 94: pregos e ferragens pra chegar em cada nível [1, 2, 3] (antes da fornalha viram ferro: Economy). |
| `upgrade_ferragens` | [0, 0, 2] |  |  |

**Camas de tábua (Bloco 94)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `conforto_cama_boa` | 3.0 |  | Ânimo de quem dorme numa cama de tábua (soma no conforto da casa). |
| `cama_segundos` | 12.0 |  | Segundos de carpinteiro pra montar uma cama na casa. |
| `level_min_stage` | [0, 2, 3] |  | Pré-requisitos de cada nível [nível 1, 2, 3]: estágio mínimo do Centro da Vila e pesquisa ("" = nenhuma). |
| `level_research` | ["", "", "medicina"] |  |  |

## `scripts/props/centro_vila.gd` (76)

**Estágios da vila**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `level_ore_required` | [0, 375, 1250, 3100, 6250] |  | Minério coletado no total pra chegar em cada estágio (índice 0 = estágio 1). |
| `level_credit_cost` | [0, 190, 625, 1500, 3100] |  | Créditos pra expandir pra cada estágio (índice 0 = estágio 1, não usado). |

**Melhoria: Moradias**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `moradias_costs` | [Vector2i(190, 40), Vector2i(375, 60), Vector2i(750, 150), Vector2i(1250, 310)] |  | Custo de cada nível: x = créditos, y = minério do armazém. Casa = créditos (x) + PEDRA (y). "Pedra" = minério de ferro (Bloco 13: o jogo não tem um recurso pedra separado; o ferro é a rocha que a mina já dá). |
| `moradias_wood` | [20, 30, 45, 60] |  | Madeira de cada casa (por nível de Moradias). |
| `house_stone_ore` | "ferro" |  | Minério usado como "pedra" nas casas. |
| `workers_per_moradia` | 4 |  |  |

**Melhoria: Enfermaria**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `enfermaria_costs` | [Vector2i(125, 25), Vector2i(310, 75), Vector2i(625, 190)] |  |  |
| `recovery_cut_per_level` | 0.2 |  | Fração do tempo de cura cortada por nível (0.2 = -20% por nível). |

**Melhoria: Trilhas batidas**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `trilhas_costs` | [Vector2i(150, 25), Vector2i(375, 100), Vector2i(810, 250)] |  |  |
| `speed_bonus_per_level` | 0.1 |  | (Antes do Bloco 89: velocidade extra pra todo mundo por nível. Não é mais usado; fica pro save/inspector.) |
| `trilhas_bonus_por_nivel` | 0.5 |  | Bloco 89: quanto cada nível de Trilhas aumenta o bônus de velocidade dos CAMINHOS (0.5 = +50% do bônus). |

**Obras (Bloco 31)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `enfermaria_build_times` | [30.0, 45.0, 60.0] |  | Segundos de trabalho de engenheiro pra cada nível de cada melhoria. |
| `trilhas_build_times` | [25.0, 40.0, 55.0] |  |  |
| `house_build_times` | [35.0, 45.0, 55.0, 65.0] |  | Segundos de trabalho de engenheiro pra erguer cada casa (por nível de Moradias). |
| `expand_build_times` | [60.0, 90.0, 120.0, 150.0] |  | Bloco 31b: segundos de engenheiro pra EXPANDIR a vila (estágio 2, 3, 4, 5). |

**Fundação (Bloco 37)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `starter_houses` | 3 |  | Casas iniciais da partida nova (fora das Moradias; não somam no limite de ipezinhos). |
| `starter_house_cost` | Vector3i(80, 20, 15) |  | Custo de cada casa inicial: x = créditos, y = pedra (ferro), z = madeira. |
| `starter_house_build_time` | 25.0 |  |  |
| `comedouro_cost` | Vector3i(100, 20, 25) |  | Comedouro novo: x = créditos, y = ferro, z = madeira; e segundos de engenheiro. |
| `comedouro_build_time` | 20.0 |  |  |
| `founding_credits` | 400 |  | Pacote que entra quando a vila é fundada (dá pras 3 casas + 1 comedouro, com folga). |
| `founding_ore` | 90 |  |  |
| `founding_wood` | 80 |  |  |

**Coletor de madeira (Bloco 45)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `coletor_credits` | 250 |  | Construir: créditos e ferro (não gasta madeira: é ele que faz madeira); segundos de engenheiro. |
| `coletor_ore` | 60 |  |  |
| `coletor_build_time` | 40.0 |  |  |

**Igreja (Bloco 88)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `igreja_credits` | 220 |  | Construir a igreja (uma por vila): créditos, pedra (ferro) e madeira; segundos de engenheiro. |
| `igreja_ore` | 40 |  |  |
| `igreja_wood` | 80 |  |  |
| `igreja_build_time` | 50.0 |  |  |
| `igreja_estagio` | 2 |  | Estágio mínimo da vila pra construir. |

**Cemitério (Bloco 93)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `cemiterio_credits_base` | 40 |  | O jogador marca o tamanho: o custo é por VAGA (túmulo) e por TRECHO de cerca (24 px); a obra também. |
| `cemiterio_credits_por_vaga` | 6 |  |  |
| `cemiterio_wood_por_trecho` | 3 |  |  |
| `cemiterio_ore_por_trecho` | 1 |  |  |
| `cemiterio_segundos_base` | 12.0 |  |  |
| `cemiterio_segundos_por_trecho` | 1.2 |  |  |
| `cemiterio_max_trechos` | Vector2i(10, 8) |  | Tamanho em trechos de cerca (mínimo 3 x 2 sempre; máximo aqui). |
| `cemiterio_estagio` | 2 |  | Estágio mínimo da vila. |

**Fornalha (Bloco 86)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `fornalha_credits` | 180 |  | Construir a fornalha: SÓ créditos e minério (madeira nenhuma: não trava o começo); segundos de engenheiro. |
| `fornalha_ore` | 50 |  |  |
| `fornalha_build_time` | 35.0 |  |  |
| `fornalha_estagio` | 2 |  | Estágio da vila em que a fornalha libera (2 = Vilarejo). |

**Carpintaria (Bloco 94)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `carpintaria_credits` | 220 |  | Construir a carpintaria: créditos, ferro e madeira; segundos de engenheiro (obra em etapas). |
| `carpintaria_ore` | 40 |  |  |
| `carpintaria_wood` | 90 |  |  |
| `carpintaria_build_time` | 45.0 |  |  |
| `carpintaria_estagio` | 2 |  | Estágio da vila em que a carpintaria libera (2 = Vilarejo: os pregos vêm do ferreiro, que vem com a fornalha). |

**Oficina (Bloco 58)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `oficina_credits` | 200 |  |  |
| `oficina_ore` | 40 |  |  |
| `oficina_wood` | 60 |  |  |
| `oficina_build_time` | 40.0 |  |  |

**Desbravar o leste (Bloco 67)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `leste_credits` | 900 |  |  |
| `leste_ore` | 120 |  |  |
| `leste_wood` | 160 |  |  |
| `leste_build_time` | 80.0 |  |  |
| `leste_min_stage` | 2 |  |  |

**Trilho e vagonete (Bloco 64)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `vagonete_credits` | 260 |  |  |
| `vagonete_ore` | 80 |  |  |
| `vagonete_wood` | 80 |  |  |
| `vagonete_build_time` | 50.0 |  |  |

**Ferrovia de carga (Bloco 79)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `ferrovia_base` | Vector4i(300, 40, 100, 60) |  | Custo da estação de cada andar: base + por andar de profundidade (créditos, ferro, madeira, segundos de obra). Bloco 94: o ferro vira barra a partir do estágio da fornalha (Economy.metal) e a estação pede pregos e ferragens (os dormentes e as talas dos trilhos): o ferro baixou pra compensar. |
| `ferrovia_por_andar` | Vector4i(150, 25, 20, 15) |  |  |
| `ferrovia_pecas_base` | Vector2i(18, 0) |  | Pregos e ferragens da estação: base + por andar de profundidade (x = pregos, y = ferragens). |
| `ferrovia_pecas_por_andar` | Vector2i(6, 1) |  |  |

**Coletor de minério (Bloco 57)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `coletor_min_credits` | 280 |  |  |
| `coletor_min_ore` | 40 |  |  |
| `coletor_min_wood` | 60 |  |  |
| `coletor_min_build_time` | 45.0 |  |  |

**Enfermaria extra (Bloco 47)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `enfermaria_extra_credits` | 200 |  | Custo da 1ª enfermaria extra (a da vila é de graça); as seguintes crescem com Economy.extra_building_cost_growth. Segundos de engenheiro pra erguer. |
| `enfermaria_extra_ore` | 40 |  |  |
| `enfermaria_extra_wood` | 60 |  |  |
| `enfermaria_extra_build_time` | 45.0 |  |  |

**Raio das casas (Bloco 37)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `house_radius_base` | 230.0 |  | Casa só pode ser posicionada até essa distância do Centro da Vila no estágio 1... |
| `house_radius_per_stage` | 70.0 |  | ...e o raio cresce isso a cada estágio da vila. |
| `house_radius_enabled` | false |  | false = sem limite (casa em qualquer lugar livre da mina). Prompt 29 (decisão do Marco, 2026-10-01): DESLIGADO — casa em qualquer lugar da pedreira (o lado da vila da paliçada), não precisa ficar perto do Centro. O parque também (usa o mesmo raio). |

## `scripts/props/coletor_madeira.gd` (7)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `wood_per_sec` | 0.6 |  | Madeira por segundo com o operador no posto (antes da zanga/ânimo dele). |

**Restauração (Bloco 81)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `fixo` | false |  | A ruína da cena (o primeiro coletor): começa em `etapa_inicial` e salva a etapa no save do Centro da Vila. |
| `etapa_inicial` | 4 |  | Etapa em que ele nasce (0 = ruína; os extras construídos nascem funcionando). |
| `etapa_nomes` | PackedStringArray(["Ruína", "Limpar folhas e entulho", "Desenferrujar", |  | Nome de cada etapa (índice = etapa). |
| `etapa_custo` | [Vector3i.ZERO, Vector3i(0, 0, 30), Vector3i(0, 45, 0), Vector3i(180, 50, 0), Vector3i.ZERO] |  | Custo de cada etapa (índice 1..3): x = créditos, y = ferro, z = madeira. |
| `etapa_segundos` | PackedFloat32Array([0.0, 25.0, 35.0, 45.0, 0.0]) |  | Segundos de engenheiro de cada etapa (índice 1..3). |
| `etapa_estagio` | PackedInt32Array([0, 0, 0, 0, 0]) |  | Estágio mínimo da vila pra pedir cada etapa (índice 1..3; 0 = qualquer). |

## `scripts/props/coletor_minerio.gd` (2)

**Coleta (Bloco 57)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `ore_per_sec` | 0.5 |  | Minério por segundo com o operador no posto (antes da zanga/ânimo dele). |
| `reach` | 230.0 |  | Até onde a broca alcança uma jazida (px da lógica). |

## `scripts/props/comedouro.gd` (6)

**Ritmo**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `FEED_RATE` | 12.0 |  | Fome restaurada por segundo por ipezinho comendo. |
| `hunger_per_food` | 5.0 |  | Quanta fome cada unidade de comida repõe (5 -> uma refeição de 30 a 95 gasta ~13 de comida). |
| `DELIVER_RATE` | 8.0 |  | Comida descarregada por segundo pelo cozinheiro. |

**Estoque**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `food_capacity` | 120.0 |  | Máximo de comida guardada. |
| `start_food` | 60.0 |  | Comida no começo de um jogo novo. |

**Som**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `eat_sound_interval` | 0.9 |  | Intervalo entre os sons de mastigar enquanto alguém come. |

## `scripts/props/deep_shaft.gd` (4)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `bottom_position` | Vector2(440, 790) |  | Onde fica a gaiola de chegada lá embaixo (coordenadas do mundo, dentro do nível 2). |
| `link_travel_cost` | 0.05 |  | Custo de navegação da descida (baixo = os ipezinhos acham que "descer é perto"). |

**Viagem (Bloco 68)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `travel_time` | 1.6 |  | Segundos na gaiola por viagem e quantos cabem nela de uma vez (mais gente = espera a próxima). |
| `capacity` | 4 |  |  |

## `scripts/props/enfermaria.gd` (7)

**Leitos e cura**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `base_beds` | 2 |  |  |
| `beds_per_level` | 1 |  |  |
| `heal_time_leve` | 20.0 |  | Segundos NO LEITO pra curar cada gravidade. A melhoria "Enfermaria" do Centro da Vila corta esse tempo (recovery_cut_per_level, lá no Centro da Vila). |
| `heal_time_grave` | 45.0 |  |  |

**Médico (Bloco 30)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `doctor_heal_bonus` | 1.5 |  | Sem médico a cura é a de sempre (passiva). Cada médico LÁ DENTRO soma essa velocidade de cura aos internados (1.5 = +150%: um grave de 45 s cura em ~18 s). |
| `max_doctors_effective` | 2 |  | Quantos médicos somam bônus ao mesmo tempo (os outros ficam de reserva). |
| `doctor_waiting_clock_mult` | 0.5 |  | Com médico lá dentro, o relógio de "sem cuidado" de quem espera leito na porta corre nessa fração (0.5 = metade: demora o dobro pra piorar/morrer). |

## `scripts/props/escavadeira.gd` (15)

**Peças (na ordem de PART_IDS)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `part_costs` | [ |  | Custo de cada peça: x = créditos, y = minério do armazém, z = segundos de fabricação. |
| `part_min_stage` | [2, 3, 3, 3, 4] |  | Estágio mínimo da vila pra fabricar cada peça. |

**Reatores (na ordem de REACTOR_IDS)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `reactor_rates` | [0.3, 0.55, 0.35, 0.9, 1.5] |  | Minério por segundo que a broca manda pro armazém com cada reator. |
| `reactor_costs` | [ |  | Construir: x = créditos, y = ferro, z = peças raras. (A Caldeira vem com a escavadeira.) |
| `reactor_build_times` | [0.0, 40.0, 60.0, 60.0, 90.0] |  | Bloco 31b: segundos de engenheiro pra montar cada reator (a Caldeira vem pronta). |
| `vapor_coal_per_sec` | 0.08 |  | Caldeira: carvão gasto por segundo. |
| `diesel_noise` | 4.0 |  | Diesel: ânimo a menos pra todos enquanto liga. |
| `cristal_find_mult` | 2.0 |  | Cristal: multiplica a chance de achado. |
| `solar_accident_mult` | 1.5 |  | Solar: multiplica a chance de acidente na mina. |
| `fusao_check_interval` | 60.0 |  | Fusão: a cada fusao_check_interval s, fusao_meltdown_chance de pane. |
| `fusao_meltdown_chance` | 0.08 |  |  |
| `fusao_outage` | 90.0 |  | Segundos desligada depois da pane, e raio da explosão (machuca grave). |
| `fusao_blast_radius` | 150.0 |  |  |

**Efeitos**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `forge_sound_interval` | 0.8 |  | Intervalo entre as marteladas enquanto fabrica. |
| `drill_fps` | 8.0 |  | Velocidade da animação da broca quando pronta (quadros por segundo). |

## `scripts/props/escudo.gd` (7)

**Etapas (na ordem de STAGE_IDS)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `stage_costs` | [ |  | x = créditos, y = minério, z = segundos de obra. Bloco 94: as bobinas baixaram de 150 pra 110 cobre e levam aço da Fundição (stage_itens). |
| `stage_ore` | ["ferro", "cobre", "solarita", "prata"] |  |  |
| `stage_wood` | [100, 0, 0, 0] |  | Extras: madeira (fundação), prata (bobinas), peças raras (núcleo), solarita (emissor). |
| `bobinas_silver` | 80 |  |  |
| `nucleo_parts` | 15 |  |  |
| `emissor_solarita` | 100 |  |  |
| `stage_itens` | [{}, {"aco": 20}, {}, {}] |  | Bloco 94: itens a mais de cada etapa ({item: qtd}), na ordem de STAGE_IDS. |

## `scripts/props/estacao_vagonete.gd` (8)

**Vagonete (Bloco 64)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `buffer_capacity` | 60.0 |  | Minério que o ponto guarda esperando o vagonete, e quanto o vagonete leva por viagem. |
| `cart_capacity` | 25.0 |  |  |
| `cart_speed` | 55.0 |  | Velocidade do vagonete (px da lógica / s) e quanto espera juntar carga antes de sair. |
| `cart_wait` | 8.0 |  |  |
| `rail_trips` | 25 |  | Viagens até o trilho quebrar e segundos de engenheiro pra consertar. |
| `repair_seconds` | 20.0 |  |  |
| `rota_fixa` | false |  | Bloco 74: o da mina (fixo): o trilho sai do batente da boca, desce reto e vira pra porta do armazém (em vez do caminho da navegação). |
| `ferrovia` | "" |  | Bloco 79: FERROVIA DE CARGA — o id do andar (S2..S5) onde fica a estação ("" = o vagonete comum). O trilho no chão é só o pedaço até a doca; o resto da viagem é a SUBIDA pelo cavalete até a superfície (a vista iso desenha o cavalete e o carrinho subindo), e a carga vai pro armazém. |

## `scripts/props/food_source.gd` (5)

**Colheita**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `HARVEST_RATE` | 3.0 |  | Comida colhida por segundo por cozinheiro. |
| `food_total` | 150.0 |  | Comida total quando a horta está cheia. |
| `regen_rate` | 0.35 |  | Comida que volta a crescer por segundo (0 = não regenera). |
| `depleted_cooldown` | 25.0 |  | Segundos "colhida" depois de esgotar, antes de começar a regenerar. |
| `min_food_to_harvest` | 5.0 |  | Abaixo disso a horta não atrai cozinheiros novos. |

## `scripts/props/fornalha.gd` (3)

**Receitas (Bloco 86)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `receitas` | [ |  | {id, nome, insumos {item: qtd}, produto {item: qtd}, segundos (de fundidor por unidade), estagio (mínimo da vila; 0 = qualquer)}. Itens = ids do items.gd. |
| `max_fila` | 4 |  | Máximo de ordens na fila. |
| `lote` | 2 |  | Unidades que o fundidor começa (pega os insumos) por viagem ao armazém. |

## `scripts/props/hazard_zone.gd` (3)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `kind` | "gas" | **"gas"** (main.tscn); **"radiacao"** (main.tscn); **"calor"** (main.tscn) |  |
| `radius` | 90.0 | **85.0** (main.tscn); **80.0** (main.tscn); **80.0** (main.tscn) | Raio da zona (px do mundo), achatado na vertical como o resto do mapa. |
| `sign_offset` | Vector2(-70, 60) | **Vector2(-95, 10)** (main.tscn); **Vector2(95, 20)** (main.tscn); **Vector2(-95, -10)** (main.tscn) | Onde fica a placa (em relação ao centro): a "entrada". |

## `scripts/props/hunt_spot.gd` (16)

**Caça**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `HUNT_RATE` | 1.0 |  | Unidades de caça por segundo por caçador. |
| `game_total` | 20.0 |  | Caça total quando a toca está cheia. |
| `regen_rate` | 0.04 |  | Caça que volta por segundo (a horta volta 0.35/s: aqui é bem mais lento). |
| `depleted_cooldown` | 90.0 |  | Segundos vazia depois de esgotar, antes de começar a regenerar. |
| `min_game_to_hunt` | 4.0 |  | Abaixo disso a toca não atrai caçadores novos. |
| `meat_raw_value` | 2.5 |  | Matéria-prima que cada unidade de caça rende (uma unidade de fruta rende 1). |
| `required_tool` | "arco" |  | Ferramenta da Oficina exigida pra caçar aqui. |

**Bichos (Bloco 61)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `animal` | "coelho" |  | "coelho" ou "javali" (javali: mais carne, menos bichos, nasce mais devagar, pode ferir). |
| `max_animals_by_kind` | [4, 2] |  | Por tipo: [coelho, javali]. |
| `meat_by_kind` | [4.0, 12.0] |  |  |
| `spawn_every_by_kind` | [45.0, 120.0] |  |  |
| `season_spawn_mult` | [1.0, 1.2, 0.8, 0.3] |  | Ritmo de nascer por estação (primavera, verão, outono, inverno) e o limite no inverno. |
| `winter_max_mult` | 0.5 |  |  |
| `javali_risk_novice` | 0.3 |  | Javali fere o caçador: chance por javali caçado, novato x experiente (abates pra deixar de ser novato). |
| `javali_risk_expert` | 0.05 |  |  |
| `javali_xp` | 5 |  |  |

## `scripts/props/igreja.gd` (2)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `rodas_bancos` | 6 |  | Bancos (lugares) na frente da igreja: rodas x lugares por roda. |
| `lugares_por_banco` | 4 |  |  |

## `scripts/props/mineral_node.gd` (11)

**Mineração**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `ore_type` | "ferro" |  | Tipo de minério desta jazida: "ferro", "cobre" ou "carvao". |
| `MINE_RATE` | 3.0 |  | Minério tirado por segundo por ipezinho (ritmo: era 4.0). |
| `ore_total` | 200.0 |  |  |
| `regen_rate` | 0.45 |  | Minério regenerado por segundo (0 = não regenera). |
| `depleted_cooldown` | 20.0 |  | Segundos "morta" depois de esgotar, antes de começar a regenerar. |
| `min_ore_to_mine` | 15.0 |  | Abaixo disso a jazida não atrai novos ipezinhos (quem já está minerando continua). |

**Zona de perigo (Bloco 42)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `hazard` | "" |  | Jazida dentro de uma zona de perigo (hazard_zone.gd): só minera quem veste o traje certo. "" = jazida comum; "gas", "calor" ou "radiacao" = precisa do traje desse perigo. |

**Galeria lacrada (Bloco 33)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `min_village_level` | 1 |  | Estágio da vila que abre esta jazida (1 = aberta desde o começo). |
| `gallery_name` | "" |  | Nome da galeria pros avisos ("oeste", "sudeste"...). |

**Visual**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `textures` | [] | **(recurso)** (mineral_node.tscn) | Variantes de sprite sorteadas no _ready (vazio = mantém a textura da cena). |
| `min_visual_scale` | 0.6 |  |  |

## `scripts/props/oficina.gd` (11)

**Ferramentas (na ordem de TOOL_IDS)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `tool_costs` | [ |  | x = créditos, y = quantidade de minério, z = segundos na forja. |
| `tool_ore_types` | ["ferro", "cobre", "carvao", "prata", "ferro", "ferro"] |  | Tipo do minério gasto em cada ferramenta. |
| `tool_wood_costs` | [30, 25, 40, 30, 35, 20] |  | Madeira gasta em cada ferramenta (cabo/estrutura) — referência: 1 madeira pra 5 minério. |
| `tool_min_stage` | [1, 2, 4, 4, 1, 3] |  | Estágio mínimo da vila (Centro da Vila) pra fabricar cada ferramenta. |
| `tool_itens` | {"picareta_de_aco": {"aco": 12}} |  | Bloco 94: itens a mais de cada ferramenta (id -> {item: qtd}). A picareta de aço leva aço da Fundição. |
| `picareta_aco_mult` | 1.25 |  | Bloco 94: minério por golpe com a picareta de aço (1.25 = +25%), pra todos os mineradores. |

**Encomendas do ferreiro (Bloco 87)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `receitas_ferreiro` | [ |  | Pregos e ferragens: só por ORDEM (quantidade do jogador), o FERREIRO faz aqui; os insumos saem do armazém quando cada unidade começa e o produto vai pro armazém. (Ferramentas, armas e equipamentos são as filas de sempre — Oficina, Arsenal, Equipment —, agora feitas pelo ferreiro.) |
| `max_fila_ferreiro` | 4 |  | Máximo de ordens na fila do ferreiro. |

**Efeitos**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `forge_sound_interval` | 0.7 |  |  |
| `idle_forge_energy` | 0.45 |  |  |
| `active_forge_energy` | 1.1 |  |  |

## `scripts/props/poca_perigo.gd` (2)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `kind` | "acido" |  |  |
| `radius` | 44.0 |  | Raio (px da lógica), achatado na vertical como o resto do mapa. |

## `scripts/props/robo.gd` (11)

**Conserto**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `repair_parts` | 6 |  |  |
| `repair_credits` | 400 |  |  |
| `repair_ore` | 60 |  |  |
| `repair_time` | 90.0 |  |  |

**Guarda**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `patrol_speed` | 42.0 |  |  |
| `post_offset` | Vector2(78, 46) |  | Posto de dia, em relação ao Centro da Vila. |
| `guard_bonus` | 5.0 |  | Felicidade somada no alvo de todos com o guarda ativo. |
| `robot_max_hp` | 80.0 |  | Luta: vida, dano, ritmo e distância em que vê as criaturas. Zerou a vida: desliga até de manhã. |
| `robot_damage` | 9.0 |  |  |
| `robot_attack_interval` | 1.2 |  |  |
| `robot_aggro` | 220.0 |  |  |

## `scripts/props/social_spot.gd` (9)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `tipo` | "praca" |  | "refeitorio", "praca", "taverna", "parque", "banco", "fogueira", "igreja". |
| `nome` | "Praça" |  | Nome pra janela/rótulo ("Praça", "Refeitório"...). |
| `coberto` | false |  | Coberto: vale com chuva e onda solar. |
| `rodas` | 2 |  | Quantas rodas de conversa e quantos lugares em cada. |
| `por_roda` | 3 |  |  |
| `raio_roda` | 18.0 |  | Distância (px do chão) do centro da roda até cada lugar; e entre os centros das rodas. |
| `espaco_rodas` | 62.0 |  |  |
| `deslocamento` | Vector2(0, 44) |  | Onde ficam as rodas em relação ao dono (na frente do prédio = +y). |
| `animo_mult` | 1.0 |  | Multiplica o ânimo de conversar aqui (taverna e igreja animam mais). |

## `scripts/props/station.gd` (9)

**Slots**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `slot_count` | 3 |  |  |
| `slot_radius` | Vector2(28, 20) |  | Raio (elíptico) onde ficam os slots, em pixels. |
| `slot_arc_deg` | 360.0 |  | Abertura do arco de slots, em graus (360 = volta inteira). |
| `slot_arc_center_deg` | 90.0 |  | Direção central do arco, em graus (90 = para baixo/frente da estação). |
| `auto_fit_area` | true |  | Ajusta sozinho o raio da área de interação para cobrir os slots. |
| `area_margin` | 12.0 |  |  |

**Obstáculo (navegação)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `obstacle_size` | Vector2.ZERO |  | Meia-largura/meia-altura da "base" que bloqueia a passagem. Zero = não bloqueia. |
| `obstacle_offset` | Vector2.ZERO |  |  |
| `obstacle_is_rect` | false |  | true = retângulo; false = elipse. |

## `scripts/props/taverna.gd` (4)

**Lugares e diversão**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `seats_per_level` | [3, 5] |  | Lugares no balcão por nível (índice 0 = nível 1). |
| `fun_per_level` | [3.0, 4.5] |  | Felicidade ganha por segundo lá dentro, por nível. |
| `note_interval` | 0.9 |  | Segundos entre as notinhas musicais que saem da janela. |
| `cheers_interval` | 7.0 |  | Segundos entre um brinde e outro (som). |

## `scripts/props/tree_node.gd` (6)

**Corte**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `CHOP_RATE` | 1.5 |  | Madeira cortada por segundo por lenhador. |
| `wood_total` | 40.0 |  | Madeira total da árvore crescida. |
| `regen_rate` | 0.15 |  | Madeira que volta a crescer por segundo (0 = não regenera). |
| `depleted_cooldown` | 45.0 |  | Segundos como toco depois de esgotar, antes de começar a crescer de novo. |
| `min_wood_to_chop` | 4.0 |  | Abaixo disso a árvore não atrai lenhadores novos. |
| `chop_sound_interval` | 0.55 |  | Intervalo entre as machadadas (som). |

## `scripts/creatures/creature.gd` (25)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `kind` | "lumivoro" | **"ferrugento"** (ferrugento.tscn); **"gosma"** (gosma.tscn); **"lumivoro"** (lumivoro.tscn); **"magmante"** (magmante.tscn) |  |
| `max_hp` | 18.0 | **42.0** (ferrugento.tscn); **24.0** (gosma.tscn); **18.0** (lumivoro.tscn); **70.0** (magmante.tscn) |  |
| `speed` | 68.0 | **44.0** (ferrugento.tscn); **62.0** (gosma.tscn); **72.0** (lumivoro.tscn); **34.0** (magmante.tscn) |  |
| `damage` | 4.0 | **7.0** (ferrugento.tscn); **5.0** (gosma.tscn); **4.0** (lumivoro.tscn); **10.0** (magmante.tscn) |  |
| `attack_interval` | 1.0 | **1.4** (ferrugento.tscn); **1.1** (gosma.tscn); **1.0** (lumivoro.tscn); **1.8** (magmante.tscn) |  |
| `attack_range` | 18.0 |  |  |
| `grave_chance` | 0.15 | **0.4** (ferrugento.tscn); **0.2** (gosma.tscn); **0.15** (lumivoro.tscn); **0.45** (magmante.tscn) | Ipezinho (não guarda) atingido: chance do machucado ser grave. |
| `steal_amount` | 3.0 | **4.0** (gosma.tscn); **5.0** (magmante.tscn) | Ferrugento no armazém: minério roubado por golpe. |
| `scare_amount` | 1.0 |  | Lumívoro num prédio aceso: ânimo tirado de cada um lá dentro, por golpe. |
| `notice_range` | 150.0 |  | Distância em que ele larga o alvo e parte pra cima de quem está perto. |
| `barricade_mult` | 1.0 | **1.5** (gosma.tscn); **2.0** (magmante.tscn) | Bloco 70: multiplica o dano na barricada (o ácido e a lava derretem). |
| `drop_ore` | "" | **"cristal_verde"** (gosma.tscn); **"cristal_rubro"** (magmante.tscn) | Bloco 70: derrubado, chance de deixar cristal (minério, quantidade) no armazém. |
| `drop_amount` | 0 | **2** (gosma.tscn); **3** (magmante.tscn) |  |
| `drop_chance` | 0.0 | **0.35** (gosma.tscn); **0.5** (magmante.tscn) |  |

**Luz (Bloco 90)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `atracao_luz` | 2.0 |  | Lumívoro: o quanto uma tocha/lampião aceso da decoração atrai mais que um prédio aceso (a distância conta dividida por isto: 2 = uma luz a 200 px pesa como um prédio a 100 px). |

**Visual (folha de quadros)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `visual_textura` | — | **(recurso)** (ferrugento.tscn) | Bloco 80: a folha de quadros da criatura (uma LINHA por animação, na ordem de visual_anims; quadros da esquerda pra direita, virada pra direita). Vazia = a arte isométrica do bonecos.json. |
| `visual_quadro` | Vector2i(24, 32) | **Vector2i(90, 87)** (ferrugento.tscn) | Tamanho de UM quadro na folha (px). |
| `visual_anims` | PackedStringArray(["parado", "caminhada", "atacar", "dano", "morrer"]) | **PackedStringArray("parado", "caminhada", "atacar", "dano", "morrer")** (ferrugento.tscn) | As animações, na ordem das linhas da folha (as que o jogo usa: parado, caminhada, atacar, dano, morrer). |
| `visual_quadros` | PackedInt32Array([2, 4, 3, 2, 4]) | **PackedInt32Array(4, 6, 6, 4, 6)** (ferrugento.tscn) | Quantos quadros cada animação tem (mesma ordem de visual_anims). |
| `visual_fps` | 8.0 | **10.0** (ferrugento.tscn) | Quadros por segundo (parado, atacar, dano, morrer). |
| `visual_passada` | 34.0 | **40.0** (ferrugento.tscn) | Px andados por ciclo da caminhada (a perna acompanha o chão: o pé não escorrega). |
| `visual_escala` | 1.0 | **0.6667** (ferrugento.tscn) | Escala do desenho (1 = 1 px da folha por px do mundo). |
| `visual_pe` | 2.0 | **6.0** (ferrugento.tscn) | Px entre o pé e a borda de baixo do quadro (o pé fica na origem da criatura). |
| `visual_carga` | — | **(recurso)** (ferrugento.tscn) | O que ele leva quando roubou o armazém (desenhado nas costas; vazio = nada). |
| `visual_carga_pos` | Vector2(-6, -16) | **Vector2(-11, -30)** (ferrugento.tscn) | Onde fica a carga (px do mundo, a partir do pé, com o desenho virado pra direita: x < 0 = costas). |

