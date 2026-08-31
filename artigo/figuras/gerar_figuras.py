#!/usr/bin/env python3
"""
Gera as figuras de dados do artigo a partir do próprio repositório do jogo.

Rode da RAIZ do repositório Grutas-de-Aroe-Jari:

    python artigo/figuras/gerar_figuras.py

Produz, em artigo/figuras/:
    planta_gruta.pdf / .png   planta da gruta reconstruída da geometria de colisão

Requer: matplotlib. A planta é reconstruída decodificando o PackedByteArray da
camada de tilemap de cenas/caverna.tscn e casando cada célula com os polígonos de
colisão declarados pelo tileset embutido — ou seja, não é captura de tela.

Paleta: slots categóricos 1-3 (azul, laranja, água-marinha), validados para
separação sob deficiência de visão de cores em modo "todos os pares".
"""

import base64
import collections
import os
import re
import struct
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon as MPoly, Rectangle

CENA = os.path.join("cenas", "caverna.tscn")
OUT = os.path.join("artigo", "figuras")
CELL = 144.0

BLUE, ORANGE, AQUA = "#2a78d6", "#eb6834", "#1baf7a"
INK, INK2, GRID, SURF = "#1a1a19", "#5c5c58", "#d8d6d0", "#fcfcfb"

plt.rcParams.update({
    "font.size": 8, "text.color": INK, "axes.labelcolor": INK2,
    "xtick.color": INK2, "ytick.color": INK2, "figure.facecolor": SURF,
    "axes.facecolor": SURF, "savefig.facecolor": SURF, "pdf.fonttype": 3,
    "axes.edgecolor": GRID, "axes.linewidth": .6,
})


def classe(nome):
    if nome.startswith("it"):
        return "item"
    if nome.lower().startswith("poca"):
        return "poca"
    if nome.startswith("Pintura") or nome == "Tutorial":
        return "pintura"
    if nome in ("Player", "Butoriko", "EsqueletoAntigo"):
        return nome
    return None


def ler_cena(caminho):
    s = open(caminho, encoding="utf-8", errors="ignore").read()

    poligonos = collections.defaultdict(list)
    padrao = r"^(\d+):(\d+)/0/physics_layer_0/polygon_\d+/points = PackedVector2Array\(([^)]*)\)"
    for m in re.finditer(padrao, s, re.M):
        nums = [float(v) for v in m.group(3).split(",")]
        pts = list(zip(nums[0::2], nums[1::2]))
        if len(pts) >= 3:
            poligonos[(int(m.group(1)), int(m.group(2)))].append(pts)

    m = re.search(r'tile_map_data = PackedByteArray\("([^"]*)"\)', s)
    raw = base64.b64decode(m.group(1))
    n = (len(raw) - 2) // 12
    celulas = []
    for i in range(n):
        x, y, _src, ax, ay, _alt = struct.unpack_from("<hhhhhh", raw, 2 + i * 12)
        celulas.append((x, y, ax, ay))

    grupos = collections.defaultdict(list)
    marcos = {}
    for bloco in re.split(r"\n(?=\[node )", s):
        a = re.match(r'\[node name="([^"]+)"', bloco)
        p = re.search(r"position = Vector2\((-?[\d.e+-]+), (-?[\d.e+-]+)\)", bloco)
        if not (a and p):
            continue
        k = classe(a.group(1))
        if k in ("item", "poca", "pintura"):
            grupos[k].append((float(p.group(1)), float(p.group(2))))
        elif k:
            marcos[k] = (float(p.group(1)), float(p.group(2)))

    return celulas, poligonos, grupos, marcos


def planta(celulas, poligonos, grupos, marcos):
    xs = [c[0] for c in celulas]
    ys = [c[1] for c in celulas]
    x0, x1 = min(xs) * CELL, (max(xs) + 1) * CELL
    y0, y1 = min(ys) * CELL, (max(ys) + 1) * CELL

    fig, ax = plt.subplots(figsize=(3.42, 3.15))
    ax.add_patch(Rectangle((x0, y0), x1 - x0, y1 - y0,
                           facecolor="#f4f2ec", edgecolor="#b9b3a8", lw=.5, zorder=0))
    for (cx, cy, atx, aty) in celulas:
        ox, oy = cx * CELL + CELL / 2, cy * CELL + CELL / 2
        for pts in poligonos.get((atx, aty), []):
            ax.add_patch(MPoly([(ox + px, oy + py) for px, py in pts], closed=True,
                               facecolor="#a49e93", edgecolor="none", zorder=1))

    series = [("item", "o", BLUE, "Itens coletáveis (%d)" % len(grupos["item"])),
              ("pintura", "^", ORANGE, "Pinturas rupestres (%d)" % len(grupos["pintura"])),
              ("poca", "s", AQUA, "Poças de água (%d)" % len(grupos["poca"]))]
    for k, mk, cor, rot in series:
        ax.scatter([p[0] for p in grupos[k]], [p[1] for p in grupos[k]],
                   marker=mk, s=17, c=cor, label=rot, zorder=4,
                   edgecolors=SURF, linewidths=.6)

    anot = [("Player", "*", "entrada", (-1300, 300)),
            ("Butoriko", "X", "covil de Butoriko", (340, 260)),
            ("EsqueletoAntigo", "P", "ossada inicial", (300, -230))]
    for chave, mk, rot, off in anot:
        if chave not in marcos:
            continue
        x, y = marcos[chave]
        ax.scatter([x], [y], marker=mk, s=115 if mk != "P" else 55, c=INK,
                   zorder=6, edgecolors=SURF, linewidths=.9)
        ax.annotate(rot, (x, y), xytext=(x + off[0], y + off[1]), fontsize=6.0,
                    color=INK, ha="left", va="center",
                    bbox=dict(boxstyle="round,pad=0.16", fc="#ffffff",
                              ec="#c9c4ba", lw=.4, alpha=.95),
                    arrowprops=dict(arrowstyle="-", color=INK, lw=.6,
                                    shrinkA=1, shrinkB=3), zorder=8)

    sx, sy = (x0 + x1) / 2 - 900, y1 + 560
    ax.plot([sx, sx + 1440], [sy, sy], color=INK2, lw=1.4, zorder=8,
            solid_capstyle="butt", clip_on=False)
    ax.text(sx + 1520, sy, "1 440 px (10 células)", fontsize=5.8, color=INK2,
            ha="left", va="center", clip_on=False)

    ax.set_aspect("equal")
    ax.invert_yaxis()
    ax.axis("off")
    ax.set_xlim(x0 - 700, x1 + 700)
    ax.set_ylim(y1 + 760, y0 - 80)
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.005), ncol=3,
              fontsize=5.9, framealpha=0, edgecolor="none",
              handletextpad=.3, columnspacing=.9, borderpad=.1)
    plt.tight_layout(pad=.1)
    plt.savefig(os.path.join(OUT, "planta_gruta.pdf"), bbox_inches="tight", pad_inches=.02)
    plt.savefig(os.path.join(OUT, "planta_gruta.png"), dpi=400, bbox_inches="tight", pad_inches=.02)
    plt.close()


if __name__ == "__main__":
    if not os.path.exists(CENA):
        sys.exit("Rode da raiz do repositório: não encontrei %s" % CENA)
    os.makedirs(OUT, exist_ok=True)
    celulas, poligonos, grupos, marcos = ler_cena(CENA)
    planta(celulas, poligonos, grupos, marcos)
    print("Figura gerada em %s (%d células, %d itens, %d pinturas, %d poças)"
          % (OUT, len(celulas), len(grupos["item"]),
             len(grupos["pintura"]), len(grupos["poca"])))
