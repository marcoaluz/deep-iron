extends CharacterBody2D

signal state_changed(new_state: String)
signal injured_changed(is_injured: bool)
signal mood_changed(level: int)  # 0 calmo, 1 irritado, 2 furioso
signal died(worker_name: String)

const STATE_LABELS := {
	"idle": "ocioso",
	"eating": "comendo",
	"mining": "minerando",
	"storing": "armazenando",
	"manual": "ordem manual",
	"home": "indo pra casa",
	"gathering": "colhendo comida",
	"delivering": "levando comida",
	"foraging": "colhendo fruta",
	"hunting": "caçando",
	"stocking": "levando matéria-prima",
	"fetching": "buscando matéria-prima",
	"cooking": "preparando comida",
	"doctor": "de plantão na enfermaria",
	"building": "construindo",
	"chopping": "cortando madeira",
	"hauling": "levando madeira",
	"infirmary": "indo pra enfermaria",
	"leisure": "indo pra taverna",
	"strike": "em greve!",
	"robot": "indo buscar o robô",
	"guard": "de guarda",
	"training": "treinando",
	"research": "pesquisando",
	"rearming": "indo ao Arsenal",
	"downed": "caído em combate",
	"rescue": "resgatando",
}
## Distância da porta/cama a partir da qual o ipezinho "chega" em casa.
const REST_REACH := 12.0
const Ores := preload("res://scripts/core/ores.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
const STEEL_PICKAXE := preload("res://assets/game/pickaxe_aco.png")
const FOOD_BASKET := preload("res://assets/game/food_basket.png")
## Nomes sorteados (sem repetir enquanto houver nome livre).
const NAMES_BOY := ["Tião", "Zé", "Juca", "Chico", "Bento", "Dito", "Tonho", "Neco",
	"Quim", "Bira", "Tuco", "Lalo", "Nando", "Beto", "Vavá", "Duda"]
const NAMES_GIRL := ["Zefa", "Lia", "Nina", "Cida", "Bia", "Tuca", "Dora", "Rosinha",
	"Mel", "Tita", "Lulu", "Nena", "Fifi", "Jana", "Didi", "Cacá"]
## Visual do corpo (tools/gen_sprites.py): outfit (pela função) x gênero x variação.
## Todos têm o mesmo layout de 4 quadros e a mesma silhueta de tronco/pés, então
## acessórios (lenço, remendo, bota) e ícones por cima (carga, zanga, curativo) encaixam igual.
const GENDERS := {"menino": "m", "menina": "f"}
## Variações de roupa/cabelo/pele por gênero (índice `look`, salvo desde o Bloco 11).
const LOOKS_PER_GENDER := 6
## Arquivo de cada outfit (%s = "m"/"f", %d = look). O mineiro usa os nomes de sempre.
const OUTFIT_FILES := {
	"mineiro": "res://assets/game/ipezinho_%s%d.png",
	"lenhador": "res://assets/game/ipezinho_lenhador_%s%d.png",
	"cozinheiro": "res://assets/game/ipezinho_cozinheiro_%s%d.png",
	"civil": "res://assets/game/ipezinho_civil_%s%d.png",
	"cacador": "res://assets/game/ipezinho_cacador_%s%d.png",  # Bloco 28
	"guarda": "res://assets/game/ipezinho_guarda_%s%d.png",
	"pesquisador": "res://assets/game/ipezinho_pesquisador_%s%d.png",
	"medico": "res://assets/game/ipezinho_medico_%s%d.png",  # Bloco 30
	"engenheiro": "res://assets/game/ipezinho_engenheiro_%s%d.png",  # Bloco 31
}
## Só o capacete de mineiro tem lanterna (a PointLight2D HeadLamp).
const OUTFITS_WITH_LAMP := ["mineiro"]
## Chance (0..1) de cada camada de acessório aparecer (botas, remendo/bolso, lenço).
const ACCESSORY_CHANCE := 0.6
const STATE_GROUP := {
	"eating": "comedouros",
	"mining": "minerios",
	"storing": "armazens",
	"gathering": "coleta_comida",
	"delivering": "comedouros",
	"foraging": "coleta_comida",  # Bloco 27: caçador na horta (fruta crua)
	"hunting": "caca",  # Bloco 27: caçador na toca (precisa de arco)
	"stocking": "armazens",  # caçador descarregando matéria-prima
	"fetching": "armazens",  # cozinheiro buscando matéria-prima
	"cooking": "comedouros",  # cozinheiro preparando
	"chopping": "arvores",
	"hauling": "armazens",
	"infirmary": "enfermarias",
	"leisure": "tavernas",
	"training": "campos",
	"research": "laboratorios",
	"rearming": "arsenais",  # Bloco 35: guarda buscando/trocando a arma
}
## Função (job) designada pelo jogador — Bloco 25: um campo só, com "ocioso" de padrão.
## Função nova (caçador, engenheiro...) = mais uma constante aqui + entrada em JOBS/JOB_LABELS
## + o que ela faz no _choose_state().
const ROLE_IDLE := "ocioso"  # sem função: não trabalha sozinho, espera no Centro da Vila
const ROLE_MINER := "minerador"
const ROLE_COOK := "cozinheiro"
const ROLE_LUMBER := "lenhador"
const ROLE_GUARD := "guarda"
const ROLE_RESEARCH := "pesquisador"
const ROLE_HUNTER := "caçador"  # Bloco 27: colhe fruta / caça (com arco) -> matéria-prima
const ROLE_DOCTOR := "médico"  # Bloco 30: plantão na enfermaria (cura mais rápida)
const ROLE_ENGINEER := "engenheiro"  # Bloco 31: sem ele nenhuma obra anda
const JOBS := [ROLE_IDLE, ROLE_MINER, ROLE_COOK, ROLE_LUMBER, ROLE_GUARD, ROLE_RESEARCH, ROLE_HUNTER, ROLE_DOCTOR, ROLE_ENGINEER]
## Texto do popup ao receber a função.
const JOB_LABELS := {
	ROLE_IDLE: "Sem função", ROLE_MINER: "Minerador!", ROLE_COOK: "Cozinheiro!",
	ROLE_LUMBER: "Lenhador!", ROLE_GUARD: "Guarda!", ROLE_RESEARCH: "Pesquisador!",
	ROLE_HUNTER: "Caçador!", ROLE_DOCTOR: "Médico!", ROLE_ENGINEER: "Engenheiro!",
}
## Bloco 26/28: outfit inteiro por função (derivado do `job`: nada novo no save).
## REGRA (Bloco 28): toda função nova nasce com outfit próprio no mesmo bloco —
## gerar os corpos no gen_sprites.py (IPEZINHO_OUTFITS), pôr o arquivo em OUTFIT_FILES
## e mapear aqui. Nada de "por enquanto usa o de mineiro".
const JOB_OUTFIT := {
	ROLE_IDLE: "civil", ROLE_MINER: "mineiro", ROLE_COOK: "cozinheiro",
	ROLE_LUMBER: "lenhador", ROLE_GUARD: "guarda", ROLE_RESEARCH: "pesquisador",
	ROLE_HUNTER: "cacador", ROLE_DOCTOR: "medico", ROLE_ENGINEER: "engenheiro",
}
## Quem está sem função fica a até esta distância do Centro da Vila.
const IDLE_HUB_RADIUS := 70.0
const LANCA := preload("res://assets/game/lanca.png")
## Bloco 35: cada arma tem o seu desenho na mão do guarda.
const PORRETE := preload("res://assets/game/porrete.png")
const BESTA := preload("res://assets/game/besta.png")
const LANCA_PRATA := preload("res://assets/game/lanca_prata.png")
const WEAPON_SPRITES := {"porrete": PORRETE, "lanca": LANCA, "besta": BESTA, "lanca_prata": LANCA_PRATA}
const BROKEN_ICON := preload("res://assets/game/arma_quebrada.png")
const AXE := preload("res://assets/game/axe.png")
const WOOD_LOG := preload("res://assets/game/wood_log.png")
const BOW := preload("res://assets/game/bow.png")
const FORAGE_BASKET := preload("res://assets/game/forage_basket.png")
const HAMMER := preload("res://assets/game/hammer.png")
## Distância da obra em que o engenheiro já conta como "no local" (a obra pode estar
## dentro de um obstáculo; a navegação para no ponto andável mais perto).
const OBRA_REACH := 70.0
## Anti-travamento: segundos parado "andando" até refazer o caminho / puxar pra área andável.
const STUCK_REPATH_TIME := 1.5
const STUCK_SNAP_TIME := 3.0
const RAW_FOOD := preload("res://assets/game/raw_food.png")
const STRIKE_SIGN := preload("res://assets/game/strike_sign.png")

@export_group("Movimento")
@export var speed: float = 120.0
@export var loaded_speed_penalty: float = 0.35  # 0.35 = até 35% mais lento com carga cheia
## Multiplicador de velocidade quando a fome chega a zero.
@export var starving_speed_mult: float = 0.5
@export var arrive_distance: float = 4.0

@export_group("Navegação")
## Desvio entre ipezinhos (RVO do NavigationAgent2D). Desligado = atravessam uns aos outros.
@export var avoidance_enabled: bool = true
## Raio do ipezinho para o desvio entre agentes.
@export var avoidance_radius: float = 7.0

@export_group("Fome")
@export var hunger_max: float = 100.0
## Fome gasta por segundo (ritmo: era 0.7).
@export var hunger_decay: float = 0.8
@export var hunger_threshold: float = 30.0  # abaixo disso, prioridade vira comer
## Come até atingir essa fração da fome máxima.
@export_range(0.5, 1.0) var eat_until_ratio: float = 0.95

@export_group("Turno / casa")
## Fração do gasto normal de fome enquanto dorme (0.2 = gasta 20%). Andando pra casa gasta normal.
@export_range(0.0, 1.0) var sleep_hunger_mult: float = 0.2
## Atraso máximo (s) pra reagir ao anoitecer/amanhecer, pra não saírem todos no mesmo frame.
@export var phase_react_delay: float = 1.5

@export_group("Acidentes")
## Chance de se machucar a cada ciclo de mineração (0.04 = 4%).
@export_range(0.0, 1.0) var injury_chance: float = 0.04
## Minério extraído que conta como um "ciclo de mineração" (16 = uma carga cheia).
@export var mining_cycle_amount: float = 16.0
## Só sem Enfermaria na cena (fallback antigo): segundos descansando em casa até curar.
## Com enfermaria, o tempo de leito vem dela (heal_time_leve / heal_time_grave).
@export var recovery_time: float = 30.0
## Multiplicador de velocidade enquanto está machucado (mancando).
## 0.73 -> pior caso (machucado + carga cheia) ≈ 120 x 0.65 x 0.73 ≈ 57 px/s.
@export var injured_speed_mult: float = 0.73
## Clareira: chance de um galho cair no lenhador a cada ciclo de corte (0.05 = 5%).
@export_range(0.0, 1.0) var branch_injury_chance: float = 0.05
## Madeira cortada que conta como um "ciclo de corte" (8 = uma carga cheia do lenhador).
@export var chop_cycle_amount: float = 8.0
## Cortar de noite (turno extra, clareira escura) multiplica a chance da queda de galho.
@export var night_chop_injury_mult: float = 2.0

@export_group("Gravidade / enfermaria")
## Chance do acidente ser GRAVE: na mina / queda de galho...
@export_range(0.0, 1.0) var grave_chance_mine: float = 0.2
@export_range(0.0, 1.0) var grave_chance_branch: float = 0.4
## ...e quanto soma no nível 2 (mais fundo, mais feio).
@export_range(0.0, 1.0) var deep_grave_bonus: float = 0.3
## No abismo (nível 3) soma mais essa em cima da do nível 2.
@export_range(0.0, 1.0) var abyss_grave_bonus: float = 0.2
## Segundos SEM LEITO até o machucado LEVE piorar pra grave...
@export var leve_untreated_time: float = 150.0
## ...e até o GRAVE morrer. (O relógio pausa enquanto está deitado num leito.)
@export var grave_untreated_time: float = 75.0
## Aviso no HUD quando faltar isso pro grave morrer.
@export var death_warning_time: float = 25.0

@export_group("Equipamento (Bloco 42)")
## Couro que cada unidade de CAÇA rende (fruta não dá couro). Vai pro armazém com a carne.
@export var leather_per_game: float = 0.5

@export_group("Caído em combate (Bloco 36)")
## Guarda que perde a luta cai GRAVE no lugar e não anda. Sem resgate, morre depois de
## tantos segundos no chão (o relógio PAUSA enquanto o médico carrega: primeiros socorros).
@export var downed_untreated_time: float = 150.0
## Médico carregando alguém nas costas anda nessa fração da velocidade.
@export_range(0.1, 1.0) var carry_patient_speed_mult: float = 0.6

@export_group("Turno extra / zanga")
## Zanga ganha por segundo trabalhando à noite em turno extra (0.8 -> ~+48 por noite).
@export var anger_gain_per_sec: float = 0.8
## Zanga perdida por segundo DORMINDO (em casa, ao relento ou curando). De dia acordado não muda.
@export var anger_decay_per_sec: float = 1.5
## A partir dessa zanga fica "irritado"...
@export_range(0.0, 100.0) var anger_irritated_at: float = 40.0
## ...e a partir dessa, "furioso".
@export_range(0.0, 100.0) var anger_furious_at: float = 75.0
## Multiplica a chance de acidente (injury_chance) quando irritado / furioso.
@export var irritated_injury_mult: float = 2.0
@export var furious_injury_mult: float = 4.0
## Multiplica quanto ele minera por segundo quando irritado / furioso.
@export var irritated_work_mult: float = 0.8
@export var furious_work_mult: float = 0.55
## Multiplica a velocidade de caminhada (acumula com carga, fome e lesão).
@export var irritated_speed_mult: float = 0.95
@export var furious_speed_mult: float = 0.85

@export_group("Felicidade")
## Felicidade de quem nasce (jogo novo / recrutado).
@export_range(0.0, 100.0) var happiness_start: float = 70.0
## Ponto de partida do alvo, antes de somar os motivos (cama, fome, zanga...).
@export var happiness_base: float = 60.0
## Quanto a felicidade anda por segundo em direção ao alvo.
@export var happiness_drift: float = 0.25
## Abaixo disso vai pra taverna (se existir) e fica lá até leisure_until.
@export_range(0.0, 100.0) var leisure_below: float = 40.0
@export_range(0.0, 100.0) var leisure_until: float = 85.0
## Faixas: feliz >= happy_at; triste < sad_below; revoltado < miserable_below.
@export_range(0.0, 100.0) var happy_at: float = 75.0
@export_range(0.0, 100.0) var sad_below: float = 40.0
@export_range(0.0, 100.0) var miserable_below: float = 25.0
## Multiplica a produção (minerar/cortar) em cada faixa.
@export var happy_work_mult: float = 1.1
@export var sad_work_mult: float = 0.8
@export var miserable_work_mult: float = 0.6

@export_group("Guarda")
## Vida na luta = base + por_habilidade x habilidade (0..1). Zerou: machuca e sai da luta.
@export var guard_base_hp: float = 30.0
@export var guard_hp_per_skill: float = 20.0
## Distância em que o guarda vê uma criatura e parte pra cima.
@export var guard_aggro: float = 200.0
@export var guard_attack_interval: float = 1.0
## Sem treino o guarda bate com metade da força (habilidade 0 -> x0.5, 100% -> x1).
@export_range(0.0, 1.0) var untrained_damage_mult: float = 0.5

@export_group("Robô antigo")
## Carregando o robô anda nessa fração da velocidade.
@export_range(0.1, 1.0) var carry_robot_speed_mult: float = 0.6

@export_group("Cozinheiro")
## Matéria-prima que o cozinheiro carrega por viagem (armazém -> comedouro). Bloco 27.
@export var cook_carry: float = 12.0
## Segundos de preparo por unidade de matéria-prima (12 unidades x 0.8 = ~10 s por leva).
@export var prep_time_per_raw: float = 0.8
## Comida pronta que cada unidade de matéria-prima rende no comedouro. Bloco 33: cozinhar
## RENDE — 1.25 = 10 de matéria-prima viram 12,5 de ração (era 1.0, sem ganho nenhum).
@export var food_per_raw: float = 1.25

@export_group("Caçador")
## Quantas unidades (fruta ou caça) o caçador carrega por viagem. Cada unidade de caça
## vale mais matéria-prima (meat_raw_value da toca), por isso caçar rende mais por viagem.
@export var hunter_carry: float = 10.0

@export_group("Lenhador")
## Madeira que o lenhador carrega por viagem (árvore -> armazém).
@export var lumber_carry: float = 8.0

@export_group("Carga")
## Minério por viagem (ritmo: era 20).
@export var cargo_capacity: float = 16.0

@export_group("IA")
@export var auto_mode: bool = true  # true = IA decide sozinha; false = só controle manual por clique
@export var decision_interval: float = 1.0  # a cada quantos segundos a IA reavalia o que fazer
## Segundos que a IA espera depois de uma ordem manual antes de voltar a decidir.
## Só começa a contar quando ele CHEGA no destino (a caminhada não gasta esse tempo).
@export var manual_override_time: float = 6.0
## Distância máxima de um passeio aleatório quando está ocioso.
@export var idle_wander_radius: float = 50.0

@export_group("Visual")
@export var walk_anim_fps: float = 9.0
@export var head_lamp_enabled: bool = true

var hunger: float = 100.0
var carrying: float = 0.0
## Tipo do minério carregado (um tipo por vez; vale só com carrying > 0).
var cargo_type: String = "ferro"
var selected: bool = false

var _target: Vector2 = Vector2.ZERO
var _moving: bool = false
var _ai_state: String = "idle"  # idle | eating | mining | storing | manual
var _decision_timer: float = 0.0
var _manual_timer: float = 0.0
var _station: Node2D = null  # estação cujo slot está reservado
var _slot: int = -1
var _work_timer: float = 0.0  # > 0 enquanto está efetivamente minerando
var _anim_time: float = 0.0
var _swing_time: float = 0.0
var _facing: float = 1.0
var _prev_swing: float = 0.0
var _swing_rising: bool = false
var _last_hunger_int: int = -1
var _home: Node2D = null  # casa com a cama fixa deste ipezinho (null = sem teto)
var _home_slot: int = -1
var _resting: bool = false  # chegou e está dormindo
var _inside: bool = false  # dormindo DENTRO de casa (fica invisível)
var _camp_pos: Variant = null  # onde dorme ao relento quando não tem cama
var _body_base_y: float = 0.0
var injured: bool = false
## Turno extra: de noite continua trabalhando em vez de ir pra cama (ligado pelo jogador).
var overtime: bool = false
## Função atual (um dos JOBS). Nasce ociosa: só trabalha depois que o jogador designa.
## (Save de antes do Bloco 25 sem função vira "minerador" — ver load_save_data / SaveManager.)
var job: String = ROLE_IDLE
## Nome próprio mostrado no HUD (o nome do NÓ continua "IpezinhoN": é a chave do save).
var display_name: String = ""
## "menino" ou "menina": sorteado ao nascer (jogo novo / recrutamento), fixo depois.
var gender: String = ""
## Variação de cor de roupa/cabelo/pele dentro do gênero (0..LOOKS_PER_GENDER-1).
var look: int = -1
## Comida PRONTA na cesta. Desde o Bloco 27 ninguém colhe comida pronta: só vem de
## save antigo, e quem tiver entrega no comedouro.
var food_carrying: float = 0.0
## Matéria-prima nas mãos (Bloco 27), em unidades de matéria-prima: o caçador leva pro
## armazém; o cozinheiro traz do armazém e prepara no comedouro.
var raw_carrying: float = 0.0
## Volume carregado (fruta ou caça: 1 por unidade colhida). É isso que enche a mochila
## do caçador — a caça ocupa 1 e vale meat_raw_value, por isso rende mais por viagem.
var _raw_units: float = 0.0
## Segundos que faltam pra leva atual ficar pronta (cozinheiro no comedouro).
var _prep_left: float = 0.0
## Madeira nas costas (só o lenhador corta; qualquer um que tenha na mão leva pro armazém).
var wood_carrying: float = 0.0
var _default_tool: Texture2D
var _has_steel_pickaxe := false
## Zanga 0..100: sobe no turno extra da noite, desce dormindo.
var anger: float = 0.0
var _mood: int = 0
var _recovery_left: float = 0.0
var _mined_since_roll: float = 0.0
var _chopped_since_roll: float = 0.0
## Causa do machucado atual: "mina" (acidente minerando) ou "galho" (queda na clareira).
var injury_cause: String = ""
## Gravidade do machucado atual: "leve" ou "grave" ("" = não machucado).
var injury_severity: String = ""
## Segundos que ainda aguenta SEM LEITO (leve -> piora, grave -> morre). Pausa no leito.
var _care_left: float = 0.0
## Deitado num leito da enfermaria (fica lá dentro, invisível).
var _admitted: bool = false
var _ward: Node = null  # enfermaria onde está internado
var _death_warned := false
## Felicidade 0..100 (-1 = ainda não definida: nasce com happiness_start).
var happiness: float = -1.0
var _stuck_time := 0.0  # Bloco 31b: anti-travamento (_check_stuck)
var _stuck_pos := Vector2.ZERO
var _stuck_stage := 0
var _ghost_left := 0.0  # segundos com o desvio desligado pra desencalhar
var _obra: Node = null  # Bloco 31: obra que o engenheiro está tocando
var _obra_on_site := false  # já chegou e está trabalhando nela
var _on_duty: Node = null  # Bloco 30: enfermaria onde o médico está de plantão (lá dentro)
var _at_taverna: Node = null  # taverna onde está se divertindo (lá dentro, invisível)
var _strike_spot: Variant = null  # onde fica parado protestando
var _strike_icon: Sprite2D
var _strike_refuse_cd := 0.0
## Robô antigo que mandaram buscar / que está nas costas.
var _robot_task: Node = null
var holding_robot: Node = null
## Guarda: habilidade de combate (0..1, sobe treinando), vida na luta e o inimigo da vez.
var combat_skill: float = 0.0
## Radiação acumulada nas ondas solares (sun.gd); passou do limite, machuca.
var rad: float = 0.0
var combat_hp: float = -1.0
var _foe: Node2D = null
var _attack_cd := 0.0
## Bloco 35: a arma que ESTE guarda carrega ("" = desarmado) e quantos golpes ela ainda
## aguenta (cada ataque numa invasão gasta 1; zerou, quebra).
var weapon: String = ""
var weapon_durability: float = 0.0
## Arma quebrada que ele leva de volta pro Arsenal (vai pra pilha de conserto).
var broken_weapon: String = ""
## Todo ipezinho tem um porrete de casa: o primeiro vem de graça quando vira guarda.
var got_porrete: bool = false
## Bloco 42: o que está vestindo agora (tipo -> durabilidade): "casaco" e/ou um traje.
## Pega e devolve sozinho no vestiário (equipment.gd).
var wearing: Dictionary = {}
## Couro da caça na mochila (vai pro armazém junto com a carne).
var leather_carrying: float = 0.0
var _hazard_cd := 0.0
## Bloco 36: guarda que perdeu a luta — caído no lugar (grave), só o MÉDICO leva pra enfermaria.
var downed: bool = false
## Portão onde ele caiu ("tunel"/"poco"): enquanto ele está caído, é a brecha na defesa.
var downed_gate: String = ""
## (caído) o médico que vem buscar / quem está carregando agora.
var _rescuer: Node = null
var _carried_by: Node = null
## (médico) o caído que ele vai buscar / que está nas costas dele.
var _rescue: Node = null
var carrying_patient: Node = null
var _broken_icon: Sprite2D
var _hub_node: Node = null
## Preenchido pelo SaveManager antes de entrar na árvore (ipezinho vindo do save).
var pending_save_data: Dictionary = {}
var _saved_home: String = ""  # nome da casa salva (a cama volta pro mesmo dono)
var _saved_home_slot: int = -1

@onready var _hunger_label: Label = $HungerLabel
@onready var _cargo_label: Label = $CargoLabel
@onready var _body: Sprite2D = $Body
@onready var _tool: Sprite2D = $Tool
@onready var _carry_icon: Sprite2D = $CarryIcon
@onready var _injury_icon: Sprite2D = $InjuryIcon
@onready var _anger_icon: Sprite2D = $AngerIcon
@onready var _cook_icon: Sprite2D = $CookIcon
@onready var _lamp: PointLight2D = $HeadLamp
@onready var _agent: NavigationAgent2D = $Agent
## Acessórios (Bloco 24): camadas filhas do Body, com os mesmos 4 quadros de caminhada.
@onready var _accessories: Array[Sprite2D] = [$Body/Boots, $Body/Detail, $Body/Neck]
var _accessory_variant: Array[int] = [-1, -1, -1]


func _ready() -> void:
	add_to_group("ipezinhos")
	_target = global_position
	hunger = hunger_max
	_decision_timer = randf_range(0.1, decision_interval)  # dessincroniza os ipezinhos
	_lamp.enabled = head_lamp_enabled
	_lamp.add_to_group("cullable_lights")
	_agent.avoidance_enabled = avoidance_enabled
	_agent.radius = avoidance_radius
	_agent.max_speed = speed * 1.2
	_agent.velocity_computed.connect(_on_velocity_computed)
	_agent.link_reached.connect(_on_link_reached)
	_body_base_y = _body.position.y
	_default_tool = _tool.texture
	if not pending_save_data.is_empty():
		load_save_data(pending_save_data)
		pending_save_data = {}
	if happiness < 0.0:
		happiness = happiness_start
	_strike_icon = Sprite2D.new()
	_strike_icon.texture = STRIKE_SIGN
	_strike_icon.position = Vector2(-11, -44)
	_strike_icon.scale = Vector2(1.5, 1.5)
	_strike_icon.visible = false
	add_child(_strike_icon)
	_broken_icon = Sprite2D.new()
	_broken_icon.texture = BROKEN_ICON
	_broken_icon.position = Vector2(0, -46)
	_broken_icon.scale = Vector2(2, 2)
	_broken_icon.visible = false
	add_child(_broken_icon)
	_ensure_appearance()
	_ensure_name()
	_apply_accessories()
	_claim_home.call_deferred()  # as casas precisam estar nos grupos
	_sync_tool_visual.call_deferred()  # recrutado depois da picareta de aço já nasce com ela
	_apply_research.call_deferred()  # carrinhos de mina (capacidade de carga)
	_update_hunger_label()
	_update_cargo_label()


func _exit_tree() -> void:
	_discharge()
	_leave_taverna()
	_end_duty()
	_obra_stop()
	_drop_robot()
	_release_station()
	if _home != null and is_instance_valid(_home):
		_home.set_inside(self, false)
		_home.release_slot(self)
	_home = null


# ------------------------------------------------------------ comandos
## Ordem do jogador (clique). A IA fica em pausa por manual_override_time.
func move_to(pos: Vector2) -> void:
	if downed:
		return  # caído não levanta por ordem: só o médico tira ele dali
	var eq := _equipment()
	if eq:
		var z: String = eq.hazard_at(pos)
		if z != "" and not can_enter_hazard(z):
			Audio.error()
			_popup("Sem %s!" % eq.NAMES[z].to_lower(), Color(1.0, 0.55, 0.4))
			var hud := get_tree().get_first_node_in_group("hud")
			if hud:
				hud.show_toast("Ordem bloqueada: pra entrar no %s precisa de %s (Oficina, tecla O)." % [
					eq.ZONE_NAMES[z].to_lower(), eq.NAMES[z].to_lower()], Color(1.0, 0.6, 0.4))
			return
	_release_station()
	_set_state("manual")
	_manual_timer = manual_override_time
	_go_to(pos)


func _go_to(pos: Vector2) -> void:
	_target = pos
	_moving = true
	_agent.target_position = pos


func get_state() -> String:
	return _ai_state


func get_state_label() -> String:
	if downed:
		if _carried_by != null:
			return "sendo levado pra enfermaria"
		var coming: bool = _rescuer != null and is_instance_valid(_rescuer) and _rescuer.get("_rescue") == self
		return "CAÍDO — %s (morre em %ds)" % ["médico a caminho" if coming else "esperando médico", ceili(_care_left)]
	if _ai_state == "rescue":
		var who: String = _rescue.display_name if _rescue != null and is_instance_valid(_rescue) else "?"
		return ("levando %s pra enfermaria" if carrying_patient != null else "indo resgatar %s") % who
	if _ai_state == "rearming":
		return "DESARMADO — indo ao Arsenal" if weapon == "" else "indo ao Arsenal trocar de arma"
	if is_guard() and weapon == "" and _ai_state in ["guard", "training", "home"]:
		var def := _defense()
		return "DESARMADO — %s" % ("sem Arsenal pra pegar outra" if def == null or def.arsenal() == null else "esperando o Arsenal")
	if _ai_state == "guard":
		return "lutando!" if _foe != null and is_instance_valid(_foe) else "de guarda"
	if _ai_state == "training":
		return "treinando (%d%%)" % roundi(combat_skill * 100.0)
	if _ai_state == "robot":
		return "carregando o robô" if holding_robot != null else "indo buscar o robô"
	if _at_taverna != null:
		return "na taverna (ânimo %d)" % roundi(happiness)
	if _admitted:
		return "internado, %s (%ds)" % [injury_severity, ceili(_recovery_left)] if injured else "recebendo alta"
	if injured and _ai_state == "infirmary":
		var clock := ("morre em %ds" if injury_severity == "grave" else "piora em %ds") % ceili(_care_left)
		if _station == null:
			return "machucado %s, esperando leito (%s)" % [injury_severity, clock]
		return "machucado %s, indo pra enfermaria (%s)" % [injury_severity, clock]
	if injured and _ai_state == "home":
		var why := " por galho" if injury_cause == "galho" else ""
		return "curando (%ds)" % ceili(_recovery_left) if _resting else "machucado%s, indo pra casa" % why
	if _ai_state == "home" and _resting:
		var sun := _sun()
		if sun and sun.shelter_now() and not _is_night():
			return "abrigado do sol" if _inside else "sem abrigo, no sol!"
		return "dormindo" if _inside else "dormindo ao relento"
	if _ai_state == "idle" and has_no_job():
		return "sem função — esperando ordem"
	if _ai_state == "idle" and is_cook():
		return "esperando matéria-prima"
	if _ai_state == "idle" and is_hunter():
		return "sem fruta nem caça na clareira"
	if _ai_state == "doctor":
		if _on_duty == null:
			return "indo pra enfermaria (plantão)"
		var n: int = _on_duty.patients().size()
		return "tratando %d internado%s" % [n, "s" if n > 1 else ""] if n > 0 else "de plantão, esperando pacientes"
	if _ai_state == "building" and _obra != null and is_instance_valid(_obra):
		var pct := roundi(_obra.obra_progress() * 100.0)
		return ("construindo: %s (%d%%)" if _obra_on_site else "indo pra obra: %s (%d%%)") % [_obra.obra_title(), pct]
	if _ai_state == "idle" and is_engineer():
		return "sem obras — esperando encomenda"
	if _ai_state == "idle" and is_doctor():
		return "sem enfermaria"
	if _ai_state == "cooking" and _prep_left > 0.0:
		return "preparando comida (%ds)" % ceili(_prep_left)
	var label: String = STATE_LABELS.get(_ai_state, _ai_state)
	if _station == null and STATE_GROUP.has(_ai_state):
		label += " (esperando)"
	if overtime and _is_night() and _ai_state != "home":
		label += " (turno extra)"
	return label


## Chamado pelas estações: esse ipezinho está trabalhando nelas agora?
func can_work_at(station: Node) -> bool:
	if _ai_state == "manual" or not auto_mode:
		return not _moving
	return station == _station


# ------------------------------------------------------------ movimento
func _physics_process(delta: float) -> void:
	_agent.max_speed = speed * _speed_bonus() * 1.2  # o desvio (RVO) limita a velocidade nisso
	var desired := Vector2.ZERO
	if _moving:
		var dist_to_target := global_position.distance_to(_target)
		if dist_to_target <= arrive_distance or _agent.is_navigation_finished():
			_moving = false
		else:
			var next := _agent.get_next_path_position()
			var to_next := next - global_position
			var d := to_next.length()
			if d > 0.01:
				# nunca passa do próximo ponto do caminho num quadro só (com FPS baixo o
				# passo ficava maior que a tolerância e ele ia e voltava em volta do ponto)
				var spd := minf(_get_effective_speed(), minf(dist_to_target, d + 2.0) / delta)
				desired = to_next / d * spd

	_check_stuck(delta)
	if _agent.avoidance_enabled:
		# parado (trabalhando/esperando) tem prioridade: quem está andando desvia dele
		_agent.avoidance_priority = 0.5 if _moving else 1.0
		_agent.velocity = desired  # a resposta chega em _on_velocity_computed
	else:
		_apply_velocity(desired)
	_update_animation(delta)


## Bloco 31b: anti-travamento. "Andando" sem sair do lugar (a malha de navegação foi
## refeita com ele dentro de um obstáculo novo — canteiro, prédio, save carregado — ou
## o desvio travou entre dois): 1) refaz o caminho; 2) puxa pro ponto andável mais
## perto e tenta de novo; 3) desiste de andar até ali (a IA decide de novo).
func _check_stuck(delta: float) -> void:
	# desvio desligado de propósito (passando por alguém): volta ao normal quando acabar
	if _ghost_left > 0.0:
		_ghost_left -= delta
		if _ghost_left <= 0.0 and not _inside and not downed:
			_agent.avoidance_enabled = avoidance_enabled
	if not _moving:
		_stuck_time = 0.0
		_stuck_stage = 0
		return
	# "saiu do lugar" = andou pelo menos 12 px (tremer no lugar, empurrado pelo desvio, não conta)
	if global_position.distance_to(_stuck_pos) > 12.0:
		_stuck_pos = global_position
		_stuck_time = 0.0
		_stuck_stage = 0
		return
	_stuck_time += delta
	if _stuck_stage == 0 and _stuck_time > STUCK_REPATH_TIME:
		_stuck_stage = 1
		_agent.target_position = _target  # refaz o caminho
		# alguém parado trabalhando no corredor: passa "por dentro" dele por um instante
		if _agent.avoidance_enabled:
			_agent.avoidance_enabled = false
			_ghost_left = 2.5
	elif _stuck_stage == 1 and _stuck_time > STUCK_SNAP_TIME:
		_stuck_stage = 2
		var map := _agent.get_navigation_map()
		var p := NavigationServer2D.map_get_closest_point(map, global_position)
		if p.distance_to(global_position) > 0.5:
			global_position = p  # estava fora da área andável
		_agent.target_position = _target
	elif _stuck_stage == 2 and _stuck_time > STUCK_SNAP_TIME * 2.0:
		_moving = false  # não dá pra chegar mais perto daqui
		_decision_timer = 0.0
		_stuck_time = 0.0
		_stuck_stage = 0


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	_apply_velocity(safe_velocity if _moving else Vector2.ZERO)


func _apply_velocity(v: Vector2) -> void:
	velocity = v
	if velocity.length_squared() > 0.5:
		move_and_slide()
	# Bloco 36: quem vai nas costas acompanha no mesmo passo (sem ficar um quadro atrás)
	if carrying_patient != null and is_instance_valid(carrying_patient) and carrying_patient._carried_by == self:
		carrying_patient.global_position = global_position + Vector2(0, 1)


func _get_effective_speed() -> float:
	var load_ratio := carrying / cargo_capacity
	var penalty := 1.0 - (load_ratio * loaded_speed_penalty)
	var s := speed * penalty
	if hunger <= 0.0:
		s *= starving_speed_mult
	if injured:
		s *= injured_speed_mult
	if holding_robot != null:
		s *= carry_robot_speed_mult
	if carrying_patient != null:
		s *= carry_patient_speed_mult
	s *= [1.0, irritated_speed_mult, furious_speed_mult][_mood]  # zanga acumula com a lesão
	return s * _speed_bonus()


## Bônus de velocidade das "Trilhas batidas" do Centro da Vila.
func _speed_bonus() -> float:
	var hub := _village_hub()
	return hub.speed_mult() if hub else 1.0


func _village_hub() -> Node:
	if _hub_node == null or not is_instance_valid(_hub_node):
		_hub_node = get_tree().get_first_node_in_group("village_hub")
	return _hub_node


# ------------------------------------------------------------ fome / IA
func _process(delta: float) -> void:
	var was_starving := hunger <= 0.0
	var sun := _sun()
	var decay: float = hunger_decay * (sleep_hunger_mult if _resting else 1.0) * (sun.hunger_mult() if sun else 1.0)  # inverno: mais fome
	hunger = maxf(hunger - decay * delta, 0.0)
	if int(hunger) != _last_hunger_int:
		_update_hunger_label()
	if hunger <= 0.0 and not was_starving:
		_on_starving()

	_work_timer = maxf(_work_timer - delta, 0.0)
	_update_anger(delta)
	# machucado: só cura DEITADO num leito da enfermaria; fora dele o relógio corre
	if injured:
		_update_injury(delta)
	_equip_tick(delta)  # Bloco 42: casaco no inverno, traje nas zonas de perigo
	if _ai_state == "guard":
		_guard_tick(delta)
	elif combat_hp >= 0.0:
		combat_hp = guard_max_hp()  # fora da luta recupera o fôlego
	# felicidade anda devagar pro alvo (na taverna quem manda é a taverna)
	if _at_taverna == null:
		happiness = move_toward(happiness, happiness_target(), happiness_drift * delta)
	_strike_refuse_cd = maxf(_strike_refuse_cd - delta, 0.0)
	if _manual_timer > 0.0 and not (_ai_state == "manual" and _moving):
		_manual_timer -= delta

	if auto_mode and _manual_timer <= 0.0 and not (_ai_state == "manual" and _moving):
		_decision_timer -= delta
		if _decision_timer <= 0.0:
			_decision_timer = decision_interval * randf_range(0.85, 1.15)
			_decide_next_action()

	# chegou na porta de casa (ou no cantinho onde dorme ao relento)
	if _ai_state == "home" and not _resting and not _moving:
		if global_position.distance_to(_rest_position()) <= REST_REACH:
			_start_resting()
	# Bloco 36: caído nas costas do médico acompanha ele
	if _carried_by != null:
		if not is_instance_valid(_carried_by) or _carried_by.get("carrying_patient") != self:
			_carried_by = null  # largou (o médico se machucou, trocou de função...)
		else:
			global_position = _carried_by.global_position + Vector2(0, 1)
	# médico: chegou no caído -> põe nas costas; chegou na enfermaria -> entrega
	if _ai_state == "rescue" and _rescue != null and is_instance_valid(_rescue):
		if carrying_patient == null:
			var d := global_position.distance_to(_rescue.global_position)
			if d <= 22.0 or (not _moving and d <= 44.0):
				carrying_patient = _rescue
				_rescue.picked_up_by(self)
				_popup("Te peguei!", Color(0.6, 0.9, 1.0))
				_decision_timer = 0.0
		else:
			var ward := _closest_in_group("enfermarias")
			var dd := global_position.distance_to(ward.doctor_spot()) if ward else INF
			if ward and (dd <= REST_REACH + 8.0 or (not _moving and dd <= 40.0)):
				var p := carrying_patient
				carrying_patient = null
				_rescue = null
				p.delivered_to(ward)
				_decision_timer = 0.0
	# robô: pega quando chega nele; larga quando chega na Oficina
	if _ai_state == "robot" and not _moving and _robot_task != null and is_instance_valid(_robot_task):
		if holding_robot == null and global_position.distance_to(_robot_task.global_position) <= 18.0:
			holding_robot = _robot_task
			_robot_task.attach(self)
			_decision_timer = 0.0
		elif holding_robot != null and global_position.distance_to(_robot_task.drop_point()) <= 20.0:
			holding_robot = null
			_robot_task.deliver()
			_robot_task = null
			_decision_timer = 0.0
	# engenheiro: chegou na obra -> trabalha nela (só assim o tempo da obra anda)
	if _ai_state == "building" and _obra != null:
		if not is_instance_valid(_obra) or not _obra.obra_pending():
			_obra_stop()
			_decision_timer = 0.0  # acabou: próxima obra da fila
		elif not _obra_on_site:
			# chegou: parou perto (a obra pode estar dentro de um obstáculo) ou já está
			# colado no ponto mesmo com outro engenheiro esbarrando nele
			var dist := global_position.distance_to(_obra.obra_position(self))
			if (not _moving and dist <= OBRA_REACH) or dist <= 24.0:
				_moving = false
				_obra_on_site = true
				_obra.obra_join(self)
		else:
			_work_timer = 0.2  # martelada
			_obra.obra_work(delta * work_mult())  # zanga/tristeza deixam mais lento
			if not _obra.obra_pending():
				_popup("Obra pronta!", Color(0.55, 1.0, 0.5))
				_obra_stop()
				_decision_timer = 0.0
	# médico chegou na porta da enfermaria: entra e fica de plantão
	if _ai_state == "doctor" and _on_duty == null and not _moving:
		var ward := _closest_in_group("enfermarias")
		if ward and global_position.distance_to(ward.doctor_spot()) <= REST_REACH:
			_start_duty(ward)
	# chegou no lugar reservado da taverna: entra
	if _ai_state == "leisure" and _at_taverna == null and not _moving and _station_ok_for("leisure"):
		if global_position.distance_to(_station.get_slot_position(_slot)) <= REST_REACH:
			_enter_taverna()
	# chegou no leito reservado da enfermaria: deita
	if _ai_state == "infirmary" and injured and not _admitted and not _moving and _station_ok_for("infirmary"):
		if global_position.distance_to(_station.get_slot_position(_slot)) <= REST_REACH:
			_admit()


func _choose_state() -> String:
	# Bloco 36: caído em combate não anda — espera o médico (ou vai nas costas dele).
	if downed:
		return "downed"
	# Machucado: só cura na ENFERMARIA — vai pra lá (ou espera leito na porta),
	# de dia ou de noite, antes de qualquer outra coisa.
	if injured and _has_infirmary():
		return "infirmary"
	# Bloco 36: guarda caído em combate — o médico larga tudo (plantão, cama, até de noite)
	# e vai buscar. Só o médico resgata.
	if is_doctor() and _has_infirmary() and (carrying_patient != null or _pick_rescue() != null):
		return "rescue"
	# Onda solar: quem está na superfície corre pro abrigo; no fundo segue (a rocha protege).
	var sun := _sun()
	if sun and sun.shelter_now():
		var env := get_tree().get_first_node_in_group("environment")
		if env == null or env.level_at(global_position) == 0:
			return "home"
		if _ai_state == "mining" and _station_ok_for("mining"):
			return "mining"
		return "idle"
	# Prioridade 0: de noite o turno acabou — todo mundo pra casa, mesmo com fome ou carga.
	# Exceção: quem está em TURNO EXTRA continua trabalhando (e ficando zangado).
	if _is_night() and not overtime and not is_guard():
		return "home"
	# Sem enfermaria na cena (fallback antigo): machucado descansa em casa.
	if injured:
		return "home"
	# Prioridade 1: comer. Quem já está comendo só sai quando estiver quase cheio.
	# Sem comida no comedouro não adianta esperar lá: segue trabalhando (com fome).
	var food_ok := _food_available()
	if _ai_state == "eating" and hunger < hunger_max * eat_until_ratio and food_ok:
		return "eating"
	if hunger < hunger_threshold and food_ok:
		return "eating"
	# Lazer: triste vai pra taverna (se existir) e fica até se animar.
	if _ai_state == "leisure" and happiness < leisure_until and _station_ok_for("leisure"):
		return "leisure"
	if happiness < leisure_below and _has_usable_station("tavernas"):
		return "leisure"
	# Greve: ninguém trabalha (só come, dorme, se trata e vai à taverna).
	if _on_strike():
		return "strike"
	# Mandaram buscar o robô antigo: vai, pega e leva pra Oficina.
	if _robot_task != null:
		if is_instance_valid(_robot_task) and _robot_task.needs_carrier(self):
			return "robot"
		_robot_task = null
	# Comida PRONTA na cesta (só de save de antes do Bloco 27): entrega no comedouro.
	if food_carrying > 0.0:
		return "delivering"
	# Bloco 27: matéria-prima nas mãos de quem não é cozinheiro vai pro armazém
	# (caçador com a mochila cheia / sem mais fruta nem caça, ou quem trocou de função).
	# (O cozinheiro com matéria-prima vai preparar: ver o bloco dele mais abaixo.)
	if raw_carrying > 0.0 and not is_cook():
		var pack_full := _raw_units >= hunter_carry - 0.01
		# (quem já está colhendo/caçando continua até a fonte acabar; só depois descarrega)
		var keep_going := _ai_state in ["foraging", "hunting"] and _station_ok_for(_ai_state)
		if not is_hunter() or pack_full or _ai_state == "stocking" or (not keep_going and not _hunter_has_work()):
			return "stocking"
	# Madeira nas costas: leva pro armazém (lenhador cheio / sem árvore, ou quem deixou de ser lenhador).
	if wood_carrying > 0.0:
		var wood_full := wood_carrying >= lumber_carry - 0.01
		# (quem já está cortando continua até a árvore virar toco; só depois vai descarregar)
		var keep_chopping := _ai_state == "chopping" and _station_ok_for("chopping")
		if not is_lumber() or wood_full or _ai_state == "hauling" or (not keep_chopping and not _has_usable_station("arvores")):
			return "hauling"
	# Bloco 25: quem não é minerador não fica com minério na mão — entrega antes
	# (ex.: trocou de função no meio da carga, ou tiraram a função dele).
	# Pesquisador fica de fora: sem laboratório ele volta a minerar (como já era),
	# e mandar guardar cada pedrinha viraria um vai-e-volta sem fim.
	if carrying > 0.0 and not is_miner() and not is_researcher():
		return "storing"
	# Médico (Bloco 30): plantão DENTRO da enfermaria, tendo internado ou não (esperando
	# por lá: não sai pra minerar sozinho). Comer, dormir, se tratar etc. vêm antes.
	if is_doctor():
		return "doctor" if _has_infirmary() else "idle"
	# Engenheiro (Bloco 31): vai tocar a obra mais antiga encomendada; sem obra, espera
	# no Centro da Vila. (Minério na mão já foi entregue pela regra de cima.)
	if is_engineer():
		return "building" if _pick_obra() != null else "idle"
	# Guarda: à noite fica nos portões; de dia treina (até ficar pronto) e descansa.
	# Bloco 35: desarmado vai ao Arsenal pegar outra arma (até de noite: sem arma no
	# posto não adianta); de dia também troca por uma melhor que estiver no cavalete.
	if is_guard():
		if (_ai_state == "rearming" and _station_ok_for("rearming")) or (_wants_rearm() and _has_usable_station("arsenais")):
			return "rearming"
		if _is_night():
			return "guard"
		if combat_skill < 1.0 and ((_ai_state == "training" and _station_ok_for("training")) or _has_usable_station("campos")):
			return "training"
		return "home"
	# Pesquisador: de dia no laboratório se tiver pesquisa em andamento; senão trabalha normal.
	if is_researcher():
		if (_ai_state == "research" and _station_ok_for("research")) or _has_usable_station("laboratorios"):
			return "research"
	# Lenhador: larga o minério que tiver e passa a só cortar e levar madeira.
	if is_lumber():
		if carrying > 0.0:
			return "storing"
		if _ai_state == "chopping" and _station_ok_for("chopping"):
			return "chopping"
		if _has_usable_station("arvores"):
			return "chopping"
		return "idle"
	# Cozinheiro (Bloco 27): busca matéria-prima no armazém e PREPARA no comedouro.
	# (Minério na mão já foi entregue pela regra do Bloco 25 lá em cima.)
	if is_cook():
		# no meio de uma leva: fica até ficar pronta
		if _ai_state == "cooking" and raw_carrying > 0.0 and _station_ok_for("cooking"):
			return "cooking"
		if raw_carrying >= cook_carry - 0.01:
			return "cooking"
		if _ai_state == "fetching" and _station_ok_for("fetching"):
			return "fetching"
		if _raw_available():
			return "fetching"
		if raw_carrying > 0.0:
			return "cooking"  # o armazém acabou: prepara o que já tem
		return "idle"  # sem matéria-prima: espera (o HUD mostra "esperando matéria-prima")
	# Caçador (Bloco 27/28): caça tem PRIORIDADE (rende mais) quando tem arco e alguma toca
	# com caça; com todas as tocas esgotadas, colhe fruta em vez de ficar parado; assim que
	# uma toca volta, larga a fruta e volta a caçar (a mochila é a mesma: não perde nada).
	# Bloco 34: horta e tocas ficam na clareira, então o caçador trabalha todo lá fora e só
	# atravessa o túnel de volta pra deixar a matéria-prima no armazém.
	if is_hunter():
		if _ai_state == "hunting" and _station_ok_for("hunting"):
			return "hunting"
		if _has_usable_station("caca"):  # a toca só conta como usável com arco e flecha
			return "hunting"
		if _ai_state == "foraging" and _station_ok_for("foraging"):
			return "foraging"
		if _has_usable_station("coleta_comida"):
			return "foraging"
		return "idle"
	# Bloco 25: sem função não trabalha sozinho — espera no Centro da Vila até o
	# jogador designar. (Comer, dormir, se tratar, taverna e greve vêm antes e seguem iguais.)
	if has_no_job():
		return "idle"
	# Daqui pra baixo: minerador (e pesquisador sem laboratório, como antes).
	# Prioridade 2: depositar carga cheia (e não desistir no meio do caminho).
	if carrying >= cargo_capacity - 0.01:
		return "storing"
	if _ai_state == "storing" and carrying > 0.0:
		return "storing"
	# Prioridade 3: minerar (continua na mesma jazida enquanto ela tiver minério).
	if _ai_state == "mining" and _station_ok_for("mining"):
		return "mining"
	if _find_best_station("minerios") != null:
		return "mining"
	# Sem jazida disponível: guarda o que já tem.
	if carrying > 0.0:
		return "storing"
	return "idle"


func _decide_next_action() -> void:
	var desired := _choose_state()

	if desired == "home":
		_release_station()
		_set_state("home")
		_go_home()
		return

	if desired == "strike":
		_release_station()
		_set_state("strike")
		_go_protest()
		return

	if desired == "guard":
		if _ai_state != "guard":
			_release_station()
			_set_state("guard")
		return  # quem manda é o _guard_tick (posto / luta)

	if desired == "downed":
		if _ai_state != "downed":
			_release_station()
			_set_state("downed")
		_moving = false
		return

	if desired == "rescue":
		if _ai_state != "rescue":
			_release_station()
			_set_state("rescue")
		var dest := _rescue_dest()
		if not _moving or _target.distance_to(dest) > 2.0:
			_go_to(dest)
		return

	if desired == "building":
		var site := _pick_obra()
		if site != _obra:
			_obra_stop()
			_obra = site
		if _ai_state != "building":
			_release_station()
			_set_state("building")
		if not _obra_on_site:
			var pos: Vector2 = _obra.obra_position(self)
			if not _moving or _target.distance_to(pos) > 2.0:
				_go_to(pos)
		return

	if desired == "doctor":
		if _ai_state != "doctor":
			_release_station()
			_set_state("doctor")
		if _on_duty == null:
			var ward := _closest_in_group("enfermarias")
			if ward and (not _moving or _target.distance_to(ward.doctor_spot()) > 2.0):
				_go_to(ward.doctor_spot())
		return

	if desired == "robot":
		_release_station()
		_set_state("robot")
		var dest: Vector2 = _robot_task.drop_point() if holding_robot != null else _robot_task.global_position
		if not _moving or _target.distance_to(dest) > 2.0:
			_go_to(dest)
		return

	if desired == _ai_state and (_admitted or _at_taverna != null):
		return  # deitado no leito / sentado no balcão: não se mexe
	if desired == _ai_state and _station_ok_for(desired):
		# Continua o que está fazendo; se foi empurrado pra fora do slot, volta.
		var slot_pos: Vector2 = _station.get_slot_position(_slot)
		if not _moving and global_position.distance_to(slot_pos) > 6.0:
			_go_to(slot_pos)
		return

	_release_station()
	_set_state(desired)

	if desired == "idle":
		if has_no_job() or is_engineer():
			_idle_at_hub()
			return
		if not _moving and randf() < 0.35:
			var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(10.0, idle_wander_radius)
			_go_to(global_position + offset)
		return

	var group: String = STATE_GROUP[desired]
	var station := _find_best_station(group)
	if station:
		_station = station
		_slot = station.reserve_slot(self)
		_go_to(station.get_slot_position(_slot))
	else:
		# Tudo ocupado: espera perto da estação mais próxima e tenta de novo no próximo tick.
		var nearest := _closest_in_group(group)
		if nearest:
			_go_to(nearest.get_wait_position(self))


## Sem função: vai pra frente do Centro da Vila e fica zanzando por ali.
## (Sem Centro da Vila na cena: fica passeando onde está, como o ocioso antigo.)
func _idle_at_hub() -> void:
	if _moving:
		return
	var sun := _sun()
	if sun and sun.shelter_now():
		return  # onda solar: quem está lá embaixo fica protegido onde está
	var hub := _village_hub()
	if hub == null or not (hub is Node2D):
		if randf() < 0.35:
			_go_to(global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(10.0, idle_wander_radius))
		return
	var center: Vector2 = (hub as Node2D).global_position + Vector2(0, 55)  # na frente da fachada
	var far := global_position.distance_to(center) > IDLE_HUB_RADIUS + 20.0
	if far or randf() < 0.25:
		var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, IDLE_HUB_RADIUS)
		offset.y *= 0.5  # área achatada, esparramada na frente do prédio
		_go_to(center + offset)


func _station_ok_for(state: String) -> bool:
	if _station == null or not is_instance_valid(_station) or _slot < 0:
		return false
	if state == "mining":
		return _station.has_ore() and carrying < cargo_capacity
	if state == "gathering":
		return _station.has_food() and food_carrying < cook_carry - 0.01
	if state == "foraging":
		return _station.has_food() and _raw_units < hunter_carry - 0.01
	if state == "hunting":
		return _station.has_game() and _station.bow_ready() and _raw_units < hunter_carry - 0.01
	if state == "stocking":
		return raw_carrying > 0.0
	if state == "fetching":
		return _station.raw_stored >= 0.5 and raw_carrying < cook_carry - 0.01
	if state == "cooking":
		return raw_carrying > 0.0 and _station.space_left() > 0.5
	if state == "delivering":
		return food_carrying > 0.0 and _station.space_left() > 0.5
	if state == "eating":
		return _station.has_food()
	if state == "chopping":
		return _station.has_wood() and wood_carrying < lumber_carry - 0.01
	if state == "hauling":
		return wood_carrying > 0.0
	if state == "research":
		return _station.is_usable()
	if state == "rearming":
		return is_guard() and _wants_rearm()
	return true


## Chegou na gaiola do elevador (NavigationLink2D): desce/sobe na hora.
func _on_link_reached(details: Dictionary) -> void:
	var link = details.get("owner")
	if not (link is Node) or not link.get_parent() \
			or not (link.get_parent().is_in_group("elevador") or link.get_parent().is_in_group("elevador_abismo")):
		return
	var exit: Vector2 = details.get("link_exit_position", global_position)
	global_position = exit
	Audio.elevator(exit)  # corrente + "clanc" da gaiola
	_body.modulate.a = 0.0
	create_tween().tween_property(_body, "modulate:a", 1.0, 0.35)


## Multiplicador de acidente pela profundidade (nível 2 = mais perigoso).
func depth_danger() -> float:
	var env := get_tree().get_first_node_in_group("environment")
	return env.danger_mult_at(global_position) if env else 1.0


## Existe alguma estação do grupo REALMENTE disponível agora? (Diferente de
## _find_best_station, não aceita a estação atual só por ser a atual: árvore que
## virou toco ou horta colhida não contam — aí o lenhador/cozinheiro vai descarregar.)
func _has_usable_station(group_name: String) -> bool:
	for node in get_tree().get_nodes_in_group(group_name):
		if node.has_method("is_usable") and not node.is_usable():
			continue
		if node.has_method("has_free_slot_for") and not node.has_free_slot_for(self):
			continue
		return true
	return false


## Estação com slot livre que compensa mais: perto e, de preferência, menos lotada.
func _find_best_station(group_name: String) -> Node2D:
	var best: Node2D = null
	var best_score := INF
	for node in get_tree().get_nodes_in_group(group_name):
		if node.has_method("is_usable") and not node.is_usable() and node != _station:
			continue
		if node.has_method("has_free_slot_for") and not node.has_free_slot_for(self):
			continue
		if node.has_method("accepts_worker") and not node.accepts_worker(self) and node != _station:
			continue
		var score := global_position.distance_to(node.global_position)
		if node.has_method("occupied_slot_count") and node != _station:
			score += node.occupied_slot_count() * 40.0
		# minério mais valioso "parece mais perto" (cobre vale 2x o ferro -> distância pela metade)
		if node.has_method("get_value_weight"):
			score /= maxf(node.get_value_weight(), 0.1)
		if score < best_score:
			best_score = score
			best = node
	return best


func _closest_in_group(group_name: String) -> Node2D:
	var closest: Node2D = null
	var closest_dist := INF
	for node in get_tree().get_nodes_in_group(group_name):
		var dist := global_position.distance_to(node.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = node
	return closest


func _release_station() -> void:
	if _station != null and is_instance_valid(_station):
		_station.release_slot(self)
	_station = null
	_slot = -1


func _set_state(new_state: String) -> void:
	if new_state == _ai_state:
		return
	if _ai_state == "home":
		_stop_resting()
	if _ai_state == "infirmary":
		_discharge()
	if _ai_state == "leisure":
		_leave_taverna()
	if _ai_state == "doctor":
		_end_duty()
	if _ai_state == "building":
		_obra_stop()  # pausa a obra onde estava (o progresso fica na obra)
	if _ai_state == "strike":
		_strike_spot = null
	if _ai_state == "robot":
		_drop_robot()
	if _ai_state == "guard":
		_foe = null
	if _ai_state == "rescue":
		_drop_patient()
	_ai_state = new_state
	state_changed.emit(new_state)


# ------------------------------------------------------------ turno / casa
func _sync_tool_visual() -> void:
	if not is_inside_tree():
		return
	var oficina := get_tree().get_first_node_in_group("oficina")
	if oficina and oficina.has_tool("picareta_aco"):
		on_tool_crafted("picareta_aco")
	else:
		_refresh_tool_texture()


func _is_night() -> bool:
	var cycle := get_tree().get_first_node_in_group("day_night")
	return cycle != null and cycle.is_night()


## Chamado pelo DayNight na virada de fase: reage logo (com um atraso aleatório curto).
func on_phase_changed(_night: bool) -> void:
	wake_decision()


## Repensa o que fazer logo (virada de fase, começo/fim de greve).
func wake_decision() -> void:
	if auto_mode and _ai_state != "manual":
		_decision_timer = randf_range(0.05, phase_react_delay)


# ------------------------------------------------------------ felicidade / greve
func _morale() -> Node:
	return get_tree().get_first_node_in_group("morale")


func _on_strike() -> bool:
	var m := _morale()
	return m != null and m.on_strike


## Motivos que somam no alvo de felicidade: [[texto, valor], ...] (os da vila vêm do morale.gd).
func happiness_factors() -> Array:
	var f: Array = []
	f.append(["tem cama", 8.0] if has_home() else ["sem cama", -15.0])
	if hunger <= 0.0:
		f.append(["passando fome", -30.0])
	elif hunger < hunger_threshold:
		f.append(["com fome", -10.0])
	if _mood == 2:
		f.append(["furioso (turno extra)", -25.0])
	elif _mood == 1:
		f.append(["irritado (turno extra)", -10.0])
	if injured:
		f.append(["machucado grave", -18.0] if injury_severity == "grave" else ["machucado", -8.0])
	var env := get_tree().get_first_node_in_group("environment")
	if env and env.has_method("is_abyss") and env.is_abyss(global_position):
		f.append(["calor do abismo", -8.0])
	var m := _morale()
	if m:
		f.append_array(m.village_factors())
	return f


func happiness_target() -> float:
	var t := happiness_base
	for f in happiness_factors():
		t += f[1]
	return clampf(t, 0.0, 100.0)


## 0 revoltado, 1 triste, 2 contente, 3 feliz.
func happiness_level() -> int:
	if happiness < miserable_below:
		return 0
	if happiness < sad_below:
		return 1
	if happiness < happy_at:
		return 2
	return 3


func happiness_label() -> String:
	return ["revoltado", "triste", "contente", "feliz"][happiness_level()]


func _happiness_work_mult() -> float:
	return [miserable_work_mult, sad_work_mult, 1.0, happy_work_mult][happiness_level()]


# ------------------------------------------------------------ guarda / combate
func guard_max_hp() -> float:
	return guard_base_hp + guard_hp_per_skill * combat_skill


func _defense() -> Node:
	return get_tree().get_first_node_in_group("defense")


## Campo de treino chama enquanto ele treina.
func train(amount: float) -> void:
	if combat_skill >= 1.0:
		return
	combat_skill = minf(combat_skill + amount, 1.0)
	_work_timer = 0.2  # balança a lança no boneco
	if combat_skill >= 1.0:
		_popup("Pronto pra lutar!", Color(0.55, 1.0, 0.5))
		_decision_timer = randf_range(0.05, 0.4)


## De noite, de guarda: vai pro posto; vendo criatura por perto, parte pra cima.
func _guard_tick(delta: float) -> void:
	_attack_cd -= delta
	if combat_hp < 0.0:
		combat_hp = guard_max_hp()
	var def := _defense()
	if _foe != null and (not is_instance_valid(_foe) or not _foe.is_alive() \
			or global_position.distance_to(_foe.global_position) > guard_aggro * 1.5):
		_foe = null
	if _foe == null:
		var best_d := guard_aggro
		for c in get_tree().get_nodes_in_group("criaturas"):
			if not c.is_alive():
				continue
			var d := global_position.distance_to(c.global_position)
			if d < best_d:
				best_d = d
				_foe = c
	if _foe == null:
		var post: Vector2 = def.guard_post(self) if def else global_position
		if global_position.distance_to(post) > 10.0 and (not _moving or _target.distance_to(post) > 4.0):
			_go_to(post)
		return
	var reach: float = def.weapon_reach(weapon) if def else 18.0
	var dist := global_position.distance_to(_foe.global_position)
	if dist > reach:
		if not _moving or _target.distance_to(_foe.global_position) > 12.0:
			_go_to(_foe.global_position)
		return
	_moving = false
	_facing = signf(_foe.global_position.x - global_position.x) if absf(_foe.global_position.x - global_position.x) > 1.0 else _facing
	_work_timer = 0.3  # golpe
	if _attack_cd <= 0.0:
		_attack_cd = guard_attack_interval
		var dmg: float = (def.weapon_damage_vs(_foe, weapon) if def else 3.0) * lerpf(untrained_damage_mult, 1.0, combat_skill)
		_foe.take_hit(dmg, self)
		Audio.hit(global_position)
		_wear_weapon()


# ------------------------------------------------------------ arma do guarda (Bloco 35)
## Pega a arma (nova ou consertada: durabilidade cheia).
func equip(id: String) -> void:
	var def := _defense()
	weapon = id
	weapon_durability = def.weapon_max_durability(id) if def and id != "" else 0.0
	_refresh_tool_texture()


## 0..1 da durabilidade (pra HUD/painel).
func weapon_condition() -> float:
	var def := _defense()
	var mx: float = def.weapon_max_durability(weapon) if def and weapon != "" else 0.0
	return clampf(weapon_durability / mx, 0.0, 1.0) if mx > 0.0 else 0.0


## "Lança de ferro 32/45" / "desarmado".
func weapon_label() -> String:
	var def := _defense()
	if weapon == "":
		return "desarmado"
	var mx: float = def.weapon_max_durability(weapon) if def else 0.0
	return "%s %d/%d" % [def.WEAPON_NAMES.get(weapon, weapon) if def else weapon, ceili(weapon_durability), roundi(mx)]


## Cada golpe desferido gasta 1 de durabilidade; zerou, a arma quebra na mão.
func _wear_weapon() -> void:
	if weapon == "":
		return
	weapon_durability -= 1.0
	if weapon_durability <= 0.0:
		_break_weapon()


func _break_weapon() -> void:
	var def := _defense()
	var nm: String = def.WEAPON_NAMES.get(weapon, weapon) if def else weapon
	broken_weapon = weapon
	weapon = ""
	weapon_durability = 0.0
	_refresh_tool_texture()
	_tool.visible = false  # mãos vazias já neste quadro (a animação mantém depois)
	_broken_icon.visible = true
	_popup("%s quebrou!" % nm, Color(1.0, 0.45, 0.35))
	Audio.clank(global_position)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		var has_arsenal: bool = def != null and def.arsenal() != null
		hud.show_toast("%s de %s quebrou! %s" % [nm, display_name,
			"Vai ao Arsenal pegar outra." if has_arsenal else "Sem Arsenal, luta no soco (G: Defesa)."],
			Color(1.0, 0.55, 0.4))
	_decision_timer = 0.0  # já decide ir ao Arsenal


## Quer ir ao Arsenal? Desarmado: sempre (se existe Arsenal). De dia: se tem arma
## melhor no cavalete. (De noite, com arma na mão, fica no posto.)
func _wants_rearm() -> bool:
	if injured:
		return false
	var def := _defense()
	if def == null or def.arsenal() == null:
		return false
	if weapon == "":
		return true
	if _is_night() or def.invasion_active:
		return false
	return def.better_in_rack(weapon) != ""


## Arsenal chama enquanto ele está lá: devolve a quebrada/usada e pega a melhor que tiver.
func rearm(_arsenal: Node) -> void:
	if not is_guard() or _ai_state != "rearming":
		return
	var def := _defense()
	if def == null:
		return
	var before := weapon
	def.swap_weapon(self)
	if weapon != before:
		_popup("Pegou: %s" % def.WEAPON_NAMES.get(weapon, weapon), Color(0.55, 1.0, 0.5))
		Audio.forge(global_position)
	_decision_timer = 0.0


## Criatura bateu. Guarda de serviço aguenta (vida de luta); os outros se machucam.
func take_hit(amount: float, attacker: Node2D) -> void:
	if injured:
		return
	var flash := create_tween()
	flash.tween_property(_body, "self_modulate", Color(2.0, 0.5, 0.5), 0.06)
	flash.tween_property(_body, "self_modulate", Color.WHITE, 0.2)
	var cause: String = attacker.get("kind") if attacker and attacker.get("kind") else "criatura"
	if is_guard() and _ai_state == "guard":
		if combat_hp < 0.0:
			combat_hp = guard_max_hp()
		combat_hp -= amount
		_foe = attacker
		_popup("-%d" % roundi(amount), Color(1.0, 0.5, 0.4))
		if combat_hp <= 0.0:
			combat_hp = guard_max_hp()
			_fall_in_combat(cause)  # Bloco 36: cai no lugar, grave; só o médico resgata
		return
	var grave: float = attacker.get("grave_chance") if attacker and attacker.get("grave_chance") != null else 0.2
	hurt(cause, "grave" if randf() < grave else "leve")


# ------------------------------------------------------------ caído em combate (Bloco 36)
## Perdeu a luta: cai GRAVE ali mesmo, não anda, e abre a brecha no portão dele.
func _fall_in_combat(cause: String) -> void:
	downed = true
	hurt(cause, "grave")
	var res := _research()
	_care_left = downed_untreated_time * (res.untreated_mult() if res else 1.0)
	var def := _defense()
	downed_gate = def.nearest_gate_id(global_position) if def else ""
	_release_station()
	_set_state("downed")
	_moving = false
	_foe = null
	_agent.avoidance_enabled = false  # caído no chão não empurra ninguém
	_rescuer = null
	_carried_by = null
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		var has_doc := get_tree().get_nodes_in_group("ipezinhos").any(func(w): return w.is_doctor() and not w.injured)
		hud.show_banner("GUARDA CAÍDO: %s" % _display(),
			"Caiu no %s e não levanta sozinho. Só um MÉDICO pode levar pra enfermaria%s. Enquanto isso o portão fica aberto pra roubo." % [
				def.gate_label(downed_gate) if def else "portão", "" if has_doc else " — NÃO HÁ MÉDICO (tecla 3)"])
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w.is_doctor():
			w.wake_decision()


## (caído) o médico chegou e pôs nas costas: o relógio pausa.
func picked_up_by(doctor: Node) -> void:
	_carried_by = doctor
	_rescuer = doctor
	global_position = doctor.global_position + Vector2(0, 1)  # já nas costas neste quadro


## (caído) o médico largou no caminho: fica ali, o relógio volta a correr.
func dropped() -> void:
	_carried_by = null
	_rescuer = null
	wake_decision()


## (caído) chegou na enfermaria nas costas do médico: deita num leito se tiver; senão
## espera na porta com o relógio normal de grave (com médico lá dentro corre mais devagar).
func delivered_to(ward: Node) -> void:
	downed = false
	downed_gate = ""
	_carried_by = null
	_rescuer = null
	_agent.avoidance_enabled = avoidance_enabled
	global_position = ward.doctor_spot()
	var res := _research()
	_care_left = maxf(_care_left, grave_untreated_time * (res.untreated_mult() if res else 1.0))
	_death_warned = false
	_release_station()
	if ward.has_free_slot_for(self):
		_station = ward
		_slot = ward.reserve_slot(self)
		_set_state("infirmary")
		global_position = ward.get_slot_position(_slot)
		_admit()
	else:
		_set_state("idle")
		_decision_timer = 0.0  # espera leito na porta
	_popup("Na enfermaria!", Color(0.55, 1.0, 0.5))


## (médico) o caído que ele vai buscar: o que já é dele, ou o mais perto sem médico.
func _pick_rescue() -> Node:
	if _rescue != null and is_instance_valid(_rescue) and _rescue.downed:
		return _rescue
	_rescue = null
	if injured:
		return null
	var best: Node = null
	var best_d := INF
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w == self or not w.downed:
			continue
		var r = w._rescuer
		if r != null and is_instance_valid(r) and r != self and r.get("_rescue") == w:
			continue  # outro médico já vai buscar esse
		var d := global_position.distance_to(w.global_position)
		if d < best_d:
			best_d = d
			best = w
	if best:
		_rescue = best
		best._rescuer = self
	return best


func _rescue_dest() -> Vector2:
	if carrying_patient != null:
		var ward := _closest_in_group("enfermarias")
		return ward.doctor_spot() if ward else global_position
	return _rescue.global_position if _rescue != null and is_instance_valid(_rescue) else global_position


## (médico) larga quem estiver carregando (saiu do resgate por qualquer motivo).
func _drop_patient() -> void:
	if carrying_patient != null and is_instance_valid(carrying_patient):
		carrying_patient.dropped()
	carrying_patient = null
	if _rescue != null and is_instance_valid(_rescue) and _rescue._rescuer == self:
		_rescue._rescuer = null
	_rescue = null


## Mandaram buscar o robô antigo (robo.gd).
func assign_robot(r: Node) -> void:
	_robot_task = r
	_manual_timer = 0.0
	wake_decision()


## Larga o robô onde está (anoiteceu, machucou, greve, ordem...). Continua encarregado.
func _drop_robot() -> void:
	if holding_robot != null:
		if is_instance_valid(holding_robot):
			holding_robot.detach()
		holding_robot = null


## Taverna chama a cada frame com quem está lá dentro.
func have_fun(amount: float) -> void:
	happiness = minf(happiness + amount, 100.0)
	if happiness >= leisure_until and _decision_timer > 0.3:
		_decision_timer = randf_range(0.05, 0.3)  # animou: sai logo


## Bloco 41: parque perto (morale.gd chama a cada quadro) — ânimo aos pouquinhos, até `cap`.
func enjoy_park(amount: float, cap: float) -> void:
	if happiness < cap:
		happiness = minf(happiness + amount, cap)


## Festa: alegria na hora.
func cheer(amount: float) -> void:
	happiness = minf(happiness + amount, 100.0)
	_popup("Eba! Festa!", Color(1.0, 0.85, 0.4))


func _enter_taverna() -> void:
	_at_taverna = _station
	_resting = true  # relaxando: a zanga baixa e a fome gasta menos
	_inside = true
	_moving = false
	_agent.avoidance_enabled = false
	_at_taverna.set_inside(self, true)
	queue_redraw()


# ------------------------------------------------------------ engenheiro (Bloco 31)
func is_engineer() -> bool:
	return job == ROLE_ENGINEER


## Qual obra atender. FILA: a encomenda mais antiga primeiro. Quem já está numa obra
## termina ela antes de trocar. Com vários engenheiros, cada um prefere uma obra que
## ninguém está tocando; se todas já têm alguém, ajuda na mais antiga (o trabalho soma).
func _pick_obra() -> Node:
	if _obra != null and is_instance_valid(_obra) and _obra.obra_pending():
		return _obra
	var oldest_free: Node = null
	var oldest_any: Node = null
	for site in get_tree().get_nodes_in_group("obras"):
		if not site.has_method("obra_pending") or not site.obra_pending():
			continue
		var t: float = site.obra_ordered_at()
		if oldest_any == null or t < oldest_any.obra_ordered_at():
			oldest_any = site
		# "tocando" = já trabalhando OU a caminho (senão dois engenheiros designados juntos
		# escolhem a mesma obra antes de qualquer um chegar)
		var taken := get_tree().get_nodes_in_group("ipezinhos").any(
			func(w): return w != self and w.get("_obra") == site)
		if not taken and (oldest_free == null or t < oldest_free.obra_ordered_at()):
			oldest_free = site
	return oldest_free if oldest_free != null else oldest_any


## Bloco 31b: nuvenzinha de poeira/lascas onde o martelo bate (fica no mundo, não
## acompanha o ipezinho, e some sozinha).
func _dust_puff() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 7
	p.lifetime = 0.55
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.gravity = Vector2(0, 90)
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 45.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = Color(0.78, 0.68, 0.55, 0.8)
	p.z_index = 5
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(16.0 * _facing, -6.0)
	p.emitting = true
	p.finished.connect(p.queue_free)


## Sai da obra (pausa): o que já foi feito fica guardado nela.
func _obra_stop() -> void:
	if _obra != null and is_instance_valid(_obra) and _obra_on_site:
		_obra.obra_leave(self)
	_obra = null
	_obra_on_site = false


# ------------------------------------------------------------ médico (Bloco 30)
func is_doctor() -> bool:
	return job == ROLE_DOCTOR


func _start_duty(ward: Node) -> void:
	_on_duty = ward
	_inside = true  # lá dentro: some do mapa, como na taverna
	_moving = false
	_agent.avoidance_enabled = false
	ward.add_doctor(self)
	queue_redraw()


func _end_duty() -> void:
	if _on_duty == null:
		return
	if is_instance_valid(_on_duty):
		_on_duty.remove_doctor(self)
	_on_duty = null
	_inside = false
	_agent.avoidance_enabled = avoidance_enabled
	queue_redraw()


func _leave_taverna() -> void:
	if _at_taverna == null:
		return
	if is_instance_valid(_at_taverna):
		_at_taverna.set_inside(self, false)
	_at_taverna = null
	_resting = false
	_inside = false
	_agent.avoidance_enabled = avoidance_enabled
	queue_redraw()


## Greve: vai pra frente do Centro da Vila e fica lá com a plaquinha.
func _go_protest() -> void:
	if _strike_spot == null:
		var hub := _village_hub()
		var center: Vector2 = hub.global_position if hub else global_position
		var p := center + Vector2.from_angle(randf_range(0.35, PI - 0.35)) * randf_range(60.0, 90.0)
		_strike_spot = NavigationServer2D.map_get_closest_point(_agent.get_navigation_map(), p)
	if not _moving and global_position.distance_to(_strike_spot) > 6.0:
		_go_to(_strike_spot)


func has_home() -> bool:
	return _home != null and is_instance_valid(_home)


## Pega uma cama (se ainda não tem casa). Vindo do save, tenta a mesma cama de antes;
## senão escolhe a casa com MAIS camas livres (empate: a mais perto), pra espalhar
## os ipezinhos pela vila em vez de empilhar todo mundo na casa mais próxima.
func _claim_home() -> void:
	if has_home() or not is_inside_tree():
		return
	if _saved_home != "":
		for casa in get_tree().get_nodes_in_group("casas"):
			if String(casa.name) == _saved_home:
				var bed: int = casa.claim_specific_bed(self, _saved_home_slot)
				if bed >= 0:
					_home = casa
					_home_slot = bed
				break
		_saved_home = ""
		if has_home():
			return
	var best: Node2D = null
	var best_free := 0
	var best_dist := INF
	for casa in get_tree().get_nodes_in_group("casas"):
		if not casa.has_free_slot_for(self):
			continue
		var free: int = casa.free_slot_count()
		var d := global_position.distance_to(casa.global_position)
		if free > best_free or (free == best_free and d < best_dist):
			best_free = free
			best_dist = d
			best = casa
	if best:
		_home = best
		_home_slot = best.claim_bed(self)


func _rest_position() -> Vector2:
	if has_home():
		return _home.get_slot_position(_home_slot)
	if _camp_pos == null:
		# sem cama: dorme do lado de fora da casa mais próxima (ou do armazém)
		var near := _closest_in_group("casas")
		if near == null:
			near = _closest_in_group("armazens")
		_camp_pos = near.get_wait_position(self) if near else global_position
	return _camp_pos


func _go_home() -> void:
	if not has_home():
		_claim_home()  # pode ter sobrado cama (alguém saiu / casa nova)
	if _resting:
		return
	var dest := _rest_position()
	if global_position.distance_to(dest) <= REST_REACH:
		_start_resting()
	elif not _moving or _target.distance_to(dest) > 1.0:
		_go_to(dest)


func _start_resting() -> void:
	if overtime:
		set_overtime(false)  # foi dormir por conta própria (ex.: machucou): acabou o turno extra
	_resting = true
	_moving = false
	_inside = has_home()
	if _inside:
		_home.set_inside(self, true)
		_agent.avoidance_enabled = false  # "dentro de casa": não atrapalha quem passa na porta
	queue_redraw()


func _stop_resting() -> void:
	if _inside and has_home():
		_home.set_inside(self, false)
	_resting = false
	_inside = false
	_camp_pos = null
	_agent.avoidance_enabled = avoidance_enabled
	queue_redraw()


# ------------------------------------------------------------ ferramentas (Oficina)
## Chamado pela Oficina: a picareta de aço troca o visual da ferramenta.
func on_tool_crafted(id: String) -> void:
	if id == "picareta_aco":
		_has_steel_pickaxe = true
	_refresh_tool_texture()


## Machado pro lenhador; picareta (de aço, se já existir) pros outros.
func _refresh_tool_texture() -> void:
	var item := _hand_item()
	if item:
		_tool.texture = item


## Bloco 29: o que vai na mão — UMA regra só, por função e (quando importa) pelo que
## está fazendo agora. Reavaliada a cada quadro em _update_animation, então trocar de
## função troca a ferramenta na hora, junto com o outfit. null = mãos vazias.
## Função nova = um caso aqui (junto do outfit, regra do Bloco 28).
func _hand_item() -> Texture2D:
	match job:
		ROLE_MINER:
			return _pickaxe()
		ROLE_LUMBER:
			return AXE
		ROLE_GUARD:
			return WEAPON_SPRITES.get(weapon, null)  # Bloco 35: a arma dele (desarmado: mãos vazias)
		ROLE_COOK:
			return FOOD_BASKET  # cesta (a carga, quando tem, vai por cima da cabeça como sempre)
		ROLE_HUNTER:
			# arco só caçando de verdade; sem arco ou colhendo fruta: a cestinha de coleta
			if _ai_state == "hunting" and _has_bow():
				return BOW
			return FORAGE_BASKET
		ROLE_RESEARCH:
			# sem laboratório ele cai pra mineração (Bloco 25): aí sim segura a picareta
			return _pickaxe() if _ai_state in ["mining", "storing"] else null
		ROLE_DOCTOR:
			return null  # plantão lá dentro da enfermaria: mãos livres
		ROLE_ENGINEER:
			return HAMMER
	return null  # ocioso (civil): mãos vazias


func _pickaxe() -> Texture2D:
	return STEEL_PICKAXE if _has_steel_pickaxe else _default_tool


# ------------------------------------------------------------ visual: menino/menina
## Sorteia gênero e variação se ainda não tiver (ou se vier inválido do save) e aplica.
func _ensure_appearance() -> void:
	if not GENDERS.has(gender):
		gender = "menino" if randf() < 0.5 else "menina"
	if look < 0 or look >= LOOKS_PER_GENDER:
		look = randi() % LOOKS_PER_GENDER
	_apply_outfit()


## Veste o outfit da função atual (chamado ao nascer/carregar e a cada troca de função).
func _apply_outfit() -> void:
	_body.texture = _body_texture(outfit(), gender, look)


## Nome do outfit que a função atual veste ("mineiro", "lenhador", "cozinheiro", "civil").
func outfit() -> String:
	return JOB_OUTFIT.get(job, "mineiro")


static var _texture_cache := {}


static func _body_texture(outfit_id: String, gender_id: String, look_id: int) -> Texture2D:
	var path: String = OUTFIT_FILES.get(outfit_id, OUTFIT_FILES["mineiro"]) % [GENDERS.get(gender_id, "m"), look_id]
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path)
	return _texture_cache[path]


## Lenço, remendo/bolso e cor de bota, independentes da roupa. Não vão pro save:
## saem de um hash do nome (que já é salvo), então o mesmo ipezinho sempre volta
## igual depois de carregar.
func _apply_accessories() -> void:
	var h := absi(("%s|%s" % [display_name, gender]).hash())
	for i in _accessories.size():
		var layer := _accessories[i]
		var roll := (h >> (i * 7)) % 100
		if roll < int((1.0 - ACCESSORY_CHANCE) * 100.0):
			_accessory_variant[i] = -1
			layer.visible = false
		else:
			_accessory_variant[i] = roll % layer.vframes
			layer.visible = true
	_sync_accessories()


## Mantém as camadas de acessório no mesmo quadro/lado do corpo.
func _sync_accessories() -> void:
	for i in _accessories.size():
		var layer := _accessories[i]
		if _accessory_variant[i] < 0:
			continue
		layer.frame = _accessory_variant[i] * layer.hframes + _body.frame
		layer.flip_h = _body.flip_h


## Nome sorteado pelo gênero, sem repetir com quem já existe (esgotou: "Zé 2", "Zé 3"...).
func _ensure_name() -> void:
	if display_name != "":
		return
	var used := {}
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w != self and w.get("display_name"):
			used[w.display_name] = true
	var pool: Array = (NAMES_GIRL if gender == "menina" else NAMES_BOY).duplicate()
	pool.shuffle()
	for n in pool:
		if not used.has(n):
			display_name = n
			return
	var base: String = pool[0]
	var i := 2
	while used.has("%s %d" % [base, i]):
		i += 1
	display_name = "%s %d" % [base, i]


# ------------------------------------------------------------ cozinheiro
func is_cook() -> bool:
	return job == ROLE_COOK


func _sun() -> Node:
	return get_tree().get_first_node_in_group("sun")


## Onda solar: exposto na superfície (sun.gd chama a cada frame).
func radiate(amount: float) -> void:
	var sun := _sun()
	if sun == null or injured:
		return
	var before := rad
	rad += amount
	if before < sun.rad_hurt_at * 0.5 and rad >= sun.rad_hurt_at * 0.5:
		_popup("Queimando!", Color(1.0, 0.6, 0.3))
	if rad >= sun.rad_hurt_at:
		rad = 0.0
		hurt("radiacao", "grave" if randf() < sun.rad_grave_chance else "leve")


func is_researcher() -> bool:
	return job == ROLE_RESEARCH


func _research() -> Node:
	return get_tree().get_first_node_in_group("research")


func _apply_research() -> void:
	if not is_inside_tree():
		return
	var r := _research()
	if r:
		r.apply_worker(self)


func is_guard() -> bool:
	return job == ROLE_GUARD


func is_lumber() -> bool:
	return job == ROLE_LUMBER


func is_miner() -> bool:
	return job == ROLE_MINER


## Sem função atribuída (Bloco 25): não trabalha sozinho.
func has_no_job() -> bool:
	return job == ROLE_IDLE


## Designa a função (teclas/botões com os ipezinhos selecionados). Trocar no meio do
## trabalho é seguro: o _choose_state() faz ele entregar primeiro o que estiver
## carregando (minério -> armazém, comida -> comedouro, madeira -> armazém).
func set_job(new_job: String) -> void:
	if not new_job in JOBS:
		push_warning("Ipezinho: função desconhecida '%s'" % new_job)
		return
	if job == new_job:
		return
	if job == ROLE_DOCTOR:
		_end_duty()  # tirou do médico: o bônus da enfermaria para NA HORA (Bloco 30)
	if job == ROLE_ENGINEER:
		_obra_stop()  # tirou do engenheiro: a obra pausa NA HORA, sem perder o feito (Bloco 31)
	if job == ROLE_DOCTOR:
		_drop_patient()  # Bloco 36: tirou do médico no meio do resgate: larga o caído ali
	job = new_job
	_popup(JOB_LABELS[job], Color(0.95, 0.9, 0.6) if job != ROLE_IDLE else Color(0.75, 0.75, 0.8))
	# Bloco 35: o primeiro porrete vem de casa; depois disso, arma nova só no Arsenal
	if job == ROLE_GUARD and weapon == "" and not got_porrete:
		got_porrete = true
		equip("porrete")
	_apply_outfit()  # troca de roupa na hora (Bloco 26)
	_prep_left = 0.0  # leva pela metade não vale pra outra função
	_refresh_tool_texture()
	if auto_mode and _ai_state != "manual":
		_decision_timer = randf_range(0.05, 0.4)  # troca de tarefa já


# ------------------------------------------------------------ caçador / cozinha (Bloco 27)
func is_hunter() -> bool:
	return job == ROLE_HUNTER


## Horta chama: o caçador colhe fruta crua (1 unidade = 1 de matéria-prima).
## Retorna quanto tirou da horta.
func harvest(amount: float) -> float:
	return _gather_raw(amount, 1.0, "foraging")


## Toca chama: o caçador caça (1 unidade de caça = `value` de matéria-prima).
## Retorna quanto tirou da toca.
func hunt(amount: float, value: float) -> float:
	return _gather_raw(amount, value, "hunting")


func _gather_raw(amount: float, value: float, state: String) -> float:
	if not is_hunter() or injured or _ai_state != state:
		return 0.0
	var taken := minf(amount * work_mult(), hunter_carry - _raw_units)  # zangado rende menos
	if taken <= 0.0:
		return 0.0
	_raw_units += taken
	raw_carrying += taken * value
	if state == "hunting":
		leather_carrying += taken * leather_per_game  # Bloco 42: pele da caça
	_work_timer = 0.2
	if _raw_units >= hunter_carry - 0.01:
		_decision_timer = 0.0  # mochila cheia: vai pro armazém já
	return taken


## Armazém chama: o caçador (ou quem tiver na mão) descarrega matéria-prima.
func deliver_raw(amount: float) -> float:
	var given := minf(amount, raw_carrying)
	if raw_carrying > 0.0:
		_raw_units *= (raw_carrying - given) / raw_carrying
	raw_carrying -= given
	if raw_carrying <= 0.001:
		_clear_raw()
		_decision_timer = 0.0
	return given


## Bloco 42: armazém chama — entrega todo o couro que estiver na mochila.
func deliver_leather() -> float:
	var n := leather_carrying
	leather_carrying = 0.0
	return n


## Armazém chama: o cozinheiro pega matéria-prima pra preparar. Retorna quanto pegou.
func receive_raw(amount: float) -> float:
	if not is_cook() or _ai_state != "fetching":
		return 0.0
	var taken := minf(amount, cook_carry - raw_carrying)
	if taken <= 0.0:
		return 0.0
	raw_carrying += taken
	_raw_units += taken
	if raw_carrying >= cook_carry - 0.01:
		_decision_timer = 0.0  # cesta cheia: vai preparar
	return taken


## Comedouro chama a cada frame enquanto o cozinheiro está lá: a leva inteira leva
## raw x prep_time_per_raw segundos; só quando termina vira comida pronta (retorno > 0).
## Se o comedouro não tiver espaço pra tudo, prepara o que cabe e guarda o resto.
func cook_tick(delta: float, space: float) -> float:
	if not is_cook() or injured or _ai_state != "cooking" or raw_carrying <= 0.0 or space <= 0.5:
		return 0.0
	if _prep_left <= 0.0:
		_prep_left = raw_carrying * prep_time_per_raw  # começa uma leva
	_prep_left -= delta * work_mult()  # zangado/triste cozinha mais devagar
	_work_timer = 0.2
	if _prep_left > 0.0:
		return 0.0
	var made := minf(raw_carrying * food_per_raw, space)
	var used := made / food_per_raw
	raw_carrying -= used
	_raw_units = maxf(_raw_units - used, 0.0)
	_prep_left = 0.0
	if raw_carrying <= 0.001:
		_clear_raw()
	_popup("%d crua → +%d comida pronta" % [roundi(used), roundi(made)], Color(0.7, 1.0, 0.55))
	_decision_timer = 0.0
	return made


func _clear_raw() -> void:
	raw_carrying = 0.0
	_raw_units = 0.0
	_prep_left = 0.0


## Tem matéria-prima pra buscar em algum armazém?
func _raw_available() -> bool:
	for a in get_tree().get_nodes_in_group("armazens"):
		if a.get("raw_stored") != null and a.raw_stored >= 0.5:
			return true
	return false


## O caçador tem onde trabalhar (toca com arco, ou horta)?
func _hunter_has_work() -> bool:
	return _has_usable_station("caca") or _has_usable_station("coleta_comida")


func _has_bow() -> bool:
	var oficina := get_tree().get_first_node_in_group("oficina")
	return oficina != null and oficina.has_tool("arco")


## Árvore chama: o lenhador põe madeira nas costas. Retorna quanto pegou.
func chop(amount: float) -> float:
	if not is_lumber() or injured or _ai_state != "chopping":
		return 0.0
	var taken := minf(amount * work_mult(), lumber_carry - wood_carrying)  # zangado corta menos
	if taken <= 0.0:
		return 0.0
	wood_carrying += taken
	_work_timer = 0.2
	if wood_carrying >= lumber_carry - 0.01:
		_decision_timer = 0.0  # carga cheia: vai pro armazém já
	_roll_branch(taken)
	return taken


## Sorteia a queda de galho a cada chop_cycle_amount de madeira cortada (mesmo esquema
## do acidente de mineração; zanga e noite multiplicam a chance).
func _roll_branch(chopped: float) -> void:
	_chopped_since_roll += chopped
	while _chopped_since_roll >= chop_cycle_amount:
		_chopped_since_roll -= chop_cycle_amount
		var chance: float = branch_injury_chance * [1.0, irritated_injury_mult, furious_injury_mult][_mood]
		if _is_night():
			chance *= night_chop_injury_mult
		if randf() < chance:
			if _station and is_instance_valid(_station) and _station.has_method("drop_branch"):
				_station.drop_branch(global_position)
			hurt("galho")
			return


## Armazém chama: descarrega a madeira. Retorna quanto entregou.
func deliver_wood(amount: float) -> float:
	var given := minf(amount, wood_carrying)
	wood_carrying -= given
	if wood_carrying <= 0.001:
		wood_carrying = 0.0
		_decision_timer = 0.0
	return given


## Comedouro chama: descarrega comida da cesta. Retorna quanto entregou.
func deliver_food(amount: float) -> float:
	var given := minf(amount, food_carrying)
	food_carrying -= given
	if food_carrying <= 0.001:
		food_carrying = 0.0
		_decision_timer = 0.0
	return given


## Algum comedouro com comida?
func _food_available() -> bool:
	for c in get_tree().get_nodes_in_group("comedouros"):
		if not c.has_method("has_food") or c.has_food():
			return true
	return false


# ------------------------------------------------------------ turno extra / zanga
## Liga/desliga o turno extra (tecla T com o ipezinho selecionado).
func set_overtime(on: bool) -> void:
	if overtime == on:
		return
	overtime = on
	if on:
		_popup("Turno extra!", Color(0.6, 0.7, 1.0))
	elif _is_night():
		_popup("Hora de dormir", Color(0.6, 0.7, 1.0))
	if auto_mode and _ai_state != "manual":
		_decision_timer = randf_range(0.05, 0.4)  # de noite: acorda ou vai pra cama já


## 0 = calmo, 1 = irritado, 2 = furioso.
func mood() -> int:
	return _mood


func mood_label() -> String:
	return ["", "irritado", "FURIOSO"][_mood]


## Multiplicador da produção pela zanga e pela felicidade.
func work_mult() -> float:
	return [1.0, irritated_work_mult, furious_work_mult][_mood] * _happiness_work_mult() * _cold_mult()


# ------------------------------------------------------------ equipamento (Bloco 42)
func _equipment() -> Node:
	return get_tree().get_first_node_in_group("equipment") if is_inside_tree() else null


## Sem casaco no frio (inverno, mina/clareira): o trabalho rende menos. Ninguém morre disso.
func _cold_mult() -> float:
	var eq := _equipment()
	if eq == null or wearing.has("casaco") or _inside or not eq.is_cold_at(global_position):
		return 1.0
	return eq.cold_work_mult


## Está com frio agora? (pro visual e pro HUD)
func is_cold() -> bool:
	return _cold_mult() < 1.0


## Pode entrar numa zona desse perigo? (vestindo o traje ou tem um no vestiário)
func can_enter_hazard(kind: String) -> bool:
	var eq := _equipment()
	return eq == null or wearing.has(kind) or eq.usable(kind) > 0  # (Bloco 44: precisa do Vestiário)


func _equip_tick(delta: float) -> void:
	var eq := _equipment()
	if eq == null:
		return
	_hazard_cd = maxf(_hazard_cd - delta, 0.0)
	# casaco: pega no inverno, devolve quando acaba; gasta só no frio de verdade
	if eq.is_winter():
		if not wearing.has("casaco") and not downed:
			var d: float = eq.take("casaco")
			if d > 0.0:
				wearing["casaco"] = d
				_popup("Vestiu o casaco", Color(0.75, 0.88, 1.0))
		if wearing.has("casaco") and not _inside and not _resting and eq.is_cold_at(global_position):
			wearing.casaco -= delta
			if wearing.casaco <= 0.0:
				wearing.erase("casaco")
				eq.give_back("casaco", 0.0)
				_popup("O casaco rasgou!", Color(1.0, 0.6, 0.45))
	elif wearing.has("casaco"):
		eq.give_back("casaco", wearing.casaco)
		wearing.erase("casaco")
	# trajes: veste na entrada da zona, devolve na saída, gasta só lá dentro
	var z: String = eq.hazard_at(global_position)
	for t in eq.SUITS:
		if wearing.has(t) and t != z:
			eq.give_back(t, wearing[t])
			wearing.erase(t)
	if z == "" or _carried_by != null:
		return
	if not wearing.has(z):
		var d: float = eq.take(z)
		if d > 0.0:
			wearing[z] = d
			_popup("Vestiu: %s" % eq.NAMES[z].to_lower(), Color(0.8, 1.0, 0.7))
		else:
			_leave_hazard(eq, z, "sem %s no vestiário" % eq.NAMES[z].to_lower())
		return
	wearing[z] -= delta * eq.wear_rate(z)
	if wearing[z] <= 0.0:
		wearing.erase(z)
		eq.give_back(z, 0.0)
		_leave_hazard(eq, z, "%s quebrou" % eq.NAMES[z].to_lower())


## Sem traje (ou ele quebrou) dentro da zona: sai na hora, sem travar nada.
func _leave_hazard(eq: Node, kind: String, why: String) -> void:
	var zone: Node = eq.zone_of(global_position)
	if zone == null:
		return
	if _hazard_cd <= 0.0:
		_hazard_cd = 4.0
		_popup("Saindo: %s!" % why, Color(1.0, 0.6, 0.4))
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_toast("%s saiu do %s: %s." % [_display(), eq.ZONE_NAMES[kind].to_lower(), why], Color(1.0, 0.65, 0.4))
	if _ai_state != "manual" or not _moving or zone.contains(_target):
		_release_station()
		_set_state("manual")
		_manual_timer = 2.0
		_go_to(zone.exit_point(global_position))


func _update_anger(delta: float) -> void:
	if overtime and not _resting and _is_night():
		anger = minf(anger + anger_gain_per_sec * delta, 100.0)
	elif _resting:
		anger = maxf(anger - anger_decay_per_sec * delta, 0.0)
	_refresh_mood()


func _refresh_mood(announce: bool = true) -> void:
	var m := 0
	if anger >= anger_furious_at:
		m = 2
	elif anger >= anger_irritated_at:
		m = 1
	if m == _mood:
		return
	var worse := m > _mood
	_mood = m
	if announce and worse:
		_popup("Grrr!" if m == 2 else "Hmpf...", Color(1.0, 0.45, 0.3) if m == 2 else Color(1.0, 0.75, 0.4))
	mood_changed.emit(m)


# ------------------------------------------------------------ acidentes
## Machuca o ipezinho (chamado pelo sorteio na mineração; tecla K testa no selecionado).
## severity "" = sorteia pela causa e pela profundidade.
func hurt(cause: String = "mina", severity: String = "") -> void:
	if injured:
		return
	injured = true
	injury_cause = cause
	injury_severity = severity if severity in ["leve", "grave"] else _roll_severity(cause)
	_care_left = grave_untreated_time if injury_severity == "grave" else leve_untreated_time
	var res := _research()
	if res:
		_care_left *= res.untreated_mult()  # medicina de campo
	_recovery_left = 0.0  # o tempo de leito é definido ao deitar (gravidade + melhoria)
	_death_warned = false
	_work_timer = 0.0
	_decision_timer = 0.0  # larga a picareta e vai pra enfermaria já
	var grave := injury_severity == "grave"
	var text := "Ai! Um galho!" if cause == "galho" else "Ai!"
	_popup(text + (" (grave)" if grave else ""), Color(1.0, 0.25, 0.2) if grave else Color(1.0, 0.4, 0.35))
	if grave and not downed:  # (caído em combate tem o aviso próprio)
		_toast("%s se machucou feio! Precisa de leito na enfermaria." % _display())
	Audio.hurt(global_position)
	var flash := create_tween()
	flash.tween_property(_body, "self_modulate", Color(2.0, 0.5, 0.5), 0.06)
	flash.tween_property(_body, "self_modulate", Color.WHITE, 0.3)
	injured_changed.emit(true)


## Sorteia leve/grave: galho é pior que mina, e o nível 2 soma deep_grave_bonus.
func _roll_severity(cause: String) -> String:
	var p := grave_chance_branch if cause == "galho" else grave_chance_mine
	var env := get_tree().get_first_node_in_group("environment")
	if env and env.is_deep(global_position):
		p += deep_grave_bonus
	if env and env.has_method("is_abyss") and env.is_abyss(global_position):
		p += abyss_grave_bonus
	return "grave" if randf() < p else "leve"


func _has_infirmary() -> bool:
	return not get_tree().get_nodes_in_group("enfermarias").is_empty()


## Relógio do machucado: cura no leito; fora dele, leve piora e grave morre.
func _update_injury(delta: float) -> void:
	if downed:
		# Bloco 36: no chão o relógio corre; nas costas do médico pausa (primeiros socorros)
		if _carried_by != null:
			return
		_care_left -= delta
		if not _death_warned and _care_left <= death_warning_time:
			_death_warned = true
			_toast("%s está caído e morre em %ds se um médico não chegar!" % [_display(), ceili(_care_left)])
		if _care_left <= 0.0:
			_die()
		return
	if _admitted:
		# Bloco 30: com médico de plantão a cura anda mais rápido (sem médico: como sempre)
		var rate: float = _ward.heal_rate() if _ward != null and is_instance_valid(_ward) and _ward.has_method("heal_rate") else 1.0
		_recovery_left -= delta * rate
		if _recovery_left <= 0.0:
			_heal()
		return
	if not _has_infirmary():
		# cena sem enfermaria (fallback antigo): cura descansando em casa
		if _resting:
			if _recovery_left <= 0.0:
				_recovery_left = get_recovery_time()
			_recovery_left -= delta
			if _recovery_left <= 0.0:
				_heal()
		return
	var ward := _closest_in_group("enfermarias")
	_care_left -= delta * (ward.waiting_clock_mult() if ward and ward.has_method("waiting_clock_mult") else 1.0)
	if injury_severity == "grave" and not _death_warned and _care_left <= death_warning_time:
		_death_warned = true
		_toast("%s vai morrer se não deitar num leito! (%ds)" % [_display(), ceili(_care_left)])
	if _care_left <= 0.0:
		if injury_severity == "grave":
			_die()
		else:
			_worsen()


## Deita no leito reservado da enfermaria (some lá dentro; a cura começa a contar).
func _admit() -> void:
	_admitted = true
	_ward = _station
	if overtime:
		set_overtime(false)
	_resting = true
	_inside = true
	_moving = false
	_agent.avoidance_enabled = false  # lá dentro: não atrapalha quem passa na porta
	if _recovery_left <= 0.0:
		_recovery_left = _ward.heal_time(injury_severity)
	_ward.set_inside(self, true)
	queue_redraw()


## Sai do leito (curou, ou foi tirado de lá por uma ordem). O que já curou não se perde.
func _discharge() -> void:
	if not _admitted:
		return
	_admitted = false
	if _ward != null and is_instance_valid(_ward):
		_ward.set_inside(self, false)
	_ward = null
	_resting = false
	_inside = false
	_agent.avoidance_enabled = avoidance_enabled
	queue_redraw()


## Leve sem cuidado por tempo demais: vira grave (e o relógio da morte começa).
func _worsen() -> void:
	injury_severity = "grave"
	_care_left = grave_untreated_time
	var res := _research()
	if res:
		_care_left *= res.untreated_mult()
	_recovery_left = 0.0
	_death_warned = false
	_popup("Piorou!", Color(1.0, 0.25, 0.2))
	Audio.hurt(global_position)
	_toast("%s piorou: machucado GRAVE! Precisa de leito." % _display())
	injured_changed.emit(true)


## Grave sem leito até o fim: morre. Vai pro memorial da enfermaria (cruz onde caiu).
func _die() -> void:
	var inf := _closest_in_group("enfermarias")
	if inf:
		inf.record_death(self)  # o HUD mostra a faixa pelo sinal patient_died
	Audio.toll()
	died.emit(_display())
	var main := get_tree().get_first_node_in_group("game_main")
	if main and main.is_selected(self):
		main.toggle_selected(self)
	injured = false
	queue_free()


func _display() -> String:
	return display_name if display_name != "" else String(name)


func _toast(text: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast(text, Color(1.0, 0.45, 0.4))


## Fallback sem enfermaria: tempo de descanso em casa (a melhoria do Centro da Vila reduz).
func get_recovery_time() -> float:
	var hub := _village_hub()
	return recovery_time * (hub.recovery_mult() if hub else 1.0)


func _heal() -> void:
	injured = false
	injury_severity = ""
	_care_left = 0.0
	_recovery_left = 0.0
	_popup("Curado!", Color(0.55, 1.0, 0.5))
	Audio.heal(global_position)
	# de dia volta ao trabalho logo; de noite continua dormindo
	_decision_timer = randf_range(0.05, phase_react_delay)
	injured_changed.emit(false)


## Sorteia o acidente a cada mining_cycle_amount de minério extraído.
func _roll_injury(mined: float) -> void:
	_mined_since_roll += mined
	while _mined_since_roll >= mining_cycle_amount:
		_mined_since_roll -= mining_cycle_amount
		# achados da escavação (peças raras, itens de reator, o robô antigo)
		var finds := get_tree().get_first_node_in_group("finds")
		if finds:
			finds.roll(self, cargo_type)
		# zanga x profundidade x vazamento do reator solar: os multiplicadores se acumulam
		var dig := get_tree().get_first_node_in_group("escavadeira")
		var leak: float = dig.accident_mult() if dig and dig.has_method("accident_mult") else 1.0
		var res := _research()
		if res:
			leak *= res.accident_mult()  # explosivos / escoramento
		if randf() < injury_chance * [1.0, irritated_injury_mult, furious_injury_mult][_mood] * depth_danger() * leak:
			hurt()
			return


## Texto flutuante acima da cabeça.
func _popup(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.04))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", 13)
	label.position = Vector2(-18, -62)
	label.z_index = 20
	add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 22.0, 1.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


# ------------------------------------------------------------ interações (duck typing)
func _on_starving() -> void:
	_hunger_label.modulate = Color.RED


func feed(amount: float) -> void:
	hunger = minf(hunger + amount, hunger_max)
	_hunger_label.modulate = Color.WHITE
	if hunger >= hunger_max * eat_until_ratio and _ai_state == "eating":
		_decision_timer = 0.0  # satisfeito: decide o próximo passo já


func mine(amount: float, ore_type: String = "ferro") -> float:
	if injured:
		return 0.0  # machucado não consegue minerar
	if _on_strike():
		if _strike_refuse_cd <= 0.0:  # nem com ordem manual
			_strike_refuse_cd = 3.0
			_popup("Tô em greve!", Color(1.0, 0.55, 0.4))
		return 0.0
	if carrying > 0.0 and ore_type != cargo_type:
		return 0.0  # não mistura minérios na mesma carga
	if carrying <= 0.0 and ore_type != cargo_type:
		cargo_type = ore_type
		_carry_icon.texture = Ores.CHUNK_TEXTURES.get(cargo_type, _carry_icon.texture)
	var space := cargo_capacity - carrying
	var res := _research()
	var boom: float = res.mining_speed_mult() if res else 1.0  # explosivos
	var taken: float = minf(amount * work_mult() * boom, space)  # zangado minera menos
	if ore_type == "solarita" and taken > 0.0:
		var diary := get_tree().get_first_node_in_group("diary")
		if diary:
			diary.unlock("solarita")
	carrying += taken
	if taken > 0.0:
		_work_timer = 0.2
		_roll_injury(taken)
	if carrying >= cargo_capacity - 0.01:
		_decision_timer = 0.0  # cheio: vai depositar sem esperar o próximo tick
	_update_cargo_label()
	return taken


func deposit(amount: float) -> float:
	var given: float = minf(amount, carrying)
	carrying -= given
	if carrying <= 0.0:
		carrying = 0.0
		_decision_timer = 0.0
	_update_cargo_label()
	return given


# ------------------------------------------------------------ visual
func _update_animation(delta: float) -> void:
	var spd := velocity.length()
	if spd > 5.0:
		_anim_time += delta * walk_anim_fps * clampf(spd / speed, 0.5, 1.3)
		var new_frame := int(_anim_time) % _body.hframes
		if new_frame != _body.frame and new_frame % 2 == 0:
			Audio.step(global_position)  # pé tocando o chão (quadros 0 e 2)
		_body.frame = new_frame
		if absf(velocity.x) > 3.0:
			_facing = signf(velocity.x)
	else:
		_anim_time = 0.0
		_body.frame = 0

	_body.flip_h = _facing < 0.0
	_body.skew = -0.08 * _facing if spd > 5.0 else 0.0  # leve inclinação ao andar
	_sync_accessories()

	# Bloco 29: item da mão (regra única em _hand_item). Ferramentas (picareta, machado,
	# lança) no ombro e balançando no trabalho; arco em pé na mão; cestas penduradas.
	var item := _hand_item()
	if item != null and _tool.texture != item:
		_tool.texture = item
	var hanging := item == FOOD_BASKET or item == FORAGE_BASKET
	var upright := item == BOW or item == BESTA  # arco e besta ficam em pé na mão
	var swings := item != null and not hanging and not upright
	_tool.offset = Vector2(-item.get_width() * 0.5, -1.0) if hanging else Vector2(-5.5, -12.5)
	_tool.position.x = 9.0 * _facing
	_tool.scale = Vector2(2.0 * _facing, 2.0)
	if hanging or upright:
		_swing_time = 0.0
		_prev_swing = 0.0
		_swing_rising = false
		if hanging:  # cesta balança de leve com o passo
			_tool.rotation = sin(_anim_time * PI) * 0.12 if spd > 5.0 else 0.0
		else:  # arco em pé; puxando a corda enquanto caça
			_tool.rotation = _facing * (-0.1 + (0.08 * sin(Time.get_ticks_msec() * 0.01) if _work_timer > 0.0 else 0.0))
	elif swings and _work_timer > 0.0:
		_swing_time += delta
		var swing := (sin(_swing_time * 12.0) * 0.5 + 0.5)  # 0..1
		_tool.rotation = _facing * lerpf(-0.9, 1.4, swing * swing)
		# impacto = ponto mais baixo do golpe (a curva para de subir)
		var rising := swing > _prev_swing
		if _swing_rising and not rising:
			if item == _pickaxe() or item == HAMMER:  # picareta na pedra / martelo na obra
				Audio.pick(global_position)
			if item == HAMMER and _ai_state == "building":
				_dust_puff()
		_swing_rising = rising
		_prev_swing = swing
	else:
		_swing_time = 0.0
		_prev_swing = 0.0
		_swing_rising = false
		_tool.rotation = _facing * -0.35

	# dormindo: dentro de casa some; ao relento fica deitado no chão
	_body.visible = not _inside
	_tool.visible = item != null and not _resting  # Bloco 29: mãos vazias = sem nada na mão
	_lamp.enabled = head_lamp_enabled and not _resting and outfit() in OUTFITS_WITH_LAMP
	var lying := (_resting and not _inside) or downed
	var limp := injured and spd > 5.0 and not downed
	var carried := downed and _carried_by != null and is_instance_valid(_carried_by)
	if carried:
		_facing = _carried_by._facing
		_body.rotation = -PI * 0.5 * _facing
	elif lying:
		_body.rotation = -PI * 0.5 * _facing
	elif limp:
		_body.rotation = sin(_anim_time * PI) * 0.12  # mancando: tomba pra um lado a cada passo
	else:
		_body.rotation = 0.0
	var bob := absf(sin(_anim_time * PI * 0.5)) * 2.0 if limp else 0.0
	_body.position.y = _body_base_y + (-13.0 if carried else (9.0 if lying else 0.0)) + bob
	_injury_icon.visible = injured and not _inside
	_strike_icon.visible = _ai_state == "strike" and not _inside
	if _strike_icon.visible:
		_strike_icon.position.y = -44.0 + (sin(Time.get_ticks_msec() * 0.008 + _facing) * 3.0 if not _moving else 0.0)
	if _injury_icon.visible:
		_injury_icon.position.y = -40.0 + sin(Time.get_ticks_msec() * 0.005) * 1.5
		# Bloco 36: caído esperando resgate = curativo piscando vermelho
		_injury_icon.modulate = Color(1.0, 0.45, 0.45, 0.5 + 0.5 * absf(sin(Time.get_ticks_msec() * 0.008))) \
			if downed and not carried else Color.WHITE
	# zanga: "veia saltando" pulsando (mais rápida e maior quando furioso) + tremidinha
	_anger_icon.visible = _mood > 0 and not _inside
	if _anger_icon.visible:
		var ms := Time.get_ticks_msec()
		var pulse := 1.0 + 0.18 * sin(ms * (0.018 if _mood == 2 else 0.008))
		_anger_icon.scale = Vector2.ONE * (2.0 if _mood == 2 else 1.5) * pulse
		_anger_icon.modulate = Color.WHITE if _mood == 2 else Color(1.0, 0.8, 0.55)
	if _mood == 2 and not lying:
		_body.position.x = sin(Time.get_ticks_msec() * 0.09) * 0.6
	else:
		_body.position.x = 0.0

	# Bloco 35: guarda desarmado = lança quebrada piscando em cima da cabeça
	_broken_icon.visible = is_guard() and weapon == "" and not _resting
	if _broken_icon.visible:
		_broken_icon.modulate = Color(1.0, 0.5, 0.45, 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.005)))
		_broken_icon.position.y = -46.0 - (2.0 if _body.frame % 2 == 1 else 0.0)

	# pedrinha de minério em cima da cabeça, maior quanto mais carga
	_cook_icon.visible = false  # Bloco 26: o chapéu agora faz parte do outfit do cozinheiro
	_carry_icon.visible = (carrying > 0.0 or food_carrying > 0.0 or wood_carrying > 0.0 or raw_carrying > 0.0) and not _resting
	if wood_carrying > 0.0:
		_carry_icon.texture = WOOD_LOG
	elif food_carrying > 0.0:
		_carry_icon.texture = FOOD_BASKET
	elif raw_carrying > 0.0:
		_carry_icon.texture = RAW_FOOD
	elif carrying > 0.0 and _carry_icon.texture in [FOOD_BASKET, WOOD_LOG, RAW_FOOD]:
		_carry_icon.texture = Ores.CHUNK_TEXTURES.get(cargo_type, _carry_icon.texture)
	if _carry_icon.visible:
		var r := carrying / cargo_capacity
		if wood_carrying > 0.0:
			r = wood_carrying / lumber_carry
		elif food_carrying > 0.0:
			r = food_carrying / cook_carry
		elif raw_carrying > 0.0:
			r = raw_carrying / cook_carry if is_cook() else _raw_units / hunter_carry
		_carry_icon.scale = Vector2.ONE * lerpf(1.0, 2.0, r)
		# (o chapéu do outfit de cozinheiro tem a mesma altura do capacete: sem desvio)
		_carry_icon.position.y = -44.0 - (2.0 if _body.frame % 2 == 1 else 0.0)

	# vermelho de fome / rosado de machucado
	if hunger <= 0.0:
		_body.modulate = Color(1.0, 0.6, 0.6)
	elif injured:
		_body.modulate = Color(1.0, 0.64, 0.6) if injury_severity == "grave" else Color(1.0, 0.78, 0.74)
	elif wearing.has("gas") or wearing.has("calor") or wearing.has("radiacao"):
		# Bloco 42: com traje de perigo (cor do traje)
		_body.modulate = Color(0.78, 1.0, 0.8) if wearing.has("gas") else (Color(1.0, 0.82, 0.66) if wearing.has("calor") else Color(1.0, 1.0, 0.62))
	elif is_cold():
		# Bloco 42: sem casaco no frio — azulado e tremendo
		_body.modulate = Color(0.8, 0.88, 1.0)
		if not lying:
			_body.position.x = sin(Time.get_ticks_msec() * 0.07) * 0.5
	else:
		_body.modulate = Color.WHITE


func _update_hunger_label() -> void:
	_last_hunger_int = int(hunger)
	_hunger_label.text = str(_last_hunger_int)


func _update_cargo_label() -> void:
	_cargo_label.text = "Carga: %d" % int(carrying)


func set_selected(is_selected: bool) -> void:
	selected = is_selected
	queue_redraw()


func _draw() -> void:
	# sombra + anel de seleção (elipses no pé do personagem)
	draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.45))
	if not _inside:
		draw_circle(Vector2(1.5, 0.5), 12.0, Color(0.02, 0.02, 0.05, 0.5))
	if selected:
		draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 32, Color(1.0, 0.84, 0.25), 2.5)


# ------------------------------------------------------------ save/load (SaveManager)
func get_save_data() -> Dictionary:
	return {
		"name": String(name),
		"position": SaveUtil.vec2_to_array(global_position),
		"hunger": hunger,
		"carrying": carrying,
		"cargo_type": cargo_type,
		"injured": injured,
		"recovery_left": _recovery_left,
		"mined_since_roll": _mined_since_roll,
		"chopped_since_roll": _chopped_since_roll,
		"injury_cause": injury_cause,
		"injury_severity": injury_severity,
		"happiness": happiness,
		"care_left": _care_left,
		"facing": _facing,
		"home": String(_home.name) if has_home() else "",
		"home_slot": _home_slot if has_home() else -1,
		"anger": anger,
		"overtime": overtime,
		"job": job,
		"food_carrying": food_carrying,
		"raw_carrying": raw_carrying,
		"raw_units": _raw_units,
		"prep_left": _prep_left,
		"wood_carrying": wood_carrying,
		"gender": gender,
		"display_name": display_name,
		"look": look,
		"combat_skill": combat_skill,
		"weapon": weapon,
		"weapon_durability": weapon_durability,
		"broken_weapon": broken_weapon,
		"got_porrete": got_porrete,
		"downed": downed,
		"downed_gate": downed_gate,
		"wearing": wearing.duplicate(),
		"leather_carrying": leather_carrying,
	}


## Aplicado no _ready (via pending_save_data). A IA recomeça do zero e decide sozinha.
func load_save_data(d: Dictionary) -> void:
	hunger = clampf(SaveUtil.num(d, "hunger", hunger_max), 0.0, hunger_max)
	carrying = clampf(SaveUtil.num(d, "carrying", 0.0), 0.0, cargo_capacity)
	var t := SaveUtil.text(d, "cargo_type", "ferro")
	cargo_type = t if Ores.NAMES.has(t) else "ferro"
	_carry_icon.texture = Ores.CHUNK_TEXTURES.get(cargo_type, _carry_icon.texture)
	injured = SaveUtil.boolean(d, "injured", false)
	# 0 = ainda não deitou (o tempo de leito é definido ao deitar)
	_recovery_left = maxf(SaveUtil.num(d, "recovery_left", 0.0), 0.0) if injured else 0.0
	happiness = clampf(SaveUtil.num(d, "happiness", happiness_start), 0.0, 100.0)  # save antigo: começa bem
	var sev := SaveUtil.text(d, "injury_severity", "leve")  # save antigo: leve
	injury_severity = (sev if sev in ["leve", "grave"] else "leve") if injured else ""
	_care_left = SaveUtil.num(d, "care_left", 0.0) if injured else 0.0
	if injured and _care_left <= 0.0:
		_care_left = grave_untreated_time if injury_severity == "grave" else leve_untreated_time
	_mined_since_roll = maxf(SaveUtil.num(d, "mined_since_roll", 0.0), 0.0)
	_chopped_since_roll = maxf(SaveUtil.num(d, "chopped_since_roll", 0.0), 0.0)
	injury_cause = SaveUtil.text(d, "injury_cause", "mina" if injured else "")
	_facing = -1.0 if SaveUtil.num(d, "facing", 1.0) < 0.0 else 1.0
	_saved_home = SaveUtil.text(d, "home", "")
	_saved_home_slot = SaveUtil.integer(d, "home_slot", -1)
	anger = clampf(SaveUtil.num(d, "anger", 0.0), 0.0, 100.0)
	overtime = SaveUtil.boolean(d, "overtime", false)
	# Bloco 25: "job". Save de antes (só "role", onde "" = fazia de tudo) já chega aqui
	# migrado pelo SaveManager (versão 3); o fallback abaixo cobre dados sem migração:
	# quem não tinha função especial continua MINERANDO, não fica ocioso do nada.
	if d.has("job"):
		var j := SaveUtil.text(d, "job", ROLE_MINER)
		job = j if j in JOBS else ROLE_MINER
	else:
		var r := SaveUtil.text(d, "role", "")
		job = r if r in [ROLE_COOK, ROLE_LUMBER, ROLE_GUARD, ROLE_RESEARCH] else ROLE_MINER
	combat_skill = clampf(SaveUtil.num(d, "combat_skill", 0.0), 0.0, 1.0)
	# Bloco 35 (save antigo: o SaveManager já pôs a melhor arma forjada nos guardas)
	var wpn := SaveUtil.text(d, "weapon", "")
	weapon = wpn if WEAPON_SPRITES.has(wpn) else ""
	var def := get_tree().get_first_node_in_group("defense") if is_inside_tree() else null
	var wmax: float = def.weapon_max_durability(weapon) if def and weapon != "" else 999.0
	var wdur := SaveUtil.num(d, "weapon_durability", -1.0)
	weapon_durability = (wmax if wdur < 0.0 else clampf(wdur, 0.0, wmax)) if weapon != "" else 0.0
	if weapon != "" and weapon_durability <= 0.0:
		weapon_durability = 1.0
	var bw := SaveUtil.text(d, "broken_weapon", "")
	broken_weapon = bw if WEAPON_SPRITES.has(bw) else ""
	got_porrete = SaveUtil.boolean(d, "got_porrete", weapon != "" or broken_weapon != "")
	# Bloco 36: caído em combate volta caído no mesmo lugar (quem carregava não é salvo:
	# o médico vem buscar de novo). O relógio (care_left) já veio acima.
	# Bloco 42 (save antigo: nada vestido, sem couro)
	wearing = {}
	var wd := SaveUtil.dict(d, "wearing")
	for k in wd:
		if k in ["casaco", "gas", "calor", "radiacao"] and (wd[k] is float or wd[k] is int) and float(wd[k]) > 0.0:
			wearing[k] = float(wd[k])
	leather_carrying = maxf(SaveUtil.num(d, "leather_carrying", 0.0), 0.0)
	downed = injured and injury_severity == "grave" and SaveUtil.boolean(d, "downed", false)
	downed_gate = SaveUtil.text(d, "downed_gate", "") if downed else ""
	if downed:
		_ai_state = "downed"
		_agent.avoidance_enabled = false
	wood_carrying = clampf(SaveUtil.num(d, "wood_carrying", 0.0), 0.0, lumber_carry)
	food_carrying = clampf(SaveUtil.num(d, "food_carrying", 0.0), 0.0, cook_carry)
	# Bloco 27 (save antigo: 0). Volume nunca passa do que cabe na mochila.
	raw_carrying = maxf(SaveUtil.num(d, "raw_carrying", 0.0), 0.0)
	_raw_units = clampf(SaveUtil.num(d, "raw_units", raw_carrying), 0.0, maxf(hunter_carry, cook_carry))
	_prep_left = maxf(SaveUtil.num(d, "prep_left", 0.0), 0.0) if raw_carrying > 0.0 else 0.0
	# save antigo (sem visual) ou valor inválido: _ensure_appearance sorteia e o próximo save guarda
	gender = SaveUtil.text(d, "gender", "")
	display_name = SaveUtil.text(d, "display_name", "")  # save antigo: sorteia um nome
	look = SaveUtil.integer(d, "look", -1)
	_refresh_mood(false)
	_target = global_position
	_update_hunger_label()
	_update_cargo_label()
