extends GutTest
## Prompt 28: o verificador "o sprite cabe na caixa" (scripts/iso/iso_art_check.gd) contra a
## arte isométrica que já tem contrato (prédios em prototipos/camera/arte_iso/*/contrato.json).

const Check := preload("res://scripts/iso/iso_art_check.gd")
const ARTE := "res://prototipos/camera/arte_iso/"


func test_arte_dos_predios_cabe_na_caixa() -> void:
	var total := 0
	var pastas := 0
	for d in DirAccess.get_directories_at(ARTE):
		var res: Array = Check.check_folder(ARTE + d)
		if res.is_empty():
			continue
		pastas += 1
		for r in res:
			total += 1
			assert_true(r.ok, "%s/%s: %d px fora (máx %d)" % [d, r.nome, r.fora, Check.MAX_OUTSIDE])
			if r.fora_contrato >= 0:
				assert_eq(r.fora, int(r.fora_contrato), "%s/%s: o jogo e o predio.py contam igual" % [d, r.nome])
	gut.p("%d desenhos em %d pastas conferidos" % [total, pastas])
	assert_gt(total, 10, "achou a arte dos prédios")


func test_desenho_fora_da_caixa_e_recusado() -> void:
	var img := Image.create(80, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# um bloco de 10×10 bem acima da caixa (que tem 20 de altura)
	img.fill_rect(Rect2i(35, 0, 10, 10), Color.WHITE)
	var fora := Check.pixels_outside(img, Vector2(40, 60), Rect2(-10, -10, 20, 20), 20.0)
	assert_eq(fora, 100, "os 100 pixels do bloco ficam fora")
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(36, 40, 8, 10), Color.WHITE)
	assert_eq(Check.pixels_outside(img, Vector2(40, 60), Rect2(-10, -10, 20, 20), 20.0), 0, "dentro da caixa: 0 fora")
