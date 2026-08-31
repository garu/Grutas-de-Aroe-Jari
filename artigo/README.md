# artigo/ — Grutas de Aroe-Jari

Artigo em grupo da disciplina **CPS837 — Projeto de Jogos** (PESC/COPPE/UFRJ, 2026/2),
sobre o jogo *Grutas de Aroe-Jari*.

## Arquivos

| Arquivo | O que é |
|---|---|
| `artigo.tex` | Fonte do artigo (IEEEtran, `conference`, português) |
| `references.bib` | 74 entradas BibTeX, todas citadas |
| `IEEEtran.cls`, `IEEEtran.bst` | Classe e estilo IEEE, para compilar offline. **Não subir no Overleaf** |
| `figuras/planta_gruta.pdf` | Planta da gruta reconstruída da geometria de colisão do tileset |
| `figuras/tela_jogo.png` | Captura do protótipo (com gama corrigida para impressão) |
| `figuras/gerar_figuras.py` | Script que regenera a planta da gruta a partir do repositório |
| `artigo.pdf` | Saída compilada |

## Como compilar

```bash
latexmk -pdf artigo.tex
```

ou, sem latexmk:

```bash
pdflatex artigo && bibtex artigo && pdflatex artigo && pdflatex artigo
```

**No Overleaf:** use o `overleaf.zip` desta pasta (New Project → Upload Project), marque
`artigo.tex` como documento principal e compile com pdfLaTeX.

Duas coisas que o zip do Overleaf faz diferente da pasta local, por causa de erros
observados na prática:

1. **Não leva `IEEEtran.cls` nem `IEEEtran.bst`.** Uma cópia local da classe no projeto
   tem precedência sobre a do TeX Live e, se chegar danificada no upload, o LaTeX falha
   com `The font size command \normalsize is not defined` e `Environment abstract
   undefined`. O Overleaf já tem IEEEtran instalado; deixar que ele use o seu é mais
   seguro. Os arquivos ficam aqui para quem compila offline.
2. **Leva a planta da gruta em PNG a 400 dpi**, não em PDF: o pdfTeX do Overleaf recusa o
   PDF vetorial do matplotlib com `reading image file failed`, embora o arquivo seja
   válido e compile localmente. As chamadas `\includegraphics` trazem a extensão
   `.png` explícita para que um PDF antigo no projeto não seja escolhido no lugar.

## Regenerar a figura da planta

As figuras de dados não são desenhadas à mão: saem do próprio repositório do jogo.

```bash
cd ..                      # raiz do repositório Grutas-de-Aroe-Jari
python artigo/figuras/gerar_figuras.py
```

O script lê `cenas/caverna.tscn` — decodifica o `PackedByteArray` do tilemap e os
polígonos de colisão do tileset — e reescreve `planta_gruta.pdf` e `planta_gruta.png`.

## Estado

Compila limpo: **13 páginas**, 0 citações indefinidas, 0 `overfull hbox`, resumo com
244 palavras, 74 referências (54% de 2021–2026).

O que ainda falta está marcado **em vermelho no PDF** com `\preencher{...}` — veja
`PENDENCIAS.md`.
