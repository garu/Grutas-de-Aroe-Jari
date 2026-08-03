extends CanvasLayer

## Inventário de Pari.
##
## Abrir/fechar: I ou TAB. Navegar: setas/WASD ou mouse.
## ENTER/ESPAÇO usa o item · C mescla receitas · Q larga no chão.
##
## PARA A ARTE (tudo opcional — sem arte ele desenha um painel simples):
##   textura_painel        -> moldura de fundo (NinePatchRect, sugestão 200x140)
##   textura_slot          -> caixinha vazia do slot (32x32)
##   textura_slot_ativo    -> mesma caixinha destacada (32x32)
##   ícones dos itens      -> res://sprites/itens/<nome>.png
##
## As margens do NinePatch ficam em `margem_painel`.

@export var textura_painel: Texture2D
@export var textura_slot: Texture2D
@export var textura_slot_ativo: Texture2D
@export var margem_painel: int = 12

@export var colunas: int = 6
@export var tamanho_slot: int = 30
@export var abrir_pausa_o_jogo: bool = true

signal item_usado(nome: String)
signal fechado

var aberto: bool = false
var _itens: Array[String] = []      # lista achatada, na ordem dos slots
var _sel: int = 0

var _raiz: Control
var _fundo: ColorRect
var _painel: Control
var _grade: GridContainer
var _lbl_titulo: Label
var _lbl_nome: Label
var _lbl_desc: Label
var _lbl_rodape: Label
var _slots: Array[Control] = []

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir()
	_raiz.visible = false
	if get_node_or_null("/root/GameState") != null:
		GameState.inventory_changed.connect(_recarregar)

# ------------------------------------------------------------------ construção
func _construir() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_raiz)

	# escurece o jogo atrás do painel
	_fundo = ColorRect.new()
	_fundo.color = Color(0, 0, 0, 0.55)
	_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(centro)

	_painel = _criar_painel()
	centro.add_child(_painel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	_painel.add_child(col)
	# NinePatchRect não posiciona filhos sozinho: aplica as margens na mão
	if _painel is NinePatchRect:
		col.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		col.offset_left = margem_painel
		col.offset_top = margem_painel
		col.offset_right = -margem_painel
		col.offset_bottom = -margem_painel

	_lbl_titulo = _label("INVENTÁRIO", 14, Color(1, 0.92, 0.75))
	_lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_lbl_titulo)

	_grade = GridContainer.new()
	_grade.columns = colunas
	_grade.add_theme_constant_override("h_separation", 3)
	_grade.add_theme_constant_override("v_separation", 3)
	col.add_child(_grade)

	_lbl_nome = _label("", 11, Color(1, 0.95, 0.85))
	col.add_child(_lbl_nome)

	_lbl_desc = _label("", 9, Color(0.78, 0.75, 0.7))
	_lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_desc.custom_minimum_size = Vector2(colunas * (tamanho_slot + 3), 26)
	col.add_child(_lbl_desc)

	_lbl_rodape = _label("", 8, Color(0.6, 0.58, 0.55))
	col.add_child(_lbl_rodape)

func _criar_painel() -> Control:
	if textura_painel != null:
		var np := NinePatchRect.new()
		np.texture = textura_painel
		np.patch_margin_left = margem_painel
		np.patch_margin_right = margem_painel
		np.patch_margin_top = margem_painel
		np.patch_margin_bottom = margem_painel
		np.custom_minimum_size = _tamanho_painel()
		return np
	var pr := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.08, 0.07, 0.06, 0.97)
	estilo.border_color = Color(0.55, 0.42, 0.25)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(3)
	estilo.set_content_margin_all(margem_painel)
	pr.add_theme_stylebox_override("panel", estilo)
	pr.custom_minimum_size = _tamanho_painel()
	return pr

func _tamanho_painel() -> Vector2:
	var largura := colunas * (tamanho_slot + 3) + margem_painel * 2
	return Vector2(largura, 150)

func _label(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l

# ------------------------------------------------------------------ abrir/fechar
func alternar() -> void:
	if aberto: fechar() else: abrir()

func abrir() -> void:
	if aberto:
		return
	aberto = true
	_recarregar()
	_raiz.visible = true
	if abrir_pausa_o_jogo:
		get_tree().paused = true

func fechar() -> void:
	if not aberto:
		return
	aberto = false
	_raiz.visible = false
	if abrir_pausa_o_jogo:
		get_tree().paused = false
	fechado.emit()

# ------------------------------------------------------------------ conteúdo
func _recarregar() -> void:
	_itens.clear()
	if get_node_or_null("/root/GameState") != null:
		for c in GameState.CATEGORIAS:
			for nome in GameState.inventario.get(c, []):
				_itens.append(nome)
	_sel = clampi(_sel, 0, maxi(0, _itens.size() - 1))
	_montar_slots()
	_atualizar_detalhe()

func _montar_slots() -> void:
	for s in _slots:
		s.queue_free()
	_slots.clear()

	var total: int = maxi(_itens.size(), colunas * 3)
	for i in range(total):
		var slot := _criar_slot(i)
		_grade.add_child(slot)
		_slots.append(slot)

func _criar_slot(indice: int) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(tamanho_slot, tamanho_slot)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP

	# fundo do slot
	if textura_slot != null:
		var tr := TextureRect.new()
		tr.texture = textura_slot
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.name = "Fundo"
		slot.add_child(tr)
	else:
		var cr := ColorRect.new()
		cr.color = Color(0.16, 0.14, 0.12, 0.9)
		cr.set_anchors_preset(Control.PRESET_FULL_RECT)
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cr.name = "Fundo"
		slot.add_child(cr)

	# conteúdo (ícone ou marca colorida)
	if indice < _itens.size():
		var nome: String = _itens[indice]
		var tex := ItemDB.icone(nome)
		if tex != null:
			var ic := TextureRect.new()
			ic.texture = tex
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.set_anchors_preset(Control.PRESET_FULL_RECT)
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(ic)
		else:
			var marca := Polygon2D.new()
			var r := tamanho_slot * 0.3
			marca.polygon = PackedVector2Array([
				Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)
			])
			marca.color = ItemDB.cor(nome)
			marca.position = Vector2(tamanho_slot, tamanho_slot) * 0.5
			slot.add_child(marca)

	# destaque de seleção
	var borda := ColorRect.new()
	borda.name = "Selecao"
	borda.color = Color(1, 0.85, 0.4, 0.28)
	borda.set_anchors_preset(Control.PRESET_FULL_RECT)
	borda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	borda.visible = false
	slot.add_child(borda)

	slot.gui_input.connect(_on_slot_input.bind(indice))
	return slot

func _on_slot_input(evento: InputEvent, indice: int) -> void:
	if evento is InputEventMouseButton and evento.pressed:
		if evento.button_index == MOUSE_BUTTON_LEFT:
			if indice < _itens.size():
				if _sel == indice:
					_usar_selecionado()
				else:
					_sel = indice
					_atualizar_detalhe()

func _atualizar_detalhe() -> void:
	for i in range(_slots.size()):
		var sel := _slots[i].get_node_or_null("Selecao") as ColorRect
		if sel != null:
			sel.visible = (i == _sel and i < _itens.size())
		var fundo := _slots[i].get_node_or_null("Fundo")
		if fundo is TextureRect and textura_slot_ativo != null:
			fundo.texture = textura_slot_ativo if (i == _sel and i < _itens.size()) else textura_slot

	if _itens.is_empty():
		_lbl_nome.text = "Mochila vazia"
		_lbl_desc.text = "Explore a caverna para encontrar tesouros, armas e utilitários."
	else:
		var nome: String = _itens[_sel]
		var extra := ""
		if ItemDB.ataque(nome) > 0:
			extra += "  +%d atq" % ItemDB.ataque(nome)
		if ItemDB.defesa(nome) > 0:
			extra += "  +%d def" % ItemDB.defesa(nome)
		_lbl_nome.text = "%s  [%s]%s" % [
			ItemDB.rotulo(nome), ItemDB.nome_categoria(ItemDB.categoria(nome)), extra
		]
		_lbl_desc.text = ItemDB.descricao(nome)

	_lbl_rodape.text = _texto_rodape()

func _texto_rodape() -> String:
	var partes: Array[String] = []
	partes.append("%d itens" % _itens.size())
	if get_node_or_null("/root/GameState") != null:
		var jogador := _achar_player()
		if jogador != null and jogador.has_method("velocidade_atual"):
			partes.append("velocidade %d" % int(jogador.velocidade_atual()))
		var prontas := _receitas_prontas()
		if prontas.size() > 0:
			partes.append("C: criar %s" % ItemDB.rotulo(prontas[0]))
		elif GameState.receitas.size() > 0:
			partes.append("%d receitas" % GameState.receitas.size())
	partes.append("I/TAB fecha")
	return "   ".join(partes)

func _receitas_prontas() -> Array:
	var prontas: Array = []
	if get_node_or_null("/root/GameState") == null:
		return prontas
	for composto in GameState.receitas.keys():
		if GameState._tem_ingredientes(GameState.receitas[composto]):
			prontas.append(composto)
	return prontas

func _achar_player() -> Node:
	var lista := get_tree().get_nodes_in_group("player")
	return lista[0] if lista.size() > 0 else null

# ------------------------------------------------------------------ ações
func _usar_selecionado() -> void:
	if _itens.is_empty():
		return
	var nome: String = _itens[_sel]
	var d := ItemDB.dados(nome)

	# tocha devolve chama ao jogador
	if d.has("recarrega_tocha"):
		var jogador := _achar_player()
		if jogador != null and jogador.has_method("reabastecer_tocha"):
			jogador.reabastecer_tocha(float(d["recarrega_tocha"]))
			_remover(nome)
			item_usado.emit(nome)
			return

	item_usado.emit(nome)

func _remover(nome: String) -> void:
	if get_node_or_null("/root/GameState") == null:
		return
	for c in GameState.inventario.keys():
		var i: int = GameState.inventario[c].find(nome)
		if i != -1:
			GameState.inventario[c].remove_at(i)
			GameState.inventory_changed.emit()
			return

func _largar_selecionado() -> void:
	if _itens.is_empty():
		return
	var nome: String = _itens[_sel]
	var jogador := _achar_player()
	if jogador == null:
		return
	var cena := load("res://cenas/Item.tscn") as PackedScene
	if cena != null:
		var it := cena.instantiate()
		it.categoria = ItemDB.categoria(nome)
		it.nome = nome
		it.global_position = jogador.global_position + Vector2(0, 40)
		jogador.get_parent().add_child(it)
	_remover(nome)

func _mesclar() -> void:
	if get_node_or_null("/root/GameState") == null:
		return
	var criado: String = GameState.tentar_mesclar()
	if criado != "":
		_lbl_nome.text = "Criado: %s" % ItemDB.rotulo(criado)

# ------------------------------------------------------------------ entrada
func _input(evento: InputEvent) -> void:
	if not (evento is InputEventKey) or not evento.pressed or evento.echo:
		return

	var tecla: int = evento.physical_keycode

	if tecla == KEY_I or tecla == KEY_TAB:
		alternar()
		get_viewport().set_input_as_handled()
		return

	if not aberto:
		return

	match tecla:
		KEY_ESCAPE:
			fechar()
		KEY_RIGHT, KEY_D:
			_mover_selecao(1)
		KEY_LEFT, KEY_A:
			_mover_selecao(-1)
		KEY_DOWN, KEY_S:
			_mover_selecao(colunas)
		KEY_UP, KEY_W:
			_mover_selecao(-colunas)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_usar_selecionado()
		KEY_C:
			_mesclar()
		KEY_Q:
			_largar_selecionado()
	get_viewport().set_input_as_handled()

func _mover_selecao(passo: int) -> void:
	if _itens.is_empty():
		return
	_sel = wrapi(_sel + passo, 0, _itens.size())
	_atualizar_detalhe()
