extends Control

## Tela "Sobre": declara o estatuto da história e credita as referências culturais.
##
## Esta tela é deliberadamente não-diegética: ela fala na voz dos autores, e não
## na voz do jogo. Uma declaração de autoria colocada dentro da ficção (numa
## pintura rupestre, por exemplo) não declara nada, porque vira fala dos antigos.
##
## A UI é montada por código, no mesmo padrão de Telas.gd.

const BLOCOS := [
{
"titulo": "A história é do povo Boé (Bororo)",
"texto": "Pari Jura e Butoriko vêm da tradição do povo Boé, conhecido na literatura como Bororo. A história não é nossa. Nós a adaptamos para jogo."
},
{
"titulo": "A adaptação é nossa",
"texto": "A gruta como labirinto, a tocha que se consome, os itens e as combinações, as armadilhas e o enfrentamento organizado como partida são invenções nossas, feitas para transformar a narrativa em algo jogável.

Onde o jogo se afasta da história, a responsabilidade é nossa, e não da tradição."
},
{
"titulo": "O povo Boé",
"texto": "Vive hoje em terras indígenas de Mato Grosso, entre elas Meruri, Sangradouro, Tadarimana e Perigara.

Bakaru, o nome que os Boé dão às suas histórias, não quer dizer lenda: segundo a etnografia de Leila Aparecida de Souza, é ao mesmo tempo história do povo, fundamento da vida e código de conduta."
},
{
"titulo": "O que lemos",
"texto": "Leila Aparecida de Souza, sobre bakaru.

Fleury Kiegawa Ekureu, professor Boé da Escola Indígena de Meruri, sobre o pariko, o diadema de penas em que se inscrevem as insígnias clânicas.

Verbete Boe (Bororo), de Paulo Serpa, em Povos Indígenas no Brasil (Instituto Socioambiental)."
},
{
"titulo": "O que não fizemos",
"texto": "Não houve consulta às comunidades Boé. Este é um trabalho acadêmico de dois desenvolvedores não indígenas, feito na disciplina CPS837 (Projeto de Jogos), PESC/COPPE/UFRJ.

Nenhum grafismo clânico ou elemento cerimonial foi reproduzido no jogo: são regulados internamente por clã, por metade e por momento cerimonial, e não nos cabe exibi-los."
},
]

const CONTATO := "Dúvidas, correções ou objeções: mribeiro@cos.ufrj.br"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var fundo := ColorRect.new()
	fundo.color = Color.BLACK
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 6)
	centro.add_child(caixa)

	var cabecalho := Label.new()
	cabecalho.text = "Sobre este jogo"
	cabecalho.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cabecalho.add_theme_font_size_override("font_size", 18)
	cabecalho.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	caixa.add_child(cabecalho)

	var rolagem := ScrollContainer.new()
	rolagem.custom_minimum_size = Vector2(440, 230)
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caixa.add_child(rolagem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 10)
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(coluna)

	for bloco in BLOCOS:
		coluna.add_child(_titulo(bloco["titulo"]))
		coluna.add_child(_paragrafo(bloco["texto"]))

	var contato := _paragrafo(CONTATO)
	contato.add_theme_color_override("font_color", Color(0.62, 0.60, 0.55))
	coluna.add_child(contato)

	var voltar := Button.new()
	voltar.text = "Voltar"
	voltar.custom_minimum_size = Vector2(160, 28)
	voltar.focus_mode = Control.FOCUS_ALL
	voltar.process_mode = Node.PROCESS_MODE_ALWAYS
	voltar.pressed.connect(_voltar)
	caixa.add_child(voltar)
	voltar.call_deferred("grab_focus")

func _titulo(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.95, 0.72, 0.38))
	return l

func _paragrafo(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(415, 0)
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color(0.86, 0.84, 0.79))
	return l

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_voltar()

func _voltar() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://cenas/TelaInicial.tscn")
