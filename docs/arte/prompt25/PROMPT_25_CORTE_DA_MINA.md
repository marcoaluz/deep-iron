# Prompt 25: tela "Corte da mina" (vista lateral)

Data: 2026-10-02. Branch `isometrico`. Geração: **6** (pixen: 4 faixas de rocha, a escavadeira e a
gaiola de lado). Checkpoint do layout dispensado.

## Como testar

Aperte **F2** (todas as letras já são atalho) ou o botão **"Corte da mina (F2)"** no fim da coluna de
construções. Abre a mina vista de lado, como um formigueiro:

- **4 andares empilhados**: superfície (clareira), mina e vila (pedreira, poeira), nível 2 (gás e
  radiação), abismo (calor). Cada um diz quantos ipezinhos tem;
- **quem está onde**: um mini-boneco da função de cada ipezinho, no tom de pele dele, na altura do
  andar e na posição de lado; escurecido = dentro de um prédio; machucado com o curativo em cima;
  o selecionado com contorno;
- **ligações**: a escada do túnel (clareira → pedreira) e os poços do elevador e do abismo, com a
  gaiola subindo e descendo;
- a **escavadeira**, o **robô** e os **invasores** (na forma forte quando for o caso);
- as **zonas de perigo** (gás, calor, radiação) com o efeito delas;
- **clicar num ipezinho** seleciona e leva a câmera até ele; **clicar no andar** leva a câmera pra
  lá; F2/Esc/X fecha.

`corte_mina_save_real.png`: a tela com os dados do **save real do Marco** (copiado pra pasta de
teste e só lido; o original ficou com o mesmo md5). `faixas_corte.png`: a arte das faixas.

## 1. O layout (o que foi decidido)

| Pergunta | Decisão |
|---|---|
| O que mostra | os 4 andares do mapa (o mapa já empilha no eixo Y: pedreira, nível 2 a partir de y≈700, abismo a partir de y≈1420), gente, máquinas, perigos e ligações |
| O que é clicável | ipezinho (seleciona e vai até ele) e andar (leva a câmera) |
| Minimapa | não: a própria tela já é o mapa inteiro de lado |
| Atualiza | ao vivo enquanto aberta (os ipezinhos andam) |

## 2. A arte

Faixas de 512×128 (desenhadas em 2x na tela) geradas no pixen, escavadeira e gaiola de lado; os
mini-bonecos são o boneco parado de frente de cada pasta, reduzido à metade (sem gerar).

## Limites

1. A posição da gaiola é animada (vai e volta): a lógica do elevador não guarda onde ela está.
2. A faixa do abismo veio com um canto escuro em cima à esquerda (ficou como rocha).

## Arquivos

`scripts/ui/corte_mina.gd` (novo), `scripts/core/hud.gd` (botão), `prototipos/camera/arte_iso/corte/`
(arte + `exporta.py`), `assets/game/ui/corte/`.
