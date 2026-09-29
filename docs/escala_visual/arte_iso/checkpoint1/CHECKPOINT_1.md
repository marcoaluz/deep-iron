# Arte isométrica — CHECKPOINT 1: minerador em 4 direções de losango

Data: 2026-09-29. **Parado aqui esperando a aprovação do Marco.** Não gerei a casa nem mais
nenhum personagem. Nada foi integrado ao jogo. A arte está em
`project.godot/prototipos/camera/arte_iso/minerador/`; as imagens pra revisar estão nesta pasta.

## Custo

| Etapa | Ferramenta | Gerações |
|---|---|---|
| Base de frente (16 candidatos, escolhido o 9) | `create_image_pro` 48×84, com o minerador v2b como referência e estilo | 25 |
| 8 direções paradas | `create_character` v3 a partir do candidato 9, câmera "high top-down" | 1 |
| Caminhada SE e NE (4 quadros cada) | `animate_character` skeleton-v3 `walking-4-frames` | 1 |
| **Total** | | **27** (saldo 1.683 → **1.656**) |

SO e NO **não foram gerados**: são o espelho de SE e NE, como manda o contrato.

## O contrato de 7 regras

| Regra | Resultado |
|---|---|
| **1. Ângulo 2:1 exato** | ⚠️ **Desvio — não dá pra garantir com o PixelLab (ver abaixo)** |
| 2. Cabe na caixa declarada | ✅ Caixa **28 × 28 × 70** (chão, 1 px de arte = 1 unidade). **0 pixels fora** nas 4 direções, **com a picareta** |
| 3. Âncora anotada | ✅ Fixa **por direção**, nos pés: SE (57,7; 100), NE (58,3; 97) no quadro de 112×112; SO e NO espelhados. O corpo não escorrega: varia no máximo 1,3 px entre quadros |
| 4. 4 diagonais, 2 desenhos + espelho | ✅ SE e NE desenhados; SO e NO espelho. As 8 poses paradas vieram juntas por 1 geração |
| 5. Picareta: sprite + 2 configurações | ✅ Atrás do corpo em SE/SO, na frente em NE/NO (`picareta_4dir.gif`). ⚠️ O sprite da picareta é o da Fase 1 |
| 6. Relevo | — não se aplica ao personagem |
| 7. Luz e peças anotadas | ✅ Lanterna do capacete: SE a (+8; −76) da âncora, SO espelhado. De costas ela não aparece; a luz vai na frente do capacete (`contrato_minerador.json`) |

**Verificador de ordem (cena de estresse, 14 mineradores novos com a caixa real, 60 s):**
- ordem incremental: **0 erros em 33.530 sobreposições**;
- ordem ingênua: 1,33% de erros (é pra isso que a ordem por caixas existe).

Veja `estresse_com_minerador.gif`: quem passa atrás de prédio some atrás dele, sem nenhuma
configuração a mais.

## Desvios e achados (pra decidir, não contornei sozinho)

1. **Regra 1, o ângulo.**
   - O PixelLab não tem câmera de 30° (o 2:1). As câmeras fixas são 20° ("low top-down"),
     35° ("high top-down") e 0°.
   - O `create_image_pro` não tem parâmetro de ângulo. Pedi "câmera 30° acima" no texto e ele
     **ignorou**: os 16 candidatos saíram quase na altura dos olhos, só com um pouco do topo
     do capacete.
   - A rotação v3 com "high top-down" (35°) deu um pouco mais de vista de cima (cabeça e topo
     do capacete maiores). Nas diagonais, o boneco olha na direção certa do losango
     (`prancha_8_direcoes_iso.png`, linha verde).
   - **O resultado é o isométrico de pixel art "normal", não o 30° matemático.** Ordem e
     clique não são afetados (dependem só da caixa). O efeito é visual: os pés aparecem um
     pouco de lado, e não "de cima" como o chão.
   - Opções:
     - **(a)** aceitar como está;
     - **(b)** testar a câmera "oblique" do PixelLab (beta). Ela é só de modo standard, que
       **não aceita referência de estilo**, então perde o estilo do v2b. Custa 1 geração de
       teste.
   - Minha recomendação: **(a)**.

2. **Espelho × direções geradas.**
   - O sudoeste que o PixelLab gerou **não** é o espelho do sudeste (30% da silhueta muda).
   - Com espelho, a alça e a lanterna trocam de lado quando ele vira pra esquerda. É o custo
     combinado das 4 direções.
   - Consequência prática: **a pose parada também tem que ser espelho**. Se usar o SO gerado
     parado e o SE espelhado andando, a alça "pula" de ombro quando ele começa a andar.

3. **A picareta** é o sprite da Fase 1 (desenhado na altura dos olhos).
   - Nas costas ela funciona; não girei em ângulo quebrado, pra não estragar os pixels.
   - Se quiser uma picareta própria do isométrico, são ~25 gerações (64 candidatos de uma vez).

4. **O quadro da caminhada cresce pra 112×112** (o PixelLab dá folga pro movimento).
   - Por isso a âncora é anotada por direção, e não "o centro de baixo do quadro".
   - O verificador (`verifica_arte.py`) calcula sozinho.

5. **Escala:** o minerador tem ~75 px de altura, a escala real decidida na Fase 1. Os prédios
   da cena de estresse ainda são as caixas antigas, menores que ele. A casa em escala real é
   o Checkpoint 2.

## O que foi construído (só pra conferir a arte, sem tocar no jogo)

- `prototipos/camera/verifica_arte.py`
  - acha a menor caixa que contém o desenho;
  - conta os pixels fora de uma caixa declarada;
  - mede a âncora e o quanto ela treme.
- `prototipos/camera/arte_iso/picareta_overlay.py`: monta a picareta nas 2 configurações e
  exporta os quadros.
- `rota_a_estresse.gd`: opção de linha de comando `arte=minerador`, que troca os bonecos de
  teste pelo minerador novo, com a caixa real e a direção de losango com histerese.

## Pra aprovar

1. O minerador (estilo, rosto e roupa) nas 4 direções: `prancha_8_direcoes_iso.png`,
   `caminhada_SE_NE.png`.
2. O **ângulo** (desvio 1): (a) aceitar ou (b) testar a câmera "oblique".
3. **Pose parada por espelho** (achado 2).
4. A **picareta** nas costas (`picareta_4dir.gif`): serve a da Fase 1, ou gerar uma
   isométrica?

Com o OK, sigo pra **casa em escala real** (Checkpoint 2).
