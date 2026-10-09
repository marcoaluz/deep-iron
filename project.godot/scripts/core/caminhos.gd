extends Node
## Bloco 89: CAMINHOS pintados pelo jogador (nó "Caminhos", criado pelo main.gd; grupo "caminhos").
##
## - Uma GRADE no chão (células de `tamanho` px); cada célula é de um tipo: terra batida, cascalho ou pedra,
##   com custo por célula (`custos`). O jogador pinta e apaga arrastando o mouse (caminho_placer.gd).
## - Quem anda sobre um caminho fica mais rápido (`bonus` por tipo). A melhoria "Trilhas batidas" do Centro da
##   Vila agora AUMENTA esse bônus (centro_vila.trilhas_bonus_mult) em vez de acelerar todo mundo.
## - O passeio da hora social (Bloco 85) segue os caminhos (rota(): busca pela grade, do caminho mais perto de
##   quem sai até o mais perto do destino).
## - Caminhos NÃO bloqueiam a navegação nem pedem rebuild_navigation. Construir um prédio por cima apaga o
##   trecho (environment.clear_decor_under_extras chama remover_sob_predios).
## - Desenho: camada própria no chão da vista iso (iso_view._draw_caminhos), abaixo dos personagens,
##   provisório (cores e pontinhos); refaz só quando muda (`versao`).
## - Save compacto: lista de células por tipo.

const TIPOS := ["terra", "cascalho", "pedra"]
const NOMES := {"terra": "Terra batida", "cascalho": "Cascalho", "pedra": "Pedra"}

## Lado de uma célula da grade (px do chão).
@export var tamanho: float = 20.0
## Custo por célula: x = créditos, y = ferro (pedra/cascalho), z = madeira.
@export var custos: Dictionary = {"terra": Vector3i(2, 0, 0), "cascalho": Vector3i(3, 1, 0), "pedra": Vector3i(5, 2, 0)}
## Bônus de velocidade de quem anda sobre o caminho (0.15 = +15%), por tipo.
@export var bonus: Dictionary = {"terra": 0.12, "cascalho": 0.2, "pedra": 0.3}
## Rota do passeio: só usa caminho que comece/termine até esta distância (px) de quem sai e do destino.
@export var rota_entrada: float = 140.0
## Rota do passeio: um waypoint a cada tantas células.
@export var rota_passo: int = 3

## Vector2i (célula) -> tipo.
var celulas: Dictionary = {}
## Muda a cada pintura/apagada (o desenho da vista iso refaz quando muda).
var versao := 0


func _ready() -> void:
	add_to_group("caminhos")


# ------------------------------------------------------------ grade
func celula_de(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / tamanho), floori(pos.y / tamanho))


func centro_de(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * tamanho


func rect_de(c: Vector2i) -> Rect2:
	return Rect2(Vector2(c) * tamanho, Vector2(tamanho, tamanho))


## O tipo do caminho embaixo de `pos` ("" = sem caminho).
func tipo_em(pos: Vector2) -> String:
	return celulas.get(celula_de(pos), "")


## Multiplicador de velocidade de quem está em `pos` (1.0 = sem caminho). A melhoria Trilhas aumenta o bônus.
func velocidade_em(pos: Vector2) -> float:
	var t: String = tipo_em(pos)
	if t == "":
		return 1.0
	var hub := get_tree().get_first_node_in_group("village_hub") if is_inside_tree() else null
	var mult: float = hub.trilhas_bonus_mult() if hub and hub.has_method("trilhas_bonus_mult") else 1.0
	return 1.0 + float(bonus.get(t, 0.0)) * mult


# ------------------------------------------------------------ pintar / apagar
func custo(tipo: String) -> Vector3i:
	return custos.get(tipo, Vector3i.ZERO)


func custo_texto(tipo: String) -> String:
	var eco := get_tree().get_first_node_in_group("economy")
	var c := custo(tipo)
	return eco.cost_text(c, "ferro") if eco else "%d cr" % c.x


## "" se dá pra pintar uma célula desse tipo agora; senão o motivo.
func motivo_pintar(tipo: String) -> String:
	if tipo not in TIPOS:
		return "tipo desconhecido"
	var eco := get_tree().get_first_node_in_group("economy")
	var c := custo(tipo)
	return eco.missing_text(c.x, c.y, "ferro", c.z) if eco else ""


## Pinta uma célula (paga). false = já era desse tipo, lugar ruim ou sem recursos.
func pintar(c: Vector2i, tipo: String) -> bool:
	if celulas.get(c, "") == tipo or not _celula_livre(c) or motivo_pintar(tipo) != "":
		return false
	var k := custo(tipo)
	var eco := get_tree().get_first_node_in_group("economy")
	if eco and not eco.spend(k.x, k.y, "ferro", k.z):
		return false
	celulas[c] = tipo
	versao += 1
	return true


## Apaga uma célula (sem devolver o que custou). false = não tinha caminho.
func apagar(c: Vector2i) -> bool:
	if not celulas.has(c):
		return false
	celulas.erase(c)
	versao += 1
	return true


## As células na linha entre dois pontos do chão (o arrastar do mouse não pula célula).
func celulas_na_linha(a: Vector2, b: Vector2) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var n := maxi(ceili(a.distance_to(b) / (tamanho * 0.5)), 1)
	for i in n + 1:
		var c := celula_de(a.lerp(b, float(i) / n))
		if out.is_empty() or out[-1] != c:
			out.append(c)
	return out


## Célula onde dá pra ter caminho: dentro do mapa e fora dos prédios (o chão por baixo deles não conta).
func _celula_livre(c: Vector2i) -> bool:
	var env := get_tree().get_first_node_in_group("environment")
	if env and env.get("map_rect") != null and not (env.map_rect as Rect2).grow(400.0).has_point(centro_de(c)):
		return false
	for r in _pegadas_de_predios():
		if r.intersects(rect_de(c)):
			return false
	return true


# ------------------------------------------------------------ prédio por cima apaga
const GRUPOS_PREDIOS := ["casas", "armazens", "comedouros", "village_hub", "escavadeira", "oficina", "enfermarias", "tavernas",
	"campos", "laboratorios", "escudos", "arsenais", "parques", "vestiarios", "coletores", "coletores_minerio", "canteiros",
	"fornalhas", "igrejas", "pontos_carga", "ferrovias", "carpintarias", "carvoarias", "curtumes", "hortas", "estufas"]


func _pegadas_de_predios() -> Array:
	var out: Array = []
	for g in GRUPOS_PREDIOS:
		for node in get_tree().get_nodes_in_group(g):
			if node.has_method("get_obstacle_outline"):
				var o: PackedVector2Array = node.get_obstacle_outline()
				if o.size() >= 3:
					var bb := Rect2(o[0], Vector2.ZERO)
					for q in o:
						bb = bb.expand(q)
					out.append(bb)
	return out


## Apaga os trechos de caminho que ficaram embaixo de prédios (chamado depois de cada construção).
func remover_sob_predios() -> int:
	if celulas.is_empty():
		return 0
	var tirou := 0
	for r in _pegadas_de_predios():
		var c0 := celula_de(r.position)
		var c1 := celula_de(r.end)
		for y in range(c0.y, c1.y + 1):
			for x in range(c0.x, c1.x + 1):
				var c := Vector2i(x, y)
				if celulas.has(c) and r.intersects(rect_de(c)):
					celulas.erase(c)
					tirou += 1
	if tirou > 0:
		versao += 1
	return tirou


# ------------------------------------------------------------ rota do passeio (Bloco 85)
## Waypoints seguindo os caminhos de `de` até `para` (vazio = não tem caminho que sirva). Busca em largura pela
## grade dos caminhos (8 vizinhos), da célula de caminho mais perto de cada ponta (até rota_entrada).
func rota(de: Vector2, para: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	if celulas.is_empty():
		return out
	var ini := _mais_perto(de)
	var fim := _mais_perto(para)
	if ini == Vector2i(-99999, -99999) or fim == Vector2i(-99999, -99999) or ini == fim:
		return out
	var veio := {ini: ini}
	var fila: Array[Vector2i] = [ini]
	var k := 0
	while k < fila.size():
		var c: Vector2i = fila[k]
		k += 1
		if c == fim:
			break
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
			var v: Vector2i = c + d
			if celulas.has(v) and not veio.has(v):
				veio[v] = c
				fila.append(v)
	if not veio.has(fim):
		return out
	var trilha: Array[Vector2i] = []
	var c: Vector2i = fim
	while c != ini:
		trilha.push_front(c)
		c = veio[c]
	trilha.push_front(ini)
	for i in range(0, trilha.size(), maxi(rota_passo, 1)):
		out.append(centro_de(trilha[i]))
	if out[-1] != centro_de(fim):
		out.append(centro_de(fim))
	return out


func _mais_perto(p: Vector2) -> Vector2i:
	var melhor := Vector2i(-99999, -99999)
	var d_min := rota_entrada
	for c in celulas:
		var d := centro_de(c).distance_to(p)
		if d < d_min:
			d_min = d
			melhor = c
	return melhor


# ------------------------------------------------------------ save (compacto: células por tipo)
func get_save_data() -> Dictionary:
	var d := {"tamanho": tamanho}
	for t in TIPOS:
		d[t] = []
	for c in celulas:
		d[celulas[c]].append([c.x, c.y])
	return d


## Save antigo: sem caminhos. Células de tamanho diferente do de agora são descartadas (a grade mudou).
func load_save_data(d: Dictionary) -> void:
	celulas.clear()
	if absf(float(d.get("tamanho", tamanho)) - tamanho) < 0.01:
		for t in TIPOS:
			for p in d.get(t, []):
				if p is Array and p.size() == 2:
					celulas[Vector2i(int(p[0]), int(p[1]))] = t
	versao += 1
