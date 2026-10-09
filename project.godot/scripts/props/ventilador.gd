extends Node2D
## Bloco 70: VENTILADOR do nível 2 (grupo "ventiladores"). Construído pelo engenheiro (fundo.gd:
## pesquisa Ventilação + obra). No alcance (Fundo.ventilador_alcance) a máscara de gás gasta menos e o
## ácido das poças queima mais devagar; cada um afina a névoa verde do S2. Na vista iso vira o prop
## "ventilador" (meta iso_prop); aqui fica o desenho da vista de cima.

const TEXTURE := preload("res://assets/game/ventilador.png")
const Desgaste := preload("res://scripts/core/desgaste.gd")  # Bloco 105: o ventilador gasta por hora ligado
const Manutencao := preload("res://scripts/core/manutencao.gd")

var _desgaste = Desgaste.new("ventilador")

var _sprite: Sprite2D
var _air: CPUParticles2D


func _ready() -> void:
	_desgaste.dono = self
	add_to_group("maquinas")
	add_to_group("ventiladores")
	set_meta("iso_prop", "ventilador")
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.scale = Vector2(2, 2)
	_sprite.offset = Vector2(0, -8)
	add_child(_sprite)
	_air = CPUParticles2D.new()  # o ar subindo (leva o gás)
	_air.amount = 10
	_air.lifetime = 1.6
	_air.position = Vector2(0, -26)
	_air.direction = Vector2(0, -1)
	_air.spread = 18.0
	_air.gravity = Vector2.ZERO
	_air.initial_velocity_min = 20.0
	_air.initial_velocity_max = 34.0
	_air.scale_amount_min = 1.5
	_air.scale_amount_max = 3.0
	_air.color = Color(0.75, 1.0, 0.7, 0.35)
	add_child(_air)
	add_to_group("efeitos")
	efeitos_mudaram()


func pop_in() -> void:
	scale = Vector2(0.4, 0.4)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Reduzir efeitos: sem o ar subindo (Bloco 105: quebrado, também não).
func efeitos_mudaram() -> void:
	_air.emitting = not preload("res://scripts/core/efeitos.gd").reduzidos() and not _desgaste.quebrada


## Bloco 105: o quanto ele protege agora (1 = tudo; cai aos poucos com o desgaste; 0 = quebrado). O fundo.gd usa isto
## nas regras de sempre (a máscara de gás e o ácido das poças no alcance; a névoa verde).
func eficiencia() -> float:
	return _desgaste.eficiencia()


func _process(delta: float) -> void:
	var dn := get_tree().get_first_node_in_group("day_night")
	var sph: float = float(dn.segundos_por_hora()) if dn else 22.5
	var antes: bool = _desgaste.quebrada
	Manutencao.gasta_em(self, "ventilador", delta / maxf(sph, 0.01))
	if _desgaste.quebrada != antes:
		efeitos_mudaram()
	# o ar mais fraco (mais lento e mais apagado) conforme ele gasta: dá pra ver antes de falhar
	var ef: float = _desgaste.eficiencia()
	_air.speed_scale = lerpf(0.35, 1.0, ef)
	_air.modulate.a = clampf(ef, 0.2, 1.0)
	_sprite.modulate = Color(0.55, 0.55, 0.6) if _desgaste.quebrada else Color.WHITE


func manut_tipo() -> String:
	return "ventilador"


func manut_condicao() -> float:
	return _desgaste.condicao


func manut_quebrada() -> bool:
	return _desgaste.quebrada


func manut_titulo() -> String:
	return "Ventilador"


func manut_pos(_w: Node) -> Vector2:
	return global_position + Vector2(0, 30)


func manut_preventiva() -> void:
	_desgaste.restaura()
	efeitos_mudaram()


func manut_consertada() -> void:
	efeitos_mudaram()


func manut_conserto_proprio() -> bool:
	return false
