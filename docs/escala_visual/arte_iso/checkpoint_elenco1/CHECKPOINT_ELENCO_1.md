# Arte isométrica — CHECKPOINT do elenco: os 2 primeiros (engenheiro + médica)

Data: 2026-09-29. **Parado aqui esperando a aprovação do Marco** antes de gerar os demais.
Nada foi integrado ao jogo. A arte está em `project.godot/prototipos/camera/arte_iso/engenheiro/`
e `.../medica/`.

## Custo

| Personagem | Base (16 candidatos) | 8 direções | Caminhada SE+NE | Total |
|---|---|---|---|---|
| Engenheiro (homem) | 25 | 1 | 1 | 27 |
| Médica (mulher) | 25 | 1 | 1 | 27 |
| Guia 2:1 do personagem (`pixelart_workbench`) | | | | 0 |
| **Total** | | | | **54** (saldo 1.481 → **1.427**) |

## Como foi feito (o padrão pros próximos)

1. **Imagem-guia 2:1 do personagem**, desenhada no PixelLab (grátis): o losango do chão
   embaixo dos pés + a caixa até a altura dele. Mandada por link junto com o minerador
   aprovado, que serve de referência de escala e de estilo.
2. `create_image_pro` 48×84 → 16 candidatos. Escolhi o mais de frente (a rotação precisa
   dele de frente).
3. `create_character` v3 com câmera "high top-down" → 8 poses paradas.
4. Caminhada skeleton-v3 só em **SE e NE**. SO e NO são espelho (inclusive parado).
5. `arte_iso/personagem.py` baixa tudo e depois:
   - espelha SO e NO;
   - anota a âncora por direção;
   - calcula a caixa do personagem;
   - monta a prancha e o GIF.

## Resultado

| | Engenheiro (homem) | Médica (mulher) |
|---|---|---|
| Identidade da função | capacete de obra laranja, colete refletivo sujo, cinto com martelo, luvas | touca com cruz, roupa cirúrgica verde-água, avental de couro, estetoscópio, bolsa a tiracolo |
| 8 direções | ✅ coerentes (de costas aparece o colete) | ✅ coerentes (de costas, a alça cruzando) |
| Caminhada (4 quadros) | ✅ estável: corpo varia 0,7–1,8 px | ✅ estável: corpo varia 0,8–1,1 px |
| Caixa declarada (regra 2) | **38 × 38 × 78**, 4 px fora | **36 × 36 × 74**, 0 px fora |
| Âncora (regra 3) | por direção (`contrato.json`) | por direção (`contrato.json`) |

**Ferramenta da função (regra 5):**
- o martelo do engenheiro vai no cinto;
- a bolsa da médica vai a tiracolo.

As duas estão **desenhadas no corpo**, então a rotação de 8 direções já resolve frente e
costas, sem sobreposição. A picareta do minerador é sobreposta só porque ela tem nível/skin
e aparece no golpe.

**A caixa muda por personagem:** o engenheiro é mais largo (aba do capacete, postura). Na
integração, cada ipezinho usa a caixa do seu desenho. A ordenação continua a mesma (0 erros,
já testada com caixas de vários tamanhos).

## Diversidade (tom de pele por paleta, sem gerar de novo)

`tons_de_pele.png` de cada um: **original, clara, parda e negra**, a partir do mesmo desenho.
- As cores de pele são lidas **do rosto**. Na primeira tentativa, o capacete laranja, o
  colete e as luvas também trocavam de cor, porque são tons quentes; corrigido.
- No jogo vira uma tabela de troca de cor por ipezinho (`arte_iso/tons_de_pele.py`, as 3
  rampas).
- Assim **cada função × gênero sai nos 3 tons** pelo custo de um desenho só.

## Observações

- **O verde da médica saiu mais vivo** que o resto da paleta suja. Dá pra escurecer pela mesma
  troca de paleta, de graça. Diga se prefere assim.
- O contorno e a densidade batem com o minerador nos dois.

## Próximo: o elenco completo (pedido do Marco)

**Homem e mulher de todas as funções:** minerador, guarda, médico, engenheiro, caçador,
pesquisador, lenhador e sem função = **16 personagens**.

| Já pronto | Falta |
|---|---|
| minerador (homem), engenheiro (homem), médica (mulher) | **13**: mineradora, guarda (h/m), médico, engenheira, caçador (h/m), pesquisador (h/m), lenhador (h/m), sem função (h/m) |

- **Custo estimado:** 13 × ~27 ≈ **350 gerações** (sobram ~1.075). Cada um nos 3 tons de pele
  por paleta.
- **Pergunta:** o jogo também tem **cozinheiro** (Bloco 27), que não estava na lista. Incluo
  (+2 personagens, ~54)?
- **Depois do elenco,** as animações de trabalho (minerar, cortar, carregar, lutar, curar…)
  são outra etapa. Custo: 1 a 25 por animação e por direção, dependendo da técnica.
