extends RefCounted
## Bloco 129: o SELECIONADOR DE ARQUIVO do sistema (janela nativa do Windows; sem ela, o seletor do próprio Godot) pro save:
## "Escolher onde salvar" (Nova partida, Salvar como…) e "Carregar de um arquivo". Só devolve o caminho escolhido
## (SaveManager.set_caminho_save / load_arquivo fazem o resto). Cancelar não faz nada.

const TITULO_SALVAR := "Onde salvar a partida"
const TITULO_ABRIR := "Carregar uma partida"


## A pasta onde o seletor abre: a do arquivo atual do save, ou Documentos.
static func pasta_inicial() -> String:
	var atual: String = SaveManager.caminho_legivel()
	var pasta := atual.get_base_dir()
	if pasta != "" and DirAccess.dir_exists_absolute(pasta):
		return pasta
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)


## Escolher (ou criar) o arquivo onde a partida salva. `ao_escolher` recebe o caminho.
static func salvar(arvore: SceneTree, ao_escolher: Callable, nome_sugerido := "deep_iron.json") -> void:
	_abre(arvore, FileDialog.FILE_MODE_SAVE_FILE, TITULO_SALVAR, nome_sugerido, ao_escolher)


## Escolher um save que já existe pra carregar. `ao_escolher` recebe o caminho.
static func abrir(arvore: SceneTree, ao_escolher: Callable) -> void:
	_abre(arvore, FileDialog.FILE_MODE_OPEN_FILE, TITULO_ABRIR, "", ao_escolher)


static func _abre(arvore: SceneTree, modo: int, titulo: String, nome: String, ao_escolher: Callable) -> void:
	var d := FileDialog.new()
	d.use_native_dialog = true  # (o do sistema; se o sistema não tiver, o motor cai no dele)
	d.access = FileDialog.ACCESS_FILESYSTEM
	d.file_mode = modo
	d.title = titulo
	d.filters = PackedStringArray(["*.json ; Save do DEEP IRON"])
	d.current_dir = pasta_inicial()
	if nome != "":
		d.current_file = nome
	d.process_mode = Node.PROCESS_MODE_ALWAYS  # (funciona com o jogo pausado)
	d.file_selected.connect(func(p: String):
		ao_escolher.call(p)
		d.queue_free())
	d.canceled.connect(d.queue_free)
	arvore.root.add_child(d)
	d.popup_centered_ratio(0.7)
