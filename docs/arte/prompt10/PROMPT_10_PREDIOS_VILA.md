# Prompt 10: prédios da vila e moradia

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/{centro,armazem,oficina,casa}/`,
entregas por `arte_iso/predios10.py`. Nada integrado ao jogo.

## O que ficou pronto

| Prédio | Estágios | Caixa declarada (pegada × altura, px) |
|---|---|---|
| **Centro da Vila**, os 5 estágios do jogo (`STAGE_NAMES`) | 1 Acampamento (barraca, fogueira, sino no poste) → **obra** → 2 Vilarejo (salão de toras) → **obra** → 3 Vila (salão enxaimel com varanda e sineira) → **obra** → 4 Vila Mineira (pedra + madeira, torre do sino, emblema de picaretas) → **obra** → 5 Cidade Mineira (prefeitura de pedra com torre do relógio) | 106×112×132 → 126×122×174 → 132×122×202 → 170×146×248 → 180×174×308 |
| **Armazém** | obra 1 (fundação, material em volta) → obra 2 (esqueleto de madeira) → obra 3 (paredes e telhado pela metade) → pronto (galpão com guincho e plataforma de carga) | 156×138×192 |
| **Armazém: lotação** | vazio / médio / cheio, com as pilhas de minério e madeira dos Prompts 8–9 na frente (sobreposição, custo 0) | — |
| **Oficina (forja)** | obra 1 → obra 2 → obra 3 → pronto (pedra embaixo, madeira em cima, chaminé de pedra, bigorna, barril de têmpera, rebolo). A forja fica apagada; o brilho é luz no código. | 132×112×204 |
| **Casa nível 2 e 3** | upgrade por cima da casa aprovada, mesma planta e porta: nível 2 ganha andar de madeira, janela e toldo; nível 3 térreo de pedra, varanda, lampião, barril | mesma pegada da casa |

- Todos os desenhos cabem na caixa declarada com **no máximo 4 px fora** (`predio.py caixa`;
  valores em `<prédio>/contrato.json`).
- **A obra entre os estágios do Centro** é o estágio seguinte em construção: andaime, telhado
  sem telha, pedra e tábua empilhadas. O jogo troca pelo progresso do engenheiro (regra do
  contrato).

## Entregas (nesta pasta)

| Arquivo | O que é |
|---|---|
| `prancha_centro.png` + `obra_centro.gif` | os 5 estágios com as 4 obras entre eles (a 50%; o GIF em tamanho real) |
| `centro_5_estagios.png` | os 5 prontos em tamanho real, com o minerador |
| `prancha_armazem.png` + `obra_armazem.gif` | obra 1–3 → pronto |
| `armazem_lotacao.png` | vazio, médio, cheio |
| `prancha_oficina.png` + `obra_oficina.gif` | obra 1–3 → pronto |
| `prancha_casa_niveis.png` + `obra_casa_niveis.gif` | nível 1 (aprovada) → 2 → 3 |

## Teste de ordenação

A ordenação por caixas passou com **0 erros** na cena de estresse (Prompt 6), e a condição
pra isso continuar valendo é o desenho caber na caixa (≤ 4 px fora). Todos os estágios deste
prompt passam nessa regra. **Não** coloquei estes desenhos dentro da cena de estresse: isso
pede o motor isométrico carregando arte (Prompt 28).

## Custo

**~500 gerações** (os prédios grandes saem a 25–40 cada, 1 candidato por chamada):

| Item | Gerações |
|---|---|
| Centro: 5 estágios + 4 obras | ~280 |
| Armazém: pronto + 3 obras | 100 |
| Oficina: pronto + 3 obras | 100 |
| Casa nível 2 e 3 | 80 |

`predio.py caixa` ficou **30× mais rápido** (busca binária da altura): 38 s por prédio em vez
de ~19 min.

## Desvios

1. **Centro: tamanho.** Os estágios 4 e 5 ficaram com 371 e 428 px de altura. Cabem no limite
   de 512 com fator ~1,7 (a decisão que o contrato deixou pra este prompt). Não precisou
   montar com 2 caixas.
2. **Âncora das obras.** As obras do Armazém e da Oficina saíram com a planta um pouco
   deslocada (a fundação é mais larga que o prédio pronto, com material em volta). Alinhei pelo
   pé só onde o encaixe era confiável (obra 3). Obra 1 e obra 2 ficam como a IA desenhou.
   Na troca de desenho no jogo, dá uma "respirada" de até ~8 px.
3. **Lotação do Armazém** por sobreposição, não por desenho próprio: as pilhas são as mesmas
   dos Prompts 8–9 e acompanham o minério certo.
4. **Variações de acabamento:** a casa já tem 4 (v0–v3). Os outros prédios deste prompt são
   únicos no mapa (Centro, Armazém, Oficina), então ficaram com uma versão cada.
5. **Oficina:** o jogo hoje a traz pronta. A obra existe pro caso de ela virar construível.
