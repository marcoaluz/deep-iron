# Bloco 92: a arte do PixelLab dos Blocos 86–90 e o padre como função

Data: 2026-10-06. Branch `isometrico`.

## O pedido

O Marco pediu, sobre os Blocos 86, 87, 88 e 90, "a mesma arte do jogo, feita no PixelLab", com fundidor e padre
como funções, só UM padre, e "tudo com o mesmo nível de detalhe e bonito no jogo". Depois ele completou: só os
personagens **masculinos** podem virar padre, e o ferreiro pode ser homem ou mulher.

A arte provisória feita por código e o "tom de cor por cima da roupa de outro ofício" saíram. Tudo foi gerado no
PixelLab pela **mesma receita** do elenco e dos prédios. A receita ficou anotada na memória do projeto e no
CLAUDE.md (regra 11).

## Personagens (oficios92.py)

| Personagem | Gênero | Roupa | Trabalho |
|---|---|---|---|
| Fundidor / fundidora | h / m | boné com óculos de solda, jaqueta grossa queimada, avental de couro, luvas até o cotovelo, lenço vermelho | **fundir**: mexe as brasas com uma barra de ferro comprida |
| Ferreiro / ferreira | h / m | careca de barba (ele) / bandana (ela), braços de fora, avental de ferreiro, tenaz no cinto | **forjar**: tenaz numa mão, martelo de ferreiro na outra, batendo |
| Padre | só homem | batina preta, colarinho branco, estola roxa, cruz de madeira, cordão, cabelo grisalho e óculos | **pregar**: livro aberto, a mão levantada abençoando |

A receita, igual à dos 18 do elenco:

1. **Candidatos:** `create_image_pro` 48×84 com 16 candidatos. Referências: o minerador (homem) ou a médica
   (mulher) e a guia 2:1. O piloto foi o fundidor; depois vieram os outros quatro.
2. **Personagem:** `create_character` v3 com câmera "high top-down", a partir do candidato mais de frente → 8
   poses paradas.
3. **Caminhada de 8 quadros:** `walking-8-frames` em `skeleton-v3`, nas direções SE e NE; SO e NO saem por
   espelho. Usa o pé no chão do Bloco 73/76.
4. **Animações comuns:** comer, ferido e deitar em v3 com 8 quadros, com as mesmas descrições do elenco;
   mancar com `sad-walk`.
5. **Trabalho:** v3 com 8 quadros. A primeira leva trouxe defeitos: fogo, poça de metal, picareta no lugar do
   martelo e a barra sumindo nos primeiros quadros. Foi refeita com uma descrição mais literal (`REFAZ`) e
   limpa no `trabalho.py`:
   - `sem_brilho`: apaga o laranja fora da paleta;
   - `soltos`: tira os pixels soltos;
   - `troca`: o quadro 0 vira cópia de um quadro com a barra.
6. **Casaco de inverno:** estado "Casaco inverno", caminhada e, no padre, o pregar.
   - O trabalho de casaco do fundidor e do ferreiro saiu ruim duas vezes: picareta, fogo e o casaco mudando
     de cor.
   - Como **a fornalha e a forja são quentes, eles trabalham sem o casaco**. O jogo já usa a animação da
     base quando o casaco não tem a do trabalho.
7. **Retrato:** `create_portrait_character` com 48 px.
   - As **5 expressões** (neutro, contente, cansado, bravo, ferido) usam as frases de sempre ("same character,
     tired and sad: ...; keep the face, hair, helmet/hat, clothes, colors and framing identical").
   - Saem nos 3 tons de pele.
   - O trecho "helmet/hat" fez o modelo **inventar chapéu**: capacete no ferreiro careca, solidéu no padre.
     Foi acrescentada uma nota por personagem (`retratos.py NOTA`), por exemplo "He is BALD: no hat...".
8. **Ícones da barra** (32 e 24 px): o cadinho despejando metal (fundidor), a bigorna com o martelo (ferreiro) e
   a cruz com a estola (padre).

Integração parcial, sem regravar os PNGs do elenco inteiro:
- bonecos: `integra.py bonecos fundidor ferreiro padre`;
- retratos: `retratos.py exporta <nomes>`.

## Prédios: a evolução da obra (obra 1 → 2 → 3 → pronto)

- **Fornalha:** usa a **Fundição** gerada no Prompt 12 (`fundicao/`), que nunca tinha entrado no jogo.
  - Tem forno de tijolo com chaminé de ferro, boca do forno com cadinho, lingotes, monte de carvão e carrinho
    de minério.
  - Já tinha obra 1, 2 e 3.
- **Igreja:** nova (`predios92.py`), no mesmo desenho da capela velha do mapa (Bloco 71), só que inteira e
  cuidada.
  - Pedra escura, ardósia com remendos de ferro, torre com sino e cruz.
  - Vitrais apagados (a luz é do jogo), rosácea, porta dupla em arco, escadaria, vasos e banco.
  - Etapas:
    - guia 2:1 (`predio.py guia igreja 140 110 130 95`);
    - pronto: guia + capela velha + casa aprovada + minerador para a escala;
    - obra 2: o esqueleto no mesmo quadro;
    - obra 1 e obra 3: `obras.py`.
- No jogo, `iso_art.gd` desenha a cena e o canteiro com a arte nova (`KIND_OF_SCENE` / `KIND_OF_CANTEIRO`), e a
  pegada da navegação sai do desenho.

## Decoração

| Peça | Desenho |
|---|---|
| Tocha | a chama animada do mapa (acesa) e a tocha apagada (de dia ou quando um Lumívoro come a luz) |
| Banco, mesa | os do mapa |
| Lampião | **novo**: poste de ferro com base de pedra e vidro âmbar |
| Cerca | **nova**: três postes e duas travessas, remendada com arame (espelhada para seguir a pegada) |
| Canteiro de flores | **novo**: borda de tábuas e pedra, flores miúdas |
| Bandeira | **nova**: pano ferrugem com o sol e a picareta, num mastro sobre pedras |

- Em `decor.gd` cada peça ganhou `"iso"` (o nome do desenho).
- Em `decoracao.gd`, `iso_prop_nome()` troca a tocha entre acesa e apagada.

## Padre: função da barra

- **Botão "Padre" [8]** na barra de funções. Selecione **um** ipezinho **homem**. A vila tem **um** padre só, e
  a função abre com a Vila no estágio do padre.
- O motivo da recusa aparece no aviso:
  - "Só homem pode ser padre";
  - "A vila já tem padre (X): tire a função dele primeiro";
  - "O padre só vem com a Vila no estágio 2".
- O padre **pode trocar de função**. Para trocar de padre: tira a função do atual e dá a outro.
- O **Padre Bento** continua chegando por evento no estágio do padre. Ele é homem e chega com a função.
- Na missa e no funeral ele **prega** (a animação "pregar").
- A barra ficou com 14 botões: cada botão foi de 90 para 82 px de largura para caberem na tela de 1280.

## Testes

- `b92_arte_oficios` passa.
  - Bonecos: as 3 funções, as 6 animações + o trabalho nas 4 direções, 8 quadros, casaco, tons de pele.
  - Retratos, ícones e o botão na barra.
  - Obras 1–3 e pronto da fornalha e da igreja.
  - Decoração; padre (mulher recusada, um só, estágio, troca de função, prega na missa); save.
- Também passaram depois das mudanças: b86, b87, b88 (ajustado: o padre agora troca de função), b90,
  p29_bonecos, p29_predios, hud_frostpunk e b54_configuracoes.

## Fotos

`docs/arte/bloco92/` (geradas por `tests/capturas_bloco92.gd`):
- `predios_em_obra.png`;
- `predios_e_oficios.png`;
- `oficios_perto.png`;
- `decoracao_noite.png`;
- `decoracao_dia.png`;
- `barra_padre.png`.

## Gasto no PixelLab

752 gerações:
- 5 imagens de candidatos;
- 5 personagens;
- animações (inclusive as refeitas);
- 5 casacos;
- retratos e expressões;
- 3 ícones;
- a igreja (pronto e obra);
- 4 peças de decoração.

Saldo: 8.669 → 7.917.
