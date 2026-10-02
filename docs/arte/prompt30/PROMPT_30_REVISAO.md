# Prompt 30: revisão final (QA visual, consistência, desempenho, limpeza)

Data: 2026-10-01. Branch `isometrico`. Sem geração no PixelLab (saldo **1.359**).

Retomado de onde a outra sessão parou: o Prompt 29 inteiro (partes 1–6) estava pronto e a
**limpeza** (item 4) já tinha sido feita (`docs/arte/limpeza_prompt30.json`), ainda sem relatório
e sem commit.

## 4. Limpeza (feita pela outra sessão; conferida aqui)

- **Apagados 5.125 arquivos**, todos conferidos contra a lista `docs/arte/limpeza_prompt30.json`:
  - 4.852 de `prototipos/camera/`: candidatos do PixelLab (`c00`…`c84`), grades de escolha,
    rascunhos `_*.png`, cenas de conferência; **as pastas `final/` e os contratos ficaram**
    (o `monta.py`, o `andares.py` e o `integra.py` continuam rodando);
  - `demo/` (demonstração do plugin LimboAI) e `godot_state_charts_examples/` (exemplos do plugin).
- **Nenhuma referência quebrada**: procurei `res://` em todos os `.gd`, `.tscn`, `.tres`, `.json`,
  `.cfg` e `.py` do projeto: 0 apontando pra arquivo apagado.
- Os relatórios em `docs/` ficaram todos.

## 1. QA visual

Percorri o jogo com a vila cheia (todos os prédios, 12 ipezinhos com funções diferentes, 8
obras em estágios diferentes) e tirei 16 fotos (`tests/qa_prompt30.gd`): as 4 estações, noite,
onda solar, invasão nos 2 portões, obras, nível 2, abismo e o mapa de longe. Em cada foto o
roteiro conta os pares desenhados na ordem errada (a verdade 3D das caixas).

Fotos: `qa_antes/` e `qa_depois/` (mesmos nomes; `ordem.txt` com a contagem).

| Achado | Antes | Depois |
|---|---|---|
| **Ordem de desenho** | 0 erros em ~800 pares por foto (16 fotos) | 0 erros em ~760 pares por foto |
| **Chuva, neve, folhas e pólen** não apareciam na vista iso (as partículas caíam no chão antigo) | `qa_antes/06`, `07`: sem folha, sem neve | caem na tela, com a intensidade do clima; somem lá embaixo (nível 2, abismo); geada esfria o terreno no inverno (`qa_depois/06`, `07`) |
| **Rótulos se cobrindo no zoom longe** (texto pequeno, um em cima do outro) | `qa_antes/16` | no zoom longe os rótulos somem; voltam ao chegar perto (`qa_depois/16`) |
| **Pedra/decoração em cima de prédio** (a pegada dos prédios novos é maior que a dos antigos) | pedra com musgo na frente da porta do Centro, rocha encostada nas casas (`qa_antes/01`) | toda estrutura limpa a decoração da pegada dela + folga pra porta (`qa_depois/01`) |
| **Decoração da montagem aprovada faltando** (guindaste, vagonete, caixotes, barris, capim, flores) | o mapa no jogo bem mais vazio que a montagem do Prompt 27 | 34 peças novas integradas (`integra.py props`); a montagem posta no mapa + 90 tufos na floresta (sorteio próprio: as pedras e cristais dos saves não mudam) |
| Pixel borrado, âncora torta, texto cortado, emenda de tile | nada visto nas 16 fotos | — |

## 2. Consistência (brilho, paleta, contorno)

`tools/qa_arte.py` mede, em cada desenho que o jogo usa, o brilho e a saturação médios e o
**contorno** (os pixels da borda), por categoria. Resultado em `qa_arte_antes.json` /
`qa_arte_depois.json`.

| Categoria | Brilho médio | Contorno médio antes → depois |
|---|---|---|
| prédios | 0,19 | 0,040 → 0,035 |
| bonecos | 0,21 | 0,024 → 0,023 |
| objetos | 0,22 | 0,062 → 0,081 (entrou capim/flores, sem contorno de propósito) |
| terreno | 0,20 | 0,155 (o chão não leva contorno: regra do contrato) |

**Corrigido: contorno de 1 px** (regra do contrato: "Crisp 1px near-black outline") nos que
vieram sem: 4 peças e os 5 reatores da Escavadeira, o portão quebrado, a obra 1 do campo de
treino, a caminhada NE de 4 casacos (nos 3 tons de pele), as 2 bétulas, o toco de bétula e a
horta pronta. `tools/contorno.py` escurece só a borda clara (mantém o tom; rodar de novo não muda
nada) e o `integra.py` chama no fim, pra a correção não se perder. Antes/depois:
`contorno_antes_depois.png`.

**Destoam de propósito (mantidos):**

- **mais claros:** Enfermaria (paredes brancas, a cruz), Escudo solar nas etapas 1–2 (metal e
  cobre novos), traje de calor (prata refletivo), toco de bétula (casca branca), horta pronta
  (cogumelos claros), cristal ciano. É o desenho, não erro de brilho;
- **mais escuro:** a laje do abismo (o andar mais fundo);
- **sem contorno:** capim e flores (folhas de 1 px; com contorno viram mancha), como o chão.

## 3. Desempenho

1920×1080, vista iso, arte nova (`tests/desempenho_iso.gd`). Antes/depois em
`desempenho_antes.txt` / `desempenho_depois.txt`.

| Situação | Antes | Depois |
|---|---|---|
| vila de perto | 75 fps (pior 1%: 16 ms) | 74 fps (16 ms) |
| mapa quase inteiro (zoom longe) | 75 fps (16 ms) | 75 fps (13 ms) |
| zoom longe + 20 ipezinhos a mais | 70 fps (36 ms) | 73 fps (27 ms) |
| **mapa cheio: 40 ipezinhos, noite, invasão, zoom longe** | **39 fps (124 ms)** | **47 fps (38 ms)** |
| mapa cheio, zoom de jogo | 60 fps (34 ms) | 59 fps (34 ms) |

**O que travava:** cada tira de animação dos bonecos (58 MB, ~2.900 tiras) era carregada do disco
na 1ª vez que aparecia: ~6 ms cada, até 60 ms. Com a vila cheia, várias no mesmo quadro = picos
de 100+ ms. **Agora:** na 1ª vez que uma roupa (função × gênero, casaco, traje) aparece, todas as
tiras dela carregam em segundo plano (`iso_bonecos.gd`).

O script da vista gasta ~3 ms por quadro com o mapa cheio (ordem + espelhos); o resto é
desenho (GPU) e luzes. Atlas de texturas e menos luzes à noite ficam na lista do futuro.

## 5. Lista final do que ficou pro futuro

**Arte que falta (precisa de geração, depois da recarga de 30/10):**

| Prompt | O quê |
|---|---|
| 16–17 | Invasores (Lumívoro, Ferrugento), criaturas mais fortes e a criatura mestre: no jogo ainda com o desenho antigo |
| 18 | Efeitos: clima novo (hoje são as partículas antigas, agora visíveis na vista iso), poeira de obra, faíscas, fumaça, explosão, brilho da onda solar |
| 19 | Luz e noite |
| 20–22 | Interface (painéis, botões, cursores, menus), ícones (recursos, status, pesquisa, itens), fonte pixel |
| 23–24 | Retratos do elenco e das criaturas; ilustrações de evento |
| 25–26 | Tela "corte da mina", título, carregando, vitória, derrota |
| 2, 3, 14 | Pequenos que faltam: colher fruta, treinar no campo, placa de greve, arma trocada no ataque, cesto, chapéu do cozinheiro, cova, explosivos, antena do rádio |

**Conteúdo futuro (Prompt 31, precisa de gameplay novo):** crianças e escola; mais andares além
do nível 2 e do abismo.

**Técnico:**

- atlas das tiras dos bonecos (menos texturas trocadas por quadro) e menos luzes à noite no
  zoom longe;
- refazer a navegação ao construir leva ~75 ms: passar pra segundo plano;
- poço/coluna visível ligando a superfície às lajes de baixo;
- galeria "abrindo" e "aberta" (só a lacrada aparece hoje);
- espinheiro, galho e raízes (gerados, ainda não postos no mapa);
- a 2ª casa/nível de casa (desenhos prontos; o jogo não tem nível de casa).

## Mudanças por arquivo

| Arquivo | O quê |
|---|---|
| `scripts/iso/iso_sky.gd` | clima na tela (cópias das partículas do Weather, com a intensidade); geada no terreno |
| `scripts/iso/iso_view.gd`, `iso_billboard.gd` | rótulos somem no zoom longe |
| `scripts/iso/iso_bonecos.gd` | tiras carregando em segundo plano por roupa |
| `scripts/iso/iso_art.gd` | peça de decoração desenhada pelo nome |
| `scripts/core/environment.gd` | decoração da montagem aprovada + tufos na floresta; toda estrutura limpa a decoração da sua pegada |
| `prototipos/camera/arte_iso/integra.py` | +34 peças (`props`); chama o contorno no fim |
| `tools/qa_arte.py`, `tools/contorno.py` (novos) | medição de consistência; contorno de 1 px |
| `tests/qa_prompt30.gd` (novo) | o percurso de QA com fotos e contagem da ordem |
| `assets/game/iso/props/` (+34), arte com contorno (31 arquivos) | — |

## Testes

Tudo com a pasta de usuário isolada; o save de verdade conferido por md5 antes e depois (intacto).

| Bateria | Resultado |
|---|---|
| GUT completo depois da limpeza (antes das correções) | **44/44** |
| GUT completo com as correções do Prompt 30 | **44/44** |
| Percurso de QA (16 fotos) | 0 pares na ordem errada, antes e depois |

## Aviso: disco C quase cheio

No meio do trabalho o **C: chegou a 0 GB livres** ("No space left on device"). Apaguei só os
rascunhos desta sessão (~360 MB na pasta temporária do Claude) e passei a rodar tudo (pasta de
usuário dos testes, temporários, fotos) no D:. O C: continua com **~350 MB livres**: vale olhar
o que encheu (a pasta Temp tem ~7 GB, incluindo um `megatex_edit.bin` de 1 GB de 2025) antes
de abrir o editor do Godot de novo.
