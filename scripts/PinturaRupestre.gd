extends Node2D

## Pintura rupestre que "fala" com quem chega perto.
## Serve de tutorial diegético (os antigos deixaram o recado na parede)
## e também pode ensinar uma receita de combinação.
##
## PARA A ARTE: preencha `textura` no inspetor com o PNG da pintura.
## Sem textura, aparece uma marca ocre no lugar.

@export_multiline var texto: String = ""
@export var titulo: String = ""

## Distância em pixels para o painel aparecer
@export var raio_leitura: float = 130.0

## Arte da pintura na parede
@export var textura: Texture2D

## Opcional: nome do composto que esta pintura ensina (ver ItemDB.RECEITAS)
@export var receita_nome: String = ""

var _lendo: bool = false
var _aviso: Node2D
var _ja_ensinou: bool = false
var _camada: CanvasLayer
var _painel: PanelContainer
var _lbl_titulo: Label
var _lbl_texto: Label

func _ready() -> void:
	add_to_group("pinturas")
	add_to_group("interagivel")
	_montar_visual()
	_montar_painel()
	_montar_aviso()

func _montar_aviso() -> void:
	_aviso = Node2D.new()
	add_child(_aviso)
	var l := Label.new()
	l.text = "E"
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(1, 0.93, 0.7))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	l.position = Vector2(-4, -30)
	_aviso.add_child(l)
	_aviso.visible = false

func _montar_visual() -> void:
	if textura != null:
		var sp := Sprite2D.new()
		sp.texture = textura
		add_child(sp)
		return
	# marca provisória até a arte existir
	var marca := Polygon2D.new()
	marca.polygon = PackedVector2Array([
		Vector2(-14, -18), Vector2(14, -18), Vector2(14, 18), Vector2(-14, 18)
	])
	marca.color = Color(0.72, 0.35, 0.18, 0.9)
	add_child(marca)
	var risco := Polygon2D.new()
	risco.polygon = PackedVector2Array([
		Vector2(-7, -10), Vector2(-2, -10), Vector2(-2, 10), Vector2(-7, 10)
	])
	risco.color = Color(0.95, 0.8, 0.55, 0.9)
	add_child(risco)

func _montar_painel() -> void:
	_camada = CanvasLayer.new()
	_camada.layer = 5
	add_child(_camada)

	var centro := Control.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada.add_child(centro)

	_painel = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.07, 0.05, 0.04, 0.93)
	estilo.border_color = Color(0.72, 0.45, 0.22)
	estilo.set_border_width_all(2)
	estilo.set_content_margin_all(8)
	_painel.add_theme_stylebox_override("panel", estilo)
	_painel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_painel.position = Vector2(-150, -110)
	_painel.custom_minimum_size = Vector2(300, 0)
	_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(_painel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	_painel.add_child(col)

	_lbl_titulo = Label.new()
	_lbl_titulo.text = titulo
	_lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_titulo.add_theme_font_size_override("font_size", 11)
	_lbl_titulo.add_theme_color_override("font_color", Color(0.95, 0.72, 0.38))
	_lbl_titulo.visible = titulo != ""
	col.add_child(_lbl_titulo)

	_lbl_texto = Label.new()
	_lbl_texto.text = texto
	_lbl_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_texto.add_theme_font_size_override("font_size", 9)
	_lbl_texto.add_theme_color_override("font_color", Color(0.9, 0.87, 0.8))
	col.add_child(_lbl_texto)

	_camada.visible = false

func _process(_delta: float) -> void:
	var perto := _perto_do_jogador()
	if _aviso != null:
		_aviso.visible = perto and not _lendo
	# afastou-se: fecha o texto sozinho
	if _lendo and not perto:
		_lendo = false
		_camada.visible = false

func _perto_do_jogador() -> bool:
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and global_position.distance_to(p.global_position) <= raio_leitura:
			return true
	return false

## Chamado pelo jogador ao apertar E
func interagir() -> void:
	if not _perto_do_jogador():
		return
	_lendo = not _lendo
	_camada.visible = _lendo
	if _lendo:
		_ensinar()

func _ensinar() -> void:
	if _ja_ensinou or receita_nome == "":
		return
	if get_node_or_null("/root/GameState") == null:
		return
	if ItemDB.RECEITAS.has(receita_nome):
		GameState.aprender_receita(receita_nome, ItemDB.RECEITAS[receita_nome])
		_ja_ensinou = true
