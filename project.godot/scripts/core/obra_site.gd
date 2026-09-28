extends RefCounted
## Bloco 31: o pedaço comum de toda OBRA (casa, melhoria da Vila, ferramenta da Oficina,
## peça da Escavadeira). Cada local guarda um destes e expõe a interface de obra
## (duck typing, consultada pelo engenheiro no ipezinho.gd):
##
##   obra_pending() -> bool          tem obra encomendada/em andamento aqui?
##   obra_title() -> String          "Casa nova", "Picareta de aço"...
##   obra_progress() -> float        0..1
##   obra_position(worker) -> Vector2  onde o engenheiro fica trabalhando
##   obra_work(seconds)              o engenheiro trabalhou `seconds` (só assim a obra anda)
##   obra_ordered_at() -> float      pra fila: a mais antiga é atendida primeiro
##   obra_join / obra_leave / obra_workers
##
## Sem engenheiro no local, o relógio da obra NÃO anda (fica "esperando engenheiro").
## O que foi feito nunca se perde: tirar o engenheiro só pausa.

## Quando a obra foi encomendada (horário do sistema): define a ordem da fila.
var ordered_at: float = 0.0
var _workers: Array[Node] = []


## Obra nova encomendada agora.
func start() -> void:
	ordered_at = Time.get_unix_time_from_system()
	_workers.clear()


func join(worker: Node) -> void:
	if not _workers.has(worker):
		_workers.append(worker)


func leave(worker: Node) -> void:
	_workers.erase(worker)


func workers() -> Array[Node]:
	_workers = _workers.filter(func(w): return is_instance_valid(w))
	return _workers


func has_engineer() -> bool:
	return not workers().is_empty()


## "40% — construindo" / "40% — esperando engenheiro"
func status(progress: float) -> String:
	return "%d%% — %s" % [roundi(progress * 100.0), "construindo" if has_engineer() else "esperando engenheiro"]


## Lado a lado quando mais de um engenheiro trabalha no mesmo lugar.
func offset_for(worker: Node) -> Vector2:
	var i := workers().find(worker)
	if i < 0:
		i = workers().size()
	return Vector2(-18.0 + 18.0 * (i % 3), 8.0 * floorf(i / 3.0))


func get_save_data() -> Dictionary:
	return {"ordered_at": ordered_at}


func load_save_data(d: Dictionary) -> void:
	var v = d.get("ordered_at", 0.0)
	ordered_at = float(v) if (v is float or v is int) else 0.0
	_workers.clear()
