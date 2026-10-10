extends Node2D
## Bloco 105: a OBRA DO CONSERTO de uma máquina quebrada (grupos "obras" e "consertos_maquina"), aberta pela Manutencao
## quando dá pra pagar o conserto. É uma obra como as outras (ObraSite, Bloco 96): o material pago vira a lista dela
## (reservado no armazém; o carregador — ou quem conserta — leva), e o trabalho só anda até a fração entregue. O ofício é
## "mecanico": o mecânico pega; sem mecânico na vila, o engenheiro (quando não tem obra de construção). Pronto: a máquina
## volta nova. Cancelar devolve o que foi pago (ObraSite.cancelar).

const ObraSite := preload("res://scripts/core/obra_site.gd")
const SaveUtil := preload("res://scripts/core/save_util.gd")

var maquina: Node = null
var segundos := 30.0
var progresso := 0.0
var oficio := "mecanico"
var _obra := ObraSite.new()


func _init() -> void:
	add_to_group("obras")
	add_to_group("consertos_maquina")
	_obra.trabalhador = "mecânico"
	_obra.verbo = "consertando"


func _ready() -> void:
	name = "Conserto_%s" % (String(maquina.name) if maquina and is_instance_valid(maquina) else "maquina")


func obra_pending() -> bool:
	return maquina != null and is_instance_valid(maquina) and progresso < segundos


func obra_title() -> String:
	return "Consertar: %s" % (maquina.manut_titulo() if maquina and is_instance_valid(maquina) else "máquina")


func obra_progress() -> float:
	return clampf(progresso / maxf(segundos, 0.1), 0.0, 1.0)


func obra_position(worker: Node) -> Vector2:
	var base: Vector2 = maquina.manut_pos(worker) if maquina and is_instance_valid(maquina) else global_position
	return base + _obra.offset_for(worker)


func obra_work(s: float) -> void:
	if not obra_pending():
		return
	progresso += s
	if progresso >= segundos:
		progresso = segundos
		_termina()


func _termina() -> void:
	if maquina and is_instance_valid(maquina):
		var d = maquina.get("_desgaste")
		if d:
			d.restaura()
		if maquina.has_method("manut_consertada"):
			maquina.manut_consertada()
	var au := get_node_or_null("/root/Audio")
	if au and au.has_method("som"):
		au.som("maquinas/consertada", global_position)  # Bloco 115 (sem arquivo, o "obra pronta" de sempre)
	var m := get_tree().get_first_node_in_group("manutencao")
	if m:
		m.conserto_terminou(maquina)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and maquina and is_instance_valid(maquina):
		hud.show_toast("%s consertado: voltou a funcionar." % maquina.manut_titulo(), Color(0.55, 1.0, 0.5), maquina)
	remove_from_group("obras")
	queue_free()


func obra_ordered_at() -> float:
	return _obra.ordered_at


func obra_join(worker: Node) -> void:
	_obra.join(worker)


func obra_leave(worker: Node) -> void:
	_obra.leave(worker)


func obra_workers() -> Array[Node]:
	return _obra.workers()


func obra_cancelar() -> void:
	remove_from_group("obras")
	queue_free()


func get_save_data() -> Dictionary:
	return {"maquina": String(maquina.get_path()) if maquina and is_instance_valid(maquina) else "", "segundos": segundos,
		"progresso": progresso, "obra": _obra.get_save_data()}


func load_save_data(d: Dictionary) -> void:
	segundos = maxf(SaveUtil.num(d, "segundos", segundos), 0.1)
	progresso = clampf(SaveUtil.num(d, "progresso", 0.0), 0.0, segundos)
	_obra.load_save_data(SaveUtil.dict(d, "obra"))
