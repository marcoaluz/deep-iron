# Prompt 3: equipamento vestível (trajes de perigo e casaco)

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/traje_*/`,
`casaco_minerador/` e `itens/icones/`. Nada integrado ao jogo.

## O que o jogo tem (conferido em `equipment.gd`, Bloco 42)

| Peça | Nome no jogo | Onde é usada |
|---|---|---|
| Casaco | Casaco de inverno | ao ar livre no inverno, nível da mina e da clareira; feito de **couro** (recurso da caça) + madeira |
| Traje gás | Máscara de gás | zona "Bolsão de gás" |
| Traje calor | Traje térmico | zona "Fenda de calor" |
| Traje radiação | Traje antirradiação | zona "Veio radioativo" |

"Couro" é recurso, não roupa. A única peça de couro é o próprio casaco.

## Trajes de perigo: prontos

**1 personagem por traje, homem e mulher** (6 no total), como pede o prompt. Cada traje é uma
"variante" do minerador ou da mineradora, porque é quem entra nas zonas. Assim mantém corpo,
altura e o corte de altura da mineradora.

| Traje | Visual (cor bem distinta, lê de longe) |
|---|---|
| Gás | macacão **amarelo-mostarda**, máscara preta com filtro redondo, capacete com lanterna por cima |
| Calor | **prateado aluminizado** com capuz e visor escuro, chamuscado |
| Radiação | **verde-oliva** com visor redondo de vidro e selo amarelo no peito |

Cada traje tem:

- **parado** nas 8 direções;
- **andar** nas 4 (esqueleto);
- **minerar** nas 4 (v3, picareta embutida no golpe);
- **carregar** (caminhada + o saco em sobreposição do Prompt 2).

Entregas:

- `trajes_8_direcoes.png`;
- `trajes_caminhada.gif`, `trajes_minerar.gif`, `trajes_carregar.gif`.

## Casaco de inverno: DECISÃO DO MARCO (o prompt pede comparar antes de gerar em massa)

Piloto feito: o **minerador com casaco** (`casaco_minerador/`, 8 direções). Casaco de couro
surrado com gola e punhos de pele e cachecol; **o capacete com lanterna continua**, então a
função segue reconhecível.

| Opção | Como fica | Custo |
|---|---|---|
| **A. Por função** (como o piloto) | cada função com o próprio casaco; chapéu, capacete e touca continuam | ~30 variante + ~3 andar + ~4 trabalho = **~37 por personagem**, ~630 pros 17 que faltam |
| B. Corpo base (homem/mulher) | no inverno todo mundo vira o mesmo "civil de casaco"; **perde a identidade da função** (sem capacete, sem chapéu) | ~74 |
| C. Sobreposição (gola de pele + cachecol por cima de cada corpo) | fica pequeno e briga com capa e avental nos quadros de trabalho; lê fraco | ~20 |

- **Recomendo A, depois do upgrade.** É a única que mantém a função legível no inverno.
- **Até lá:** o frio pode aparecer por código (tom azulado + o ícone de "sem casaco" que o
  HUD já tem).
- Comer, mancar e ferido **de casaco** não entram na conta A. No inverno, essas animações
  aparecem sem casaco, ou seria +16 por personagem.

## Desgaste

Novo, gasto e quase rasgado em arte triplicaria o custo de cada peça. Com o saldo atual,
**o desgaste fica só por ícone na UI** (a barra/estado que o vestiário já tem), como o prompt
permite.

## Ícones de inventário e vestiário

Recortados da própria arte, **sem gerar de novo**, em 32×32 (cabeça e tronco):

- `itens/icones/traje_gas.png`, `traje_calor.png`, `traje_radiacao.png`, `casaco.png`;
- prancha: `icones_vestiario.png`.

## Custo

**~250 gerações** (saldo ~414 → **162**):

| Item | Gerações |
|---|---|
| 6 variantes de traje + 1 de casaco (~28 cada) | ~196 |
| Andar dos 6 trajes | ~18 |
| Minerar dos 6 trajes | 24 |
| Refações do Prompt 2 feitas aqui | ~12 |

**As variantes custaram quase o dobro do que eu estimei (~28, não ~16).** A primeira leitura
do saldo saiu antes da cobrança completa.

## Desvios

1. **Casaco:** só o piloto, por falta de crédito (ver tabela). A escolha é sua.
2. **3 peles nos trajes:** não se aplica ao traje de gás (a máscara cobre o rosto). Nos de
   calor e radiação o rosto aparece pouco atrás do visor. A troca de paleta funciona, mas
   quase não se vê.
3. **Nomes e cores:** o jogo pinta as zonas de verde (gás), laranja (calor) e verde-limão
   (radiação). Os trajes seguem as cores do prompt (amarelo, prata, oliva), que se distinguem
   bem das zonas e entre si.

## Atualização: casaco por função COMPLETO (18 personagens)

O Marco aprovou a **opção A (casaco por função)**. Terminado depois do upgrade.

- **Os 18** têm o casaco (8 direções), o **andar** e o **trabalho da função** de casaco. O
  civil e a civil mulher não têm trabalho.
- Todos mantêm o que identifica a função: capacete com lanterna, capacete laranja, capacete
  de aço, gorro de médico, chapéu de cozinheiro, chapéu de caçador, óculos do pesquisador,
  boné, lenço.
- As mulheres têm o mesmo corte de altura das versões sem casaco (`encolhe.CORTE`).

Entregas (nesta pasta, geradas por `python casacos.py entrega docs/arte/prompt03`):

- `casaco_por_funcao.png`: os 18, sem casaco × com casaco;
- `casaco_animacoes.gif` (+ `_q0.png`): andar em cima e trabalho embaixo, todos de casaco.

Arte em `arte_iso/casaco_*/`; IDs e o que foi refeito em `arte_iso/casaco_ids.json`.

**Custo do casaco inteiro:** ~600 gerações (17 variantes de ~28 + andares + trabalhos + 8
refações).

**Correções feitas nesta leva (reportando):**

1. **Caçador e cozinheira:** a direção de trás virava o rosto → refeita pela NO e
   espelhada (opção `atras=` do `trabalho.py`).
2. **Lenhadora (SE):** veio com um retângulo de fundo marrom e arcos brancos → refeita só a
   SE (opção `de=SE:<anim>`).
3. **Cozinheiro (NE, quadro 6)** com a cor estourada e **cozinheira (SE, quadro 0)** com a
   tigela solta → quadro trocado pelo vizinho (opção `troca=`).
4. **Caçadora:** ponta da flecha em laranja vivo, parecendo fogo → escurecida (opção
   `sem_brilho`).
5. **Restos pequenos aceitos:** 2–3 pixels amarelos soltos no instrumento do pesquisador
   (NE, 1 quadro) e um risco cinza curto no casaco do caçador (NO, 2 quadros). Somem na
   escala do jogo.
