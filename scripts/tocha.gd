class_name Tocha
extends PointLight2D

## Chama do Pari: um halo redondo que treme feito fogo de verdade.
## O Player.gd é quem manda no tamanho e no brilho conforme o
## combustível que ainda resta; aqui só acontece o tremular.

## Brilho ao redor do qual a chama oscila.
@export var energia_atual: float = 2.0

## Quanto o brilho sobe e desce a cada tremida.
@export var oscilacao_tocha: float = 0.1

## Tremidas por segundo. Valores altos deixam a chama nervosa demais.
@export var tremidas_por_segundo: float = 14.0

var _energia_alvo: float = 0.0
var _tempo_ate_tremer: float = 0.0

func _ready() -> void:
	_energia_alvo = energia_atual
	energy = energia_atual

func _process(delta: float) -> void:
	_tempo_ate_tremer -= delta
	if _tempo_ate_tremer <= 0.0:
		_energia_alvo = randf_range(
			energia_atual - oscilacao_tocha,
			energia_atual + oscilacao_tocha
		)
		_tempo_ate_tremer = 1.0 / maxf(1.0, tremidas_por_segundo)

	# Vai até o novo brilho em vez de saltar: o fogo pisca, não pula.
	energy = lerpf(energy, maxf(0.0, _energia_alvo), minf(1.0, delta * 12.0))
