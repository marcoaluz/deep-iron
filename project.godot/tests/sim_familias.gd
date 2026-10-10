extends SceneTree
## Bloco 111 (não é teste): SIMULA 3 anos (168 dias de jogo) de uma vila com famílias, dia a dia, num MODELO que lê os
## @export do familias.gd (gestação, fases, chance, intervalo, máximo de filhos, porção da criança, política). Rodar o jogo
## de verdade por 168 dias levaria ~3 h reais por cenário (8x); o modelo roda em segundos e mostra a CURVA: população x camas
## x comida. O que o modelo SUPÕE (e não mede) está nas constantes abaixo, com a fonte.
##   <Godot>.exe --headless --path . -s res://tests/sim_familias.gd -- [adulto=28] [semente=7] [saida=<arquivo.txt>]
const DIAS := 168
## Adultos no começo (metade de cada; como a partida de teste dos benches do 108–110).
const INICIAL := 12
## Camas no começo (3 casas de 4 + o alojamento: a partida nova).
const CAMAS_INICIAIS := 16
## Cenário "constrói": uma casa nova (4 camas, nível 1 do casa.gd) a cada N dias.
const CASA_A_CADA := 14
const CAMAS_POR_CASA := 4
## Comida: um adulto come 3 porções de 8 por dia (medido: bench do Bloco 108, ~240 unidades/dia pra 10).
const COME_ADULTO := 24.0
## SUPOSIÇÃO do modelo: quanto um produtor (caçador/agricultor) rende por dia, e quantos adultos o jogador põe na
## comida (1 em 4). Escolhido pra uma vila SÓ DE ADULTOS empatar (4 adultos x 24 = 96 ≈ 100): a criança é que pesa.
const PRODUZ_POR_PRODUTOR := 100.0
const FRACAO_NA_COMIDA := 0.25
## Comida guardada no começo (unidades).
const ESTOQUE_INICIAL := 300.0
## SUPOSIÇÃO calibrada pelo bench do Bloco 110 (12 ipezinhos: os 3 primeiros casais no dia 14): o adulto precisa de uns
## 12 dias de convivência e aí forma par com chance de 12% ao dia (se tiver alguém livre do outro sexo e não parente).
const CONVIVENCIA_DIAS := 12
const CHANCE_PAR_DIA := 0.12
## Ânimo: a vila boa fica em ~70 (benches 108–110); "passando fome" derruba ~25 (bench 110) — abaixo de animo_minimo
## ninguém engravida.
const ANIMO_BOM := 70.0
const ANIMO_FOME := 25.0

var fam: Node
var out := PackedStringArray()


class Pessoa:
	var id := 0
	var mulher := false
	var idade := 0.0  # dias
	var adulto := true
	var chegou := 0
	var par := -1
	var par_desde := 0
	var pais: Array = []
	var gravida := 0.0  # dias que faltam (0 = não)
	var leve := false


func _initialize() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := String(a).split("=")
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	fam = load("res://scripts/core/familias.gd").new()
	var adulto := float(args.get("adulto", "28"))
	var semente := int(args.get("semente", "7"))
	_p("SIMULAÇÃO DE 3 ANOS (%d dias de jogo; 1 dia = 9 min reais em 1x, 3 anos = %.1f h reais em 1x) — MODELO, ver o cabeçalho" % [DIAS, DIAS * 9.0 / 60.0])
	_p("familias.gd: gestação %.0f d, bebê até %.0f d, criança até %.0f d, ADULTO aos %.0f d, chance %.2f/dia, intervalo %d d, máx %d filhos, porção da criança x%.1f" % [
		fam.gestacao_dias, fam.bebe_dias, fam.crianca_ate, adulto, fam.chance_dia, fam.intervalo_filhos_dias, fam.max_filhos, fam.crianca_porcao])
	for pol in ["neutro", "incentivar", "desestimular"]:
		for constroi in [false, true]:
			seed(semente)
			_roda(adulto, pol, constroi)
	var saida := String(args.get("saida", ""))
	if saida != "":
		var f := FileAccess.open(saida, FileAccess.WRITE)
		f.store_string("\n".join(out) + "\n")
		f.close()
	fam.free()
	quit()


func _p(s: String) -> void:
	print(s)
	out.append(s)


func _roda(adulto_aos: float, pol: String, constroi: bool) -> void:
	var mult: float = 1.0 if pol == "neutro" else (fam.incentivar_mult if pol == "incentivar" else fam.desestimular_mult)
	_p("")
	_p("== política %s | jogador %s | adulto aos %.0f dias" % [pol, "constrói uma casa a cada %d dias" % CASA_A_CADA if constroi else "NÃO constrói casa", adulto_aos])
	_p("  dia | adultos crianças bebês grávidas | nasceram | camas livres | comida (porções/morador) | casais | travou por")
	var gente: Array = []
	var prox := 0
	for i in INICIAL:
		var p := Pessoa.new()
		p.id = prox
		prox += 1
		p.mulher = i % 2 == 1
		p.idade = 40.0
		gente.append(p)
	var camas := CAMAS_INICIAIS
	var estoque := ESTOQUE_INICIAL
	var nasceram := 0
	var filhos_do_casal := {}
	var ultimo := {}
	var travas := {}
	var animo := ANIMO_BOM
	for dia in range(1, DIAS + 1):
		if constroi and dia % CASA_A_CADA == 0:
			camas += CAMAS_POR_CASA
		# comida do dia: os adultos na comida produzem (a grávida no fim rende menos), todo mundo come
		var adultos := gente.filter(func(p): return p.adulto)
		var produtores := int(ceil(adultos.size() * FRACAO_NA_COMIDA))
		var prod := 0.0
		for k in produtores:
			prod += PRODUZ_POR_PRODUTOR * (fam.trabalho_leve_mult if adultos[k].leve else 1.0)
		var come := 0.0
		for p in gente:
			if p.adulto:
				come += COME_ADULTO
			elif p.idade >= fam.bebe_dias:
				come += COME_ADULTO * fam.crianca_porcao
		estoque = maxf(estoque + prod - come, 0.0)
		var fome := estoque <= 0.0
		animo = ANIMO_BOM - (ANIMO_FOME if fome else 0.0) + (fam.animo_esperando * 0.2 if gente.any(func(p): return p.gravida > 0.0) else 0.0)
		if pol == "desestimular":
			animo -= 3.0
		# casais (só adultos, sem par, de fora da família)
		for a in gente:
			if not a.adulto or a.par >= 0 or a.mulher or dia - a.chegou < CONVIVENCIA_DIAS:
				continue
			if randf() >= CHANCE_PAR_DIA:
				continue
			for b in gente:
				if b.adulto and b.mulher and b.par < 0 and dia - b.chegou >= CONVIVENCIA_DIAS and not _parentes(a, b):
					a.par = b.id
					b.par = a.id
					a.par_desde = dia
					b.par_desde = dia
					break
		# a manhã: cada casal pode engravidar (as mesmas condições do motivo_sem_filho)
		var gravidas := gente.filter(func(p): return p.gravida > 0.0).size()
		var pop := gente.size()
		for m in gente:
			if not m.mulher or m.par < 0 or m.gravida > 0.0:
				continue
			var k := "%d|%d" % [m.id, m.par]
			var motivo := ""
			if dia - m.par_desde < fam.casal_estavel_dias:
				motivo = "casal novo"
			elif int(filhos_do_casal.get(k, 0)) >= fam.max_filhos:
				motivo = "máx de filhos"
			elif dia - int(ultimo.get(k, -999)) < fam.intervalo_filhos_dias:
				motivo = "filho recente"
			elif camas - pop - gravidas < 1:
				motivo = "sem cama"
			elif animo < fam.animo_minimo:
				motivo = "desânimo"
			elif estoque / 8.0 < fam.comida_porcoes_por_morador * pop:
				motivo = "pouca comida"
			if motivo != "":
				travas[motivo] = int(travas.get(motivo, 0)) + 1
				continue
			if randf() < fam.chance_dia * mult:
				m.gravida = fam.gestacao_dias
				gravidas += 1
		# o dia passa: gestação, parto, idades
		var novos: Array = []
		for p in gente:
			p.idade += 1.0
			if not p.adulto and p.idade >= adulto_aos:
				p.adulto = true
				p.chegou = dia
			if p.gravida > 0.0:
				p.gravida -= 1.0
				p.leve = p.gravida <= fam.trabalho_leve_dias
				if p.gravida <= 0.0:
					p.leve = false
					var b := Pessoa.new()
					b.id = prox
					prox += 1
					b.mulher = randf() < 0.5
					b.idade = 0.0
					b.adulto = false
					b.pais = [p.id, p.par]
					novos.append(b)
					var k := "%d|%d" % [p.id, p.par]
					filhos_do_casal[k] = int(filhos_do_casal.get(k, 0)) + 1
					ultimo[k] = dia
					nasceram += 1
		gente.append_array(novos)
		if dia % 14 == 0 or dia == 1:
			var bebes := gente.filter(func(p): return not p.adulto and p.idade < fam.bebe_dias).size()
			var criancas := gente.filter(func(p): return not p.adulto and p.idade >= fam.bebe_dias).size()
			var casais := gente.filter(func(p): return p.mulher and p.par >= 0).size()
			var trava := ""
			var maior := 0
			for t in travas:
				if int(travas[t]) > maior:
					maior = int(travas[t])
					trava = t
			_p("  %3d | %7d %8d %5d %8d | %8d | %12d | %10.1f %s | %6d | %s" % [dia, gente.filter(func(p): return p.adulto).size(), criancas, bebes,
				gente.filter(func(p): return p.gravida > 0.0).size(), nasceram, camas - gente.size(), estoque / 8.0 / maxf(gente.size(), 1),
				"FOME" if fome else "    ", casais, ("%s (%d casal-dias)" % [trava, maior]) if trava != "" else "-"])
			travas.clear()
	var adultos_fim := gente.filter(func(p): return p.adulto).size()
	_p("  FIM: %d pessoas (%d adultos), %d nascimentos em 3 anos; a vila de adultos foi de %d pra %d (+%d%%)" % [gente.size(), adultos_fim, nasceram, INICIAL, adultos_fim, int(round(100.0 * (adultos_fim - INICIAL) / INICIAL))])


func _parentes(a: Pessoa, b: Pessoa) -> bool:
	if a.id in b.pais or b.id in a.pais:
		return true
	for x in a.pais:
		if x in b.pais:
			return true
	return false
