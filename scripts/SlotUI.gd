class_name SlotUI
extends Panel

## Um espaço do inventário: mochila, equipamento, bancada de mistura
## ou resultado. Sabe arrastar e receber itens.

enum Tipo { MOCHILA, EQUIP, CRAFT, RESULTADO }

signal item_solto(origem: SlotUI, destino: SlotUI)
signal item_clicado(slot: SlotUI)

var tipo: int = Tipo.MOCHILA
var indice: int = 0            ## posição na mochila ou na bancada
var slot_equip: String = ""    ## só para EQUIP: "arma", "tocha"...
var item: String = ""

var _icone: Control
var _selecionado: bool = false

const LADO := 28

func _init() -> void:
	custom_minimum_size = Vector2(LADO, LADO)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	_aplicar_estilo()
	_redesenhar()

func definir_item(nome: String) -> void:
	item = nome
	_redesenhar()

func marcar(ativo: bool) -> void:
	_selecionado = ativo
	_aplicar_estilo()

# ------------------------------------------------------------------ visual
func _aplicar_estilo() -> void:
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0.13, 0.11, 0.09, 0.95)
	e.border_color = Color(0.95, 0.78, 0.4) if _selecionado else Color(0.42, 0.33, 0.22)
	e.set_border_width_all(2 if _selecionado else 1)
	e.set_corner_radius_all(2)
	add_theme_stylebox_override("panel", e)

func _redesenhar() -> void:
	if _icone != null and is_instance_valid(_icone):
		_icone.queue_free()
		_icone = null
	if item == "":
		return
	_icone = _fazer_icone(item, LADO)
	add_child(_icone)

static func _fazer_icone(nome: String, lado: int) -> Control:
	var tex := ItemDB.icone(nome)
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return tr
	# marca provisória enquanto não há arte
	var base := Control.new()
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var marca := Polygon2D.new()
	var r: float = lado * 0.28
	marca.polygon = PackedVector2Array([
		Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)
	])
	marca.color = ItemDB.cor(nome)
	marca.position = Vector2(lado, lado) * 0.5
	base.add_child(marca)
	return base

# ------------------------------------------------------------------ regras
## Este espaço aceita o item indicado?
func aceita(nome: String) -> bool:
	if nome == "":
		return false
	match tipo:
		Tipo.EQUIP:
			return ItemDB.slot_de(nome) == slot_equip
		Tipo.RESULTADO:
			return false
		_:
			return true

# ------------------------------------------------------------------ arrastar
func _get_drag_data(_pos: Vector2) -> Variant:
	if item == "":
		return null
	var previa := Control.new()
	previa.custom_minimum_size = Vector2(LADO, LADO)
	previa.size = Vector2(LADO, LADO)
	var ic := _fazer_icone(item, LADO)
	previa.add_child(ic)
	previa.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(previa)
	return {"slot": self}

func _can_drop_data(_pos: Vector2, dados: Variant) -> bool:
	if not (dados is Dictionary) or not dados.has("slot"):
		return false
	var origem: SlotUI = dados["slot"]
	if origem == self:
		return false
	# troca: o destino também precisa caber na origem, se ela tiver item
	if not aceita(origem.item):
		return false
	if item != "" and not origem.aceita(item):
		return false
	return true

func _drop_data(_pos: Vector2, dados: Variant) -> void:
	var origem: SlotUI = dados["slot"]
	item_solto.emit(origem, self)

func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed:
		if evento.button_index == MOUSE_BUTTON_LEFT:
			item_clicado.emit(self)
