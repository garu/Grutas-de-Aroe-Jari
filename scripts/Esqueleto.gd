extends Node2D

## Marca o ponto onde Pari morreu, guardando os itens perdidos ali.
## Encostar recupera tudo que ficou para trás.

signal recuperado(itens: Dictionary)

@export var itens: Dictionary = {}

## Distância em que os ossos devolvem a carga. Precisa acompanhar o tamanho
## do desenho, senão o Pari passa por cima sem recolher nada.
@export var raio_recolhimento: float = 34.0

## Arte dos ossos. Vazio usa a de CAMINHO_PADRAO; sem o arquivo, sobra a
## marca clara desenhada na cena.
@export var textura: Texture2D

const CAMINHO_PADRAO := "res://sprites/Player/skeleton.png"

func _ready() -> void:
	add_to_group("esqueletos")
	_montar_visual()

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

func _process(_delta: float) -> void:
	if itens.is_empty():
		return
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and global_position.distance_to(p.global_position) < raio_recolhimento:
			_recuperar()
			return

func _recuperar() -> void:
	var devolvidos: Dictionary = itens.duplicate(true)
	if get_node_or_null("/root/GameState") != null:
		for categoria in itens.keys():
			for nome in itens[categoria]:
				GameState.adicionar_item(nome)
	itens.clear()
	recuperado.emit(devolvidos)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(queue_free)
