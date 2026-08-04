extends Node2D

## Item caído no chão da caverna.
## Só entra na mochila quando o jogador aperta E por perto.

signal coletado(item)

@export var categoria: String = "utilitario"
@export var nome: String = "cipo"

## Só para pinturas antigas: receita ensinada ao ler
@export var receita_nome: String = ""
@export var receita_ingredientes: PackedStringArray = []

## Quanto de chama devolve (tochas/gravetos deixados no chão)
@export var recarrega_tocha: float = 0.0

## Distância em que aparece o aviso de "E"
@export var raio_interacao: float = 60.0

var _coletado: bool = false
var _aviso: Node2D

func _ready() -> void:
	add_to_group("itens")
	add_to_group("interagivel")
	_pintar()
	_montar_aviso()

func _pintar() -> void:
	var marca := get_node_or_null("Marca") as Polygon2D
	var sprite := get_node_or_null("Icone") as Sprite2D
	var tex := ItemDB.icone(nome)

	if tex != null and sprite != null:
		sprite.texture = tex
		sprite.visible = true
		if marca != null:
			marca.visible = false
	elif marca != null:
		marca.visible = true
		marca.color = ItemDB.cor(nome)
		if sprite != null:
			sprite.visible = false

func _montar_aviso() -> void:
	_aviso = Node2D.new()
	add_child(_aviso)
	var l := Label.new()
	l.text = "E"
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(1, 0.93, 0.7))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	l.position = Vector2(-4, -26)
	_aviso.add_child(l)
	_aviso.visible = false

func _process(_delta: float) -> void:
	if _coletado:
		return
	_aviso.visible = _perto_do_jogador()

func _perto_do_jogador() -> bool:
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and global_position.distance_to(p.global_position) <= raio_interacao:
			return true
	return false

## Chamado pelo jogador ao apertar E
func interagir() -> void:
	coletar()

func coletar() -> void:
	if _coletado:
		return
	_coletado = true

	if get_node_or_null("/root/GameState") != null:
		if categoria == "pintura" and receita_nome != "":
			var ingredientes: Array = Array(receita_ingredientes)
			if ingredientes.is_empty() and ItemDB.RECEITAS.has(receita_nome):
				ingredientes = ItemDB.RECEITAS[receita_nome]
			GameState.aprender_receita(receita_nome, ingredientes)
		else:
			if not GameState.adicionar_item(nome):
				# mochila cheia: o item continua no chão
				_coletado = false
				return

	if recarrega_tocha > 0.0:
		for p in get_tree().get_nodes_in_group("player"):
			if p.has_method("reabastecer_tocha"):
				p.reabastecer_tocha(recarrega_tocha)

	coletado.emit(self)
	remove_from_group("itens")
	remove_from_group("interagivel")
	var t := create_tween()
	t.tween_property(self, "scale", scale * 1.4, 0.12)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.18)
	t.tween_callback(queue_free)
