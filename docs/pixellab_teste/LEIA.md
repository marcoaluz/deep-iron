# Teste de estilo: Minerador via PixelLab

Pasta de revisão — **nada aqui está ligado ao jogo**. `atual/` = o que o jogo usa hoje;
`gerado/` = onde entram os resultados do PixelLab, pra comparar lado a lado.

## Estado

**Tentativa 1 gerada (2026-09-28)**: veja `gerado/RELATORIO.md` e
`gerado/comparacao_lado_a_lado.png`. Resumo: a paleta e o tamanho 16×17 nativo batem;
contorno, rosto, lanterna e caminhada não batem. Não substitui o sprite atual.

## Passo 0 — o minerador de hoje (referência)

| Item | Como é hoje |
|---|---|
| Arquivo | `ipezinho_m0..m5.png` (menino) e `ipezinho_f0..f5.png` (menina) — 6 variações de roupa cada |
| Tamanho | **16×17 px por quadro**, mostrado em escala 2 (32×34 na tela) |
| Quadros | folha 64×17 = **4 quadros** de caminhada; o quadro 0 é também a pose parada |
| Direção | **uma só: de frente pra câmera** (chibi). Esquerda/direita = a mesma imagem espelhada (`flip_h`). Não tem costas, perfil nem diagonais |
| Paleta | 92 cores na folha, tons terrosos "gastos" (graduação quente do gerador): capacete de latão, macacão jeans desbotado, flanela vinho, pele com rosado |
| Contorno | contorno seletivo (escuro em volta, mais claro por dentro) + sombreado de forma com luz de cima-esquerda |
| Capacete | latão com lanterna amarela na frente (a luz em si é um PointLight2D do jogo) |
| Picareta | **sprite separado** (`pickaxe.png`), o código gira pra dar a martelada — não faz parte da folha do corpo |
| Carga | pedrinha (`ore_chunk.png`) em cima da cabeça, o código aumenta com a carga |
| Inclinação / sombra | feitas pelo código (skew andando; elipse no chão) |
| Acessórios | camadas por cima (bota, remendo, lenço) alinhadas quadro a quadro na mesma grade 16×17 |
| Gerador | `tools/gen_sprites.py` → `build_ipezinho()` / `ipezinho_sheet()` |

Arquivos em `atual/`: as folhas `ipezinho_m0.png` e `ipezinho_f0.png`, a picareta, a pedra,
`minerador_prancha.png` (4 quadros em 8x + espelhado + paleta) e
`minerador_caminhada_8x.gif` (a caminhada animada).

## O que pedir ao PixelLab

- **create_character** (ou `create_image_pro` com `atual/ipezinho_m0.png` como referência):
  - descrição: *"tiny chibi dwarf-like miner, big round head, brass mining helmet with a
    yellow headlamp on the front, faded blue denim overalls over a worn burgundy flannel
    shirt, rosy cheeks, short legs, dark boots; muted earthy palette, dark selective
    outline, soft top-left lighting, low detail pixel art"*
  - **só a direção sul (de frente pra câmera)** — o jogo não usa outras
  - tamanho: o **menor possível**; o alvo é 16×17 por quadro
- **animate_character**: **caminhada de 4 quadros** de frente. Mineração não precisa: a
  picareta é girada pelo código (se o PixelLab desenhar a picareta na mão, ela vai brigar
  com a do jogo).

## Como comparar (o que decide se "bate")

1. **Densidade de pixel** — o ponto mais crítico. O jogo inteiro é pixel "gordo" (arte em
   16 px ampliada 2x). Se o PixelLab devolver 32 px ou mais e isso for mostrado em escala 1,
   o minerador fica com pixels 2x mais finos que todo o resto (casas, jazidas, chão) — destoa
   mesmo com paleta certa. Tem que dar pra reduzir pra 16×17 sem virar borrão.
2. **Paleta** — cores gastas/terrosas como a prancha; nada saturado demais.
3. **Contorno e luz** — contorno escuro seletivo, luz de cima-esquerda.
4. **Silhueta** — cabeça grande com capacete, corpo curto; legível em 16 px.
5. **Caminhada** — 4 quadros de frente, sem "flutuar" (os pés tocam o chão).
6. **Espelhável** — tem que ficar bom espelhado (o jogo espelha pra esquerda).

Coloque os resultados em `gerado/` com o número da tentativa (`tentativa1_...png`).
