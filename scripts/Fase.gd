extends Node2D

## Gerencia a fase: HUD, esqueletos pendentes, diálogo de abertura,
## morte do jogador e saídas da caverna.

@export var mostrar_dialogo_inicial: bool = true
@export var texto_abertura: String = "Butoriko fez sua última vítima, ele precisa ser impedido."

var _dialogo_ativo: bool = false
var _hud: CanvasLayer
var _lbl_vida: Label
var _lbl_tocha: Label
var _lbl_itens: Label
var _lbl_dialogo: Label

@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	randomize()
	_montar_hud()
	_reposicionar_player()
	_recriar_esqueletos()

	if player != null:
		player.vida_alterada.connect(_on_vida)
		player.tocha_alterada.connect(_on_tocha)
		player.morreu.connect(_on_morreu)
		_on_vida(player.vida, player.vida_maxima)

	if get_node_or_null("/root/GameState") != null:
		GameState.inventory_changed.connect(_atualizar_itens)
		_atualizar_itens()

	if mostrar_dialogo_inicial:
		_abrir_dialogo()

func _reposicionar_player() -> void:
	if player != null and get_node_or_null("/root/GameState") != null:
		player.global_position = GameState.ponto_recomeco

func _recriar_esqueletos() -> void:
	if get_node_or_null("/root/GameState") == null:
		return
	var cena := load("res://Scenes/Esqueleto.tscn") as PackedScene
	if cena == null:
		return
	for registro in GameState.esqueleto_pendente:
		var e := cena.instantiate()
		e.global_position = registro["pos"]
		e.itens = registro["itens"]
		add_child(e)
	GameState.esqueleto_pendente.clear()

# ------------------------------------------------------------------ HUD
func _montar_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)

	_lbl_vida = _novo_label(Vector2(8, 6))
	_lbl_tocha = _novo_label(Vector2(8, 22))
	_lbl_itens = _novo_label(Vector2(8, 38))

	_lbl_dialogo = _novo_label(Vector2(40, 300))
	_lbl_dialogo.size = Vector2(560, 50)
	_lbl_dialogo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_dialogo.visible = false

func _novo_label(pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	_hud.add_child(l)
	return l

func _on_vida(atual: int, maximo: int) -> void:
	_lbl_vida.text = "Vida: %d/%d" % [atual, maximo]

func _on_tocha(restante: float, _total: float) -> void:
	_lbl_tocha.text = "Tocha: %ds" % int(ceil(restante))

func _atualizar_itens() -> void:
	if get_node_or_null("/root/GameState") == null:
		return
	var partes: Array[String] = []
	for c in GameState.CATEGORIAS:
		var n: int = GameState.contar(c)
		if n > 0:
			partes.append("%s %d" % [c.substr(0, 3), n])
	var receitas: int = GameState.receitas.size()
	var txt := "Itens: " + (", ".join(partes) if partes.size() > 0 else "-")
	if receitas > 0:
		txt += "  |  receitas: %d (C mescla)" % receitas
	_lbl_itens.text = txt

# ------------------------------------------------------------------ diálogo
func _abrir_dialogo() -> void:
	_dialogo_ativo = true
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_lbl_dialogo.visible = true
	_lbl_dialogo.text = "\"%s\"\n\n[qualquer tecla para continuar]" % texto_abertura

func _unhandled_input(event: InputEvent) -> void:
	if not _dialogo_ativo:
		return
	if event is InputEventKey and event.pressed:
		_dialogo_ativo = false
		_lbl_dialogo.visible = false
		get_tree().paused = false

# ------------------------------------------------------------------ morte
func _on_morreu() -> void:
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")

## Chamado por uma saída da caverna: salva o ponto de recomeço
func registrar_saida(pos: Vector2) -> void:
	if get_node_or_null("/root/GameState") != null:
		GameState.ponto_recomeco = pos
