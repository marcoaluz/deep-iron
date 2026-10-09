extends RefCounted
## Bloco 99: a CABINE de uma ligação entre andares — o elevador do S2 (deep_shaft.gd) e as plataformas S3..S5
## (abyss_shaft.gd). Antes (Bloco 68) o ipezinho sumia na gaiola e aparecia lá embaixo depois de um tempo; agora:
##   - quem chega na gaiola entra na FILA do lado dele (em cima ou embaixo) e espera a cabine ali, de pé;
##   - a cabine, parada num lado, abre a porta e EMBARCA até `capacidade`; depois anda pelo poço (`segundos_viagem` de
##     ponta a ponta) e DESEMBARCA todo mundo no outro andar. Sem ninguém esperando, fica parada onde está;
##   - cada viagem gasta o cabo: depois de `viagens_ate_quebrar` ela QUEBRA (sempre na chegada, ninguém fica preso dentro)
##     — o dono desliga a ligação, a fila volta a andar (o caminho passa pela escada em espiral, espiral.gd) e o conserto
##     vira obra de engenheiro com material (o dono paga o `conserto_*` e chama o _obra.start(), Bloco 96).
## O dono (Node2D com `global_position` em cima e `bottom_position` embaixo) chama `tick(delta)` no _process e encaminha a
## interface de obra pro conserto quando `consertando`. A vista iso desenha a cabine pela `pos` (0 = em cima, 1 = embaixo).
## O save guarda a posição, as viagens e o conserto; quem estava na fila/dentro volta pro chão ao carregar.

const SaveUtil := preload("res://scripts/core/save_util.gd")

var dono: Node2D
## Números (o dono copia os @export dele aqui no _ready).
var capacidade := 4
var segundos_viagem := 6.0
var embarque := 1.2
var viagens_ate_quebrar := 60
var conserto_segundos := 30.0

## 0 = em cima, 1 = embaixo; pra onde vai; quantas viagens desde o último conserto.
var pos := 0.0
var alvo := 0.0
var viagens := 0
var quebrada := false
## O conserto foi pago e espera/está com o engenheiro; quanto falta (s de engenheiro).
var consertando := false
var conserto_left := 0.0
## [{w, saida, de_cima}] na fila; [{w, saida}] dentro.
var fila: Array = []
var a_bordo: Array = []
var _porta := 0.0
## Quantas viagens fez desde o começo (estatística da janela).
var total_viagens := 0


func _init(o: Node2D) -> void:
	dono = o


func parada() -> bool:
	return is_equal_approx(pos, alvo)


func em_cima() -> bool:
	return parada() and pos < 0.5


## Quantos esperam de cada lado: Vector2i(em cima, embaixo).
func esperando() -> Vector2i:
	var c := 0
	var b := 0
	for e in fila:
		if e.de_cima:
			c += 1
		else:
			b += 1
	return Vector2i(c, b)


func tem(w: Node) -> bool:
	for e in fila:
		if e.w == w:
			return true
	for e in a_bordo:
		if e.w == w:
			return true
	return false


func dentro(w: Node) -> bool:
	for e in a_bordo:
		if e.w == w:
			return true
	return false


## O ipezinho chegou na gaiola (de cima ou de baixo) e quer ir pra `saida`. Devolve a posição dele na fila (0 = o 1º).
func entra(w: Node, de_cima: bool, saida: Vector2) -> int:
	if tem(w):
		return 0
	fila.append({"w": w, "saida": saida, "de_cima": de_cima})
	var n := 0
	for e in fila:
		if e.de_cima == de_cima:
			n += 1
	return n - 1


## Saiu da fila (mudou de ideia: outra tarefa). Quem já embarcou vai até o fim da viagem.
func sai(w: Node) -> void:
	fila = fila.filter(func(e): return e.w != w)


func tick(delta: float) -> void:
	fila = fila.filter(func(e): return is_instance_valid(e.w))
	a_bordo = a_bordo.filter(func(e): return is_instance_valid(e.w))
	if quebrada:
		return
	if parada():
		var cima := pos < 0.5
		# embarca quem espera deste lado (até lotar)
		var i := 0
		while i < fila.size() and a_bordo.size() < capacidade:
			var e: Dictionary = fila[i]
			if e.de_cima == cima:
				fila.remove_at(i)
				a_bordo.append({"w": e.w, "saida": e.saida})
				if e.w.has_method("embarca_cabine"):
					e.w.embarca_cabine()
				_porta = 0.0  # mais gente entrando: a porta fica aberta mais um pouco
				continue
			i += 1
		_porta += delta
		var outro_lado := esperando().y if cima else esperando().x
		if _porta >= embarque and (not a_bordo.is_empty() or outro_lado > 0):
			alvo = 1.0 if cima else 0.0
			_porta = 0.0
			Audio.elevator(dono.global_position)
		return
	# Bloco 105: o cabo gasto anda mais devagar (a eficiência do desgaste: as viagens até quebrar)
	var ef := preload("res://scripts/core/desgaste.gd").eficiencia_de(condicao())
	pos = move_toward(pos, alvo, delta * maxf(ef, 0.2) / maxf(segundos_viagem, 0.1))
	if not parada():
		return
	# chegou: todo mundo desce
	for e in a_bordo:
		if e.w.has_method("desembarca_cabine"):
			e.w.desembarca_cabine(e.saida)
	a_bordo.clear()
	viagens += 1
	total_viagens += 1
	_porta = 0.0
	if viagens >= viagens_ate_quebrar:
		quebra()


## O cabo arrebentou (na chegada): a fila volta pra navegação (a ligação some; o caminho vai pela escada em espiral).
func quebra() -> void:
	quebrada = true
	consertando = false
	conserto_left = 0.0
	var mt: Node = dono.get_tree().get_first_node_in_group("manutencao") if dono and dono.is_inside_tree() else null
	if mt:
		mt.conta_quebra(dono)  # Bloco 105 (telemetria)
	for e in fila:
		if is_instance_valid(e.w) and e.w.has_method("cabine_cancelada"):
			e.w.cabine_cancelada()
	fila.clear()
	if dono.has_method("_cabine_quebrou"):
		dono._cabine_quebrou()


## O dono pagou o conserto: o engenheiro faz.
func comeca_conserto() -> void:
	consertando = true
	conserto_left = conserto_segundos


func conserto_progresso() -> float:
	return clampf(1.0 - conserto_left / maxf(conserto_segundos, 0.1), 0.0, 1.0) if consertando else 0.0


## O engenheiro trabalhou `s` segundos no conserto. true = ficou pronta.
func trabalha(s: float) -> bool:
	if not consertando:
		return false
	conserto_left -= s
	if conserto_left > 0.0:
		return false
	consertando = false
	conserto_left = 0.0
	quebrada = false
	viagens = 0
	return true


## Faltam quantas viagens pro cabo gastar (0 = quebrada).
func viagens_restantes() -> int:
	return 0 if quebrada else maxi(viagens_ate_quebrar - viagens, 0)


## Pra janela e pro rótulo.
func estado_texto() -> String:
	if quebrada:
		return "cabo arrebentado — " + ("consertando (%d%%)" % roundi(conserto_progresso() * 100.0) if consertando else "esperando o conserto")
	var e := esperando()
	var onde := "em cima" if pos < 0.5 else "embaixo"
	if not parada():
		onde = "descendo" if alvo > pos else "subindo"
	var txt := "cabine %s (%d/%d)" % [onde, a_bordo.size(), capacidade]
	if e.x + e.y > 0:
		txt += " • fila: %d em cima, %d embaixo" % [e.x, e.y]
	return txt


func get_save_data() -> Dictionary:
	return {"pos": snappedf(pos, 0.001), "viagens": viagens, "total": total_viagens, "quebrada": quebrada,
		"consertando": consertando, "conserto_left": conserto_left}


## Save antigo (sem a chave): a cabine nova, parada em cima.
func load_save_data(d: Dictionary) -> void:
	pos = 1.0 if SaveUtil.num(d, "pos", 0.0) >= 0.5 else 0.0  # (parada num dos lados: ninguém viaja salvo)
	alvo = pos
	viagens = clampi(SaveUtil.integer(d, "viagens", 0), 0, viagens_ate_quebrar)
	total_viagens = maxi(SaveUtil.integer(d, "total", 0), 0)
	quebrada = SaveUtil.boolean(d, "quebrada", false)
	consertando = SaveUtil.boolean(d, "consertando", false) and quebrada
	conserto_left = clampf(SaveUtil.num(d, "conserto_left", conserto_segundos), 0.0, conserto_segundos) if consertando else 0.0
	fila.clear()
	a_bordo.clear()


## Bloco 105: a condição do cabo (1 novo .. 0 arrebentado) — as viagens até quebrar.
func condicao() -> float:
	if quebrada:
		return 0.0
	return clampf(1.0 - float(viagens) / maxf(float(viagens_ate_quebrar), 1.0), 0.0, 1.0)
