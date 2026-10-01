extends GutTest
## Prompt 28: testes do núcleo isométrico (scripts/iso/). Rápidos: não abrem a partida.

const Iso := preload("res://scripts/iso/iso_core.gd")
const Order := preload("res://scripts/iso/iso_order.gd")
const IsoView := preload("res://scripts/iso/iso_view.gd")


func _box(x: float, y: float, w: float, d: float, h: float, zb: float = 0.0, n: String = "") -> Iso.Box:
	return Iso.Box.new(Rect2(x, y, w, d), zb, zb + h, "predio", n)


func test_projecao_e_volta() -> void:
	for p in [Vector2.ZERO, Vector2(100, -40), Vector2(-333, 777)]:
		for z in [0.0, 36.0, -110.0]:
			var s := Iso.iso(p, z)
			assert_almost_eq(Iso.iso_inv(s, z), p, Vector2(0.001, 0.001), "volta de %s z=%s" % [p, z])
	assert_eq(Iso.iso(Vector2(10, 0)), Vector2(10, 5), "x do chão vai pra direita e pra baixo (2:1)")
	assert_eq(Iso.iso(Vector2(0, 10)), Vector2(-10, 5), "y do chão vai pra esquerda e pra baixo")
	assert_eq(Iso.PROJ * Vector2(30, 20), Iso.iso(Vector2(30, 20)), "a transformação do chão é a mesma projeção")


func test_atras_de() -> void:
	var a := _box(0, 0, 20, 20, 10)
	var b := _box(30, 0, 20, 20, 10)
	assert_eq(Iso.behind(a, b), true, "a, com x menor, fica atrás")
	assert_eq(Iso.behind(b, a), false)
	var cima := _box(0, 0, 20, 20, 10, 10.0)
	assert_eq(Iso.behind(a, cima), true, "a de baixo fica atrás da de cima")
	var cruza := _box(10, 10, 20, 20, 10)
	assert_eq(Iso.behind(a, cruza), null, "se atravessam: nenhum eixo separa")


## A ordem incremental (encaixar/tirar uma caixa) tem que dar o mesmo resultado VÁLIDO que
## reordenar tudo: nenhum par que se sobrepõe na tela desenhado na ordem errada.
func test_ordem_incremental_valida() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 28
	var boxes := []
	for i in 60:
		boxes.append(_box(rng.randf_range(-400, 400), rng.randf_range(-400, 400), rng.randf_range(12, 90),
			rng.randf_range(10, 70), rng.randf_range(8, 120), 0.0, str(i)))
	# sem sobreposição no chão (como prédios de verdade)
	var ok := []
	for b in boxes:
		if ok.all(func(o): return not o.rect.intersects(b.rect)):
			ok.append(b)
	var ord := Order.new()
	ord.build(ok.slice(0, ok.size() / 2))
	for b in ok.slice(ok.size() / 2):
		ord.add_static(b)  # construiu uma por vez
	assert_eq(_erros(ord.order), 0, "encaixando uma por vez: 0 pares na ordem errada")
	for i in range(0, ok.size(), 3):
		ord.remove_static(ok[i])  # demoliu algumas
	assert_eq(_erros(ord.order), 0, "depois de demolir: 0 pares na ordem errada")
	assert_eq(ord.order.size(), ok.size() - ceili(ok.size() / 3.0), "as demolidas saíram")
	gut.p("fixas: %d   reordenações completas: %d" % [ord.order.size(), ord.full_rebuilds])


func _erros(order: Array) -> int:
	var n := 0
	for i in order.size():
		for j in range(i + 1, order.size()):
			if not Iso.screen_rect(order[i]).intersects(Iso.screen_rect(order[j])):
				continue
			if Iso.behind(order[j], order[i]) == true:
				n += 1
	return n


## Quem anda: fica depois da fixa que está atrás dele e antes da que está na frente.
func test_quem_anda_encaixa() -> void:
	var ord := Order.new()
	var tras := _box(0, 0, 40, 40, 60, 0.0, "trás")
	var frente := _box(0, 60, 40, 40, 60, 0.0, "frente")
	ord.build([frente, tras])
	var boneco := Iso.Box.new(Rect2(10, 45, 12, 12), 0.0, 30.0, "ipezinho", "boneco")
	var z := ord.dynamic_z([boneco])
	assert_gt(z[boneco], ord.z_of_static(tras), "boneco depois da caixa de trás")
	assert_lt(z[boneco], ord.z_of_static(frente), "boneco antes da caixa da frente")


func test_raio_da_camera() -> void:
	var predio := _box(0, 0, 60, 40, 80, 0.0, "prédio")
	var planes := [{"rect": Rect2(-500, -500, 1000, 1000), "z": 0.0, "name": "chão"}]
	# topo do prédio
	var topo := Iso.iso(Vector2(30, 20), 80.0)
	var h := Iso.pick(topo, [predio], planes)
	assert_eq(h.what, "topo", "mira no telhado acerta o topo")
	assert_eq(h.box, predio)
	# face da frente (y = 40), no meio da altura
	var face := Iso.iso(Vector2(30, 40), 40.0)
	h = Iso.pick(face, [predio], planes)
	assert_eq(h.what, "face", "mira na parede acerta a FACE")
	assert_almost_eq(h.ground.y, 40.0, 0.5, "o pé da parede fica na borda da pegada")
	# chão livre
	var chao := Iso.iso(Vector2(200, 200), 0.0)
	h = Iso.pick(chao, [predio], planes)
	assert_eq(h.what, "plano", "fora do prédio: chão")
	assert_almost_eq(h.ground, Vector2(200, 200), Vector2(0.01, 0.01))


func test_direcao_de_losango() -> void:
	assert_eq(IsoView.diamond_dir(Vector2(10, 5), -1), IsoView.DIR_SE, "direita-baixo = SE")
	assert_eq(IsoView.diamond_dir(Vector2(-10, 5), -1), IsoView.DIR_SW)
	assert_eq(IsoView.diamond_dir(Vector2(-10, -5), -1), IsoView.DIR_NW)
	assert_eq(IsoView.diamond_dir(Vector2(10, -5), -1), IsoView.DIR_NE)
	# histerese: andando reto pra baixo (90°, na fronteira SE/SW) não troca
	assert_eq(IsoView.diamond_dir(Vector2(0.5, 10), IsoView.DIR_SW), IsoView.DIR_SW, "fronteira: fica no que estava")
	assert_eq(IsoView.diamond_dir(Vector2(-0.5, 10), IsoView.DIR_SE), IsoView.DIR_SE, "fronteira: fica no que estava")
	assert_eq(IsoView.diamond_dir(Vector2.ZERO, IsoView.DIR_NW), IsoView.DIR_NW, "parado: mantém")
	assert_true(IsoView.faces_camera(IsoView.DIR_SE) and IsoView.faces_camera(IsoView.DIR_SW), "SE/SW olham pra câmera")
	assert_false(IsoView.faces_camera(IsoView.DIR_NE), "NE é de costas")
