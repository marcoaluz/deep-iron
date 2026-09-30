# Prompt 13: máquinas e grandes estruturas

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/final_maquinas/`, montada por
`arte_iso/maquinas13.py`. Nada integrado ao jogo.

## Conferido no código

- **Escavadeira** (`escavadeira.gd`): peças estrutura, motor, hidráulica, cabine, broca;
  reatores vapor, diesel, cristal, solar, fusão.
- **Escudo solar** (`escudo.gd`): etapas fundação, bobinas, núcleo, emissor.
- **Elevador** e **Elevador do abismo** (`deep_shaft.gd`, `abyss_shaft.gd`): ruína → conserto →
  pronto.
- **Coletor de madeira**, **Coletor de minério** ("em breve"), **Satélite** e **Holofotes**
  (pesquisas).

## O que ficou pronto

| Máquina | Estados |
|---|---|
| **Escavadeira** = a "plataforma de perfuração" da visão do mapa | 5 etapas no mesmo lugar: 1 estrutura (convés + torre treliçada) → 2 motor → 3 hidráulica → 4 cabine → 5 broca (pronta); **animação perfurando** (a broca sobe e desce e a hélice "gira" em faixas) |
| **5 reatores** | caldeira a vapor, motor a diesel, cristal ressonante (ciano), núcleo solar (laranja), fusão improvisada (bobina de cobre). Ficam embaixo do convés. O pulso aceso é código. |
| **Elevador** | ruína (torre torta, roda caída, gaiola esmagada) → pronto (castelete, roda, cabos, gaiola, guincho); **gaiola como sprite separado**, pro código fazer subir e descer |
| **Elevador do abismo** | o mesmo desenho, mais escuro (ruína e pronto) |
| **Escudo solar** | 4 etapas do jogo: fundação (plataforma redonda com material) → bobinas (4 torres de cobre) → núcleo (gaiola com o cristal de solarita) → emissor (prato no mastro = pronto). A cúpula ligada é efeito do Prompt 18. |
| **Coletor de madeira** = a **máquina grande de cortar árvores** da visão do mapa | quebrada (enferrujada, musgo, vidro quebrado) → consertada (remendos, braço erguido com a serra) |
| **Coletor de minério** ("em breve") | pronto: esteira, funil, braço de caçambas, máquina a vapor |
| **Satélite** | 4 ângulos + GIF girando |
| **Holofote** | poste com holofote e gerador |

## Entregas (nesta pasta)

`prancha_escavadeira.png`, `escavadeira_perfurando.gif`, `prancha_escudo.png`,
`prancha_elevadores.png`, `prancha_coletores.png`, `prancha_reatores_satelite.png`,
`satelite_girando.gif`.

## Custo

**~330 gerações**.

## Técnica (economia)

As etapas da escavadeira e do escudo **não foram geradas uma a uma**:

- A IA fez o esqueleto da escavadeira e a fundação do escudo (por inpaint no próprio pronto).
- Cada etapa seguinte acrescenta a peça recortando a região dela do pronto
  (`escavadeira/regioes.json`, `ESCUDO` no script).
- As bobinas entram pela cor de cobre, pra não arrastar o núcleo que fica atrás.

## Desvios

1. **Guindaste/torre decorativa:** fica pro Prompt 14 (é o guindaste da pedreira, aceito na
   visão do mapa).
2. **Elevador subindo e descendo:** a arte é a gaiola separada. O movimento é código (hoje o
   jogo já usa NavigationLink no elevador).
3. **Coletores "operando":** sem animação desenhada. Tremor, fumaça e serra girando saem por
   código e efeito (Prompt 18).
4. **Elevador do abismo** = o mesmo desenho escurecido, não um desenho próprio.
5. **Etapa "broca" da escavadeira:** a diferença pro passo anterior é pequena (a broca fica
   dentro da torre). Lê melhor com a animação perfurando.
