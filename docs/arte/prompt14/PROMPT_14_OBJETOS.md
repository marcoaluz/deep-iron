# Prompt 14: objetos e props

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/objetos/final/` (115 peças),
montador `objetos/objetos.py`. Nada integrado ao jogo.

## O que ficou pronto

| Grupo | Peças |
|---|---|
| **Armazenagem** | caixote, 2 caixotes, caixote com palha, barril, tambor de óleo, 2 barris, saco, sacos, tábuas, sucata, pneus, roda de carroça, corrente, corda, palete, caixa de ferramentas |
| **Luzes** | tocha de parede (2), tocha de chão, tochas apagadas, lampião no gancho, lampião no poste, lampião pequeno, lampiões na mesa, lampião no caixote, fogueira (2) e apagada, braseiro e apagado, poste de rua. **Chama animada em 4 quadros** (script) nas tochas, fogueiras e braseiro |
| **Placas e estruturas** | placas com **pictograma** (caveira, raio, gás, perigo; sem texto), poste, poste cruzado, placa de direção, andaime solto, escada de mão, varal, poço d'água, banco, mesa, bigorna no toco, ferramentas encostadas |
| **Pilhas de recurso** (P/M/G) | pedra, tijolo, comida, couro, carvão (P/M), aço (P/M). Minério e madeira já existem (Prompts 8–9) |
| **Destroços pré-colapso e ossos** | chapa enterrada, carcaça de máquina, porta de carro, poste caído, bloco de concreto, ossos com crânio, costelas, braço de robô, painel listrado, barril vazando, cano, trilho quebrado, corrente enferrujada, furadeira velha, caixas de metal, vagonete velho |
| **Vagonete** | vazio e cheio (SE e espelho SO); anda sobre os trilhos do Prompt 7, que servem pra superfície também |
| **Guindaste da pedreira** (sugestão aceita) | mastro e lança de madeira, roda do guincho, bloco de pedra pendurado |

Cerca de estacas (sugestão aceita): usa a paliçada do muro nível 1 (Prompt 12) e a cerca da
horta (Prompt 11).

## Entregas (nesta pasta)

`prancha_objetos.png`, `fogo_fogueira.gif`, `fogo_tocha_parede.gif`, `fogo_braseiro.gif`.

## Custo

**~145 gerações** (6 lotes de 16 + guindaste).

## Desvios

1. **Vagonete:** uma orientação + espelho (é simétrico). Pras direções de "subida" (NE/NO), a
   mesma figura serve. Andar em 4 direções é movimento no código.
2. **Fogo** por script (brilho tremendo + ponta da chama). A luz em volta é do Prompt 19.
3. Alguns objetos vieram com uma mancha clara na base (sombra ao contrário); tirada por
   script.
