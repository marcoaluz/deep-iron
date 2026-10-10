extends RefCounted
## Bloco 108: o PONTO ÚNICO de composição dos multiplicadores de regra (produção, acidente, porção...). Quem consome
## pergunta `Modificadores.mult(arvore, "producao", ipezinho)` e recebe o produto do `mult(chave, quem)` de TODO nó do
## grupo "modificadores". Hoje só as Políticas da Vila (politicas.gd) entram no grupo; a DIFICULDADE (Prompt 5) só precisa
## entrar no mesmo grupo e responder às mesmas chaves — quem consome não muda nada.
## Chaves: producao, acidente, porcao, fome_refeicao, migracao_intervalo, treino, roubo.
## (Os multiplicadores antigos — zanga, ânimo, frio, inverno, pesquisa... — continuam onde estavam: estes entram como UM
## fator a mais, sempre multiplicando.)

static var _quadro := -1
static var _nos: Array = []


## O produto dos multiplicadores da chave (1.0 = nada muda). `quem` = o ipezinho, quando a regra depende dele.
static func mult(arvore: SceneTree, chave: String, quem: Node = null) -> float:
	if arvore == null:
		return 1.0
	var f := Engine.get_process_frames()
	if f != _quadro:  # a lista do grupo, uma vez por quadro (todo ipezinho pergunta várias vezes)
		_quadro = f
		_nos = arvore.get_nodes_in_group("modificadores")
	var m := 1.0
	for n in _nos:
		if is_instance_valid(n):
			m *= float(n.mult(chave, quem))
	return m
