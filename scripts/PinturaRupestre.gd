extends Node2D

## Pintura rupestre que "fala" com quem chega perto.
## Serve de tutorial diegético (os antigos deixaram o recado na parede)
## e também pode ensinar uma receita de combinação.
##
## PARA A ARTE: preencha `textura` no inspetor com o PNG da pintura.
## Sem textura, aparece uma marca ocre no lugar.

@export_multiline var texto: String = ""
@export var titulo: String = ""

## Distância em pixels para o painel continuar aberto
@export var raio_leitura: float = 130.0

## Painel largo, texto alinhado à esquerda e centralizado na tela.
## Use na pintura que lista os comandos do jogo.
@export var lista_de_comandos: bool = false

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
var _lbl_receita: Label
var _lbl_rodape: Label

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
	# A lista de comandos é alta demais para o rodapé: vai para o meio da tela.
	var largura: float = 360.0 if lista_de_comandos else 300.0
	if lista_de_comandos:
		_painel.set_anchors_preset(Control.PRESET_CENTER)
		_painel.position = Vector2(-largura / 2.0, -90)
	else:
		_painel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_painel.position = Vector2(-largura / 2.0, -110)
	_painel.custom_minimum_size = Vector2(largura, 0)
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
	# Lista de teclas se lê melhor alinhada à esquerda; recado curto, centrado.
	_lbl_texto.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT if lista_de_comandos else HORIZONTAL_ALIGNMENT_CENTER
	)
	_lbl_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_texto.add_theme_font_size_override("font_size", 10 if lista_de_comandos else 9)
	_lbl_texto.add_theme_color_override("font_color", Color(0.9, 0.87, 0.8))
	_lbl_texto.visible = texto != ""
	col.add_child(_lbl_texto)

	# A receita em si, montada do catálogo. Sem isto a pintura anuncia o
	# nome do composto e não ensina nada a quem está lendo.
	_lbl_receita = Label.new()
	_lbl_receita.text = texto_da_receita()
	_lbl_receita.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_receita.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_receita.add_theme_font_size_override("font_size", 11)
	_lbl_receita.add_theme_color_override("font_color", Color(0.97, 0.79, 0.42))
	_lbl_receita.visible = _lbl_receita.text != ""
	col.add_child(_lbl_receita)

	_lbl_rodape = Label.new()
	_lbl_rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_rodape.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_rodape.add_theme_font_size_override("font_size", 8)
	_lbl_rodape.add_theme_color_override("font_color", Color(0.68, 0.64, 0.58))
	_lbl_rodape.visible = false
	col.add_child(_lbl_rodape)

	_camada.visible = false

## Monta "Pá = Pedrinhas + Graveto de fogo + Cipó" a partir do ItemDB.
## Devolve "" quando a pintura não ensina nada.
func texto_da_receita() -> String:
	if receita_nome == "":
		return ""

	if not ItemDB.RECEITAS.has(receita_nome):
		push_warning(
			"PinturaRupestre '%s': a receita \"%s\" não existe em ItemDB.RECEITAS. Nada será ensinado."
			% [name, receita_nome]
		)
		return ""

	var nomes: Array[String] = []
	for ingrediente in ItemDB.RECEITAS[receita_nome]:
		nomes.append(ItemDB.rotulo(ingrediente))

	return "%s  =  %s" % [ItemDB.rotulo(receita_nome), "  +  ".join(nomes)]

func _process(_delta: float) -> void:
	var perto := _perto_do_jogador()
	if _aviso != null:
		_aviso.visible = _no_alcance_do_e() and not _lendo
	# afastou-se: fecha o texto sozinho
	if _lendo and not perto:
		_lendo = false
		_camada.visible = false

func _perto_do_jogador() -> bool:
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and global_position.distance_to(p.global_position) <= raio_leitura:
			return true
	return false

## O aviso "E" só acende quando apertar E de fato funciona. A pintura pode
## ficar aberta de mais longe (raio_leitura), mas o braço do Pari é curto.
func _no_alcance_do_e() -> bool:
	for p in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p):
			continue
		var alcance: float = raio_leitura
		var declarado: Variant = p.get("alcance_interacao")
		if declarado != null:
			alcance = minf(raio_leitura, float(declarado))
		if global_position.distance_to(p.global_position) <= alcance:
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
	if receita_nome == "" or not ItemDB.RECEITAS.has(receita_nome):
		return
	if get_node_or_null("/root/GameState") == null:
		return

	if not _ja_ensinou:
		GameState.aprender_receita(receita_nome, ItemDB.RECEITAS[receita_nome])
		_ja_ensinou = true

	if _lbl_rodape != null:
		_lbl_rodape.text = "Pari guardou a mistura. Reveja na bancada da mochila (I)."
		_lbl_rodape.visible = true
