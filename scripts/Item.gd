extends Node2D

## Item coletável da caverna: tesouros, armas, utilitários,
## pinturas rupestres (ensinam receitas) e compostos.

signal coletado(item)

@export var categoria: String = "tesouro"
@export var nome: String = "ceramica"

## Só para pinturas rupestres: receita ensinada ao ser lida
@export var receita_nome: String = ""
@export var receita_ingredientes: PackedStringArray = []

## Só para tochas: quanto de chama devolve ao jogador
@export var recarrega_tocha: float = 0.0

var _coletado: bool = false

func _ready() -> void:
	add_to_group("itens")
	_pintar()

func _pintar() -> void:
	var marca := get_node_or_null("Marca") as Polygon2D
	if marca == null:
		return
	match categoria:
		"tesouro": marca.color = Color(0.95, 0.8, 0.25)
		"arma": marca.color = Color(0.8, 0.85, 0.9)
		"utilitario": marca.color = Color(0.45, 0.8, 0.45)
		"pintura": marca.color = Color(0.85, 0.5, 0.8)
		_: marca.color = Color(0.9, 0.6, 0.3)

func coletar() -> void:
	if _coletado:
		return
	_coletado = true

	if get_node_or_null("/root/GameState") != null:
		if categoria == "pintura" and receita_nome != "":
			# pinturas ensinam crafting em vez de ocupar peso
			var ingredientes: Array = Array(receita_ingredientes)
			if ingredientes.is_empty() and ItemDB.RECEITAS.has(receita_nome):
				ingredientes = ItemDB.RECEITAS[receita_nome]
			GameState.aprender_receita(receita_nome, ingredientes)
		else:
			GameState.adicionar_item(nome)

	if recarrega_tocha > 0.0:
		for p in get_tree().get_nodes_in_group("player"):
			if p.has_method("reabastecer_tocha"):
				p.reabastecer_tocha(recarrega_tocha)

	coletado.emit(self)
	remove_from_group("itens")
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.4, 1.4), 0.12)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.18)
	t.tween_callback(queue_free)
