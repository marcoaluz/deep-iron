# Protótipo comparativo de câmera: Rota A (isométrico) × Rota B (top-down com relevo)

Data: 2026-09-29. **Protótipos isolados** em `project.godot/prototipos/camera/`. Nenhum
sistema do jogo foi tocado, nenhuma arte final foi gerada; os prédios da A são caixas
provisórias e os da B são os sprites atuais do jogo.

## Como abrir

No editor do Godot, abra a cena e aperte **F6**:

- `prototipos/camera/rota_a_iso.tscn`
- `prototipos/camera/rota_b_relevo.tscn`

**Controles (iguais nas duas):**

| Tecla / mouse | O quê |
|---|---|
| roda | zoom |
| botão do meio / WASD | mover |
| clique esquerdo | selecionar |
| clique direito | manda o ipezinho selecionado (ou a Mel) andar até lá |
| **C** | construir casa (fantasma verde/vermelho) |
| **Tab** | pegadas e pontos de ordenação |
| **N** (só na A) | alterna a ordenação "ingênua" × "cortada" |

## A mesma cena nas duas

- Centro da Vila, Armazém, 3 casas (uma em cima de um platô).
- Um platô com subida (rampa na A, escada na B).
- 2 ipezinhos:
  - **Zeca** dá voltas no Centro: atrás, dos lados e na frente. É o caso difícil.
  - **Mel** sobe e desce o platô.

A lógica é **o mesmo arquivo** nas duas (`proto_logic.gd`): prédios, platô, navegação e
movimento em coordenada de chão, como o jogo de hoje. Só o desenho e o clique mudam.

## Imagens

| Arquivo | O que mostra |
|---|---|
| `lado_a_lado.png` | a cena inteira nas duas rotas, com o fantasma de construção válido |
| `A_caso_dificil_cortada_x_ingenua.png` | **o caso do prédio grande** na A, de perto |
| `A_volta_cortada.gif` / `A_volta_ingenua.gif` | a volta completa do Zeca nos dois modos |
| `B_volta_no_centro.png` / `B_volta.gif` | a mesma volta na B |
| `A_plato_e_fantasma_invalido.png` / `B_plato_e_fantasma_invalido.png` | relevo e fantasma vermelho ("no penhasco") |

## Resultado: Rota A (isométrico)

**Ficou bom**
- Projeção e inversa funcionam: o clique volta pro ponto de chão exato.
- A navegação e a lógica não mudaram nada.
- O visual "de maquete" com relevo é o que mais lembra as referências.
- A Mel sobe a rampa e aparece em cima do platô; a casa em cima do platô fica na altura certa.
- O posicionador (fantasma) funciona no chão e no platô, e recusa "metade no platô" e "no
  penhasco".

**Ficou estranho / quebrou**
- **Prédio grande com um ponto de ordenação só (modo ingênuo) QUEBRA, como previsto:**
  - Zeca atrás do canto direito é desenhado **por cima** do prédio;
  - Zeca na frente do canto esquerdo é **cortado** pelo prédio.

  Resolve **cortando o prédio em pedaços de ~40 px**, cada um com o seu ponto (modo cortado,
  certo nos dois casos). Com arte de verdade, isso significa que **todo prédio maior que um
  "tile" tem que ter a arte fatiada em colunas**.
- **Clique com relevo é ambíguo:** o mesmo ponto da tela pode ser o topo do platô ou o chão
  atrás dele. O protótipo dá prioridade ao topo. Com mais níveis, a regra fica mais difícil.
- **Altura + ordenação:** funcionou com a regra "chave = chão + altura" pra 1 platô. Casos
  como ponte, prédio na beira do penhasco e árvore alta na frente do platô vão pedir
  tratamento caso a caso.
- O personagem de frente em cena isométrica parece "adesivo": precisa de 4 a 8 direções.
- **Bug encontrado no caminho (não é da rota):** a 1ª consulta de rota do Godot volta vazia
  antes da navegação sincronizar. Corrigido na lógica compartilhada.

## Resultado: Rota B (top-down com relevo)

**Ficou bom**
- **Nenhuma conta de projeção.** O clique é o mouse direto e a ordenação é a de hoje (um
  ponto na base).
- O platô **parece alto** só com desenho: piso de grama, face de rocha na borda de baixo
  (ocupa espaço no chão) e escada. Casa e ipezinho em cima dele funcionam sem nada especial.
- Prédios em escala 3 deixam a vila com cara de vila (casa ≈ 2,3× o minerador).
- **Caso do prédio grande:** atrás, o Zeca some atrás do Centro; nos cantos de trás fica meio
  escondido pelo telhado; do lado e na frente aparece inteiro. **Um ponto só por prédio
  basta.**

**Ficou estranho / quebrou**
- **A pegada tem que ter a largura do desenho.** Na 1ª versão a pegada era do quadro inteiro
  (com a sobra transparente) e o Zeca passava longe do prédio, sem testar nada. Corrigido
  medindo a parte desenhada do sprite. É uma regra simples de arte: "a base do desenho é a
  pegada".
- Quem passa atrás de prédio alto **some** inteiro. É o comportamento normal do top-down;
  jogos assim deixam o telhado transparente quando tem alguém atrás, e isso é pouco código.
- Relevo é **ilusão:** não dá "ponte por cima de caminho", nem vantagem de altura como regra
  de jogo, sem modelar isso à parte.
- Não pega o ângulo diagonal das casas das referências. Pega o "Stardew com penhasco".

## Tempo real gasto

Relógio do protótipo (a sessão do Claude, não uma pessoa programando), conferido pela hora
dos arquivos:

| | Início | Fim | Tempo | Código próprio da rota |
|---|---|---|---|---|
| **Rota A** (incluindo a base comum: lógica e câmera) | 09:48:42 | 09:56:16 | **~7,5 min** | 446 linhas (`rota_a_iso` + `iso_box`) |
| **Rota B** | 09:56:16 | 09:59:31 | **~3,3 min** | 342 linhas |

A base comum (lógica + câmera, 204 linhas) foi feita dentro do tempo da A.

- **Correções de rota:**
  - A: 2 — tipo no GDScript e a 1ª consulta de navegação (esta é da base comum);
  - B: 1 — a pegada × a largura do desenho.
- **Pra comparar:** o tempo absoluto não prevê o tempo de uma pessoa. O que vale é a
  proporção (**A ≈ 2× B**) e o **tipo** de problema: os da A são de sistema (ordenação,
  clique com altura), os da B são de regra de arte.

## Opinião técnica: risco daqui a 3 ou 4 meses

**A Rota B tem bem menos risco.** Os problemas da A **crescem com o conteúdo**:

1. **Todo asset novo carrega a regra do isométrico:**
   - prédio fatiado em colunas (ou pegada de um tile só);
   - personagens em 4 a 8 direções.

   As roupas viram 18 × 6 × (4 a 8) folhas por animação (hoje são 108 folhas, só de frente).
   Cada função nova (regra da casa: "função nova vem com roupa") passa a custar 4 a 8× mais
   arte.
2. **Relevo + isométrico multiplica os casos de ordenação e de clique:** penhasco, ponte,
   escada, prédio na beira, árvore alta. Cada tipo novo de terreno é um caso novo de "quem
   desenha na frente".
3. **Tudo o que é desenho no jogo** passa pela projeção e precisa de revisão: rótulos, luzes,
   partículas, clima, cruzes do cemitério, zonas de perigo, barra de progresso de obra (71
   `offset`s, 17 áreas de clique). Não é difícil, mas é muita superfície pra bug visual.

Na B, os riscos são de **arte** e não de sistema:

- os penhascos precisam de peças pros 4 lados e cantos (o `TileMapLayer` com autotile de
  terreno do Godot resolve);
- o personagem ganha costas e lado (2 a 3 direções);
- o telhado transparente é um detalhe.

A lógica, o clique, a ordenação e os testes continuam como hoje.

**Quando a A valeria o risco:** se o ângulo diagonal das casas (o "visual de maquete" das
referências 1 e 2) for essencial pra identidade do jogo, e não só "ter relevo". Nesse caso,
o protótipo mostra que dá: a lógica aguenta. Mas o custo recorrente fica na arte e na
ordenação de cada peça nova.

**O corte da mina (referência 3)** continua separado e serve pras duas rotas.
