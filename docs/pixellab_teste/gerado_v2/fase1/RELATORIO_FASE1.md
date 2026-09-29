# Redesenho visual — Fase 1: minerador corrigido, animações e teste de consistência

Data: 2026-09-29. Checkpoint de aprovação: **nada foi integrado ao jogo**. Nenhum código,
cena ou save foi alterado. Tudo está em `docs/pixellab_teste/gerado_v2/fase1/` e
`docs/pixellab_teste/teste_consistencia/`.

## Resumo para decisão

| Ponto | Resultado |
|---|---|
| Parte A: corpo mais esguio e em 3/4 | ✅ Corrigido. Coxa de 33 → 26 px (CraftPix: 22–24), pose solta com a mão no cinto e o peso numa perna |
| Parte A: luvas | ✅ Corrigido. Luvas de couro nas duas mãos, em todos os 16 candidatos |
| Parte A: contorno mais fino | ⚠️ Em parte. Ver "Contorno" abaixo: a causa não era a espessura do contorno |
| Decisão da picareta | **(a) híbrida**: sobreposta nas costas e embutida só no golpe. Ver seção própria |
| Caminhada com picareta nas costas | ✅ Estável (skeleton-v3) |
| Minerar | ✅ Estável com **interpolação v3 entre dois estados**. O v3 com texto falhou |
| Machucado leve | ✅ Estável (skeleton-v3 e v3 texto) |
| Machucado grave | ✅ Pose parada estável. ⚠️ A animação só fica estável no corpo, o rosto varia |
| Guarda e casa no mesmo estilo | ✅ Paleta e densidade batem. ⚠️ O guarda tem contorno mais suave, a casa saiu em escala reduzida |
| Custo da fase | **247 gerações** (saldo: 25 → 272 usadas de 2000) |

**Três decisões pedem o Marco antes da Fase 2:**
1. **Escala dos prédios.** A casa saiu com porta de ~33 px para um minerador de 71 px, ou
   seja, uns 50% do tamanho "real". É a mesma proporção do jogo hoje (porta de 9 px, minerador
   de 17 px). Em escala real, a casa precisaria de canvas ~2× maior (≈240×210).
2. **Picareta:** aprovar a opção (a) híbrida descrita abaixo.
3. **Texto de estilo padrão:** trocar "contorno fino, não preto puro" por "contorno de 1 px
   quase preto". Explico no item "Contorno".

## Parte A — minerador corrigido

Prancha: `comparacao_v1_v2corrigido_craftpix.png` (CraftPix, v1 e v2 corrigido, 5× nativo, pés
alinhados).

| | CraftPix | v1 | **v2 corrigido** |
|---|---|---|---|
| Altura | 68–69 px | 73 px | **71 px** |
| Largura na coxa | 22–24 px | 33 px | **26 px** |
| Brilho médio | 0,31 | 0,22 | **0,23** (meta ~0,22) |
| Cores | 11–13 por personagem | 46 | **36** |
| Luvas | — | não | **sim, nas duas mãos** |
| Pose | 3/4 com atitude | frontal e rígida | **3/4, mão no cinto, peso numa perna** |

Mantido do v1: capacete de aço com lanterna âmbar visível, fuligem no rosto, expressão
fechada, remendo redondo no colete e remendo no joelho. Foi **adicionada a alça de couro
diagonal** no peito, que serve de encaixe para a picareta da opção (a).

- **Geração:** `create_image_pro` 48×80, 16 candidatos, **escolhido o 4**. Os candidatos
  12–15 perderam o colete e foram descartados.
- **Referências:** operário de suspensório, homem de terno e homem de colete (CraftPix).
  Imagem de estilo: o do colete (`style_copy` = contorno, detalhe e sombreado, sem paleta).

**Contorno.** Medindo as referências, **o contorno externo da CraftPix também é quase preto**
(95–99% dos pixels da borda). O v1 parecia "pesado" por outros motivos:
- corpo largo;
- linhas pretas entre os braços e o tronco;
- pose frontal, que junta as massas escuras.

O v2 corrigido resolve isso pelo corpo e pela pose. O contorno continua preto de 1 px, igual
à referência. Pedir "não preto puro" no prompt foi uma premissa errada. No guarda, o modelo
levou isso ao pé da letra e o contorno sumiu (ver Parte C). Recomendo que o texto de estilo
das próximas fases peça **"crisp 1px near-black outline"**.

Personagem v3: `minerador_corrigido_8_direcoes.png`. O sul ficou idêntico pixel a pixel ao
candidato e as 8 direções saíram coerentes.

## Parte B — estados e animações

Prancha geral: `resumo_animacoes.png`. Em todas as animações, o skeleton-v3 foi testado
primeiro.

Primeiro criei **estados** do mesmo personagem com `create_character_state`. Cada estado
mantém o mesmo rosto e a mesma roupa, nas 8 direções. Depois animei cada estado.
Revisão dos estados: `estados_revisao.png`.

| Estado | Canvas | Resultado |
|---|---|---|
| Picareta nas costas | 64×88 | Picareta na diagonal, legível nas 8 direções |
| Picareta na mão (erguida) | 80×96 | Sobre o ombro, pronta pra golpear |
| Golpe embaixo | 80×96 | Tronco inclinado, picareta cravada no chão (com um montinho de terra) |
| Machucado leve | 48×80 | Braço numa tipoia de pano sujo, ombros caídos, sem sangue |
| Machucado grave | 72×80 | Sentado e caído, perna na tala, cabeça baixa, capacete torto, sem sangue |

### 1. Caminhada com a picareta nas costas

| Tentativa | Ferramenta | Resultado |
|---|---|---|
| (b) embutida | estado "costas" + `animate_character` skeleton-v3 `walking-4-frames` | ✅ Estável: a picareta fica atrás do ombro nos 4 quadros |
| (a) sobreposta | caminhada base (skeleton-v3) + picareta de teste sobreposta localmente, seguindo o balanço de cada quadro | ✅ Tão legível quanto a (b) (`picareta_opcao_a_vs_b.png`, `opcao_a_overlay.gif`) |

### Decisão de arquitetura da picareta: (a) híbrida

**Nas costas, a picareta é sobreposta pelo código e encosta na alça desenhada no sprite.
No golpe, ela é embutida na animação.**

Por que (a) nas costas:
- **Visualmente dá empate.** Com a posição certa, a sobreposta lê tão bem quanto a embutida
  (compare as duas linhas de `picareta_opcao_a_vs_b.png`).
- **Custa bem menos pra manter.** Na (b), cada skin ou nível de picareta exige um estado novo
  (~20 gerações) e todas as caminhadas de novo. Na (a), cada skin é um sprite pequeno
  (~25 gerações, 64 candidatos) e as caminhadas do personagem servem pra todas as skins.
- **O encaixe já existe.** A alça diagonal faz parte do sprite base, sem geração extra.

Por que **não dá pra sobrepor no golpe**:
- Com 73 px e braços detalhados, girar um sprite solto não acompanha os braços. Mão, cabo e
  arco precisam ser desenhados juntos.
- Então a animação de minerar leva a picareta embutida. Consequência: skin nova de picareta
  = regerar o golpe (estado "golpe" + interpolação, ~22 gerações por direção; oeste sai
  espelhando o leste).
- Sugestão: usar uma única picareta "de trabalho" no golpe. Com o movimento rápido, a
  diferença de skin quase não aparece.

Custo de código da (a): uma tabela de deslocamento e ordem de desenho por direção e quadro.
No sul a picareta fica atrás do corpo; no norte, na frente. Se o jogo continuar só com
frente e espelho, são 4 deslocamentos.

### 2. Minerar (chegada + golpes)

Direção leste (de lado, onde o arco do golpe se lê melhor). Oeste = espelho.

| Tentativa | Ferramenta | Custo | Resultado |
|---|---|---|---|
| Golpe A | `animate_character` v3 com texto, 4 quadros | 1 | ❌ A picareta some no quadro 0, aparece um rastro branco de movimento (efeito fora do estilo) e o laço não tem a subida |
| **Golpe B** | estado "golpe embaixo" + `animate_character` v3 **interpolação** (início = estado erguida, fim = estado golpe), 5 quadros | ~21 | ✅ **Estável.** Mesmo boneco nos 5 quadros e arco legível. Tocar ida e volta fecha o ciclo sem salto (`anim_minerar_interpolacao_paleta_ciclo.gif`) |
| Chegada | v3 interpolação (início = estado costas, fim = estado erguida) | 1 | ⚠️ Mesmo boneco, mas a picareta aparece na frente de repente no quadro 1, sem o gesto de puxar das costas |

- **Skeleton-v3 no golpe: não existe modelo pronto.** Nenhum modelo de animação do PixelLab
  é de golpe de picareta. Montar um esqueleto próprio com `animate_with_skeleton_v3` exigiria
  posicionar à mão as 18 juntas de cada quadro. Não foi preciso, porque a interpolação
  resolveu.
- **Correção de paleta:** a interpolação pôs um brilho **ciano** na lâmina (quadros 1–3).
  Resolvi localmente, sem custo, trocando cada cor pela mais próxima da paleta dos dois
  estados de origem (~100 px por quadro). Versões `anim_minerar_interpolacao_paleta*`.
- **O montinho de terra** no quadro final vem do estado "golpe". Quando a rocha for um sprite
  próprio, talvez seja preciso apagá-lo.

### 3. Machucado leve

| Tentativa | Ferramenta | Resultado |
|---|---|---|
| A | skeleton-v3 `sad-walk`, 8 quadros | ✅ Estável e mantém a tipoia. Anda curvado, olhando pro chão (o rosto some sob o capacete) |
| B | v3 texto "limping…", 4 quadros | ✅ Estável e mantém a tipoia. O passo desigual lê como "mancando" e o rosto fica visível |

Recomendo a **B** pela leitura do machucado. A A também serve e tem mais quadros.

### 4. Machucado grave

| Tentativa | Ferramenta | Resultado |
|---|---|---|
| A | skeleton-v3 `breathing-idle` | ❌ **Falhou.** O modelo é de alguém em pé, então o personagem levanta e a tala some |
| B | v3 texto "breathing heavily while sitting", 4 quadros | ⚠️ Corpo, tala e pose ficam estáveis, mas o rosto muda: cabeça baixa → rosto de frente → careta |

Recomendo usar a **pose parada** (estado "machucado grave", 8 direções) com uma respiração
sutil feita pelo código (escala vertical de 1–2%). Tom sóbrio, sem sangue.

## Parte C — teste de consistência

Prancha: `../../teste_consistencia/consistencia_minerador_guarda_casa.png` (minerador, guarda e
casa na mesma escala, mesmo chão).

| Item | Resultado |
|---|---|
| **Guarda**, parado + caminhada | Mesmo texto de estilo e mesmas referências CraftPix do minerador, **sem mudar o prompt**. Precisou de **um ajuste de parâmetro**: com canvas 48×80, todos os 16 candidatos saíram cortados (topo do capacete ou sola das botas). **O `create_image_pro` estica o boneco até encher a altura do canvas**, e o prompt pede um guarda "tall". Com 48×84, saíram 16 candidatos inteiros; **escolhido o 11**. A paleta bate (brilho 0,17) e a densidade também, e a silhueta é bem diferente da do minerador. ⚠️ **O contorno ficou mais suave**, sem a borda escura nítida do minerador. A caminhada skeleton-v3 ficou estável (há um pixel solto no quadro 2). |
| **Casa nível 1** | Mesmo texto de estilo, mais o minerador como referência de escala. ✅ Estilo consistente: ardósia com musgo, chapa enferrujada, base de pedra, tábuas gastas, porta em arco, contorno escuro, brilho 0,21. 4 candidatos, **escolhida a 0**. ⚠️ **A escala saiu reduzida:** porta de ~33 px para minerador de 71 px, apesar de o prompt pedir uma porta do tamanho dele. ⚠️ Saiu em 3/4 mostrando a parede lateral, não em fachada reta como pedi. |

**Conclusão da Parte C:** o fluxo se mantém consistente em paleta, densidade de pixel,
sombreado e clima. Os desvios são pequenos e previsíveis:
- **Canvas:** reservar folga de altura pra personagens altos.
- **Contorno:** fixar "near-black" no texto de estilo.
- **Escala de prédio:** decisão de projeto, não do fluxo.

## Custo em gerações

Total medido pelo saldo: **247 gerações nesta fase** (25 → 272 usadas de 2000; sobram 1728
até 2026-10-29).

| Item | Ferramenta | Custo |
|---|---|---|
| Minerador corrigido (16 candidatos) | `create_image_pro` 48×80 | 25 |
| Picareta de teste (64 candidatos), usada só na simulação da (a) | `create_image_pro` 40×40 | 25 |
| Minerador → personagem 8 direções | `create_character` v3 | 1 |
| Estados: costas, na mão, leve, grave, golpe | `create_character_state` ×5 | ≈100 (a doc diz 20–40 cada) |
| Caminhadas e animações skeleton-v3: base, costas, sad-walk, breathing, guarda | `animate_character` skeleton-v3 ×5 | ≈20 (a doc diz 2–4 cada) |
| Minerar texto, chegada, golpe interpolado, leve texto, grave texto | `animate_character` v3 ×5 | 5 |
| Guarda 1ª rodada (48×80, cortado, descartado) | `create_image_pro` | 25 |
| Guarda 2ª rodada (48×84) | `create_image_pro` | 25 |
| Guarda → personagem 8 direções | `create_character` v3 | 1 |
| Casa (4 candidatos) | `create_image_pro` 128×112 | 20 |
| **Total** | | **247** |

Estados e skeleton-v3 somam 120 juntos pelo saldo. A divisão ≈100/≈20 é estimativa. Gasto
que não virou asset: guarda cortado (25), minerar v3 texto (1) e grave skeleton (~4).

**Estimativa pra Fase 2**, por personagem novo no pacote mínimo (parado + caminhada):
~30 gerações. Com o pacote completo do minerador (4 estados + 5 animações): ~130.

## Receita consolidada pras próximas fases

1. **Personagem:** `create_image_pro`
   - 48×80, ou **48×84+ se for alto**;
   - 3 recortes CraftPix em `reference_images`;
   - `style_image` = CraftPix do colete, com `style_copy=[outline, detail, shading]`;
   - texto de estilo padrão com **"crisp 1px near-black outline"**.
2. `create_character(mode="v3", reference_image=<escolhido>, view="side")`.
3. **Poses** (ferramenta na mão, machucado etc.): `create_character_state`, com
   `override_width/height` quando a pose ocupa mais espaço.
4. **Andar:** `animate_character` skeleton-v3 `walking-4-frames`.
   **Ações sem modelo pronto:** estado de início + estado de fim + **interpolação v3**,
   depois trocar as cores pela paleta de origem.
   **Poses paradas no chão:** usar o estado parado. O skeleton-v3 "levanta" o personagem.
5. **Prédio:** `create_image_pro` com o mesmo texto de estilo e um personagem como referência
   de escala, depois de decidida a escala.

## Arquivos

`gerado_v2/fase1/`:
- `comparacao_v1_v2corrigido_craftpix.png`: prancha pedida (v1 × v2 corrigido × CraftPix).
- `minerador_corrigido_grade_16.png`, `minerador_corrigido_candidatos/`,
  `minerador_corrigido_escolhido_c04.png`, `minerador_corrigido_rotacoes/`,
  `minerador_corrigido_8_direcoes.png`.
- `estados_revisao.png` e `estado_*/`: os 5 estados em 8 direções.
- `resumo_animacoes.png`: todas as animações numa prancha.
- `anim_*/`, `anim_*_tira.png`, `anim_*.gif`: cada animação (quadros, tira e GIF).
- `picareta_opcao_a_vs_b.png`, `opcao_a_overlay/`, `opcao_a_overlay.gif`,
  `picareta_teste_*`: decisão da picareta.

`teste_consistencia/`:
- `consistencia_minerador_guarda_casa.png`.
- `guarda_grade_16.png`, `guarda_candidatos/`, `guarda_escolhido_c11.png`,
  `guarda_8_direcoes.png`, `guarda_rotacoes/`, `guarda_caminhada_skeleton*`.
- `guarda_t1_48x80/`: a rodada cortada, guardada como evidência.
- `casa_grade_4.png`, `casa_candidatos/`, `casa_escolhida_c00.png`,
  `casa_escala_com_personagens.png`.

IDs no PixelLab (conta do Marco):
- Minerador v2b: `0e06f946-d5fa-497f-a78b-d61e34fad92a`. O grupo tem 6 estados; os IDs de
  cada estado aparecem no `get_character`.
- Guarda: `260cfe31-47c2-413c-bd74-bab73f5530e4`.
