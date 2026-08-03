extends Control

## Tela de menu genérica (abertura, derrota e vitória).
## A UI é montada por código para não depender de layout no .tscn.

enum Tipo { ABERTURA, DERROTA, VITORIA }

@export var tipo: Tipo = Tipo.ABERTURA
@export var titulo: String = "Grutas de Aroe-Jari"
@export var mensagem: String = ""
@export var cena_jogo: String = "res://cenas/caverna.tscn"
@export var mostrar_logotipo: bool = true

func _ready() -> void:
	# a tela precisa responder mesmo se o jogo ficou pausado antes de morrer
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false

	# ocupa a viewport inteira (anchors E offsets, senão fica com tamanho zero)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# fundo negro cobrindo a tela inteira
	var fundo := ColorRect.new()
	fundo.color = Color.BLACK
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# centraliza o conteúdo em qualquer resolução
	var centro := CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var caixa := VBoxContainer.new()
	caixa.alignment = BoxContainer.ALIGNMENT_CENTER
	caixa.add_theme_constant_override("separation", 8)
	centro.add_child(caixa)

	if mostrar_logotipo and tipo == Tipo.ABERTURA:
		var tex := load("res://sprites/logotipo/logotipo.png")
		if tex != null:
			var logo := TextureRect.new()
			logo.texture = tex
			logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			logo.custom_minimum_size = Vector2(260, 190)
			caixa.add_child(logo)

	# na abertura o logotipo já traz o nome do jogo
	if not (mostrar_logotipo and tipo == Tipo.ABERTURA):
		var lbl := Label.new()
		lbl.text = titulo
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
		caixa.add_child(lbl)

	if mensagem != "":
		var sub := Label.new()
		sub.text = mensagem
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.custom_minimum_size = Vector2(280, 0)
		sub.add_theme_color_override("font_color", Color(0.8, 0.78, 0.72))
		caixa.add_child(sub)

	var primeiro: Button = null
	match tipo:
		Tipo.ABERTURA:
			primeiro = _botao("Jogar", _jogar)
			caixa.add_child(primeiro)
		Tipo.DERROTA:
			primeiro = _botao("Recomeçar", _recomecar)
			caixa.add_child(primeiro)
			caixa.add_child(_botao("Sair", _sair))
		Tipo.VITORIA:
			primeiro = _botao("Compartilhar", _compartilhar)
			caixa.add_child(primeiro)
			caixa.add_child(_botao("Menu principal", _sair))

	# deixa o teclado funcionar também (Enter/Espaço no botão em foco)
	if primeiro != null:
		primeiro.call_deferred("grab_focus")

func _botao(texto: String, alvo: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(160, 28)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.focus_mode = Control.FOCUS_ALL
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	b.pressed.connect(alvo)
	return b

# ------------------------------------------------------------------ ações
func _trocar_cena(caminho: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(caminho)

func _jogar() -> void:
	if get_node_or_null("/root/GameState") != null:
		GameState.reset_completo()
	_trocar_cena(cena_jogo)

func _recomecar() -> void:
	# volta ao último ponto de saída, com os itens que sobraram
	_trocar_cena(cena_jogo)

func _sair() -> void:
	_trocar_cena("res://cenas/TelaInicial.tscn")

func _compartilhar() -> void:
	DisplayServer.clipboard_set("https://github.com/Grutas-de-Aroe-Jari")
