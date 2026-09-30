# Prompt 8: jazidas, minérios, rochas e achados

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/jazidas/final/`,
montador `jazidas/jazidas.py`. Nada integrado ao jogo.

## O que o jogo tem (conferido no código)

- **Minérios** (`scripts/core/ores.gd`, `mineral_node.gd`): ferro, cobre, carvão, prata,
  solarita. Hoje cada jazida tem 3 quadros (`ore_<tipo>_0..2`).
- **Achados** (`finds.gd`): bobina, cristal, peça, painel solar (+ o robô, Prompt 5).
- **Pedaço carregado** (`chunk_*`) e **pilha de minério** (`ore_pile`) no Armazém.

## O que ficou pronto

| Grupo | Peças |
|---|---|
| **Jazidas**, 5 minérios × 4 estados | cheia, meia, quase vazia (cor de cada minério) + esgotada (rocha quebrada sem minério, a mesma pros 5) |
| **Pilha de minério**, 3 tamanhos × 5 minérios | pequena, média, grande |
| **Pedaço de minério solto**, 6 formas × 5 minérios | no chão, no vagonete, na mão |
| **Lascas do golpe**, 1 folha de 6 quadros por minério | rocha + cor do minério, saem do ponto e caem (efeito do Prompt 18) |
| **Rochas grandes** (superfície), 6 | alta pontuda, larga baixa, arredondada, partida, blocos, com filhote |
| **Rochas com musgo** (borda da floresta), 6 | com samambaia e capim na base |
| **Rochas da mina**, 3 | recolor azul-rocha da caverna |
| **Pedrinhas soltas**, 8 | cinza e marrom |
| **Cristais** das camadas fundas, 4 cores × 2 | ciano (nível 2), lima (radiação), violeta e brasa (abismo) |
| **Achados**, os 4 do jogo | bobina (rolo de cabo), cristal, peça (engrenagem), painel solar, meio enterrados com um brilho |
| **Entulho**, 4 tamanhos | espalhado, pequeno, médio, grande |

**Cada minério se lê de longe:**

- ferro: vermelho-ferrugem;
- cobre: pátina verde com brilho de cobre, como a cor dele na interface;
- carvão: preto com reflexo azulado;
- prata: branco;
- solarita: ouro luminoso.

## Técnica que economizou (reportando)

- Jazida, pilha e pedaço foram gerados **uma vez**, com o minério numa cor de marcação
  (turquesa, bem separada da rocha). O `jazidas.py` troca o turquesa pela rampa de cada
  minério, pelo brilho de cada pixel.
- Os **4 estados da jazida saíram do mesmo lote de 16 candidatos**, que variavam
  naturalmente de "cheio" a "rocha quebrada". Custo: 1 geração em vez de 20.
- Pilhas e pedaços também saíram de 1 lote cada (64 candidatos nos pedaços).
- A esgotada apaga o turquesa trocando pela cor de rocha de brilho parecido.

## Entregas

- `prancha_jazidas.png` (nesta pasta).

## Custo

**~185 gerações**: 9 lotes (jazida 25, os outros 20 cada).

## Desvios

1. **Jazidas dos 5 minérios com a mesma forma.** Só a cor muda. A forma de cada estado é a
   mesma, o que também ajuda a ler o desgaste. Se quiser formas diferentes por minério, são
   +20 por minério.
2. **Pilhas e pedaços** têm rocha bem escura, com pontos de minério menores que na jazida.
   Leem pela cor, mas menos que a jazida.
3. **Cristais** são mais saturados que o resto (brilho das camadas fundas). O brilho de luz em
   si é do Prompt 19.
4. **Pedrinhas** vieram com uma linha clara embaixo (sombra desenhada ao contrário), tirada
   por script.
5. **A animação de golpe na jazida** saiu como folha de lascas por script, como o prompt
   permite. O golpe em si é a animação de minerar do minerador (Prompt 1).
6. **O jogo hoje tem 3 quadros por jazida.** A arte tem 4 estados; a troca pela quantidade é
   integração.
