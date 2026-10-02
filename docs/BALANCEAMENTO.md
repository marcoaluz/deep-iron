# Balanceamento: onde mexer em cada valor

Gerado por `python tools/lista_balanceamento.py` (Bloco 52). Os valores são `@export` nos scripts: dá
pra mudar no Inspector do Godot (na cena do sistema: `scenes/game/main.tscn` e as cenas dos prédios) ou
direto no script. **Mudar valor é decisão do Marco**; aqui só está onde fica cada um.

Pra medir: painel de debug (F3, só em build de editor) e a telemetria (`user://telemetria/`,
resumo com `python tools/resumo_telemetria.py`).

A coluna **na cena** aparece quando uma cena `.tscn` troca o padrão do script: no jogo vale o da cena.

Total: **555 valores** em 4 pastas de scripts (62 trocados por alguma cena).

## `scripts/core/audio_manager.gd` (63)

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

**Limites**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `max_voices` | 24 |  |  |
| `max_steps_per_second` | 8.0 |  | Máximo de passos tocando por segundo somando todos os ipezinhos. |
| `sfx_max_distance` | 900.0 |  | Distância (em pixels do mundo) além da qual efeitos posicionais não tocam. |

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

## `scripts/core/day_night.gd` (18)

**Duração (segundos reais)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `day_duration` | 180.0 |  |  |
| `night_duration` | 60.0 |  |  |
| `time_scale` | 1.0 |  | Acelera o relógio (2 = passa 2x mais rápido). Útil pra testar. |
| `start_time` | 0.0 |  | Em que ponto do dia o jogo começa (segundos desde o amanhecer). |

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

## `scripts/core/defense.gd` (35)

**Armas (na ordem de WEAPON_IDS)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `weapon_damage` | [3.0, 6.0, 7.0, 11.0] |  |  |
| `weapon_range` | [18.0, 18.0, 110.0, 18.0] |  |  |
| `weapon_vs_ferrugento` | [1.0, 1.0, 1.0, 1.6] |  | Multiplicador do dano contra Ferrugentos. |
| `weapon_costs` | [Vector3i.ZERO, Vector3i(150, 40, 20), Vector3i(350, 40, 40), Vector3i(600, 60, 20)] |  | x = créditos, y = minério, z = madeira. |
| `weapon_ore` | ["", "ferro", "cobre", "prata"] |  |  |
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
| `hp_growth` | 0.15 |  | Vida das criaturas cresce essa fração por onda. |
| `warn_before` | 40.0 |  | Aviso quando faltar isso (s) pro anoitecer numa noite de invasão. |
| `spawn_spread` | 20.0 |  | As criaturas vão chegando ao longo desses segundos do começo da noite. |
| `strong_from_wave` | 4 |  | Prompt 17: a partir dessa onda, 1 a cada `strong_every` criaturas vem na forma FORTE (Lumívoro bruto, Ferrugento carregador), com mais vida e dano. 0 = nunca. |
| `strong_every` | 3 |  |  |
| `strong_hp_mult` | 1.6 |  |  |
| `strong_damage_mult` | 1.3 |  |  |

## `scripts/core/economy.gd` (15)

**Venda**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `ore_price` | 2.0 |  | Créditos por unidade de ferro. |
| `copper_price` | 4.0 |  | Créditos por unidade de cobre. |
| `coal_price` | 3.0 |  | Créditos por unidade de carvão. |
| `silver_price` | 8.0 |  | Créditos por unidade de prata (nível 2: mais perigoso, paga mais). |
| `solarita_price` | 14.0 |  | Créditos por unidade de solarita (nível 3, o abismo). |
| `starting_credits` | 0.0 |  |  |
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
| `deep_rect` | Rect2(-560, 700, 1120, 620) |  | Área do nível 2, abaixo (ao sul) da mina; a descida é o elevador da escavadeira. |
| `deep_floor_texture` | — | **(recurso)** (main.tscn) |  |
| `deep_injury_mult` | 2.5 |  | Chance de acidente multiplicada por isso minerando no nível 2 (acumula com a zanga). |
| `deep_boulder_count` | 12 |  |  |
| `deep_crystal_count` | 7 |  |  |
| `deep_pebble_count` | 40 |  |  |
| `deep_tint` | Color(0.7, 0.72, 0.88) |  | Tom da decoração do fundo (mais escuro e frio que a mina). |

**Nível 3 (abismo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `abyss_rect` | Rect2(-480, 1420, 960, 560) |  | Área do nível 3, abaixo do nível 2; a descida é a plataforma do abismo (conserto). |
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
| `palisade_y` | -462.0 |  | Paliçada entre a floresta e a vila: y da linha e meia largura da abertura do portão. |
| `gate_half_width` | 40.0 |  |  |
| `cliff_thickness` | 6.0 |  | Espessura (px do mundo) da "parede" que a navegação vê na beira de um penhasco. |

## `scripts/core/equipment.gd` (22)

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

## `scripts/core/morale.gd` (34)

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

## `scripts/core/research.gd` (18)

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

## `scripts/core/save_manager.gd` (3)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `autosave_interval` | 180.0 |  | Segundos entre autosaves (0 = desligado). Padrão: 3 minutos. |
| `save_on_quit` | true |  | Salva sozinho ao fechar a janela. |
| `max_backups` | 5 |  | Quantos backups com data/hora manter em user://backups (o mais antigo, por data, sai). |

## `scripts/core/sun.gd` (18)

**Estações (índice 0 = Primavera)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `days_per_season` | 4 |  |  |
| `adjust_day_length` | true |  | Mexe na duração do dia/noite conforme a estação (desligue pra testar com dia fixo). |
| `season_day_mult` | [1.0, 1.2, 1.0, 0.8] |  |  |
| `season_night_mult` | [1.0, 0.8, 1.0, 1.25] |  |  |
| `season_wave_chance` | [0.3, 0.6, 0.3, 0.15] |  |  |
| `season_hunger_mult` | [1.0, 1.0, 1.0, 1.25] |  |  |
| `season_garden_mult` | [1.3, 1.0, 0.8, 0.5] |  |  |
| `winter_joy` | -3.0 |  | Ânimo no inverno (frio). |

**Ondas solares**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `first_wave_day` | 2 |  |  |
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

## `scripts/workers/ipezinho.gd` (69)

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
| `hunger_decay` | 0.8 |  | Fome gasta por segundo (ritmo: era 0.7). |
| `hunger_threshold` | 30.0 |  |  |
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
| `walk_anim_fps` | 9.0 |  |  |
| `head_lamp_enabled` | true |  |  |

## `scripts/props/abyss_shaft.gd` (7)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `bottom_position` | Vector2(-360, 1500) |  | Onde fica a gaiola de chegada lá embaixo (coordenadas do mundo, dentro do abismo). |
| `link_travel_cost` | 0.05 |  |  |

**Conserto**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `repair_parts` | 12 |  |  |
| `repair_credits` | 1500 |  |  |
| `repair_silver` | 150 |  |  |
| `repair_time` | 120.0 |  |  |
| `repair_min_stage` | 4 |  | Estágio mínimo da vila pra começar o conserto. |

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

## `scripts/props/barricada.gd` (6)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `gate_id` | "tunel" |  |  |
| `display_name` | "Portão do túnel" |  |  |
| `hp_per_level` | [0.0, 120.0, 260.0, 450.0] |  | Vida por nível (índice = nível). |
| `upgrade_costs` | [Vector3i.ZERO, Vector3i(80, 0, 60), Vector3i(250, 120, 40), Vector3i(500, 200, 30)] |  | Ampliar pro nível i: x = créditos, y = minério, z = madeira. (índice 0 não usado) |
| `upgrade_ore` | ["", "", "ferro", "ferro"] |  | Minério gasto em cada nível ("" = qualquer). |
| `repair_wood_per_hp` | 0.25 |  | Madeira gasta por ponto de vida consertado. |

## `scripts/props/campo_treino.gd` (1)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `train_rate` | 0.009 |  | Habilidade ganha por segundo treinando (1.0 = 100%). 0.009 -> ~110 s pra ficar pronto. |

## `scripts/props/casa.gd` (3)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `built` | true |  | false = lote vazio (formato antigo; hoje as casas novas são posicionadas pelo jogador). |
| `placed_by_player` | false |  | true = casa nova que o jogador posicionou (a posição vai pro save; as 3 iniciais são fixas). |
| `starter_house` | false |  | Bloco 37: casa inicial da fundação (não soma no limite de ipezinhos quando fica pronta). |

## `scripts/props/centro_vila.gd` (32)

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
| `speed_bonus_per_level` | 0.1 |  | Velocidade extra por nível (0.1 = +10% por nível). |

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

## `scripts/props/coletor_madeira.gd` (1)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `wood_per_sec` | 0.6 |  | Madeira por segundo com o operador no posto (antes da zanga/ânimo dele). |

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

## `scripts/props/deep_shaft.gd` (2)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `bottom_position` | Vector2(440, 790) |  | Onde fica a gaiola de chegada lá embaixo (coordenadas do mundo, dentro do nível 2). |
| `link_travel_cost` | 0.05 |  | Custo de navegação da descida (baixo = os ipezinhos acham que "descer é perto"). |

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

## `scripts/props/escudo.gd` (6)

**Etapas (na ordem de STAGE_IDS)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `stage_costs` | [ |  | x = créditos, y = minério, z = segundos de obra. |
| `stage_ore` | ["ferro", "cobre", "solarita", "prata"] |  |  |
| `stage_wood` | [100, 0, 0, 0] |  | Extras: madeira (fundação), prata (bobinas), peças raras (núcleo), solarita (emissor). |
| `bobinas_silver` | 80 |  |  |
| `nucleo_parts` | 15 |  |  |
| `emissor_solarita` | 100 |  |  |

## `scripts/props/food_source.gd` (5)

**Colheita**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `HARVEST_RATE` | 3.0 |  | Comida colhida por segundo por cozinheiro. |
| `food_total` | 150.0 |  | Comida total quando a horta está cheia. |
| `regen_rate` | 0.35 |  | Comida que volta a crescer por segundo (0 = não regenera). |
| `depleted_cooldown` | 25.0 |  | Segundos "colhida" depois de esgotar, antes de começar a regenerar. |
| `min_food_to_harvest` | 5.0 |  | Abaixo disso a horta não atrai cozinheiros novos. |

## `scripts/props/hazard_zone.gd` (3)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `kind` | "gas" | **"gas"** (main.tscn); **"radiacao"** (main.tscn); **"calor"** (main.tscn) |  |
| `radius` | 90.0 | **85.0** (main.tscn); **80.0** (main.tscn); **80.0** (main.tscn) | Raio da zona (px do mundo), achatado na vertical como o resto do mapa. |
| `sign_offset` | Vector2(-70, 60) | **Vector2(-95, 10)** (main.tscn); **Vector2(95, 20)** (main.tscn); **Vector2(-95, -10)** (main.tscn) | Onde fica a placa (em relação ao centro): a "entrada". |

## `scripts/props/hunt_spot.gd` (7)

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

## `scripts/props/oficina.gd` (7)

**Ferramentas (na ordem de TOOL_IDS)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `tool_costs` | [ |  | x = créditos, y = quantidade de minério, z = segundos na forja. |
| `tool_ore_types` | ["ferro", "cobre", "carvao", "prata", "ferro"] |  | Tipo do minério gasto em cada ferramenta. |
| `tool_wood_costs` | [30, 25, 40, 30, 35] |  | Madeira gasta em cada ferramenta (cabo/estrutura) — referência: 1 madeira pra 5 minério. |
| `tool_min_stage` | [1, 2, 4, 4, 1] |  | Estágio mínimo da vila (Centro da Vila) pra fabricar cada ferramenta. |

**Efeitos**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `forge_sound_interval` | 0.7 |  |  |
| `idle_forge_energy` | 0.45 |  |  |
| `active_forge_energy` | 1.1 |  |  |

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

## `scripts/creatures/creature.gd` (10)

**(sem grupo)**

| valor | padrão | na cena | o quê |
|---|---|---|---|
| `kind` | "lumivoro" | **"ferrugento"** (ferrugento.tscn); **"lumivoro"** (lumivoro.tscn) |  |
| `max_hp` | 18.0 | **42.0** (ferrugento.tscn); **18.0** (lumivoro.tscn) |  |
| `speed` | 68.0 | **44.0** (ferrugento.tscn); **72.0** (lumivoro.tscn) |  |
| `damage` | 4.0 | **7.0** (ferrugento.tscn); **4.0** (lumivoro.tscn) |  |
| `attack_interval` | 1.0 | **1.4** (ferrugento.tscn); **1.0** (lumivoro.tscn) |  |
| `attack_range` | 18.0 |  |  |
| `grave_chance` | 0.15 | **0.4** (ferrugento.tscn); **0.15** (lumivoro.tscn) | Ipezinho (não guarda) atingido: chance do machucado ser grave. |
| `steal_amount` | 3.0 |  | Ferrugento no armazém: minério roubado por golpe. |
| `scare_amount` | 1.0 |  | Lumívoro num prédio aceso: ânimo tirado de cada um lá dentro, por golpe. |
| `notice_range` | 150.0 |  | Distância em que ele larga o alvo e parte pra cima de quem está perto. |

