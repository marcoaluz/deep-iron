extends "res://prototipos/camera/proto_logic.gd"
## PROTÓTIPO ROTA A (endurecida): o mundo da cena de estresse, só dados de CHÃO.
##
## Todos os tipos de prédio do jogo (caixas provisórias com pegada e altura de verdade), os 5
## estágios do Centro da Vila, a Escavadeira, barricadas compridas (nos dois sentidos), o
## elevador fino e alto; relevo: 3 platôs em sequência (com vales estreitos entre eles), um
## 2º andar em cima do 1º, galeria rebaixada com escada e o abismo (sem acesso).
## O relevo é um MAPA DE ALTURA (uma altura por ponto do chão): sem ponte nem túnel por
## cima de caminho, a navegação continua 2D como no jogo.

const Iso := preload("res://prototipos/camera/iso_core.gd")

## [nome, retângulo no chão, altura, nível da base]
const CATALOG := [
	["Centro (estágio 5)", Rect2(-240, -150, 180, 100), 152.0, 0.0],
	["Escavadeira", Rect2(20, -180, 160, 120), 190.0, 0.0],
	["Arsenal", Rect2(240, -160, 92, 64), 76.0, 0.0],
	["Elevador", Rect2(400, -170, 48, 48), 120.0, 0.0],
	["Barricada (em pé)", Rect2(520, -190, 16, 76), 40.0, 0.0],
	["Barricada (deitada)", Rect2(580, -160, 76, 16), 40.0, 0.0],
	["Centro (estágio 1)", Rect2(-240, -10, 120, 66), 58.0, 0.0],
	["Centro (estágio 2)", Rect2(-80, -10, 120, 66), 70.0, 0.0],
	["Centro (estágio 3)", Rect2(80, -10, 116, 64), 100.0, 0.0],
	["Centro (estágio 4)", Rect2(240, -30, 172, 95), 100.0, 0.0],
	["Oficina", Rect2(460, -10, 84, 60), 68.0, 0.0],
	["Taverna", Rect2(580, -10, 72, 52), 56.0, 0.0],
	["Armazém", Rect2(-330, 140, 76, 56), 68.0, 0.0],
	["Laboratório", Rect2(-220, 140, 68, 52), 60.0, 0.0],
	["Enfermaria", Rect2(-110, 140, 68, 52), 56.0, 0.0],
	["Vestiário", Rect2(0, 140, 84, 56), 68.0, 0.0],
	["Coletor de madeira", Rect2(120, 140, 104, 70), 80.0, 0.0],
	["Casa", Rect2(-330, 260, 60, 48), 52.0, 0.0],
	["Casa", Rect2(-220, 260, 60, 48), 52.0, 0.0],
	["Casa", Rect2(-110, 260, 60, 48), 52.0, 0.0],
	["Comedouro", Rect2(0, 260, 64, 40), 30.0, 0.0],
	["Parque", Rect2(100, 250, 100, 72), 10.0, 0.0],
	["Campo de treino", Rect2(-330, 360, 68, 48), 12.0, 0.0],
	["Horta", Rect2(-220, 360, 52, 32), 8.0, 0.0],
	["Escudo solar", Rect2(0, 360, 64, 64), 76.0, 0.0],
	["Casa (no platô)", Rect2(-420, -440, 60, 48), 52.0, 36.0],
	["Taverna (no platô alto)", Rect2(0, -450, 72, 52), 56.0, 54.0],
]

## Relevo. Platô: [nome, retângulo, altura do topo, altura da base]
var raised := [
	["Platô 1", Rect2(-660, -460, 360, 260), 36.0, 0.0],
	["Platô 1 — 2º andar", Rect2(-620, -440, 160, 120), 72.0, 36.0],
	["Platô 2", Rect2(-280, -460, 200, 160), 36.0, 0.0],
	["Platô 3 (mais alto)", Rect2(-60, -460, 200, 120), 54.0, 0.0],
]
## Buraco: [nome, retângulo, profundidade (negativa)]
var pits := [
	["Galeria rebaixada", Rect2(-640, 120, 260, 200), -36.0],
	["Abismo", Rect2(260, 170, 360, 250), -110.0],
]
## Rampas/escadas (sobem pro norte): [retângulo, z no lado norte, z no lado sul]
var ramps := [
	[Rect2(-520, -200, 40, 50), 36.0, 0.0],  # chão -> platô 1
	[Rect2(-520, -320, 40, 40), 72.0, 36.0],  # platô 1 -> 2º andar
	[Rect2(-200, -300, 40, 50), 36.0, 0.0],  # chão -> platô 2
	[Rect2(20, -340, 40, 60), 54.0, 0.0],  # chão -> platô 3
	[Rect2(-560, 120, 40, 50), 0.0, -36.0],  # chão -> galeria (desce)
]
const RIM := 24.0  # espessura da "massa de chão" em volta dos buracos (ela tapa quem está dentro)


func build() -> void:
	bounds = Rect2(-700, -500, 1400, 960)
	for c in CATALOG:
		buildings.append(Building.new(c[0], c[1], c[2], c[3]))
	# beiras (penhasco) com abertura onde a rampa encosta
	for r in raised:
		var opening := _ramp_touching(r[1])
		_ring(r[1], opening)
	for p in pits:
		var opening := _ramp_touching(p[1])
		_ring(p[1], opening)
	for rp in ramps:
		var rr: Rect2 = rp[0]
		terrain_blocks.append(Rect2(rr.position.x - 6, rr.position.y, 6, rr.size.y))
		terrain_blocks.append(Rect2(rr.end.x, rr.position.y, 6, rr.size.y))
	# o abismo não tem acesso: o fundo inteiro é bloqueado
	terrain_blocks.append(pits[1][1])
	setup_nav()


## A rampa que encosta na borda (norte ou sul) desse retângulo: [x0, x1, lado] ou [].
func _ramp_touching(r: Rect2) -> Array:
	for rp in ramps:
		var rr: Rect2 = rp[0]
		if rr.position.x >= r.position.x and rr.end.x <= r.end.x:
			if absf(rr.position.y - r.end.y) < 1.0:
				return [rr.position.x, rr.end.x, "sul"]  # rampa sai pela borda sul (platô)
			if absf(rr.position.y - r.position.y) < 1.0 and r.has_point(rr.get_center()):
				return [rr.position.x, rr.end.x, "norte"]  # rampa entra pela borda norte (buraco)
			if absf(rr.end.y - r.position.y) < 1.0:
				return [rr.position.x, rr.end.x, "norte"]
	return []


func _ring(r: Rect2, opening: Array, t: float = 6.0) -> void:
	var n := [Rect2(r.position.x - t, r.position.y - t, r.size.x + t * 2.0, t)]
	var s := [Rect2(r.position.x - t, r.end.y, r.size.x + t * 2.0, t)]
	for side in [["norte", n], ["sul", s]]:
		if not opening.is_empty() and opening[2] == side[0]:
			var full: Rect2 = side[1][0]
			side[1].clear()
			side[1].append(Rect2(full.position.x, full.position.y, opening[0] - full.position.x, t))
			side[1].append(Rect2(opening[1], full.position.y, full.end.x - opening[1], t))
	terrain_blocks.append_array(n)
	terrain_blocks.append_array(s)
	terrain_blocks.append(Rect2(r.position.x - t, r.position.y, t, r.size.y))
	terrain_blocks.append(Rect2(r.end.x, r.position.y, t, r.size.y))


func height_at(p: Vector2) -> float:
	for rp in ramps:
		var rr: Rect2 = rp[0]
		if rr.has_point(p):
			return lerpf(rp[1], rp[2], clampf((p.y - rr.position.y) / rr.size.y, 0.0, 1.0))
	for i in range(raised.size() - 1, -1, -1):  # o de cima primeiro (2º andar antes do 1º)
		if raised[i][1].has_point(p):
			return raised[i][2]
	for pt in pits:
		if pt[1].has_point(p):
			return pt[2]
	return 0.0


## Todas as caixas FIXAS (terreno + prédios), pra desenhar, ordenar e clicar.
func static_boxes() -> Array:
	var out := []
	for r in raised:
		out.append(Iso.Box.new(r[1], r[3], r[2], "terreno", r[0]))
	for p in pits:
		# Buraco: as paredes de DENTRO que se vêem (norte e oeste) e a massa de chão da FRENTE
		# (sul e leste), que tapa quem está lá dentro. As faces de fora ficam enterradas (não
		# desenham), e a massa da frente é tão grossa quanto o buraco é fundo — senão o fundo
		# "vaza" por cima do chão da frente na projeção.
		var pr: Rect2 = p[1]
		var d: float = p[2]
		var nm: String = p[0]
		var rim: float = -d + 8.0
		var wn := Iso.Box.new(Rect2(pr.position.x, pr.position.y - 1.0, pr.size.x, 1.0), d, 0.0, "terreno", "parede (norte) — " + nm)
		wn.hide = ["top", "right"]
		var ww := Iso.Box.new(Rect2(pr.position.x - 1.0, pr.position.y, 1.0, pr.size.y), d, 0.0, "terreno", "parede (oeste) — " + nm)
		ww.hide = ["top", "left"]
		var rs := Iso.Box.new(Rect2(pr.position.x - 1.0, pr.end.y, pr.size.x + 1.0 + rim, rim), d, 0.0, "terreno", "beira (sul) — " + nm)
		rs.hide = ["left", "right"]
		var re := Iso.Box.new(Rect2(pr.end.x, pr.position.y, rim, pr.size.y), d, 0.0, "terreno", "beira (leste) — " + nm)
		re.hide = ["left", "right"]
		out.append_array([wn, ww, rs, re])
	for rp in ramps:
		var b := Iso.Box.new(rp[0], minf(rp[1], rp[2]), maxf(rp[1], rp[2]), "rampa", "rampa/escada")
		b.ramp_axis = Vector2(0, -1)
		out.append(b)
	for bd in buildings:
		out.append(Iso.Box.new(bd.rect, bd.level, bd.level + bd.height, "predio", bd.kind, bd))
	return out


## Planos (chão e fundos de buraco): [{rect, z, name, holes}]
func planes() -> Array:
	var holes := []
	for p in pits:
		holes.append(p[1])
	var out := [{"rect": bounds, "z": 0.0, "name": "chão", "holes": holes}]
	for p in pits:
		out.append({"rect": p[1], "z": p[2], "name": "fundo — " + p[0], "holes": []})
	return out


## Pontos pra onde os ipezinhos passeiam (em todos os níveis alcançáveis).
func wander_points() -> Array:
	var pts := []
	for bd in buildings:
		var r: Rect2 = bd.rect
		pts.append(Vector2(r.get_center().x, r.end.y + 14))  # na frente
		pts.append(Vector2(r.end.x + 14, r.get_center().y))  # do lado
		pts.append(Vector2(r.get_center().x, r.position.y - 14))  # atrás
	for r in raised:
		pts.append(r[1].get_center() + Vector2(40, 30))
	pts.append(pits[0][1].get_center())
	pts.append(pits[0][1].get_center() + Vector2(70, 50))
	return pts.filter(func(p): return bounds.grow(-10).has_point(p))
