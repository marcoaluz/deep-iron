# Bloco 80 — o portão único e o Ferrugento robô

O pedido veio como "Bloco 49". Esse número já existe no histórico (`bloco-49: saúde do repositório`), então
esta entrega virou o **Bloco 80**, o próximo livre, como está no CLAUDE.md.

**Skills usadas:** `godot-gdscript`, `save-systems`, `godot-gdscript-headless-testing`, `godot-nodes-scenes` e
`create-game-assets`.

## A) O portão do poço saiu

- **Cena:** o nó `BarricadaPoco` saiu de `scenes/game/main.tscn`. O único portão é o **da floresta**
  (`BarricadaTunel`, `gate_id "tunel"`).
- **`barricada.gd`:** `@export_enum("tunel")`.
- **`defense.gd`:**
  - **Nascimento:** Ferrugento, Gosma e Magmante nascem na **boca do poço do elevador** (`boca_poco()`) **sem
    barricada** (`setup(null, ...)`): entram direto. O `gate_id` deles é `""` (sem portão). O Ferrugento só
    aparece com o nível 2 aberto, como antes.
  - **`guard_post`:** os postos são o portão da floresta e, com o nível 2 aberto, um **posto na boca do
    poço**. É o `posto_poco()`, a `poco_post_dist` px (`@export`, 40) da boca, pro lado do armazém. Os guardas
    se dividem entre os dois.
  - **`nearest_gate_id`:** se o posto do poço estiver mais perto que qualquer portão, devolve `""`. Quem cai
    lá não abre brecha, então **a brecha só existe no portão da floresta**.
  - **`gate_label`:** "portão da floresta" e, pra `""`, "posto do poço".
  - `breached` e `raid` não mudaram: `breached("")` é sempre falso.
- **`defense_panel.gd`:** só a linha do portão da floresta (o laço `["tunel", "poco"]` e a checagem de
  `level2_open` do poço saíram). Entrou uma linha explicando o poço: sem muro, e metade dos guardas faz posto
  lá.
- **`ipezinho.gd`:** o aviso "GUARDA CAÍDO" só diz "o portão fica aberto pra roubo" quando há portão.
- **Save antigo** (documentado no cabeçalho do `save_manager.gd`):
  - `barricadas.BarricadaPoco` é ignorado. As barricadas são lidas pelo nome do nó, e o nó não existe mais.
  - `downed_gate: "poco"` vira `""`: guarda caído, mas sem brecha. O `ipezinho.gd` confere se o portão ainda
    existe.

## B) O Ferrugento é um robô

**Antes** era uma máquina-aranha com caçamba (`docs/arte/bloco80/antes_maquina.png`). **Agora** é um robô
pequeno e enferrujado no estilo exterminador: endoesqueleto de metal, crânio e olhos vermelhos. Ele anda, ataca
e rouba minério como antes. A arte é do **PixelLab**, que você liberou: personagem "pro" com o estilo do
Lumívoro, mais 5 animações. O gerador é `prototipos/camera/arte_iso/criaturas/ferrugento_robo.py`.

- **Imagens:**
  - `rotacoes_pixellab.png`: o personagem nas 8 direções.
  - `folha_pixellab.png`: a folha do jogo.
  - `ferrugento_no_jogo.png` e `ferrugento_andando.gif`: no jogo, ao lado de um guarda.
- **O primeiro placeholder** desenhado por código (`criaturas/ferrugento_placeholder.py`) ficou como referência
  do formato. O PNG dele saiu do jogo.

### O visual é configurável (pra trocar os sprites sem mexer na lógica)

`creature.gd` ganhou o grupo **"Visual (folha de quadros)"**. Uma folha tem uma **linha por animação**, com os
quadros da esquerda pra direita e o desenho virado pra direita (o jogo espelha pra esquerda):

| Campo | O quê | Ferrugento |
|---|---|---|
| `visual_textura` | a folha (vazia = a arte isométrica antiga do bonecos.json) | `assets/game/ferrugento_robo.png` |
| `visual_quadro` | tamanho de um quadro (px) | 90 × 87 |
| `visual_anims` | as animações, na ordem das linhas | parado, caminhada, atacar, dano, morrer |
| `visual_quadros` | quadros de cada animação | 4, 6, 6, 4, 6 |
| `visual_fps` | quadros por segundo | 10 |
| `visual_passada` | px andados por ciclo da caminhada (o pé não escorrega) | 40 |
| `visual_escala` | escala do desenho | 0,6667 (1 px da folha = 1 px de arte na vista iso) |
| `visual_pe` | px entre o pé e a borda de baixo do quadro | 6 |
| `visual_carga` / `visual_carga_pos` | o que ele leva quando rouba, e onde | pedaço de minério nas costas |

Pra encaixar outros sprites, trocar esses campos no nó raiz de `scenes/creatures/ferrugento.tscn`. A animação
segue o estado: morrer, desligar ao amanhecer, dano, atacar, caminhada pela distância andada, parado. A vista
iso desenha a folha pelo espelho (`iso_bonecos.criatura_pose` devolve `{}` pra quem tem folha própria), e o
corte da mina (F2) usa o primeiro quadro dela. Qualquer outra criatura pode usar o mesmo esquema.

### Textos

Atualizados:
- o diário (página "Ferrugentos");
- a janela do robô antigo ("robô de antes da explosão");
- a dica da tela de carregamento (o poço não tem muro, ponha guardas lá);
- os comentários de `creature.gd`, `defense.gd` e `barricada.gd`.

## Testes

- **`b80_portao_unico_ferrugento.gd` (novo):**
  - não existe portão do poço;
  - a invasão funciona sem ele, antes e depois do nível 2;
  - os postos ficam no portão da floresta e na boca do poço;
  - o Ferrugento e a Gosma nascem na boca do poço, entram direto e não têm portão;
  - o visual troca pela folha de quadros (atacar, caminhada);
  - a brecha só abre no portão da floresta;
  - um save antigo com `BarricadaPoco` e `downed_gate "poco"` carrega sem erro.
- **Ajustados:**
  - `b70_fundo` (a Gosma sai do poço sem portão);
  - `p17_criaturas` (o Ferrugento não usa mais a arte de máquina; confere a folha, a carga nas costas e o
    "desliga" ao amanhecer).
- **Passaram:** b35, b36, b70, p17, b62, b74, b63, b47 e p18, rodados sozinhos.
- **Bateria inteira: interrompida.** O Claude Code encerrou a rodada por falta de memória no sistema, não por
  falha. Antes disso, **42 de 63** rodaram e todos passaram.
- **Não conferidos depois da mudança (17):** b37, b38, b39, b40, b41, b42, b54, b55, b56, b57, b58, b60, b61,
  b64, b67, b68 e b69. Nenhum deles mexe em portão, Ferrugento ou visual de criatura, mas não foram rodados.

## Pontos de atenção

- **Tamanho:** o robô ficou um pouco menor que um ipezinho. Pra deixar menor, é só mudar `visual_escala` na
  cena (0,5 já fica bem menor; fora de 1:1 os pixels ficam um pouco irregulares).
- **Direção:** a folha tem **uma direção** (SE), espelhada pra esquerda. Andando "pra cima" (NE/NO) ele
  continua de frente. Se quiser as 4 direções, o personagem já existe no PixelLab (id em `ferrugento_robo.json`)
  e dá pra gerar a direção NE.
- A arte antiga de máquina continua nos arquivos (`assets/game/iso/bonecos/criatura_ferrugento*`), mas o jogo
  não usa mais.
