extends Area2D

## Pedrinha arremessada por Pari.
## Voa reto, machuca a primeira criatura que encostar e
## se despedaça ao bater na rocha ou ao esgotar o alcance.

@export var velocidade: float = 520.0
@export var alcance: float = 950.0
@export var dano: int = 6
@export var nome_item: String = "pedras"

var direcao: Vector2 = Vector2.RIGHT
var _percorrido: float = 0.0

func _ready() -> void:
	# camada 8 (projétil), enxerga rocha (1) e criaturas (4)
	collision_layer = 8
	collision_mask = 1 | 4
	body_entered.connect(_on_encostou)
	_montar_visual()
	rotation = direcao.angle()

func _montar_visual() -> void:
	var tex := ItemDB.icone(nome_item)
	if tex != null:
		var sp := Sprite2D.new()
		sp.texture = tex
		var lado: float = maxf(tex.get_width(), tex.get_height())
		if lado > 16.0:
			sp.scale = Vector2.ONE * (16.0 / lado)
		add_child(sp)
	else:
		var marca := Polygon2D.new()
		marca.polygon = PackedVector2Array([
			Vector2(-4, -3), Vector2(4, -4), Vector2(5, 3), Vector2(-3, 4)
		])
		marca.color = Color(0.62, 0.6, 0.58)
		add_child(marca)

	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 5.0
	forma.shape = circulo
	add_child(forma)

func _physics_process(delta: float) -> void:
	var passo: float = velocidade * delta
	position += direcao * passo
	_percorrido += passo
	if _percorrido >= alcance:
		_despedacar()

func _on_encostou(corpo: Node) -> void:
	if corpo.has_method("receber_dano"):
		corpo.receber_dano(dano)
	_despedacar()

func _despedacar() -> void:
	set_physics_process(false)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(0.3, 0.3), 0.12)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.12)
	t.tween_callback(queue_free)
