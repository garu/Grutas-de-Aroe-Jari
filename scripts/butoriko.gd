class_name Butoriko
extends CharacterBody2D

@export_group("Sons")

@export var som_rosnado: AudioStream
@export var tempo_minimo_rosnado: float = 30.0
@export var tempo_maximo_rosnado: float = 120.0
@export var distancia_maxima_som: float = 800.0

## Atenuação sonora (1.0 = linear, >1.0 o som cai mais rápido com a distância).
@export var atenuacao_som: float = 1.0

@export_group("Movimento")

## Velocidade de movimento em pixels por segundo.
@export var velocidade: float = 80.0

## Tempo mínimo entre mudanças aleatórias de direção.
@export var tempo_minimo_de_mudanca_de_direcao: float = 0.8

## Tempo máximo entre mudanças aleatórias de direção.
@export var tempo_maximo_de_mudanca_de_direcao: float = 2.5

## Se verdadeiro, a cobra evita virar de costas imediatamente,
## a menos que não haja outra opção.
@export var evitar_reversao: bool = true

## Distância usada para testar se uma direção está bloqueada.
@export var distancia_de_sondagem_de_colisao: float = 10.0

## Margem extra usada na sondagem de colisão.
@export var margem_segura_de_colisao: float = 0.0


@export_group("Perseguicao")

## Se verdadeiro, a cobra persegue o jogador quando o enxerga.
@export var ativar_perseguicao: bool = true

## Caminho para o nó do jogador.
## Exemplo: ../Jogador
## Se ficar vazio, o script tentará encontrar um nó no grupo "jogador".
@export var caminho_do_jogador: NodePath

## Distância máxima para a cobra notar o jogador.
## Use 0 ou negativo para deixar o raio ilimitado.
@export var raio_de_deteccao: float = 180.0

## Multiplicador de velocidade enquanto estiver perseguindo.
## 1.0 significa a mesma velocidade do modo aleatório.
@export var multiplicador_de_velocidade_de_perseguicao: float = 1.2

## Camadas de física que bloqueiam a visão da cobra.
## Normalmente deve incluir a camada de colisão das paredes do TileMapLayer.
@export var mascara_de_colisao_da_visao: int = 1


@export_group("Rastro")

## PNG transparente usado para cada marca do rastro.
@export var textura_da_marca: Texture2D

## Local onde as marcas do rastro serão adicionadas.
## Se a Cobra e as MarcasDeRastro forem irmãs, use: ../MarcasDeRastro
## Se ficar vazio, a cobra usará o próprio pai.
@export var caminho_do_recipiente_de_marcas: NodePath

## Intervalo mínimo, em segundos, entre marcas do rastro.
@export var intervalo_minimo_da_marca: float = 0.35

## Intervalo máximo, em segundos, entre marcas do rastro.
@export var intervalo_maximo_da_marca: float = 1.25

## Se maior que 0, evita gerar marcas muito próximas umas das outras.
@export var distancia_minima_entre_marcas: float = 0.0

## Move a marca para frente ou para trás ao longo da direção do movimento.
## Valores negativos colocam a marca atrás da cobra.
@export var deslocamento_frontal_da_marca: float = 0.0

## Escala uniforme da marca do rastro.
@export var escala_da_marca: float = 1.0

## Cor/modulação da marca do rastro. O alpha controla a transparência.
@export var cor_da_marca: Color = Color(1.0, 1.0, 1.0, 0.7)

## Z index de cada marca do rastro.
@export var indice_z_da_marca: int = -1

## Deslocamento de rotação da marca em graus.
## Se a sua PNG aponta para:
## - Direita: use 0
## - Cima: use 90
## - Baixo: use -90
## - Esquerda: use 180
@export_range(-360.0, 360.0, 1.0)
var deslocamento_de_rotacao_da_marca_em_graus: float = 0.0

## Quantidade máxima de marcas mantidas na cena.
## Use 0 para desativar a limpeza automática por quantidade.
@export var maximo_de_marcas: int = 300

## Se maior que 0, as marcas desaparecem após essa quantidade de segundos.
## Use 0 para torná-las permanentes.
@export var tempo_de_vida_da_marca: float = 0.0


const DIRECOES := [
	Vector2.RIGHT,
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2.UP,
]

var direcao_atual := Vector2.RIGHT
var jogador: Node2D

var recipiente_de_marcas: Node2D
var marcas: Array[Node] = []
var temporizador_de_direcao: Timer
var temporizador_de_marcas: Timer
var tem_ultima_posicao_de_marca := false
var ultima_posicao_de_marca := Vector2.ZERO
var estava_perseguindo := false

var reproductor_rosnado: AudioStreamPlayer2D
var temporizador_de_rosnado: Timer

func _ready() -> void:
	randomize()

	# Importante para movimento top-down.
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	temporizador_de_direcao = _garantir_temporizador("TemporizadorDeDirecao")
	temporizador_de_marcas = _garantir_temporizador("TemporizadorDeMarcas")

	temporizador_de_direcao.one_shot = true
	temporizador_de_marcas.one_shot = true

	temporizador_de_direcao.timeout.connect(_ao_expirar_temporizador_de_direcao)
	temporizador_de_marcas.timeout.connect(_ao_expirar_temporizador_de_marcas)

	_resolver_jogador()
	_resolver_recipiente_de_marcas()
	_configurar_audio_rosnado()

	_escolher_nova_direcao()
	_reiniciar_temporizador_de_direcao()
	_reiniciar_temporizador_de_marcas()

	if textura_da_marca == null:
		push_warning("CobraErrante: textura_da_marca está vazia. Nenhuma marca de rastro será gerada.")

	if ativar_perseguicao and jogador == null:
		push_warning("CobraErrante: jogador não encontrado. Defina caminho_do_jogador ou coloque o jogador no grupo 'jogador'.")

func _atacar_jogador() -> void:
	if jogador.has_method("receber_dano"):
		jogador.receber_dano(10)

func _physics_process(_delta_tempo: float) -> void:
	# Verifica se encostou no jogador (distância em pixels, ex: 25 pixels)
	if jogador != null and is_instance_valid(jogador):
		if global_position.distance_to(jogador.global_position) <= 25.0:
			_atacar_jogador()
			
	# Tenta perseguir primeiro. Se conseguir perseguindo, ignora o modo aleatório neste frame.
	if ativar_perseguicao and _tentar_perseguir_jogador():
		return

	# Se acabou de parar de perseguir, volta ao modo aleatório de forma limpa.
	if estava_perseguindo:
		estava_perseguindo = false
		_reiniciar_temporizador_de_direcao()

	if direcao_atual == Vector2.ZERO:
		_escolher_nova_direcao()

	velocity = direcao_atual * velocidade
	move_and_slide()

	# Se colidiu/deslizou contra algo e a direção atual está bloqueada,
	# escolhe uma nova direção.
	if get_slide_collision_count() > 0 and not _direcao_esta_livre(direcao_atual):
		_escolher_nova_direcao()
		_reiniciar_temporizador_de_direcao()


func _garantir_temporizador(nome_do_temporizador: String) -> Timer:
	var temporizador := get_node_or_null(nome_do_temporizador) as Timer

	if temporizador == null:
		temporizador = Timer.new()
		temporizador.name = nome_do_temporizador
		add_child(temporizador)

	return temporizador


func _resolver_jogador() -> void:
	jogador = null

	if caminho_do_jogador != NodePath(""):
		var no := get_node_or_null(caminho_do_jogador)
		if no is Node2D:
			jogador = no

	# Alternativa: encontrar o jogador pelo grupo "jogador".
	if jogador == null:
		var jogadores := get_tree().get_nodes_in_group("jogador")
		if jogadores.size() > 0 and jogadores[0] is Node2D:
			jogador = jogadores[0]


func _resolver_recipiente_de_marcas() -> void:
	recipiente_de_marcas = null

	if caminho_do_recipiente_de_marcas != NodePath(""):
		var no := get_node_or_null(caminho_do_recipiente_de_marcas)
		if no is Node2D:
			recipiente_de_marcas = no

	if recipiente_de_marcas == null:
		recipiente_de_marcas = get_parent() as Node2D


func _reiniciar_temporizador_de_direcao() -> void:
	var valor_minimo := maxf(0.02, tempo_minimo_de_mudanca_de_direcao)
	var valor_maximo := maxf(valor_minimo, tempo_maximo_de_mudanca_de_direcao)

	temporizador_de_direcao.wait_time = randf_range(valor_minimo, valor_maximo)
	temporizador_de_direcao.start()


func _reiniciar_temporizador_de_marcas() -> void:
	var valor_minimo := maxf(0.02, intervalo_minimo_da_marca)
	var valor_maximo := maxf(valor_minimo, intervalo_maximo_da_marca)

	temporizador_de_marcas.wait_time = randf_range(valor_minimo, valor_maximo)
	temporizador_de_marcas.start()


func _ao_expirar_temporizador_de_direcao() -> void:
	_escolher_nova_direcao()
	_reiniciar_temporizador_de_direcao()


func _ao_expirar_temporizador_de_marcas() -> void:
	_gerar_marca()
	_reiniciar_temporizador_de_marcas()


func _tentar_perseguir_jogador() -> bool:
	if not _conseguir_ver_jogador():
		return false
		
	# Se não estava perseguindo no frame anterior, é o primeiro instante de detecção!
	if not estava_perseguindo:
		_tocar_rosnado()

	# Para as mudanças aleatórias de direção enquanto estiver perseguindo.
	temporizador_de_direcao.stop()

	if jogador == null or not is_instance_valid(jogador):
		return false

	var direcao := (jogador.global_position - global_position).normalized()

	if direcao == Vector2.ZERO:
		velocity = Vector2.ZERO
		move_and_slide()
		estava_perseguindo = true
		return true

	direcao_atual = direcao
	velocity = direcao_atual * velocidade * maxf(0.0, multiplicador_de_velocidade_de_perseguicao)

	move_and_slide()

	estava_perseguindo = true
	return true


func _conseguir_ver_jogador() -> bool:
	if not ativar_perseguicao:
		return false

	if jogador == null or not is_instance_valid(jogador):
		_resolver_jogador()
		if jogador == null:
			return false

	var vetor_para_o_jogador := jogador.global_position - global_position

	if raio_de_deteccao > 0.0 and vetor_para_o_jogador.length() > raio_de_deteccao:
		return false

	# Raycast de linha de visão.
	# Se o raio chegar ao jogador sem acertar algo que bloqueie a visão,
	# a cobra consegue ver o jogador.
	var estado_do_espaco := get_world_2d().direct_space_state

	var rids_excluidos: Array[RID] = []
	rids_excluidos.append(get_rid())

	var consulta := PhysicsRayQueryParameters2D.create(
		global_position,
		jogador.global_position,
		mascara_de_colisao_da_visao,
		rids_excluidos
	)

	consulta.collide_with_areas = false
	consulta.collide_with_bodies = true

	var resultado := estado_do_espaco.intersect_ray(consulta)

	# Nada bloqueou o raio.
	if resultado.is_empty():
		return true

	# Se o raio acertou diretamente o jogador, também considera que viu.
	var colisor: Object = resultado.get("collider")
	if colisor == jogador:
		return true

	return false


func _escolher_nova_direcao() -> void:
	var candidatas := DIRECOES.duplicate()
	candidatas.shuffle()

	var preferidas := []
	var reversas := []

	for direcao in candidatas:
		if evitar_reversao and direcao_atual != Vector2.ZERO and direcao == -direcao_atual:
			reversas.append(direcao)
		else:
			preferidas.append(direcao)

	# Tenta primeiro direções que não sejam reversão.
	for direcao in preferidas:
		if _direcao_esta_livre(direcao):
			direcao_atual = direcao
			return

	# Se necessário, permite reversão.
	for direcao in reversas:
		if _direcao_esta_livre(direcao):
			direcao_atual = direcao
			return

	# Último caso.
	if direcao_atual == Vector2.ZERO:
		direcao_atual = candidatas[randi() % candidatas.size()]
	else:
		direcao_atual = -direcao_atual


func _direcao_esta_livre(direcao: Vector2) -> bool:
	if direcao == Vector2.ZERO:
		return false

	var distancia := maxf(1.0, distancia_de_sondagem_de_colisao)
	var margem := maxf(0.0, margem_segura_de_colisao)

	# test_only = true, então isso não move o corpo de verdade.
	var colisao := move_and_collide(direcao * distancia, true, margem)

	return colisao == null


func _gerar_marca() -> void:
	if textura_da_marca == null:
		return

	if direcao_atual == Vector2.ZERO:
		return

	if recipiente_de_marcas == null:
		_resolver_recipiente_de_marcas()

	if recipiente_de_marcas == null:
		return

	var posicao_da_marca := global_position + direcao_atual * deslocamento_frontal_da_marca

	# Filtro opcional por distância.
	# Isso evita muitas marcas acumuladas quando a cobra está parada/travada.
	if distancia_minima_entre_marcas > 0.0 and tem_ultima_posicao_de_marca:
		if posicao_da_marca.distance_to(ultima_posicao_de_marca) < distancia_minima_entre_marcas:
			return

	var marca := Sprite2D.new()
	marca.texture = textura_da_marca
	marca.modulate = cor_da_marca
	marca.scale = Vector2.ONE * escala_da_marca
	marca.z_index = indice_z_da_marca
	marca.rotation = direcao_atual.angle() + deg_to_rad(deslocamento_de_rotacao_da_marca_em_graus)

	recipiente_de_marcas.add_child(marca)
	marca.global_position = posicao_da_marca

	marcas.append(marca)

	ultima_posicao_de_marca = posicao_da_marca
	tem_ultima_posicao_de_marca = true

	# Limpeza opcional: remover marcas mais antigas.
	if maximo_de_marcas > 0:
		while marcas.size() > maximo_de_marcas:
			var marca_antiga: Node = marcas.pop_front()
			if is_instance_valid(marca_antiga):
				marca_antiga.queue_free()

	# Limpeza opcional: remover marcas após tempo de vida.
	if tempo_de_vida_da_marca > 0.0:
		get_tree().create_timer(tempo_de_vida_da_marca).timeout.connect(
			func():
				if is_instance_valid(marca):
					marcas.erase(marca)
					marca.queue_free()
		)

func _configurar_audio_rosnado() -> void:
	# Cria ou obtém o player de áudio 2D posicionado no próprio boss
	reproductor_rosnado = get_node_or_null("ReproductorRosnado") as AudioStreamPlayer2D
	if reproductor_rosnado == null:
		reproductor_rosnado = AudioStreamPlayer2D.new()
		reproductor_rosnado.name = "ReproductorRosnado"
		add_child(reproductor_rosnado)

	if som_rosnado != null:
		reproductor_rosnado.stream = som_rosnado

	reproductor_rosnado.max_distance = distancia_maxima_som
	reproductor_rosnado.attenuation = atenuacao_som

	# Configura o temporizador do rosnado
	temporizador_de_rosnado = _garantir_temporizador("TemporizadorDeRosnado")
	temporizador_de_rosnado.one_shot = true
	temporizador_de_rosnado.timeout.connect(_ao_expirar_temporizador_de_rosnado)
	_reiniciar_temporizador_de_rosnado()


func _reiniciar_temporizador_de_rosnado() -> void:
	var v_min := maxf(0.1, tempo_minimo_rosnado)
	var v_max := maxf(v_min, tempo_maximo_rosnado)

	temporizador_de_rosnado.wait_time = randf_range(v_min, v_max)
	temporizador_de_rosnado.start()


func _ao_expirar_temporizador_de_rosnado() -> void:
	_tocar_rosnado()
	_reiniciar_temporizador_de_rosnado()


func _tocar_rosnado() -> void:
	if reproductor_rosnado != null and reproductor_rosnado.stream != null:
		reproductor_rosnado.play()
