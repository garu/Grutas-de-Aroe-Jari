extends Node2D

## Ossos de quem não saiu da gruta.
##
## Marcam o ponto onde Pari morreu e guardam o que ele deixou cair.
## Aperte E por perto para recolher a carga de volta.
##
## Um esqueleto sem itens não some nem responde ao E: vira cenário, o
## registro de uma morte antiga.

signal recuperado(itens: Dictionary)

## categoria -> [nomes de item], como o GameState.aplicar_morte() devolve
@export var itens: Dictionary = {}

## Distância em que aparece o aviso de "E".
@export var raio_interacao: float = 60.0

## Arte dos ossos. Vazio usa a de CAMINHO_PADRAO; sem o arquivo, sobra a
## marca clara desenhada na cena.
@export var textura: Texture2D

const CAMINHO_PADRAO := "res://sprites/Player/skeleton.png"

var _recolhido: bool = false
var _aviso: Node2D


func _ready() -> void:
	add_to_group("esqueletos")
	# só entra na lista do E se houver o que recolher
	if not itens.is_empty():
		add_to_group("interagivel")
	_montar_visual()
	_montar_aviso()


func _montar_visual() -> void:
	if textura == null and ResourceLoader.exists(CAMINHO_PADRAO):
		textura = load(CAMINHO_PADRAO) as Texture2D
	if textura == null:
		return

	var sp := Sprite2D.new()
	sp.texture = textura
	add_child(sp)

	# com os ossos desenhados, a marca provisória sai de cena
	var marca := get_node_or_null("Marca") as CanvasItem
	if marca != null:
		marca.visible = false


func _montar_aviso() -> void:
	_aviso = Node2D.new()
	add_child(_aviso)

	var l := Label.new()
	l.text = "E"
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(1, 0.93, 0.7))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	l.position = Vector2(-4, -44)
	_aviso.add_child(l)
	_aviso.visible = false


func _process(_delta: float) -> void:
	if _recolhido or itens.is_empty():
		return
	_aviso.visible = _perto_do_jogador()


func _perto_do_jogador() -> bool:
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and global_position.distance_to(p.global_position) <= raio_interacao:
			return true
	return false


# ------------------------------------------------------------------ interação
## Chamado pelo jogador ao apertar E
func interagir() -> void:
	if _recolhido or itens.is_empty():
		return
	_recolhido = true

	var devolvidos: Dictionary = itens.duplicate(true)
	if get_node_or_null("/root/GameState") != null:
		for categoria in itens.keys():
			for nome in itens[categoria]:
				GameState.adicionar_item(nome)

	itens.clear()
	remove_from_group("interagivel")
	if _aviso != null:
		_aviso.visible = false
	recuperado.emit(devolvidos)

	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(queue_free)
