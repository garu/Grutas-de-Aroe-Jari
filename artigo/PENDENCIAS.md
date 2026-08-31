# Pendências e conferência

Notas de trabalho do artigo. Estado atual: **13 páginas**, resumo com 244 palavras,
**74 referências citadas (54,1% de 2021–2026)**, 3 figuras e 6 tabelas todas referenciadas
no texto, 0 citação indefinida, 0 estouro de coluna (`overfull hbox`).

---

## 1. A preencher antes da entrega

Marcado **em vermelho no PDF** como `[PREENCHER: ...]`. Buscar por `\preencher{` no
`artigo.tex`.

| Onde | O que falta |
|---|---|
| §V-D, primeiro parágrafo | Protocolo do playtest: número de participantes, perfil, build usada (Windows ou web), tempo de sessão, observação direta ou relato posterior, roteiro |
| §V-D, Tabela V | Achados nas quatro dimensões (cognitiva, emocional, comportamental, cultural) e a resposta de projeto de cada uma |
| Agradecimentos | Nome do professor da disciplina |
| `references.bib`, entrada `souzabakaru` | Nome e ano do congresso. O PDF disponível não os traz; autoria e páginas (303–312) estão confirmadas. Marcado com `% [VERIFICAR ANTES DA ENTREGA]`, comentário que não é impresso |

**Se o playtest não vier a tempo:** retirar "avaliação preliminar" do título e do resumo e
converter a §V-D em "Protocolo de avaliação proposto". Os outros três resultados não
dependem dela. Do jeito que está, título e resumo prometem uma avaliação que a §V-D ainda
não entrega.

---

## 2. Origem da narrativa

A §III-C separa duas coisas: **a história é da tradição Boé** (Pari Jura, Butoriko, os
obstáculos, o cerne de sucupira) e **a adaptação é de vocês** (a gruta como labirinto, a
tocha que se consome, os itens e receitas, as armadilhas, o enfrentamento como partida).
Onde o jogo se afasta da história, a responsabilidade é da adaptação.

A §III-D relata a busca por um registro publicado dessa narrativa, que não foi
encontrada em nenhum acervo digitalizado que alcancei. O texto é explícito quanto ao que
isso significa e ao que **não** significa: não indica que a narrativa não seja da
tradição, indica que o acervo não está digitalizado. O volume II da *Enciclopédia Bororo*
(62 *bakaru*) não está online, e uma tradição oral não se esgota no que foi publicado.

**A conferir no texto:**

- A §III-C atribui a duas leituras duas decisões de projeto: Ekureu (*pariko* e regulação
  clânica) levou a manter grafismos clânicos e elementos cerimoniais fora do jogo; a
  associação *aroe*/mortos deu sentido ao topônimo e às ossadas. **Confirmar se foi assim.**
- **De onde veio a narrativa até vocês?** O artigo hoje diz apenas que ela "chegou ao
  projeto" como narrativa Boé. Se houve uma fonte concreta (material didático de MT, um
  livro, alguém que contou), isso deve entrar: é o elo que falta na cadeia, e é o que
  transformaria a pendência de citação em citação de fato.
- A §VI-A agora credita a **tradição** pela inversão do sentido extrativista (o retorno da
  aldeia para recolher as lembranças dos mortos está na história, não é invenção de vocês);
  de vocês é a leitura desse elemento em chave de mecânica.

Pendência que segue na agenda: conferir o volume II da *Enciclopédia Bororo* (Albisetti &
Venturelli, 1969). Serve para **encontrar a referência**, não para validar a existência.

### ⚠️ Verificar antes de entregar: a tela "Sobre"

O artigo afirma que o jogo declara a origem da narrativa, por meio da tela em
`cenas/Sobre.tscn` e `scripts/Sobre.gd`, com botão e linha de crédito em
`scripts/Telas.gd`. A afirmação aparece na §V-E, na §VI-C, na Tabela VI e na conclusão.

**Esse código nunca foi executado.** Não havia Godot na máquina onde foi escrito. Abra no
editor e confirme:

1. O `Sobre.tscn` importa sem erro (foi escrito à mão, sem `uid`).
2. O botão "Sobre" aparece na tela inicial e na de vitória e leva à tela certa.
3. O texto cabe nos 640×360 lógicos (viewport 1280×720 com `stretch/scale = 2.0`).

Se não funcionar e não houver tempo, reverta as quatro passagens do artigo para a versão
em que a ausência da declaração era assumida como falha do projeto.

## 3. Correções já aplicadas

Números conferidos contra o repositório:

| Estava | Correto |
|---|---|
| 13 cenas | **15** |
| 17 scripts | **16** |
| 14 itens no catálogo | **13** |
| 36 commits (63%) nos últimos 3 dias | **48 (84%)** |
| 636 células de 4032×3312 px | grade de **28×23 posições**, 636 preenchidas |

Achados incorporados ao texto a partir da leitura do código:

- `Enemy.tscn` está implementado (30 PV, dano 10, raio 130 px), mas **nenhuma criatura
  menor foi instanciada na gruta** — Butoriko é a única ameaça do protótipo. Tabela IV e
  §V-B.
- Há **dois caminhos para obter água** que não se relacionam: a receita das pinturas
  (cuia + folhas secas) e as seis poças do mapa, que enchem a cuia diretamente. §IV-D.
- Os **pesos não se conservam** na combinação: a armadilha de tronco pesa 4 contra 6 dos
  ingredientes, de modo que combinar alivia a carga. Se foi intencional, é um ponto de
  design; se não, é um valor a revisar no `ItemDB`. §IV-D.

Ajustes de argumentação:

- A tese "só o global foi cortado" era falsificada pela própria Tabela IV (tocha,
  obstáculos, geração procedural e condição de vitória são locais e caíram também).
  Reformulada para o que a tabela sustenta: *nenhum* sistema global sobreviveu, enquanto a
  maioria dos locais sobreviveu. Rebaixada de achado para hipótese.
- Criada a §VI-C, *O que fizemos com o artefato enquanto a verificação não ocorre*, que
  resolve a tensão entre recomendar não distribuir com atribuição e manter o repositório
  público, e ordena as pendências da Tabela VI: nomear o povo é etapa **posterior** à
  verificação, não alternativa a ela. **Conferir se as três medidas declaradas ali são
  verdadeiras** — em particular, a declaração de procedência foi incorporada ao
  `README.md` da raiz do repositório.
- "Fidelidade razoável ao mito" substituído pelo que a Tabela III mostra: de nove
  elementos, um implementado, um parcial, sete ausentes.

Também corrigidos: 22 aspas retas (`"x"`), que em LaTeX saem coladas na palavra seguinte;
notas internas do `.bib` que estavam sendo impressas na lista de referências; duas células
de tabela que estouravam a coluna; 15 erros de português; citações ausentes (Rogers,
*O cru e o cozido*, Huizinga).

---

## 4. Checklist de avaliação — artigo em grupo

| Critério | Exigência | Situação |
|---|---|---|
| Template IEEE | obrigatório | ✅ IEEEtran `conference` |
| Páginas | ≥ 9 | ✅ **13** |
| Palavras | ≥ 6000 | ✅ ~11.300 no PDF |
| Resumo | 150–250 palavras | ✅ **244** |
| Introdução | motivação, contexto, objetivos | ✅ §I |
| Referencial teórico | ≥ 9 artigos, abrangente | ✅ §II, 8 subseções |
| Metodologia | clara, com citações | ✅ §III, inclui ameaças à validade |
| Resultados | claros e detalhados | ✅ §V, 5 subseções, 3 figuras, 5 tabelas |
| Discussão | crítica, comparada à literatura | ✅ §VI, 6 subseções |
| Conclusão | achados + trabalhos futuros | ✅ §VII, 5 frentes priorizadas |
| Referências | ≥ 30 | ✅ **74** |
| Atualidade | metade dos últimos 5 anos | ✅ **54,1%** (40 de 2021–2026) |
| Estilo IEEE / BibTeX | obrigatório | ✅ |
| Figuras e tabelas | formatadas e referenciadas | ✅ todas as 9 citadas no texto |

---

## 5. Perguntas prováveis na avaliação

1. *"Vocês recomendam não distribuir com atribuição, mas o repositório é público."*
   Respondida na §VI-C. Depende de a declaração estar de fato no `README` da raiz.
2. *"Se a narrativa pode ser confabulação, em que sentido a Tabela III é uma matriz de
   correspondência mito–mecânica?"* Respondida em parte: a matriz vale como método,
   independentemente do estatuto da fonte. A §VI-A explicita isso quanto à defesa da
   "extração invertida".
3. *"Qual modelo, quando, com que prompt?"* A §III-C nomeia o modelo e a data, e admite a
   ausência de registro do prompt como falha de reprodutibilidade.

---

## 6. Melhoria de maior retorno, se houver tempo

Um **apêndice com o texto integral da narrativa** usada como base. Hoje o leitor só tem o
resumo de duas linhas da introdução, e a Tabela III é anunciada como instrumento
auditável — mas a coluna do mito é inauditável sem a fonte. Publicar o texto reforçaria o
argumento central, porque permitiria a qualquer leitor avaliar por si a hipótese de
confabulação.

---

## 7. Refazer as figuras

Da raiz do repositório:

```bash
python artigo/figuras/gerar_figuras.py
```

A Figura 2 merece uma captura de gameplay melhor — hoje usa `preview_cenario.png`, que
mostra pouco. Uma cena com Pari Jura num corredor e um item no chão dentro do halo da
tocha demonstraria melhor a mecânica de visão limitada. Salvar como
`artigo/figuras/tela_jogo.png`.
