extends RefCounted
## Bloco 54: TECLAS REMAPEÁVEIS. Cada atalho do jogo é uma AÇÃO com tecla padrão (as de sempre);
## o jogador troca em Configurações > Teclas e a escolha fica no settings.cfg ([teclas] ação=código).
## main.gd pergunta acao(tecla) em vez de comparar códigos fixos.
##   Teclas.acao(KEY_1) -> "minerador"     Teclas.tecla("minerador") -> KEY_1     Teclas.nome("minerador") -> "1"

const Settings := preload("res://scripts/core/settings.gd")
## ação -> teclas padrão (a 1ª é a principal; as outras são atalhos extras fixos, como o teclado numérico)
const PADRAO := {
	"construir": [KEY_SPACE], "minerador": [KEY_1, KEY_KP_1], "cacador": [KEY_2, KEY_KP_2], "medico": [KEY_3, KEY_KP_3],
	"engenheiro": [KEY_4, KEY_KP_4], "cozinheiro": [KEY_C], "lenhador": [KEY_L], "guarda": [KEY_X], "pesquisador": [KEY_Z],
	"sem_funcao": [KEY_0, KEY_KP_0], "turno_extra": [KEY_T], "vender": [KEY_V], "recrutar": [KEY_R],
	"proximo": [KEY_TAB], "seguir": [KEY_F], "pausa": [KEY_P], "dicas": [KEY_H], "musica": [KEY_M],
	"painel_hub": [KEY_U], "painel_escavadeira": [KEY_E], "painel_oficina": [KEY_O], "painel_enfermaria": [KEY_I],
	"painel_moral": [KEY_B], "painel_defesa": [KEY_G], "painel_diario": [KEY_J], "painel_lab": [KEY_Q], "painel_sol": [KEY_Y],
	"painel_trabalho": [KEY_5, KEY_KP_5],
	"fundidor": [KEY_6, KEY_KP_6],  # Bloco 86
	"ferreiro": [KEY_7, KEY_KP_7],  # Bloco 87
	"padre": [KEY_8, KEY_KP_8],  # Bloco 92
	"carpinteiro": [KEY_9, KEY_KP_9],  # Bloco 94
	"salvar": [KEY_F5], "carregar": [KEY_F9],
	# fixas (não aparecem pra remapear): Esc, e as de teste/depuração
	"voltar": [KEY_ESCAPE], "caixas": [KEY_F4], "pular_fase": [KEY_N], "machucar": [KEY_K],
}
## Teclas que não podem virar atalho (câmera WASD/setas/Home, tela cheia, corte da mina, debug, Esc).
const RESERVADAS := [KEY_ESCAPE, KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_HOME,
	KEY_F2, KEY_F3, KEY_F11, KEY_ENTER, KEY_KP_ENTER, KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]
## Nome de cada ação na tela de configurações (a ordem é a da lista).
const NOMES := [
	["construir", "Menu de construção"], ["minerador", "Função: minerador"], ["cacador", "Função: caçador"],
	["medico", "Função: médico"], ["engenheiro", "Função: engenheiro"], ["cozinheiro", "Função: cozinheiro"],
	["lenhador", "Função: lenhador"], ["guarda", "Função: guarda"], ["pesquisador", "Função: pesquisador"],
	["fundidor", "Função: fundidor"], ["ferreiro", "Função: ferreiro"], ["padre", "Função: padre (só um)"], ["carpinteiro", "Função: carpinteiro"],
	["sem_funcao", "Tirar a função"], ["turno_extra", "Turno extra"], ["vender", "Vender minério"], ["recrutar", "Recrutar"],
	["proximo", "Próximo ipezinho"], ["seguir", "Câmera segue"], ["pausa", "Pausa"], ["dicas", "Atalhos (ajuda)"],
	["musica", "Música liga/desliga"], ["painel_hub", "Centro da Vila"], ["painel_escavadeira", "Escavadeira"],
	["painel_oficina", "Oficina"], ["painel_enfermaria", "Enfermaria"], ["painel_moral", "Bem-estar"],
	["painel_defesa", "Defesa"], ["painel_diario", "Diário"], ["painel_lab", "Laboratório"], ["painel_sol", "O Sol"],
	["painel_trabalho", "Trabalhadores (áreas de trabalho)"],
	["salvar", "Salvar"], ["carregar", "Carregar"],
]

static var _por_tecla: Dictionary = {}
static var _principal: Dictionary = {}


static func _carrega() -> void:
	if not _por_tecla.is_empty():
		return
	_principal.clear()
	for a in PADRAO:
		_principal[a] = int(Settings.get_value("teclas", a, int(PADRAO[a][0])))
	for a in PADRAO:
		var extras: Array = PADRAO[a].slice(1)
		for k in extras:
			_por_tecla[int(k)] = a
	for a in _principal:
		_por_tecla[int(_principal[a])] = a  # a principal (talvez trocada) ganha das extras


## A ação dessa tecla ("" = nenhuma).
static func acao(keycode: int) -> String:
	_carrega()
	return _por_tecla.get(keycode, "")


static func tecla(nome_acao: String) -> int:
	_carrega()
	return int(_principal.get(nome_acao, KEY_NONE))


## Nome da tecla na tela (as teclas são físicas: a posição no teclado, qualquer layout).
static func nome(nome_acao: String) -> String:
	return nome_tecla(tecla(nome_acao))


static func nome_tecla(k: int) -> String:
	if k == KEY_SPACE:
		return "Espaço"
	var logical := DisplayServer.keyboard_get_keycode_from_physical(k) if DisplayServer.get_name() != "headless" else k
	return OS.get_keycode_string(logical if logical != KEY_NONE else k)


## Pode usar essa tecla pra uma ação?
static func permitida(keycode: int) -> bool:
	return keycode != KEY_NONE and not keycode in RESERVADAS


## Troca a tecla de uma ação. Se outra ação usava essa tecla, as duas trocam entre si.
static func define(nome_acao: String, keycode: int) -> void:
	_carrega()
	if not PADRAO.has(nome_acao) or not permitida(keycode):
		return
	var antiga := tecla(nome_acao)
	for a in _principal:
		if a != nome_acao and int(_principal[a]) == keycode:
			_principal[a] = antiga
			Settings.set_value("teclas", a, antiga)
	_principal[nome_acao] = keycode
	Settings.set_value("teclas", nome_acao, keycode)
	_por_tecla.clear()
	_recalcula()


static func restaura_padrao() -> void:
	for a in PADRAO:
		Settings.set_value("teclas", a, int(PADRAO[a][0]))
	_por_tecla.clear()
	_principal.clear()
	_carrega()


static func _recalcula() -> void:
	for a in PADRAO:
		for k in PADRAO[a].slice(1):
			_por_tecla[int(k)] = a
	for a in _principal:
		_por_tecla[int(_principal[a])] = a
