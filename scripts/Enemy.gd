extends CharacterBody2D

## Criatura base da caverna (morcego, aranha, cobra, Butoriko).
## Persegue o Pari quando ele entra no raio de detecção e
## causa dano por contato (o ataque é o toque, conforme o SGDD).

signal morreu(criatura)

@export var tipo: String = "morcego"
@export var vida_maxima: int = 30
@export var dano_contato: int = 10
@export var velocidade: float = 45.0
@export var raio_deteccao: float = 130.0
@export var distancia_contato: float = 18.0
@export var intervalo_dano: float = 1.0
@export var e_chefe: bool = false

## Movimento errático quando não está perseguindo
@export var vagueia: bool = true

var vida: int
var vivo: bool = true
var _cooldown_dano: float = 0.0
var _rumo: Vector2 = Vector2.ZERO
var _tempo_rumo: float = 0.0

@onready var corpo: Node2D = $Corpo

func _ready() -> void:
	vida = vida_maxima
	add_to_group("inimigos")
	if e_chefe:
		add_to_group("chefe")
	_sortear_rumo()

func _physics_process(delta: float) -> void:
	if not vivo:
		return

	if _cooldown_dano > 0.0:
		_cooldown_dano -= delta

	var alvo := _achar_player()
	if alvo != null:
		var d: float = global_position.distance_to(alvo.global_position)
		if d <= raio_deteccao:
			velocity = (alvo.global_position - global_position).normalized() * velocidade
		else:
			velocity = _vaguear(delta)

		if d <= distancia_contato and _cooldown_dano <= 0.0:
			if alvo.has_method("receber_dano"):
				alvo.receber_dano(dano_contato)
				_cooldown_dano = intervalo_dano
	else:
		velocity = _vaguear(delta)

	move_and_slide()

func _achar_player() -> Node2D:
	var lista := get_tree().get_nodes_in_group("player")
	for p in lista:
		if is_instance_valid(p) and p.get("vivo") != false:
			return p
	return null

func _vaguear(delta: float) -> Vector2:
	if not vagueia:
		return Vector2.ZERO
	_tempo_rumo -= delta
	if _tempo_rumo <= 0.0:
		_sortear_rumo()
	return _rumo * velocidade * 0.4

func _sortear_rumo() -> void:
	_rumo = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	_tempo_rumo = randf_range(1.0, 2.5)

# ------------------------------------------------------------------ dano
func receber_dano(quantidade: int) -> void:
	if not vivo:
		return
	vida = maxi(0, vida - quantidade)
	if corpo != null:
		corpo.modulate = Color(1, 0.4, 0.4)
		create_tween().tween_property(corpo, "modulate", Color.WHITE, 0.25)
	if vida <= 0:
		morrer()

func morrer() -> void:
	if not vivo:
		return
	vivo = false
	remove_from_group("inimigos")
	morreu.emit(self)
	if e_chefe:
		_vitoria()
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.4)
	t.tween_callback(queue_free)

func _vitoria() -> void:
	# Derrotar Butoriko abre a tela de vitória (SGDD)
	await get_tree().create_timer(0.6).timeout
	get_tree().change_scene_to_file("res://Scenes/Vitoria.tscn")
