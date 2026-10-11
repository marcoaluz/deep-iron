extends Node2D
## Bloco 127: a INTEGRIDADE de UM prédio (filho "Integridade" do prédio, grupos "maquinas" e "integridades"). É o adaptador
## que deixa um prédio ferido por invasor entrar na manutenção do Bloco 105 como se fosse uma máquina: guarda um `Desgaste`
## (condição 1..0; a eficiência cai depois do desgaste de início; 0 = EM RUÍNAS = quebrada) e fala a interface `manut_*`.
##   - ferido: o mecânico faz a preventiva (só tempo dele) até `estruturas.limite_conserto`;
##   - em ruínas: obra de conserto com material (conserto_maquina.gd), com o custo de `manut_custo()` = a fração do original
##     (`estruturas.ruina_custo_pct`); sem mecânico, o engenheiro faz.
## Quem cria e guarda é o nó Estruturas (estruturas.gd); o prédio em si não muda.

const Desgaste := preload("res://scripts/core/desgaste.gd")
const IsoArt := preload("res://scripts/iso/iso_art.gd")

var _desgaste: Desgaste = null  # o Desgaste (desgaste.gd; a Manutencao lê por este nome)
## "Casa", "Armazém"... (o toast e o painel do mecânico).
var titulo := "Prédio"
## O tipo lógico ("casa", "armazem", "enfermaria", "taverna", "centro", "predio"): a tabela de custo e os efeitos.
var tipo_predio := "predio"
## O custo da reconstrução [créditos, metal, madeira, segundos].
var custo: Array = [150, 20, 20, 45.0]
## Até que condição o mecânico faz a preventiva neste prédio (estruturas.limite_conserto).
var limite := 0.9


func _init() -> void:
	name = "Integridade"
	add_to_group("maquinas")
	add_to_group("integridades")
	_desgaste = Desgaste.new("predio", self)


func predio() -> Node2D:
	return get_parent() as Node2D


func gasta(q: float) -> void:
	_desgaste.gasta(q)


func condicao() -> float:
	return _desgaste.condicao


func em_ruina() -> bool:
	return _desgaste.quebrada


func eficiencia() -> float:
	return _desgaste.eficiencia()


# ------------------------------------------------------------ interface "maquinas" (Manutencao, Bloco 105)
func manut_tipo() -> String:
	return "predio"


func manut_condicao() -> float:
	return _desgaste.condicao


func manut_quebrada() -> bool:
	return _desgaste.quebrada


func manut_titulo() -> String:
	return titulo


## O mecânico/engenheiro trabalha em frente ao prédio (embaixo da pegada).
func manut_pos(_worker: Node) -> Vector2:
	var p := predio()
	if p == null:
		return global_position
	var r := IsoArt.base_rect(p)
	if r.has_area():
		return Vector2(r.get_center().x, r.end.y + 18.0)
	return p.global_position + Vector2(0.0, 40.0)


func manut_preventiva() -> void:
	_desgaste.restaura()
	_avisa_estruturas()


func manut_conserto_proprio() -> bool:
	return false


## O conserto grande terminou (conserto_maquina.gd chama depois de restaurar o desgaste).
func manut_consertada() -> void:
	_avisa_estruturas()


## O que a reconstrução custa (a Manutencao lê no lugar da tabela por tipo).
func manut_custo() -> Array:
	return custo


## Até que condição a preventiva vale neste prédio.
func manut_limite() -> float:
	return limite


## O texto do toast quando ele cai em ruínas.
func manut_texto_quebra() -> String:
	return "%s EM RUÍNAS: parou. O mecânico (ou o engenheiro) reconstrói com material." % titulo


func _avisa_estruturas() -> void:
	var e := get_tree().get_first_node_in_group("estruturas") if is_inside_tree() else null
	if e and e.has_method("mudou"):
		e.mudou(predio())


func get_save_data() -> Dictionary:
	var p := predio()
	return {"path": String(p.get_path()) if p else "", "pos": [p.global_position.x, p.global_position.y] if p else [0.0, 0.0],
		"d": _desgaste.get_save_data()}
