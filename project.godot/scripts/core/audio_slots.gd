extends RefCounted
## Bloco 114: o CATÁLOGO DE SONS (data/audio/slots.json). Cada som do jogo é um SLOT com nome fixo ("ambiencia/s2_acido",
## "stingers/amanhecer"...): o jogo procura res://assets/audio/<id>.ogg|wav|mp3 e, nos slots com variações, <id>_0, <id>_1...
## Sem arquivo o slot fica MUDO (sem erro) — ou vale o som antigo, a "reserva", que o Audio resolve. Arquivo novo é só pôr na
## pasta com o nome certo (docs/audio/PEDIDO_DE_SONS.md lista todos). O loop é forçado por código: o .ogg/.wav não precisa
## estar marcado como loop no import.
## Os testes trocam os arquivos por sons FALSOS na memória (poe_falso) pra conferir o sistema sem nenhum áudio de verdade.

const ARQUIVO := "res://data/audio/slots.json"
const PASTA := "res://assets/audio/"
const EXTENSOES := ["ogg", "wav", "mp3"]
## Quantas variações (_0 a _N) a busca olha, no máximo.
const MAX_VARIACOES := 8

static var _dados: Dictionary = {}  # id -> o slot (o dicionário do .json)
static var _ordem: Array[String] = []
static var _cache: Dictionary = {}  # id -> Array[AudioStream] dos arquivos
static var _falsos: Dictionary = {}  # id -> Array[AudioStream] (testes)
## Só pros testes: ignora os arquivos de verdade (a pasta assets/audio vai enchendo): só valem os sons falsos e a reserva.
static var ignora_arquivos := false
## Só pros testes: de onde vêm os arquivos (res://assets/audio/); uma pasta que não existe = o jogo rodando sem nenhum arquivo de som.
static var pasta_atual := PASTA


static func carrega(forca: bool = false) -> void:
	if not _dados.is_empty() and not forca:
		return
	_dados = {}
	_ordem = []
	_cache = {}
	var f := FileAccess.open(ARQUIVO, FileAccess.READ)
	if f == null:
		push_warning("AudioSlots: sem %s" % ARQUIVO)
		return
	var j = JSON.parse_string(f.get_as_text())
	if typeof(j) != TYPE_DICTIONARY:
		push_warning("AudioSlots: %s ilegível" % ARQUIVO)
		return
	for s in j.get("slots", []):
		if typeof(s) == TYPE_DICTIONARY and s.has("id"):
			_dados[String(s.id)] = s
			_ordem.append(String(s.id))


## Todos os ids, na ordem do arquivo.
static func todos() -> Array[String]:
	carrega()
	return _ordem


static func existe(id: String) -> bool:
	carrega()
	return _dados.has(id)


## O slot (dicionário do .json); vazio se não existe.
static func slot(id: String) -> Dictionary:
	carrega()
	return _dados.get(id, {})


## Os caminhos de arquivo que existem de verdade pra esse slot (<id>.ext e <id>_0.._N.ext).
static func arquivos(id: String) -> Array[String]:
	var out: Array[String] = []
	var base := pasta_atual + id
	for ext in EXTENSOES:
		if ResourceLoader.exists("%s.%s" % [base, ext]):
			out.append("%s.%s" % [base, ext])
			break
	for i in MAX_VARIACOES:
		for ext in EXTENSOES:
			var p := "%s_%d.%s" % [base, i, ext]
			if ResourceLoader.exists(p):
				out.append(p)
				break
	return out


## Os sons do slot: os falsos dos testes, senão os arquivos (carregados uma vez; o loop é forçado nos de loop).
static func streams(id: String) -> Array[AudioStream]:
	if _falsos.has(id):
		return _falsos[id]
	carrega()
	if ignora_arquivos:
		return []
	if _cache.has(id):
		return _cache[id]
	var out: Array[AudioStream] = []
	var s := slot(id)
	var repete := String(s.get("tipo", "")) in ["loop", "loop_predio"] or (String(s.get("tipo", "")) == "tema" and bool(s.get("loop", false)))
	for p in arquivos(id):
		var st = load(p)
		if st is AudioStream:
			if repete:
				forca_loop(st)
			out.append(st)
	_cache[id] = out
	return out


## Esquece o que já foi carregado (os testes de carga trocam a pasta ou ligam o "ignora arquivos").
static func limpa_cache() -> void:
	_cache = {}


## Tem arquivo de verdade (ou som falso de teste) neste slot?
static func tem(id: String) -> bool:
	return not streams(id).is_empty()


## Faz o som repetir (WAV, OGG ou MP3), mesmo que o import não marque loop.
static func forca_loop(st: AudioStream) -> void:
	if st is AudioStreamWAV:
		if st.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			st.loop_mode = AudioStreamWAV.LOOP_FORWARD
			st.loop_begin = 0
			st.loop_end = int(st.get_length() * st.mix_rate)
	elif st is AudioStreamOggVorbis:
		st.loop = true
	elif st is AudioStreamMP3:
		st.loop = true


# ------------------------------------------------------------ testes
## Põe sons falsos (da memória) num slot; `[]` com limpa_falso tira.
static func poe_falso(id: String, lista: Array) -> void:
	var arr: Array[AudioStream] = []
	for st in lista:
		arr.append(st)
	_falsos[id] = arr


static func limpa_falsos() -> void:
	_falsos = {}


## Um som de mentira (silêncio de `seg` segundos, mono 8 bits) só pros testes.
static func som_falso(seg: float = 1.0) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_8_BITS
	w.mix_rate = 8000
	w.stereo = false
	var n := int(seg * 8000.0)
	var d := PackedByteArray()
	d.resize(n)
	d.fill(0)
	w.data = d
	return w
