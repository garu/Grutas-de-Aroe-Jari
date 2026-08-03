extends CanvasLayer

## Mochila de Pari: equipamento, carga e bancada de mistura.
##
## Abrir/fechar: I ou TAB (ESC fecha).
## Arrastar move entre mochila, equipamento, bancada e lixeira.
## Arrastar para FORA do quadro larga o item no chão da caverna.
## Botão direito equipa (ou usa, se não for equipável); num espaço
## equipado, guarda de volta na mochila.
##
## PARA A ARTE (opcional, no inspetor):
##   textura_painel -> moldura de fundo (NinePatchRect)
## Ícones dos itens: res://sprites/itens/<nome>.png

@export var textura_painel: Texture2D
@export var margem_painel: int = 10
@export var colunas: int = 5
@export var abrir_pausa_o_jogo: bool = true

const LINHAS := 4
const SLOTS_CRAFT := 3

signal item_usado(nome: String)

var aberto: bool = false

var _raiz: Control
var _painel: Control
var _lbl_info: Label
var _lbl_desc: Label
var _lbl_rodape: Label

var _slots_mochila: Array[SlotUI] = []
var _slots_equip: Dictionary = {}     # slot_equip -> SlotUI
var _slots_craft: Array[SlotUI] = []
var _slot_resultado: SlotUI
var _bancada: Array[String] = []      # itens postos na bancada
var _btn_criar: Button
var _lbl_craft: Label
var _slot_lixeira: SlotUI

## controle do arraste para fora do quadro
var _arrastando: SlotUI = null
var _estava_arrastando: bool = false

## Painel de testes (F10): fonte infinita de todos os itens
var modo_criativo: bool = false
var _caixa_criativa: Control
var _slots_criativos: Array[SlotUI] = []

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(SLOTS_CRAFT):
		_bancada.append("")
	_construir()
	_raiz.visible = false
	if get_node_or_null("/root/GameState") != null:
		GameState.inventory_changed.connect(_atualizar_tudo)
		GameState.equip_changed.connect(_atualizar_tudo)
		GameState.recipes_changed.connect(_atualizar_resultado)

# ------------------------------------------------------------------ montagem
func _construir() -> void:
	_raiz = Control.new()
	add_child(_raiz)
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.6)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_painel = _criar_painel()
	centro.add_child(_painel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	_painel.add_child(col)
	if _painel is NinePatchRect:
		col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		col.offset_left = margem_painel
		col.offset_top = margem_painel
		col.offset_right = -margem_painel
		col.offset_bottom = -margem_painel

	var titulo := _label("MOCHILA DE PARI", 12, Color(1, 0.85, 0.5))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(titulo)

	# ------------------------------- três colunas: equipar | carga | mistura
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	col.add_child(linha)

	linha.add_child(_montar_equipamento())
	linha.add_child(_montar_mochila())
	linha.add_child(_montar_bancada())
	linha.add_child(_montar_lixeira())

	# ------------------------------- painel de testes (F10)
	_caixa_criativa = _montar_criativo()
	col.add_child(_caixa_criativa)
	_caixa_criativa.visible = false

	# ------------------------------- rodapé
	_lbl_info = _label("", 10, Color(1, 0.95, 0.85))
	col.add_child(_lbl_info)

	_lbl_desc = _label("", 8, Color(0.75, 0.72, 0.66))
	_lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_desc.custom_minimum_size = Vector2(380, 30)
	col.add_child(_lbl_desc)

	_lbl_rodape = _label("", 8, Color(0.58, 0.55, 0.5))
	col.add_child(_lbl_rodape)

func _montar_equipamento() -> Control:
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 2)
	caixa.add_child(_label("EQUIPADO", 9, Color(0.85, 0.7, 0.45)))

	for nome_slot in ItemDB.SLOTS:
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 4)

		var s := SlotUI.new()
		s.tipo = SlotUI.Tipo.EQUIP
		s.slot_equip = nome_slot
		s.item_solto.connect(_on_item_solto)
		s.item_clicado.connect(_on_slot_clicado)
		s.item_clicado_direito.connect(_on_slot_direito)
		s.arraste_iniciado.connect(_on_arraste)
		linha.add_child(s)
		_slots_equip[nome_slot] = s

		var rot := _label(ItemDB.ROTULO_SLOT.get(nome_slot, nome_slot), 8, Color(0.7, 0.67, 0.6))
		rot.custom_minimum_size = Vector2(52, 0)
		rot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		linha.add_child(rot)

		caixa.add_child(linha)
	return caixa

func _montar_mochila() -> Control:
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 2)
	caixa.add_child(_label("CARGA", 9, Color(0.85, 0.7, 0.45)))

	var grade := GridContainer.new()
	grade.columns = colunas
	grade.add_theme_constant_override("h_separation", 3)
	grade.add_theme_constant_override("v_separation", 3)
	caixa.add_child(grade)

	for i in range(colunas * LINHAS):
		var s := SlotUI.new()
		s.tipo = SlotUI.Tipo.MOCHILA
		s.indice = i
		s.item_solto.connect(_on_item_solto)
		s.item_clicado.connect(_on_slot_clicado)
		s.item_clicado_direito.connect(_on_slot_direito)
		s.arraste_iniciado.connect(_on_arraste)
		grade.add_child(s)
		_slots_mochila.append(s)
	return caixa

func _montar_bancada() -> Control:
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 2)
	caixa.add_child(_label("MISTURA", 9, Color(0.85, 0.7, 0.45)))

	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 3)
	caixa.add_child(linha)

	for i in range(SLOTS_CRAFT):
		var s := SlotUI.new()
		s.tipo = SlotUI.Tipo.CRAFT
		s.indice = i
		s.item_solto.connect(_on_item_solto)
		s.item_clicado.connect(_on_slot_clicado)
		s.item_clicado_direito.connect(_on_slot_direito)
		s.arraste_iniciado.connect(_on_arraste)
		linha.add_child(s)
		_slots_craft.append(s)

	var seta := _label("↓", 12, Color(0.7, 0.6, 0.45))
	seta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caixa.add_child(seta)

	var linha2 := HBoxContainer.new()
	linha2.add_theme_constant_override("separation", 4)
	caixa.add_child(linha2)

	_slot_resultado = SlotUI.new()
	_slot_resultado.tipo = SlotUI.Tipo.RESULTADO
	_slot_resultado.item_clicado.connect(_on_slot_clicado)
	linha2.add_child(_slot_resultado)

	_btn_criar = Button.new()
	_btn_criar.text = "JUNTAR"
	_btn_criar.custom_minimum_size = Vector2(70, 26)
	_btn_criar.process_mode = Node.PROCESS_MODE_ALWAYS
	_btn_criar.focus_mode = Control.FOCUS_NONE
	_btn_criar.pressed.connect(_criar)
	linha2.add_child(_btn_criar)

	# diz em uma linha se a mistura serve para alguma coisa
	_lbl_craft = _label("", 8, Color(0.7, 0.68, 0.62))
	_lbl_craft.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_craft.custom_minimum_size = Vector2(78, 24)
	caixa.add_child(_lbl_craft)

	var limpar := Button.new()
	limpar.text = "Limpar"
	limpar.custom_minimum_size = Vector2(70, 20)
	limpar.process_mode = Node.PROCESS_MODE_ALWAYS
	limpar.focus_mode = Control.FOCUS_NONE
	limpar.pressed.connect(_limpar_bancada)
	caixa.add_child(limpar)
	return caixa

func _montar_lixeira() -> Control:
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 3)
	caixa.add_child(_label("DESCARTE", 9, Color(0.85, 0.5, 0.45)))

	_slot_lixeira = SlotUI.new()
	_slot_lixeira.tipo = SlotUI.Tipo.LIXEIRA
	_slot_lixeira.item_solto.connect(_on_item_solto)
	_slot_lixeira.item_clicado.connect(_on_slot_clicado)
	caixa.add_child(_slot_lixeira)

	var lixo := _label("🗑", 14, Color(0.85, 0.5, 0.45))
	lixo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caixa.add_child(lixo)

	var aviso := _label("solte aqui\npara destruir\n\nou arraste\npara fora do\nquadro para\nlargar no chão",
		7, Color(0.6, 0.55, 0.52))
	aviso.custom_minimum_size = Vector2(66, 0)
	caixa.add_child(aviso)
	return caixa

func _limpar_bancada() -> void:
	_devolver_bancada()
	_atualizar_tudo()

## Compara a bancada com TODAS as receitas do jogo (mesmo as não aprendidas)
func _resultado_teorico() -> String:
	var usados: Array = []
	for i in _bancada:
		if i != "":
			usados.append(i)
	if usados.is_empty():
		return ""
	for composto in ItemDB.RECEITAS.keys():
		var receita: Array = ItemDB.RECEITAS[composto]
		if receita.size() != usados.size():
			continue
		var restante := receita.duplicate()
		var bate := true
		for nome in usados:
			var idx: int = restante.find(nome)
			if idx == -1:
				bate = false
				break
			restante.remove_at(idx)
		if bate and restante.is_empty():
			return composto
	return ""

func _estilo_botao(cor_fundo: Color, cor_borda: Color) -> void:
	var e := StyleBoxFlat.new()
	e.bg_color = cor_fundo
	e.border_color = cor_borda
	e.set_border_width_all(1)
	e.set_corner_radius_all(2)
	e.set_content_margin_all(3)
	_btn_criar.add_theme_stylebox_override("normal", e)
	var h := e.duplicate()
	h.bg_color = cor_fundo.lightened(0.15)
	_btn_criar.add_theme_stylebox_override("hover", h)
	var d := e.duplicate()
	d.bg_color = Color(0.14, 0.13, 0.12)
	d.border_color = Color(0.3, 0.28, 0.25)
	_btn_criar.add_theme_stylebox_override("disabled", d)

func _montar_criativo() -> Control:
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 2)

	var sep := HSeparator.new()
	caixa.add_child(sep)

	caixa.add_child(_label(
		"TESTES (F10) — arraste daqui: estoque infinito · solte aqui para descartar",
		8, Color(0.55, 0.78, 0.95)
	))

	var grade := GridContainer.new()
	grade.columns = 12
	grade.add_theme_constant_override("h_separation", 3)
	grade.add_theme_constant_override("v_separation", 3)
	caixa.add_child(grade)

	for nome in ItemDB.ITENS.keys():
		var s := SlotUI.new()
		s.tipo = SlotUI.Tipo.CRIATIVO
		s.item_solto.connect(_on_item_solto)
		s.item_clicado.connect(_on_slot_clicado)
		s.item_clicado_direito.connect(_on_slot_direito)
		s.arraste_iniciado.connect(_on_arraste)
		grade.add_child(s)
		s.definir_item(nome)
		_slots_criativos.append(s)
	return caixa

func _criar_painel() -> Control:
	if textura_painel != null:
		var np := NinePatchRect.new()
		np.texture = textura_painel
		np.patch_margin_left = margem_painel
		np.patch_margin_right = margem_painel
		np.patch_margin_top = margem_painel
		np.patch_margin_bottom = margem_painel
		np.custom_minimum_size = Vector2(400, 200)
		return np
	var pc := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0.08, 0.065, 0.055, 0.97)
	e.border_color = Color(0.55, 0.42, 0.25)
	e.set_border_width_all(2)
	e.set_corner_radius_all(3)
	e.set_content_margin_all(margem_painel)
	pc.add_theme_stylebox_override("panel", e)
	return pc

func _label(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l

# ------------------------------------------------------------------ abrir/fechar
func alternar() -> void:
	if aberto:
		fechar()
	else:
		abrir()

func abrir() -> void:
	if aberto:
		return
	aberto = true
	_atualizar_tudo()
	_raiz.visible = true
	if abrir_pausa_o_jogo:
		get_tree().paused = true

## F10: painel de testes com todos os itens em quantidade infinita
func alternar_criativo() -> void:
	modo_criativo = not modo_criativo
	_caixa_criativa.visible = modo_criativo
	if modo_criativo and not aberto:
		abrir()
	if modo_criativo:
		_lbl_info.text = "Modo de testes ligado"
	_atualizar_rodape()

func fechar() -> void:
	if not aberto:
		return
	# o que sobrou na bancada volta para a mochila
	_devolver_bancada()
	aberto = false
	_raiz.visible = false
	if abrir_pausa_o_jogo:
		get_tree().paused = false

func _devolver_bancada() -> void:
	if get_node_or_null("/root/GameState") == null:
		return
	for i in range(_bancada.size()):
		if _bancada[i] != "":
			GameState.adicionar_item(_bancada[i])
			_bancada[i] = ""

# ------------------------------------------------------------------ atualização
func _atualizar_tudo() -> void:
	if get_node_or_null("/root/GameState") == null:
		return
	for i in range(_slots_mochila.size()):
		var nome := ""
		if i < GameState.mochila.size():
			nome = GameState.mochila[i]
		_slots_mochila[i].definir_item(nome)

	for nome_slot in _slots_equip.keys():
		_slots_equip[nome_slot].definir_item(GameState.item_equipado(nome_slot))

	for i in range(_slots_craft.size()):
		_slots_craft[i].definir_item(_bancada[i])

	_atualizar_resultado()
	_atualizar_rodape()

func _atualizar_resultado() -> void:
	if get_node_or_null("/root/GameState") == null:
		return

	var na_bancada := 0
	for i in _bancada:
		if i != "":
			na_bancada += 1

	var saida: String = GameState.resultado_da_mistura(_bancada)   # receita aprendida
	var teorico: String = _resultado_teorico()                      # existe no jogo

	_slot_resultado.definir_item(saida)
	_btn_criar.disabled = saida == ""

	if saida != "":
		# dá certo: verde
		_estilo_botao(Color(0.16, 0.36, 0.18), Color(0.45, 0.85, 0.45))
		_btn_criar.add_theme_color_override("font_color", Color(0.85, 1, 0.85))
		_lbl_craft.add_theme_color_override("font_color", Color(0.55, 0.9, 0.55))
		_lbl_craft.text = "✓ dá certo"
		_lbl_info.text = "Pode virar: %s" % ItemDB.rotulo(saida)
		_lbl_desc.text = ItemDB.descricao(saida)
		return

	_estilo_botao(Color(0.2, 0.18, 0.16), Color(0.4, 0.36, 0.3))
	_btn_criar.add_theme_color_override("font_color", Color(0.55, 0.52, 0.48))

	if na_bancada == 0:
		_lbl_craft.add_theme_color_override("font_color", Color(0.66, 0.63, 0.58))
		_lbl_craft.text = "arraste itens\naqui"
		_lbl_info.text = ""
		_lbl_desc.text = _texto_receitas()
	elif teorico != "":
		# combinação certa, mas ele ainda não viu a pintura
		_lbl_craft.add_theme_color_override("font_color", Color(0.95, 0.8, 0.35))
		_lbl_craft.text = "? receita\ndesconhecida"
		_lbl_info.text = "Esta mistura existe, mas Pari ainda não a aprendeu"
		_lbl_desc.text = "Procure a pintura rupestre que ensina esta combinação."
	else:
		_lbl_craft.add_theme_color_override("font_color", Color(0.85, 0.45, 0.4))
		_lbl_craft.text = "✕ não vira\nnada"
		_lbl_info.text = ""
		_lbl_desc.text = _texto_receitas()

func _texto_receitas() -> String:
	if GameState.receitas.is_empty():
		return "Pari ainda não aprendeu nenhuma mistura — as pinturas nas paredes ensinam."
	var partes: Array[String] = []
	for composto in GameState.receitas.keys():
		var nomes: Array[String] = []
		for n in GameState.receitas[composto]:
			nomes.append(ItemDB.rotulo(n))
		partes.append("%s = %s" % [ItemDB.rotulo(composto), " + ".join(nomes)])
	return "Sabe fazer:  " + "   ·   ".join(partes)

func _atualizar_rodape() -> void:
	if get_node_or_null("/root/GameState") == null:
		return
	var partes: Array[String] = []
	partes.append("carga %d/%d" % [GameState.mochila.size(), GameState.CAPACIDADE])
	partes.append("peso %d" % GameState.peso_total())
	partes.append("atq +%d" % GameState.bonus_ataque())
	partes.append("def +%d" % GameState.bonus_defesa())
	var jogador := _achar_player()
	if jogador != null and jogador.has_method("velocidade_atual"):
		partes.append("vel %d" % int(jogador.velocidade_atual()))
	partes.append("%d receitas" % GameState.receitas.size())
	var ajuda := "     [arraste · direito equipa/usa · fora do quadro = largar · I fecha · F10 testes]"
	if modo_criativo:
		ajuda = "     [MODO TESTES: clique ou arraste do painel azul · F10 desliga]"
	_lbl_rodape.text = "   ".join(partes) + ajuda

func _mostrar_item(nome: String) -> void:
	if nome == "":
		_lbl_info.text = ""
		_lbl_desc.text = ""
		return
	var extra := ""
	if ItemDB.ataque(nome) > 0:
		extra += "  +%d atq" % ItemDB.ataque(nome)
	if ItemDB.defesa(nome) > 0:
		extra += "  +%d def" % ItemDB.defesa(nome)
	if ItemDB.cura(nome) > 0:
		extra += "  cura %d" % ItemDB.cura(nome)
	if ItemDB.recarrega_tocha(nome) > 0.0:
		extra += "  +%ds de chama" % int(ItemDB.recarrega_tocha(nome))
	_lbl_info.text = "%s  (peso %d)%s" % [ItemDB.rotulo(nome), ItemDB.peso(nome), extra]
	_lbl_desc.text = ItemDB.descricao(nome)

# ------------------------------------------------------------------ arrastar
func _on_item_solto(origem: SlotUI, destino: SlotUI) -> void:
	var a: String = origem.item
	var b: String = destino.item

	_retirar(origem)
	if b != "":
		_retirar(destino)

	_colocar(destino, a)
	if b != "":
		_colocar(origem, b)

	_atualizar_tudo()

## Tira o item do lugar de origem (sem devolver para lugar nenhum)
func _retirar(slot: SlotUI) -> void:
	match slot.tipo:
		SlotUI.Tipo.MOCHILA:
			if slot.indice < GameState.mochila.size():
				GameState.mochila.remove_at(slot.indice)
		SlotUI.Tipo.EQUIP:
			GameState.desequipar(slot.slot_equip)
		SlotUI.Tipo.CRAFT:
			_bancada[slot.indice] = ""
		SlotUI.Tipo.CRIATIVO, SlotUI.Tipo.LIXEIRA:
			pass   # estoque infinito / lixeira: nada sai daqui

## Põe o item no lugar de destino
func _colocar(slot: SlotUI, nome: String) -> void:
	if nome == "":
		return
	match slot.tipo:
		SlotUI.Tipo.MOCHILA:
			if GameState.mochila.size() >= GameState.CAPACIDADE:
				_lbl_info.text = "Mochila cheia"
				return
			var pos: int = mini(slot.indice, GameState.mochila.size())
			GameState.mochila.insert(pos, nome)
			GameState.inventory_changed.emit()
		SlotUI.Tipo.EQUIP:
			GameState.equipar(slot.slot_equip, nome)
		SlotUI.Tipo.CRAFT:
			_bancada[slot.indice] = nome
		SlotUI.Tipo.CRIATIVO, SlotUI.Tipo.LIXEIRA:
			# item destruído
			_lbl_info.text = "Descartou: %s" % ItemDB.rotulo(nome)

# ------------------------------------------------------------------ cliques
func _on_slot_clicado(slot: SlotUI) -> void:
	for s in _slots_mochila:
		s.marcar(s == slot)
	for k in _slots_equip.keys():
		_slots_equip[k].marcar(_slots_equip[k] == slot)
	for s in _slots_craft:
		s.marcar(s == slot)
	for s in _slots_criativos:
		s.marcar(s == slot)
	_mostrar_item(slot.item)

	# no painel de testes, um clique já manda o item para a mochila
	if slot.tipo == SlotUI.Tipo.CRIATIVO and slot.item != "":
		if GameState.adicionar_item(slot.item):
			_lbl_info.text = "+ %s" % ItemDB.rotulo(slot.item)
		else:
			_lbl_info.text = "Mochila cheia"
		_atualizar_tudo()
		return

	if slot.tipo == SlotUI.Tipo.RESULTADO and not _btn_criar.disabled:
		_criar()

func _criar() -> void:
	if get_node_or_null("/root/GameState") == null:
		return
	var saida: String = GameState.resultado_da_mistura(_bancada)
	if saida == "":
		return
	for i in range(_bancada.size()):
		_bancada[i] = ""
	GameState.adicionar_item(saida)
	_lbl_info.text = "Você fez: %s" % ItemDB.rotulo(saida)
	_lbl_desc.text = ItemDB.descricao(saida)
	_atualizar_tudo()

# ------------------------------------------------------------------ clique direito
## Equipa (se couber num espaço) ou usa. Num espaço de equipar, desequipa.
func _on_slot_direito(slot: SlotUI) -> void:
	if slot.item == "":
		return
	var nome: String = slot.item

	if slot.tipo == SlotUI.Tipo.EQUIP:
		var voltou: String = GameState.desequipar(slot.slot_equip)
		if voltou != "" and not GameState.adicionar_item(voltou):
			GameState.equipar(slot.slot_equip, voltou)
			_lbl_info.text = "Mochila cheia"
		else:
			_lbl_info.text = "Guardou: %s" % ItemDB.rotulo(nome)
		_atualizar_tudo()
		return

	if slot.tipo == SlotUI.Tipo.CRIATIVO:
		GameState.adicionar_item(nome)
		_atualizar_tudo()
		return

	var espaco: String = ItemDB.slot_de(nome)
	var ja_equipado: bool = espaco != "" and GameState.item_equipado(espaco) == nome

	# equipável e ainda não está na mão -> equipa
	if espaco != "" and not ja_equipado:
		var trocado: String = GameState.item_equipado(espaco)
		_retirar(slot)
		GameState.equipar(espaco, nome)
		if trocado != "":
			GameState.adicionar_item(trocado)
		GameState.inventory_changed.emit()
		_lbl_info.text = "Equipou: %s" % ItemDB.rotulo(nome)
		_atualizar_tudo()
		return

	# senão, tenta usar
	_usar(slot)
	_atualizar_tudo()

# ------------------------------------------------------------------ arrastar para fora
func _on_arraste(slot: SlotUI) -> void:
	_arrastando = slot

func _process(_delta: float) -> void:
	if not aberto:
		return
	var arrastando_agora: bool = get_viewport().gui_is_dragging()
	if _estava_arrastando and not arrastando_agora:
		# o arraste terminou: ninguém aceitou e o mouse estava fora do quadro?
		if not get_viewport().gui_is_drag_successful() and _arrastando != null:
			if not _painel.get_global_rect().has_point(_raiz.get_global_mouse_position()):
				_largar_no_chao(_arrastando)
		_arrastando = null
	_estava_arrastando = arrastando_agora

## Tira o item de onde estava e joga no chão da caverna
func _largar_no_chao(slot: SlotUI) -> void:
	if slot.item == "" or slot.tipo == SlotUI.Tipo.CRIATIVO:
		return
	var nome: String = slot.item
	var jogador := _achar_player()
	if jogador == null:
		return
	_retirar(slot)
	GameState.inventory_changed.emit()
	var cena := load("res://cenas/Item.tscn") as PackedScene
	if cena != null:
		var it := cena.instantiate()
		it.categoria = ItemDB.categoria(nome)
		it.nome = nome
		it.scale = Vector2(3, 3)
		jogador.get_parent().add_child(it)
		it.global_position = jogador.global_position + Vector2(0, 50)
	_lbl_info.text = "Largou no chão: %s" % ItemDB.rotulo(nome)
	_atualizar_tudo()

func _usar(slot: SlotUI) -> void:
	if slot.item == "" or slot.tipo != SlotUI.Tipo.MOCHILA:
		return
	var nome: String = slot.item
	var jogador := _achar_player()
	var usou := false
	if jogador != null:
		var chama := ItemDB.recarrega_tocha(nome)
		if chama > 0.0 and jogador.has_method("reabastecer_tocha"):
			jogador.reabastecer_tocha(chama)
			usou = true
		var c := ItemDB.cura(nome)
		if c > 0 and jogador.has_method("curar"):
			jogador.curar(c)
			usou = true
	if usou:
		GameState.remover_indice(slot.indice)
		item_usado.emit(nome)
		_lbl_info.text = "Usou: %s" % ItemDB.rotulo(nome)
	else:
		_lbl_info.text = "%s não se usa sozinho — misture ou equipe" % ItemDB.rotulo(nome)


func _achar_player() -> Node:
	var lista := get_tree().get_nodes_in_group("player")
	return lista[0] if lista.size() > 0 else null


# ------------------------------------------------------------------ entrada
func _input(evento: InputEvent) -> void:
	if not (evento is InputEventKey) or not evento.pressed or evento.echo:
		return

	var tecla: int = evento.physical_keycode
	if tecla == KEY_F10:
		alternar_criativo()
		get_viewport().set_input_as_handled()
		return
	if tecla == KEY_I or tecla == KEY_TAB:
		alternar()
		get_viewport().set_input_as_handled()
		return
	if not aberto:
		return
	if tecla == KEY_ESCAPE:
		fechar()
		get_viewport().set_input_as_handled()
