class_name ItemDB
extends RefCounted

## Catálogo de itens das Grutas de Aroe-Jari.
##
## PARA A ARTE: salve cada ícone como
##     res://sprites/itens/<nome_do_item>.png
## que ele aparece sozinho no inventário. Sem o arquivo, entra um
## losango colorido no lugar.
##
## Nomes de arquivo esperados:
##   cipo · raiz_unha_de_gato · tronco_sucupira · flor_craua · graveto
##   pedras · pote_vazio · pote_agua · pote_veneno
##   armadilha_tronco · pa · folhas_secas

const PASTA_ICONES := "res://sprites/itens/"

## Slots de equipamento
const SLOT_ARMA := "arma"
const SLOT_TOCHA := "tocha"
const SLOT_UTILITARIO := "utilitario"
const SLOT_ARMADILHA := "armadilha"

const SLOTS := [SLOT_ARMA, SLOT_TOCHA, SLOT_UTILITARIO, SLOT_ARMADILHA]

const ROTULO_SLOT := {
	SLOT_ARMA: "Mão",
	SLOT_TOCHA: "Chama",
	SLOT_UTILITARIO: "Cintura",
	SLOT_ARMADILHA: "Armadilha"
}

## nome -> dados. Campos opcionais: ataque, defesa, cura, recarrega_tocha
const ITENS := {
	# ------------------------------------------------------- utilitários / matéria-prima
	"cipo": {
		"rotulo": "Cipó",
		"slot": "utilitario",
		"categoria": "utilitario",
		"peso": 1,
		"defesa": 1,
		"desc": "Amarra tudo o que a caverna oferece. Base de armadilhas e cabos."
	},
	"raiz_unha_de_gato": {
		"rotulo": "Raiz de unha-de-gato",
		"slot": "utilitario",
		"categoria": "utilitario",
		"peso": 1,
		"cura": 25,
		"desc": "Raiz medicinal. Mastigada, fecha feridas e devolve fôlego."
	},
	"flor_craua": {
		"rotulo": "Flor de crauá",
		"slot": "utilitario",
		"categoria": "utilitario",
		"peso": 1,
		"desc": "Dá fibra resistente e seiva forte o bastante para envenenar."
	},
	"graveto": {
		"rotulo": "Graveto de fogo",
		"slot": "tocha",
		"categoria": "utilitario",
		"peso": 1,
		"recarrega_tocha": 20.0,
		"desc": "Madeira seca de girar. Alimenta a chama que te mantém vivo."
	},
	"folhas_secas": {
		"rotulo": "Folhas secas",
		"slot": "tocha",
		"categoria": "utilitario",
		"peso": 1,
		"recarrega_tocha": 10.0,
		"desc": "Acendalha leve. Pega fogo rápido, dura pouco."
	},
	"pote_vazio": {
		"rotulo": "Cuia",
		"slot": "utilitario",
		"categoria": "utilitario",
		"peso": 2,
		"desc": "Cuia de barro. Serve para carregar água ou preparar misturas."
	},
	"pote_agua": {
		"rotulo": "Cuia com água",
		"slot": "utilitario",
		"categoria": "utilitario",
		"peso": 3,
		"cura": 15,
		"desc": "Água das galerias fundas. Mata a sede e limpa ferimentos."
	},

	# ------------------------------------------------------- matéria pesada
	"tronco_sucupira": {
		"rotulo": "Tronco de sucupira",
		"slot": "arma",
		"visual": "sword",
		"categoria": "arma",
		"peso": 5,
		"ataque": 10,
		"desc": "Madeira densa e teimosa. Golpe forte, mas pesa como pedra."
	},
	"pedras": {
		"rotulo": "Pedrinhas",
		"slot": "arma",
		"arremesso": true,
		"categoria": "arma",
		"peso": 1,
		"ataque": 3,
		"desc": "Servem para atirar de longe ou virar ponta de ferramenta."
	},

	# ------------------------------------------------------- compostos
	"pote_veneno": {
		"rotulo": "Cuia com veneno",
		"slot": "arma",
		"visual": "sword",
		"categoria": "composto",
		"peso": 3,
		"ataque": 12,
		"desc": "Seiva de crauá fermentada. Derruba criaturas depressa."
	},
	"armadilha_tronco": {
		"rotulo": "Armadilha de tronco",
		"slot": "armadilha",
		"categoria": "composto",
		"peso": 4,
		"defesa": 6,
		"desc": "Tronco preso por cipós, armado para o que vier atrás de você."
	},
	"pa": {
		"rotulo": "Pá",
		"slot": "arma",
		"visual": "sword",
		"categoria": "composto",
		"peso": 3,
		"ataque": 8,
		"defesa": 2,
		"desc": "Pedra amarrada a um cabo. Cava, apoia e quebra crânios."
	}
}

## Receitas aprendidas nas pinturas rupestres: composto -> ingredientes
const RECEITAS := {
	"armadilha_tronco": ["tronco_sucupira", "cipo"],
	"pa": ["pedras", "graveto", "cipo"],
	"pote_veneno": ["pote_vazio", "flor_craua"],
	"pote_agua": ["pote_vazio", "folhas_secas"]
}

# ------------------------------------------------------------------ consultas

static func dados(nome: String) -> Dictionary:
	return ITENS.get(nome, {
		"rotulo": nome.capitalize(),
		"categoria": "utilitario",
		"peso": 1,
		"desc": ""
	})

static func rotulo(nome: String) -> String:
	return dados(nome).get("rotulo", nome)

static func categoria(nome: String) -> String:
	return dados(nome).get("categoria", "utilitario")

static func peso(nome: String) -> int:
	return int(dados(nome).get("peso", 1))

static func descricao(nome: String) -> String:
	return dados(nome).get("desc", "")

static func ataque(nome: String) -> int:
	return int(dados(nome).get("ataque", 0))

static func defesa(nome: String) -> int:
	return int(dados(nome).get("defesa", 0))

## Esta arma é arremessada em vez de golpear?
static func e_arremesso(nome: String) -> bool:
	return bool(dados(nome).get("arremesso", false))

## Conjunto de sprites que o Pari usa com este item ("sword" ou "")
static func visual(nome: String) -> String:
	return dados(nome).get("visual", "")

## Em que slot este item pode ser equipado ("" = não equipável)
static func slot_de(nome: String) -> String:
	return dados(nome).get("slot", "")

static func cura(nome: String) -> int:
	return int(dados(nome).get("cura", 0))

static func recarrega_tocha(nome: String) -> float:
	return float(dados(nome).get("recarrega_tocha", 0.0))

## Item que faz algo ao ser usado (Enter no inventário)
static func e_usavel(nome: String) -> bool:
	return cura(nome) > 0 or recarrega_tocha(nome) > 0.0

## Carrega o ícone, se a arte já existir.
static func icone(nome: String) -> Texture2D:
	var caminho: String = PASTA_ICONES + nome + ".png"
	if ResourceLoader.exists(caminho):
		return load(caminho) as Texture2D
	return null

## Cor de apoio usada enquanto não há ícone.
static func cor(nome: String) -> Color:
	match categoria(nome):
		"tesouro": return Color(0.95, 0.8, 0.25)
		"arma": return Color(0.8, 0.85, 0.9)
		"utilitario": return Color(0.45, 0.8, 0.45)
		"pintura": return Color(0.85, 0.5, 0.8)
		_: return Color(0.9, 0.6, 0.3)

static func nome_categoria(categoria_id: String) -> String:
	match categoria_id:
		"tesouro": return "Tesouros"
		"arma": return "Armas"
		"utilitario": return "Utilitários"
		"pintura": return "Pinturas"
		"composto": return "Compostos"
		_: return categoria_id.capitalize()
