extends RefCounted
## Bloco 90: CATÁLOGO DA DECORAÇÃO construída pelo jogador (use com preload: const Decor := preload(...)), no
## estilo do ores.gd / items.gd. Cada peça: id, nome, textura (assets/game/decor/<id>.png, provisória), pegada
## (px do chão, centrada no pé), custo (créditos, ferro, madeira), luz (energia, cor, alcance; energia 0 = não
## tem), vagas de sentar (vira ponto social: banco/mesa) e valor de beleza (ânimo de quem mora perto).
## Peça com pegada grande (area >= OBSTACULO_MIN_AREA) entra na navegação como obstáculo; as pequenas não.
## Bloco 92: "iso" = o desenho do PixelLab na vista iso (props.json); a tocha troca entre a chama animada
## ("tocha_chao") e a apagada ("tocha_apagada") — o "textura" fica pro ícone do cartão e pro mapa antigo.

## Pegada a partir da qual a peça bloqueia a navegação (px² do chão).
const OBSTACULO_MIN_AREA := 300.0

const CATALOGO := {
	"tocha": {"iso": "tocha_chao", "nome": "Tocha", "textura": "res://assets/game/decor/tocha.png", "pegada": Vector2(8, 8),
		"custo": Vector3i(4, 0, 4), "luz": {"energia": 0.75, "cor": Color(1.0, 0.62, 0.28), "alcance": 0.55},
		"assentos": 0, "beleza": 1.0},
	"lampiao": {"iso": "decor_lampiao", "nome": "Lampião", "textura": "res://assets/game/decor/lampiao.png", "pegada": Vector2(8, 8),
		"custo": Vector3i(12, 3, 2), "luz": {"energia": 0.95, "cor": Color(1.0, 0.86, 0.55), "alcance": 0.8},
		"assentos": 0, "beleza": 1.5},
	"banco": {"iso": "banco", "nome": "Banco", "textura": "res://assets/game/decor/banco.png", "pegada": Vector2(28, 10),
		"custo": Vector3i(10, 0, 8), "luz": {}, "assentos": 2, "beleza": 1.0},
	"mesa": {"iso": "mesa", "nome": "Mesa", "textura": "res://assets/game/decor/mesa.png", "pegada": Vector2(24, 18),
		"custo": Vector3i(14, 0, 12), "luz": {}, "assentos": 4, "beleza": 1.0},
	"cerca": {"iso": "decor_cerca", "nome": "Cerca", "textura": "res://assets/game/decor/cerca.png", "pegada": Vector2(40, 6),
		"custo": Vector3i(4, 0, 6), "luz": {}, "assentos": 0, "beleza": 0.5},
	"canteiro_flores": {"iso": "decor_canteiro_flores", "nome": "Canteiro de flores", "textura": "res://assets/game/decor/canteiro_flores.png", "pegada": Vector2(20, 14),
		"custo": Vector3i(8, 0, 4), "luz": {}, "assentos": 0, "beleza": 2.5},
	"bandeira": {"iso": "decor_bandeira", "nome": "Bandeira", "textura": "res://assets/game/decor/bandeira.png", "pegada": Vector2(8, 8),
		"custo": Vector3i(10, 0, 3), "luz": {}, "assentos": 0, "beleza": 2.0},
}


static func existe(id: String) -> bool:
	return CATALOGO.has(id)


static func info(id: String) -> Dictionary:
	return CATALOGO.get(id, {})


static func nome(id: String) -> String:
	return String(info(id).get("nome", id))


static func custo(id: String) -> Vector3i:
	return info(id).get("custo", Vector3i.ZERO)


static func tem_luz(id: String) -> bool:
	return float(info(id).get("luz", {}).get("energia", 0.0)) > 0.0


static func pegada(id: String) -> Vector2:
	return info(id).get("pegada", Vector2(8, 8))


## Pegada no chão em volta do pé (o pé fica no meio, na borda de baixo... aqui: no centro).
static func pegada_rect(id: String, pos: Vector2) -> Rect2:
	var p := pegada(id)
	return Rect2(pos - p * 0.5, p)


static func e_obstaculo(id: String) -> bool:
	var p := pegada(id)
	return p.x * p.y >= OBSTACULO_MIN_AREA
