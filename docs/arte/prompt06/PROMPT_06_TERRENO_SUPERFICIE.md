# Prompt 6: terreno da superfície

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/relevo/final/superficie/`,
montador em `relevo/superficie.py`. Nada integrado ao jogo.

## O que já existia (checkpoint de relevo, aprovado) e o que este prompt completou

| Peça | Antes | Agora |
|---|---|---|
| Terra batida (colônia), grama (clareira) | ✅ | — |
| Blocos de platô (degrau de 32), borda de buraco, transição por vértice | ✅ | — |
| Escada de madeira | ✅ | — |
| **Grama alta/seca** | — | ✅ 5 variações |
| **Trilha de terra batida** | — | ✅ 5 |
| **Cascalho** | — | ✅ 4 |
| **Lama** | — | ✅ 1 (+ espelho) |
| **Laje de pedra** (praça) | — | ✅ 4 |
| **Chão de canteiro/obra** | — | ✅ 2 (+ espelho) |
| **Escada de pedra** | — | ✅ (+ espelho pro outro lado) |
| **Rampa** (sem degraus) | — | ✅ (+ espelho) |
| **Boca de mina no paredão** (vigas de madeira) | — | ✅ paredão de 3 degraus, 2×1 tiles, abertura da altura de um minerador |

**Fora deste prompt, conferido no código:**

- **Água:** o jogo não tem.
- **Estações no chão:** o jogo usa estação só no clima e no casaco (contrato §3). Nada a
  gerar.

A **imagem de referência do Marco** (o corte com a vila no alto e os níveis descendo) guiou
o conteúdo da superfície: vila no platô, laje, trilha, paredão com a boca de mina de vigas,
escada de pedra descendo. O mapa do jogo continua isométrico. O corte lateral dessa imagem é
a tela do Prompt 25.

## Entregas (nesta pasta)

| Arquivo | O que é |
|---|---|
| `prancha_superficie.png` | cada piso ladrilhado 5×5 (variação e espelho sorteados como no jogo), escada de pedra, rampa, boca de mina |
| `minimapa_superficie.png` (+ `_x2`) | cena de teste montada: platô da vila com casa e praça de laje, paredão com a boca de mina, escada de pedra de 3 lances, cascalho de rejeito na frente da mina, lama, canteiro, platô baixo com rampa, grama alta nas bordas, 7 personagens |

## Teste na cena de estresse (`rota_a_estresse.tscn`, headless, APPDATA isolado)

A cena de estresse usa a **mesma geometria** do tileset (degrau 32, rampa de 1 degrau,
platôs, galeria rebaixada, abismo), com 14 ipezinhos andando.

| Teste | Resultado |
|---|---|
| Ordenação, modo de produção (caixas incremental) | **0 erros** em 1.200 quadros, 5,1 ms/quadro |
| Clique pelo raio da câmera | **100%** em chão, topo de platô, face de penhasco, beira de buraco, fundo de galeria e abismo, rampa/escada, prédios |
| Save real | md5 igual antes e depois (`savegame.json: OK`) |

Ver o tileset **desenhado** dentro dessa cena (e não em caixas) é o motor isométrico no jogo:
Prompt 27 (montagem do mapa) e 28 (integração).

## Custo

**~215 gerações** (saldo 4.103 → **3.863**, com os 25 do robô arrastado):

| Item | Gerações |
|---|---|
| 6 pisos (16 candidatos cada) | 120 |
| Escada de pedra + rampa | 40 |
| Boca de mina (3 tentativas, 4 candidatos cada) | 75 |

## Desvios e decisões (reportando)

1. **Brilho.** Trilha, canteiro e grama alta vieram 2× mais claros que a terra. Foram
   escurecidos por script (`superficie.py`, alvo em valor HSV): terra 0,24 · clareira e
   grama alta 0,34 · trilha, laje e canteiro ~0,30 · cascalho 0,28 · lama 0,19.
2. **Emenda (grade) nos pisos lisos.** A IA escurece a borda do losango. Em piso liso, a
   correção antiga (`equaliza_borda`) volta pra mesma cor, porque a paleta tem poucas cores.
   Pra trilha, lama e canteiro, a faixa da borda é refeita com textura do miolo
   (`recheia_borda`), e a grade sumiu.
3. **Menos de 3 variações na lama (1) e no canteiro (2).** As outras variações tinham
   pegadas, poças ou listras que formavam xadrez. Com o espelho sorteado, o efeito é de 2 e 4
   variações. Se quiser mais, dá pra gerar uma leva mais lisa (20).
4. **Boca de mina: 3 tentativas.**
   - 1ª: saiu um barraco de tábuas;
   - 2ª: paredão certo, mas encolhido;
   - 3ª: com o minerador como régua, acertou.

   O topo dela é coberto pelo chão do próprio platô na montagem. Uma só orientação (abertura
   na face esquerda, a iluminada). Bloco não espelha, porque troca a luz. A outra face custa
   +25 se precisar.
5. **Links de referência expiram** (~1 dia). O bloco e a casa aprovados foram copiados pra
   bancada, com link permanente, e anotados no contrato.
