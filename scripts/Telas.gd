extends Control

## Tela de menu genérica (abertura, derrota e vitória).
## A UI é montada por código para não depender de layout no .tscn.

enum Tipo { ABERTURA, DERROTA, VITORIA }

@export var tipo: Tipo = Tipo.ABERTURA
@export var titulo: String = "Grutas de Aroe-Jari"
@export var mensagem: String = ""
@export var cena_jogo: String = "res://cenas/Main.tscn"
@export var mostrar_logotipo: bool = true

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# fundo negro cobrindo a tela inteira
	var fundo := ColorRect.new()
	fundo.color = Color.BLACK
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)

	# centraliza o conteúdo em qualquer resolução
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

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

	match tipo:
		Tipo.ABERTURA:
			caixa.add_child(_botao("Jogar", _jogar))
		Tipo.DERROTA:
			caixa.add_child(_botao("Recomeçar", _recomecar))
			caixa.add_child(_botao("Sair", _sair))
		Tipo.VITORIA:
			caixa.add_child(_botao("Compartilhar", _compartilhar))
			caixa.add_child(_botao("Menu principal", _sair))

func _botao(texto: String, alvo: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(160, 28)
	b.pressed.connect(alvo)
	return b

# ------------------------------------------------------------------ ações
func _jogar() -> void:
	if get_node_or_null("/root/GameState") != null:
		GameState.reset_completo()
	get_tree().change_scene_to_file(cena_jogo)

func _recomecar() -> void:
	# volta ao último ponto de saída, com os itens que sobraram
	get_tree().change_scene_to_file(cena_jogo)

func _sair() -> void:
	get_tree().change_scene_to_file("res://cenas/TelaInicial.tscn")

func _compartilhar() -> void:
	DisplayServer.clipboard_set("https://github.com/Grutas-de-Aroe-Jari")
