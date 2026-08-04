class_name Poca
extends Node2D

## Poça de água no chão da caverna.
##
## Não entra na mochila: fica onde está. Só serve para quem carrega uma cuia
## vazia — encher transforma a cuia em cuia com água. Sem cuia, o Pari olha
## a água e segue em frente.

signal enchida(vezes: int)
signal secou

## Item que precisa estar na mochila (ou equipado) para poder encher.
@export var item_vazio: String = "cuia"

## No que a cuia se transforma depois de cheia.
@export var item_cheio: String = "cuia_agua"

## Quantas vezes dá para encher aqui. Use 0 para uma poça que não seca.
@export var usos: int = 0

## Distância em que aparece o aviso de "E".
@export var raio_interacao: float = 60.0

## Arte da poça. Deixando vazio, usa a de CAMINHO_PADRAO; sem o arquivo,
## o script desenha uma mancha d'água no lugar.
@export var textura: Texture2D

const CAMINHO_PADRAO := "res://sprites/itens/coletaveis/agua.png"

## Tamanho da mancha desenhada, em pixels (antes da escala do nó).
@export var raio_x: float = 46.0
@export var raio_y: float = 24.0

@export var cor_agua: Color = Color(0.29, 0.58, 0.78, 0.92)
@export var cor_brilho: Color = Color(0.82, 0.95, 1.0, 0.85)

## Camada de desenho. Precisa ser 0 ou mais: em -1 a poça fica atrás do
## chão da caverna e some da tela.
@export var indice_z: int = 0

var _usada: int = 0
var _seca: bool = false
var _aviso: Node2D
var _recado: Label
var _tempo_recado: float = 0.0


func _ready() -> void:
	add_to_group("pocas")
	add_to_group("interagivel")
	z_index = maxi(0, indice_z)
	_montar_visual()
	_montar_aviso()
	_reluzir()


func _montar_visual() -> void:
	if textura == null and ResourceLoader.exists(CAMINHO_PADRAO):
		textura = load(CAMINHO_PADRAO) as Texture2D

	if textura != null:
		var sp := Sprite2D.new()
		sp.texture = textura
		add_child(sp)
		return

	# Sem arte ainda: borda de pedra molhada, água e dois reflexos por cima.
	var borda := _oval(raio_x + 5.0, raio_y + 4.0, Color(0.16, 0.18, 0.2, 0.8))
	add_child(borda)
	add_child(_oval(raio_x, raio_y, cor_agua))

	var brilho := _oval(raio_x * 0.42, raio_y * 0.32, cor_brilho)
	brilho.position = Vector2(-raio_x * 0.26, -raio_y * 0.3)
	add_child(brilho)

	var faisca := _oval(raio_x * 0.16, raio_y * 0.14, cor_brilho)
	faisca.position = Vector2(raio_x * 0.34, raio_y * 0.28)
	add_child(faisca)


func _oval(rx: float, ry: float, cor: Color) -> Polygon2D:
	var pontos := PackedVector2Array()
	for i in range(16):
		var a := TAU * float(i) / 16.0
		pontos.append(Vector2(cos(a) * rx, sin(a) * ry))
	var p := Polygon2D.new()
	p.polygon = pontos
	p.color = cor
	return p


func _montar_aviso() -> void:
	_aviso = Node2D.new()
	add_child(_aviso)

	var l := Label.new()
	l.text = "E"
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(1, 0.93, 0.7))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	l.position = Vector2(-4, -46)
	_aviso.add_child(l)
	_aviso.visible = false

	# recado curto ("precisa de uma cuia", "cuia cheia")
	_recado = Label.new()
	_recado.add_theme_font_size_override("font_size", 9)
	_recado.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82))
	_recado.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_recado.add_theme_constant_override("outline_size", 4)
	_recado.position = Vector2(-52, -64)
	_recado.size = Vector2(104, 0)
	_recado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_recado.visible = false
	add_child(_recado)


func _process(delta: float) -> void:
	if _tempo_recado > 0.0:
		_tempo_recado -= delta
		if _tempo_recado <= 0.0 and _recado != null:
			_recado.visible = false

	if _aviso != null:
		_aviso.visible = not _seca and _tempo_recado <= 0.0 and _perto_do_jogador()


func _perto_do_jogador() -> bool:
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and global_position.distance_to(p.global_position) <= raio_interacao:
			return true
	return false


func _dizer(texto: String) -> void:
	if _recado == null:
		return
	_recado.text = texto
	_recado.visible = true
	_tempo_recado = 1.6


# ------------------------------------------------------------------ interação
## Chamado pelo jogador ao apertar E
func interagir() -> void:
	if _seca:
		return
	if get_node_or_null("/root/GameState") == null:
		return

	if not _tirar_cuia_vazia():
		_dizer("Precisa de uma cuia vazia")
		return

	if not GameState.adicionar_item(item_cheio):
		# mochila lotada: devolve a cuia e avisa
		GameState.adicionar_item(item_vazio)
		_dizer("A mochila está cheia")
		return

	_usada += 1
	enchida.emit(_usada)
	_dizer("%s" % ItemDB.rotulo(item_cheio))
	_ondular()

	if usos > 0 and _usada >= usos:
		_secar()


## Tira uma cuia vazia do equipamento ou da mochila. Falso se não houver.
func _tirar_cuia_vazia() -> bool:
	for slot in ItemDB.SLOTS:
		if GameState.item_equipado(slot) == item_vazio:
			GameState.desequipar(slot)
			return true
	return GameState.remover_item(item_vazio)


## A água respira devagar. Num corredor escuro, o que se mexe chama o olho —
## é o que faz a poça ser achada em vez de passar batida.
func _reluzir() -> void:
	var t := create_tween().set_loops()
	t.tween_property(self, "modulate", Color(1.25, 1.25, 1.3), 1.4)
	t.tween_property(self, "modulate", Color(0.82, 0.86, 0.92), 1.4)


## Um tremor na superfície quando a cuia entra na água.
func _ondular() -> void:
	var original := scale
	var t := create_tween()
	t.tween_property(self, "scale", original * Vector2(1.15, 0.85), 0.09)
	t.tween_property(self, "scale", original, 0.16)


func _secar() -> void:
	_seca = true
	remove_from_group("interagivel")
	secou.emit()
	if _aviso != null:
		_aviso.visible = false
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.25, 0.5)
