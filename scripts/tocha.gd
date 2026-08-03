extends PointLight2D

@export var energia_atual: float = 2.0
@export var oscilacao_tocha: float = 0.1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	energy = randf_range(energia_atual - oscilacao_tocha, energia_atual + oscilacao_tocha)
