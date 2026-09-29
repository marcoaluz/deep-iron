# Câmera isométrica: avaliação de viabilidade

Data: 2026-09-29. **Só levantamento.** Nenhum código, cena ou asset foi alterado.
As 3 imagens de referência foram salvas depois; ver o **Adendo** logo abaixo.

## Adendo: o que as referências mostram (imagens salvas em 2026-09-29)

Salvas em `docs/pixellab_teste/referencia_estilo/` como `isometrico_1.png`,
`isometrico_2.png` e `isometrico_3_corte.png` (1408×768 cada).

**Imagens 1 e 2 (vila e mina na superfície)** não são um isométrico 2:1 "de grade". São uma
ilustração em **vista oblíqua alta, com relevo**. O que realmente muda em relação ao jogo de
hoje, em ordem de peso:

1. **Relevo de verdade:** penhascos, platôs em 2 ou 3 alturas, escadas de pedra, bocas de
   mina **na parede do penhasco**, poço aberto com broca descendo. Hoje o mapa é plano. Isso
   pesa mais que o ângulo: altura muda navegação (rampas, escadas), ordem de desenho e onde
   dá pra construir.
2. **Prédios vistos na diagonal** (casas giradas, telhado e duas paredes aparecendo), grandes
   em relação ao personagem (casa ≈ 3 a 4× a altura do minerador, como o Stardew).
3. **Personagem adulto e pequeno**, de lado e de 3/4 (várias direções).
4. **Densidade de detalhe alta:** carrinhos, trilhos, caixotes, ferramentas no chão, trilhas
   orgânicas de terra.

A perspectiva é de ilustração (varia pela imagem). Um jogo **isométrico** consegue chegar
nesse visual, e um **top-down 3/4 com relevo e arte nova** (a projeção de hoje, com
penhascos em camadas estilo Stardew) chega em boa parte dele. Esse "meio caminho" custa bem
menos: sem camada de projeção, e personagem de frente/lado/costas em vez de diagonais. Vale
colocar as duas lado a lado no protótipo (§6) antes de decidir.

**Imagem 3 (corte da mina)** confirma o §7: é **vista de lado**, com os níveis empilhados
(superfície → poeira → gás tóxico verde → lava → fundo), ligados por elevador e escada em
espiral, e até um **minimapa de corte** no canto. Ela bate direto com os sistemas que já
existem:

- níveis ligados por elevador;
- zonas de perigo com traje (gás, calor, radiação, do Bloco 42);
- escavadeira no fundo.

É a candidata natural pra tela "Corte da mina" sob demanda, **independente** da câmera
principal.

## 0. Fase 2 do redesenho top-down: status

**Não estava rodando.** Nenhuma geração ativa nem recente no PixelLab (`list_jobs`). Quem
começou foi outra sessão (deep-iron-8a, parada). Em `gerado_v2/fase2/` só existe
`paletas_pele.json`: parou **antes do primeiro personagem**. Nada a cancelar.
Recomendação: **manter pausada** até decidir a câmera. Personagem isométrico precisa de
4 ou 8 direções; o de hoje só tem a de frente (espelhada).

## 1. O que hoje depende de "visão de cima"

| Sistema | Como é hoje | Depende de top-down? |
|---|---|---|
| **Chão / mapa** | Sem TileMap. Texturas repetidas por retângulo (`environment.gd`), bordas de pedregulho, áreas = `Rect2` (mapa, clareira, fundo, abismo) | Visual sim; a lógica (retângulos no chão) não |
| **Navegação** | `NavigationRegion2D` feita em código a partir de retângulos e contornos de obstáculo (`_bake_navigation`) | Não: é o plano do chão |
| **Colisão / obstáculo** | Contorno retangular por prédio (`get_obstacle_outline`), vagas em arco | Não (chão) |
| **Clique no mapa** | 1 `get_global_mouse_position` + `contains_point` (17 retângulos no formato do desenho) | **Sim:** o retângulo clicável é o desenho na tela |
| **Posicionador (construir)** | Pegada retangular alinhada aos eixos; fantasma = sprite | Lógica não; fantasma e mouse sim |
| **Ordem de desenho** | O `World` já usa `y_sort_enabled` (o de mais embaixo desenha na frente) | Já existe; em iso muda a chave (ver §2) |
| **Câmera** | `Camera2D` própria (zoom, pan, limites). Phantom Camera instalado, sem uso | Limites e pan em retângulo |
| **UI (HUD, menus)** | Tela | Não |
| **Save** | X/Y absolutos no chão | **Não muda de sentido** se o chão lógico for mantido (§3) |
| **Desenho dos objetos** | 71 `offset` de sprite, rótulos, luzes, partículas, sombras, `flip_h` (17) | **Sim** |

Tamanho do código: ~20.200 linhas de GDScript. `global_position` aparece 261 vezes e
`distance_to` 66, mas quase tudo é **lógica no chão** (distância, raio, vaga, rota). Não é
desenho.

## 2. Ordem de profundidade (depth sorting)

- O Godot 4 **não tem mais o nó YSort**: virou a propriedade `y_sort_enabled` em qualquer
  Node2D/TileMapLayer. É nativo e o jogo **já usa** no `World`, porque o top-down 3/4 atual já
  tem o mesmo problema (quem está mais embaixo na tela vai na frente).
- `TileMapLayer` tem **tile isométrico nativo** (`tile_shape = ISOMETRIC`) com y-sort e origem
  de ordenação por tile. É comum e nada exótico.
- **Onde complica:** o y-sort ordena por **um ponto por nó**. Em isométrico, prédio grande
  (Centro da Vila, escavadeira, arsenal) com personagem passando pela lateral dá o erro
  clássico (o boneco some atrás ou aparece na frente errado). As soluções padrão são:
  - ponto de ordenação no canto mais "à frente" da pegada;
  - ou prédio grande dividido em 2 ou 3 pedaços.

  Dá pra fazer em cima da estrutura atual, mas tem que ser tratado **prédio a prédio**.
- **Atenção técnica (confirmar no protótipo):** se o isométrico for feito aplicando uma
  transformação no nó `World`, o y-sort ordena pela coordenada **local** (y do chão) e não
  pela da tela (x+y). Por isso a proposta abaixo projeta a **posição de desenho** e não o
  `World` inteiro.

## 3. Arquitetura recomendada: chão lógico + camada de desenho

A regra que decide "acréscimo grande" contra "reescrever":

> **O jogo continua simulando num plano de chão cartesiano (o de hoje).** Posições,
> navegação, colisão, raios, velocidades e save ficam iguais. Só a **apresentação** projeta
> esse chão pra tela: `tela = (x − y, (x + y) / 2)` (2:1) e a inversa pro mouse.

Na prática:

- cada entidade (ipezinho, prédio, jazida) mantém o nó lógico;
- o visual dela (sprite, rótulo, luz) fica num nó de desenho posicionado na posição projetada,
  dentro de uma camada com y-sort pela **tela**;
- o chão vira TileMapLayer isométrico, ou as texturas atuais desenhadas com a mesma
  transformação.

## 4. Esforço

### a) Só desenho e conta (fácil): ~1 bloco
- Fórmula de projeção e a inversa (mouse → chão). Uma função.
- Câmera: limites e pan passam a ser o losango do mapa. A Phantom Camera **não ajuda aqui**
  (ela segue alvo e faz zoom, não projeta). A `Camera2D` atual serve.
- Barra de vida, rótulos e ícones sobre a cabeça: posição projetada + deslocamento na tela.

### b) Rework de sistema (médio/alto): ~4 a 6 blocos
- **Camada de desenho** separada da lógica (§3) pra todas as cenas de entidade (~30 cenas).
- **Ordem de profundidade** com ponto de ordenação por prédio e divisão dos grandes.
- **Clique no mapa:** os 17 `contains_point` viram o retângulo do desenho **na tela**; o chão
  pela inversa.
- **Posicionador:** pegada vira losango na tela (a lógica continua retangular no chão), fantasma
  projetado, e a regra "não encosta no desenho do outro" passa a olhar a tela.
- **Chão e bordas:** o `environment.gd` desenha o mapa (texturas, pedregulhos, paredes das
  galerias). A parte **visual** dele é refeita em tiles isométricos; a navegação continua a
  mesma.
- **Direção do personagem:** hoje é esquerda/direita espelhado. Em iso são 4 (ou 8) direções
  a partir do vetor de movimento no chão.
- Luz, sombra, partícula e clima: conferir um por um (71 `offset`s).

### c) Praticamente do zero: **a arte, não o código**
- **Todos os ~130 desenhos** (personagens, prédios, jazidas, decoração, chão) precisam ser
  refeitos no ângulo isométrico. Nada do top-down aproveita.
- **Personagens em 4 a 8 direções** com caminhada em cada uma. O PixelLab `create_character`
  já gera 8 direções nativas (o relatório da tentativa 1 viu isso como problema; aqui vira
  vantagem).
- No código **nada** entra nessa categoria se a arquitetura do §3 for seguida.
  - **Viraria reescrita:** projetar o mundo trocando as posições lógicas pelas da tela, ou
    migrar pra 3D.

## 5. O que se aproveita 100%

Continua igual, porque não conhece perspectiva:

- economia, pesquisa, obras e engenheiro, defesa e armas;
- equipamento, ânimo, fome, saúde, médico;
- IA e estados dos ipezinhos, funções, sol/clima (a lógica), eventos;
- **save** (as coordenadas continuam sendo do chão, então os saves atuais continuam válidos);
- menus e HUD;
- testes GUT de lógica.

A maior parte das ~20 mil linhas é isso. **É um acréscimo grande na apresentação mais uma
arte nova, não reescrever o jogo.**

Os testes que olham desenho (quadro do sprite, `contains_point`, posicionador) vão precisar
de ajuste; os de lógica, não.

## 6. Em fases, com teste controlado primeiro

1. **Protótipo isolado (1 a 2 blocos):** cena nova, fora do jogo (`iso_teste.tscn`), com a
   fundação:
   - Centro da Vila, armazém, 3 casas e 2 ipezinhos andando;
   - sprites provisórios.

   Validar: projeção, ordem de profundidade com personagem passando atrás e na frente de
   prédio grande, clique, posicionador e navegação. O jogo de verdade não é tocado.
2. Se aprovado: camada de desenho no jogo inteiro, com a arte **atual** projetada
   provisoriamente. O jogo continua jogável, só feio.
3. Arte isométrica por grupos: chão → personagens → prédios, a mesma ideia de fases da
   auditoria de escala.

Nada é tudo-ou-nada até o passo 2, e o protótipo decide se vale.

## 7. Referências: vila (1 e 2) × corte da mina (3)

São **duas necessidades diferentes**:

- **Imagens 1 e 2 (vila em ângulo isométrico):** é a **câmera do jogo**. É isso que este
  relatório avalia.
- **Imagem 3 (corte transversal tipo formigueiro):** é **vista de lado**, outra projeção. Faz
  mais sentido como uma **tela à parte, sob demanda** ("Corte da mina"), mostrando os níveis
  empilhados:
  - superfície, nível 2 (fundo) e abismo, ligados por elevadores;
  - com os ipezinhos em cada nível.

  O mapa atual **já empilha os níveis no eixo Y** (fundo a partir de y≈700, abismo a partir
  de y≈1420), então essa tela pode ler os dados que já existem.

  Ela é **independente** da decisão isométrica: dá pra fazer mesmo mantendo o top-down.
  Tentar que a câmera principal seja as duas coisas ao mesmo tempo seria um problema bem
  maior.

## Resumo pra decidir

- **Viável sem reescrever o jogo**, se o chão lógico for mantido e só a apresentação projetar.
- **Código:** cerca de 1 bloco de conta, 4 a 6 de rework e 1 a 2 de protótipo antes.
- **O custo pesado é arte:** tudo refeito, com personagens em várias direções.
- **Primeiro passo sugerido:** o protótipo isolado da fundação.
- **Corte da mina:** decisão separada.
