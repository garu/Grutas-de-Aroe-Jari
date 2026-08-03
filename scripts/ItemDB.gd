class_name ItemDB
extends RefCounted

## Catálogo de itens da caverna.
##
## PARA A ARTE: basta salvar o PNG do ícone em
##     res://sprites/itens/<nome_do_item>.png
## que ele é carregado automaticamente (ex.: "ceramica" -> ceramica.png).
## Ícones recomendados: 32x32 (ou 16x16), fundo transparente.
## Se o arquivo não existir, o inventário desenha um losango colorido no lugar.

const PASTA_ICONES := "res://sprites/itens/"

## nome -> dados do item
const ITENS := {
	# ---------------------------------------------------------- tesouros
	"ceramica": {
		"rotulo": "Cerâmica",
		"categoria": "tesouro",
		"peso": 2,
		"desc": "Vaso ritual bororo. Pesado, mas vale muito na aldeia."
	},
	"adorno": {
		"rotulo": "Adorno de penas",
		"categoria": "tesouro",
		"peso": 1,
		"desc": "Ornamento cerimonial roubado por Butoriko."
	},
	"pepita": {
		"rotulo": "Pepita",
		"categoria": "tesouro",
		"peso": 2,
		"desc": "Ouro bruto encontrado nas grutas."
	},

	# ---------------------------------------------------------- armas
	"cacete": {
		"rotulo": "Cacete",
		"categoria": "arma",
		"peso": 3,
		"ataque": 8,
		"desc": "Madeira dura. Golpe lento, porém forte."
	},
	"faca": {
		"rotulo": "Faca de pedra",
		"categoria": "arma",
		"peso": 1,
		"ataque": 5,
		"desc": "Leve e afiada. Boa para combinar com venenos."
	},
	"pedra": {
		"rotulo": "Pedra",
		"categoria": "arma",
		"peso": 1,
		"ataque": 3,
		"desc": "Simples, mas serve."
	},
	"arco": {
		"rotulo": "Arco",
		"categoria": "arma",
		"peso": 2,
		"ataque": 6,
		"desc": "Precisa de flechas para valer a pena."
	},
	"flecha": {
		"rotulo": "Flecha",
		"categoria": "arma",
		"peso": 1,
		"ataque": 2,
		"desc": "Ponta de osso. Use com o arco."
	},

	# ---------------------------------------------------------- utilitários
	"cipo": {
		"rotulo": "Cipó",
		"categoria": "utilitario",
		"peso": 1,
		"defesa": 2,
		"desc": "Amarra coisas. Base de armadilhas."
	},
	"folha_medicinal": {
		"rotulo": "Folha medicinal",
		"categoria": "utilitario",
		"peso": 1,
		"defesa": 2,
		"desc": "Cura pequenos ferimentos. Também envenena lâminas."
	},
	"tocha": {
		"rotulo": "Tocha",
		"categoria": "utilitario",
		"peso": 1,
		"defesa": 1,
		"recarrega_tocha": 25.0,
		"desc": "Devolve fôlego à chama que te mantém vivo."
	},

	# ---------------------------------------------------------- compostos
	"arma_envenenada": {
		"rotulo": "Arma envenenada",
		"categoria": "composto",
		"peso": 2,
		"ataque": 15,
		"desc": "Faca banhada em seiva. Derruba criaturas rápido."
	},
	"armadilha": {
		"rotulo": "Armadilha",
		"categoria": "composto",
		"peso": 2,
		"defesa": 5,
		"desc": "Cipó e pedra armados no chão."
	}
}

## Receitas conhecidas do jogo: composto -> ingredientes
const RECEITAS := {
	"arma_envenenada": ["faca", "folha_medicinal"],
	"armadilha": ["cipo", "pedra"]
}

# ------------------------------------------------------------------ consultas

static func dados(nome: String) -> Dictionary:
	return ITENS.get(nome, {
		"rotulo": nome.capitalize(),
		"categoria": "tesouro",
		"peso": 1,
		"desc": ""
	})

static func rotulo(nome: String) -> String:
	return dados(nome).get("rotulo", nome)

static func categoria(nome: String) -> String:
	return dados(nome).get("categoria", "tesouro")

static func peso(nome: String) -> int:
	return int(dados(nome).get("peso", 1))

static func descricao(nome: String) -> String:
	return dados(nome).get("desc", "")

static func ataque(nome: String) -> int:
	return int(dados(nome).get("ataque", 0))

static func defesa(nome: String) -> int:
	return int(dados(nome).get("defesa", 0))

## Carrega o ícone do item, se a arte já existir.
static func icone(nome: String) -> Texture2D:
	var caminho: String = PASTA_ICONES + nome + ".png"
	if ResourceLoader.exists(caminho):
		return load(caminho) as Texture2D
	return null

## Cor de apoio usada quando ainda não há ícone desenhado.
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
