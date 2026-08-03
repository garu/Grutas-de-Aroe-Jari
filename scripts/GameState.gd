extends Node

## Estado global do jogo (autoload "GameState").
## Guarda inventário, receitas aprendidas e o ponto de recomeço.

signal inventory_changed
signal recipes_changed

## Categorias do SGDD
const TESOURO := "tesouro"
const ARMA := "arma"
const UTILITARIO := "utilitario"
const PINTURA := "pintura"
const COMPOSTO := "composto"

const CATEGORIAS := [TESOURO, ARMA, UTILITARIO, PINTURA, COMPOSTO]

## inventario: categoria -> Array[String] (nomes dos itens)
var inventario: Dictionary = {}

## Receitas aprendidas nas pinturas rupestres: nome do composto -> [ingrediente_a, ingrediente_b]
var receitas: Dictionary = {}

## Ponto onde o jogador recomeça (última entrada/saída usada da caverna)
var ponto_recomeco: Vector2 = Vector2(640, 448)

## Itens deixados no chão pela morte anterior: [{"pos": Vector2, "itens": {cat: [nomes]}}]
var esqueleto_pendente: Array = []

func _ready() -> void:
	reset_completo()

func reset_completo() -> void:
	inventario.clear()
	for c in CATEGORIAS:
		inventario[c] = []
	receitas.clear()
	esqueleto_pendente.clear()
	ponto_recomeco = Vector2(640, 448)
	inventory_changed.emit()

# ---------------------------------------------------------------- inventário

func adicionar_item(categoria: String, nome: String) -> void:
	if not inventario.has(categoria):
		inventario[categoria] = []
	inventario[categoria].append(nome)
	inventory_changed.emit()

func total_itens() -> int:
	var t := 0
	for c in inventario.keys():
		t += inventario[c].size()
	return t

func contar(categoria: String) -> int:
	return inventario.get(categoria, []).size()

## Soma o peso real de cada item (é o que deixa Pari mais lento)
func peso_total() -> int:
	var t := 0
	for c in inventario.keys():
		for nome in inventario[c]:
			t += ItemDB.peso(nome)
	return t

## Poder de ataque extra vindo dos itens carregados
func bonus_ataque() -> int:
	var t := 0
	for c in inventario.keys():
		for nome in inventario[c]:
			t += ItemDB.ataque(nome)
	return t

## Defesa extra vinda dos itens carregados
func bonus_defesa() -> int:
	var t := 0
	for c in inventario.keys():
		for nome in inventario[c]:
			t += ItemDB.defesa(nome)
	return t

# ---------------------------------------------------------------- morte

## Regra do SGDD: ao morrer perde tudo, menos um item de cada categoria.
## Devolve o que foi perdido (para virar pilha no esqueleto).
func aplicar_morte() -> Dictionary:
	var perdidos: Dictionary = {}
	for c in inventario.keys():
		var lista: Array = inventario[c]
		if lista.size() > 1:
			perdidos[c] = lista.slice(1)
			inventario[c] = [lista[0]]
	inventory_changed.emit()
	return perdidos

func registrar_esqueleto(pos: Vector2, itens: Dictionary) -> void:
	if itens.is_empty():
		return
	esqueleto_pendente.append({"pos": pos, "itens": itens})

# ---------------------------------------------------------------- crafting

func aprender_receita(nome_composto: String, ingredientes: Array) -> void:
	receitas[nome_composto] = ingredientes
	recipes_changed.emit()

## Tenta criar qualquer composto cujas receitas o jogador já conheça e tenha os itens.
## Retorna o nome do composto criado, ou "" se nada pôde ser feito.
func tentar_mesclar() -> String:
	for composto in receitas.keys():
		var ingredientes: Array = receitas[composto]
		if _tem_ingredientes(ingredientes):
			_consumir(ingredientes)
			adicionar_item(COMPOSTO, composto)
			return composto
	return ""

func _tem_ingredientes(ingredientes: Array) -> bool:
	var restantes := ingredientes.duplicate()
	for c in inventario.keys():
		for nome in inventario[c]:
			var i := restantes.find(nome)
			if i != -1:
				restantes.remove_at(i)
	return restantes.is_empty()

func _consumir(ingredientes: Array) -> void:
	for nome in ingredientes:
		for c in inventario.keys():
			var i: int = inventario[c].find(nome)
			if i != -1:
				inventario[c].remove_at(i)
				break
	inventory_changed.emit()
