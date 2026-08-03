extends Node

## Estado global do jogo (autoload "GameState").
## Mochila, equipamento, receitas aprendidas e ponto de recomeço.

signal inventory_changed
signal recipes_changed
signal equip_changed

const CAPACIDADE := 20

## Itens carregados, na ordem dos slots da mochila
var mochila: Array[String] = []

## slot de equipamento -> nome do item ("" = vazio)
var equipado: Dictionary = {}

## Receitas aprendidas nas pinturas: composto -> [ingredientes]
var receitas: Dictionary = {}

## Ponto de recomeço (última saída usada). Enquanto `tem_recomeco` for
## falso, vale a posição que o Pari já tem na cena.
var ponto_recomeco: Vector2 = Vector2.ZERO
var tem_recomeco: bool = false

## Pilhas deixadas por mortes anteriores
var esqueleto_pendente: Array = []

func _ready() -> void:
	reset_completo()

func reset_completo() -> void:
	mochila.clear()
	equipado.clear()
	for s in ItemDB.SLOTS:
		equipado[s] = ""
	receitas.clear()
	esqueleto_pendente.clear()
	ponto_recomeco = Vector2.ZERO
	tem_recomeco = false
	inventory_changed.emit()
	equip_changed.emit()

# ---------------------------------------------------------------- mochila

func adicionar_item(nome: String) -> bool:
	if mochila.size() >= CAPACIDADE:
		return false
	mochila.append(nome)
	inventory_changed.emit()
	return true

func remover_indice(indice: int) -> String:
	if indice < 0 or indice >= mochila.size():
		return ""
	var nome: String = mochila[indice]
	mochila.remove_at(indice)
	inventory_changed.emit()
	return nome

func remover_item(nome: String) -> bool:
	var i: int = mochila.find(nome)
	if i == -1:
		return false
	mochila.remove_at(i)
	inventory_changed.emit()
	return true

func tem_item(nome: String) -> bool:
	return mochila.has(nome)

func total_itens() -> int:
	return mochila.size()

func contar(categoria: String) -> int:
	var n := 0
	for nome in mochila:
		if ItemDB.categoria(nome) == categoria:
			n += 1
	return n

# ---------------------------------------------------------------- equipamento

func equipar(slot: String, nome: String) -> bool:
	if not equipado.has(slot):
		return false
	if ItemDB.slot_de(nome) != slot:
		return false
	equipado[slot] = nome
	equip_changed.emit()
	return true

func desequipar(slot: String) -> String:
	if not equipado.has(slot):
		return ""
	var nome: String = equipado[slot]
	equipado[slot] = ""
	equip_changed.emit()
	return nome

func item_equipado(slot: String) -> String:
	return equipado.get(slot, "")

func itens_equipados() -> Array[String]:
	var lista: Array[String] = []
	for s in equipado.keys():
		if equipado[s] != "":
			lista.append(equipado[s])
	return lista

# ---------------------------------------------------------------- atributos

## Peso conta tudo: o que está na mochila e o que está equipado
func peso_total() -> int:
	var t := 0
	for nome in mochila:
		t += ItemDB.peso(nome)
	for nome in itens_equipados():
		t += ItemDB.peso(nome)
	return t

## Só o que está equipado fortalece
func bonus_ataque() -> int:
	var t := 0
	for nome in itens_equipados():
		t += ItemDB.ataque(nome)
	return t

func bonus_defesa() -> int:
	var t := 0
	for nome in itens_equipados():
		t += ItemDB.defesa(nome)
	return t

# ---------------------------------------------------------------- morte

## Ao morrer, Pari larga tudo: o que estava na mão cai junto com a carga.
## Sobra apenas um item de cada categoria, e nada fica equipado.
## Devolve o que ficou para trás (vira a pilha do esqueleto).
func aplicar_morte() -> Dictionary:
	var perdidos: Dictionary = {}
	var guardados: Array[String] = []
	var vistas: Array[String] = []

	# o que estava equipado entra na mesma conta e sai dos slots
	var tudo: Array[String] = []
	tudo.append_array(mochila)
	for slot in equipado.keys():
		if equipado[slot] != "":
			tudo.append(equipado[slot])
			equipado[slot] = ""

	for nome in tudo:
		var cat: String = ItemDB.categoria(nome)
		if not vistas.has(cat):
			vistas.append(cat)
			guardados.append(nome)
		else:
			if not perdidos.has(cat):
				perdidos[cat] = []
			perdidos[cat].append(nome)

	mochila = guardados
	inventory_changed.emit()
	equip_changed.emit()
	return perdidos

func registrar_esqueleto(pos: Vector2, itens: Dictionary) -> void:
	if itens.is_empty():
		return
	esqueleto_pendente.append({"pos": pos, "itens": itens})

# ---------------------------------------------------------------- crafting

func aprender_receita(nome_composto: String, ingredientes: Array) -> void:
	receitas[nome_composto] = ingredientes
	recipes_changed.emit()

func conhece_receita(nome_composto: String) -> bool:
	return receitas.has(nome_composto)

## Qual composto sai desta combinação de ingredientes (ordem não importa).
## Devolve "" se a mistura não corresponde a nenhuma receita conhecida.
func resultado_da_mistura(ingredientes: Array) -> String:
	var usados: Array = []
	for i in ingredientes:
		if i != "":
			usados.append(i)
	if usados.is_empty():
		return ""

	for composto in receitas.keys():
		var receita: Array = receitas[composto]
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
