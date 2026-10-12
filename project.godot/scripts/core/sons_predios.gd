extends Node
## Bloco 114: os LOOPS DOS PRÉDIOS (fornalha, taverna, cemitério, vagonete, coletores, carpintaria): um loop posicional por
## prédio, que SÓ TOCA PERTO DA CÂMERA e só com o prédio em atividade. Filho do autoload Audio (audio_manager.gd).
##
## Os slots vêm de data/audio/slots.json (tipo "loop_predio": grupo do jogo, método `ativo`, raio em px do mundo). A cada
## `confere` segundos olha todos os prédios dos grupos, fica com os `max_loops` mais perto da câmera (dentro do raio, em
## atividade, com som) e dá a cada um um AudioStreamPlayer2D no lugar dele; quem saiu da lista (câmera longe, prédio parado)
## desce e para. O prédio responde `som_ativo()` (sem o método = sempre ativo). Sem arquivo no slot, nada toca (o gerenciador
## nem cria o player).

const Slots := preload("res://scripts/core/audio_slots.gd")

## Segundos entre uma conferência e a próxima.
@export var confere: float = 0.25
## No máximo quantos loops de prédio tocam juntos (os mais perto da câmera).
@export var max_loops: int = 6
## Segundos pra um loop subir ao entrar no alcance e descer ao sair.
@export var fade: float = 0.7
## Volume de quem está sem som (dB).
@export var db_mudo: float = -40.0

var _t := 0.0
var _vozes: Dictionary = {}  # id do nó (instance_id) -> {player, slot}


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = confere
	atualiza()


## Refaz a lista do que toca agora (o _process chama; os testes também).
func atualiza() -> void:
	var cam := get_viewport().get_camera_2d()
	var querem: Array = []
	if cam:
		var centro: Vector2 = cam.get_screen_center_position()
		for id in Slots.todos():
			var s := Slots.slot(id)
			if String(s.get("tipo", "")) != "loop_predio" or not Slots.tem(id):
				continue
			var raio := float(s.get("raio", 600.0))
			for n in get_tree().get_nodes_in_group(String(s.get("grupo", ""))):
				if not (n is Node2D) or not is_instance_valid(n) or not n.is_inside_tree():
					continue
				var d: float = (n as Node2D).global_position.distance_to(centro)
				if d > raio and not _destacado(n):
					continue
				var metodo := String(s.get("ativo", ""))
				if metodo != "" and n.has_method(metodo) and not bool(n.call(metodo)):
					continue
				# Bloco 118: o zoom decide (a câmera longe = mudo), menos o prédio que o jogador acabou de clicar
				var fz := 1.0 if _destacado(n) else _fator(id)
				if fz < 0.03:
					continue
				querem.append({"no": n, "slot": id, "dist": d, "raio": maxf(raio, 400.0 if _destacado(n) else raio), "fator": fz})
	querem.sort_custom(func(a, b): return a.dist < b.dist)
	if querem.size() > max_loops:
		querem.resize(max_loops)
	var vivos := {}
	for q in querem:
		var k: int = (q.no as Object).get_instance_id()
		vivos[k] = true
		var v: Dictionary = _vozes.get(k, {})
		if v.is_empty() or v.slot != q.slot:
			if not v.is_empty():
				_solta(k)
			_vozes[k] = _cria(q)
		_vozes[k].player.global_position = (q.no as Node2D).global_position
		_ajusta_volume(k, q)
	for k in _vozes.keys():
		if not vivos.has(k):
			_solta(k)


## Bloco 118: o fator de zoom da classe do slot (1 sem o Audio, nos testes).
func _fator(id: String) -> float:
	var a := get_parent()
	return float(a.fator_zoom(Slots.zoom_de(id))) if a != null and a.has_method("fator_zoom") else 1.0


func _destacado(no: Object) -> bool:
	var a := get_parent()
	return a != null and a.has_method("destacado") and bool(a.destacado(no))


## Leva o volume do loop pro do slot + o zoom (suave, a cada conferência).
func _ajusta_volume(k: int, q: Dictionary) -> void:
	var v: Dictionary = _vozes[k]
	var p: AudioStreamPlayer2D = v.player
	var alvo := float(Slots.slot(q.slot).get("db", 0.0)) + linear_to_db(maxf(float(q.get("fator", 1.0)), 0.001))
	if v.get("db", NAN) != alvo:
		v["db"] = alvo
		var tw := create_tween()
		tw.tween_property(p, "volume_db", alvo, confere * 1.2)


func _cria(q: Dictionary) -> Dictionary:
	var s := Slots.slot(q.slot)
	var arr := Slots.streams(q.slot)
	var p := AudioStreamPlayer2D.new()
	p.bus = StringName(String(s.get("bus", "SFX")))
	p.max_distance = float(q.raio)
	p.attenuation = 1.2
	p.stream = arr[0]
	p.volume_db = db_mudo
	add_child(p)
	p.global_position = (q.no as Node2D).global_position
	p.set_meta("slot", String(q.slot))  # Bloco 131: o diagnóstico de som sabe quem é
	p.play()
	var au := get_node_or_null("/root/Audio")
	if au and au.get("silenciados") != null and au.silenciados.has(String(q.slot)):
		p.stream_paused = true  # silenciado no diagnóstico (F3)
	var alvo := float(s.get("db", 0.0)) + linear_to_db(maxf(float(q.get("fator", 1.0)), 0.001))
	_sobe(p, alvo)
	return {"player": p, "slot": q.slot, "db": alvo, "subindo": true}


func _sobe(p: AudioStreamPlayer2D, db: float) -> void:
	var tw := create_tween()
	tw.tween_property(p, "volume_db", db, fade)


func _solta(k: int) -> void:
	var v: Dictionary = _vozes.get(k, {})
	_vozes.erase(k)
	if v.is_empty():
		return
	var p: AudioStreamPlayer2D = v.player
	if not is_instance_valid(p):
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", db_mudo, fade)
	tw.tween_callback(p.queue_free)


## O que está tocando agora: lista de ids de slot (um por prédio), pro teste e pro relatório.
func tocando() -> Array[String]:
	var out: Array[String] = []
	for k in _vozes:
		out.append(String(_vozes[k].slot))
	return out


## Quantos loops de prédio estão vivos.
func quantos() -> int:
	return _vozes.size()
