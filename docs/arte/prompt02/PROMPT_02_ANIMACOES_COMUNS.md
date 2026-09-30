# Prompt 2: animações comuns do elenco

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/<personagem>/<animação>/`.
Nada integrado ao jogo.

## Estados que existem de verdade (conferido no código)

| Estado no jogo | Aparece no mapa? | Arte |
|---|---|---|
| Carregar (hauling, delivering, storing...) | sim | **caminhada + saco nas costas em sobreposição** |
| Comer (no comedouro) | sim | **comer** (em pé, tigela e colher) |
| Machucado leve (anda mais devagar) | sim | **mancar** (esqueleto `sad-walk`, corpo curvado) + ícone de curativo no código |
| Machucado grave / guarda caído em combate | sim | **ferido**: senta no chão com a perna na tala e fica respirando |
| Morte (fome, frio, grave sem leito) | sim, antes da cova | **deitar**: ajoelha e deita, sem drama; o último quadro fica parado |
| Dormir **sem casa** | sim (na rua) | último quadro do **deitar** + respiração no código |
| Dormir em casa, taverna, internado | **não**: o ipezinho some dentro do prédio (`_inside`) | nenhuma |
| Parque | anda dentro da área (lazer passivo); **ninguém senta** no código | nenhuma |
| Festa | "Eba! Festa!" onde cada um está | **código**: pulinho sobre a pose parada |
| Greve | fica parado com a placa | pose parada + placa (sobreposição, Prompt 4) |

## Escolha de economia (o prompt pediu pra reportar)

Não usei "corpo base + troca de roupa": a roupa de cada função muda a silhueta (capa,
avental, jaleco, capacete), e trocar só a cor não resolve. Ficou assim:

- **Por função** (18 personagens): comer, ferido, deitar e mancar. ~16 gerações por
  personagem.
- **Carregar:** o v3 foi inconsistente (a mineradora apareceu no NE sem saco). Troquei por
  **caminhada + saco em sobreposição** (`arte_iso/saco.py`, `itens/saco_costas.png`).
  - Serve pros 18 e pros trajes, e custou 0.
  - O saco fica **atrás** do corpo de frente pra câmera e **na frente** de costas, como a
    picareta.
  - Acompanha o balanço do passo e a altura de cada personagem.
- **Código, sem arte:** festa, respiração, ícone de curativo.

## Entregas (nesta pasta)

| Arquivo | O que é |
|---|---|
| `carregar_18.gif` | os 18 andando com o saco |
| `comer_18.gif` | comer |
| `ferido_18.gif` | ferido |
| `deitar_18.gif` | deitar |
| `mancar_esq_18.gif` | mancar |
| `*_ultimo_quadro.png` | a pose final de cada animação (deitado, sentado com tala) |

## Custo

**~345 gerações** (saldo 749 → ~404 no fim do Prompt 2): 72 animações novas + pilotos + 5
refeitas. O carregar em sobreposição custou 0.

## Desvios e correções (reportando)

1. **Machucado leve com tipoia (o jeito da fase 1 de que o Marco gostou).**
   - Pelo v3 com texto, a tipoia não aparece de forma consistente.
   - Com variante, seriam ~30 por personagem (~540 pros 18).
   - Ficou o `sad-walk` (o mesmo andar abatido da fase 1) + ícone de curativo no código.
   - A tipoia desenhada pode entrar depois do upgrade, se quiser.
2. **Queda de costas pelo esqueleto (`falling-back-death`):** saiu acrobática. Troquei por
   "deitar" em v3 (ajoelha e deita), sóbrio como pede o contrato.
3. **Sangue:** a IA pôs uma poça escura sob a cabeça do guarda deitado. O filtro "sem
   sangue" do `trabalho.py` foi ampliado (vermelho escuro) e **todos os 36 deitar/ferido
   foram reprocessados**.
4. **Engenheiro deitado (SE):** veio com um retângulo de fundo nos 8 quadros. Refeito (2).
5. **Rastro com a cor da lanterna:** o rastro branco do carregar tinha a mesma cor do brilho
   da lanterna do capacete e escapava do filtro. A limpeza agora também compara quantidade
   de pixels (cor clara que aparece muito mais que nas poses paradas = rastro).
6. **Pesquisadora:** a direção de trás de todas as animações dela sai pela NO espelhada,
   pelo mesmo motivo da caminhada.
