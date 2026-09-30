# Arte isométrica: elenco completo (18 personagens)

Data: 2026-09-29. Nada foi integrado ao jogo. A arte está em
`project.godot/prototipos/camera/arte_iso/<personagem>/`, e o rastreio de ids está em
`arte_iso/elenco.json`.

## O que ficou pronto

Homem e mulher de cada função: minerador, guarda, médico, engenheiro, caçador, pesquisador,
lenhador, sem função e cozinheiro. Cada personagem tem:

- `rotacoes/`: 8 poses paradas;
- `caminhada/{SE,NE,SO,NO}`: 4 quadros; SO e NO são espelho;
- `contrato.json`: âncora por direção e caixa;
- `tons_de_pele.png`: original, clara, parda e negra;
- `prancha_8_direcoes_iso.png`;
- `caminhada_4dir.gif`.

Imagens deste relatório:

- `fila_elenco_S.png` / `fila_elenco_SE.png`: os 18 lado a lado, em pares homem/mulher;
- `caminhadas_homens.png` / `caminhadas_mulheres.png`: os 4 quadros SE + 4 NE de cada um,
  recortados na âncora;
- `tons_de_pele_amostra.png`: 12 personagens nos 4 tons;
- `fila_corpos.png`: a checagem de físico.

## Custo

| Etapa | Gerações |
|---|---|
| 15 desenhos-base (`create_image_pro`, 16 candidatos cada) | 375 |
| Caçadora: 2º lote (o 1º saiu com rosto masculino) | 25 |
| 15 rotações de 8 direções (v3) | 15 |
| Caminhadas SE+NE (skeleton-v3), com 3 refeitas | ~19 |
| Caçadora sem arco (3º lote + rotação + caminhada) | 27 |
| **Total do elenco (fora engenheiro + médica, já contados)** | **461** (saldo 1.427 → **966**) |

Guias 2:1 e todo o pós-processamento (espelho, âncora, caixa, tons): 0.

## Variedade de físico (pedido do Marco)

| Pedido | Resultado |
|---|---|
| Lenhador forte | ✅ ombros largos, braço grosso |
| Sem função homem magro | ✅ |
| Cozinheiro meio gordinho | ✅ barriga visível de frente e de lado |
| Sem função mulher um pouco cheinha | ✅ |
| Lenhadora forte, curva leve | ✅ forte; ⚠️ a curva quase não aparece |
| Cozinheira, curva leve | ⚠️ o avental cobre o corpo; de SE aparece um pouco |
| Mulheres com pouco busto, sem exagero, não em todas | ✅ discreto: ~75 px de altura dá pouco espaço pra isso |

A diferença de gênero se lê principalmente pelo rosto, pelo cabelo (coque, trança, rabo) e
pela silhueta (saia, cintura).

## Caixas (regra 2)

Agora são duas caixas por personagem:

- **estrita:** até 4 px de fora. Cresce muito quando a ferramenta sai do corpo: a ponta do
  machado deixa o lenhador com 54 de largura.
- **de corpo:** até 0,5% dos pixels de fora (`arte_iso/caixa_corpo.py`). O que fica de fora é
  ponta fina de ferramenta.

**Recomendo usar a de corpo na ordenação.**

| | Homem (corpo) | Mulher (corpo) |
|---|---|---|
| Minerador | 28×28×70 | 34×34×78 |
| Guarda | 32×32×74 | 34×34×78 |
| Médico | 34×34×80 | 32×32×74 |
| Engenheiro | 34×34×78 | 34×34×78 |
| Caçador | **48×48×74** | 34×34×74 |
| Pesquisador | 30×30×74 | 28×28×76 |
| Lenhador | 36×36×76 | 32×32×76 |
| Sem função | 32×32×82 | 36×36×74 |
| Cozinheiro | 30×30×78 | 32×32×80 |

- Na caminhada, o corpo varia de 0,4 a 1,8 px entre quadros em todos: nenhum salta.
- O minerador (o 1º, de referência) é o mais baixo (70). Os outros vão de 74 a 82. Isso lê
  como variação natural de altura. Se preferir todos iguais, dá pra escalar na integração.

## Desvios e problemas (regra: reportar, não contornar sozinho)

1. **O caçador não tem arco na mão.** Eu tinha anotado que o candidato #7 tinha arco. Olhando
   de perto, ele segura um **rolo de corda** e leva uma **aljava com flechas** nas costas
   (ver `cacador_candidatos.png`). Quase todos os outros candidatos vieram com espingarda ou
   besta.
   - No jogo, o arco já é uma ferramenta à parte: sem arco, o caçador colhe frutas (Bloco 34).
     Então o arco entra por sobreposição, como a picareta do minerador, e o rolo de
     corda/armadilha combina com o caçador sem arco.
   - Continua sendo o personagem mais largo (48, por causa da capa).
   - A caminhada NE foi refeita 1× porque o rolo espetava pra frente.
   - **Marco confirmou:** o arco só aparece quando a Oficina libera "caça de animais"
     (`oficina.gd`, ferramenta `arco`). Sem ele, o caçador fica sem arco. O corpo base está
     certo, e o "com arco" entra por sobreposição quando a ferramenta existir.
   - **Caçadora refeita (decisão do Marco, +27):** a do 2º lote levava nas costas uma vara
     curva (lia como arco), com aljava e faca na mão. O 3º lote saiu **sem arco, sem aljava e
     com um cesto de frutas** (#8), o que combina com a coleta antes da Oficina.
     - A anterior ficou em `cacadora/com_arco_ref/` como referência do visual "com arco".
     - O caçador ficou como está: a aljava dele é pequena e só aparece de costas.
2. **Caçadora:** o 1º lote saiu com rosto masculino. Gerei um 2º lote (+25) com trança e
   traços femininos. O 1º lote está guardado em `cacadora/lote1` (serve de variação de
   caçador).
3. **Pesquisadora, caminhada NE:** a pose NE da rotação saiu quase de costas (igual à N). As 2
   tentativas de caminhada NE viravam o rosto pra câmera no meio do passo.
   - Solução: animei a **NW** e o NE sai por espelho, com o mesmo contrato de 2 desenhos +
     espelho, só trocando o lado de origem.
   - `personagem.py` e `links.py` aceitam isso (`NO:<id>`).
   - As 2 tentativas estão guardadas em `caminhada_lote1/` e `caminhada_lote2/`.
4. **Cozinheira:** nos 16 candidatos o rosto saiu ambíguo. Escolhi o de rosto mais suave
   (#6). A rotação de 8 direções saiu mais feminina que o candidato.
5. **Troca de tom de pele: corrigida e com um limite.**
   - Com o elenco inteiro apareceu um vazamento: colete, capa, xadrez e calça marrom têm
     **exatamente o mesmo RGB** da pele e trocavam de cor junto.
   - Agora uma cor só conta como pele no corpo se aparecer mais no rosto do que no resto.
     Na faixa da cabeça, vale a regra solta.
   - O claro/escuro passou a seguir a luminosidade absoluta.
   - **Limite:** no caçador a troca é fraca (rosto pequeno sob a barba). Na integração,
     o mais seguro é uma **máscara de pele por quadro** gerada offline, em vez de só uma
     tabela de cores.

## Próximo (pela ordem do brief)

Tiles de relevo: primeiro um conjunto pequeno (1 platô com as transições) e **parada pra
aprovação**. Depois os prédios restantes com a sequência de obra, e por fim os objetos.

Saldo: **966** gerações (renova em 2026-10-29).
