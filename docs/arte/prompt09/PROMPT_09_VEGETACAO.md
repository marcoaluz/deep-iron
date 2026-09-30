# Prompt 9: árvores, vegetação e horta

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/vegetacao/final/`,
montador `vegetacao/vegetacao.py`. Nada integrado ao jogo.

## O que o jogo tem (conferido no código)

- **Árvore** (`tree_node.gd`): o lenhador corta, ela esgota e vira **toco**, fica parada um
  tempo e **cresce de novo**.
- **Horta** (`food_source.gd`): **cogumelos de caverna** (uma cultura só), na clareira; hoje 3
  quadros (cheia, metade, colhida).
- **Estação:** só no clima e no casaco (contrato §3). A vegetação não troca por estação, então
  não há variante de estação.

## O que ficou pronto

| Grupo | Peças |
|---|---|
| **Árvores**, 3 espécies + seca | pinheiro (2), carvalho de copa larga (3), bétula de tronco claro (2), árvore seca (1). ~2× a altura do minerador. |
| **Ciclo da árvore** | inteira → sendo cortada (árvore + lascas + tremida no código) → toco (1 por espécie) → tora caída (2) → muda rebrotando (1 por espécie) |
| **Horta de cogumelos**, 6 estágios | vazio, preparado (sulcos), plantado (brotinhos), crescendo, pronto pra colher, colhido (tocos). O mesmo canteiro nos 6. |
| **Madeira** | tora, toras P/M/G, lenha P/G, tábuas P/M/G (3 tamanhos de cada) |
| **Vegetação rasteira** (3+ de cada) | arbusto (3), samambaia (2), moita (3), espinheiro (2), flores silvestres (4), capim alto (4), galho (3), tronco com musgo (3), cogumelos (3), raízes (2) |
| **Lascas de madeira** | folha de 6 quadros pro golpe do machado (efeito do Prompt 18) |

**Caixa das árvores:** o tronco fica no centro do tile (guia com o losango do chão e a linha do
tronco). Pra ordenação, a caixa é **só o tronco** (≈ 12×12 no chão), não a copa: o boneco
passa atrás da copa, como pede o prompt.

## Entregas

- `prancha_vegetacao.png` (nesta pasta).

## Custo

**~310 gerações**:

| Item | Gerações |
|---|---|
| 3 espécies de árvore (4 candidatos cada) | 75 |
| Toco, tora, muda | 70 |
| Vegetação rasteira (64 candidatos) + arbustos | 45 |
| Horta | 20 |
| Madeira | 20 |

## Desvios

1. **Tora caída:** o lote próprio saiu cortado nas pontas. Usei as toras do lote de madeira,
   que vieram inteiras.
2. **Um candidato de capim veio com uma mancha branca** (a IA desenhou um "brilho"). Troquei
   por outro. O lote de 64 também **vazou pedaços do vizinho** na borda do quadro; o script
   deixa só a peça principal.
3. **Horta:** o jogo tem só cogumelo. Se entrar outra cultura (hidroponia), são +20 por
   cultura.
4. **Árvore sendo cortada:** não gerei um desenho próprio. A árvore inteira + lascas + um
   tremor curto no código leem bem e custam 0.
5. **A máquina de cortar árvores** da visão do mapa é do Prompt 13 (máquinas).
