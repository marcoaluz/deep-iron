# Robô antigo: fluxo de jogo decidido pelo Marco (2026-09-30)

Documento pra integração (Prompts 28–29). **Nada disso está no código ainda.** O `robo.gd` e o
`finds.gd` de hoje seguem outro fluxo (ver "O que muda no código").

## O fluxo

1. **Achado.** O **pesquisador** passa a fazer **exploração fora da vila**. Numa exploração
   ele acha o robô, caído e quebrado.
   - Arte: `robo/estados/achado.png` (no chão, com entulho).
2. **Arrastar.** Aparece a opção de trazer o robô. O jogo pede **5 NPCs** (quaisquer
   funções). O jogador manda os 5, e eles **arrastam o robô até o portão** e, do portão, pra
   dentro da vila.
   - Arte do robô: `robo/estados/arrastado.png`, deitado, sem entulho, com o braço e a
     ombreira soltos amarrados em cima.
   - Arte dos 5: **a caminhada normal, mais devagar**, com a corda da mão até o robô
     desenhada **por código** (Line2D). Custo 0.
   - Opcional: animação de "puxar corda" de verdade pros 18 (esqueleto `pull-heavy-object`,
     ~90 gerações).
3. **Parado dentro da vila.** Os 5 deixam o robô **deitado num lugar perto do portão**, e ele
   fica ali.
   - Arte: `robo/estados/conserto_1.png`.
4. **Conserto em 3 estágios.** Cada estágio pede **itens**. O jogador coleta e coloca no
   robô, e quando o estágio fica completo o desenho troca:

   | Estágio | Arte ao começar | Arte quando termina |
   |---|---|---|
   | 1 | `conserto_1` (desmontado, peças na lona) | `conserto_2` |
   | 2 | `conserto_2` (braço e ombreira no chão, ferramentas) | `conserto_3` |
   | 3 (último) | `conserto_3` (montado, cabos na bateria) | **levanta** → ativo |

   Os 4 desenhos usam o mesmo quadro (288×216) e **a mesma âncora** (`robo/contrato.json`):
   trocam no lugar, sem pulo.
5. **Ativo.**
   - **De dia:** anda pela vila fazendo **ronda** (segurança). Arte: `robo/caminhada/`.
   - **À noite:** fica **parado em pé na entrada**. Arte: a pose parada (`robo/rotacoes/`).
   - Combate: `atacar/`, `dano/`, e `desligar/` quando cai (o último quadro fica parado até
     de manhã).

## Regras de jogo novas

- **Só uma entrada na vila.** O robô guarda essa entrada à noite.
- **Com o robô ativo, não precisa de guarda.** Pode ter guarda pra ajudar, mas **o guarda
  ganha um debuff** (ex.: menos ânimo ou menos eficiência, "o robô faz o meu trabalho"). O
  valor fica pra integração.

## O que muda no código (para a integração)

| Hoje (`robo.gd` / `finds.gd` / `defense.gd`) | Novo |
|---|---|
| O robô é um "achado" raro do **fundo da mina** (`finds.gd`, `robot_chance`) | Achado na **exploração do pesquisador**, fora da vila (sistema de exploração novo) |
| **1 ipezinho carrega** o robô (`carried`), inclusive pelo elevador | **5 NPCs arrastam** até o portão; o robô desliza deitado e a corda é desenhada por código |
| Fica ao lado da **Oficina** (`drop_point`) | Fica **perto do portão**, dentro da vila |
| Conserto = **peças raras + créditos + ferro + tempo**, um bloco só (`repair_*`) | **3 estágios, cada um com itens**, e o desenho troca por estágio |
| De dia fica de guarda no Centro da Vila, à noite patrulha as casas | **De dia ronda pela vila, à noite parado na entrada** |
| **2 portões** (túnel e poço, `defense.gd`) | **1 entrada** |
| O guarda não interage com o robô | **Debuff no guarda** com o robô ativo |

## Arte que existe pra cada momento

| Momento | Arquivo |
|---|---|
| Achado na exploração | `robo/estados/achado.png` |
| Sendo arrastado | `robo/estados/arrastado.png` |
| Parado esperando conserto / estágio 1 | `robo/estados/conserto_1.png` |
| Estágio 2 | `robo/estados/conserto_2.png` |
| Estágio 3 | `robo/estados/conserto_3.png` |
| Ronda | `robo/caminhada/` (4 direções) |
| Guarda na entrada à noite | `robo/rotacoes/` (parado) |
| Combate | `robo/atacar/`, `robo/dano/`, `robo/desligar/` |
| Retrato / ícone | `robo/retrato.png`, `itens/icones/robo.png` |

**Falta, se quiser:** "levantar" (o robô se erguendo de deitado para em pé, quando o
conserto termina). Hoje a troca seria direta. Uma animação de levantar nesse tamanho custa
~16 (v3, 2 direções). Dá pra fazer junto com a integração.
