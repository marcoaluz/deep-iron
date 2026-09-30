# Prompt 5: robô antigo

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/robo/`. Nada integrado ao
jogo.

## Decisão do Marco no meio do prompt: robô GIGANTE

O primeiro piloto saiu do tamanho de uma pessoa (84 px). O Marco pediu:

- **bem maior** que os NPCs, **quase da altura de uma casa**;
- **começa deitado, todo quebrado**, e as peças vão sendo colocadas nele.

Ficou assim:

| | Altura |
|---|---|
| Casa (com telhado) | 270 px |
| **Robô em pé** | **218 px** |
| Minerador (régua) | 74 px |

O robô de 84 px (`robo/candidatos/b_1.png`) serviu de referência de design pro gigante.

## O que ficou pronto

**Em pé (ativo): personagem de 4 direções**, como o elenco.

- 8 poses paradas (`robo/rotacoes/`); no jogo, SE e NE desenhadas, SO e NO por espelho.
- Animações, cada uma com `anim.json` (âncora por direção):

| Animação | Quadros | Como |
|---|---|---|
| andar | 4 | esqueleto `walking-4-frames` (SE) + `walking-8-frames` 1 quadro sim, 1 não (NE) |
| atacar | 8 | v3: soco pesado com o punho direito |
| dano | 6 | v3: tranco pra trás e volta à guarda |
| desligar / derrubado | 8 | v3: perde a força, cai de joelhos e apoia as mãos; **o último quadro fica parado** (derrubado até de manhã, `stunned` no `robo.gd`). Sem explosão. |

**Fluxo de jogo decidido pelo Marco** (exploração do pesquisador → 5 NPCs arrastam até o
portão → conserto em 3 estágios com itens → ronda de dia e entrada à noite; debuff no guarda):
`FLUXO_ROBO.md`, pra integração.

**Deitado: 5 estados parados**, no mesmo quadro (288×216) e com a **mesma âncora**. Trocam no
lugar, como a obra de um prédio. A sobreposição com o robô base é de 96–100%, sem pulo.

| Estado | No jogo (`robo.gd`) | Desenho |
|---|---|---|
| `achado` | achado na exploração | quebrado: antebraço arrancado com cabos, ombreira caída, peito aberto, entulho nas pernas |
| `arrastado` | 5 NPCs arrastam (corda por código) | igual, sem entulho, amarrado com cordas no peito, tornozelos e braço |
| `conserto_1` | parado perto do portão / estágio 1 | ainda desmontado; lona com peças e caixote ao lado |
| `conserto_2` | estágio 2 | braço e ombreira no chão, prontos pra voltar; placas novas, caixa de ferramentas, chaves, martelo, cabo |
| `conserto_3` | estágio 3 (último) | montado, remendos de cobre, cabos do peito até uma bateria |
| ativo | levanta | passa pra arte em pé |

**Retrato** (96×96, busto com o olho ciano), pro Prompt 23, e **ícone** de 32 px, tirado do
retrato por script (`itens/icones/robo.png`).

O olho ciano é a mesma cor da `EyeLight` do jogo (0.45, 1, 0.95). A luz em si continua no
código.

## Entregas (nesta pasta)

| Arquivo | O que é |
|---|---|
| `prancha_robo.png` | escala (casa × minerador × robô), 8 direções, retrato e ícone, 4 estados, animações |
| `robo_estados.gif` | achado → arrastado → estágios 1, 2, 3 → em pé |
| `FLUXO_ROBO.md` | o fluxo de jogo do robô e o que muda no código |
| `robo_animacoes.gif` | andar, atacar, dano e desligar (SE e NE) |

Gerado por `arte_iso/robo/prancha_robo.py docs/arte/prompt05`. As folhas de revisão quadro a
quadro ficam em `robo/<anim>_folha.png` (`folha_robo.py`).

## Custo

**~425 gerações**, um pouco acima do previsto por causa do tamanho e das refações:

| Item | Gerações |
|---|---|
| Piloto no tamanho humano (descartado pelo pedido do gigante) | ~66 |
| Base gigante (2 versões) + 8 direções | 45 |
| Animações (andar ×3 tentativas, atacar, dano, desligar, 2 refações de SE) | ~90 |
| Robô deitado + pé completado | 70 |
| 5 estados + 2 ombreiras completadas + 2 estados refeitos | ~225 |
| Retrato | 20 |

Um personagem desse tamanho custa **8 gerações por direção** em cada animação v3 (contra 2 do
elenco). Saldo do ciclo: **4.103**.

## Desvios e correções (reportando)

1. **Tamanho novo.** O gigante sai do padrão de personagem (caixa 28×28×70). Caixa em pé:
   pegada 52×52 e altura 166. Deitado: caixa 190×70×50. Está no `robo/contrato.json`.
2. **O jogo hoje manda um ipezinho CARREGAR o robô** até a Oficina (`carried` no `robo.gd`).
   Com esse tamanho isso não faz sentido. É integração (código), não arte. Opções:
   - consertar onde foi achado;
   - arrastar num trenó com vários ipezinhos.

   A escolha é sua. A arte funciona nos dois casos: o `achado` é o "no lugar", e o
   `conserto_1` já é o "na Oficina".
3. **Andar NE mais de perfil que a pose parada.** Testei 3 jeitos:
   - `walking-8-frames`: a SE girava de perfil no meio do passo;
   - `walking-4-frames`: a NE virava perfil pro leste;
   - NO espelhada: mostrava o lado da frente.

   Ficou a SE do de 4 quadros e a NE do de 8 (um quadro sim, outro não). A NE lê "de costas e
   de lado", sem rosto. Pra ficar perfeita, só com o modo pro (20–40 por direção).
4. **Ataque SE (1ª tentativa):** o punho saía solto do braço, com riscos cinza → refeito
   (+8). **Dano SE (1ª):** fundo bege em todos os quadros → refeito (+6). Nova opção
   `sem_fundo` no `trabalho.py`, mas **só serve quando há fundo**: numa animação limpa ela
   apaga partes do boneco.
5. **Estados cortados na borda:**
   - o robô deitado (pé) e 2 ombreiras soltas foram completados por inpaint, com o quadro
     ampliado;
   - os estados 1 e 3 saíram deslocados ou cortados e foram refeitos no mesmo quadro dos
     outros.
6. **Achado com entulho:** o entulho é cinza-marrom genérico. Se o robô aparecer em nível de
   rocha diferente (ardósia, basalto), dá pra recolorir o entulho por script.
