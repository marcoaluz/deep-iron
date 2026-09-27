extends Node
## Autoload "SaveManager": salvar/carregar o progresso em JSON (user://savegame.json).
##
## Cada sistema expõe get_save_data() -> Dictionary e load_save_data(data) -> void;
## aqui só se junta tudo, escreve/lê o arquivo e decide QUANDO salvar:
##   - F5 salva, F9 carrega (teclas tratadas no main.gd);
##   - autosave a cada autosave_interval segundos (0 = desligado);
##   - ao fechar a janela (NOTIFICATION_WM_CLOSE_REQUEST).
## Ajuste os números na cena res://scenes/core/save_manager.tscn (Inspector).
##
## ---------------------------------------------------------------------------
## INVENTÁRIO — estado que só vivia em memória e agora vai pro save
## (nomes reais das variáveis; "nome do nó" = chave usada pra achar o objeto):
##
##   economy.gd (nó Economy)
##     credits, recruited_count (custo do próximo recrutamento), total_earned,
##     max_workers (a melhoria Moradias aumenta em tempo de jogo), auto_sell.
##     Preços (ore_price, copper_price, coal_price) são fixos no Inspector: não vão.
##   day_night.gd (nó DayNight)
##     day, time. (_night é recalculado a partir de time.)
##   centro_vila.gd (Centro da Vila)
##     level (estágio 1-5), upgrades {moradias, enfermaria, trilhas}.
##     O EFEITO das melhorias já está salvo nos outros sistemas (max_workers,
##     casas construídas); speed_mult/recovery_mult são calculados de upgrades.
##   casa.gd (cada casa, pelo nome do nó)
##     built. Casas POSICIONADAS pelo jogador (Bloco 12) também vão em
##     "placed_houses" [{name, position}] e são recriadas antes dos ipezinhos;
##     as 3 iniciais são fixas na cena e não precisam de posição.
##     Quem dorme em qual cama é salvo no ipezinho (home + home_slot).
##   armazem.gd (cada armazém, pelo nome do nó)
##     stock {ferro, cobre, carvao}, lifetime_stored (marco dos estágios da vila).
##     total_stored é a soma do stock (recalculado).
##   mineral_node.gd (cada jazida, pelo nome do nó)
##     ore_remaining, _cooldown (esgotada/regenerando), variante do sprite
##     (índice da textura + flip, só pra ela não "mudar de cara" ao carregar).
##     _unlocked é recalculado a partir da Oficina.
##   oficina.gd (Oficina)
##     crafted {picareta_aco, lampiao}, crafting, craft_left.
##     Quais minérios estão liberados sai de crafted (TOOL_UNLOCKS).
##   escavadeira.gd (Escavadeira)
##     installed {estrutura, motor, hidraulica, cabine, broca}, fabricating, fab_left.
##     complete é recalculado (todas instaladas) e NÃO repete a fanfarra/banner.
##   ipezinho.gd (cada ipezinho — recriados a partir do save)
##     name, posição, hunger, carrying, cargo_type, injured, _recovery_left,
##     _mined_since_roll, _facing, casa (nome do nó) + cama (_home_slot).
##     Estado da IA (_ai_state, estação reservada, ordem manual) NÃO é salvo:
##     ao carregar cada um decide de novo o que fazer (de noite volta pra cama).
##   comedouro.gd (cada comedouro, pelo nome do nó) — Bloco 10
##     food_stock.
##   food_source.gd (horta de cogumelos, pelo nome do nó) — Bloco 10
##     food_remaining, _cooldown.
##   ipezinho.gd — Blocos 9 e 10: anger, overtime, role (cozinheiro), food_carrying.
##   ipezinho.gd — Bloco 11: gender ("menino"/"menina") e look (variação de roupa);
##     save antigo sem esses campos sorteia uma vez e passa a guardar.
##   Bloco 13: armazem.gd wood_stored; tree_node.gd (cada árvore da clareira)
##     wood_remaining + _cooldown; ipezinho.gd role "lenhador" + wood_carrying.
##   camera_controller.gd (Camera2D)
##     posição e zoom (conforto: volta a olhar pro mesmo lugar).
##
##   Fica de fora (transitório ou só visual): timers de som/popup, animações,
##   partículas, seleção atual, _inside das casas, decoração do mapa (vem de
##   map_seed, sempre igual), preferências de áudio.
## ---------------------------------------------------------------------------

signal saved(path: String)
signal loaded
signal save_failed(message: String)

const SAVE_PATH := "user://savegame.json"
const TEMP_PATH := "user://savegame.tmp"
## Novo Jogo com um save existente move o antigo pra cá (não se perde nada sem querer).
const BACKUP_PATH := "user://savegame_backup.json"
## JSON ilegível vai pra cá (pra dar pra investigar), e o jogo começa do zero.
const CORRUPT_PATH := "user://savegame_corrompido.json"
const SAVE_VERSION := 2
## Versão 1 tinha 4 lotes fixos na cena; um lote construído vira casa posicionada no mesmo lugar.
const LEGACY_LOTS := {
	"Lote1": Vector2(-170, 245),
	"Lote2": Vector2(-530, 300),
	"Lote3": Vector2(-80, 370),
	"Lote4": Vector2(-640, 365),
}
const MAIN_SCENE := "res://scenes/game/main.tscn"
const SaveUtil := preload("res://scripts/core/save_util.gd")

## Segundos entre autosaves (0 = desligado). Padrão: 3 minutos.
@export var autosave_interval: float = 180.0
## Salva sozinho ao fechar a janela.
@export var save_on_quit: bool = true

## true = a próxima partida (main.tscn) deve aplicar _pending_data ao ficar pronta.
var pending_load: bool = false
var _pending_data: Dictionary = {}
var _game: Node = null  # nó Main da partida em andamento
var _autosave_timer: float = 0.0
## Já garantimos o backup do save antigo nesta partida nova?
var _backup_checked: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().set_auto_accept_quit(false)  # quem fecha é o _notification abaixo


func _process(delta: float) -> void:
	if not is_game_running() or autosave_interval <= 0.0:
		return
	_autosave_timer += delta
	if _autosave_timer >= autosave_interval:
		_autosave_timer = 0.0
		save_game("autosave")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if save_on_quit and is_game_running():
			save_game("ao fechar")
		get_tree().quit()


# ------------------------------------------------------------ estado do arquivo
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## "none" (não existe), "ok" ou "corrupt" (existe mas não é um JSON de save).
func save_status() -> String:
	if not has_save():
		return "none"
	return "ok" if read_save() != null else "corrupt"


## Lê e valida o arquivo. Retorna o Dictionary ou null se estiver ilegível.
func read_save() -> Variant:
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	if text == "":
		return null
	var json := JSON.new()  # (JSON.parse_string imprime erro no console; assim fica silencioso)
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return null
	return _migrate(json.data)


## Resumo pra tela de Continuar (dia, estágio, população, quando salvou).
func save_summary() -> Dictionary:
	var data = read_save()
	if data == null:
		return {}
	return SaveUtil.dict(data, "summary").merged({"saved_at": SaveUtil.text(data, "saved_at", "?")})


# ------------------------------------------------------------ partida
## Chamado pelo main.gd no _ready de cada partida.
func register_game(main: Node) -> void:
	_game = main
	_autosave_timer = 0.0
	if not pending_load and has_save() and not _backup_checked:
		# partida nova (ex.: rodando main.tscn direto no editor) com save antigo na pasta:
		# guarda o antigo antes que o autosave o substitua
		backup_existing_save()
	_backup_checked = true


func is_game_running() -> bool:
	return _game != null and is_instance_valid(_game) and _game.is_inside_tree()


## Menu: começa do zero. Se havia save, ele vira savegame_backup.json.
func start_new_game() -> void:
	backup_existing_save()
	_backup_checked = true
	pending_load = false
	_pending_data = {}
	get_tree().change_scene_to_file(MAIN_SCENE)


## Menu (Continuar) ou F9: recarrega a partida a partir do arquivo.
func load_game() -> bool:
	var data = read_save()
	if data == null:
		save_failed.emit("save ilegível")
		Audio.error()
		return false
	_pending_data = data
	pending_load = true
	_backup_checked = true
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_SCENE)
	return true


## Move o save atual pro backup (sobrescreve o backup anterior).
func backup_existing_save() -> void:
	if not has_save():
		return
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if dir.file_exists(BACKUP_PATH.get_file()):
		dir.remove(BACKUP_PATH.get_file())
	dir.rename(SAVE_PATH.get_file(), BACKUP_PATH.get_file())


## Move um save ilegível pra savegame_corrompido.json.
func quarantine_corrupt_save() -> void:
	var dir := DirAccess.open("user://")
	if dir == null or not has_save():
		return
	if dir.file_exists(CORRUPT_PATH.get_file()):
		dir.remove(CORRUPT_PATH.get_file())
	dir.rename(SAVE_PATH.get_file(), CORRUPT_PATH.get_file())


# ------------------------------------------------------------ salvar
func save_game(reason: String = "manual") -> bool:
	if not is_game_running():
		return false
	var data := _collect()
	var json := JSON.stringify(data, "\t")
	# escreve num temporário e troca: se o jogo cair no meio, o save antigo fica inteiro
	var f := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if f == null:
		var msg := "não deu pra escrever %s (erro %d)" % [TEMP_PATH, FileAccess.get_open_error()]
		push_warning("SaveManager: " + msg)
		save_failed.emit(msg)
		return false
	f.store_string(json)
	f.close()
	var dir := DirAccess.open("user://")
	if dir.file_exists(SAVE_PATH.get_file()):
		dir.remove(SAVE_PATH.get_file())
	dir.rename(TEMP_PATH.get_file(), SAVE_PATH.get_file())
	_autosave_timer = 0.0
	print("SaveManager: jogo salvo (%s) em %s" % [reason, ProjectSettings.globalize_path(SAVE_PATH)])
	saved.emit(reason)
	return true


func _collect() -> Dictionary:
	var tree := get_tree()
	var data := {
		"save_version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(false, true),
	}
	var singles := {
		"economy": "economy",
		"day_night": "day_night",
		"village": "village_hub",
		"oficina": "oficina",
		"escavadeira": "escavadeira",
	}
	for key in singles:
		var node := tree.get_first_node_in_group(singles[key])
		if node and node.has_method("get_save_data"):
			data[key] = node.get_save_data()
	for key in ["casas", "armazens", "minerios", "comedouros", "coleta_comida", "arvores"]:
		data[key] = _collect_group(key)
	var workers := []
	for w in tree.get_nodes_in_group("ipezinhos"):
		workers.append(w.get_save_data())
	data["workers"] = workers
	var placed := []
	for casa in tree.get_nodes_in_group("casas"):
		if casa.get("placed_by_player"):
			placed.append({"name": String(casa.name), "position": SaveUtil.vec2_to_array(casa.global_position)})
	data["placed_houses"] = placed
	var cam: Node = _game.get_node_or_null("Camera2D")
	if cam:
		data["camera"] = {"position": SaveUtil.vec2_to_array(cam.get_screen_center_position()), "zoom": cam.zoom.x}
	data["summary"] = _summary()
	return data


## {nome do nó: dados} de todos os nós de um grupo.
func _collect_group(group: String) -> Dictionary:
	var out := {}
	for node in get_tree().get_nodes_in_group(group):
		if node.has_method("get_save_data"):
			out[String(node.name)] = node.get_save_data()
	return out


func _summary() -> Dictionary:
	var tree := get_tree()
	var hub := tree.get_first_node_in_group("village_hub")
	var dn := tree.get_first_node_in_group("day_night")
	var eco := tree.get_first_node_in_group("economy")
	return {
		"day": dn.day if dn else 1,
		"stage": hub.stage_name() if hub else "",
		"workers": tree.get_nodes_in_group("ipezinhos").size(),
		"credits": int(eco.credits) if eco else 0,
	}


# ------------------------------------------------------------ carregar
## Chamado pelo main.gd quando a partida está pronta (navegação montada).
func apply_pending(main: Node) -> void:
	if not pending_load:
		return
	pending_load = false
	var data := _pending_data
	_pending_data = {}

	# ordem importa: oficina antes das jazidas (desbloqueio), casas antes dos ipezinhos (camas)
	_apply_single("day_night", SaveUtil.dict(data, "day_night"))
	_apply_single("economy", SaveUtil.dict(data, "economy"))
	_apply_single("village_hub", SaveUtil.dict(data, "village"))
	if not SaveUtil.dict(data, "economy").has("max_workers"):
		_recompute_max_workers()
	_spawn_placed_houses(SaveUtil.array(data, "placed_houses"))
	_apply_group("casas", SaveUtil.dict(data, "casas"))
	_apply_group("armazens", SaveUtil.dict(data, "armazens"))
	_apply_single("oficina", SaveUtil.dict(data, "oficina"))
	_apply_group("minerios", SaveUtil.dict(data, "minerios"))
	_apply_group("comedouros", SaveUtil.dict(data, "comedouros"))
	_apply_group("coleta_comida", SaveUtil.dict(data, "coleta_comida"))
	_apply_group("arvores", SaveUtil.dict(data, "arvores"))
	_apply_single("escavadeira", SaveUtil.dict(data, "escavadeira"))
	if data.has("workers") and typeof(data.workers) == TYPE_ARRAY:
		_apply_workers(main, data.workers)

	var cam_data := SaveUtil.dict(data, "camera")
	var cam: Node = main.get_node_or_null("Camera2D")
	if cam and not cam_data.is_empty():
		cam.focus_on(SaveUtil.vec2(cam_data, "position", cam.global_position))
		cam.set("_target_zoom", clampf(SaveUtil.num(cam_data, "zoom", cam.zoom.x), cam.zoom_min, cam.zoom_max))
	print("SaveManager: save carregado (versão %d, salvo em %s)" % [
		SaveUtil.integer(data, "save_version", 0), SaveUtil.text(data, "saved_at", "?")])
	loaded.emit()


## Recria as casas que o jogador posicionou (antes dos ipezinhos, pra camas baterem).
func _spawn_placed_houses(list: Array) -> void:
	var hub := get_tree().get_first_node_in_group("village_hub")
	if hub == null or list.is_empty():
		return
	for h in list:
		if typeof(h) != TYPE_DICTIONARY:
			continue
		var house_name := SaveUtil.text(h, "name", "")
		if house_name == "" or hub.get_parent().has_node(house_name):
			continue
		var pos := SaveUtil.vec2(h, "position", Vector2.INF)
		if pos == Vector2.INF:
			continue
		hub.spawn_house(pos, house_name, false)
	var env := get_tree().get_first_node_in_group("environment")
	if env:
		env.rebuild_navigation()  # uma vez só, com todas as casas


func _apply_single(group: String, d: Dictionary) -> void:
	if d.is_empty():
		return
	var node := get_tree().get_first_node_in_group(group)
	if node and node.has_method("load_save_data"):
		node.load_save_data(d)


func _apply_group(group: String, by_name: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group(group):
		var d = by_name.get(String(node.name), null)
		if typeof(d) == TYPE_DICTIONARY and node.has_method("load_save_data"):
			node.load_save_data(d)


## Save sem max_workers (versão velha/editado): refaz a partir das Moradias.
func _recompute_max_workers() -> void:
	var eco := get_tree().get_first_node_in_group("economy")
	var hub := get_tree().get_first_node_in_group("village_hub")
	if eco and hub:
		var base: int = eco.get_script().get_property_default_value("max_workers")
		eco.max_workers = base + hub.workers_per_moradia * int(hub.upgrades.get("moradias", 0))


## Troca os ipezinhos da cena pelos do save (cada um volta pra sua cama).
func _apply_workers(main: Node, list: Array) -> void:
	var eco := get_tree().get_first_node_in_group("economy")
	var parent: Node = main.get_node_or_null("World")
	if eco == null or eco.worker_scene == null or parent == null:
		return
	if main.has_method("select"):
		main.select(null)
	for w in get_tree().get_nodes_in_group("ipezinhos"):
		w.get_parent().remove_child(w)  # _exit_tree devolve estação e cama já agora
		w.free()
	for wd in list:
		if typeof(wd) != TYPE_DICTIONARY:
			continue
		var w: Node2D = eco.worker_scene.instantiate()
		w.name = SaveUtil.text(wd, "name", "Ipezinho")
		w.position = SaveUtil.vec2(wd, "position", Vector2.ZERO)
		w.set("pending_save_data", wd)  # aplicado no _ready do ipezinho
		parent.add_child(w)


## Salvos de versões antigas passam por aqui. (Versão 1 = atual, nada a fazer.)
func _migrate(data: Dictionary) -> Dictionary:
	var version := SaveUtil.integer(data, "save_version", 0)
	if version > SAVE_VERSION:
		push_warning("SaveManager: save da versão %d é mais novo que o jogo (%d); tentando carregar mesmo assim" % [version, SAVE_VERSION])
	if version < 2:
		# lotes fixos construídos -> casas posicionadas no mesmo lugar (mesmo nome: camas batem)
		var placed: Array = SaveUtil.array(data, "placed_houses")
		var casas := SaveUtil.dict(data, "casas")
		for lot in LEGACY_LOTS:
			var d = casas.get(lot, null)
			if typeof(d) == TYPE_DICTIONARY and SaveUtil.boolean(d, "built", false):
				placed.append({"name": lot, "position": SaveUtil.vec2_to_array(LEGACY_LOTS[lot])})
			elif casas.has(lot):
				casas.erase(lot)  # lote vazio: não existe mais
		data["placed_houses"] = placed
	# if version < 3: ...
	return data
