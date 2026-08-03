extends CharacterBody2D

## Pari - movimento 8 direções, ataque, dano, morte,
## tocha com duração e peso do inventário afetando a velocidade.
## Setas/WASD para andar, ESPAÇO (ou X) para atacar, C para mesclar itens.

signal vida_alterada(atual: int, maximo: int)
signal morreu
signal tocha_alterada(restante: float, total: float)

# ------------------------------------------------------------------ atributos
@export var velocidade_base: float = 90.0
@export var vida_maxima: int = 100
@export var ataque_base: int = 20
@export var defesa_base: int = 0

## Cada item carregado deixa Pari mais lento (SGDD)
@export var lentidao_por_item: float = 2.5
@export var velocidade_minima: float = 30.0

# ------------------------------------------------------------------ combate
@export var alcance_ataque: float = 34.0
@export var duracao_ataque: float = 0.35
@export var invulnerabilidade: float = 0.8

# ------------------------------------------------------------------ tocha
@export var tocha_segundos: float = 60.0
@export var tocha_escala_max: float = 2.4
@export var tocha_escala_min: float = 0.6

var vida: int
var direcao: String = "down"
var vivo: bool = true
var _atacando: bool = false
var _invulneravel: float = 0.0
var _tocha_restante: float
var _coleta_cooldown: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var tocha: PointLight2D = $TorchLight
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	vida = vida_maxima
	_tocha_restante = tocha_segundos
	add_to_group("player")
	vida_alterada.emit(vida, vida_maxima)
	if anim.sprite_frames != null and anim.sprite_frames.has_animation("hurt_down"):
		anim.animation_finished.connect(_on_anim_finished)
	_ajustar_limites_camera()

# ------------------------------------------------------------------ câmera
## Ajusta os limites ao tamanho real do mapa desenhado, para a câmera
## seguir o Pari pela caverna inteira. Não altera zoom nem enquadramento.
func _ajustar_limites_camera() -> void:
	if camera == null:
		return
	var mapa := _achar_tilemap(get_tree().current_scene)
	if mapa == null or mapa.tile_set == null:
		_camera_sem_limites()
		return

	var usado: Rect2i = mapa.get_used_rect()
	if usado.size.x <= 0 or usado.size.y <= 0:
		_camera_sem_limites()
		return

	var ts := Vector2(mapa.tile_set.tile_size)
	var canto_a: Vector2 = mapa.to_global(Vector2(usado.position) * ts)
	var canto_b: Vector2 = mapa.to_global(Vector2(usado.end) * ts)

	camera.limit_left = int(floor(minf(canto_a.x, canto_b.x)))
	camera.limit_top = int(floor(minf(canto_a.y, canto_b.y)))
	camera.limit_right = int(ceil(maxf(canto_a.x, canto_b.x)))
	camera.limit_bottom = int(ceil(maxf(canto_a.y, canto_b.y)))

func _camera_sem_limites() -> void:
	camera.limit_left = -10000000
	camera.limit_top = -10000000
	camera.limit_right = 10000000
	camera.limit_bottom = 10000000

func _achar_tilemap(no: Node) -> TileMapLayer:
	if no == null:
		return null
	if no is TileMapLayer:
		return no
	for filho in no.get_children():
		var achado := _achar_tilemap(filho)
		if achado != null:
			return achado
	return null

# ------------------------------------------------------------------ velocidade
func velocidade_atual() -> float:
	var peso := 0
	if get_node_or_null("/root/GameState") != null:
		peso = GameState.peso_total()
	return maxf(velocidade_minima, velocidade_base - peso * lentidao_por_item)

func dano_total() -> int:
	var bonus := 0
	if get_node_or_null("/root/GameState") != null:
		bonus = GameState.bonus_ataque()
	return ataque_base + bonus

func defesa_total() -> int:
	var bonus := 0
	if get_node_or_null("/root/GameState") != null:
		bonus = GameState.bonus_defesa()
	return defesa_base + bonus

# ------------------------------------------------------------------ loop
func _physics_process(delta: float) -> void:
	if not vivo:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _invulneravel > 0.0:
		_invulneravel -= delta
	if _coleta_cooldown > 0.0:
		_coleta_cooldown -= delta

	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir == Vector2.ZERO:
		dir = Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		)

	if _atacando:
		velocity = Vector2.ZERO
	else:
		velocity = dir.normalized() * velocidade_atual()
	move_and_slide()

	if not _atacando:
		_atualizar_animacao(dir)

	if Input.is_action_just_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_X):
		atacar()

	_coletar_proximos()

func _atualizar_animacao(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		if absf(dir.x) >= absf(dir.y):
			direcao = "right" if dir.x > 0.0 else "left"
		else:
			direcao = "down" if dir.y > 0.0 else "up"
		anim.play("walk_" + direcao)
	else:
		anim.play("idle_" + direcao)

# ------------------------------------------------------------------ ataque
func atacar() -> void:
	if _atacando or not vivo:
		return
	_atacando = true
	# usa a animação de "hurt" como esboço de ataque até existir a folha própria
	if anim.sprite_frames.has_animation("hurt_" + direcao):
		anim.play("hurt_" + direcao)

	var alvo_dir := _vetor_direcao()
	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		if not is_instance_valid(inimigo):
			continue
		var delta_pos: Vector2 = inimigo.global_position - global_position
		if delta_pos.length() <= alcance_ataque and delta_pos.normalized().dot(alvo_dir) > 0.35:
			if inimigo.has_method("receber_dano"):
				inimigo.receber_dano(dano_total())

	await get_tree().create_timer(duracao_ataque).timeout
	_atacando = false

func _vetor_direcao() -> Vector2:
	match direcao:
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"left": return Vector2.LEFT
		_: return Vector2.RIGHT

# ------------------------------------------------------------------ dano/morte
func receber_dano(quantidade: int) -> void:
	if not vivo or _invulneravel > 0.0:
		return
	var final: int = maxi(1, quantidade - defesa_total())
	vida = maxi(0, vida - final)
	_invulneravel = invulnerabilidade
	vida_alterada.emit(vida, vida_maxima)
	modulate = Color(1, 0.5, 0.5)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.3)
	if vida <= 0:
		morrer()

## Recupera vida (raiz de unha-de-gato, cuia com água...)
func curar(quantidade: int) -> void:
	if not vivo or quantidade <= 0:
		return
	vida = mini(vida_maxima, vida + quantidade)
	vida_alterada.emit(vida, vida_maxima)
	modulate = Color(0.6, 1, 0.6)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.3)

func morrer() -> void:
	if not vivo:
		return
	vivo = false
	velocity = Vector2.ZERO
	anim.play("death_" + direcao)
	if get_node_or_null("/root/GameState") != null:
		var perdidos: Dictionary = GameState.aplicar_morte()
		GameState.registrar_esqueleto(global_position, perdidos)
	morreu.emit()

func _on_anim_finished() -> void:
	if _atacando and anim.animation.begins_with("hurt_"):
		anim.play("idle_" + direcao)

# ------------------------------------------------------------------ itens
func _coletar_proximos() -> void:
	if _coleta_cooldown > 0.0:
		return
	for item in get_tree().get_nodes_in_group("itens"):
		if not is_instance_valid(item):
			continue
		if global_position.distance_to(item.global_position) < 20.0:
			if item.has_method("coletar"):
				item.coletar()
				_coleta_cooldown = 0.15
			return

# ------------------------------------------------------------------ tocha
## Quando a chama fica baixa, queima sozinha o combustível equipado
## no espaço "Chama" (graveto, folhas secas).
func _consumir_combustivel() -> void:
	if get_node_or_null("/root/GameState") == null:
		return
	var combustivel: String = GameState.item_equipado(ItemDB.SLOT_TOCHA)
	if combustivel == "":
		return
	var ganho := ItemDB.recarrega_tocha(combustivel)
	if ganho <= 0.0:
		return
	GameState.desequipar(ItemDB.SLOT_TOCHA)
	reabastecer_tocha(ganho)

func _process(delta: float) -> void:
	if not vivo:
		return
	if _tocha_restante > 0.0:
		_tocha_restante = maxf(0.0, _tocha_restante - delta)
		tocha_alterada.emit(_tocha_restante, tocha_segundos)
		if _tocha_restante < tocha_segundos * 0.15:
			_consumir_combustivel()
		if _tocha_restante <= 0.0:
			# tocha apagou: mesma penalidade da morte (SGDD)
			morrer()
	var t: float = _tocha_restante / tocha_segundos
	tocha.texture_scale = lerpf(tocha_escala_min, tocha_escala_max, t)
	tocha.energia_atual = lerpf(0.15, 1.5, t)

func reabastecer_tocha(segundos: float) -> void:
	_tocha_restante = minf(tocha_segundos, _tocha_restante + segundos)
