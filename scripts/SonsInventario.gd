class_name SonsInventario
extends RefCounted

## Sons do inventário sintetizados em código (sem arquivos de áudio):
##  - abrir(): chiado curto da trança + um "toc" grave de madeira ao assentar;
##  - fechar(): chiado mais curto e seco.
## Retornam AudioStreamWAV prontos para tocar num AudioStreamPlayer.

const TAXA := 22050


static func _wav(amostras: PackedFloat32Array) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = TAXA
	s.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(amostras.size() * 2)
	for i in amostras.size():
		var v := clampf(amostras[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(round(v * 32767.0)))
	s.data = bytes
	return s


## Chiado do cesto abrindo + toc de madeira ao assentar (~0.28s).
static func abrir() -> AudioStreamWAV:
	var n := int(0.28 * TAXA)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260909
	var lp := 0.0   # estado do passa-baixa (suaviza o ruído)
	for i in n:
		var t := float(i) / TAXA
		# envelope do chiado: ataque rápido, cauda média
		var env := exp(-t * 13.0) * (1.0 - exp(-t * 80.0))
		var ruido := rng.randf_range(-1.0, 1.0)
		lp += (ruido - lp) * 0.32
		var rustle := lp * env * 0.5
		# "toc" grave de madeira, entrando um pouco depois (o assentar)
		var td := t - 0.11
		var toc := 0.0
		if td > 0.0:
			toc = sin(td * TAU * 165.0) * exp(-td * 24.0) * 0.32
		buf[i] = rustle + toc
	return _wav(buf)


## Chiado curto e seco ao fechar (~0.18s).
static func fechar() -> AudioStreamWAV:
	var n := int(0.18 * TAXA)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var lp := 0.0
	for i in n:
		var t := float(i) / TAXA
		var env := exp(-t * 22.0) * (1.0 - exp(-t * 110.0))
		var ruido := rng.randf_range(-1.0, 1.0)
		lp += (ruido - lp) * 0.28
		buf[i] = lp * env * 0.42
	return _wav(buf)
