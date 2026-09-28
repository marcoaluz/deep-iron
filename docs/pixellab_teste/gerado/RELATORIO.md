# Relatório — Teste de estilo do minerador via PixelLab (tentativa 1)

Data: 2026-09-28. Nada foi integrado ao jogo; nenhum código, cena ou save foi alterado.

## Veredito curto

**O estilo não bate.** A paleta e o tamanho batem, mas a legibilidade não. O sprite
gerado parece uma foto reduzida pra 16 px: cheio de ruído, sem o contorno escuro
seletivo, sem a lanterna do capacete, com o rosto borrado e sem pixels "desenhados"
(olhos de 1 px, bochecha rosada, faixa do capacete). A caminhada também não segura a
identidade: a cabeça gira de lado nos quadros 2 e 3 e as cores trocam de um quadro pro outro.
Do jeito que está, não substitui o sprite feito pelo `gen_sprites.py`.

## O que foi feito

| Etapa | Ferramenta | Parâmetros-chave | Custo |
|---|---|---|---|
| Corpo (pose parada, de frente) | `create_image_pro` | `width=16, height=17`, `style_image_base64` = quadro 0 de `ipezinho_m0.png` (16×17, copia paleta, contorno, detalhe e sombreado), `reference_images=[{quadro 0 ampliado 8x, usage:"character base and outfit…"}]`, `no_background=true` | 20 gerações → 64 candidatos |
| Caminhada | `animate_image` | quadro escolhido (candidato 11) como `first_frame_base64`, `frame_count=4`, só de frente | 1 geração |

**Total: 1 tentativa de cada, 21 gerações** (o saldo trial caiu de 33 para 12).
Não sobrou saldo pra uma segunda rodada do `create_image_pro`, que custa 20.

### Por que `animate_image` e não `animate_character`
O `animate_character` exige um personagem criado no PixelLab (`create_character`).
Em todos os modos que aceitam imagem de referência (`v3`) ou estilo (`pro`), o
`create_character` **sempre gera 8 direções**, e o briefing pede pra não gastar com isso.
O `animate_image` é o equivalente pra sprite solto: anima só a imagem de frente, sem criar
as rotações.

## Tamanho de canvas: o que a API aceitou (pra reusar)

| Ferramenta | Parâmetro | Aceita 16×17? | Observação |
|---|---|---|---|
| `create_image_pro` | `width`, `height` (mín. 16, sem múltiplo de 4) | **Sim, 16×17 nativo** | ≤42 px devolve **64 candidatos** pelo mesmo preço (20 gerações). Não houve redimensionamento. |
| `animate_image` | herda o tamanho do `first_frame` | **Sim, 16×17** | 1 geração pra 4 quadros; devolve 5 imagens (índice 0 = entrada inalterada). |
| `create_image_pixen` | `width`, `height` | Não | múltiplo de 4 e **quadrado abaixo de 32** → o mais perto seria 16×16 ou 20×20; não aceita referência. |
| `create_character_pro_flash` | `width`, `height` | Não | múltiplo de 4 (16×16 ou 16×20); sempre 8 direções. |
| `create_character` | `size` (quadrado, mín. 16) | Não | sempre quadrado; `v3`/`pro` sempre 8 direções. |

**Receita pros próximos personagens:** `create_image_pro(width=16, height=17,
style_image_base64=<quadro 16×17 atual>, reference_images=[…])` e depois
`animate_image(first_frame_base64=<escolhido>, frame_count=4)`.

## Critérios do LEIA.md

1. **Densidade de pixel: bate no tamanho, não na leitura.** Saiu nativo em 16×17 (não
   precisou reduzir, então não borrou por redimensionamento). Mas o *conteúdo* tem cara de
   imagem reduzida: 60–63 cores únicas em ~190 pixels opacos, variação de tom pixel a pixel
   e nenhum pixel "desenhado" de propósito. Na escala 2 do jogo, o atual lê como rosto +
   lanterna + macacão; o gerado lê como uma mancha marrom com capacete.
2. **Paleta: bate.** Latão, jeans desbotado, vinho e pele quente estão lá, com o mesmo tom
   gasto e nada saturado (ver as faixas de paleta em `comparacao_lado_a_lado.png`). Aqui o
   `style_image` funcionou bem.
3. **Contorno e luz: não bate.** Não tem contorno escuro seletivo em volta da silhueta: as
   bordas se desfazem em pixels acinzentados e soltos. A luz de cima-esquerda aparece só de
   leve no capacete.
4. **Silhueta: bate em parte.** A proporção chibi (cabeça grande com capacete, corpo curto)
   está certa, mas a **lanterna amarela sumiu** em quase todos os 64 candidatos, e o rosto
   não tem olhos nem bochecha legíveis.
5. **Caminhada: não bate.** A animação redesenha o boneco a cada quadro em vez de mover o
   mesmo boneco: nos quadros 2 e 3 a cabeça vira pra lateral, o rosto muda e o quadro 4 tem
   pixels soltos nos pés. Não dá um ciclo limpo de 4 quadros como o atual.
6. **Espelhável: funciona** (não tem nada assimétrico que quebre no `flip_h`), mas herda os
   problemas acima.

## Arquivos em `gerado/`

- `comparacao_lado_a_lado.png`: atual × gerado em 8x, normal e espelhado, os dois na escala
  real do jogo (2x) e as paletas.
- `comparacao_caminhada_8x.gif`: as duas caminhadas animadas lado a lado.
- `tentativa1_grade_64.png`: os 64 candidatos do `create_image_pro` (6x).
- `tentativa1_candidatos/c00..c63.png`: os candidatos em 16×17.
- `tentativa1_escolhido_c11.png`: o candidato usado de base (o de rosto mais legível).
- `tentativa1_caminhada/q0..q4.png`: `q0` é a entrada; `q1..q4` são os 4 quadros gerados.
- `tentativa1_folha_64x17.png`: `q1..q4` em folha 64×17, no formato do jogo.
- `tentativa1_caminhada_8x.gif`: a caminhada gerada, ampliada.

## Se quiser insistir (precisa de mais saldo)

- Rodar o `create_image_pro` de novo com a **folha inteira** ou vários quadros como referência
  e pedir explicitamente "1px dark outline, 2 black pixel eyes, yellow headlamp pixel".
- Passar o resultado pelo `reduce_colors` / `correct_pixelart` pra cortar o ruído (~20–30
  cores), ou limpar à mão com o `pixelart_workbench` (grátis).
- Pra caminhada, testar `animate_image_pixminimax` (precisa de assinatura tier 1) ou
  gerar só as poses das pernas e compor sobre o tronco fixo, como o `gen_sprites.py` já faz.
  Na prática, nessa resolução o gerador procedural atual ainda sai na frente.
