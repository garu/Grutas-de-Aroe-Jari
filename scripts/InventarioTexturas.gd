class_name InventarioTexturas
extends RefCounted

## Fornece a arte da moldura do inventário:
##  - os quadros de CRESCIMENTO (o desdobrar) são recortados da folha
##    res://sprites/UI/Inventario.png;
##  - o estado TOTALMENTE ABERTO (e o fundo em repouso) usa a versão limpa
##    res://sprites/UI/Inventario2.png, porque o fundo sem trama deixa os
##    itens mais legíveis.
## O Inventario.gd usa isto quando não há PNGs separados (inventario_frame_0*.png).

const FOLHA := "res://sprites/UI/Inventario.png"
const LIMPO := "res://sprites/UI/Inventario2.png"

## Regiões dos quadros de crescimento dentro da folha (medidas do PNG 402x157).
## Só os dois menores; o quadro cheio é substituído pelo fundo limpo.
const REGIOES := [
	Rect2i(34, 42, 68, 67),
	Rect2i(159, 32, 85, 92),
]

## Canvas comum: cada quadro é centralizado nele, para crescerem concêntricos.
const CANVAS := Vector2i(134, 156)


static func _folha_img() -> Image:
	if not ResourceLoader.exists(FOLHA):
		return null
	var tex := load(FOLHA) as Texture2D
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


static func _recortar(reg: Rect2i, folha: Image) -> Texture2D:
	var canvas := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	var destino := Vector2i((CANVAS.x - reg.size.x) / 2, (CANVAS.y - reg.size.y) / 2)
	canvas.blit_rect(folha, reg, destino)
	return ImageTexture.create_from_image(canvas)


## Textura do estado totalmente aberto (fundo limpo), ou null.
static func aberto() -> Texture2D:
	if ResourceLoader.exists(LIMPO):
		return load(LIMPO)
	return null


## Quadros do desdobrar, na ordem fechado -> aberto: os menores trançados
## e, por último, o fundo limpo. Vazio se faltar tudo.
static func quadros() -> Array[Texture2D]:
	var r: Array[Texture2D] = []
	var folha := _folha_img()
	if folha != null:
		for reg in REGIOES:
			r.append(_recortar(reg, folha))
	var limpo := aberto()
	if limpo != null:
		r.append(limpo)
	return r


## Um quadro específico (1..N). O último índice é sempre o fundo limpo (aberto).
static func frame(n: int) -> Texture2D:
	var total := REGIOES.size() + 1
	if n == total:
		return aberto()
	if n < 1 or n > REGIOES.size():
		return null
	var folha := _folha_img()
	if folha == null:
		return null
	return _recortar(REGIOES[n - 1], folha)
