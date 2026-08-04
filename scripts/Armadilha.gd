class_name Armadilha
extends Node2D

## Armadilha armada no chão da caverna.
##
## Fica parada onde o Pari a deixou, virada para onde ele estava olhando.
## Quando a Butoriko passa por cima, ela morde: o dano sai e a armadilha
## espera um pouco antes de poder morder de novo.
##
## Só a Butoriko é ferida. O Pari e os bichos menores passam em paz.

signal disparou(alvo, dano_causado)
signal gastou

## Item que virou esta armadilha (define o ícone e o dano padrão).
@export var nome_item: String = "armadilha_tronco"

## Dano por acionamento. Se ficar em 0, usa o valor do ItemDB.
@export var dano: int = 0

## Raio, em pixels, em que a Butoriko é considerada "em cima" da armadilha.
@export var raio: float = 46.0

## Espera, em segundos, antes de a armadilha poder ferir de novo.
@export var intervalo_dano: float = 2.0

## Quantos acionamentos até se desfazer. Use 0 para ela nunca acabar.
@export var usos_maximos: int = 0

## Escala do ícone desenhado no chão.
@export var escala_icone: float = 0.35

## Grupo dos alvos que pisam nela.
@export var grupo_alvo: String = "butoriko"

## Camada de desenho. 0 fica em cima do chão da caverna e embaixo do Pari,
## que anda com z_index 10.
@export var indice_z: int = 0

var _cooldown: float = 0.0
var _usos: int = 0
var _armada: bool = true


func _ready() -> void:
	add_to_group("armadilhas")
	z_index = indice_z
	if dano <= 0:
		dano = ItemDB.dano_armadilha(nome_item)
	_montar_visual()


func _montar_visual() -> void:
	var icone := get_node_or_null("Icone") as Sprite2D
	var marca := get_node_or_null("Marca") as Polygon2D
	var textura := ItemDB.icone(nome_item)

	if textura != null and icone != null:
		icone.texture = textura
		icone.scale = Vector2.ONE * escala_icone
		icone.visible = true
		if marca != null:
			marca.visible = false
	elif marca != null:
		marca.visible = true
		marca.color = ItemDB.cor(nome_item)
		if icone != null:
			icone.visible = false


func _process(delta: float) -> void:
	if not _armada:
		return

	if _cooldown > 0.0:
		_cooldown -= delta
		return

	var alvo := _alvo_em_cima()
	if alvo != null:
		_ferir(alvo)


## Primeiro alvo do grupo que estiver dentro do raio da armadilha.
func _alvo_em_cima() -> Node2D:
	for candidato in get_tree().get_nodes_in_group(grupo_alvo):
		if not is_instance_valid(candidato) or not (candidato is Node2D):
			continue
		if not candidato.has_method("receber_dano"):
			continue
		var alvo := candidato as Node2D
		if global_position.distance_to(_ponto_de_pisada(alvo)) <= raio:
			return alvo
	return null


## Onde o bicho realmente pisa. A Butoriko tem a origem na altura da cabeça
## e o corpo bem mais abaixo, então medir pela forma de colisão acerta o pé.
func _ponto_de_pisada(alvo: Node2D) -> Vector2:
	var forma := alvo.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma != null:
		return forma.global_position
	return alvo.global_position


func _ferir(alvo: Node2D) -> void:
	alvo.receber_dano(dano)

	_cooldown = maxf(0.1, intervalo_dano)
	_usos += 1
	disparou.emit(alvo, dano)
	_sacudir()

	if usos_maximos > 0 and _usos >= usos_maximos:
		_gastar()


## Um tranco curto para dar a entender que a armadilha pegou.
func _sacudir() -> void:
	var escala_original := scale
	modulate = Color(1, 0.6, 0.5)
	var t := create_tween()
	t.tween_property(self, "scale", escala_original * 1.25, 0.07)
	t.tween_property(self, "scale", escala_original, 0.12)
	t.parallel().tween_property(self, "modulate", Color.WHITE, 0.2)


func _gastar() -> void:
	_armada = false
	gastou.emit()
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	t.tween_callback(queue_free)
