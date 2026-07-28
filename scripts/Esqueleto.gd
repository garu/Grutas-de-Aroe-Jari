extends Node2D

## Marca o ponto onde Pari morreu, guardando os itens perdidos ali.
## Encostar recupera tudo que ficou para trás.

@export var itens: Dictionary = {}

func _ready() -> void:
	add_to_group("esqueletos")

func _process(_delta: float) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and global_position.distance_to(p.global_position) < 22.0:
			_recuperar()
			return

func _recuperar() -> void:
	if get_node_or_null("/root/GameState") != null:
		for categoria in itens.keys():
			for nome in itens[categoria]:
				GameState.adicionar_item(categoria, nome)
	itens.clear()
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(queue_free)
