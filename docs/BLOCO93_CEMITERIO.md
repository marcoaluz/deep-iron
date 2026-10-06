# Bloco 93: o cemitério, o padre que enterra e os ritos fúnebres

Data: 2026-10-06. Branch `isometrico`.

## O pedido do Marco

1. Ter a **estrutura do cemitério**.
2. Quando alguém morre, **o padre vai lá, pega o morto e leva para o cemitério**.
3. Uma **opção na pesquisa**: o padre faz o **funeral**, e com isso o **ânimo aumenta um pouco**.
4. **A lápide mostra o nome da pessoa e quando morreu.**
5. **O cemitério começa vazio**: cruzes e lápides vão aparecendo conforme as pessoas morrem.
6. O cemitério **pode ser criado com o tamanho que o jogador quiser**.

## Como funciona

### Construir: o jogador escolhe o tamanho

- **CONSTRUIR → Culto → Cemitério → "Marcar"**: arraste no mapa o terreno. É a mesma ferramenta das áreas de
  trabalho (`area_placer.begin_custom`, generalizada).
- **Tamanho:**
  - o terreno se encaixa nos trechos da cerca (24 px);
  - mínimo de 3 x 2 trechos, máximo de 10 x 8 (`cemiterio_max_trechos`);
  - pode ter mais de um cemitério.
- **Custo e obra pelo tamanho:**
  - créditos: base + por vaga;
  - ferro e madeira: por trecho de cerca;
  - segundos de engenheiro: base + por trecho.
  - A dica mostra "N vagas • X cr + Y ferro + Z madeira" enquanto arrasta.
- **Regras do terreno:**
  - precisa ser chão livre, sem nenhuma construção dentro;
  - a decoração do mapa (capim, pedra) sai;
  - abre no estágio 2 da Vila (`cemiterio_estagio`).
- **A obra** é do engenheiro.
  - O próprio cemitério é o local da obra (interface do `obra_site.gd`, como o coletor em ruína do Bloco 81),
    porque o desenho depende do tamanho.
  - A evolução aparece montada com as peças:
    1. estacas nos 4 cantos;
    2. os postes todos;
    3. a cerca do fundo e dos lados, a frente pela metade, sem portão;
    4. pronto: a cerca inteira e o portão no meio da frente.

### Começa vazio; cada morte vira uma cruz ou uma lápide

- **Com cemitério**, quem morre deixa o **corpo** (a mortalha) onde caiu (`corpo.gd`), e a cruz do lado da
  enfermaria deixa de aparecer. O memorial do diário continua.
- **O padre** busca os mortos (`ipezinho._padre_enterro`), de dia e fora da missa/funeral:
  1. vai até o corpo ("buscando um corpo");
  2. pega: o corpo sai do chão e vai **nos ombros dele** (sobreposto à caminhada, como o saco do minerador);
  3. leva até a próxima vaga ("levando ao cemitério");
  4. **enterra** rezando, com a animação "pregar" (`enterro_tempo`).
- **O túmulo:**
  - aparece uma **cruz de madeira ou uma lápide** (3 de cada), com o **nome e o dia**, por exemplo
    "Beto · † dia 12" (uma linha, na frente de tudo: o texto de duas linhas saía desencontrado no espelho da vista iso);
  - as vagas enchem do fundo para a frente;
  - cheio, o padre procura outro cemitério.
- **Sem padre**, o corpo espera, com o aviso "sem padre, ninguém leva ao cemitério (função Padre, tecla 8)".
- **Uma emergência** no meio do caminho (ou trocar a função do padre, ou ele morrer): o corpo volta para o chão,
  e ele busca depois.

### Pesquisa: Ritos fúnebres (Laboratório, ramo Vila, depois de Medicina)

- **Sem a pesquisa**, o padre só enterra, e não há funeral.
- **Com ela**, depois do enterro o funeral fica marcado **no cemitério**, na hora social:
  - a vila vai até o portão (ponto social "cemiterio", ao ar livre);
  - o padre prega;
  - no fim, o **luto cai** (`funeral_alivio`) e a vila ganha o fator **"funeral digno"**: +5 de ânimo por 240 s
    (`morale.funeral_bonus` / `funeral_bonus_tempo`).
- **Sem cemitério**, o funeral pesquisado é na igreja, como no Bloco 88.
- **Mudança no Bloco 88:** o funeral agora **precisa da pesquisa**. O teste b88 foi ajustado.

## Arte (PixelLab, predios93.py)

A primeira versão foi um terreno fixo. Ficou como referência do estilo e como ícone do menu. Como o cemitério
começa vazio e tem tamanho livre, a arte do jogo é **modular**:

| Peça | Para quê |
|---|---|
| `cem_cerca` / `cem_cerca_y` | trecho de grade de ferro com lanças, nas duas diagonais. Saiu com inclinação 0,31 e foi acertada para o 2:1 coluna a coluna, sem borrar |
| `cem_poste` | poste de madeira escura com capitel de ferro, em cada emenda (cobre a junta) |
| `cem_portao` | o portão duplo com o arco de ferro |
| `cem_cruz_0..2`, `cem_lapide_0..2` | os túmulos (cova fresca com cruz / lápide) |
| `corpo` | o corpo na mortalha no chão |
| `corpo_costas` | a mortalha nos ombros do padre |
| `pq_ritos` | ícone da pesquisa: lápide com lírio e vela |

As peças em diagonal têm a âncora no meio da linha do pé (`integra.py ANCORA_NA_LINHA`). O nó fica no meio do
trecho.

## Save

Fica no `calendario`:
- `cemiterios`: retângulo, obra, pronto e covas com nome, dia, estação, causa, tipo, variante e vaga;
- `corpos`: os que esperam e o que o padre carregava, que volta para o chão.

O funeral ganhou `onde`, e o morale ganhou `funeral_left`. Save antigo: sem cemitério e sem corpos.

## Testes

`b93_cemiterio` passa (0 falhas). Também passaram depois: b88 (ajustado: o funeral precisa da pesquisa), b77 (a ferramenta de marcar área generalizada) e b36 (morte de guarda).

## Fotos

`docs/arte/bloco93/` (`tests/capturas_bloco93.gd`):
- `evolucao_obra` (as 4 etapas juntas): `obra_1_estacas`, `obra_2_postes`, `obra_3_cerca`;
- `pronto_vazio`;
- `padre_levando`;
- `com_tumulos`;
- `menu_culto`.
