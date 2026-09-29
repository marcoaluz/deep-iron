extends RefCounted
## Leitura "tolerante" de dados do save (use com preload).
##
## O JSON pode vir de uma versão antiga, editado à mão ou pela metade: toda
## leitura passa por aqui, com valor padrão, e nunca confia no tipo do que veio.
## (JSON não tem int: todo número volta como float.)


static func num(d: Dictionary, key: String, default: float) -> float:
	var v = d.get(key, default)
	if typeof(v) in [TYPE_FLOAT, TYPE_INT]:
		return float(v)
	return default


static func integer(d: Dictionary, key: String, default: int) -> int:
	return int(num(d, key, default))


static func boolean(d: Dictionary, key: String, default: bool) -> bool:
	var v = d.get(key, default)
	if typeof(v) == TYPE_BOOL:
		return v
	if typeof(v) in [TYPE_FLOAT, TYPE_INT]:
		return v != 0
	return default


static func text(d: Dictionary, key: String, default: String) -> String:
	var v = d.get(key, default)
	return v if typeof(v) == TYPE_STRING else default


static func dict(d: Dictionary, key: String) -> Dictionary:
	var v = d.get(key, {})
	return v if typeof(v) == TYPE_DICTIONARY else {}


static func array(d: Dictionary, key: String) -> Array:
	var v = d.get(key, [])
	return v if typeof(v) == TYPE_ARRAY else []


## Vector2 salvo como [x, y].
static func vec2(d: Dictionary, key: String, default: Vector2) -> Vector2:
	var v = d.get(key, null)
	if typeof(v) == TYPE_ARRAY and v.size() >= 2 \
			and typeof(v[0]) in [TYPE_FLOAT, TYPE_INT] and typeof(v[1]) in [TYPE_FLOAT, TYPE_INT]:
		return Vector2(v[0], v[1])
	return default


## Bloco 47: posições de um prédio que agora pode ter vários. Lê a lista nova (list_key);
## save antigo tem só a chave de um (old_key) — vira lista de um.
static func positions(d: Dictionary, list_key: String, old_key: String = "") -> Array[Vector2]:
	var raw: Array = array(d, list_key)
	if raw.is_empty() and old_key != "" and d.has(old_key):
		raw = [d[old_key]]
	var out: Array[Vector2] = []
	for r in raw:
		var p := vec2({"p": r}, "p", Vector2.INF)
		if p.is_finite():
			out.append(p)
	return out


static func vec2_to_array(v: Vector2) -> Array:
	return [snappedf(v.x, 0.1), snappedf(v.y, 0.1)]
