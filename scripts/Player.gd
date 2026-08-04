extends CharacterBody2D

## Pari - movimento 8 direções, ataque, dano, morte,
## tocha com duração e peso do inventário afetando a velocidade.
## Setas/WASD para andar, ESPAÇO (ou X) para atacar, E para interagir
## (pegar itens do chão e ler pinturas), I para a mochila.

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

## Arremesso (pedrinhas)
@export var escala_projetil: float = 3.0
@export var distancia_saida_projetil: float = 40.0

## Alcance da tecla E (pegar item, ler pintura)
@export var alcance_interacao: float = 70.0

## Modo de teste (God): velocidade fixa, sem dano, atravessa rocha
@export var velocidade_god: float = 420.0

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
var _god_aplicado: bool = false
var _mascara_original: int = 1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var tocha: PointLight2D = $TorchLight
@onready var camera: Camera2D = $Camera2D
@onready var som_passos: AudioStreamPlayer2D = $passos

func _ready() -> void:
	vida = vida_maxima
	_tocha_restante = tocha_segundos
	add_to_group("player")
	_mascara_original = collision_mask
	vida_alterada.emit(vida, vida_maxima)
	if god():
		_god_aplicado = true
		_aplicar_god(true)
	if anim.sprite_frames != null and anim.sprite_frames.has_animation("unarmed_hurt_down"):
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

# ------------------------------------------------------------------ aparência
## Conjunto de sprites conforme o que está na mão: "sword" ou "unarmed"
func conjunto() -> String:
	if get_node_or_null("/root/GameState") == null:
		return "unarmed"
	var arma: String = GameState.item_equipado(ItemDB.SLOT_ARMA)
	if arma != "" and ItemDB.visual(arma) == "sword":
		return "sword"
	return "unarmed"

## Monta o nome da animação, com quedas seguras quando a folha não existe.
## (hoje só há folha de ataque para o conjunto armado)
func _anim(acao: String) -> String:
	if anim.sprite_frames == null:
		return ""
	var nome: String = "%s_%s_%s" % [conjunto(), acao, direcao]
	if anim.sprite_frames.has_animation(nome):
		return nome
	var alternativa: String = "unarmed_%s_%s" % [acao, direcao]
	if anim.sprite_frames.has_animation(alternativa):
		return alternativa
	# sem folha de soco desarmado: usa o "hurt" como esboço do golpe
	if acao == "attack":
		var esboco: String = "unarmed_hurt_" + direcao
		if anim.sprite_frames.has_animation(esboco):
			return esboco
	return "unarmed_idle_" + direcao

# ------------------------------------------------------------------ modo God
func god() -> bool:
	if get_node_or_null("/root/GameState") == null:
		return false
	return GameState.modo_god

## Liga/desliga a travessia de rocha e devolve a vida cheia ao ligar
func _aplicar_god(ligado: bool) -> void:
	if ligado:
		collision_mask = 0          # atravessa paredes
		vida = vida_maxima
		vida_alterada.emit(vida, vida_maxima)
		modulate = Color(1, 1, 0.6)
	else:
		collision_mask = _mascara_original
		modulate = Color.WHITE

# ------------------------------------------------------------------ velocidade
func velocidade_atual() -> float:
	if god():
		return velocidade_god      # rápido e sem peso
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

	# liga/desliga o modo de teste quando ele muda
	var g := god()
	if g != _god_aplicado:
		_god_aplicado = g
		_aplicar_god(g)

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
	_atualizar_som_passos()

	if not _atacando:
		_atualizar_animacao(dir)

	if Input.is_action_just_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_X):
		atacar()

	if Input.is_physical_key_pressed(KEY_E):
		_interagir()

func _atualizar_som_passos() -> void:
	# Verifica se o personagem está se movendo (velocidade maior que zero)
	if velocity.length() > 0.0:
		# Se estiver andando e o som AINDA não estiver tocando, inicia o som
		if not som_passos.playing:
			som_passos.play()
	else:
		# Se parou de andar e o som ESTÁ tocando, interrompe imediatamente
		if som_passos.playing:
			som_passos.stop()

func _atualizar_animacao(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		if absf(dir.x) >= absf(dir.y):
			direcao = "right" if dir.x > 0.0 else "left"
		else:
			direcao = "down" if dir.y > 0.0 else "up"
		anim.flip_h = (direcao == "left")
		anim.play(_anim("walk"))
	else:
		anim.flip_h = (direcao == "left")
		anim.play(_anim("idle"))

# ------------------------------------------------------------------ ataque
func atacar() -> void:
	if _atacando or not vivo:
		return
	_atacando = true
	var arma := ""
	if get_node_or_null("/root/GameState") != null:
		arma = GameState.item_equipado(ItemDB.SLOT_ARMA)

	if arma != "" and ItemDB.e_arremesso(arma):
		anim.play(_anim("idle"))
		_arremessar(arma)
	else:
		anim.play(_anim("attack"))
		_golpear()

	await get_tree().create_timer(duracao_ataque).timeout
	_atacando = false

## Golpe corpo a corpo no cone à frente
func _golpear() -> void:
	var alvo_dir := _vetor_direcao()
	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		if not is_instance_valid(inimigo):
			continue
		var delta_pos: Vector2 = inimigo.global_position - global_position
		if delta_pos.length() <= alcance_ataque and delta_pos.normalized().dot(alvo_dir) > 0.35:
			if inimigo.has_method("receber_dano"):
				inimigo.receber_dano(dano_total())

## Lança uma pedrinha na direção em que Pari olha
func _arremessar(arma: String) -> void:
	var cena := load("res://cenas/Projetil.tscn") as PackedScene
	if cena == null:
		return
	var p := cena.instantiate()
	# definido antes de entrar na árvore: o _ready do projétil usa estes valores
	p.direcao = _vetor_direcao()
	p.dano = dano_total()
	p.nome_item = arma
	p.scale = Vector2.ONE * escala_projetil
	get_parent().add_child(p)
	p.global_position = global_position + _vetor_direcao() * distancia_saida_projetil

func _vetor_direcao() -> Vector2:
	match direcao:
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"left": return Vector2.LEFT
		_: return Vector2.RIGHT

# ------------------------------------------------------------------ dano/morte
func receber_dano(quantidade: int) -> void:
	if not vivo or _invulneravel > 0.0 or god():
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
	anim.play(_anim("death"))
	if get_node_or_null("/root/GameState") != null:
		var perdidos: Dictionary = GameState.aplicar_morte()
		GameState.registrar_esqueleto(global_position, perdidos)
	morreu.emit()

func _on_anim_finished() -> void:
	if _atacando and anim.animation.contains("_attack_"):
		anim.play(_anim("idle"))

# ------------------------------------------------------------------ interação (E)
## Pega itens do chão e lê pinturas rupestres: sempre o alvo mais próximo.
func _interagir() -> void:
	if _coleta_cooldown > 0.0:
		return
	var alvo: Node = null
	var menor: float = alcance_interacao
	for obj in get_tree().get_nodes_in_group("interagivel"):
		if not is_instance_valid(obj) or not obj.has_method("interagir"):
			continue
		var d: float = global_position.distance_to(obj.global_position)
		if d <= menor:
			menor = d
			alvo = obj
	if alvo != null:
		alvo.interagir()
		_coleta_cooldown = 0.35

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
	if god():
		_tocha_restante = tocha_segundos
	if _tocha_restante > 0.0 and not god():
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
