# Grutas-de-Aroe-Jari

Jogo digital 2D de vista superior, feito em Godot 4, em que o herói Pari Jura entra na
gruta de Aroe-Jari com uma tocha que se consome, recolhe matéria-prima entre as ossadas
das vítimas, monta armadilhas e enfrenta a serpente Butoriko.

Desenvolvido por **Breno G. de Oliveira** e **Maximilian S. Ribeiro** na disciplina
CPS837 (Projeto de Jogos), PESC/COPPE/UFRJ, 2026/2.

## Sobre a história

**Leia antes de usar ou citar este material.**

**A história é do povo Boé (Bororo).** Pari Jura e Butoriko vêm da tradição do povo Boé,
conhecido na literatura como Bororo, que vive hoje em terras indígenas de Mato Grosso,
entre elas Meruri, Sangradouro, Tadarimana e Perigara. A narrativa não é nossa.

**A adaptação é nossa.** A gruta como labirinto, a tocha que se consome, os itens e as
combinações, as armadilhas e o enfrentamento organizado como partida foram inventados por
nós para transformar a narrativa em algo jogável. Onde o jogo se afasta da história, a
responsabilidade é nossa, e não da tradição.

### Referência documental pendente

Não conseguimos localizar um registro publicado dessa narrativa para citar. Buscamos em
português, espanhol e inglês, em repositórios de teses, no acervo digital da FUNAI, na
base do Instituto Socioambiental e na literatura secundária sobre a *Enciclopédia
Bororo*. Isso **não** significa que a narrativa não exista na tradição: significa que o
acervo relevante não está digitalizado. O volume II da *Enciclopédia Bororo* (Albisetti &
Venturelli, 1969), que reúne 62 *bakaru*, não está disponível em texto integral online, e
a conferência desse volume segue pendente.

Enquanto a referência não for estabelecida, o jogo e o artigo citam a narrativa como
pertencente à tradição Boé, sem atribuí-la a autor ou obra específica.

### Leituras que informaram o projeto

- **Leila Aparecida de Souza**, sobre *bakaru*: os Boé descrevem o termo como história do
  povo, fundamento da vida e código de conduta, e não como "lenda".
- **Fleury Kiegawa Ekureu**, professor Boé da Escola Indígena de Meruri, sobre o *pariko*,
  o diadema de penas em que se inscrevem as insígnias clânicas. Foi essa leitura que nos
  levou a **não** reproduzir nenhum grafismo clânico nem elemento cerimonial no jogo: são
  regulados internamente por clã, por metade e por momento cerimonial.
- Verbete **Boe (Bororo)**, de Paulo Serpa, em Povos Indígenas no Brasil (ISA).

### O que não fizemos

Não houve consulta às comunidades Boé. O projeto não é um codesenvolvimento. Este
repositório é material de pesquisa que acompanha o artigo, e não um produto cultural: o
jogo não é publicado em loja nem divulgado como jogo sobre a cultura Boé.

Se você é Boé (Bororo) e tem qualquer observação sobre o uso que fizemos da narrativa ou
das referências, o contato é bem-vindo: mribeiro@cos.ufrj.br.

## Artigo

O artigo que descreve o projeto, a adaptação da narrativa em mecânica e a questão da
referência documental está em [`artigo/`](artigo/). Compile com `latexmk -pdf artigo.tex`.

## Estrutura

```
cenas/      cenas Godot (.tscn) e recursos de tileset
scripts/    GDScript
sprites/    arte
sons/       áudio
build/      builds para Windows e navegador
artigo/     artigo acadêmico (LaTeX/IEEEtran)
```

## Licença

Veja [`LICENSE`](LICENSE).
