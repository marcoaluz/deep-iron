# DEEP IRON — Contrato de arte (fonte única de verdade)

Toda a arte do jogo é refeita em **isométrico 2:1 (Rota A)**. Este arquivo junta o que já
foi decidido e aprovado. **Todo prompt de arte começa lendo este contrato e o
`docs/arte/INVENTARIO.md`, e termina atualizando o INVENTARIO.**

Fontes que ele consolida:

- `docs/escala_visual/prototipo_camera/ENDURECIMENTO_rota_A.md` (as 7 regras);
- os checkpoints em `docs/escala_visual/arte_iso/`: minerador, casa, elenco, relevo;
- `docs/pixellab_teste/gerado_v2/` (Fase 1 do estilo);
- a memória do fluxo PixelLab.

O `deep-iron-dev-log` citado pelo Marco não está no repositório; se tiver algo que falta
aqui, acrescentar.

---

## 1. Estilo

**Referência.** A régua de estilo tem duas partes:

- CraftPix (`docs/pixellab_teste/referencia_estilo/craftpix_*.png`): personagem adulto de
  ~70–80 px, textura legível, proporção ~6,5 cabeças;
- as 3 imagens isométricas de referência (`isometrico_1.png`, `isometrico_2.png`,
  `isometrico_3_corte.png`).

**Tom "dark/sujo":**

- paleta terrosa: marrom escuro, ferrugem, cinza-chumbo, preto-fuligem, com **um acento**
  por peça (lanterna âmbar, colete laranja, brasa...);
- desgaste, fuligem, remendos, sujeira;
- **mais escuro e mais sujo que a CraftPix.**

**Brilho médio.**

- Métrica: média do **valor HSV** (máx(R,G,B)/255) dos pixels opacos.
- Meta: **~0,22–0,23**. A CraftPix fica em 0,31–0,33.
- Medido na arte aprovada: casa 0,22; chão da colônia 0,24; minerador 0,20; bloco de
  penhasco 0,18.
- Tolerância aceita por tipo: **0,18–0,26**. Fora disso, reportar.

**Texto de estilo obrigatório**, anexado ao fim de TODA geração (com o acento trocado por
peça):

> Grimy, dark, desaturated earthy palette: dark browns, rust, lead grey, soot black;
> [one accent]. Darker and dirtier than the references. **Crisp 1px near-black outline**
> around the silhouette like the references; interior detail drawn with darker shades of the
> local color rather than black lines. Clear form shading with light from top-left, low
> color count, clean readable pixel clusters.

- Nunca escrever "not pure black": essa frase fez o guarda perder o contorno.
- **Exceção de terreno:** tile de chão e face de penhasco NÃO levam contorno nas bordas que
  emendam. O contorno viraria uma grade (ver §2.6).

**Luz.** Vem de cima-esquerda. Topo mais claro, face da esquerda (SO) média, face da direita
(SE) mais escura. Isso vale pra personagem, prédio e terreno.

**Escala.**

- O **minerador isométrico aprovado é a régua**: ~70 px de altura, caixa 28×28×70.
- **Porta de prédio = altura do minerador** (a da casa tem ~80).
- Prédios em **escala real**, sem miniatura. Fator em relação ao jogo antigo: **~2,1** na
  pegada (casa de 60 → pegada 130×100).
- **Limite técnico:** o maior quadro do PixelLab é ~512 px. Os 3 maiores (Centro da Vila
  estágios 4–5 e Escavadeira) não cabem no fator 2,1. Pra eles, **decidir no prompt**: fator
  ~1,7 ou montar com 2 caixas (regra do prédio em "L").

**Sem gore.** Ferimento, morte e combate sempre sóbrios, sem sangue:

- ferido: curativo/tala;
- morto: deitado e imóvel, cova;
- combate: golpe sem respingo.

---

## 2. Técnica

### 2.1 Imagem-guia 2:1 (antes de TODA geração)

- A guia é desenhada no próprio PixelLab (`pixelart_workbench draw`, grátis) e passada **por
  link** em `reference_images` com o uso "layout guide ONLY (do not draw the lines)".
- Nunca transcrever imagem em base64 à mão (corrompe).
- Personagem: losango do chão sob os pés + a caixa até a altura dele.
- Prédio: caixa em arame 2:1 + contorno da porta na parede SO.
  - Gerador: `arte_iso/predio.py guia <pasta> <largura_x> <fundo_y> <altura> [sobra] [porta]`.
- Terreno: bloco (losango 64×32 + 2 faces de 32) ou forma da escada.

### 2.2 Caixa declarada (regra 2)

- **Antes de gerar**, declarar pegada (largura × fundo) + altura.
- O desenho pronto tem que caber na caixa, **no máximo 4 px fora**.
- **O fundo da caixa fica fixo na parede de trás** ao encaixar: sem isso, o isométrico troca
  fundo por altura e a caixa sai degenerada.
- Cada desenho (estágio, variação) tem a SUA caixa no `contrato.json` da pasta.
  - Encaixe automático: `arte_iso/predio.py caixa`.
- Prédio côncavo (em "L") = 2+ caixas. Rampa = caixa com topo inclinado.
- Personagem: caixa estrita (≤ 4 px fora) **e** caixa de corpo (≤ 0,5% dos pixels fora,
  `caixa_corpo.py`). **Na ordenação usa-se a de corpo**; ponta de ferramenta pode sair.

### 2.3 Âncora (regra 3)

- **Prédio:** o centro da pegada no chão, anotado em pixels do quadro
  (`contrato.json → ancora_no_quadro`). **A mesma âncora em todas as variações e estágios**
  de um objeto: a obra e o pronto trocam no mesmo lugar. Pra isso, os estágios e variações
  usam o desenho pronto como referência de estrutura.
- **Personagem:** âncora por direção (pé), anotada no `contrato.json` da pasta.
- **Tile:** canto de cima do quadro = canto norte do tile na altura do topo;
  `tela(i,j,k) = ((i−j)·32, (i+j)·16 − k·32)`.

### 2.4 Personagens e criaturas

- **4 direções de losango** (SE, NE, SO, NO): 2 desenhos (SE e NE) + espelho **por
  animação**. O parado também sai por espelho.
- As 8 poses paradas que o `create_character` v3 dá de graça ficam guardadas em `rotacoes/`.
- Histerese de 15° na troca de direção (integração).
- Se a pose NE da rotação sair quase de costas (igual à N), a caminhada NE vira o rosto no
  meio do passo. Nesse caso, animar a **NO** e espelhar (`links.py … NO:<id>`).

### 2.5 Animação (nesta ordem de preferência)

1. **skeleton-v3** com modelo pronto (ex.: `walking-4-frames`): corpo e cores estáveis.
2. **Interpolação v3** entre dois estados (pose inicial → pose final), quando não há modelo.
   Depois, travar as cores na paleta de origem.
3. **v3 com texto** só se as outras falharem: tende a deformar (cabeça vira, pernas somem).

Cada animação é revisada numa folha de quadros (`folha_caminhadas.py`, SE + NE lado a lado,
recortados na âncora).

**Animação de trabalho: o que funcionou no Prompt 1.**

- Técnica: **v3 com texto, 8 quadros, `keep_first_frame=false`**, 2 gerações por direção.
  - Desvio da ordem acima, reportado e aceito pela qualidade.
  - Não existe modelo de esqueleto pra essas ações. O `cross-punch` testado no guarda virou
    soco sem arma.
  - Pose nova + interpolação custaria 20–40 por personagem.
- **Texto que segura o resultado:**
  - "already holds the <tool> from the first frame";
  - "keeps facing the same direction / never turns toward the viewer";
  - "Only the character and his <tool>: no rock, no ground, no motion trails, no white arcs,
    no glow, no effects".
- **O objeto de trabalho que a IA insiste em desenhar** (panela no fogão, toco, balde) vira
  outro objeto que **anda junto** com o personagem. Ex.: cozinheiro batendo numa **tigela no
  braço**.
- **Limpeza automática** (`trabalho.py`):
  - apaga branco puro;
  - apaga cor muito clara (luminosidade ≥ 0,80) que não existe nas poses paradas do
    personagem (rastro, sopro, vapor);
  - apaga mancha solta clara ou minúscula.
- **Direção de trás que gira** (o personagem vira de frente no meio do golpe): animar a **NO**
  e espelhar pra NE.

**Objeto carregado = sobreposição, não animação.** O v3 desenha o objeto de um jeito
diferente em cada direção. Por isso:

- saco, e depois cesto, tora e caixa: **caminhada + sprite por cima** (`saco.py`);
- atrás do corpo de frente pra câmera, na frente de costas;
- acompanha o balanço do passo.

**Variante de personagem** (`create_character_state`) custa **~28 gerações**, não 16. Usar só
quando a roupa muda a silhueta inteira (trajes, casaco).

**Filtros de limpeza** do `trabalho.py`:

- sangue (vermelho escuro incluído) sempre sai;
- a opção `claro` preserva branco de tipoia, tala e curativo;
- a opção `estado=<Pasta>` escolhe a variante no zip do grupo.

**Altura relativa do elenco.**

- A mulher fica **3–4 px mais baixa** que o homem da mesma função.
- Pra encolher, **tirar linhas inteiras** acima do pé (`encolhe.py`), sempre as mesmas em
  todos os quadros: paradas, caminhada, trabalho. **Nunca reescalar.**
- Aprovado pelo Marco. O corte de cada personagem está em `encolhe.CORTE`, e o
  `trabalho.py`/`aplica_corte.py` aplicam sozinhos.

### 2.6 Tileset (regra 6: relevo = mapa de altura)

- **Tile = 32×32 no chão** (losango de **64×32** na tela). **Degrau = 32** de altura
  (aprovado). Bloco = 64×64.
- **"4 lados + cantos" sem tile de canto.** Com blocos e desenho coluna a coluna ((i+j)
  crescente, de baixo pra cima), toda face escondida é coberta sozinha. Cantos de fora e de
  dentro saem certos com: chão, bloco com borda, bloco sem borda (embaixo de outro) e escada
  (+ espelho).
- **Buraco:**
  - paredes externas (do lado da câmera) **não desenhadas**;
  - **borda da frente tão grossa quanto o buraco é fundo**: o chão em volta é coluna cheia
    desde o fundo;
  - cada degrau abaixo do chão escurece 20%.
- **Transição entre tipos de chão:** tipo nos vértices + ruído em coordenada de mundo
  (`relevo/tiles.py topo_misto`), sem os 16 cantos por par.
- **Espelho:** só o chão espelha. **Bloco nunca**, porque o espelho troca a face clara com a
  escura.
- **Retificação:**
  - a IA desenha o bloco 1–2 px menor e com contorno;
  - `tiles.py retifica` reamostra na geometria exata, pulando o contorno;
  - `equaliza_borda` tira o escurecido da borda (usando a paleta do próprio tile).
- **Escada:** só na frente de face visível (sul/leste do platô) ou encostada na parede do
  fundo de um buraco.
- Na integração, cada platô/buraco vira **uma imagem montada** = a caixa dele na ordenação.

### 2.7 Fluxo PixelLab que funciona (custos reais)

| Peça | Como | Custo |
|---|---|---|
| Personagem (base) | `create_image_pro` 48×84 + guia + minerador/médica aprovados como referência + texto de estilo | 16 candidatos, 25 |
| Personagem (8 dir.) | `create_character` v3, `view="high top-down"`, candidato escolhido por link | 1 |
| Caminhada SE+NE | `animate_character` skeleton-v3 `walking-4-frames` | ~2–3 |
| Prédio | `create_image_pro` ~240×288 + guia + casa/minerador como referência | 1 candidato, 25 |
| Obra/variação | mesma chamada, com o prédio pronto como referência de estrutura | 25 cada |
| Bloco de terreno | `create_image_pro` 64×64 + guia + bloco aprovado | 16 candidatos, 20 |

- **Personagem gigante** (robô, 218 px, Prompt 5): base `create_image_pro` ~176×224 (1
  candidato, 20); rotação v3 custa 5; cada animação v3 custa **8 por direção**.
- **Estágios de um objeto deitado/parado** (achado, conserto): gerar com o desenho base como
  referência **no mesmo tamanho de quadro que ele**. Com o quadro maior que a referência, o
  modelo desloca e corta. Conferir a sobreposição com o base (≥ 95%) e as bordas; o que
  encostar na borda se completa com inpaint num quadro ampliado.
- `create_image_pro` **ignora** texto de ângulo ("30° camera"): é a guia que garante o 2:1.
- Limite de **8 jobs** ao mesmo tempo.
- Link do Backblaze precisa de User-Agent de curl.
- `wait_for_jobs` pode repetir resultado antigo: conferir com `list_jobs`.
- `no_background` às vezes devolve **fundo branco sólido** (escada): tirar no script.
- **Ampliar o candidato antes de escolher:** um "arco" era um rolo de corda.

---

## 3. Regras de conteúdo

- **Obra em toda estrutura construível:**
  - `obra_1`: fundação e material solto;
  - `obra_2`: esqueleto/andaime;
  - `obra_3`: paredes e telhado incompletos;
  - `pronto`.
- **Upgrade de nível** (1→2→3) **também tem obra entre os níveis**: andaime sobre o prédio do
  nível anterior.
- **No jogo, o desenho troca pelo progresso do engenheiro:** 0–33% / 33–66% / 66–100%.
  **Nunca** o "fantasma que fica nítido" (canteiro.gd atual). Isso é trabalho de integração.
- **Estados só de luz** (acesa quando em uso: laboratório, oficina, taverna, enfermaria,
  coletor, cabine da escavadeira) saem por **ponto de luz no código** (regra 7), sem desenho
  novo.
- **Estados de conteúdo** (pilha do armazém, comida do comedouro, plantação da horta, armas
  do arsenal) são **sobreposição** com a mesma âncora.
- **Diversidade:**
  - todo humano cobre homem e mulher e pele clara, parda e negra;
  - os tons saem por **troca de paleta no código**, com as rampas em
    `prototipos/camera/arte_iso/paletas_pele.json` (lidas também por `tons_de_pele.py`);
  - as cores de pele de cada sprite saem do rosto;
  - na cabeça vale a regra solta, no corpo só a cor que não é também de roupa;
  - na integração, preferir **máscara de pele por quadro**.
- **Variedade de corpo:** forte, magro, meio gordinho, cheinho. Mulheres com busto/curva
  **discretos**, não em todas.
- **Ferramentas pela regra de progresso do jogo:** o **arco só aparece quando a Oficina libera
  "caça de animais"**. Antes disso, o caçador fica sem arco (cesto/corda).
- **Picareta híbrida:**
  - overlay nas costas: **atrás** do corpo quando o boneco está de frente pra câmera (SE/SO),
    **na frente** quando está de costas (NE/NO);
  - no golpe, é **parte do desenho da animação de minerar**;
  - valem 2 conjuntos de posição (frente/costas), espelhados.
- **Machucado do elenco:** ícone de curativo/tala sobreposto + **pose parada com respiração
  por código**, sem animação de IA.
- **Estações:**
  - elemento natural (chão, árvore, vegetação, telhado) ganha variante por estação **só se o
    jogo usar estação nele**;
  - **hoje o jogo só usa estação no clima** (folha, pólen, chuva, neve em `weather.gd`) e no
    casaco de inverno (`equipment.gd`), então chão e árvore **não** têm variante por enquanto.

---

## 4. Processo (vale pra TODO prompt de arte)

1. **Ler este contrato e o `INVENTARIO.md`** antes de começar.
2. **Estimar o custo** em gerações antes de gerar (`get_balance`). Se passar do saldo do
   ciclo, gerar só o que cabe, pela prioridade do inventário, e **parar reportando** o que
   faltou e quanto custa.
3. **Peça-piloto** de cada tipo novo, que tem que passar no **verificador automático**:
   - caixa: ≤ 4 px fora (`predio.py caixa` / `personagem.py` / `caixa_corpo.py`);
   - âncora igual entre estágios;
   - cena de estresse + ordem por caixas (`rota_a_estresse.gd`, com `arte=`), 0 erros.
4. Se a piloto passar e seguir o contrato, **continuar sem esperar o Marco**, **exceto** nos
   prompts marcados **CHECKPOINT MARCO**.
5. Tudo isolado em `project.godot/prototipos/camera/arte_iso/<categoria>/`. **Nada
   integrado** ao jogo principal antes dos prompts de integração.
6. **Desvio do contrato:** reportar, não contornar sozinho.
7. **Entrega:**
   - prancha lado a lado;
   - GIF das animações;
   - custo (saldo antes → depois);
   - desvios;
   - `INVENTARIO.md` atualizado (status de cada item).
8. **Segurança de teste:** toda execução do Godot (headless ou janela) usa APPDATA e
   XDG_DATA_HOME isolados (`fake_appdata`) e confere o md5 do save real antes/depois. Nunca
   tocar no save do jogador nem fechar o editor do Marco.
