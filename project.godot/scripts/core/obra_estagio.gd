extends RefCounted
## Prompt 28: a OBRA POR ESTÁGIOS (regra do docs/arte/CONTRATO_ARTE.md: "o desenho troca pelo
## progresso do engenheiro: 0–33% / 33–66% / 66–100%. Nunca o fantasma que fica nítido").
##
## Quem constrói (canteiro, expansão do Centro da Vila, peças e reatores da Escavadeira) chama
## apply(sprite, progresso) a cada atualização e clear(sprite) quando a obra acaba. Com a arte
## de hoje o estágio é um corte do próprio desenho (obra_estagio.gdshader); no Prompt 29 os
## desenhos obra_1/2/3 da arte nova entram no lugar, pela mesma função stage().

const SHADER := preload("res://scripts/core/obra_estagio.gdshader")
## Por estágio (1, 2, 3): fração da altura que aparece e a cor de obra.
const VISIBLE := [0.34, 0.67, 1.0]
const TINT := [Color(0.72, 0.6, 0.46), Color(0.8, 0.7, 0.56), Color(0.9, 0.84, 0.74)]
const META := "obra_estagio"


## 1 (0–33%), 2 (33–66%) ou 3 (66–100%).
static func stage(progress: float) -> int:
	var p := clampf(progress, 0.0, 1.0)
	if p < 1.0 / 3.0:
		return 1
	if p < 2.0 / 3.0:
		return 2
	return 3


## Mostra o estágio do progresso no sprite (o quadro dele continua o mesmo).
static func apply(sprite: CanvasItem, progress: float) -> void:
	var s := stage(progress)
	var mat: ShaderMaterial = sprite.get_meta(META) if sprite.has_meta(META) else null
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = SHADER
		sprite.set_meta(META, mat)
	var vf := 1
	var row := 0
	if sprite is Sprite2D:
		var sp := sprite as Sprite2D
		vf = maxi(sp.vframes, 1)
		row = sp.frame / maxi(sp.hframes, 1)
	mat.set_shader_parameter("visible_frac", VISIBLE[s - 1])
	mat.set_shader_parameter("vframes", vf)
	mat.set_shader_parameter("frame_row", row)
	mat.set_shader_parameter("tint", TINT[s - 1])
	sprite.material = mat
	sprite.modulate = Color.WHITE


## A obra acabou (ou parou de existir): o desenho volta ao normal.
static func clear(sprite: CanvasItem) -> void:
	if sprite.has_meta(META) and sprite.material == sprite.get_meta(META):
		sprite.material = null


## Estágio que o sprite está mostrando (0 = sem obra). Pra testes e pro HUD.
static func shown(sprite: CanvasItem) -> int:
	if not sprite.has_meta(META) or sprite.material != sprite.get_meta(META):
		return 0
	var f: float = (sprite.material as ShaderMaterial).get_shader_parameter("visible_frac")
	for i in VISIBLE.size():
		if absf(VISIBLE[i] - f) < 0.001:
			return i + 1
	return 0
