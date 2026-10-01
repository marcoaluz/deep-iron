extends GutTest
## Prompt 28: paletas de pele por código (scripts/iso/skin_palette.gd). O jogo tem que dar o
## mesmo resultado do pipeline de arte (tons_de_pele.py), cujas saídas estão em tests/data/pele.

const Pele := preload("res://scripts/iso/skin_palette.gd")
const DATA := "res://tests/data/pele/"


func _img(nome: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(DATA + nome + ".png"))
	img.convert(Image.FORMAT_RGBA8)
	return img


func test_tres_tons() -> void:
	assert_eq(Pele.tones().size(), 3, "clara, parda e negra")
	for t in ["clara", "parda", "negra"]:
		assert_eq(Pele.ramp(t).size(), 4, "rampa de 4 cores: %s" % t)


func test_igual_ao_pipeline() -> void:
	for sprite in ["minerador_se", "medica_sw"]:
		var orig := _img(sprite)
		for tone in ["clara", "parda", "negra"]:
			var esperado := _img("%s_%s" % [sprite, tone])
			var nosso := Pele.recolor_sheet(orig, tone)
			var diff := 0
			var trocados := 0
			var trocados_py := 0
			for y in orig.get_height():
				for x in orig.get_width():
					var a := nosso.get_pixel(x, y)
					var b := esperado.get_pixel(x, y)
					if absi(a.r8 - b.r8) > 1 or absi(a.g8 - b.g8) > 1 or absi(a.b8 - b.b8) > 1 or a.a8 != b.a8:
						diff += 1
					if a != orig.get_pixel(x, y):
						trocados += 1
					if b != orig.get_pixel(x, y):
						trocados_py += 1
			assert_eq(diff, 0, "%s %s: igual ao tons_de_pele.py (±1 de arredondamento)" % [sprite, tone])
			assert_eq(trocados, trocados_py, "%s %s: trocou os mesmos %d pixels" % [sprite, tone, trocados_py])


## Máscara por quadro: numa folha com 2 quadros, cada um acha a pele no SEU rosto.
func test_folha_quadro_a_quadro() -> void:
	var orig := _img("minerador_se")
	var w := orig.get_width()
	var folha := Image.create(w * 2, orig.get_height(), false, Image.FORMAT_RGBA8)
	folha.blit_rect(orig, Rect2i(Vector2i.ZERO, orig.get_size()), Vector2i.ZERO)
	folha.blit_rect(orig, Rect2i(Vector2i.ZERO, orig.get_size()), Vector2i(w, 0))
	var out := Pele.recolor_sheet(folha, "negra", 2, 1)
	var um := Pele.recolor_sheet(orig, "negra")
	var iguais := true
	for y in orig.get_height():
		for x in w:
			if out.get_pixel(x + w, y) != um.get_pixel(x, y) or out.get_pixel(x, y) != um.get_pixel(x, y):
				iguais = false
	assert_true(iguais, "os 2 quadros saem iguais ao quadro sozinho")
