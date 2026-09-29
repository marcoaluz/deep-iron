# Relatório — Minerador v2 do zero, estilo CraftPix (tentativa 1)

Data: 2026-09-29. Nada foi integrado ao jogo; nenhum código, cena ou save foi alterado.
O sprite e a paleta do minerador atual **não** foram usados como referência.

## Veredito curto

**Bateu no essencial; é o primeiro resultado aproveitável.**

- **Proporção, lanterna, rosto e paleta suja: bateram.** O boneco tem proporção adulta na
  mesma escala da CraftPix. A lanterna âmbar aparece nos 16 candidatos. O rosto tem expressão
  fechada, barba por fazer e fuligem. A paleta saiu ~30% mais escura que a CraftPix.
- **Caminhada: o skeleton-v3 manteve o mesmo boneco nos 4 quadros.** O v3 com texto
  voltou a "pular".
- **Não bateu:**
  - **faltam as luvas** (as mãos saem de pele nos 16 candidatos);
  - **o corpo é mais atarracado** e a pose mais dura e simétrica que a da CraftPix;
  - **o contorno preto é mais grosso e uniforme** que o contorno seletivo da CraftPix.

## Ponto de atenção: escala no jogo

O personagem tem **73 px de altura num canvas de 48×80**, contra 17 px do minerador atual.
Nessa densidade, o resto da arte do jogo (prédios, jazidas, chão, feitos em 16 px e ampliados
2x) vai destoar. Adotar esse estilo implica refazer a arte do jogo nessa escala, não só
trocar o personagem.

## O que foi feito

| Etapa | Ferramenta | Parâmetros-chave | Custo anunciado |
|---|---|---|---|
| Corpo, de frente | `create_image_pro` | `width=48, height=80`; 4 recortes CraftPix em `reference_images`, cada um com um `usage` (proporção, contorno/rosto, roupa, textura de couro); `style_image` = o do avental com `style_copy=[outline, detail, shading]`, **sem** `color_palette` (a paleta suja foi pedida no texto) | 25 gerações → **16 candidatos** |
| Personagem de verdade | `create_character(mode="v3", reference_image=candidato 9, view="side")` | o sul ficou **idêntico pixel a pixel** ao candidato; gerou 8 direções coerentes | 1 geração |
| Caminhada A | `animate_character(mode="skeleton-v3", template="walking-4-frames", directions=["south"])` | 4 quadros | 2–4 gerações (faixa da doc) |
| Caminhada B | `animate_character(mode="v3", action_description=…, frame_count=4, keep_first_frame=false)` | 4 quadros | 1 geração |

Saldo no fim: 1975 de 2000 gerações (o `get_balance` mostra 25 usadas).
ID do personagem no PixelLab: `a3a10765-d9e7-427b-8332-bbbf81a512cb`
("Minerador Deep Iron v2"), caso queira gerar outras animações dele depois.

### Candidato escolhido: o 9, de 16 (`t1_escolhido_c09.png`)

- Capacete de **aço cinza**: a lanterna âmbar contrasta mais que nos candidatos de capacete
  marrom (0, 1, 4, 8, 13), onde capacete e colete se misturam.
- É o **mais remendado**: remendo redondo no colete e rasgos e remendos nos joelhos, o que
  combina com a ideia de "engenheiro improvisando".
- Tem rosto sério com fuligem. Os candidatos 3 e 5 eram as alternativas mais próximas.

### Desvios do briefing (limites da API, explicados antes da geração)

- O **`create_character` não aceita imagem de referência de estilo.** No modo v3, a imagem de
  referência é o próprio boneco a ser girado. Por isso as CraftPix entraram no
  `create_image_pro`, e o resultado escolhido é que foi passado ao `create_character` v3.
- Os modos **Pro e V3 sempre geram 8 direções.** Não existe opção de 4 nesses modos. As
  rotações custaram 1 geração e estão em `personagem_rotacoes/`.
- O **`create_character_state` não foi usado.** Ele cria variantes do personagem (outra
  roupa, outra pose fixa) por 20–40 gerações e não produz quadros de caminhada. O que evita o
  "redesenhar a cada quadro" é o skeleton-v3, que desenha todos os quadros a partir da mesma
  imagem base.
- A **interpolação v3 não foi testada.** O skeleton-v3 já resolveu a estabilidade, e a
  interpolação precisaria de uma pose final desenhada à parte. Ela também só gera meio ciclo
  (de uma pose a outra), não um loop.

## Critérios do briefing

| Critério | Resultado | Por quê |
|---|---|---|
| Proporção e detalhe iguais à CraftPix | **Em parte** | A altura bate (73 px contra 65–71 px da CraftPix) e a proporção é adulta (~6,5 cabeças). Tem textura visível: xadrez da flanela, couro, remendos, sujeira na calça. Mas o corpo é bem mais largo e musculoso e a pose é rígida e simétrica, enquanto a CraftPix é mais esguia, em 3/4 e com atitude (mão na cintura). O contorno preto é mais pesado. A contagem de cores é maior (46 contra 9–19). |
| Capacete + lanterna legíveis | **Sim** | Lanterna âmbar de 2×2 px com brilho, visível nos 16 candidatos e em todos os quadros da caminhada. |
| Rosto com expressão fechada | **Sim** | Sobrancelha baixa, boca reta, barba por fazer e fuligem. O "olhar cansado" não aparece de fato nessa resolução: os olhos têm 1–2 px. |
| Paleta mais suja que a CraftPix | **Sim** | Brilho médio 0,22 contra 0,31 da CraftPix, com saturação parecida (0,45 contra 0,47). Marrom, ferrugem e cinza-chumbo. O único acento forte é a lanterna. A pele ainda sai um pouco alaranjada. |
| Roupa pedida | **Em parte** | Colete de couro remendado, flanela escura, calça reforçada e botas de cadarço altas estão lá. **Faltam as luvas.** |
| Caminhada com o mesmo personagem | **Sim (skeleton-v3) / Não (v3 texto)** | No skeleton-v3, capacete, lanterna, remendos, rosto e cores ficam iguais nos 4 quadros; só pernas e braços mudam, e o passo é contido. No v3 texto, no quadro 3 a cabeça vira de lado, o corpo afina e as pernas se juntam numa só. |

## Arquivos em `gerado_v2/`

- `comparacao_craftpix_vs_gerado.png`: **prancha principal**. Quatro personagens CraftPix,
  o gerado parado e os 4 quadros da caminhada skeleton-v3, tudo em 4x nativo, com as duas
  paletas e os números de brilho e saturação.
- `comparacao_caminhadas.png`: base × skeleton-v3 × v3 texto.
- `caminhada_skeleton_v3_5x.gif` e `caminhada_v3_texto_5x.gif`: as caminhadas animadas.
- `caminhada_*/q0..q3.png`: quadros originais (canvas 112×112 e 108×108 da API);
  `q*_48x80.png`: os mesmos recortados em 48×80, alinhados pelos pés.
- `caminhada_*_folha_192x80.png`: os 4 quadros numa folha só.
- `t1_grade_16.png` e `t1_candidatos/c00..c15.png`: os 16 candidatos.
- `t1_escolhido_c09.png`: o candidato escolhido.
- `personagem_rotacoes/*.png` e `personagem_8_direcoes.png`: as 8 direções.
- As referências ficaram em `../referencia_estilo/`: as imagens originais (ampliadas 2x),
  a versão reduzida a 1x (`*_1x.png`) e os recortes individuais (`*_p1..p4.png`).

## Próximos passos sugeridos (se aprovar o estilo)

- **Luvas e silhueta mais esguia:** `create_character_state` no mesmo personagem com
  "wearing thick work gloves, slimmer build", ou uma nova rodada do `create_image_pro`
  pedindo "slim wiry build, relaxed 3/4 stance" (cerca de 25 gerações).
- **Caminhada mais ampla:** testar outros modelos de caminhada no skeleton-v3
  (`walking-6-frames`, `walking-8-frames`).
- **Antes de tudo, decidir a escala do jogo.** Um personagem de 73 px pede cenário na mesma
  densidade.
