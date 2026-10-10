extends CharacterBody2D

signal state_changed(new_state: String)
signal injured_changed(is_injured: bool)
signal mood_changed(level: int)  # 0 calmo, 1 irritado, 2 furioso
signal died(worker_name: String)

const STATE_LABELS := {
	"esperando_espaco": "esperando espaço no armazém",  # Bloco 106
	"abrigo": "no abrigo (onda solar)",  # Bloco 109
	"bebe": "bebê (em casa)", "parto": "dando à luz", "brincando": "brincando", "aprendendo": "aprendendo um ofício",
	"escola": "na escola",  # Bloco 111
	"social": "hora social",  # Bloco 85
	"padre": "na igreja",  # Bloco 88
	"buscando_corpo": "buscando um corpo",  # Bloco 93
	"levando_corpo": "levando ao cemitério",
	"enterrando": "enterrando",
	"buscando_insumo": "indo ao armazém (insumos)",  # Bloco 86
	"fundindo": "fundindo",
	"serrando": "serrando",  # Bloco 94
	"carvoejando": "carvoejando",  # Bloco 107
	"curtindo": "curtindo couro",  # Bloco 107
	"montando_cama": "montando uma cama",
	"idle": "ocioso",
	"eating": "comendo",
	"mining": "minerando",
	"storing": "armazenando",
	"na_mina": "dentro da mina",  # Bloco 99
	"catalogando": "catalogando",  # Bloco 102
	"patrulha": "caçando no fundo",  # Bloco 103
	"batendo": "batendo o mato",  # Bloco 104
	"carregando": "carregando material",  # Bloco 105
	"manutencao": "fazendo manutenção",
	"expedicao": "saindo em expedição",
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
	"operating": "operando o coletor",
	"operating_ore": "operando o coletor de minério",  # Bloco 57
}
## Distância da porta/cama a partir da qual o ipezinho "chega" em casa.
const REST_REACH := 12.0
const Ores := preload("res://scripts/core/ores.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")
const Schedule := preload("res://scripts/core/schedule.gd")  # Bloco 84
const Items := preload("res://scripts/core/items.gd")  # Bloco 86
const Icones := preload("res://scripts/ui/icones.gd")  # Bloco 85: o balão da hora social
const Modificadores := preload("res://scripts/core/modificadores.gd")  # Bloco 108: políticas (e a dificuldade, depois)
const Settings := preload("res://scripts/core/settings.gd")  # Bloco 95: liga/desliga o balão de motivo
const ObraSite := preload("res://scripts/core/obra_site.gd")  # Bloco 96: o material da obra
const BALAO := preload("res://assets/game/ui/balao.png")
## Bloco 95: onde fica o balão (conversa e motivo), px da lógica acima do pé. A vista iso sobe junto com a
## altura da arte nova (iso_billboard: lift); -66 deixava o balão longe da cabeça.
const BALAO_POS := Vector2(12, -50)
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
	# Blocos 86-88: no mapa antigo (sem a vista iso) o desenho de outro ofício; na vista iso, a arte própria do
	# PixelLab (Bloco 92: iso_bonecos.gd OUTFIT_FUNCAO -> fundidor / ferreiro / padre)
	"fundidor": "res://assets/game/ipezinho_engenheiro_%s%d.png",
	"ferreiro": "res://assets/game/ipezinho_engenheiro_%s%d.png",
	"padre": "res://assets/game/ipezinho_civil_%s%d.png",
	"carpinteiro": "res://assets/game/ipezinho_lenhador_%s%d.png",  # Bloco 94 (na vista iso: a arte do PixelLab)
	"batedor": "res://assets/game/ipezinho_cacador_%s%d.png",  # Bloco 104 (na vista iso: a arte do PixelLab, oficios104.py)
	"carregador": "res://assets/game/ipezinho_civil_%s%d.png",  # Bloco 105 (na vista iso: a arte do PixelLab, oficios105.py)
	"mecanico": "res://assets/game/ipezinho_engenheiro_%s%d.png",
	"agricultor": "res://assets/game/ipezinho_civil_%s%d.png",  # Bloco 107 (na vista iso: a arte do PixelLab, oficios107.py)
}
## Só o capacete de mineiro tem lanterna (a PointLight2D HeadLamp).
const OUTFITS_WITH_LAMP := ["mineiro"]
## Chance (0..1) de cada camada de acessório aparecer (botas, remendo/bolso, lenço).
const ACCESSORY_CHANCE := 0.6
const STATE_GROUP := {
	"eating": "comedouros",
	"escola": "escolas",  # Bloco 111
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
	"operating": "coletores",  # Bloco 45: lenhador designado operando o coletor de madeira
	"operating_ore": "coletores_minerio",  # Bloco 57: minerador designado operando a broca
	"infirmary": "enfermarias",
	"leisure": "tavernas",
	"training": "campos",
	"research": "laboratorios",
	"rearming": "arsenais",  # Bloco 35: guarda buscando/trocando a arma
	"buscando_insumo": "armazens",  # Bloco 86: fundidor largando barras / pegando insumos
	"fundindo": "fornalhas",  # Bloco 86: fundidor na fornalha
	"serrando": "carpintarias",  # Bloco 94: carpinteiro na carpintaria
	"carvoejando": "carvoarias",  # Bloco 107: lenhador na carvoaria
	"curtindo": "curtumes",  # Bloco 107: caçador no curtume
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
const ROLE_SMELTER := "fundidor"  # Bloco 86: opera a Fornalha (só por ordem)
const ROLE_SMITH := "ferreiro"  # Bloco 87: opera a Oficina e o Arsenal (só por ordem)
const ROLE_PRIEST := "padre"  # Bloco 88: o padre (um só, chega por evento). Bloco 92: é FUNÇÃO — só homem, um por vez
const ROLE_CARPENTER := "carpinteiro"  # Bloco 94: opera a Carpintaria (só por ordem) e monta as camas novas
const ROLE_SCOUT := "batedor"  # Bloco 104: bate o mato (avista de longe, rastreia tocas) e lidera as expedições
const ROLE_CARRIER := "carregador"  # Bloco 105: leva o material do armazém pras obras, a fornalha e a cozinha (logistica.gd)
const ROLE_MECHANIC := "mecânico"  # Bloco 105: consertos e manutenção das máquinas (manutencao.gd)
const ROLE_FARMER := "agricultor"  # Bloco 107: colhe a horta e a estufa (dentro da vila); com ele, o caçador só caça
const JOBS := [ROLE_IDLE, ROLE_MINER, ROLE_COOK, ROLE_LUMBER, ROLE_GUARD, ROLE_RESEARCH, ROLE_HUNTER, ROLE_DOCTOR, ROLE_ENGINEER, ROLE_SMELTER, ROLE_SMITH, ROLE_PRIEST, ROLE_CARPENTER, ROLE_SCOUT, ROLE_CARRIER, ROLE_MECHANIC, ROLE_FARMER]
## Texto do popup ao receber a função.
const JOB_LABELS := {
	ROLE_IDLE: "Sem função", ROLE_MINER: "Minerador!", ROLE_COOK: "Cozinheiro!",
	ROLE_LUMBER: "Lenhador!", ROLE_GUARD: "Guarda!", ROLE_RESEARCH: "Pesquisador!",
	ROLE_HUNTER: "Caçador!", ROLE_DOCTOR: "Médico!", ROLE_ENGINEER: "Engenheiro!", ROLE_SMELTER: "Fundidor!", ROLE_SMITH: "Ferreiro!", ROLE_PRIEST: "Padre",
	ROLE_CARPENTER: "Carpinteiro!",  # Bloco 94
	ROLE_SCOUT: "Batedor!",  # Bloco 104
	ROLE_CARRIER: "Carregador!",  # Bloco 105
	ROLE_MECHANIC: "Mecânico!",
	ROLE_FARMER: "Agricultor!",  # Bloco 107
}
## Bloco 26/28: outfit inteiro por função (derivado do `job`: nada novo no save).
## REGRA (Bloco 28): toda função nova nasce com outfit próprio no mesmo bloco —
## gerar os corpos no gen_sprites.py (IPEZINHO_OUTFITS), pôr o arquivo em OUTFIT_FILES
## e mapear aqui. Nada de "por enquanto usa o de mineiro".
const JOB_OUTFIT := {
	ROLE_IDLE: "civil", ROLE_MINER: "mineiro", ROLE_COOK: "cozinheiro",
	ROLE_LUMBER: "lenhador", ROLE_GUARD: "guarda", ROLE_RESEARCH: "pesquisador",
	ROLE_HUNTER: "cacador", ROLE_DOCTOR: "medico", ROLE_ENGINEER: "engenheiro",
	ROLE_SMELTER: "fundidor",  # Bloco 86: PROVISÓRIO (pedido do jogador): a roupa do engenheiro + tom de fuligem
	ROLE_SMITH: "ferreiro",  # Bloco 87: PROVISÓRIO: a roupa do engenheiro + tom de aço
	ROLE_PRIEST: "padre",  # Bloco 88: PROVISÓRIO: a roupa de civil + tom de batina
	ROLE_CARPENTER: "carpinteiro",  # Bloco 94: a arte do PixelLab (oficios94.py)
	ROLE_SCOUT: "batedor",  # Bloco 104: a arte do PixelLab (oficios104.py)
	ROLE_CARRIER: "carregador",  # Bloco 105: a arte do PixelLab (oficios105.py)
	ROLE_MECHANIC: "mecanico",
	ROLE_FARMER: "agricultor",  # Bloco 107: a arte do PixelLab (oficios107.py)
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
const Tipo := preload("res://scripts/ui/tipografia.gd")

@export_group("Obras (Bloco 51)")
## Vigia do engenheiro: indo pra obra sem chegar nem 16 px mais perto por esse tempo (s de jogo),
## procura outro ponto de acesso alcançável (ou o chão andável mais perto da obra) e segue.
@export var obra_watchdog_time: float = 12.0

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
## Fome gasta por segundo REAL. Bloco 84 (fome controlada): devagar — 0,2/s = 4,5 por hora de jogo; quem
## enche são as 3 refeições da agenda (Schedule). (Era 0.8 com o comer contínuo.)
@export var hunger_decay: float = 0.2
## Abaixo disso come FORA da hora das refeições (fome braba: uma porção).
@export var hunger_threshold: float = 30.0
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

@export_group("Descobertas (Bloco 103)")
## Ânimo que a pesquisadora ganha a cada descoberta (estudo do catálogo) e quanto disso some por segundo.
@export var animo_descoberta_ganho: float = 12.0
@export var animo_descoberta_decai: float = 0.02
## Bloco 107: o ânimo do ENSOPADO (a cozinha soma a cada prato; some devagar, por segundo).
@export var animo_prato_decai: float = 0.01
## Cada descoberta (xp_pesquisa) deixa o estudo de campo esta fração mais rápido, até o máximo.
@export var xp_pesquisa_bonus: float = 0.1
@export var xp_pesquisa_max: float = 0.5

@export_group("Batedor (Bloco 104)")
## Segundos olhando de luneta em cada ponto da beira da floresta (e rastreando a toca).
@export var segundos_bater: float = 20.0

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
## Bloco 94: minério a mais por viagem com a MOCHILA de couro (o minerador pega uma no armazém).
@export var mochila_carga: float = 4.0

@export_group("IA")
@export var auto_mode: bool = true  # true = IA decide sozinha; false = só controle manual por clique
@export var decision_interval: float = 1.0  # a cada quantos segundos a IA reavalia o que fazer
## Segundos que a IA espera depois de uma ordem manual antes de voltar a decidir.
## Só começa a contar quando ele CHEGA no destino (a caminhada não gasta esse tempo).
@export var manual_override_time: float = 6.0
## Distância máxima de um passeio aleatório quando está ocioso.
@export var idle_wander_radius: float = 50.0

@export_group("Escolha da estação (Bloco 109)")
## A estação de menor CUSTO ganha; cada termo vale "px de caminho". A distância conta x peso_distancia...
@export var peso_distancia: float = 1.0
## ...cada trabalhador já na estação soma isto (a fila; era o 40 fixo de antes)...
@export var peso_fila: float = 40.0
## ...uma estação cheia desconta até isto (proporcional ao que ela ainda tem, 0..1)...
@export var peso_quantidade: float = 60.0
## ...o que está FALTANDO no armazém desconta até isto (0 = tem falta_referencia ou mais; 1 = não tem nada)...
@export var peso_falta: float = 120.0
## ...e cada ponto de perigo soma isto (andar mais fundo, zona sem o traje, criatura viva perto da estação).
@export var peso_perigo: float = 250.0
## Unidades no armazém que contam como "tem bastante" pro peso_falta.
@export var falta_referencia: float = 120.0
## Raio (px) em volta da estação em que uma criatura viva conta como perigo.
@export var perigo_criatura_raio: float = 160.0

@export_group("Função secundária (Bloco 109)")
## A secundária de cada função quando o jogador deixa no automático (sem a chave = nenhuma). Só vale no expediente e só
## quando a função principal não tem NADA pra fazer (o engenheiro sem obra, o ferreiro sem encomenda, o fundidor sem ordem
## em oficina nenhuma, o guarda de dia que não vigiou). Esperar espaço no armazém (Bloco 106) ou uma entrega do carregador
## NÃO conta: aí ele espera, como antes. O cozinheiro e o carregador nunca têm secundária (o parado deles é esperar entrega).
@export var secundaria_padrao: Dictionary = {"engenheiro": "lenhador", "ferreiro": "minerador", "fundidor": "minerador",
	"carpinteiro": "lenhador", "mecânico": "lenhador", "guarda": "lenhador", "pesquisador": "minerador"}

@export_group("Perigo (Bloco 109)")
## Quem não é guarda e vê uma criatura viva a esta distância (px, no mesmo andar) larga tudo e corre pra casa...
@export var fuga_raio: float = 140.0
## ...e fica longe por estes segundos (pra não ir e voltar).
@export var fuga_tempo: float = 20.0
## Onda solar: vai pro ABRIGO mais perto (casa pronta ou taverna, de qualquer um) quando a própria cama fica mais longe que
## ele + isto (px). Sem cama: sempre o abrigo mais perto.
@export var abrigo_folga: float = 80.0

@export_group("Carona (Bloco 109)")
## Sem carregador na vila: quem acabou de descarregar no armazém leva o material de uma obra a até esta distância (px)
## dele antes de voltar ao trabalho (o mesmo caminho do carregador do Bloco 105)...
@export var carona_raio: float = 260.0
## ...e só uma vez a cada tantos segundos (não vira carregador de tempo inteiro).
@export var carona_intervalo: float = 45.0

@export_group("Visual")
## Bloco 73: 13 quadros/s na velocidade normal = o passo da vista iso (IsoBillboard.PASSO_CICLO:
## 4 quadros a cada 56 px de arte = ~37 px daqui); o som do passo cai junto com o pé.
@export var walk_anim_fps: float = 13.0
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
## Bloco 61: bichos que ele já abateu (caçador novato x experiente pro javali).
var hunt_kills := 0
## Bloco 68: segundos que ainda faltam na gaiola do elevador (0 = fora).
var _cage_wait := 0.0
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
## Bloco 77: a área de trabalho (work_areas.gd, WorkArea) onde ele foi posto pelo jogador, ou null. Com
## área, a busca de trabalho da função fica presa ao retângulo dela (e ocioso ele espera lá dentro).
var work_area = null
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
## Bloco 51: vigia (distância mais curta até a obra e há quanto tempo não melhora) e o ponto de
## acesso alternativo achado por ele (INF = o ponto normal da obra)
var _obra_watch_best := INF
var _obra_watch_t := 0.0
var _obra_alt := Vector2.INF
var _obra_alt_of: Node = null
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
## Bloco 70: a poça de perigo (ácido/lava) em que está pisando SEM o traje (null = nenhuma) e há quanto
## tempo (s) está exposto; passou de Fundo.exposicao, queima.
var _na_poca: Node = null
var _poca_expo := 0.0
## Bloco 71: segundos que ainda está molhado (passou pela água do S4): a lava queima menos.
var _molhado := 0.0
## Bloco 36: guarda que perdeu a luta — caído no lugar (grave), só o MÉDICO leva pra enfermaria.
var downed: bool = false
## Portão onde ele caiu ("tunel"; "" = no posto do poço, sem portão — Bloco 80): enquanto ele está caído
## no portão, é a brecha na defesa.
var downed_gate: String = ""
## (caído) o médico que vem buscar / quem está carregando agora.
var _rescuer: Node = null
var _carried_by: Node = null
## (médico) o caído que ele vai buscar / que está nas costas dele.
var _rescue: Node = null
var carrying_patient: Node = null
var _broken_icon: Sprite2D
var _hub_node: Node = null
## Bloco 84 (agenda e refeições): as refeições que ele já fez hoje ("cafe", "almoco", "jantar"; zeram no
## amanhecer) e as perdidas seguidas (estava com fome e a hora passou sem comer: rende menos até comer).
var refeicoes_hoje: Dictionary = {}
var refeicoes_perdidas: int = 0
var _prato := 0.0  # fome que ainda falta comer do prato servido
var _servido := false  # já pegou o prato nesta ida ao comedouro
var _refeicao_alvo := ""  # a refeição que ele foi fazer ("" = fome braba fora de hora)
var _periodo := ""  # período da agenda na última olhada
var _agenda_t := 0.0
var _sched: Node = null
var _caminhos: Node = null  # Bloco 89
## Bloco 85 (hora social): ânimo de ter conversado (fator do ânimo; some devagar), o ponto social e o lugar
## reservados, quanto falta pra trocar de ponto, se já chegou na roda, o passeio (waypoints) e o balão.
var animo_social := 0.0
## Bloco 88: ânimo de ter ido à missa (fator "foi à missa"; some devagar).
var animo_fe := 0.0
var _spot: Node = null
var _spot_i := -1
var _social_t := 0.0
var _conversando := false
var _com_companhia := false
var _com_amigo := false  # Bloco 110: a conversa de agora é com um amigo (anima mais)
## Bloco 110: os TRAÇOS (1 ou 2; vazio = ainda não sorteou: sorteia na primeira pergunta — o save antigo também), a
## HABILIDADE por função (0..1, sobe com a prática) e o ânimo do próprio casamento (some devagar).
var tracos: Array = []
var habilidade := {}
var animo_casamento := 0.0
## Bloco 111: a FAMÍLIA — a fase da vida ("adulto"; ou "bebe", "crianca", "aprendiz"), a idade (s de jogo, de quem nasceu
## aqui), os pais e os filhos (nomes dos nós), a gravidez (s que faltam; -1 = não), o pai do bebê, o resguardo depois de um
## parto sem médico, o ESTUDO (escola, 0..1), o mentor do aprendiz e o ânimo de ter ido à escola/brincado.
var fase := "adulto"
var idade_s := 0.0
var pais: Array = []
var filhos: Array = []
var gravidez_s := -1.0
var pai_bebe := ""
var resguardo_s := 0.0
var estudo := 0.0
var mentor := ""
var animo_escola := 0.0
var _parto_t := 0.0
var _brinca_t := 0.0
var _passeio: Array[Vector2] = []
var _balao_t := 0.0
var _balao: Sprite2D = null
var _balao_vida := 0.0
## Bloco 95: o BALÃO DE MOTIVO (por que está parado). Liga/desliga nas configurações ([hud] baloes_motivo):
## lido uma vez aqui (o settings.cfg é lido do disco a cada get_value) e trocado pela tela de configurações.
static var baloes_motivo := true
## Bloco 112: a introdução no mapa (intro_cinema.gd) esconde os balões (a caravana parada não está "sem trabalho").
static var sem_baloes := false
## Bloco 108: acidentes de trabalho (mina + galho) da sessão, pra telemetria contar por dia.
static var acidentes_trabalho := 0
## Bloco 109: mortes "bobas" da sessão (quem não é guarda, por criatura ou radiação) e as caronas — telemetria.
static var mortes_bobas := 0
static var caronas := 0
## Bloco 109: teste antigo que mede o tempo de resposta de uma função (fundidor, engenheiro...) liga isto no _initialize.
static var secundaria_desligada := false
const CAUSAS_BOBAS := ["radiacao", "lumivoro", "ferrugento", "gosma", "magmante"]
## Bloco 109: as secundárias possíveis ("" = automática pela função; "nenhuma" = desligada).
const SECUNDARIAS := ["", "nenhuma", ROLE_MINER, ROLE_LUMBER, ROLE_HUNTER, ROLE_FARMER]
## Bloco 109: a função secundária escolhida pelo jogador ("" = automática) e se ele está nela agora.
var funcao_secundaria := ""
var _na_secundaria := false
## Bloco 109: o abrigo da onda solar onde ele entrou, a fuga de uma criatura e a carona da logística.
var _abrigado_em: Node = null
var _fuga_t := 0.0
var _carona := false
var _carona_cd := 0.0
static var _baloes_lido := false
var _motivo := ""
var _motivo_t := 0.0
var _motivo_cd := 0.0
var _motivo_balao: Sprite2D = null
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
## Bloco 102: a PESQUISADORA NATURALISTA (catalogo.gd). nota_campo = a entrada que ela já estudou no campo e ainda
## vai entregar no laboratório (vai no save); _campo = a tarefa de agora {id, pos, fase (indo/anotando/voltando), t, lab}.
var nota_campo := ""
var _campo := {}
## Bloco 103: descobertas feitas (cada uma deixa o estudo mais rápido) e o ânimo da última (vai sumindo).
var xp_pesquisa := 0
var animo_descoberta := 0.0
## Bloco 107: o ânimo de ter comido ensopado (a cozinha soma; decai sozinho).
var animo_prato := 0.0
## Bloco 107: o cozinheiro prepara a leva x isto mais devagar (o ensopado / a ração; a cozinha põe a cada quadro).
var prep_mult := 1.0

## Bloco 104: EXPEDIÇÃO (expedicoes.gd). _expedicao_saida = andando até a saída; fora = fora do mundo (escondido, fora do
## grupo da vila: não come, não trabalha, não conta; a cama fica); nasce_fora = recriado do save já fora.
var fora := false
var nasce_fora := false
var _expedicao_saida := Vector2.INF
var _camadas_colisao := Vector2i(-1, -1)
## Bloco 104: o batedor batendo o mato: {pos, t (segundos parado olhando), toca}.
var _bate := {}
## Bloco 105: o CARREGADOR — a entrega de agora (logistica.gd: {tipo, alvo, chave} + fase) e o que ele leva fora das
## obras (barras, matéria-prima: {item: qtd}); os insumos a caminho da fornalha só aparecem (o pagamento já foi feito).
var _carga := {}
var entrega_mao := {}
var _levando_insumo := false
## Bloco 105: o MECÂNICO — a máquina da preventiva e o tempo que ele já trabalhou nela.
var _manut_alvo: Node = null
var _manut_t := 0.0
var _manut_andando := 0.0  # Bloco 105: segundos andando sem chegar na máquina (desiste: manutencao.preventiva_desiste)
## Bloco 105: o engenheiro (ou o mecânico) esperando o carregador trazer o material.
var _espera_carregador := false

## Bloco 101: MIGRANTE esperando no portão (migrantes.gd): fora do grupo "ipezinhos" (não come, não ocupa cama, não conta)
## e sem IA nem necessidades — só anda até onde mandarem. Aceito: vira_morador().
var visitante := false

## Bloco 99: a cabine do elevador em que ele está (na fila ou dentro), se já embarcou e há quanto tempo espera; e a
## boca da mina onde ele trabalha DENTRO (estacao_vagonete.gd com interior).
var _na_cabine: Node = null
var _a_bordo := false
var _fila_t := 0.0
var _mina_dentro: Node = null
## Bloco 99: na fila da cabine há mais que isso (s de jogo), desiste e procura outro caminho (a escada em espiral).
const FILA_DESISTE := 120.0

## Bloco 98: o destino de verdade (o _target vira o lugar de espera no portão fechado) e se está esperando o portão.
var _alvo_final := Vector2.ZERO
var _esperando_portao := false

@onready var _agent: NavigationAgent2D = $Agent
## Acessórios (Bloco 24): camadas filhas do Body, com os mesmos 4 quadros de caminhada.
@onready var _accessories: Array[Sprite2D] = [$Body/Boots, $Body/Detail, $Body/Neck]
var _accessory_variant: Array[int] = [-1, -1, -1]


func _ready() -> void:
	if visitante:
		add_to_group("migrantes_gente")  # Bloco 101: ainda não é da vila
		auto_mode = false
	else:
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
	if not visitante:
		_claim_home.call_deferred()  # as casas precisam estar nos grupos
	if nasce_fora:
		sai_do_mundo.call_deferred()  # Bloco 104: do save, numa expedição
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
	if _na_cabine != null and not _a_bordo:
		if pos.distance_to(_alvo_final) <= 2.0:
			return  # (o mesmo destino: continua na fila)
		_sai_da_fila()  # Bloco 99: mudou de ideia esperando a cabine
	_alvo_final = pos
	_esperando_portao = false
	pos = _ate_o_portao(pos)
	_target = pos
	_moving = true
	_agent.target_position = pos


## Bloco 98: o portão da paliçada fechado (de noite) separa a floresta da vila: quem tem destino do outro lado vai
## esperar encostado no portão, do lado dele (e não ao longo da cerca, que é o ponto mais perto do destino).
func _ate_o_portao(pos: Vector2) -> Vector2:
	var b := get_tree().get_first_node_in_group("barricadas")
	if b == null or not b.has_method("separa") or not b.separa(global_position, pos):
		return pos
	_esperando_portao = true
	return b.espera_pos(self, global_position)


## Bloco 98: o portão abriu ou fechou (o Barricada avisa todo mundo). Quem esperava segue pro destino; quem andava
## com o caminho cortado refaz o caminho (e vai esperar no portão).
func portao_mudou() -> void:
	if _esperando_portao:
		_go_to(_alvo_final)
	elif _moving:
		_go_to(_target)


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
		var why: String = {"galho": " por galho", "parto": " do parto"}.get(injury_cause, "")
		return "curando (%ds)" % ceili(_recovery_left) if _resting else "machucado%s, indo pra casa" % why
	if _ai_state == "home" and _resting:
		var sun := _sun()
		if sun and sun.shelter_now() and not _is_night():
			return "abrigado do sol" if _inside else "sem abrigo, no sol!"
		if _periodo in ["social", "voltar"]:  # Bloco 84: ainda não é hora de dormir
			return "descansando em casa" if _inside else "descansando ao relento"
		return "dormindo" if _inside else "dormindo ao relento"
	if _ai_state == "social":  # Bloco 85
		if _spot == null or not is_instance_valid(_spot):
			return "hora social"
		if _conversando:
			return ("conversando: %s" if _com_companhia else "esperando alguém: %s") % _spot.nome
		return "passeando até: %s" % _spot.nome
	if _ai_state == "eating" and _refeicao_alvo != "":  # Bloco 84
		return "%s (%s)" % ["comendo" if _servido else "indo comer", Schedule.nome_refeicao(_refeicao_alvo)]
	if _ai_state == "building" and _espera_carregador and _obra != null and is_instance_valid(_obra):
		return "esperando o carregador trazer o material"  # Bloco 105
	if _ai_state == "carregando" and not _carga.is_empty():  # Bloco 105
		var nm := {"obra": "material pra obra", "insumo": "insumos pra fornalha", "barras": "barras pro armazém", "cozinha": "matéria-prima pra cozinha"}
		return "levando %s" % nm.get(String(_carga.tipo), "material")
	if _ai_state == "manutencao" and _manut_alvo != null and is_instance_valid(_manut_alvo):
		return "manutenção: %s" % _manut_alvo.manut_titulo()
	if _ai_state == "catalogando":  # Bloco 102
		var cat := _catalogo()
		var nm: String = "???" if cat == null or _campo.is_empty() else ("amostra de " + cat.nome(_campo.id) if _campo.get("lab", false) else "???")
		match String(_campo.get("fase", "")):
			"anotando":
				return "estudando %s (%d%%)" % [nm, roundi(float(_campo.t) / maxf(cat.segundos_estudo, 1.0) * 100.0)] if cat else "estudando"
			"voltando":
				return "levando a anotação pro laboratório"
		return "indo estudar uma descoberta"
	if _ai_state == "idle" and has_no_job():
		return "sem função — esperando ordem"
	if _ai_state == "idle" and is_cook():
		return "esperando matéria-prima"
	if _ai_state == "idle" and is_farmer():
		return "sem horta nem estufa pra colher (construa pelo menu CONSTRUIR)"  # Bloco 107
	if _ai_state == "idle" and is_hunter():
		return "sem fruta nem caça na clareira"
	if _ai_state == "doctor":
		if _on_duty == null:
			return "indo pra enfermaria (plantão)"
		var n: int = _on_duty.patients().size()
		return "tratando %d internado%s" % [n, "s" if n > 1 else ""] if n > 0 else "de plantão, esperando pacientes"
	if _ai_state == "building" and _obra != null and is_instance_valid(_obra) and _material_texto() != "":
		return _material_texto()  # Bloco 96: buscando / levando / falta material
	if _ai_state == "building" and _obra != null and is_instance_valid(_obra):
		var pct := roundi(_obra.obra_progress() * 100.0)
		if is_smith():  # Bloco 87
			return ("forjando: %s (%d%%)" if _obra_on_site else "indo pra forja: %s (%d%%)") % [_obra.obra_title(), pct]
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
	if _na_cabine != null:  # Bloco 99: esperando a cabine (de pé na fila) ou viajando nela
		_fila_t += delta
		_apply_velocity(Vector2.ZERO)
		if not _a_bordo and _fila_t > FILA_DESISTE:
			_sai_da_fila()
			_go_to(_alvo_final)
		return
	if _cage_wait > 0.0:  # Bloco 68: na gaiola do elevador (viagem / fila)
		_cage_wait -= delta
		_apply_velocity(Vector2.ZERO)
		return
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
	var load_ratio := carrying / capacidade_carga()
	var penalty := 1.0 - (load_ratio * loaded_speed_penalty)
	var s := speed * penalty
	if hunger <= 0.0:
		s *= starving_speed_mult
	if injured:
		s *= injured_speed_mult
	if _na_poca != null and is_instance_valid(_na_poca):
		s *= _na_poca.lentidao()  # Bloco 70: atolado no ácido/lava sem traje
	if holding_robot != null:
		s *= carry_robot_speed_mult
	if carrying_patient != null:
		s *= carry_patient_speed_mult
	s *= [1.0, irritated_speed_mult, furious_speed_mult][_mood]  # zanga acumula com a lesão
	s *= _neve_mult()  # Bloco 94: a neve atrasa quem anda sem botas
	return s * _speed_bonus()


## Bloco 89: bônus de velocidade do CAMINHO embaixo dele (a melhoria Trilhas aumenta o bônus dos caminhos).
func _speed_bonus() -> float:
	if _caminhos == null or not is_instance_valid(_caminhos):
		_caminhos = get_tree().get_first_node_in_group("caminhos") if is_inside_tree() else null
	return _caminhos.velocidade_em(global_position) if _caminhos else 1.0


func _village_hub() -> Node:
	if _hub_node == null or not is_instance_valid(_hub_node):
		_hub_node = get_tree().get_first_node_in_group("village_hub")
	return _hub_node


# ------------------------------------------------------------ fome / IA
func _process(delta: float) -> void:
	if visitante:
		return  # Bloco 101: esperando no portão (sem fome, sem agenda, sem IA)
	var was_starving := hunger <= 0.0
	var sun := _sun()
	var decay: float = hunger_decay * (sleep_hunger_mult if _resting else 1.0) * (sun.hunger_mult() if sun else 1.0)  # inverno: mais fome
	decay *= Modificadores.mult(get_tree(), "fome", self)  # Bloco 113: a dificuldade
	var rel_f := _relacoes()
	if rel_f:
		decay *= rel_f.mult_fome(self)  # Bloco 110: o guloso
		_pratica(rel_f, delta)
	if e_crianca():  # Bloco 111: a criança come meia porção e a fome dela cai na mesma fração; o bebê a mãe alimenta
		var fam_c := _familias()
		decay *= fam_c.crianca_porcao if fam_c else 0.5
		if e_bebe():
			hunger = hunger_max
			decay = 0.0
	_familia_tick(delta)
	hunger = maxf(hunger - decay * delta, 0.0)
	if int(hunger) != _last_hunger_int:
		_update_hunger_label()
	if hunger <= 0.0 and not was_starving:
		_on_starving()
	_agenda_tick(delta)  # Bloco 84
	if _ai_state == "catalogando":
		_campo_tick(delta)  # Bloco 102
	elif _ai_state == "batendo":
		_bate_tick(delta)  # Bloco 104
	elif _ai_state == "carregando":
		_carrega_tick()  # Bloco 105
	elif _ai_state == "manutencao":
		_manut_tick(delta)
	if animo_descoberta > 0.0:
		animo_descoberta = maxf(animo_descoberta - animo_descoberta_decai * delta, 0.0)  # Bloco 103
	if animo_prato > 0.0:
		animo_prato = maxf(animo_prato - animo_prato_decai * delta, 0.0)  # Bloco 107
	_fuga_t = maxf(_fuga_t - delta, 0.0)  # Bloco 109
	_carona_cd = maxf(_carona_cd - delta, 0.0)
	_social_process(delta)  # Bloco 85
	_motivo_tick(delta)  # Bloco 95

	_work_timer = maxf(_work_timer - delta, 0.0)
	_update_anger(delta)
	# machucado: só cura DEITADO num leito da enfermaria; fora dele o relógio corre
	if injured:
		_update_injury(delta)
	_equip_tick(delta)  # Bloco 42: casaco no inverno, traje nas zonas de perigo
	if _ai_state == "guard":
		_guard_tick(delta)
	elif _ai_state == "patrulha":
		_patrulha_tick(delta)  # Bloco 103
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
			if _material_obra == _obra:
				solta_material(true)  # Bloco 96: a obra acabou/foi cancelada com material na mão: volta pro armazém
			_obra_stop()
			_decision_timer = 0.0  # acabou: próxima obra da fila
		elif _material_tick():
			pass  # Bloco 96: buscando ou levando material (as viagens andam sozinhas)
		elif not _obra_on_site:
			# chegou: parou perto (a obra pode estar dentro de um obstáculo) ou já está
			# colado no ponto mesmo com outro engenheiro esbarrando nele
			var dist := global_position.distance_to(_obra_goal())
			if (not _moving and dist <= OBRA_REACH) or dist <= 24.0:
				_moving = false
				_obra_on_site = true
				_obra_watch_best = INF
				_obra_watch_t = 0.0
				_obra.obra_join(self)
			else:
				_obra_watchdog_tick(delta, dist)
		elif _pode_construir():
			_work_timer = 0.2  # martelada
			_obra.obra_work(delta * work_mult())  # zanga/tristeza deixam mais lento
			if not _obra.obra_pending():
				_popup("Obra pronta!", Color(0.55, 1.0, 0.5))
				Audio.build_done(global_position)  # Bloco 55
				_obra_stop()
				_decision_timer = 0.0
	# médico chegou na porta da enfermaria: entra e fica de plantão
	if _ai_state == "doctor" and _on_duty == null and not _moving:
		var ward := _doctor_ward()
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
	# Bloco 111: o bebê fica em casa (na cama: só o ícone)
	if e_bebe():
		return "bebe"
	# Bloco 36: caído em combate não anda — espera o médico (ou vai nas costas dele).
	if downed:
		return "downed"
	# Bloco 111: chegou a hora do parto (a enfermaria, se tem; senão em casa)
	if gravida() and gravidez_s <= 0.0 and not injured:
		return "parto"
	# Bloco 104: mandado pra uma expedição: anda até a saída (a expedicoes.gd tira ele do mundo lá)
	if _expedicao_saida != Vector2.INF and not injured:
		return "expedicao"
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
			return _destino_onda()  # Bloco 109: o abrigo MAIS PERTO (sem cama, nunca mais do lado de fora)
		if _ai_state == "mining" and _station_ok_for("mining"):
			return "mining"
		return "idle"
	# Bloco 84: invasão em andamento — quem não é guarda fica em casa (o médico, no plantão).
	# Bloco 109: e já no AVISO da invasão (recolhe mais cedo); criatura viva perto: larga tudo e corre pra casa.
	var def_inv := _defense()
	if def_inv and (def_inv.invasion_active or (def_inv.has_method("aviso_dado") and def_inv.aviso_dado())) and not is_guard():
		return "doctor" if is_doctor() and _has_infirmary() else "home"
	if not is_guard() and not is_doctor() and not _valente() and _foge():
		return "home"
	# Sem enfermaria na cena (fallback antigo): machucado descansa em casa.
	if injured:
		return "home"
	# Bloco 84: comendo (pegou o prato, ou indo pegar com comida lá): fica até acabar.
	var food_ok := _food_available()
	if _ai_state == "eating" and ((not _servido and food_ok) or _prato > 0.0):
		if _prato > 0.0 and not _moving and (_station == null or not is_instance_valid(_station) or _slot < 0):
			_prato = 0.0  # Bloco 109: perdeu o lugar no comedouro com o prato pela metade: larga (antes ficava parado pra sempre)
		else:
			return "eating"
	# Bloco 84: a AGENDA (Schedule): dormir, refeições, voltar, hora social, plantão, vigília. "" = horário
	# de trabalho (ou sem relógio): segue a lógica de sempre aqui embaixo.
	var ag := _agenda_estado(food_ok)
	if ag != "":
		return ag
	# Prioridade 1: comer FORA de hora só com fome braba (uma porção).
	# Sem comida no comedouro não adianta esperar lá: segue trabalhando (com fome).
	if hunger < hunger_threshold and food_ok:
		return "eating"
	# Lazer: triste vai pra taverna (se existir) e fica até se animar.
	if _ai_state == "leisure" and happiness < leisure_until and _station_ok_for("leisure"):
		return "leisure"
	if happiness < leisure_below and _has_usable_station("tavernas") and not e_crianca():
		return "leisure"
	# Greve: ninguém trabalha (só come, dorme, se trata e vai à taverna).
	if _on_strike() and not e_crianca():  # (Bloco 111: criança não faz greve)
		return "strike"
	# Mandaram buscar o robô antigo: vai, pega e leva pra Oficina.
	if _robot_task != null:
		if is_instance_valid(_robot_task) and _robot_task.needs_carrier(self):
			return "robot"
		_robot_task = null
	# Comida PRONTA na cesta (só de save de antes do Bloco 27): entrega no comedouro.
	if food_carrying > 0.0:
		return "delivering"
	# Bloco 109: a CARONA (sem carregador na vila): acabou de descarregar no armazém e leva material pra uma obra perto.
	if _carona:
		if not _carga.is_empty():
			return "carregando"
		_carona = false
	if _quer_carona():
		return "carregando"
	# Bloco 27: matéria-prima nas mãos de quem não é cozinheiro vai pro armazém
	# (caçador com a mochila cheia / sem mais fruta nem caça, ou quem trocou de função).
	# (O cozinheiro com matéria-prima vai preparar: ver o bloco dele mais abaixo.)
	# Bloco 106: o compartimento do que ele coleta cheio em todos os armazéns: não coleta mais, guarda o que carrega e
	# espera disponível (volta sozinho quando abrir espaço). A emergência, a agenda e as necessidades já vieram antes.
	# (só quem COLETA aquilo espera; quem tem a carga por outro motivo — trocou de função, o engenheiro com sobra — fica
	# com ela e segue a função dele, sem ir até o armazém cheio)
	if raw_carrying > 0.0 and _faz_coleta() and _sem_espaco("alimentos"):
		return "esperando_espaco"
	if wood_carrying > 0.0 and _faz(ROLE_LUMBER) and _sem_espaco("madeira"):
		return "esperando_espaco"
	if raw_carrying > 0.0 and not is_cook() and not _sem_espaco("alimentos"):
		var pack_full := _raw_units >= hunter_carry - 0.01
		# (quem já está colhendo/caçando continua até a fonte acabar; só depois descarrega)
		var keep_going := _ai_state in ["foraging", "hunting"] and _station_ok_for(_ai_state)
		if not _faz_coleta() or pack_full or _ai_state == "stocking" or (not keep_going and not _hunter_has_work()):
			return "stocking"
	# Madeira nas costas: leva pro armazém (lenhador cheio / sem árvore, ou quem deixou de ser lenhador).
	if wood_carrying > 0.0 and not _sem_espaco("madeira"):
		var wood_full := wood_carrying >= lumber_carry - 0.01
		# (quem já está cortando continua até a árvore virar toco; só depois vai descarregar)
		var keep_chopping := _ai_state == "chopping" and _station_ok_for("chopping")
		if not _faz(ROLE_LUMBER) or wood_full or _ai_state == "hauling" or (not keep_chopping and not _has_usable_station("arvores")):
			return "hauling"
	# Bloco 25: quem não é minerador não fica com minério na mão — entrega antes
	# (ex.: trocou de função no meio da carga, ou tiraram a função dele).
	# Pesquisador fica de fora: sem laboratório ele volta a minerar (como já era),
	# e mandar guardar cada pedrinha viraria um vai-e-volta sem fim.
	if carrying > 0.0 and not _faz(ROLE_MINER) and not is_researcher() and not _sem_espaco("minerios"):
		return "storing"
	# Bloco 109: a FUNÇÃO; sem nada pra fazer nela (no expediente), a SECUNDÁRIA.
	var e := _estado_funcao()
	if _sem_trabalho(e) and _pode_secundaria():
		var e2 := _estado_secundario()
		if e2 != "":
			if not _na_secundaria:
				_na_secundaria = true
				_apply_outfit()  # veste a roupa da secundária (a arte que já existe dela)
				_popup("De %s agora" % nome_funcao(secundaria()), Color(0.8, 0.9, 0.6))
			return e2
	if _na_secundaria:
		_na_secundaria = false
		_apply_outfit()
	return e


## A decisão da FUNÇÃO principal (o que vinha no fim do _choose_state antes do Bloco 109).
func _estado_funcao() -> String:
	if e_crianca():
		return _estado_crianca()  # Bloco 111: escola, brincar, aprender
	if resguardo_s > 0.0:
		return "home"  # Bloco 111: o resguardo depois de um parto sem médico
	# Médico (Bloco 30): plantão DENTRO da enfermaria, tendo internado ou não (esperando
	# por lá: não sai pra minerar sozinho). Comer, dormir, se tratar etc. vêm antes.
	if is_doctor():
		return "doctor" if _has_infirmary() else "idle"
	# Engenheiro (Bloco 31): vai tocar a obra mais antiga encomendada; sem obra, espera
	# no Centro da Vila. (Minério na mão já foi entregue pela regra de cima.)
	if is_engineer():
		return "building" if _pick_obra() != null else "idle"
	# Bloco 87: ferreiro — a obra da Oficina e a forja do Arsenal (só com encomenda; sem: espera).
	if is_smith():
		return "building" if _pick_obra() != null else "idle"
	# Bloco 105: mecânico — primeiro o conserto da quebra (obra com material, ofício "mecanico"); depois a preventiva.
	if is_mechanic():
		if _pick_obra() != null:
			return "building"
		var mt := _manutencao()
		if mt and ((_manut_alvo != null and is_instance_valid(_manut_alvo)) or mt.alvo_preventiva(self) != null):
			return "manutencao"
		return "idle"
	# Bloco 105: carregador — as entregas da logística (obras, fornalha, cozinha).
	if is_carrier():
		var lg := _logistica()
		if lg and (not _carga.is_empty() or lg.tem_entrega_para(self)):
			return "carregando"
		return "idle"
	# Guarda: à noite fica nos portões; de dia treina (até ficar pronto) e descansa.
	# Bloco 35: desarmado vai ao Arsenal pegar outra arma (até de noite: sem arma no
	# posto não adianta); de dia também troca por uma melhor que estiver no cavalete.
	if is_guard():
		if (_ai_state == "rearming" and _station_ok_for("rearming")) or (_wants_rearm() and _has_usable_station("arsenais")):
			return "rearming"
		if _is_night():
			return "guard"
		var def_p := _defense()
		if def_p and def_p.has_method("patrulha_para") and def_p.patrulha_para(self) != "":
			return "patrulha"  # Bloco 103: mandado caçar os moradores do fundo (de dia)
		if combat_skill < teto_treino() and ((_ai_state == "training" and _station_ok_for("training")) or _has_usable_station("campos")):
			return "training"
		return "home"
	# Bloco 104: o batedor bate o mato (de dia; a agenda já mandou pra casa de noite)
	if is_scout():
		return "batendo"
	# Pesquisador: de dia no laboratório se tiver pesquisa em andamento; senão trabalha normal.
	# Bloco 102: com uma anotação na mão, entrega primeiro; sem pesquisa, sai pra CATALOGAR o que a vila avistou
	# (catalogo.gd); sem nada pra catalogar, minera como antes.
	if is_researcher():
		if nota_campo != "":
			return "catalogando"
		if (_ai_state == "research" and _station_ok_for("research")) or _has_usable_station("laboratorios"):
			return "research"
		var cat := _catalogo()
		if cat and ((_ai_state == "catalogando" and not _campo.is_empty()) or cat.tem_alvo(self)):
			return "storing" if carrying > 0.0 else "catalogando"  # (o minério na mão vai pro armazém antes)
	# Lenhador: larga o minério que tiver e passa a só cortar e levar madeira.
	# Bloco 45: o designado pro coletor de madeira fica operando a máquina.
	if is_lumber():
		if carrying > 0.0 and not _sem_espaco("minerios"):
			return "storing"
		var op_carvao := _estado_oficina_extra()  # Bloco 107: com ordem na carvoaria, um lenhador opera
		if op_carvao != "":
			return op_carvao
		if _sem_espaco("madeira"):
			return "esperando_espaco"  # Bloco 106 (o coletor dele também para)
		if _my_coletor() != null:
			return "operating"
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
		if raw_carrying <= 0.0 and _cozinha_com_estoque() != null:
			return "cooking"  # Bloco 105: o carregador trouxe pro estoque da cozinha (ela abastece a cesta lá)
		if _ai_state != "fetching" and raw_carrying <= 0.0:
			var lgc := _logistica()
			var coz := _closest_in_group("comedouros")
			if lgc and coz and lgc.deixa_pro_carregador("cozinha", coz):
				return "idle"  # Bloco 105: o carregador vem trazendo (sem ninguém pegar, ele mesmo vai: fallback)
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
	# Bloco 107: o AGRICULTOR colhe a horta e a estufa (o grupo "coleta_comida") e leva a fruta pro armazém.
	if is_farmer():
		if _sem_espaco("alimentos"):
			return "esperando_espaco"
		if _ai_state == "foraging" and _station_ok_for("foraging"):
			return "foraging"
		if _has_usable_station("coleta_comida"):
			return "foraging"
		return "idle"
	if is_hunter():
		var op_curtume := _estado_oficina_extra()  # Bloco 107: com ordem no curtume, um caçador opera
		if op_curtume != "":
			return op_curtume
		if _sem_espaco("alimentos"):
			return "esperando_espaco"  # Bloco 106
		if _ai_state == "hunting" and _station_ok_for("hunting"):
			return "hunting"
		if _has_usable_station("caca"):  # a toca só conta como usável com arco e flecha
			return "hunting"
		# Bloco 107: com agricultor na vila, a horta é dele (o caçador só caça); sem, ele colhe como sempre
		if _ai_state == "foraging" and _station_ok_for("foraging") and not _agricultor_na_vila():
			return "foraging"
		if _has_usable_station("coleta_comida") and not _agricultor_na_vila():
			return "foraging"
		return "idle"
	# Bloco 86: fundidor — só trabalha com ORDEM na fornalha (sem ordem: não pega nada).
	if is_smelter():
		return _estado_fundidor()
	# Bloco 94: carpinteiro — primeiro monta a cama que o jogador mandou trocar; senão, as ordens da carpintaria.
	if is_carpenter():
		if barras_mao.is_empty() and _casa_pra_cama() != null:
			return "montando_cama"
		return _estado_fundidor()
	# Bloco 25: sem função não trabalha sozinho — espera no Centro da Vila até o
	# jogador designar. (Comer, dormir, se tratar, taverna e greve vêm antes e seguem iguais.)
	if has_no_job():
		return "idle"
	# Bloco 57: o minerador designado pro coletor de minério entrega o que tem e fica operando.
	if is_miner() and _sem_espaco("minerios"):
		return "esperando_espaco"  # Bloco 106: o minério (e o ponto do vagonete) cheio: não minera mais
	if is_miner() and _my_coletor_minerio() != null:
		return "storing" if carrying > 0.0 else "operating_ore"
	# Daqui pra baixo: minerador (e pesquisador sem laboratório, como antes).
	# Bloco 99: com a área de mina, o trilho e o vagonete funcionando, o mineiro trabalha DENTRO da mina (entra pela boca;
	# o minério vai pro vagonete). Com carga na mão, entrega antes (a regra de baixo).
	if is_miner() and carrying <= 0.0 and _boca_da_mina() != null:
		return "na_mina"
	# Prioridade 2: depositar carga cheia (e não desistir no meio do caminho).
	if carrying >= capacidade_carga() - 0.01:
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
	if desired != "abrigo" and _abrigado_em != null:
		_sai_do_abrigo()  # Bloco 109: a onda passou (ou outra coisa ganhou): sai do abrigo
	if desired == "bebe":  # Bloco 111: na cama de casa (escondido: só o ícone)
		if _ai_state != "bebe":
			_release_station()
			_set_state("bebe")
		_go_home()
		return
	if desired == "parto":  # Bloco 111
		if _ai_state != "parto":
			_release_station()
			_set_state("parto")
			_parto_t = 0.0
		var dp := _destino_parto()
		if global_position.distance_to(dp) > 40.0 and (not _moving or _target.distance_to(dp) > 4.0):
			_go_to(dp)
		return
	if desired == "brincando":  # Bloco 111
		if _ai_state != "brincando":
			_release_station()
			_set_state("brincando")
			_brinca_t = 0.0
		_brinca()
		return
	if desired == "aprendendo":  # Bloco 111
		if _ai_state != "aprendendo":
			_release_station()
			_set_state("aprendendo")
		_acompanha()
		return
	if desired == "abrigo":  # Bloco 109: vai pro abrigo mais perto e entra
		if _ai_state != "abrigo":
			_release_station()
			_set_state("abrigo")
		_vai_pro_abrigo()
		return
	if not carregando_corpo.is_empty() and desired != "padre":
		_larga_corpo()  # Bloco 93: emergência no meio do caminho: o corpo volta pro chão (ele busca depois)

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

	if desired == "na_mina":  # Bloco 99: vai pra boca e entra (quem está dentro fica)
		if _ai_state != "na_mina":
			_release_station()
			_set_state("na_mina")
		if _mina_dentro == null:
			var b := _boca_da_mina()
			if b != null:
				var porta: Vector2 = b.boca_pos()
				if global_position.distance_to(porta) <= 16.0:
					_entra_mina(b)
				elif not _moving or _target.distance_to(porta) > 2.0:
					_go_to(porta)
		return

	if desired == "montando_cama":  # Bloco 94
		_montar_cama()
		return

	if desired == "expedicao":  # Bloco 104: até a saída da expedição
		if _ai_state != "expedicao":
			_release_station()
			_set_state("expedicao")
		if not _moving or _target.distance_to(_expedicao_saida) > 4.0:
			_go_to(_expedicao_saida)
		return

	if desired == "carregando":  # Bloco 105: a entrega (anda sozinha no _carrega_tick)
		if _ai_state != "carregando":
			_release_station()
			_set_state("carregando")
		_carregar()
		return

	if desired == "manutencao":  # Bloco 105: a preventiva (anda no _manut_tick)
		if _ai_state != "manutencao":
			_release_station()
			_set_state("manutencao")
		var mt := _manutencao()
		if mt and (_manut_alvo == null or not is_instance_valid(_manut_alvo)):
			_manut_alvo = mt.alvo_preventiva(self)
			_manut_t = 0.0
			_manut_andando = 0.0
			if _manut_alvo:
				mt.reserva(_manut_alvo, self)
		if _manut_alvo:
			var p: Vector2 = _manut_alvo.manut_pos(self)
			if global_position.distance_to(p) > 26.0 and (not _moving or _target.distance_to(p) > 4.0):
				_go_to(p)
		return

	if desired == "batendo":  # Bloco 104: escolhe um ponto da beira da floresta e vai olhar
		if _ai_state != "batendo":
			_release_station()
			_set_state("batendo")
			_bate = {}
		_batendo()
		return

	if desired == "catalogando":  # Bloco 102: a tarefa de campo (anda sozinha no _campo_tick)
		if _ai_state != "catalogando":
			_release_station()
			_set_state("catalogando")
		_catalogar()
		return

	if desired == "padre":  # Bloco 88: o padre fica na porta da igreja (sem igreja: na praça)
		var cal := get_tree().get_first_node_in_group("calendario")
		if cal and _padre_enterro(cal):
			return  # Bloco 93: buscando, levando ou enterrando alguém
		if _ai_state != "padre":
			_release_station()
			_set_state("padre")
		var ig: Node = cal.igreja() if cal else null
		var dest: Vector2 = ig.altar_pos() if ig else (_village_hub().global_position + Vector2(0, 70) if _village_hub() else global_position)
		var fl: Node = cal.funeral_lugar_agora() if cal else null
		if fl != null and fl.has_method("portao_pos"):
			dest = fl.portao_pos()  # Bloco 93: o funeral é no cemitério
		if global_position.distance_to(dest) > 12.0 and (not _moving or _target.distance_to(dest) > 2.0):
			_go_to(dest)
		elif cal and cal.pregando_agora():
			_work_timer = decision_interval * 1.2  # Bloco 92: na missa e no funeral ele prega (até a próxima decisão)
		return

	if desired == "social":  # Bloco 85
		if _ai_state != "social":
			_release_station()
			_set_state("social")
			_social_vai()
		return

	if desired == "guard":
		if _ai_state != "guard":
			_release_station()
			_set_state("guard")
		return  # quem manda é o _guard_tick (posto / luta)

	if desired == "patrulha":  # Bloco 103: quem manda é o _patrulha_tick (desce, procura o morador, luta)
		if _ai_state != "patrulha":
			_release_station()
			_set_state("patrulha")
		return

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
		if not _obra_on_site and material_pedido.is_empty() and material_mao.is_empty():  # (Bloco 96: viagem anda sozinha)
			var pos: Vector2 = _obra_goal()
			if not _moving or _target.distance_to(pos) > 2.0:
				_go_to(pos)
		return

	if desired == "doctor":
		if _ai_state != "doctor":
			_release_station()
			_set_state("doctor")
		if _on_duty == null:
			var ward := _doctor_ward()
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

	if desired == "esperando_espaco":  # Bloco 106: disponível, esperando o armazém abrir espaço (no Centro ou na área)
		if _ai_state != "esperando_espaco":
			_release_station()
			_set_state("esperando_espaco")
		_idle_at_hub()
		return

	if desired == "idle":
		if has_no_job() or is_engineer() or is_smith() or work_area != null:  # Bloco 77: com área, espera nela
			_idle_at_hub()
			return
		if not _moving and randf() < 0.35:
			var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(10.0, idle_wander_radius)
			_go_to(global_position + offset)
		return

	var group: String = STATE_GROUP[desired]
	var station := _find_best_station(group)
	if desired == "storing" and carrying > 0.0:  # Bloco 64: ponto de carga do vagonete mais perto?
		var pc := _find_best_station("pontos_carga")
		if pc and (station == null or global_position.distance_to(pc.global_position) < global_position.distance_to(station.global_position)):
			station = pc
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
	if work_area != null:  # Bloco 77: sem trabalho na área (sem árvore, mina desligada): espera nela
		var r: Rect2 = work_area.rect
		if not r.has_point(global_position) or randf() < 0.2:
			_go_to(r.position + Vector2(randf_range(0.2, 0.8) * r.size.x, randf_range(0.2, 0.8) * r.size.y))
		return
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
	if state in ["mining", "chopping", "foraging", "hunting"] and not _area_permite(_station, STATE_GROUP[state]):
		return false  # Bloco 77: a área mudou (desligaram a mina, tiraram ele da área)
	if state == "mining":
		return _station.has_ore() and carrying < capacidade_carga()
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
	if state == "cooking":  # (Bloco 105: ou o estoque da cozinha, que o carregador trouxe)
		return (raw_carrying > 0.0 or float(_station.get("raw_local") if _station.get("raw_local") != null else 0.0) >= 0.5) and _station.space_left() > 0.5
	if state == "delivering":
		return food_carrying > 0.0 and _station.space_left() > 0.5
	if state == "eating":
		return _station.has_food()
	if state == "operating":
		return is_lumber() and _station.get("operator") == self
	if state == "operating_ore":
		return is_miner() and _station.get("operator") == self
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
			or not (link.get_parent().is_in_group("elevador") or link.get_parent().is_in_group("elevadores") or link.get_parent().is_in_group("espirais")):
		return
	var exit: Vector2 = details.get("link_exit_position", global_position)
	var shaft: Node = link.get_parent()
	if shaft.has_method("usa_cabine") and shaft.get("cabine") != null:
		_entra_na_fila(shaft, details.get("link_entry_position", global_position), exit)  # Bloco 99
		return
	global_position = exit
	if shaft.is_in_group("espirais"):
		Audio.step(exit)  # Bloco 99: os passos na escada em espiral
	else:
		Audio.elevator(exit)  # corrente + "clanc" da gaiola
	# Bloco 68: a viagem leva tempo (Bloco 99: a escada em espiral, espiral.gd, usa isto: some e aparece no outro andar)
	_cage_wait = shaft.ride_wait() if shaft.has_method("ride_wait") else 0.0
	_body.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(_cage_wait)
	tw.tween_property(_body, "modulate:a", 1.0, 0.35)


# ------------------------------------------------------------ a cabine (Bloco 99)
## Chegou na gaiola: entra na fila do lado dele e espera de pé (os da fila ficam um atrás do outro).
func _entra_na_fila(shaft: Node, entrada: Vector2, saida: Vector2) -> void:
	var cima: bool = entrada.distance_to(shaft.global_position) <= entrada.distance_to(shaft.bottom_position)
	var n: int = shaft.cabine.entra(self, cima, saida)
	_na_cabine = shaft
	_a_bordo = false
	_fila_t = 0.0
	var lado := Vector2(-11.0, 8.0) if cima else Vector2(-11.0, 10.0)
	global_position = (shaft.global_position if cima else shaft.bottom_position) + lado + Vector2(-7.0, 4.0) * float(n)


func _sai_da_fila() -> void:
	if _na_cabine != null and is_instance_valid(_na_cabine):
		_na_cabine.cabine.sai(self)
	_na_cabine = null
	_a_bordo = false
	_body.modulate.a = 1.0


## A cabine chama: entrou (some dentro dela).
func embarca_cabine() -> void:
	_a_bordo = true
	_body.modulate.a = 0.0


## A cabine chegou no outro andar: sai na gaiola de lá e segue o caminho.
func desembarca_cabine(saida: Vector2) -> void:
	_na_cabine = null
	_a_bordo = false
	global_position = saida
	create_tween().tween_property(_body, "modulate:a", 1.0, 0.3)
	_agent.target_position = _target  # (o caminho continua daqui)


## O cabo arrebentou com ele na fila: procura outro caminho (a escada em espiral).
func cabine_cancelada() -> void:
	_na_cabine = null
	_a_bordo = false
	_body.modulate.a = 1.0
	_go_to(_alvo_final)


## Bloco 101: o migrante aceito vira morador: entra no grupo da vila, sem função, e pega uma cama (a IA leva ele pra dentro;
## de noite o portão abre pra ele como pra qualquer morador).
func vira_morador() -> void:
	if not visitante:
		return
	visitante = false
	remove_from_group("migrantes_gente")
	add_to_group("ipezinhos")
	auto_mode = true
	_manual_timer = 0.0
	set_job(ROLE_IDLE)
	_claim_home()
	_decision_timer = 0.0


func na_cabine() -> bool:
	return _na_cabine != null


# ------------------------------------------------------------ dentro da mina (Bloco 99)
## A boca da mina onde ele pode trabalhar DENTRO agora (mineiro da área de mina, com o trilho e o vagonete
## funcionando): o ponto de carga com interior que aceita. null = minera como sempre (na mão).
func _boca_da_mina() -> Node:
	if _mina_dentro != null and is_instance_valid(_mina_dentro) and _mina_dentro.aceita_dentro(self):
		return _mina_dentro
	for b in get_tree().get_nodes_in_group("bocas_mina"):
		if b.aceita_dentro(self):
			return b
	return null


func _entra_mina(b: Node) -> void:
	_mina_dentro = b
	b.entra(self)
	_moving = false
	_inside = true  # (criatura não pega quem está lá dentro)
	_agent.avoidance_enabled = false
	visible = false
	_popup("Pra dentro da mina!", Color(0.85, 0.8, 0.65))


func _sai_mina() -> void:
	if _mina_dentro == null:
		return
	var b := _mina_dentro
	_mina_dentro = null
	if is_instance_valid(b):
		b.sai(self)
		global_position = b.boca_pos()
	_inside = false
	visible = true
	_agent.avoidance_enabled = avoidance_enabled


func dentro_da_mina() -> bool:
	return _mina_dentro != null


## Multiplica a picareta: zanga/tristeza, explosivos (pesquisa) e a picareta de aço (Bloco 94). (mine() e a mina por dentro)
func mult_mineracao() -> float:
	var res := _research()
	var boom: float = res.mining_speed_mult() if res else 1.0
	var ofi := get_tree().get_first_node_in_group("oficina")
	if ofi and ofi.has_method("mult_mineracao"):
		boom *= ofi.mult_mineracao()
	return work_mult() * boom


## Lá dentro: minerou `taken` (o ponto de carga tirou da jazida). Acidente e achados sorteiam igual (por minério).
func minerou_dentro(taken: float, tipo: String) -> void:
	if taken <= 0.0:
		return
	cargo_type = tipo
	_work_timer = 0.2
	_roll_injury(taken)
	_area_registra(taken)


## Multiplicador de acidente pela profundidade (nível 2 = mais perigoso).
func depth_danger() -> float:
	var env := get_tree().get_first_node_in_group("environment")
	return env.danger_mult_at(global_position) if env else 1.0


## Existe alguma estação do grupo REALMENTE disponível agora? (Diferente de
## _find_best_station, não aceita a estação atual só por ser a atual: árvore que
## virou toco ou horta colhida não contam — aí o lenhador/cozinheiro vai descarregar.)
func _has_usable_station(group_name: String) -> bool:
	var env := get_tree().get_first_node_in_group("environment")
	for node in get_tree().get_nodes_in_group(group_name):
		if node.has_method("is_usable") and not node.is_usable():
			continue
		if env and env.has_method("trancado") and env.trancado((node as Node2D).global_position):
			continue  # Bloco 67
		if _andar_bloqueado((node as Node2D).global_position):
			continue  # Bloco 103: andar ainda não reconhecido
		if not _area_permite(node, group_name):
			continue  # Bloco 77: fora da área dele / dentro da área de outros
		if node.has_method("has_free_slot_for") and not node.has_free_slot_for(self):
			continue
		return true
	return false


## Estação com slot livre que compensa mais: perto e, de preferência, menos lotada.
func _find_best_station(group_name: String) -> Node2D:
	var best: Node2D = null
	var best_score := INF
	var env := get_tree().get_first_node_in_group("environment")
	for node in get_tree().get_nodes_in_group(group_name):
		if node.has_method("is_usable") and not node.is_usable() and node != _station:
			continue
		if env and env.has_method("trancado") and env.trancado((node as Node2D).global_position):
			continue  # Bloco 67: o leste ainda não foi desbravado
		if _andar_bloqueado((node as Node2D).global_position):
			continue  # Bloco 103: andar que ninguém reconheceu (a IA não manda ninguém sozinha)
		if not _area_permite(node, group_name):
			continue  # Bloco 77: fora da área dele / dentro da área de outros
		if node.has_method("has_free_slot_for") and not node.has_free_slot_for(self):
			continue
		if node.has_method("accepts_worker") and not node.accepts_worker(self) and node != _station:
			continue
		var score := _custo_estacao(node, group_name)
		if score < best_score:
			best_score = score
			best = node
	return best


## Bloco 109: o CUSTO de uma estação (menor = melhor), em "px de caminho": distância + fila - o quanto ela tem - o que
## FALTA no armazém + perigo (pesos no grupo "Escolha da estação"). O minério mais valioso continua "parecendo mais perto"
## (a distância dividida pelo valor, como antes do Bloco 109).
func _custo_estacao(node: Node, group_name: String) -> float:
	var pos: Vector2 = (node as Node2D).global_position
	var c := global_position.distance_to(pos) * peso_distancia
	if node.has_method("occupied_slot_count") and node != _station:
		c += node.occupied_slot_count() * peso_fila
	if node.has_method("get_value_weight"):
		c /= maxf(node.get_value_weight(), 0.1)
	if node.has_method("fracao_restante"):
		c -= clampf(node.fracao_restante(), 0.0, 1.0) * peso_quantidade
	c -= _falta_no_armazem(node, group_name) * peso_falta
	c += _perigo_em(node) * peso_perigo
	return c


## 0..1: o quanto a vila está SEM o que essa estação dá (1 = nada no armazém; 0 = falta_referencia ou mais).
func _falta_no_armazem(node: Node, group_name: String) -> float:
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null or falta_referencia <= 0.0:
		return 0.0
	var item := ""
	match group_name:
		"minerios":
			item = String(node.tipo_extraido()) if node.has_method("tipo_extraido") else String(node.get("ore_type"))
		"arvores":
			item = "madeira"
		"coleta_comida", "caca":
			item = "comida_crua"
	if item == "":
		return 0.0
	return 1.0 - clampf(float(eco.quantidade(item)) / falta_referencia, 0.0, 1.0)


## Pontos de perigo da estação: o andar mais fundo (o multiplicador de acidente - 1, até 1), a zona de perigo sem o traje
## e criatura viva por perto (Bloco 109).
func _perigo_em(node: Node) -> float:
	var pos: Vector2 = (node as Node2D).global_position
	var env := get_tree().get_first_node_in_group("environment")
	var p := 0.0
	if env and env.has_method("danger_mult_at"):
		p += clampf(float(env.danger_mult_at(pos)) - 1.0, 0.0, 1.0)
	var hz := String(node.get("hazard")) if node.get("hazard") != null else ""
	if hz != "" and not wearing.has(hz):
		p += 0.5
	if _criatura_perto(pos, perigo_criatura_raio) != null:
		p += 1.0
	return p


## Bloco 109: uma criatura viva a até `raio` de `pos`, no mesmo andar (null = nenhuma).
func _criatura_perto(pos: Vector2, raio: float) -> Node:
	var env := get_tree().get_first_node_in_group("environment")
	var andar: int = env.level_at(pos) if env and env.has_method("level_at") else 0
	for c in get_tree().get_nodes_in_group("criaturas"):
		if not c.has_method("is_alive") or not c.is_alive():
			continue
		if pos.distance_to(c.global_position) > raio:
			continue
		if env and env.has_method("level_at") and env.level_at(c.global_position) != andar:
			continue
		return c
	return null


## Bloco 110: o valente não foge de criatura.
func _valente() -> bool:
	if e_crianca():
		return false  # Bloco 111: criança foge sempre
	var rel := _relacoes()
	return rel != null and rel.tem(self, "valente")


## Bloco 109: viu criatura perto: foge (e continua fugindo por fuga_tempo, pra não ir e voltar).
func _foge() -> bool:
	if _criatura_perto(global_position, fuga_raio) != null:
		if _fuga_t <= 0.0:
			_popup("Bicho! Pra casa!", Color(1.0, 0.55, 0.4))
		_fuga_t = fuga_tempo
	return _fuga_t > 0.0


# ------------------------------------------------------------ função secundária (Bloco 109)
## A secundária que vale agora ("" = nenhuma): a escolhida pelo jogador ou, no automático, a padrão da função.
func secundaria() -> String:
	var sec := funcao_secundaria
	if sec == "":
		sec = String(secundaria_padrao.get(job, ""))
	if sec == "nenhuma" or sec == job or not sec in [ROLE_MINER, ROLE_LUMBER, ROLE_HUNTER, ROLE_FARMER]:
		return ""
	return sec


## Está fazendo a secundária agora?
func na_secundaria() -> bool:
	return _na_secundaria


static func nome_funcao(f: String) -> String:
	return {ROLE_MINER: "minerador", ROLE_LUMBER: "lenhador", ROLE_HUNTER: "caçador", ROLE_FARMER: "agricultor"}.get(f, f)


## Faz o trabalho dessa função agora (a principal ou a secundária em curso)?
func _faz(funcao: String) -> bool:
	return job == funcao or (_na_secundaria and secundaria() == funcao)


func _faz_coleta() -> bool:
	return is_gatherer() or (_na_secundaria and secundaria() in [ROLE_HUNTER, ROLE_FARMER])


## A principal não tem NADA pra fazer? ("idle" de verdade: não vale esperar espaço no armazém nem uma entrega; o fundidor e o
## carpinteiro só sem ordem em oficina nenhuma; o guarda de dia em casa.)
func _sem_trabalho(e: String) -> bool:
	if is_guard():
		return e == "home"
	if e != "idle":
		return false
	if is_smelter() or is_carpenter():  # nenhuma ordem em oficina nenhuma (nem a que espera insumo: o balão "sem material" fica)
		return not get_tree().get_nodes_in_group(_grupo_oficina()).any(func(f): return f.get("fila") != null and not (f.fila.fila as Array).is_empty())
	return true


## A secundária só entra no EXPEDIENTE, com a IA ligada, fora de uma área de trabalho (a área manda) e — no guarda — de
## dia e só se ele não vigiou a noite passada (quem vigiou descansa).
func _pode_secundaria() -> bool:
	if secundaria_desligada or has_no_job() or work_area != null or not auto_mode or secundaria() == "" or is_cook() or is_carrier():
		return false
	var sch := _schedule()
	if sch and sch.periodo(self) != "trabalho":
		return false
	if is_guard():
		if _is_night():
			return false
		if sch and sch.has_method("vigiou_ontem") and sch.vigiou_ontem(self):
			return false
	return true


## O estado da secundária ("" = ela também não tem o que fazer agora).
func _estado_secundario() -> String:
	match secundaria():
		ROLE_LUMBER:
			if _sem_espaco("madeira"):
				return ""
			if (_ai_state == "chopping" and _station_ok_for("chopping")) or _has_usable_station("arvores"):
				return "chopping"
		ROLE_MINER:
			if _sem_espaco("minerios"):
				return ""
			if carrying >= capacidade_carga() - 0.01 or (_ai_state == "storing" and carrying > 0.0):
				return "storing"
			if (_ai_state == "mining" and _station_ok_for("mining")) or _find_best_station("minerios") != null:
				return "mining"
			if carrying > 0.0:
				return "storing"
		ROLE_HUNTER:
			if _sem_espaco("alimentos"):
				return ""
			if (_ai_state == "hunting" and _station_ok_for("hunting")) or _has_usable_station("caca"):
				return "hunting"
			if not _agricultor_na_vila() and ((_ai_state == "foraging" and _station_ok_for("foraging")) or _has_usable_station("coleta_comida")):
				return "foraging"
		ROLE_FARMER:
			if _sem_espaco("alimentos"):
				return ""
			if (_ai_state == "foraging" and _station_ok_for("foraging")) or _has_usable_station("coleta_comida"):
				return "foraging"
	return ""


## O jogador escolhe ("" automática, "nenhuma" ou uma função).
func set_secundaria(f: String) -> void:
	if not f in SECUNDARIAS:
		return
	funcao_secundaria = f
	if _na_secundaria and secundaria() == "":
		_na_secundaria = false
		_apply_outfit()
	if auto_mode and _ai_state != "manual":
		_decision_timer = randf_range(0.05, 0.4)


# ------------------------------------------------------------ abrigo da onda solar (Bloco 109)
## A casa pronta ou taverna mais perto (de qualquer um: na onda solar todo mundo entra onde der).
func _abrigo_mais_perto() -> Node2D:
	var best: Node2D = null
	var bd := INF
	for grupo in ["casas", "tavernas"]:
		for a in get_tree().get_nodes_in_group(grupo):
			if not a.has_method("set_inside") or (a.get("built") != null and not a.built):
				continue
			var d := global_position.distance_to((a as Node2D).global_position)
			if d < bd:
				bd = d
				best = a
	return best


## Onda solar: a própria cama (se não estiver bem mais longe que o abrigo mais perto) ou o abrigo mais perto.
func _destino_onda() -> String:
	var abr := _abrigo_mais_perto()
	if abr == null:
		return "home"
	if has_home() and global_position.distance_to(_rest_position()) <= global_position.distance_to(abr.global_position) + abrigo_folga:
		return "home"
	return "abrigo"


func _vai_pro_abrigo() -> void:
	if _abrigado_em != null and is_instance_valid(_abrigado_em):
		return
	var abr := _abrigo_mais_perto()
	if abr == null:
		_go_home()
		return
	var porta: Vector2 = abr.get_wait_position(self) if abr.has_method("get_wait_position") else abr.global_position
	if global_position.distance_to(porta) <= REST_REACH + 8.0:
		_moving = false
		_abrigado_em = abr
		_inside = true
		abr.set_inside(self, true)
		_agent.avoidance_enabled = false
		queue_redraw()
	elif not _moving or _target.distance_to(porta) > 1.0:
		_go_to(porta)


func _sai_do_abrigo() -> void:
	if _abrigado_em != null and is_instance_valid(_abrigado_em):
		_abrigado_em.set_inside(self, false)
	_abrigado_em = null
	if not _resting:
		_inside = false
	_agent.avoidance_enabled = avoidance_enabled
	queue_redraw()


# ------------------------------------------------------------ carona (Bloco 109)
## Sem carregador na vila: acabou de descarregar no armazém, de mãos vazias? Leva o material de uma obra perto (a mesma
## entrega do carregador: a obra conta como "a caminho"). true = pegou a carona.
func _quer_carona() -> bool:
	if _carona_cd > 0.0 or is_carrier() or is_engineer() or has_no_job() or not _carga.is_empty():
		return false
	if not _ai_state in ["storing", "hauling", "stocking"]:
		return false
	if carrying > 0.0 or wood_carrying > 0.0 or raw_carrying > 0.0 or not material_mao.is_empty():
		return false
	var lg := _logistica()
	var eco := get_tree().get_first_node_in_group("economy")
	if lg == null or eco == null or not lg.has_method("reserva_carona") or lg.tem_carregador():
		return false
	var arm := _closest_in_group("armazens")
	if arm == null or global_position.distance_to(arm.global_position) > 90.0:
		return false
	_carona_cd = carona_intervalo
	var t: Dictionary = lg.reserva_carona(self, carona_raio)
	if t.is_empty():
		return false
	_carga = t.duplicate()
	_carga["fase"] = "ao_armazem"
	if not _prepara_obra(t.alvo, eco):
		lg.solta(self)
		_carga = {}
		return false
	_carona = true
	caronas += 1
	_popup("Levo material pra obra", Color(1.0, 0.85, 0.45))
	return true


## Bloco 103: o andar desse ponto ainda não foi reconhecido (e o jogador não mandou descer mesmo assim)?
func _andar_bloqueado(pos: Vector2) -> bool:
	var cat := _catalogo()
	return cat != null and cat.has_method("andar_bloqueado") and cat.andar_bloqueado(pos, self)


## Bloco 47: pode ter mais de uma enfermaria. O médico vai pra que precisa dele (gente
## deitada ou esperando lá e nenhum outro médico); senão pra mais perto e menos coberta.
## Com uma enfermaria só é sempre ela (como antes).
func _doctor_ward() -> Node2D:
	var best: Node2D = null
	var best_score := INF
	for ward in get_tree().get_nodes_in_group("enfermarias"):
		var others := 0
		for d in ward.doctors():
			if d != self:
				others += 1
		var need: int = ward.patients().size() + ward.waiting().size()
		var score: float = global_position.distance_to(ward.global_position) + 400.0 * others
		if need > 0 and others == 0:
			score -= 5000.0
		if score < best_score:
			best_score = score
			best = ward
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
	if new_state == "buscando_insumo":  # Bloco 86: uma visita nova ao armazém
		_visita_feita = false
	if new_state == "eating":  # Bloco 84: indo comer — um prato novo, da refeição da hora (se for)
		_servido = false
		_prato = 0.0
		_refeicao_alvo = _refeicao_da_hora()
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
		material_pedido.clear()  # Bloco 96: ia buscar e foi fazer outra coisa (o que já pegou continua na mão)
		_material_armazem = null
	if _ai_state == "strike":
		_strike_spot = null
	if _ai_state == "robot":
		_drop_robot()
	if _ai_state == "guard":
		_foe = null
	if _ai_state == "rescue":
		_drop_patient()
	if _ai_state == "social":
		_social_sai()  # Bloco 85: solta o lugar no ponto
	if _ai_state == "na_mina":
		_sai_mina()  # Bloco 99: refeição, fim do expediente, emergência ou o vagonete parou: sai pela boca
	if _ai_state == "manutencao":
		var mt := _manutencao()  # Bloco 105: largou a preventiva (o tempo feito se perde: recomeça)
		if mt:
			mt.solta(self)
		_manut_alvo = null
		_manut_t = 0.0
	if _ai_state == "catalogando":
		_campo = {}  # Bloco 102: largou o campo (a anotação feita continua com ela: entrega depois)
		var cat := _catalogo()
		if cat:
			cat.solta(self)
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
	if has_home() and _home.has_method("comfort_bonus") and _home.comfort_bonus() > 0.0:
		f.append(["casa nível %d" % _home.level, _home.comfort_bonus()])  # Bloco 56
	if has_home() and _home.has_method("cama_boa") and _home.cama_boa(_home_slot):
		f.append(["cama de tábua", _home.conforto_cama_boa])  # Bloco 94
	if has_home():
		var dec := get_tree().get_first_node_in_group("decoracoes_mgr")
		var bel: float = dec.beleza_da_casa(_home) if dec else 0.0
		if bel >= 0.5:
			f.append(["casa enfeitada", bel])  # Bloco 90: decoração perto de casa
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
	var nx: Resource = env.nivel_extra_em(global_position) if env and env.has_method("nivel_extra_em") else null
	if nx and nx.animo != 0.0:  # Bloco 71: o nível novo pesa ou acalma (o lago azul)
		f.append([nx.animo_motivo if nx.animo_motivo != "" else nx.nome, nx.animo])
	if animo_social >= 0.5:
		f.append(["conversou com os amigos", animo_social])  # Bloco 85
	if animo_descoberta >= 0.5:
		f.append(["fez uma descoberta", animo_descoberta])  # Bloco 103
	var rel_a := _relacoes()
	if rel_a:
		f.append_array(rel_a.fatores_animo(self))  # Bloco 110: amigos, parceiro, luto pessoal, traços
	if animo_casamento >= 0.5:
		f.append(["casou", animo_casamento])  # Bloco 110
	if animo_escola >= 0.5:
		f.append(["foi à escola" if estudo > 0.0 else "brincou", animo_escola])  # Bloco 111
	var fam_a := _familias()
	if fam_a:
		f.append_array(fam_a.fatores_animo(self))  # Bloco 111: vai ter um filho
	if animo_prato >= 0.5:
		f.append(["comeu um ensopado", animo_prato])  # Bloco 107
	if animo_fe >= 0.5:
		f.append(["foi à missa", animo_fe])  # Bloco 88
	var m := _morale()
	if m:
		f.append_array(m.village_factors())
	var pol := get_tree().get_first_node_in_group("politicas")
	if pol:
		f.append_array(pol.fatores_animo(self))  # Bloco 108: o ponto único do ânimo das políticas
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


# ------------------------------------------------------------ casal (Bloco 110)
## Muda pra casa do parceiro: larga a cama de agora e pega a livre mais perto da dele. true = mudou.
func muda_pra_casa(casa: Node, slot_parceiro: int) -> bool:
	if casa == null or not is_instance_valid(casa) or not casa.has_method("claim_specific_bed"):
		return false
	var perto := -1
	var bd := INF
	var alvo: Vector2 = casa.get_slot_position(slot_parceiro) if slot_parceiro >= 0 else (casa as Node2D).global_position
	for i in casa.slot_count:
		if casa.has_method("_slot_taken") and casa._slot_taken(i):
			continue  # (cama de outro)
		var d: float = casa.get_slot_position(i).distance_to(alvo)
		if d < bd:
			bd = d
			perto = i
	if perto < 0:
		return false
	var antiga := _home
	var antigo_slot := _home_slot
	if antiga != null and is_instance_valid(antiga):
		antiga.set_inside(self, false)
		antiga.release_slot(self)
	var bed: int = casa.claim_specific_bed(self, perto)
	if bed < 0:
		if antiga != null and is_instance_valid(antiga):
			_home_slot = antiga.claim_specific_bed(self, antigo_slot)
		return false
	_home = casa
	_home_slot = bed
	return true


# ------------------------------------------------------------ guarda / combate
func guard_max_hp() -> float:
	return guard_base_hp + guard_hp_per_skill * combat_skill


func _defense() -> Node:
	return get_tree().get_first_node_in_group("defense")


## Campo de treino chama enquanto ele treina.
func train(amount: float) -> void:
	var teto := teto_treino()  # Bloco 108: o treinamento (política) sobe o teto acima de 100%
	if combat_skill >= teto:
		return
	var antes := combat_skill
	combat_skill = minf(combat_skill + amount, teto)
	_work_timer = 0.2  # balança a lança no boneco
	if antes < 1.0 and combat_skill >= 1.0:
		_popup("Pronto pra lutar!", Color(0.55, 1.0, 0.5))
	if combat_skill >= teto:
		if teto > 1.0:
			_popup("Veterano!", Color(0.55, 1.0, 0.5))
		_decision_timer = randf_range(0.05, 0.4)


## Bloco 108: até onde a habilidade de combate sobe agora (1,0 = 100%; o treinamento das políticas sobe).
func teto_treino() -> float:
	var pol := get_tree().get_first_node_in_group("politicas") if is_inside_tree() else null
	return float(pol.teto_treino()) if pol else 1.0


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
	_golpeia(def)


## Bloco 103: chega no _foe e bate (o mesmo do posto, separado pra patrulha usar).
func _golpeia(def: Node) -> void:
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


## Bloco 103: a PATRULHA do fundo — desce pro andar (o caminho de sempre: elevador ou espiral), procura o morador
## vivo mais perto e luta como no posto. Sem morador: o _choose_state tira ele daqui.
func _patrulha_tick(delta: float) -> void:
	_attack_cd -= delta
	if combat_hp < 0.0:
		combat_hp = guard_max_hp()
	var def := _defense()
	if def == null:
		return
	var andar: String = def.patrulha_para(self)
	if andar == "":
		_decision_timer = 0.0
		return
	if _foe == null or not is_instance_valid(_foe) or not _foe.is_alive():
		_foe = def.alvo_patrulha(self, andar)
	if _foe == null:
		var p: Vector2 = def.ponto_patrulha(andar)
		if global_position.distance_to(p) > 20.0 and (not _moving or _target.distance_to(p) > 4.0):
			_go_to(p)
		return
	_golpeia(def)


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
			"Caiu no %s e não levanta sozinho. Só um MÉDICO pode levar pra enfermaria%s.%s" % [
				def.gate_label(downed_gate) if def else "portão", "" if has_doc else " — NÃO HÁ MÉDICO (tecla 3)",
				" Enquanto isso o portão fica aberto pra roubo." if downed_gate != "" else ""])
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
	if not material_mao.is_empty() and _material_obra != null and is_instance_valid(_material_obra) and _material_obra.obra_pending():
		return _material_obra  # Bloco 96: primeiro entrega o que tem na mão
	if _obra != null and is_instance_valid(_obra) and _obra.obra_pending() and _obra_e_minha(_obra):
		return _obra
	var oldest_free: Node = null
	var oldest_any: Node = null
	# Bloco 105: sem mecânico, o engenheiro conserta a máquina quebrada — mas só quando não tem obra de construção
	var construcao := is_engineer() and get_tree().get_nodes_in_group("obras").any(func(o): return o.has_method("obra_pending") and o.obra_pending() and _oficio_de(o) == "")
	for site in get_tree().get_nodes_in_group("obras"):
		if not site.has_method("obra_pending") or not site.obra_pending():
			continue
		if not _obra_e_minha(site):
			continue  # Bloco 87: Oficina e Arsenal são do ferreiro; Bloco 105: os consertos de máquina, do mecânico
		if construcao and _oficio_de(site) == "mecanico":
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


## Bloco 105: o ofício de uma obra ("" = construção do engenheiro; "ferreiro"; "mecanico" = conserto de máquina).
func _oficio_de(site: Node) -> String:
	if site.has_method("oficio_obra"):
		return String(site.oficio_obra())
	var o = site.get("oficio")
	return String(o) if o != null else ""


## Bloco 105: essa obra é pra mim? O ferreiro: a forja. O mecânico: os consertos. O engenheiro: a construção — e os
## consertos de máquina quando a vila não tem mecânico.
func _obra_e_minha(site: Node) -> bool:
	var of := _oficio_de(site)
	if is_smith():
		return of == ROLE_SMITH
	if is_mechanic():
		return of == "mecanico"
	if of == "mecanico":
		var mt := _manutencao()
		return mt == null or not mt.tem_mecanico()
	return of != ROLE_SMITH


## Prompt 18: acidente na mina — pedrinhas caindo do teto em cima dele (só visual; a vista iso
## troca o quadradinho pela pedra de pixel, iso_fx.gd papel "pedra").
func _rockfall() -> void:
	var p := CPUParticles2D.new()
	p.name = "Rocks"
	p.one_shot = true
	p.explosiveness = 0.6
	p.amount = 9
	p.lifetime = 0.8
	p.position = Vector2(0, -70)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(14, 4)
	p.direction = Vector2(0, 1)
	p.spread = 10.0
	p.gravity = Vector2(0, 260)
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 30.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.0
	p.color = Color(0.55, 0.5, 0.45)
	p.z_index = 6
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(0, -70)
	p.emitting = true
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)


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


## Onde ir pra tocar a obra: o ponto dela ou o ponto de acesso que o vigia achou (Bloco 51).
func _obra_goal() -> Vector2:
	if _obra_alt != Vector2.INF and _obra_alt_of == _obra:
		return _obra_alt
	return _obra.obra_position(self)


## Bloco 51: o engenheiro que fica "a caminho" sem se aproximar (depois de carregar o save, a malha
## de navegação é refeita e o ponto da obra ou ele mesmo pode ficar sem caminho; o anti-travamento
## desistia de andar e a IA mandava andar pro MESMO ponto de novo, pra sempre).
func _obra_watchdog_tick(delta: float, dist: float) -> void:
	if dist < _obra_watch_best - 16.0:
		_obra_watch_best = dist
		_obra_watch_t = 0.0
		return
	_obra_watch_t += delta
	if _obra_watch_t < obra_watchdog_time:
		return
	_obra_watch_t = 0.0
	_obra_watch_best = INF
	var map := _agent.get_navigation_map()
	var alvo: Vector2 = _obra.obra_position(self)
	var centro: Vector2 = (_obra as Node2D).global_position if _obra is Node2D else alvo
	# 1) um ponto de acesso em volta da obra que o caminho alcança de verdade
	var melhor := Vector2.INF
	var melhor_d := INF
	for r in [40.0, 60.0, 85.0]:
		for k in 12:
			var p: Vector2 = centro + Vector2.RIGHT.rotated(TAU * k / 12.0) * r
			var cp := NavigationServer2D.map_get_closest_point(map, p)
			if cp.distance_to(p) > 10.0:
				continue  # fora do chão andável
			var path := NavigationServer2D.map_get_path(map, global_position, cp, true)
			if path.is_empty() or path[path.size() - 1].distance_to(cp) > 8.0:
				continue  # não chega lá
			var dd := cp.distance_to(alvo)
			if dd < melhor_d:
				melhor_d = dd
				melhor = cp
		if melhor != Vector2.INF:
			break
	if melhor != Vector2.INF:
		_obra_alt = melhor
		_obra_alt_of = _obra
		print("[vigia] %s sem avançar há %.0f s a caminho de %s: novo ponto de acesso %s (o normal era %s)" % [
			_display(), obra_watchdog_time, _obra.obra_title(), melhor.round(), alvo.round()])
		_go_to(melhor)
		return
	# 2) nenhum caminho: vai pro chão andável mais perto da obra (último recurso)
	var perto := NavigationServer2D.map_get_closest_point(map, alvo)
	print("[vigia] %s preso sem caminho até %s: puxado pro chão andável mais perto (%s)" % [_display(), _obra.obra_title(), perto.round()])
	global_position = perto
	_moving = false
	_decision_timer = 0.0


## Sai da obra (pausa): o que já foi feito fica guardado nela.
func _obra_stop() -> void:
	if _obra != null and is_instance_valid(_obra) and _obra_on_site:
		_obra.obra_leave(self)
	_obra_alt = Vector2.INF
	_obra_alt_of = null
	_obra_watch_best = INF
	_obra_watch_t = 0.0
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
	Audio.voz(global_position, "cansaco", gender)  # Bloco 114: suspiro de quem vai dormir (desligável)
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
## Chamado pela Oficina: a picareta temperada (id picareta_aco) troca o visual da ferramenta.
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
	if e_crianca():
		return "crianca"  # Bloco 111: a arte das crianças (oficios111.py; o aprendiz também)
	return JOB_OUTFIT.get(secundaria() if _na_secundaria else job, "mineiro")  # Bloco 109: na secundária, a roupa dela


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


# ------------------------------------------------------------ o naturalista (Bloco 102)
func _catalogo() -> Node:
	return get_tree().get_first_node_in_group("catalogo") if is_inside_tree() else null


## Bloco 103: quanto mais descobertas, mais rápido ela estuda (+xp_pesquisa_bonus cada, até xp_pesquisa_max).
func ritmo_estudo() -> float:
	return 1.0 + minf(float(xp_pesquisa) * xp_pesquisa_bonus, xp_pesquisa_max)


## Bloco 103: fez uma descoberta (o catálogo chama): realizada — ânimo, experiência e o balão de comemoração com o
## ícone do que ela descobriu.
func descobriu(id: String) -> void:
	xp_pesquisa += 1
	animo_descoberta = animo_descoberta_ganho
	var Cat := preload("res://scripts/core/catalogo.gd")
	_popup("Descobri! %s" % Cat.nome(id), Color(0.75, 0.95, 1.0))
	var ic: Texture2D = Cat.icone(id)
	_mostra_balao("pesquisador")  # o balão de sempre...
	if ic and _balao:
		var s := _balao.get_node("Icone") as Sprite2D  # ...com o ícone do que ela descobriu
		s.texture = ic
		s.scale = Vector2.ONE * (11.0 / maxf(float(maxi(ic.get_width(), ic.get_height())), 1.0))
		_balao.visible = true
	_balao_vida = 3.0


## Decide o passo da tarefa de campo: pega o alvo (reservado no catálogo) ou vai entregar a anotação.
func _catalogar() -> void:
	var cat := _catalogo()
	if cat == null:
		return
	if nota_campo != "" and String(_campo.get("fase", "")) != "voltando":
		_campo = {"id": nota_campo, "pos": cat.entrega_pos(self), "fase": "voltando", "t": 0.0, "lab": false}
	if _campo.is_empty():
		var a: Dictionary = cat.reserva(self)
		if a.is_empty():
			_decision_timer = 0.0  # (nada pra estudar: decide de novo)
			return
		_campo = {"id": a.id, "pos": a.pos, "fase": "indo", "t": 0.0, "lab": a.lab}
		if a.has("corpo"):
			_campo["corpo"] = a.corpo  # Bloco 103: estuda no corpo (colhe o que ele deixou)
	if String(_campo.fase) in ["indo", "voltando"]:
		var p: Vector2 = _campo.pos
		if global_position.distance_to(p) > cat.alcance_estudo and (not _moving or _target.distance_to(p) > 2.0):
			_go_to(p)


## Cada quadro: chegou -> anota (com a animação de pesquisar) -> volta -> entrega.
func _campo_tick(delta: float) -> void:
	var cat := _catalogo()
	if cat == null or _campo.is_empty():
		return
	var p: Vector2 = _campo.pos
	var perto: bool = global_position.distance_to(p) <= cat.alcance_estudo or (not _moving and global_position.distance_to(p) <= cat.alcance_estudo * 2.0)
	match String(_campo.fase):
		"indo":
			if not cat.alvo_valido(_campo):
				_campo = {}  # outra estudou (ou o laboratório), ou o corpo sumiu: escolhe outro
				_decision_timer = 0.0
			elif perto:
				_moving = false
				_campo.fase = "anotando"
				_campo.t = 0.0
				_popup("Hmm, o que é isso?", Color(0.75, 0.9, 1.0))
		"anotando":
			if not cat.alvo_valido(_campo):
				_campo = {}
				_decision_timer = 0.0
				return
			_campo.t = float(_campo.t) + delta * work_mult() * ritmo_estudo()
			_work_timer = 0.2  # a animação de pesquisar (anotando)
			if float(_campo.t) >= cat.segundos_estudo:
				cat.fim_da_anotacao(_campo, self)  # Bloco 103: colhe o corpo / o risco do reconhecimento
				nota_campo = String(_campo.id)
				_campo = {"id": nota_campo, "pos": cat.entrega_pos(self), "fase": "voltando", "t": 0.0, "lab": false}
				if global_position.distance_to(_campo.pos) > cat.alcance_estudo:
					_go_to(_campo.pos)
		"voltando":
			if perto:
				var id := nota_campo
				nota_campo = ""
				_campo = {}
				cat.entrega(id, self)
				_decision_timer = 0.0


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
	if e_crianca() and new_job != ROLE_IDLE:
		_popup("Criança não trabalha", Color(1.0, 0.8, 0.5))  # Bloco 111
		return
	if new_job == ROLE_PRIEST and motivo_padre() != "":
		return  # Bloco 92: só homem vira padre, e a vila tem um só (main.gd avisa o motivo)
	if new_job != ROLE_PRIEST and not carregando_corpo.is_empty():
		_larga_corpo()  # Bloco 93: deixou de ser padre com um corpo nos ombros
	if not new_job in JOBS:
		push_warning("Ipezinho: função desconhecida '%s'" % new_job)
		return
	if job == new_job:
		return
	if work_area != null and new_job != work_area.job():
		var wa := _work_areas()
		if wa:
			wa.sair(self)  # Bloco 77: trocou de função à mão: deixa o posto da área
		else:
			work_area = null
	if job == ROLE_DOCTOR:
		_end_duty()  # tirou do médico: o bônus da enfermaria para NA HORA (Bloco 30)
	if job == ROLE_ENGINEER:
		_obra_stop()  # tirou do engenheiro: a obra pausa NA HORA, sem perder o feito (Bloco 31)
		solta_material(true)  # Bloco 96: o material da mão volta pro armazém
	if job == ROLE_DOCTOR:
		_drop_patient()  # Bloco 36: tirou do médico no meio do resgate: larga o caído ali
	if job == ROLE_CARRIER and not _carga.is_empty():
		_desfaz_carga(true)  # Bloco 105: deixou de ser carregador no meio da entrega
	if job == ROLE_MECHANIC:
		var mt0 := _manutencao()
		if mt0:
			mt0.solta(self)
		_manut_alvo = null
	if job == ROLE_RESEARCH and nota_campo != "":
		var cat := _catalogo()  # Bloco 102: deixou de ser pesquisadora com a anotação na mão: ela entrega na hora
		if cat:
			cat.entrega(nota_campo, self)
		nota_campo = ""
	if job == ROLE_LUMBER and _my_coletor() != null:
		_my_coletor().release()  # Bloco 45: deixou de ser lenhador: o coletor para
	if job == ROLE_MINER and _my_coletor_minerio() != null:
		_my_coletor_minerio().release()  # Bloco 57: deixou de ser minerador: a broca para
	job = new_job
	_na_secundaria = false  # Bloco 109: a secundária recomeça pela função nova
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


# ------------------------------------------------------------ áreas de trabalho (Bloco 77)
func _work_areas() -> Node:
	return get_tree().get_first_node_in_group("work_areas") if is_inside_tree() else null


## work_areas.gd chama (a lista da área é dela; aqui só o vínculo e a troca de tarefa já).
func entrar_area(a) -> void:
	work_area = a
	_release_station()  # a estação de antes pode estar fora da área
	if auto_mode and _ai_state != "manual":
		_decision_timer = randf_range(0.05, 0.4)


func sair_area() -> void:
	work_area = null
	if auto_mode and _ai_state != "manual":
		_decision_timer = randf_range(0.05, 0.4)


## A estação (do grupo) pode ser usada por ele? (a área dele / área de outros / mina desligada)
func _area_permite(node: Node, group_name: String) -> bool:
	var wa := _work_areas()
	return wa == null or wa.areas.is_empty() or wa.pode_usar(self, (node as Node2D).global_position, group_name)


func _area_registra(qtd: float) -> void:
	if work_area != null and qtd > 0.0:
		work_area.registra(qtd)


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
	if not _faz_coleta() or injured or _ai_state != state:
		return 0.0
	var taken := minf(amount * work_mult(), hunter_carry - _raw_units)  # zangado rende menos
	if taken <= 0.0:
		return 0.0
	_raw_units += taken
	raw_carrying += taken * value
	_area_registra(taken * value)  # Bloco 77
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


# ------------------------------------------------------------ coletor de madeira (Bloco 45)
## O coletor em que ele é o operador (ou null).
func _my_coletor() -> Node:
	if not is_inside_tree():
		return null
	for c in get_tree().get_nodes_in_group("coletores"):
		if c.get("operator") == self:
			return c
	return null


## Coletor chama a cada quadro com ele no posto: mexendo nas alavancas (anima o machado).
func operate_tick() -> void:
	_work_timer = 0.2


## Save carregado com ele operando: volta pro posto. Bloco 47: pode ter vários coletores —
## volta pro que estava (o mais perto de onde a máquina dele estava; save antigo: o primeiro).
func _relink_coletor(at: Vector2 = Vector2.INF) -> void:
	if not is_inside_tree() or not is_lumber():
		return
	var c: Node2D = null
	for k in get_tree().get_nodes_in_group("coletores"):
		if k.get("operator") != null and k.operator != self:
			continue  # já tem outro operador
		if k.has_method("restaurado") and not k.restaurado():
			continue  # Bloco 81: ruína não tem operador
		if c == null or (at != Vector2.INF and k.global_position.distance_to(at) < c.global_position.distance_to(at)):
			c = k
	if c:
		c.designate(self)


# ------------------------------------------------------------ coletor de minério (Bloco 57)
func _my_coletor_minerio() -> Node:
	if not is_inside_tree():
		return null
	for c in get_tree().get_nodes_in_group("coletores_minerio"):
		if c.get("operator") == self:
			return c
	return null


## Save carregado com ele operando a broca: volta pra ela (a mais perto de onde estava).
func _relink_coletor_minerio(at: Vector2 = Vector2.INF) -> void:
	if not is_inside_tree() or not is_miner():
		return
	var c: Node2D = null
	for k in get_tree().get_nodes_in_group("coletores_minerio"):
		if k.get("operator") != null and k.operator != self:
			continue
		if c == null or (at != Vector2.INF and k.global_position.distance_to(at) < c.global_position.distance_to(at)):
			c = k
	if c:
		c.designate(self)


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
		_prep_left = raw_carrying * prep_time_per_raw * maxf(prep_mult, 0.1)  # começa uma leva (Bloco 107: o prato / a ração)
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
	if is_farmer():
		return _has_usable_station("coleta_comida")  # Bloco 107
	return _has_usable_station("caca") or (_has_usable_station("coleta_comida") and not _agricultor_na_vila())


func _has_bow() -> bool:
	var oficina := get_tree().get_first_node_in_group("oficina")
	return oficina != null and oficina.has_tool("arco")


## Árvore chama: o lenhador põe madeira nas costas. Retorna quanto pegou.
func chop(amount: float) -> float:
	if not _faz(ROLE_LUMBER) or injured or _ai_state != "chopping":
		return 0.0
	var taken := minf(amount * work_mult(), lumber_carry - wood_carrying)  # zangado corta menos
	if taken <= 0.0:
		return 0.0
	wood_carrying += taken
	_work_timer = 0.2
	if wood_carrying >= lumber_carry - 0.01:
		_decision_timer = 0.0  # carga cheia: vai pro armazém já
	_roll_branch(taken)
	_area_registra(taken)  # Bloco 77
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
		chance *= Modificadores.mult(get_tree(), "acidente", self)  # Bloco 108: a jornada e a fraqueza
		var rel_g := _relacoes()
		if rel_g:
			chance *= rel_g.mult_acidente(self)  # Bloco 110: o cuidadoso
		if randf() < chance:
			acidentes_trabalho += 1
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
	return [1.0, irritated_work_mult, furious_work_mult][_mood] * _happiness_work_mult() * _cold_mult() * _mult_refeicoes() \
		* (Modificadores.mult(get_tree(), "producao", self) if is_inside_tree() else 1.0) \
		* _mult_pessoal()  # Bloco 108: a jornada e a fraqueza; Bloco 110: os traços e a habilidade


## Bloco 111: o parto contando, o aprendiz aprendendo, o resguardo e o ânimo da escola sumindo.
func _familia_tick(delta: float) -> void:
	if animo_escola > 0.0:
		animo_escola = maxf(animo_escola - 0.005 * delta, 0.0)
	if resguardo_s > 0.0:
		resguardo_s = maxf(resguardo_s - delta, 0.0)
	var fam := _familias()
	if fam == null:
		return
	if _ai_state == "parto" and not _moving and global_position.distance_to(_destino_parto()) <= 40.0:
		_parto_t += delta
		var precisa: float = fam.parto_segundos * (fam.parto_medico_mult if _medico_no_parto() else 1.0)
		if _parto_t >= precisa:
			_parto_t = 0.0
			fam.parto(self, _medico_no_parto())
			_decision_timer = 0.0
	if _ai_state == "aprendendo":
		var m: Node = fam.mentor_de(self)
		if m != null and global_position.distance_to((m as Node2D).global_position) <= fam.aprendiz_perto * 1.6:
			fam.aprende(self, m, delta)


## Bloco 110: trabalhando (o golpe/a martelada de agora), a habilidade da função sobe; o casamento some devagar.
func _pratica(rel: Node, delta: float) -> void:
	if animo_casamento > 0.0:
		animo_casamento = maxf(animo_casamento - rel.casamento_noivos / maxf(rel.casamento_tempo, 1.0) * delta, 0.0)
	if _work_timer <= 0.0 or is_guard() or has_no_job() or not _ai_state in rel.ESTADOS_TRABALHO:
		return
	var f := funcao_atual()
	habilidade[f] = minf(float(habilidade.get(f, 0.0)) + rel.habilidade_ganho * delta, 1.0)


## Bloco 110: traços (preguiçoso/trabalhador) e a habilidade na função que ele está fazendo agora.
func _mult_pessoal() -> float:
	var rel := _relacoes()
	var fam := _familias()
	var leve: float = fam.trabalho_leve_mult if fam and fam.trabalho_leve(self) else 1.0  # Bloco 111: fim da gravidez
	if rel == null:
		return leve
	return leve * rel.mult_producao(self) * (1.0 + rel.habilidade_bonus * float(habilidade.get(funcao_atual(), 0.0)))


func _relacoes() -> Node:
	return get_tree().get_first_node_in_group("relacoes") if is_inside_tree() else null


## Bloco 110: a função que ele está fazendo agora (a secundária em curso ou a principal).
func funcao_atual() -> String:
	return secundaria() if _na_secundaria else job


# ------------------------------------------------------------ família (Bloco 111)
func e_crianca() -> bool:
	return fase != "adulto"


func e_bebe() -> bool:
	return fase == "bebe"


func gravida() -> bool:
	return gravidez_s >= 0.0


func _familias() -> Node:
	return get_tree().get_first_node_in_group("familias") if is_inside_tree() else null


## O bebê puxa o tom de pele de um dos pais (o `look` escolhe o tom: iso_bonecos._tone).
func herda_tom(p: Node) -> void:
	if p != null and p.get("look") != null and int(p.look) >= 0:
		look = int(p.look)
		_apply_outfit()


## familias.gd chama quando ele cresce.
func muda_fase(nova: String) -> void:
	var antes := fase
	fase = nova
	if antes == "bebe" and nova != "bebe" and _resting:
		_stop_resting()  # o bebê vira criança: sai da cama e anda
	if nova == "adulto":
		_set_state("idle")
	_apply_outfit()
	_popup({"crianca": "Já anda!", "aprendiz": "Aprendiz!", "adulto": "Adulto!"}.get(nova, ""), Color(0.8, 0.95, 0.7))
	_decision_timer = 0.0


## A criança no horário de trabalho dos adultos: o aprendiz acompanha o mentor; a criança vai à escola (se tem vaga) ou
## brinca na praça/parque.
func _estado_crianca() -> String:
	var fam := _familias()
	if fase == "aprendiz" and fam:
		var m: Node = fam.mentor_de(self)
		if m != null and is_instance_valid(m) and m.is_inside_tree() and not m.get("fora"):
			return "aprendendo"
	if fase == "crianca" and ((_ai_state == "escola" and _station_ok_for("escola")) or _has_usable_station("escolas")):
		return "escola"
	return "brincando"


## Brinca: vai pra perto de uma praça/parque e pula por ali (a animação "brincar"); troca de lugar de tempos em tempos.
func _brinca() -> void:
	if _moving:
		return
	_brinca_t -= decision_interval
	_work_timer = 0.6  # (a animação de brincar)
	animo_escola = maxf(animo_escola, 2.0)
	if _brinca_t > 0.0:
		return
	_brinca_t = randf_range(6.0, 14.0)
	var alvo: Vector2 = global_position
	var spots: Array = get_tree().get_nodes_in_group("social_spots").filter(func(sp): return not sp.coberto or sp.get("tipo") == "praca")
	var parques: Array = get_tree().get_nodes_in_group("parques")
	var lugares: Array = []
	for sp in spots:
		lugares.append(sp.centro())
	for pq in parques:
		lugares.append((pq as Node2D).global_position)
	if not lugares.is_empty():
		var perto: Vector2 = lugares[0]
		for l in lugares:
			if global_position.distance_to(l) < global_position.distance_to(perto):
				perto = l
		alvo = perto + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(10.0, 40.0)
	else:
		alvo = global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(10.0, idle_wander_radius)
	_go_to(alvo)


## O aprendiz: fica perto do mentor (a família faz ele aprender no _process).
func _acompanha() -> void:
	var fam := _familias()
	var m: Node = fam.mentor_de(self) if fam else null
	if m == null:
		return
	var alvo: Vector2 = (m as Node2D).global_position + Vector2(-18, 10)
	if global_position.distance_to(alvo) > (fam.aprendiz_perto if fam else 36.0) and (not _moving or _target.distance_to(alvo) > 12.0):
		_go_to(alvo)


## O parto: na enfermaria (se tem) ou em casa; o _process conta o tempo quando ela chega.
func _destino_parto() -> Vector2:
	var ward := _closest_in_group("enfermarias")
	if ward:
		return ward.doctor_spot() if ward.has_method("doctor_spot") else (ward as Node2D).global_position
	return _rest_position()


func _medico_no_parto() -> bool:
	var ward := _closest_in_group("enfermarias")
	return ward != null and ward.has_method("doctors") and not (ward.doctors() as Array).is_empty() \
		and global_position.distance_to((ward as Node2D).global_position) < 120.0


## Bloco 110: os traços (sorteia na primeira vez: ipezinho novo, migrante, save antigo).
func tracos_de() -> Array:
	if e_crianca():
		return tracos  # (Bloco 111: a criança ganha os traços quando vira adulta)
	if tracos.is_empty():
		var rel := _relacoes()
		if rel:
			tracos = rel.sorteia_tracos()
	return tracos


## Bloco 84: refeição perdida rende menos (Schedule.perda_por_refeicao cada, até perda_max).
func _mult_refeicoes() -> float:
	var s := _schedule()
	return s.mult_refeicoes(refeicoes_perdidas) if s else 1.0


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
	# Bloco 94: botas — pega no inverno, devolve quando acaba; gasta só andando na neve
	if eq.is_winter():
		if not wearing.has("botas") and not downed:
			var b: float = eq.take("botas")
			if b > 0.0:
				wearing["botas"] = b
				_popup("Calçou as botas", Color(0.75, 0.88, 1.0))
		if wearing.has("botas") and _moving and not _inside and eq.is_cold_at(global_position):
			wearing.botas -= delta
			if wearing.botas <= 0.0:
				wearing.erase("botas")
				eq.give_back("botas", 0.0)
				_popup("A bota furou!", Color(1.0, 0.6, 0.45))
	elif wearing.has("botas"):
		eq.give_back("botas", wearing.botas)
		wearing.erase("botas")
	# trajes: veste na entrada da zona, devolve na saída, gasta só lá dentro
	var zona: String = eq.hazard_at(global_position)
	# Bloco 70: fora das zonas, a poça de perigo (ácido/lava) também pede o traje dela
	var fundo := _fundo()
	var poca: Node = fundo.poca_at(global_position) if zona == "" and fundo and not _inside else null
	var z: String = zona if zona != "" else (String(poca.traje()) if poca else "")
	_na_poca = null
	_molhado = maxf(_molhado - delta, 0.0)
	if poca and poca.kind == "agua":  # Bloco 71: água não pede traje — atrasa e molha
		_na_poca = poca
		if _molhado <= 0.0 and _hazard_cd <= 0.0:
			_hazard_cd = 4.0
			_popup("Molhado: a lava queima menos", Color(0.6, 0.85, 1.0))
		_molhado = fundo.agua_molhado if fundo else 20.0
	for t in eq.SUITS:
		if wearing.has(t) and t != z:
			eq.give_back(t, wearing[t])
			wearing.erase(t)
	if z == "" or _carried_by != null:
		_poca_expo = maxf(_poca_expo - delta * 0.5, 0.0)  # fora da poça o ardor passa
		return
	if not wearing.has(z):
		var d: float = eq.take(z)
		if d > 0.0:
			wearing[z] = d
			_popup("Vestiu: %s" % eq.NAMES[z].to_lower(), Color(0.8, 1.0, 0.7))
		elif poca != null:
			_poca_tick(poca, delta)  # sem traje no vestiário: passa pela poça e se arrisca
		else:
			_leave_hazard(eq, z, "sem %s no vestiário" % eq.NAMES[z].to_lower())
		return
	var vent: float = fundo.ventilacao_mult(global_position) if fundo and z == "gas" else 1.0
	wearing[z] -= delta * eq.wear_rate(z) * vent  # (Bloco 70: o ventilador poupa a máscara)
	if wearing[z] <= 0.0:
		wearing.erase(z)
		eq.give_back(z, 0.0)
		if poca == null:
			_leave_hazard(eq, z, "%s quebrou" % eq.NAMES[z].to_lower())


func _fundo() -> Node:
	return get_tree().get_first_node_in_group("fundo")


## Bloco 70: dentro da poça sem traje — devagar e, passou do tempo, queima (vai pra enfermaria como
## qualquer machucado). O ventilador do S2 faz o ácido arder mais devagar.
func _poca_tick(poca: Node, delta: float) -> void:
	_na_poca = poca
	var fundo := _fundo()
	var k: float = fundo.ventilacao_mult(global_position) if fundo and poca.kind == "acido" else 1.0
	if poca.kind == "lava" and _molhado > 0.0 and fundo:
		k *= fundo.molhado_lava  # Bloco 71: molhado na água do S4, a lava queima menos
	_poca_expo += delta * k
	if _hazard_cd <= 0.0:
		_hazard_cd = 4.0
		_popup("%s! Sem %s" % [poca.nome(), _equipment().NAMES[poca.traje()].to_lower()], Color(1.0, 0.6, 0.4))
	if _poca_expo < poca.exposicao() or injured:
		return
	_poca_expo = 0.0
	var grave: bool = randf() < poca.grave_chance()
	if fundo:
		fundo.registra_queimadura(poca.kind)
	hurt(poca.kind, "grave" if grave else "leve")
	_toast("%s se queimou no %s (sem %s)." % [_display(), poca.nome().to_lower(), _equipment().NAMES[poca.traje()].to_lower()])


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
	if cause == "mina" and is_inside_tree():
		_rockfall()
		if injury_severity == "grave":  # Prompt 24: acidente feio ganha a faixa com a cena
			var hud := get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_banner"):
				hud.show_banner("ACIDENTE NA MINA", "%s se machucou feio no desabamento. Precisa de leito na enfermaria." % _display())
	var grave := injury_severity == "grave"
	var text: String = {"galho": "Ai! Um galho!", "javali": "Ai! O javali!", "acido": "Ai! Ácido!", "lava": "Ai! Queimou!", "parto": "Complicação no parto!"}.get(cause, "Ai!")
	_popup(text + (" (grave)" if grave else ""), Color(1.0, 0.25, 0.2) if grave else Color(1.0, 0.4, 0.35))
	if grave and not downed and cause != "parto":  # (caído em combate e o parto têm o aviso próprio)
		_toast("%s se machucou feio! Precisa de leito na enfermaria." % _display())
	Audio.hurt(global_position)
	Audio.voz(global_position, "dor", gender)  # Bloco 114: a voz curta (desligável)
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
	Audio.voz(global_position, "dor", gender)
	_toast("%s piorou: machucado GRAVE! Precisa de leito." % _display())
	injured_changed.emit(true)


## Grave sem leito até o fim: morre. Vai pro memorial da enfermaria (cruz onde caiu).
func _die() -> void:
	if not is_guard() and String(injury_cause) in CAUSAS_BOBAS:
		mortes_bobas += 1  # Bloco 109: morte "boba" (quem não é guarda, por criatura ou radiação) — telemetria
	var rel_x := _relacoes()
	if rel_x:
		rel_x.morreu(self)  # Bloco 110: o luto dos amigos e do parceiro
	var inf := _closest_in_group("enfermarias")
	if inf:
		inf.record_death(self)  # o HUD mostra a faixa pelo sinal patient_died
	Audio.stinger("morte")  # Bloco 114 (sem arquivo: o sino fúnebre)
	var cal := get_tree().get_first_node_in_group("calendario")
	if not carregando_corpo.is_empty():
		_larga_corpo()
	if cal:
		cal.on_morte(_display())  # Bloco 88: funeral na hora social seguinte
		if cal.tem_cemiterio() and not has_meta("sem_corpo"):  # (Bloco 104: quem morreu na expedição não volta)
			cal.novo_corpo(_display(), global_position, String(injury_cause))  # Bloco 93: o padre vem buscar
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
		var cat := _catalogo()
		if cat and cat.has_method("mult_acidente"):
			leak *= cat.mult_acidente(global_position)  # Bloco 103: andar liberado sem reconhecimento
		leak *= Modificadores.mult(get_tree(), "acidente", self)  # Bloco 108: a jornada e a fraqueza (políticas da vila)
		var rel_m := _relacoes()
		if rel_m:
			leak *= rel_m.mult_acidente(self)  # Bloco 110: o cuidadoso
		if randf() < injury_chance * [1.0, irritated_injury_mult, furious_injury_mult][_mood] * depth_danger() * leak:
			acidentes_trabalho += 1
			hurt()
			return


## Texto flutuante acima da cabeça.
func _popup(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.04))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", Tipo.MAPA)
	label.position = Vector2(-18, -62)
	label.z_index = 20
	add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 22.0, 1.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


# ------------------------------------------------------------ agenda e refeições (Bloco 84)
func _schedule() -> Node:
	if _sched == null or not is_instance_valid(_sched):
		_sched = get_tree().get_first_node_in_group("schedule") if is_inside_tree() else null
	return _sched


## Período da agenda agora ("" = sem Schedule).
func periodo_agenda() -> String:
	var s := _schedule()
	return s.periodo(self) if s else ""


## A refeição desta hora que ele ainda não fez ("" = nenhuma).
func _refeicao_da_hora() -> String:
	var s := _schedule()
	if s == null:
		return ""
	var m: String = s.refeicao_do(s.periodo(self))
	return m if m != "" and not refeicoes_hoje.has(m) else ""


## A camada da agenda no _choose_state. "" = deixa a lógica de sempre decidir (horário de trabalho, sem
## relógio, ou o turno extra fora de hora).
func _agenda_estado(food_ok: bool) -> String:
	var s := _schedule()
	if s == null:  # (cena sem Schedule: o de antes — de noite pra casa)
		return "home" if _is_night() and not overtime and not is_guard() else ""
	var p: String = s.periodo(self)
	var m: String = s.refeicao_do(p)
	if m != "" and not refeicoes_hoje.has(m) and food_ok and hunger < hunger_max * s.refeicao_dispensa:
		return "eating"  # a refeição da hora (uma porção)
	if is_doctor() and _has_infirmary():
		return "doctor"  # sempre de plantão (come nos turnos dele, acima)
	if is_priest():
		return "padre"  # Bloco 88: na igreja (de noite também: dorme lá)
	if p == "missa":
		return "social"  # Bloco 88: missa de domingo — o ponto é a igreja (calendario.ponto_forcado)
	# Bloco 84: fora do horário de trabalho, quem ainda tem carga termina a entrega antes de ir pra casa
	# ("voltar" dura meia hora de jogo, ~11 s: nem sempre dá pra chegar no armazém dentro dela)
	if p in ["voltar", "social", "dormir"] and not overtime:
		var entrega := _entrega_pendente()
		if entrega != "":
			return entrega
	match p:
		"dormir":
			if overtime or (is_guard() and _is_night() and s.de_vigia(self)):
				return ""
			return "home"
		"vigilia":
			return ""  # (o guarda de vigia: a lógica do guarda manda pro posto)
		"social":
			if overtime:
				return ""
			# depois do jantar: taverna se estiver pra baixo (Bloco 85: a hora social de verdade)
			if (_ai_state == "leisure" and happiness < leisure_until and _station_ok_for("leisure")) \
					or (happiness < leisure_below and _has_usable_station("tavernas")):
				return "leisure"
			# Bloco 85: hora social — um ponto social com lugar (com chuva, só coberto); senão, casa
			if (_ai_state == "social" and _spot != null and is_instance_valid(_spot)) or _escolhe_spot(true) != null:
				return "social"
			return "home"
		"voltar":
			if overtime:
				return ""
			return "home"  # (a carga já foi entregue acima)
	return ""


# ------------------------------------------------------------ hora social (Bloco 85)
## Chove ou tem onda solar agora? (aí só valem os pontos cobertos)
func _precisa_coberto() -> bool:
	var w := get_tree().get_first_node_in_group("weather")
	var sun := _sun()
	var chuva: bool = w != null and (w.get("forcar_chuva") == true or (w.has_method("is_raining") and w.is_raining()))
	return chuva or (sun != null and sun.wave_active())


## O melhor ponto social pra ele agora (null = nenhum com lugar). `so_ver` = só olhar, sem reservar.
## Nota: perto ganha, ponto com gente (e lugar) ganha, um pouco de sorte pra não irem todos pro mesmo.
func _escolhe_spot(so_ver := false) -> Node:
	# Bloco 88: missa e funeral (igreja) e festival (praça): todo mundo pro mesmo ponto
	var forcado := _ponto_forcado()
	if forcado != null:
		if forcado == _spot or forcado.livres() > 0:
			return forcado
	var coberto := _precisa_coberto()
	var melhor: Node = null
	var melhor_nota := -INF
	for sp in get_tree().get_nodes_in_group("social_spots"):
		if sp == _spot or (coberto and not sp.coberto) or sp.livres() <= 0:
			continue
		var d: float = global_position.distance_to(sp.centro())
		var gente: int = sp.ocupantes().size()
		var nota := -d / 40.0 + (6.0 if gente > 0 else 0.0) + randf() * 6.0 + _nota_social(sp)  # Bloco 110
		if nota > melhor_nota:
			melhor_nota = nota
			melhor = sp
	if melhor == null and not so_ver and _spot != null and is_instance_valid(_spot):
		return _spot  # (sem outro: fica onde está)
	return melhor


## Bloco 110: o parceiro e os amigos puxam pra roda deles (sentam juntos).
func _nota_social(sp: Node) -> float:
	var rel := _relacoes()
	if rel == null:
		return 0.0
	var n := 0.0
	for o in sp.ocupantes():
		var nv: int = rel.nivel(self, o)
		if nv == 5:
			n += rel.puxa_parceiro
		elif nv >= 3:
			n += rel.puxa_proximo
		elif nv == 2:
			n += rel.puxa_amigo
	return n


## Vai pra um ponto social: reserva o lugar e monta o passeio (passa por outro ponto se o desvio for curto).
## Bloco 88: o ponto pra onde o calendário manda todo mundo agora (null = livre).
func _ponto_forcado() -> Node:
	var cal := get_tree().get_first_node_in_group("calendario")
	return cal.ponto_forcado() if cal else null


func _social_vai() -> void:
	var novo := _escolhe_spot()
	if novo == null:
		_decision_timer = 0.0
		return
	if novo != _spot:
		_social_solta()
		_spot = novo
	_spot_i = _spot.reservar(self)
	if _spot_i < 0:
		_spot = null
		_decision_timer = 0.0
		return
	_conversando = false
	_com_companhia = false
	_social_t = 0.0
	var destino: Vector2 = _spot.lugar(_spot_i)
	_passeio = []
	var s := _schedule()
	var desvio_max: float = s.passeio_desvio if s else 160.0
	var direto := global_position.distance_to(destino)
	var via: Vector2 = Vector2.INF
	var menor := desvio_max
	for sp in get_tree().get_nodes_in_group("social_spots"):
		if sp == _spot:
			continue
		var c: Vector2 = sp.centro()
		var desvio := global_position.distance_to(c) + c.distance_to(destino) - direto
		if desvio < menor and global_position.distance_to(c) > 40.0 and c.distance_to(destino) > 40.0:
			menor = desvio
			via = c
	# Bloco 89: com caminho pintado entre ele e o ponto, o passeio segue o caminho
	var cam := get_tree().get_first_node_in_group("caminhos")
	var pelo_caminho: PackedVector2Array = cam.rota(global_position, destino) if cam else PackedVector2Array()
	if not pelo_caminho.is_empty():
		for q in pelo_caminho:
			_passeio.append(q)
	elif via != Vector2.INF:
		_passeio.append(via)
	_passeio.append(destino)
	_go_to(_passeio[0])


## Solta o lugar reservado (sem sair do estado).
func _social_solta() -> void:
	if _spot != null and is_instance_valid(_spot):
		_spot.liberar(self)
	_spot_i = -1
	_conversando = false
	_com_companhia = false


## Saiu da hora social: solta tudo e esconde o balão.
func _social_sai() -> void:
	_social_solta()
	_spot = null
	_passeio.clear()
	if _balao:
		_balao.visible = false


## O ponto social chama: está na roda conversando?
func esta_conversando() -> bool:
	return _ai_state == "social" and _conversando


## A cada quadro, barato: o ânimo de conversar sumindo e, na hora social, chegar/conversar/trocar de ponto.
func _social_process(delta: float) -> void:
	if _balao and _balao.visible:
		_balao_vida -= delta
		if _balao_vida <= 0.0:
			_balao.visible = false
	var s := _schedule()
	if animo_fe > 0.0:  # Bloco 88: o ânimo da missa some devagar
		var calf := get_tree().get_first_node_in_group("calendario")
		animo_fe = maxf(animo_fe - (calf.missa_decai if calf else 0.01) * delta, 0.0)
	if _ai_state != "social":
		if animo_social > 0.0 and s:
			animo_social = maxf(animo_social - s.animo_decai * delta, 0.0)
		return
	if s == null or _spot == null or not is_instance_valid(_spot):
		_decision_timer = 0.0
		return
	if not _conversando:
		if _moving:
			return
		if _passeio.size() > 1:  # chegou no ponto do caminho: segue pro lugar
			_passeio.pop_front()
			_go_to(_passeio[0])
			return
		_conversando = true
		_social_t = randf_range(s.conversa_min, maxf(s.conversa_max, s.conversa_min))
		_balao_t = randf_range(0.3, s.balao_max)
		return
	var forcado := _ponto_forcado()
	if forcado == null or forcado == _spot:
		if forcado == null:
			_social_t -= delta  # (no ponto forçado ele fica até acabar)
	else:
		_social_t = 0.0  # começou a missa/funeral/festival: vai pra lá
	if _spot.tipo == "igreja":  # Bloco 88: aconselhamento (o padre lá dobra) e a missa
		var cal := get_tree().get_first_node_in_group("calendario")
		if cal:
			var pd: Node = cal.padre()
			var mult := 2.0 if pd != null and pd.get_state() == "padre" else 1.0
			anger = maxf(anger - cal.aconselhamento_por_segundo * mult * delta, 0.0)
			if periodo_agenda() == "missa":
				var rel_d := _relacoes()
				animo_fe = maxf(animo_fe, cal.missa_animo * (rel_d.devoto_missa if rel_d and rel_d.tem(self, "devoto") else 1.0))  # Bloco 110
	_balao_t -= delta
	if _balao_t <= 0.0:
		_balao_t = randf_range(s.balao_min, maxf(s.balao_max, s.balao_min))
		var comp: Array = _spot.companheiros(self)
		_com_companhia = not comp.is_empty()
		_com_amigo = false
		if _com_companhia:
			var outro: Node2D = comp[randi() % comp.size()]
			_facing = signf(outro.global_position.x - global_position.x) if absf(outro.global_position.x - global_position.x) > 1.0 else _facing
			_mostra_balao(_assunto())
			var rel_s := _relacoes()
			if rel_s:  # Bloco 110: a conversa conta pra relação (e com amigo anima mais)
				rel_s.conversou(self, outro, _spot.tipo == "igreja")
				_com_amigo = rel_s.nivel(self, outro) >= 2
		if _precisa_coberto() and not _spot.coberto:
			_social_t = 0.0  # começou a chover: procura um lugar coberto
	if _com_companhia:
		var rel_c := _relacoes()
		var mult_amigo: float = rel_c.conversa_amigo_mult if rel_c and _com_amigo else 1.0  # Bloco 110: com amigo anima mais
		animo_social = minf(animo_social + s.animo_por_segundo * _spot.animo_mult * mult_amigo * delta, s.animo_max)
	if _social_t <= 0.0:
		_social_vai()  # troca de ponto (o passeio passa por outro no caminho)


## O assunto do balão: o que pesa pra ele agora (fome, frio, a função, a estação...), com um pouco de sorte.
func _assunto() -> String:
	var temas: Array[String] = ["animo", "creditos", "minerio", "madeira"]
	if hunger < hunger_max * 0.5:
		temas.append("comida")
	if is_cold():
		temas.append("frio")
	if anger >= anger_furious_at * 0.5:
		temas.append("zanga")
	var icone_funcao: String = Icones.FUNCAO.get(job, "")
	if icone_funcao != "":
		temas.append(icone_funcao)
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn and dn.has_method("season_index") and dn.season_index() >= 0:
		temas.append(Icones.ESTACAO[dn.season_index()])
	return temas[randi() % temas.size()]


## Balão de fala com um ícone em cima da cabeça (some sozinho).
func _mostra_balao(icone: String) -> void:
	if _balao == null:
		_balao = Sprite2D.new()
		_balao.name = "Balao"
		_balao.texture = BALAO
		_balao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_balao.position = BALAO_POS
		_balao.z_index = 21
		var ic := Sprite2D.new()
		ic.name = "Icone"
		ic.scale = Vector2(0.34, 0.34)
		ic.position = Vector2(0, -2)
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_balao.add_child(ic)
		add_child(_balao)
	var tex := Icones.tex(icone)
	(_balao.get_node("Icone") as Sprite2D).texture = tex
	(_balao.get_node("Icone") as Sprite2D).scale = Vector2(0.34, 0.34)  # (Bloco 103: a descoberta troca o ícone e a escala)
	_balao.visible = tex != null and not sem_baloes
	_balao_vida = 1.8


# ------------------------------------------------------------ balão de motivo (Bloco 95)
## Ícone de cada motivo (assets/game/ui/icones/) e o nome dele (dica, lista, teste).
const MOTIVO_ICONE := {"sem_trabalho": "sem_funcao", "sem_ferramenta": "sem_ferramenta", "armazem_cheio": "armazem_cheio",
	"caminho_bloqueado": "caminho_bloqueado", "sem_comida": "al_falta_comida",
	"sem_material": "al_obra_parada"}  # Bloco 105 (ícone provisório até a arte própria ser aprovada)
const MOTIVO_NOME := {"sem_trabalho": "sem trabalho", "sem_ferramenta": "sem ferramenta", "armazem_cheio": "armazém cheio",
	"caminho_bloqueado": "caminho bloqueado", "sem_comida": "sem comida", "sem_material": "sem material"}
## Segundos parado pelo MESMO motivo antes de o balão aparecer (não pisca a cada troca de tarefa).
@export var motivo_espera: float = 2.0
## A cada quantos segundos o motivo é conferido (barato: só olha o estado que a IA já decidiu).
@export var motivo_intervalo: float = 0.5


## Por que está parado? "" = não está (ou o motivo é a agenda: dormindo, comendo, na hora social...).
##   sem_trabalho       sem função, ou com função e sem nada pra fazer (sem obra, sem jazida, sem árvore...)
##   sem_ferramenta     guarda com a arma quebrada; caçador com toca e sem arco; minerador só com jazida trancada
##   armazem_cheio      com a carga nas costas e o armazém cheio (Bloco 97: o armazém tem limite)
##   caminho_bloqueado  andando e preso no mesmo lugar (o anti-travamento já começou a agir)
##   sem_comida         com fome e a cozinha vazia
##   sem_material       (Bloco 105) o carregador ou o fundidor/carpinteiro sem nada pra levar e uma ordem parada por
##                      falta de insumo no armazém
func motivo_parado() -> String:
	if downed or injured or _resting or holding_robot != null or e_crianca():
		return ""  # (Bloco 111: criança não é "parada": brinca, estuda, aprende)
	if _moving and _stuck_stage >= 1:
		return "caminho_bloqueado"
	if hunger < hunger_threshold:
		var tem_comida := false
		for c in get_tree().get_nodes_in_group("comedouros"):
			if c.food_stock > 0.0:
				tem_comida = true
				break
		if not tem_comida:
			return "sem_comida"
	if is_guard() and weapon == "" and _ai_state in ["guard", "training", "home", "idle"]:
		var def := _defense()
		if def == null or def.arsenal() == null:
			return "sem_ferramenta"
	# Bloco 106: esperando o compartimento dele abrir espaço
	if _ai_state == "esperando_espaco":
		return "armazem_cheio"
	# Bloco 97: com carga pra entregar, parado, e o armazém dele (ou todos) cheio
	var tem_carga := carrying > 0.0 or wood_carrying > 0.0 or raw_carrying > 0.0 or not barras_mao.is_empty()
	if tem_carga and not _moving and _ai_state in ["storing", "hauling", "stocking", "buscando_insumo"]:
		var cat_c: String = {"storing": "minerios", "hauling": "madeira", "stocking": "alimentos", "buscando_insumo": "minerios"}[_ai_state]
		var cheio_aqui: bool = _station != null and _station.has_method("cheio_cat") and _station.cheio_cat(cat_c)
		if cheio_aqui or (_station == null and _sem_espaco(cat_c)):
			return "armazem_cheio"
	if _ai_state != "idle":
		return ""
	if is_hunter() and not _has_bow() and not get_tree().get_nodes_in_group("caca").is_empty() 			and (not _has_usable_station("coleta_comida") or _agricultor_na_vila()):
		return "sem_ferramenta"
	if is_carrier() or is_smelter() or job == ROLE_CARPENTER:
		if _ordem_sem_insumo():
			return "sem_material"
		if not is_carrier():
			var fo := _fornalha_alvo()
			if fo and (fo.fila.a_caminho() > 0 or not (fo.barras_prontas as Dictionary).is_empty() or (fo.fila.a_comecar() > 0 and fo.falta() == "")):
				return ""  # esperando o carregador trazer o insumo / levar as barras: não está parado à toa
	if is_miner() and _find_best_station("minerios") == null:
		for m in get_tree().get_nodes_in_group("minerios"):
			if m.has_method("is_unlocked") and not m.is_unlocked() and m.ore_remaining > 0.0:
				return "sem_ferramenta"  # só sobrou jazida que pede ferramenta nova (Oficina)
	return "sem_trabalho"


func _motivo_tick(delta: float) -> void:
	_motivo_cd -= delta
	if _motivo_cd > 0.0:
		return
	_motivo_cd = motivo_intervalo
	if not _baloes_lido:
		_baloes_lido = true
		baloes_motivo = bool(Settings.get_value("hud", "baloes_motivo", true))
	var m := motivo_parado() if baloes_motivo and not sem_baloes else ""
	if m != _motivo:
		_motivo = m
		_motivo_t = 0.0
	else:
		_motivo_t += motivo_intervalo
	var mostra := _motivo != "" and _motivo_t >= motivo_espera and not (_balao != null and _balao.visible)
	if mostra and _motivo_balao == null:
		_motivo_balao = Sprite2D.new()
		_motivo_balao.name = "BalaoMotivo"
		_motivo_balao.texture = BALAO
		_motivo_balao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_motivo_balao.position = BALAO_POS  # o mesmo lugar do balão da conversa (os dois nunca juntos)
		_motivo_balao.z_index = 21
		var ic := Sprite2D.new()
		ic.name = "Icone"
		ic.scale = Vector2(0.34, 0.34)
		ic.position = Vector2(0, -2)
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_motivo_balao.add_child(ic)
		add_child(_motivo_balao)
	if _motivo_balao:
		if mostra:
			(_motivo_balao.get_node("Icone") as Sprite2D).texture = Icones.tex(MOTIVO_ICONE.get(_motivo, ""))
		if _motivo_balao.visible != mostra:
			_motivo_balao.visible = mostra


## O motivo que o balão está mostrando agora ("" = nenhum).
func motivo_no_balao() -> String:
	return _motivo if _motivo_balao != null and _motivo_balao.visible else ""


# ------------------------------------------------------------ material da obra (Bloco 96)
## Quanto o engenheiro leva por viagem (unidades de material: madeira, minério, barras, tábuas, pregos...).
@export var carga_material: float = 10.0
## Distância (px) em que ele "chegou" no armazém pra pegar o material.
@export var material_alcance: float = 40.0
## O que está nas mãos, indo pra obra ({item: qtd}).
var material_mao: Dictionary = {}
## O que ele prometeu buscar e ainda vai pegar no armazém ({item: qtd}).
var material_pedido: Dictionary = {}
## A obra dessas viagens e o armazém onde vai buscar.
var _material_obra: Node = null
var _material_armazem: Node = null
## Chegou na obra, a parte liberada está feita e não tem o material em armazém nenhum.
var _material_falta := false


func _material_qtd(d: Dictionary) -> float:
	var n := 0.0
	for k in d:
		n += float(d[k])
	return n


## Pode martelar? Só até a fração do material que já chegou (obra sem material: sempre).
func _pode_construir() -> bool:
	var site = ObraSite.de(_obra)
	if site == null or not site.tem_material() or site.tudo_entregue():
		return true  # (tudo entregue: até o fim, sem trava — senão parava em 99,99%)
	return _obra.obra_progress() < site.fracao() - 0.0001


## As viagens do material. true = está indo buscar ou levando (este quadro é da viagem, não da obra).
func _material_tick() -> bool:
	var site = ObraSite.de(_obra)
	if site == null or not site.tem_material():
		return false
	var eco := get_tree().get_first_node_in_group("economy")
	# 1) com material na mão: leva pra obra e entrega
	if not material_mao.is_empty() and _material_obra == _obra:
		var alvo: Vector2 = _obra_goal()
		var dist := global_position.distance_to(alvo)
		if (not _moving and dist <= OBRA_REACH) or dist <= 24.0:
			for k in material_mao:
				site.entregar(k, float(material_mao[k]))
			_popup("+" + ", ".join(material_mao.keys().map(func(k): return "%d %s" % [int(material_mao[k]), ObraSite._nome(k)])), Color(0.55, 1.0, 0.5))
			material_mao.clear()
			_material_obra = null
			if eco:
				eco.reserva_mudou()
			_moving = false
			return false  # chegou: daqui pra frente é a obra (entra e trabalha)
		if _obra_on_site:
			_obra.obra_leave(self)
			_obra_on_site = false
		if not _moving or _target.distance_to(alvo) > 2.0:
			_go_to(alvo)
		return true
	# 2) indo buscar: chegou no armazém, pega
	if not material_pedido.is_empty():
		if _material_armazem == null or not is_instance_valid(_material_armazem) or eco == null:
			material_pedido.clear()
			return false
		var pos: Vector2 = _material_armazem.get_wait_position(self) if _material_armazem.has_method("get_wait_position") else _material_armazem.global_position
		var d := global_position.distance_to(pos)
		if d <= material_alcance or (not _moving and d <= OBRA_REACH):
			for k in material_pedido:
				var got: float = eco.tira_do_armazem(_material_armazem, k, float(material_pedido[k]))
				if got > 0.0:
					material_mao[k] = float(material_mao.get(k, 0.0)) + got
			material_pedido.clear()
			_material_armazem = null
			eco.reserva_mudou()
			_moving = false
			if material_mao.is_empty():
				return false  # o armazém ficou sem (alguém pegou antes): decide de novo
			_material_obra = _obra
			return true
		if not _moving or _target.distance_to(pos) > 2.0:
			_go_to(pos)
		return true
	# 3) a parte liberada está feita? então vai buscar o que falta (do armazém mais perto que tem)
	if site.tudo_entregue() or _obra.obra_progress() < site.fracao() - 0.0001:
		_material_falta = false
		_espera_carregador = false
		return false  # ainda tem o que construir com o que já chegou
	if eco == null:
		return false
	# Bloco 105: com carregador na vila, quem constrói só constrói: espera ele trazer (fallback: ninguém pegou a tempo)
	var lg := _logistica()
	if lg and lg.deixa_pro_carregador("obra", _obra):
		_espera_carregador = true
		_material_falta = false
		return false
	_espera_carregador = false
	var cabe := carga_material
	var escolhido: Node = null
	for k in site.necessario:
		var precisa: float = site.a_buscar(k)
		if precisa < 0.5:
			continue
		var arms: Array = eco.armazens_com(k, global_position)
		if arms.is_empty():
			continue
		if escolhido == null:
			escolhido = arms[0]
		if not arms.has(escolhido):
			continue  # (outro armazém: fica pra próxima viagem)
		var q := minf(minf(precisa, cabe), eco._no_armazem(escolhido, k))
		if q >= 0.5:
			material_pedido[k] = q
			cabe -= q
		if cabe < 0.5:
			break
	if material_pedido.is_empty():
		var falta := false
		for k in site.necessario:
			if site.a_buscar(k) >= 0.5:
				falta = true
		_material_falta = falta  # nada no armazém (ou tudo já a caminho): espera na obra
		return false
	_material_falta = false
	_material_obra = _obra
	_material_armazem = escolhido
	eco.reserva_mudou()
	if _obra_on_site:
		_obra.obra_leave(self)
		_obra_on_site = false
	_go_to(escolhido.get_wait_position(self) if escolhido.has_method("get_wait_position") else escolhido.global_position)
	return true


## Larga o material: devolve = o que está na mão volta pro armazém (cancelou, trocou de função, a obra sumiu).
func solta_material(devolve: bool) -> void:
	var eco := get_tree().get_first_node_in_group("economy") if is_inside_tree() else null
	if devolve and eco:
		for k in material_mao:
			eco.devolve(k, float(material_mao[k]), global_position)
	material_mao.clear()
	material_pedido.clear()
	_material_obra = null
	_material_armazem = null
	_material_falta = false
	if eco:
		eco.reserva_mudou()


## Save: o material que estava na mão volta pro armazém (quando o mundo já está montado).
func _devolve_material_salvo(mm: Dictionary) -> void:
	var eco := get_tree().get_first_node_in_group("economy") if is_inside_tree() else null
	if eco == null:
		return
	for k in mm:
		var v = mm[k]
		if (v is float or v is int) and float(v) > 0.0:
			eco.devolve(String(k), float(v), global_position)


## "buscando 10 madeira no armazém (Taverna)" / "levando 10 madeira pra Taverna (20/40)" / "esperando material".
func _material_texto() -> String:
	var site = ObraSite.de(_obra)
	if site == null or not site.tem_material():
		return ""
	var titulo: String = _obra.obra_title()
	if not material_mao.is_empty() and _material_obra == _obra:
		return "levando %s pra %s (%d/%d)" % [_lista_material(material_mao), titulo, int(site.total_entregue() + _material_qtd(material_mao)), int(site.total_necessario())]
	if not material_pedido.is_empty():
		return "buscando %s no armazém (%s)" % [_lista_material(material_pedido), titulo]
	if _material_falta and not _pode_construir():
		return "esperando material no armazém (%s)" % titulo
	return ""


func _lista_material(d: Dictionary) -> String:
	return ", ".join(d.keys().map(func(k): return "%d %s" % [roundi(float(d[k])), ObraSite._nome(k)]))


## O ícone da carga: a tora pra madeira, a pedra do minério, o ícone do item (barra, tábua, prego...).
func _icone_material() -> Texture2D:
	_carry_icon.set_meta("_material", true)
	var k: String = material_mao.keys()[0]
	if k == "madeira":
		return WOOD_LOG
	if Ores.CHUNK_TEXTURES.has(k):
		return Ores.CHUNK_TEXTURES[k]
	var t := Icones.tex("it_" + k)
	return t if t != null else WOOD_LOG


# ------------------------------------------------------------ fundidor (Bloco 86)
## Barras prontas que ele leva pro armazém ({item: qtd}).
var barras_mao: Dictionary = {}
## Bloco 93: o corpo que o padre leva nos ombros ({nome, dia, estacao, causa}; vazio = nada).
var carregando_corpo: Dictionary = {}
var _corpo_alvo: Node2D = null
var _enterro_ini := -1.0
var _fornalha: Node = null
var _visita_feita := false


func is_smelter() -> bool:
	return job == ROLE_SMELTER


## Bloco 87: o ferreiro (Oficina e Arsenal).
func is_smith() -> bool:
	return job == ROLE_SMITH


## Bloco 88: o padre.
func is_priest() -> bool:
	return job == ROLE_PRIEST


## Bloco 107: o agricultor / a agricultora (horta e estufa).
func is_farmer() -> bool:
	return job == ROLE_FARMER


## Bloco 107: quem colhe a horta (caçador ou agricultor).
func is_gatherer() -> bool:
	return job == ROLE_HUNTER or job == ROLE_FARMER


## Bloco 107: tem um agricultor trabalhando na vila (sem ferimento)? Olha a cada segundo, não a cada decisão.
var _agri_na_vila_t := -10.0
var _agri_na_vila := false


func _agricultor_na_vila() -> bool:
	var agora := Time.get_ticks_msec() / 1000.0
	if agora - _agri_na_vila_t > 1.0:
		_agri_na_vila_t = agora
		_agri_na_vila = get_tree().get_nodes_in_group("ipezinhos").any(func(w): return w != self and w.has_method("is_farmer") and w.is_farmer() and not w.injured)
	return _agri_na_vila


## Bloco 94: o carpinteiro / a carpinteira (Carpintaria e as camas novas).
func is_carpenter() -> bool:
	return job == ROLE_CARPENTER


## Bloco 104: o batedor.
func is_scout() -> bool:
	return job == ROLE_SCOUT


## Bloco 106: o compartimento `cat` está cheio em TODOS os armazéns (e, pro minério, nenhum ponto do vagonete recebe)?
## Quem coleta isso para de coletar e espera disponível.
func _sem_espaco(cat: String) -> bool:
	if not is_inside_tree():
		return false
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null or not eco.has_method("armazens_cheios") or not eco.armazens_cheios(cat):
		return false
	if cat == "minerios":
		for p in get_tree().get_nodes_in_group("pontos_carga"):
			if p.has_method("is_usable") and p.is_usable():
				return false  # (o ponto do vagonete ainda recebe)
	return true


## Bloco 105: alguma Fornalha/Carpintaria (a dele, se for o operador) com ordem parada por falta de insumo?
func _ordem_sem_insumo() -> bool:
	var grupos: Array = ["fornalhas", "carpintarias", "carvoarias", "curtumes"]
	if is_smelter():
		grupos = ["fornalhas"]
	elif job == ROLE_CARPENTER:
		grupos = ["carpintarias"]
	for g in grupos:
		for f in get_tree().get_nodes_in_group(g):
			if f.get("fila") != null and f.fila.a_comecar() > 0 and f.fila.comecadas() == 0 and f.has_method("falta") and f.falta() != "":
				return true
	return false


## Bloco 105: do save: o que o carregador levava (barras, matéria-prima) volta pro armazém.
func _devolve_entrega(em: Dictionary) -> void:
	var eco := get_tree().get_first_node_in_group("economy") if is_inside_tree() else null
	if eco:
		for k in em:
			eco.devolve(String(k), float(em[k]), global_position)


## Bloco 105: o carregador e o mecânico.
func is_carrier() -> bool:
	return job == ROLE_CARRIER


func is_mechanic() -> bool:
	return job == ROLE_MECHANIC


func _logistica() -> Node:
	return get_tree().get_first_node_in_group("logistica") if is_inside_tree() else null


func _manutencao() -> Node:
	return get_tree().get_first_node_in_group("manutencao") if is_inside_tree() else null


## Bloco 105: a cozinha com matéria-prima no estoque (o carregador trouxe), ou null.
func _cozinha_com_estoque() -> Node:
	for c in get_tree().get_nodes_in_group("comedouros"):
		if float(c.get("raw_local") if c.get("raw_local") != null else 0.0) >= 0.5:
			return c
	return null


# ------------------------------------------------------------ o carregador (Bloco 105)
## Pega a entrega (reservada na logística) e vai pro primeiro ponto dela.
func _carregar() -> void:
	var lg := _logistica()
	var eco := get_tree().get_first_node_in_group("economy")
	if lg == null or eco == null:
		return
	if _carga.is_empty():
		var t: Dictionary = lg.reserva(self)
		if t.is_empty():
			_decision_timer = 0.0
			return
		_carga = t.duplicate()
		_carga["fase"] = "ao_alvo" if String(t.tipo) == "barras" else "ao_armazem"
		if String(t.tipo) == "obra" and not _prepara_obra(t.alvo, eco):
			lg.solta(self)
			_carga = {}
			return
		if String(t.tipo) in ["insumo", "cozinha"]:
			_carga["arm"] = _armazem_perto(eco)
	var dest := _carga_destino()
	if dest != Vector2.INF and global_position.distance_to(dest) > 24.0 and (not _moving or _target.distance_to(dest) > 4.0):
		_go_to(dest)


## A obra: escolhe o armazém e o que levar (até a carga dele) — os mesmos campos do engenheiro (a obra conta como "a caminho").
func _prepara_obra(site: Node, eco: Node) -> bool:
	var os = ObraSite.de(site)
	if os == null:
		return false
	var cabe := capacidade_carga()
	var escolhido: Node = null
	material_pedido.clear()
	for k in os.necessario:
		var precisa: float = os.a_buscar(k)
		if precisa < 0.5:
			continue
		var arms: Array = eco.armazens_com(k, global_position)
		if arms.is_empty():
			continue
		if escolhido == null:
			escolhido = arms[0]
		if not arms.has(escolhido):
			continue
		var q := minf(minf(precisa, cabe), eco._no_armazem(escolhido, k))
		if q >= 0.5:
			material_pedido[k] = q
			cabe -= q
		if cabe < 0.5:
			break
	if material_pedido.is_empty():
		return false
	_material_obra = site
	_material_armazem = escolhido
	_carga["arm"] = escolhido
	eco.reserva_mudou()
	return true


func _armazem_perto(eco: Node) -> Node:
	var melhor: Node = null
	for a in get_tree().get_nodes_in_group("armazens"):
		if melhor == null or global_position.distance_to(a.global_position) < global_position.distance_to(melhor.global_position):
			melhor = a
	return melhor


func _carga_destino() -> Vector2:
	if _carga.is_empty():
		return Vector2.INF
	var alvo = _carga.get("alvo")
	if String(_carga.fase) in ["ao_armazem", "ao_armazem2"]:
		var a = _carga.get("arm")
		if a == null or not is_instance_valid(a):
			return Vector2.INF
		return a.get_wait_position(self) if a.has_method("get_wait_position") else (a as Node2D).global_position
	if alvo == null or not is_instance_valid(alvo):
		return Vector2.INF
	if String(_carga.tipo) == "obra":
		return alvo.obra_position(self)
	return (alvo as Node2D).global_position + Vector2(0, 30)


## Cada quadro: chegou no ponto da fase -> pega / entrega.
func _carrega_tick() -> void:
	if _carga.is_empty():
		return
	var lg := _logistica()
	var eco := get_tree().get_first_node_in_group("economy")
	var alvo = _carga.get("alvo")
	if alvo == null or not is_instance_valid(alvo) or eco == null:
		_desfaz_carga(true)
		return
	var dest := _carga_destino()
	if dest == Vector2.INF:
		_desfaz_carga(true)
		return
	var d := global_position.distance_to(dest)
	if not (d <= 24.0 or (not _moving and d <= 60.0)):
		return
	_moving = false
	var tipo := String(_carga.tipo)
	match String(_carga.fase):
		"ao_armazem":
			match tipo:
				"obra":
					for k in material_pedido:
						var got: float = eco.tira_do_armazem(_material_armazem, k, float(material_pedido[k]))
						if got > 0.0:
							material_mao[k] = float(material_mao.get(k, 0.0)) + got
					material_pedido.clear()
					_material_armazem = null
					eco.reserva_mudou()
					if material_mao.is_empty():
						_desfaz_carga(false)
						return
				"insumo":
					var n: int = alvo.fila.comecar_unidades(int(alvo.lote), eco, true)
					if n <= 0:
						_desfaz_carga(false)
						return
					_levando_insumo = true
					_popup("Insumos: %d x (%s)" % [n, alvo.fila.texto_insumos(alvo.fila.atual().receita)], Color(1.0, 0.85, 0.45))
				"cozinha":
					var arm = _carga.get("arm")
					var quer := minf(capacidade_carga(), float(alvo.raw_local_max) - float(alvo.raw_local))
					var tem := minf(float(arm.raw_stored), eco.livre("comida_crua"))
					var q := minf(quer, tem)
					if q < 0.5:
						_desfaz_carga(false)
						return
					arm.raw_stored -= q
					entrega_mao["comida_crua"] = q
			_carga.fase = "ao_alvo"
			_go_to(_carga_destino())
		"ao_alvo":
			match tipo:
				"obra":
					var os = ObraSite.de(alvo)
					if os:
						for k in material_mao:
							os.entregar(k, float(material_mao[k]))
						_popup("+" + ", ".join(material_mao.keys().map(func(k): return "%d %s" % [int(material_mao[k]), ObraSite._nome(k)])), Color(0.55, 1.0, 0.5))
					material_mao.clear()
					_material_obra = null
					eco.reserva_mudou()
				"insumo":
					alvo.fila.entrega_a_caminho()
					_levando_insumo = false
				"cozinha":
					alvo.raw_local = minf(float(alvo.raw_local) + float(entrega_mao.get("comida_crua", 0.0)), float(alvo.raw_local_max))
					entrega_mao.clear()
				"barras":
					entrega_mao = (alvo.barras_prontas as Dictionary).duplicate()
					alvo.barras_prontas.clear()
					if entrega_mao.is_empty():
						_desfaz_carga(false)
						return
					var total := 0.0
					for k in entrega_mao:
						total += float(entrega_mao[k])
					var arm2: Node = eco.armazem_com_espaco(global_position, total, Items.compartimento(String(entrega_mao.keys()[0])))  # (Bloco 107: o compartimento do item)
					_carga["arm"] = arm2 if arm2 else _armazem_perto(eco)
					_carga.fase = "ao_armazem2"
					_go_to(_carga_destino())
					return
			_fim_da_entrega(tipo)
		"ao_armazem2":  # as barras chegando no armazém (cheio: espera como todo mundo, Bloco 97)
			var arm3 = _carga.get("arm")
			var total2 := 0.0
			for k in entrega_mao:
				total2 += float(entrega_mao[k])
			var cat_e: String = Items.compartimento(String(entrega_mao.keys()[0])) if not entrega_mao.is_empty() else "minerios"
			if arm3.has_method("espaco_cat") and float(arm3.espaco_cat(cat_e)) < total2 - 0.01:
				var outro: Node = eco.armazem_com_espaco(global_position, total2, cat_e)
				if outro and outro != arm3:
					_carga["arm"] = outro
					_go_to(_carga_destino())
				return
			for k in entrega_mao:
				arm3.add_item(k, float(entrega_mao[k]))
			_popup("+%s" % ", ".join(entrega_mao.keys().map(func(k): return "%d %s" % [int(entrega_mao[k]), Items.nome(k).to_lower()])), Color(0.55, 1.0, 0.5))
			entrega_mao.clear()
			_fim_da_entrega(tipo)


func _fim_da_entrega(tipo: String) -> void:
	var lg := _logistica()
	if lg:
		lg.feita(self, tipo)
	_carga = {}
	_decision_timer = 0.0


## Larga a entrega (a obra sumiu, trocou de função...). devolve = o que estiver na mão volta pro armazém; os insumos já
## pagos vão pra fornalha (as unidades começam: nada se perde).
func _desfaz_carga(devolve: bool) -> void:
	var lg := _logistica()
	if lg:
		lg.solta(self)
	if not material_mao.is_empty() or not material_pedido.is_empty():
		solta_material(devolve)
	var eco := get_tree().get_first_node_in_group("economy") if is_inside_tree() else null
	if _levando_insumo and _carga.get("alvo") != null and is_instance_valid(_carga.alvo) and _carga.alvo.get("fila") != null:
		_carga.alvo.fila.entrega_a_caminho()
	_levando_insumo = false
	if eco:
		for k in entrega_mao:
			eco.devolve(k, float(entrega_mao[k]), global_position)
	entrega_mao.clear()
	_carga = {}
	_decision_timer = 0.0


# ------------------------------------------------------------ o mecânico (Bloco 105)
## Chegou na máquina: trabalha o tempo da preventiva (a animação de consertar) e ela volta nova.
func _manut_tick(delta: float) -> void:
	if _manut_alvo == null or not is_instance_valid(_manut_alvo):
		_manut_alvo = null
		return
	var mt := _manutencao()
	if mt == null or _manut_alvo.manut_quebrada():
		_manut_alvo = null
		_decision_timer = 0.0
		return
	var p: Vector2 = _manut_alvo.manut_pos(self)
	if global_position.distance_to(p) > 30.0 and (_moving or global_position.distance_to(p) > 70.0):
		_manut_andando += delta
		if _manut_andando > mt.preventiva_desiste:
			mt.desiste(_manut_alvo, self)  # não chega (caminho fechado): larga e vai pra outra
			_manut_alvo = null
			_manut_andando = 0.0
			_decision_timer = 0.0
		return
	_manut_andando = 0.0
	_moving = false
	_manut_t += delta * work_mult()
	_work_timer = 0.2  # a animação de consertar
	if _manut_t >= mt.segundos_de(_manut_alvo):
		mt.preventiva_feita(_manut_alvo, self)
		_popup("Manutenção feita: %s" % _manut_alvo.manut_titulo(), Color(0.6, 1.0, 0.7))
		_manut_alvo = null
		_manut_t = 0.0
		_decision_timer = 0.0


# ------------------------------------------------------------ expedições (Bloco 104)
## A expedicoes.gd mandou: anda até a saída (lá ela tira do mundo).
func vai_pra_expedicao(saida: Vector2) -> void:
	_expedicao_saida = saida
	_manual_timer = 0.0
	_decision_timer = 0.0


## Some do mundo: escondido, sem processar, fora do grupo da vila (não come, não trabalha, não defende). A cama fica.
func sai_do_mundo() -> void:
	if fora:
		return
	fora = true
	_expedicao_saida = Vector2.INF
	_release_station()
	if _ai_state != "idle":
		_set_state("idle")
	_moving = false
	velocity = Vector2.ZERO
	remove_from_group("ipezinhos")
	add_to_group("expedicao_gente")
	_camadas_colisao = Vector2i(collision_layer, collision_mask)
	collision_layer = 0
	collision_mask = 0
	_agent.avoidance_enabled = false
	visible = false
	var main := get_tree().get_first_node_in_group("game_main")
	if main and main.has_method("is_selected") and main.is_selected(self):
		main.toggle_selected(self)
	process_mode = Node.PROCESS_MODE_DISABLED


## Volta da expedição: aparece na saída e anda pra vila como sempre.
func volta_ao_mundo(pos: Vector2) -> void:
	if not fora:
		return
	fora = false
	process_mode = Node.PROCESS_MODE_INHERIT
	global_position = pos
	_target = pos
	visible = true
	remove_from_group("expedicao_gente")
	add_to_group("ipezinhos")
	if _camadas_colisao.x >= 0:
		collision_layer = _camadas_colisao.x
		collision_mask = _camadas_colisao.y
	_agent.avoidance_enabled = avoidance_enabled
	_agent.target_position = pos
	wake_decision()


## Morreu longe (a expedição volta sem ele): o memorial e o luto como sempre, mas sem corpo pro padre buscar.
func morre_na_expedicao(regiao: String) -> void:
	set_meta("sem_corpo", true)
	injury_cause = "expedicao: " + regiao
	process_mode = Node.PROCESS_MODE_INHERIT
	_die()


## Bloco 104: o batedor escolhe pra onde olhar: as tocas (rastrear) e a beira da clareira/floresta.
func _batendo() -> void:
	if not _bate.is_empty():
		var p: Vector2 = _bate.pos
		if float(_bate.t) <= 0.0 and global_position.distance_to(p) > 20.0 and (not _moving or _target.distance_to(p) > 4.0):
			_go_to(p)
		return
	var pontos: Array = []
	var env := get_tree().get_first_node_in_group("environment")
	for t in get_tree().get_nodes_in_group("caca"):
		if t.visible and not (env and env.has_method("trancado") and env.trancado(t.global_position)):
			pontos.append({"pos": (t as Node2D).global_position + Vector2(0, 40), "toca": t})
	if env and env.get("clearing_rect") != null:
		var r: Rect2 = env.clearing_rect
		for i in 3:
			pontos.append({"pos": Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y)), "toca": null})
	if pontos.is_empty():
		_idle_at_hub()
		return
	var esc: Dictionary = pontos[randi() % pontos.size()]
	_bate = {"pos": NavigationServer2D.map_get_closest_point(_agent.get_navigation_map(), esc.pos), "t": 0.0, "toca": esc.toca}
	_go_to(_bate.pos)


## Bloco 104: chegou no ponto: olha de luneta um tempo; na toca, deixa ela "rastreada" no dia (nascem mais bichos).
func _bate_tick(delta: float) -> void:
	if _bate.is_empty():
		return
	var p: Vector2 = _bate.pos
	if float(_bate.t) <= 0.0 and (_moving and global_position.distance_to(p) > 24.0):
		return
	_moving = false
	_bate.t = float(_bate.t) + delta
	_work_timer = 0.2  # a animação de bater (a luneta)
	if float(_bate.t) >= segundos_bater:
		var t = _bate.toca
		if t != null and is_instance_valid(t) and t.has_method("rastreia"):
			t.rastreia()
			_popup("Rastro fresco!", Color(0.8, 0.95, 0.6))
		_bate = {}
		_decision_timer = 0.0


# ------------------------------------------------------------ carpinteiro, mochila, botas (Bloco 94)
## Tem a mochila de couro (pegou uma no armazém): carrega mochila_carga a mais de minério.
var tem_mochila := false
var _casa_cama: Node = null
var _monta_ini := -1.0


## Minério que cabe numa viagem (com a mochila, mais).
func capacidade_carga() -> float:
	return cargo_capacity + (mochila_carga if tem_mochila else 0.0)


## Armazém chama quando o minerador entrega: sem mochila e com uma no armazém, ele pega.
func pega_mochila(arm: Node) -> void:
	if tem_mochila or not is_miner():
		return
	var eco := get_tree().get_first_node_in_group("economy")
	if eco == null or eco.quantidade("mochila") < 1.0:
		return
	if arm.take_item("mochila", 1.0) < 1.0 and eco.take_item("mochila", 1.0) < 1.0:
		return
	tem_mochila = true
	_popup("Pegou uma mochila: +%d de carga" % roundi(mochila_carga), Color(0.55, 1.0, 0.5))


## A neve (inverno, superfície) atrasa quem anda sem botas. 1.0 = sem efeito.
func _neve_mult() -> float:
	var eq := _equipment()
	if eq == null or _inside or wearing.has("botas") or not eq.is_cold_at(global_position):
		return 1.0
	return eq.neve_speed_mult


## A casa mais perto com cama de tábua esperando montagem (reservada pra ele), ou null.
func _casa_pra_cama() -> Node:
	if _casa_cama != null and is_instance_valid(_casa_cama) and _casa_cama.camas_a_montar() > 0:
		return _casa_cama
	_casa_cama = null
	var d_min := INF
	for c in get_tree().get_nodes_in_group("casas"):
		if not c.has_method("camas_a_montar") or c.camas_a_montar() <= 0:
			continue
		var outro = c.get("montador")
		if outro != null and outro != self and is_instance_valid(outro) and outro.is_carpenter():
			continue  # outro carpinteiro já está nela
		var d := global_position.distance_to(c.global_position)
		if d < d_min:
			d_min = d
			_casa_cama = c
	if _casa_cama:
		_casa_cama.montador = self
	return _casa_cama


## Vai até a porta da casa e monta a cama de tábua (casa.cama_segundos, serrando/martelando); a cama entra na
## primeira cama comum da casa (casa.instala_cama_boa).
func _montar_cama() -> void:
	var c := _casa_pra_cama()
	if c == null:
		_monta_ini = -1.0
		_decision_timer = 0.0
		return
	var dest: Vector2 = c.porta_montagem()
	if global_position.distance_to(dest) > 14.0:
		if _ai_state != "montando_cama":
			_release_station()
			_set_state("montando_cama")
		if not _moving or _target.distance_to(dest) > 2.0:
			_go_to(dest)
		_monta_ini = -1.0
		return
	if _ai_state != "montando_cama":
		_set_state("montando_cama")
	_moving = false
	var agora := Time.get_ticks_msec() / 1000.0
	if _monta_ini < 0.0:
		_monta_ini = agora
	_work_timer = decision_interval * 1.2  # serrando e martelando na porta
	if (agora - _monta_ini) * Engine.time_scale >= float(c.cama_segundos) / maxf(work_mult(), 0.1):
		_monta_ini = -1.0
		if c.instala_cama_boa():
			_popup("Cama nova montada!", Color(0.55, 1.0, 0.5))
		c.montador = null
		_casa_cama = null
		_decision_timer = 0.0


## Bloco 93: o padre e os mortos (com cemitério). De dia e fora da missa/funeral: vai até o corpo que espera (o
## mais perto, reservado pra ele), pega (o corpo sai do chão e vai nos ombros: iso_bonecos "corpo"), leva até a
## vaga do cemitério com lugar e enterra (enterro_tempo segundos, rezando: a animação "pregar"); a cruz ou a
## lápide aparece (cemiterio.enterra) e, com os ritos, o funeral é marcado (calendario.on_enterro).
## Devolve true enquanto está nisso.
func _padre_enterro(cal: Node) -> bool:
	if _is_night() or cal.pregando_agora():
		return false
	var dest_cem: Node = cal.cemiterio_com_vaga(global_position)
	if not carregando_corpo.is_empty():
		if dest_cem == null:
			_larga_corpo()  # (o cemitério encheu ou sumiu)
			return false
		var vaga: Vector2 = dest_cem.vaga_pos()
		if global_position.distance_to(vaga) > cal.enterro_alcance:
			if _ai_state != "levando_corpo":
				_release_station()
				_set_state("levando_corpo")
			if not _moving or _target.distance_to(vaga) > 2.0:
				_go_to(vaga)
			_enterro_ini = -1.0
			return true
		if _ai_state != "enterrando":
			_set_state("enterrando")
			_moving = false
		if _enterro_ini < 0.0:
			_enterro_ini = Time.get_ticks_msec() / 1000.0
		_work_timer = decision_interval * 1.2  # rezando na cova
		if Time.get_ticks_msec() / 1000.0 - _enterro_ini >= cal.enterro_tempo / maxf(Engine.time_scale, 0.01):
			var info := carregando_corpo.duplicate()
			carregando_corpo = {}
			_enterro_ini = -1.0
			dest_cem.enterra(info)
			cal.on_enterro(String(info.get("nome", "?")))
			_work_timer = 0.0
			_decision_timer = 0.0
		return true
	if dest_cem == null:
		return false
	if _corpo_alvo == null or not is_instance_valid(_corpo_alvo) or not _corpo_alvo.livre_pra(self):
		_corpo_alvo = null
		for c in get_tree().get_nodes_in_group("corpos"):
			if c.livre_pra(self) and (_corpo_alvo == null or c.global_position.distance_to(global_position) < _corpo_alvo.global_position.distance_to(global_position)):
				_corpo_alvo = c
	if _corpo_alvo == null:
		return false
	_corpo_alvo.reservado_por = self
	if global_position.distance_to(_corpo_alvo.global_position) > cal.enterro_alcance:
		if _ai_state != "buscando_corpo":
			_release_station()
			_set_state("buscando_corpo")
		if not _moving or _target.distance_to(_corpo_alvo.global_position) > 2.0:
			_go_to(_corpo_alvo.global_position)
		return true
	carregando_corpo = _corpo_alvo.info()  # pegou: vai nos ombros
	_corpo_alvo.get_parent().remove_child(_corpo_alvo)
	_corpo_alvo.queue_free()
	_corpo_alvo = null
	_popup("Levando %s" % String(carregando_corpo.get("nome", "")), Color(0.85, 0.82, 0.95))
	_decision_timer = 0.0
	return true


## O corpo que ele carrega volta pro chão onde ele está (outra emergência, trocou de função, morreu).
func _larga_corpo() -> void:
	var cal := get_tree().get_first_node_in_group("calendario") if is_inside_tree() else null
	if cal and not carregando_corpo.is_empty():
		var c: Node2D = cal.CORPO.new()
		c.monta(carregando_corpo)
		c.position = global_position + Vector2(8, 4)
		var hub := get_tree().get_first_node_in_group("village_hub")
		(hub.get_parent() if hub else get_parent()).add_child(c)
	carregando_corpo = {}
	_enterro_ini = -1.0
	_corpo_alvo = null


## Bloco 92: por que ESTE ipezinho não pode virar padre agora ("" = pode): só homem; um padre por vila; e a
## função abre no estágio do padre (calendario.padre_estagio).
func motivo_padre() -> String:
	if is_priest():
		return ""
	if String(gender) != "menino":
		return "Só homem pode ser padre"
	var cal := get_tree().get_first_node_in_group("calendario") if is_inside_tree() else null
	if cal:
		var pd: Node = cal.padre()
		if pd != null and pd != self:
			return "A vila já tem padre (%s): tire a função dele primeiro" % String(pd.get("display_name"))
		var hub := get_tree().get_first_node_in_group("village_hub")
		if hub and int(hub.level) < int(cal.padre_estagio):
			return "O padre só vem com a Vila no estágio %d" % int(cal.padre_estagio)
	return ""


## A fornalha dele: a que tem as unidades que ele começou; senão a mais perto com ordem.
func _fornalha_alvo() -> Node:
	var grupo := _grupo_oficina()  # Bloco 94/107: a oficina de ordens da função
	if _fornalha != null and is_instance_valid(_fornalha) and _fornalha.fila.tem_trabalho() and _fornalha.is_in_group(grupo):
		return _fornalha
	_fornalha = null
	var d_min := INF
	for f in get_tree().get_nodes_in_group(grupo):
		if not f.fila.tem_trabalho():
			continue
		var d := global_position.distance_to(f.global_position)
		if d < d_min:
			d_min = d
			_fornalha = f
	return _fornalha


## Bloco 107: o grupo da oficina de ordens da função (fundidor: fornalhas; carpinteiro: carpintarias; lenhador: carvoarias;
## caçador: curtumes). O lenhador e o caçador só operam quando a oficina tem ORDEM (senão, o trabalho de sempre).
func _grupo_oficina() -> String:
	if is_carpenter():
		return "carpintarias"
	if is_lumber():
		return "carvoarias"
	if is_hunter():
		return "curtumes"
	return "fornalhas"


## Bloco 107: o lenhador (carvoaria) e o caçador (curtume) operam a oficina quando ela tem ordem. "" = nada a fazer lá
## (segue o trabalho de sempre). Só UM por vez começa uma leva nova; quem já está com o trabalho começado continua.
func _estado_oficina_extra() -> String:
	var f := _fornalha_alvo()
	if f == null:
		return "buscando_insumo" if not barras_mao.is_empty() else ""
	if not f.e_operador(self):
		return ""
	# quem já é o operador (indo buscar insumo, trabalhando ou com o que ficou pronto na mão) continua; os outros seguem o
	# trabalho de sempre (só UM opera a oficina)
	var sou_o_operador := _ai_state in [f.estado_trabalho, "buscando_insumo"] or not barras_mao.is_empty()
	if not sou_o_operador and _outro_opera(f):
		return ""
	var e := _estado_fundidor()
	return "" if e == "idle" else e


## Outro ipezinho já está operando essa oficina (indo buscar insumo, ou trabalhando)?
func _outro_opera(f: Node) -> bool:
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		if w != self and w.get("_fornalha") == f and w.get_state() in [f.estado_trabalho, "buscando_insumo"]:
			return true
	return false


## A decisão do fundidor (no horário de trabalho): fundir as unidades começadas; buscar insumos (e largar as
## barras) no armazém; com a ordem pausada (falta insumo) ou sem ordem, espera.
func _estado_fundidor() -> String:
	var f := _fornalha_alvo()
	var tem_barra := not barras_mao.is_empty()
	if f == null:
		return "buscando_insumo" if tem_barra else "idle"
	if f.fila.comecadas() > 0:
		return f.estado_trabalho  # "fundindo" / "serrando" (Bloco 94)
	if tem_barra:
		return "buscando_insumo"
	# Bloco 105: com carregador, ele traz os insumos e leva as barras; sem ninguém pegar a tempo, o operador vai
	var lg := _logistica()
	if not (f.barras_prontas as Dictionary).is_empty() and not (lg and lg.deixa_pro_carregador("barras", f)):
		pega_barras(f.barras_prontas.duplicate())
		f.barras_prontas.clear()
		return "buscando_insumo"
	if f.fila.a_caminho() > 0:
		return "idle"  # o carregador vem trazendo
	if f.fila.a_comecar() > 0 and f.falta() == "":
		if lg and lg.deixa_pro_carregador("insumo", f):
			return "idle"
		return "buscando_insumo"
	return "idle"  # pausada (falta insumo): espera; nada é gasto


## Armazém chama quando ele chega pra "buscar insumo": larga as barras e, no horário de trabalho, COMEÇA a
## próxima leva (os insumos saem do armazém só agora).
func na_armazem_fundidor(arm: Node) -> void:
	if _visita_feita:
		return
	_visita_feita = true
	var eco := get_tree().get_first_node_in_group("economy")
	for item in barras_mao:
		arm.add_item(item, float(barras_mao[item]))
	if not barras_mao.is_empty():
		_popup("+%s" % ", ".join(barras_mao.keys().map(func(k): return "%d %s" % [int(barras_mao[k]), Items.nome(k).to_lower()])), Color(0.55, 1.0, 0.5))
	barras_mao.clear()
	var f := _fornalha_alvo()
	if f and periodo_agenda() in ["trabalho", "", "cafe", "almoco"] and f.fila.comecadas() == 0:
		var n: int = f.fila.comecar_unidades(f.lote, eco)
		if n > 0:
			_popup("Pegou insumos: %d x (%s)" % [n, f.fila.texto_insumos(f.fila.atual().receita)], Color(1.0, 0.85, 0.45))
	_decision_timer = 0.0


## Fornalha chama quando sai barra: ela vai pras mãos dele.
func pega_barras(pronto: Dictionary) -> void:
	for item in pronto:
		barras_mao[item] = barras_mao.get(item, 0.0) + float(pronto[item])
	if _fornalha_alvo() == null or (_fornalha != null and _fornalha.fila.comecadas() <= 0):
		_decision_timer = 0.0  # acabou a leva: leva as barras e busca mais


## Fornalha chama a cada quadro com ele fundindo (anima o martelo, como na obra).
func fundir_tick() -> void:
	_work_timer = 0.2


## Bloco 84: a carga que ele ainda tem pra largar no armazém (o estado de entregar), "" = nada.
func _entrega_pendente() -> String:
	# Bloco 97: todos os armazéns cheios = a entrega não acaba nunca; fica com a carga e segue a agenda
	# (festival, funeral, dormir) — entrega amanhã no expediente, quando tiver espaço
	# Bloco 106: por compartimento (o cheio não prende; os outros entregam)
	if wood_carrying > 0.0 and not _sem_espaco("madeira"):
		return "hauling"
	if raw_carrying > 0.0 and not is_cook() and not _sem_espaco("alimentos"):
		return "stocking"
	if carrying > 0.0 and not is_researcher() and not _sem_espaco("minerios"):
		return "storing"
	if not barras_mao.is_empty():
		return "buscando_insumo"  # Bloco 86: o fundidor leva as barras (sem começar leva nova fora de hora)
	return ""


## Olha a agenda de tempos em tempos: virou o período? Decide já, e confere se perdeu a refeição.
func _agenda_tick(delta: float) -> void:
	_agenda_t -= delta
	if _agenda_t > 0.0:
		return
	_agenda_t = 0.25
	var p := periodo_agenda()
	if p == _periodo:
		return
	_fim_de_periodo(_periodo)
	_periodo = p
	wake_decision()


## Acabou um período de refeição: com fome e sem ter comido = perdeu (rende menos até comer).
## (Quem está a caminho do prato não perde; ferido/caído não conta.)
func _fim_de_periodo(antes: String) -> void:
	var s := _schedule()
	if s == null or antes == "":
		return
	var m: String = s.refeicao_do(antes)
	if m == "" or refeicoes_hoje.has(m) or injured or downed:
		return
	if _ai_state == "eating" and _refeicao_alvo == m:
		return
	if hunger >= hunger_max * s.refeicao_dispensa:
		return  # sem fome: pular não faz falta
	refeicoes_perdidas += 1
	_popup("Perdi o %s!" % s.nome_refeicao(m), Color(1.0, 0.6, 0.4))


## Comedouro: ele chegou pra comer e ainda não pegou o prato?
func quer_prato() -> bool:
	return _ai_state == "eating" and not _servido


## Comedouro serviu UMA porção (fome que ela restaura). Conta a refeição da hora.
func recebe_prato(fome: float) -> void:
	_servido = true
	_prato = maxf(fome, 0.0)
	if _refeicao_alvo != "":
		refeicoes_hoje[_refeicao_alvo] = true
		refeicoes_perdidas = 0


## Comedouro chama a cada quadro: come até `maximo` do prato. Retorna quanto comeu.
func come_prato(maximo: float) -> float:
	if _prato <= 0.0:
		return 0.0
	var c := minf(maximo, _prato)
	_prato -= c
	feed(c)
	if hunger >= hunger_max:
		_prato = 0.0  # (cheio: o resto fica no prato)
	if _prato <= 0.0:
		_decision_timer = 0.0  # acabou: decide o próximo passo já
	return c


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
	var space := capacidade_carga() - carrying
	var taken: float = minf(amount * mult_mineracao(), space)  # zangado minera menos; explosivos e a picareta de aço
	if ore_type in ["solarita", "cristal_verde", "cristal_rubro"] and taken > 0.0:
		var diary := get_tree().get_first_node_in_group("diary")
		if diary:
			diary.unlock("solarita" if ore_type == "solarita" else "cristais")
	carrying += taken
	if taken > 0.0:
		_work_timer = 0.2
		_roll_injury(taken)
		_area_registra(taken)  # Bloco 77
	if carrying >= capacidade_carga() - 0.01:
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
		_anim_time += delta * walk_anim_fps * clampf(spd / speed, 0.0, 1.6)  # devagar = passo devagar
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
			if item == HAMMER:
				Audio.build_hit(global_position)  # Bloco 55: martelo na madeira da obra
			elif item == _pickaxe():
				Audio.pick(global_position)  # picareta na pedra
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
	_carry_icon.visible = (carrying > 0.0 or food_carrying > 0.0 or wood_carrying > 0.0 or raw_carrying > 0.0 or not material_mao.is_empty()) and not _resting
	if not material_mao.is_empty():
		_carry_icon.texture = _icone_material()  # Bloco 96: o material da obra (tora, pedra de minério, o item)
	elif wood_carrying > 0.0:
		_carry_icon.texture = WOOD_LOG
	elif food_carrying > 0.0:
		_carry_icon.texture = FOOD_BASKET
	elif raw_carrying > 0.0:
		_carry_icon.texture = RAW_FOOD
	elif carrying > 0.0 and (_carry_icon.texture in [FOOD_BASKET, WOOD_LOG, RAW_FOOD] or _carry_icon.has_meta("_material")):
		_carry_icon.texture = Ores.CHUNK_TEXTURES.get(cargo_type, _carry_icon.texture)
	if _carry_icon.visible:
		var r := carrying / capacidade_carga()
		if not material_mao.is_empty():
			r = minf(_material_qtd(material_mao) / maxf(carga_material, 1.0), 1.0)
		elif wood_carrying > 0.0:
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
		"funcao_secundaria": funcao_secundaria,  # Bloco 109
		"tracos": tracos.duplicate(), "habilidade": habilidade.duplicate(), "animo_casamento": animo_casamento,  # Bloco 110
		"fase": fase, "idade_s": idade_s, "pais": pais.duplicate(), "filhos": filhos.duplicate(), "gravidez_s": gravidez_s,
		"pai_bebe": pai_bebe, "resguardo_s": resguardo_s, "estudo": estudo, "mentor": mentor,  # Bloco 111
		"weapon": weapon,
		"weapon_durability": weapon_durability,
		"broken_weapon": broken_weapon,
		"got_porrete": got_porrete,
		"downed": downed,
		"downed_gate": downed_gate,
		"wearing": wearing.duplicate(),
		"leather_carrying": leather_carrying,
		"operates_coletor": _my_coletor() != null,
		"coletor_pos": SaveUtil.vec2_to_array(_my_coletor().global_position) if _my_coletor() != null else [],  # Bloco 47
		"coletor_minerio_pos": SaveUtil.vec2_to_array(_my_coletor_minerio().global_position) if _my_coletor_minerio() != null else [],  # Bloco 57
		"hunt_kills": hunt_kills,  # Bloco 61
		"nota_campo": nota_campo,  # Bloco 102
		"xp_pesquisa": xp_pesquisa,  # Bloco 103
		"entrega_mao": entrega_mao.duplicate(),  # Bloco 105 (o carregador: volta pro armazém ao carregar)
		"animo_descoberta": animo_descoberta,
		"animo_prato": animo_prato,  # Bloco 107
		"area_id": work_area.id if work_area != null else 0,  # Bloco 77
		"refeicoes_hoje": refeicoes_hoje.keys(),  # Bloco 84
		"refeicoes_perdidas": refeicoes_perdidas,
		"animo_social": animo_social,  # Bloco 85
		"animo_fe": animo_fe,  # Bloco 88
		"barras_mao": barras_mao.duplicate(),  # Bloco 86
		"material_mao": material_mao.duplicate(),  # Bloco 96 (volta pro armazém ao carregar)
		"mochila": tem_mochila,  # Bloco 94
	}


func _religa_area(id: int) -> void:
	var wa := _work_areas()
	if wa:
		wa.religar(self, id)


## Aplicado no _ready (via pending_save_data). A IA recomeça do zero e decide sozinha.
func load_save_data(d: Dictionary) -> void:
	hunger = clampf(SaveUtil.num(d, "hunger", hunger_max), 0.0, hunger_max)
	# Bloco 84 (save antigo: nenhuma refeição feita hoje, nenhuma perdida)
	refeicoes_hoje = {}
	for m in SaveUtil.array(d, "refeicoes_hoje"):
		if m in ["cafe", "almoco", "jantar"]:
			refeicoes_hoje[m] = true
	refeicoes_perdidas = clampi(SaveUtil.integer(d, "refeicoes_perdidas", 0), 0, 10)
	animo_social = clampf(SaveUtil.num(d, "animo_social", 0.0), 0.0, 50.0)  # Bloco 85 (save antigo: 0)
	animo_fe = clampf(SaveUtil.num(d, "animo_fe", 0.0), 0.0, 50.0)  # Bloco 88 (save antigo: 0)
	barras_mao = {}  # Bloco 86 (save antigo: nada na mão)
	var bm := SaveUtil.dict(d, "barras_mao")
	for k in bm:
		if Items.onde(String(k)) == "itens" and float(bm[k]) > 0.0:
			barras_mao[String(k)] = float(bm[k])
	tem_mochila = SaveUtil.boolean(d, "mochila", false)  # Bloco 94 (save antigo: sem mochila)
	# Bloco 96: o material que estava na mão de um engenheiro volta pro armazém (a obra pede de novo): nada se
	# perde nem duplica. Save antigo: nada na mão.
	material_mao = {}
	material_pedido = {}
	_material_obra = null
	var mm := SaveUtil.dict(d, "material_mao")
	if not mm.is_empty():
		_devolve_material_salvo.call_deferred(mm)
	carrying = clampf(SaveUtil.num(d, "carrying", 0.0), 0.0, capacidade_carga())
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
	var sec := SaveUtil.text(d, "funcao_secundaria", "")  # Bloco 109 (save antigo: automática pela função)
	funcao_secundaria = sec if sec in SECUNDARIAS else ""
	# Bloco 110 (save antigo: sem traços — sorteia na primeira pergunta —, sem habilidade)
	tracos = SaveUtil.array(d, "tracos").filter(func(x): return x is String and x in load("res://scripts/core/relacoes.gd").TRACOS)
	habilidade = {}
	var hab := SaveUtil.dict(d, "habilidade")
	for k in hab:
		habilidade[String(k)] = clampf(float(hab[k]), 0.0, 1.0)
	animo_casamento = maxf(SaveUtil.num(d, "animo_casamento", 0.0), 0.0)
	# Bloco 111 (save antigo: todo mundo adulto, sem família)
	var fs := SaveUtil.text(d, "fase", "adulto")
	fase = fs if fs in ["bebe", "crianca", "aprendiz", "adulto"] else "adulto"
	idade_s = maxf(SaveUtil.num(d, "idade_s", 0.0), 0.0)
	pais = SaveUtil.array(d, "pais").map(func(x): return String(x))
	filhos = SaveUtil.array(d, "filhos").map(func(x): return String(x))
	gravidez_s = SaveUtil.num(d, "gravidez_s", -1.0)
	pai_bebe = SaveUtil.text(d, "pai_bebe", "")
	resguardo_s = maxf(SaveUtil.num(d, "resguardo_s", 0.0), 0.0)
	estudo = clampf(SaveUtil.num(d, "estudo", 0.0), 0.0, 1.0)
	mentor = SaveUtil.text(d, "mentor", "")
	combat_skill = clampf(SaveUtil.num(d, "combat_skill", 0.0), 0.0, 2.0)  # Bloco 108: acima de 1,0 = treinamento (cai sozinho fora dele)
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
		if k in ["casaco", "gas", "calor", "radiacao", "botas"] and (wd[k] is float or wd[k] is int) and float(wd[k]) > 0.0:
			wearing[k] = float(wd[k])
	leather_carrying = maxf(SaveUtil.num(d, "leather_carrying", 0.0), 0.0)
	if SaveUtil.boolean(d, "operates_coletor", false):
		_relink_coletor.call_deferred(SaveUtil.vec2(d, "coletor_pos", Vector2.INF))  # Bloco 45/47
	hunt_kills = maxi(SaveUtil.integer(d, "hunt_kills", 0), 0)  # Bloco 61
	nota_campo = SaveUtil.text(d, "nota_campo", "")  # Bloco 102 (save antigo: nenhuma)
	xp_pesquisa = maxi(SaveUtil.integer(d, "xp_pesquisa", 0), 0)  # Bloco 103 (save antigo: 0)
	var em := SaveUtil.dict(d, "entrega_mao")  # Bloco 105: o que um carregador levava volta pro armazém (a entrega recomeça)
	if not em.is_empty():
		_devolve_entrega.call_deferred(em)
	animo_descoberta = clampf(SaveUtil.num(d, "animo_descoberta", 0.0), 0.0, 50.0)
	animo_prato = clampf(SaveUtil.num(d, "animo_prato", 0.0), 0.0, 50.0)  # Bloco 107 (save antigo: 0)
	var area_id := SaveUtil.integer(d, "area_id", 0)  # Bloco 77 (save antigo: sem área)
	if area_id > 0:
		_religa_area.call_deferred(area_id)
	var cm_pos := SaveUtil.vec2(d, "coletor_minerio_pos", Vector2.INF)
	if cm_pos != Vector2.INF:
		_relink_coletor_minerio.call_deferred(cm_pos)  # Bloco 57
	downed = injured and injury_severity == "grave" and SaveUtil.boolean(d, "downed", false)
	downed_gate = SaveUtil.text(d, "downed_gate", "") if downed else ""
	if downed_gate != "" and def != null and def.gate(downed_gate) == null:
		downed_gate = ""  # Bloco 80: save antigo caído no portão do poço (que saiu): sem brecha
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
