extends Node2D
## O vagonete que anda no trilho (grupo "vagonetes") — Bloco 64. A estação (estacao_vagonete.gd)
## põe ele no lugar a cada quadro; aqui só o desenho: cheio/vazio, virado pro lado da viagem
## (arte do pacote de objetos: SE e SO; NE/NO = espelho). A vista iso copia o Sprite2D.

const TEX := {"cheio_SE": "res://assets/game/iso/props/vagonete_cheio_SE.png", "cheio_SO": "res://assets/game/iso/props/vagonete_cheio_SO.png",
	"vazio_SE": "res://assets/game/iso/props/vagonete_vazio_SE.png", "vazio_SO": "res://assets/game/iso/props/vagonete_vazio_SO.png",
	"grande_SE": "res://assets/game/iso/props/vagonete_grande_SE.png", "grande_SO": "res://assets/game/iso/props/vagonete_grande_SO.png",
	"ruina_SE": "res://assets/game/iso/props/vagonete_ruina_SE.png", "ruina_SO": "res://assets/game/iso/props/vagonete_ruina_SO.png"}  # Bloco 107
## Bloco 99: com a carga a partir disso o carrinho mostra o monte grande de minério.
const CARGA_GRANDE := 60.0

var station: Node = null
var full := false
## Bloco 107: a RUÍNA do vagonete da boca (a estação em ruína): o carrinho velho e destruído, parado no começo do trilho.
var ruina := false
var dir := Vector2.RIGHT
var _sprite: Sprite2D
static var _tex := {}


func _ready() -> void:
	add_to_group("vagonetes")
	_sprite = Sprite2D.new()
	_sprite.name = "Visual"
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	var env := get_tree().get_first_node_in_group("environment")
	var s: float = env.iso_scale() if env and env.has_method("has_iso_map") and env.has_iso_map() else 0.5
	_sprite.scale = Vector2.ONE / maxf(s, 0.01)


func _process(_delta: float) -> void:
	if station == null or not is_instance_valid(station):
		queue_free()
		return
	# direção na tela: x-y (direita) e (x+y)/2 (baixo)
	var scr := Vector2(dir.x - dir.y, (dir.x + dir.y) * 0.5)
	var lado := "SE" if (scr.x >= 0.0) == (scr.y >= 0.0) else "SO"
	var key := ("cheio_" if full else "vazio_") + lado
	if ruina:
		key = "ruina_" + lado
	if full and station.has_method("carga_no_carrinho") and station.carga_no_carrinho() >= CARGA_GRANDE:
		key = "grande_" + lado  # Bloco 99: a carga grande
	if not _tex.has(key):
		_tex[key] = load(TEX[key]) if ResourceLoader.exists(TEX[key]) else null
	var t: Texture2D = _tex[key]
	if t and _sprite.texture != t:
		_sprite.texture = t
	_sprite.flip_h = scr.y < 0.0  # subindo na tela (NE/NO): espelho
	if t:
		_sprite.offset = Vector2(-t.get_width() * 0.5, -t.get_height() + 6.0)
