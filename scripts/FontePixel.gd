class_name FontePixel
extends RefCounted

## Biblioteca da fonte pixel art (Font_pixelart), montada a partir do
## res://sprites/font/Font_pixelart.fnt (BMFont apontando pro PNG).
##
##   FontePixel.fonte()                    -> o FontFile (carregado uma vez)
##   FontePixel.aplicar(label, cor, tam)   -> põe fonte + cor + tamanho num Label
##   FontePixel.rotulo(texto, cor, tam)    -> cria um Label já na fonte pixel
##
## Cobre A-Z, a-z, 0-9 e . , ; : ? ! . Os acentuados são mapeados para a
## letra base no próprio .fnt (á->a, ç->c, ã->a...), então texto com acento
## escreve normalmente (sem o acento desenhado). Símbolos sem glifo
## (✓, ✕, →, R$, %, -, / ...) simplesmente não aparecem.

const CAMINHO := "res://sprites/font/Font_pixelart.fnt"
const TAMANHO_BASE := 12   # tamanho nativo dos glifos, em pixels


## Devolve o FontFile da fonte pixel, ou null se o arquivo faltar.
static func fonte() -> FontFile:
	if ResourceLoader.exists(CAMINHO):
		return load(CAMINHO)   # load() já mantém a fonte em cache
	return null


## Aplica a fonte pixel (+ cor e tamanho) a um Label que já existe.
## Se a fonte não carregar, mantém a fonte padrão e só ajusta a cor.
static func aplicar(alvo: Label, cor: Color = Color.WHITE, tamanho: int = TAMANHO_BASE) -> void:
	var f := fonte()
	if f != null:
		alvo.add_theme_font_override("font", f)
		alvo.add_theme_font_size_override("font_size", tamanho)
		alvo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	alvo.add_theme_color_override("font_color", cor)


## Aplica só a fonte pixel (+ tamanho) a qualquer Control com tema de fonte
## — Button, Label, etc. Não mexe na cor.
static func aplicar_fonte(ctrl: Control, tamanho: int = TAMANHO_BASE) -> void:
	var f := fonte()
	if f != null:
		ctrl.add_theme_font_override("font", f)
		ctrl.add_theme_font_size_override("font_size", tamanho)
		ctrl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Cria um Label já com a fonte pixel, cor e texto.
static func rotulo(texto: String, cor: Color = Color.WHITE, tamanho: int = TAMANHO_BASE) -> Label:
	var l := Label.new()
	l.text = texto
	aplicar(l, cor, tamanho)
	return l
