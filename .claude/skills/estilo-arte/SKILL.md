---
name: estilo-arte
description: A receita prática do estilo visual do DEEP IRON para gerar arte no PixelLab e trazê-la pro Godot. Use ao escrever qualquer prompt do PixelLab (personagem, criatura, prédio, prop, decoração, retrato, ícone, ilustração), ao escolher tamanhos, ao integrar o resultado no jogo ou ao revisar se uma peça combina com o resto. Complementa a skill deep-iron-arte (o contrato) com os textos de prompt, os tamanhos, as camadas e o caminho de importação. Não serve pra código de gameplay.
---

# Estilo de arte (DEEP IRON) — receita

Leia também `deep-iron-arte` (o contrato: guia 2:1, caixa, âncora, obras, peles) e `docs/arte/CONTRATO_ARTE.md` / `INVENTARIO.md` se existirem. Aqui está **como escrever o prompt, o tamanho e a importação**.

## Prefixo de estilo (cole no fim do prompt; muda só o acento de cor)

> Grimy, dark, desaturated earthy palette: dark browns, rust, lead grey, soot black; <ACENTO> accent. Darker and dirtier than the references. Crisp 1px near-black outline around the silhouette like the references; interior detail drawn with darker shades of the local color rather than black lines. Clear form shading with light from top-left, low color count, clean readable pixel clusters.

- `<ACENTO>` = **uma** cor de destaque da peça ("dull amber glass", "faded indigo blue", "oily dark teal"). Duas no máximo ("deep blue gems and dull orange embers").
- Prédios/props: "Isometric 2:1 view, same angle, scale and art style as the reference …", "Only the object, transparent background, no ground tile, no characters."
- Luz sempre de cima-esquerda. Sem gore: ferimento, morte e combate sóbrios.

## Prefixo negativo (o modelo inventa chapéu e ferramenta)

- Personagem de ofício novo: `He/She is NOT a miner: NO helmet, NO headlamp, NO pickaxe, NO shovel, NO lantern; the <peça-chave> and the <peça-chave> are the key features.` O minerador é a régua e o modelo copia o capacete dele.
- Animação de trabalho: `Only the character and his <ferramenta>: no <objeto> drawn, no ground, no motion trails, no white arcs, no effects.`
- Retrato (5 expressões): a frase padrão ("same character, tired and sad … keep the face, hair, helmet/hat, clothes, colors and framing identical") **mais** uma nota por personagem em `retratos.py NOTA` ("He is BALD: no hat…", "keep exactly this beanie…"), senão o modelo inventa chapéu.
- Luz e fogo: a luz entra por código; peça "unlit", "no glow, no rays".

## Tamanhos

| Peça | Tamanho |
|---|---|
| Personagem (create_image_pro) | **48x84** (48x80 corta a cabeça); minerador/médica como referência de escala |
| Quadro de animação (v3) | 8 quadros, 4 direções de losango (SE, NE + espelho) |
| Retrato | 48 px, 5 expressões (neutro, contente, cansado, bravo, ferido) × 3 tons de pele (clara, parda, negra) |
| Prédio | caixa declarada; porta = altura do minerador; obra 1 → 2 → 3 → pronto |
| Decoração/prop | ex.: lampião 32x84, cerca 64x48, monumento 112x144 (recortado e com âncora) |
| Cartão do CONSTRUIR | 96x64 (`ui95.py reaproveita` ou `gera`) |
| Ilustração de evento | 256x144 (`assets/game/ui/ilustracoes/`) |
| Ícone de UI | 32 px (+ p24) |

## Camadas de desenho (`docs/arte/CAMADAS.md`)

0 fundo e céu · 1 terreno · 2 detalhes (prédios, árvores, decoração) · 3 dinâmicos (ipezinhos, criaturas) · 4 efeitos e luz. Nada novo usa `z_index` relativo no mundo iso: entra pela caixa ou ganha um z fixo da faixa. Luz nova entra no grupo `cullable_lights`.

## Fluxo no PixelLab (piloto antes do lote; mostrar o plano e os prompts antes de gastar quando o prompt pede)

1. Candidatos: `create_image_pro` com a guia 2:1 + o aprovado de referência (16 candidatos custam ~15). Escolher olhando a grade (silhueta limpa, braços relaxados, sem objeto inventado).
2. Personagem v3 "high top-down" do candidato; caminhada de 8 quadros (skeleton-v3), comer/ferido/deitar/mancar e o trabalho; casaco de inverno; retrato.
3. Scripts em `project.godot/prototipos/camera/arte_iso/` (`oficiosNN.py`, `predios92.py decor`, `ui95.py`) e o cliente em `tools/pixellab/` (`pl.py`, `gen.py`, `chars.py`). Cada job grava o id no JSON do script: nunca resubmeta sem conferir `list_jobs` (um processo de fundo pode ter morrido com o job já pago).

## Importar no Godot

1. `python integra.py bonecos <funções>` (só essas pastas), `python integra.py props <nomes>`, `python retratos/retratos.py exporta <nomes>`: **subcomandos parciais**; confira `git status` e devolva o que não é do bloco (o `integra.py` regrava PNGs).
2. Função nova: entrada em `integra.py FUNCOES` (homem, mulher, trabalho) e em `iso_bonecos.gd OUTFIT_FUNCAO`; o `PROVISORIO` só vale enquanto a função não está no `bonecos.json`.
3. `godot --headless --path project.godot --import` (gera `.import` e `.uid`); depois o teste do bloco.
4. Imagens (png/gif/wav/ogg/mp3) vão pro **Git LFS**; commit por caminho explícito.
5. Conferência: folha com as 8 poses + casaco + retrato em `docs/arte/blocoNN/` (veja a folha antes de dizer que está pronta).

## Checklist rápido de revisão

Cabe na caixa · âncora igual nas variações · contorno 1 px e paleta como o resto · lê bem em 1x · GIF em loop sem pulo · 3 peles · nenhum objeto/chapéu inventado · sem texto desenhado na imagem.
