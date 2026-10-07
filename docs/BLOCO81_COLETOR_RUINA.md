# Bloco 81 — o coletor de madeira em ruína

O pedido veio como "Bloco 50". Esse número já existe no histórico, então esta entrega virou o **Bloco 81**, o
próximo livre, e o teste é o `b81`.

**Skills usadas:**
- `godot-gdscript`
- `godot-nodes-scenes`
- `save-systems`
- `godot-gdscript-headless-testing`
- `survival-crafting` (restauração por etapas com custo)
- `create-game-assets` (camadas provisórias)

## O que mudou

O primeiro coletor de madeira **não se constrói mais**. Ele já está na floresta, em **ruína**: enferrujado e
coberto de folhas. O jogador o **restaura por etapas**, como as peças da Escavadeira e a plataforma do abismo
(ruína que vira máquina).

| Etapa | O quê | Custo (padrão) | Engenheiro |
|---|---|---|---|
| 0 | Ruína | — | — |
| 1 | Limpar folhas e entulho | 30 madeira (só madeira e tempo) | 25 s |
| 2 | Desenferrujar | 45 ferro | 35 s |
| 3 | Consertar caldeira e serra | 180 cr + 50 ferro | 45 s |
| 4 | Funcionando | libera designar o operador | — |

Tudo isso é `@export` no `coletor_madeira.gd`, no grupo "Restauração (Bloco 81)":
- `etapa_nomes`, `etapa_custo` (créditos, ferro, madeira), `etapa_segundos` e `etapa_estagio`;
- `etapa_estagio` é o estágio mínimo da vila de cada etapa, opcional (0 = qualquer);
- `fixo` e `etapa_inicial` dizem qual nó é a ruína da cena e em que etapa ela começa.

### Como funciona

- **Pedir e fazer:** o jogador **pede** a etapa (clicando na ruína: janela do coletor → "Pedir: …"), e o custo
  sai na hora. O **engenheiro** faz a etapa pela interface de obra (`obra_pending` / `obra_work` / `ObraSite`):
  - sem engenheiro, a etapa não anda;
  - quando fica pronta, a próxima espera ser pedida.
- **A janela** mostra todas as etapas, o progresso e o que falta:
  - `[feito]` para as já feitas;
  - `[agora]` com a porcentagem, para a que está em obra;
  - `[próxima]` com o custo e "falta: …", para a que vem a seguir;
  - `[depois]` para as outras.

  O botão diz o motivo quando não dá (falta recurso ou estágio da vila).
- **Na ruína:** não aceita operador, não produz e não solta fumaça.
- **Funcionando:** banner "COLETOR DE MADEIRA RESTAURADO!" e libera designar o lenhador.
- **Extras (Bloco 47):** o cartão "Coletor de madeira" do menu CONSTRUIR e o botão do Centro da Vila só
  aparecem **depois** que a ruína for restaurada. Os extras continuam pelo canteiro e já nascem funcionando.
  Como a ruína conta como o primeiro, o custo do extra já é o do segundo.

### Onde fica

- O nó **`ColetorMadeira`** está em `main.tscn`, em **(-420, 260)**, na parte sul da clareira, com
  `fixo = true` e `etapa_inicial = 0`.
- O lugar foi escolhido por varredura:
  - a mais de 250 px de árvores, tocas e horta (a árvore mais perto fica a 437 px);
  - navegável, com caminho do portão até a frente da máquina;
  - fora da trilha dos bichos.
- O engenheiro trabalha **na frente** da máquina, fora da pegada da arte (`IsoArt.front`), como nas outras
  obras.

### Visual provisório (pronto pra trocar)

A arte isométrica já tinha o desenho **"quebrado"** do coletor. Por cima dele entram camadas provisórias que
saem a cada etapa (`iso_art._coletor_madeira`):

| Etapas feitas | Desenho |
|---|---|
| 0 | quebrado com tom de ferrugem + **folhas** + **entulho**. Durante a limpeza, folhas e entulho somem aos poucos com o progresso. |
| 1 | quebrado com ferrugem. Durante a desferrugem, a ferrugem clareia e a máquina limpa aparece por cima, "fantasma que fica nítido". |
| 2 | a máquina limpa, mas apagada (cinza). Durante o conserto, ela acende. |
| 3 (funcionando) | o desenho pronto. |

- **Camadas:** `ruina_folhas.png` e `ruina_entulho.png` (mesmo quadro e mesma âncora do quebrado) são geradas
  por `prototipos/camera/arte_iso/coletor_ruina.py`. O `integra.py` as recoloca no `predios.json` se for
  rodado de novo.
- **Pra trocar por desenhos de verdade:** pôr os estados **`ruina_0` … `ruina_3`** (pelo número de etapas
  feitas) no `predios.json`. O jogo usa esses desenhos no lugar das camadas, sem mexer em código.
- **Vista de cima (a lógica 2D):** um tom de ferrugem no sprite.

Fotos no jogo: `docs/arte/bloco81/etapas.png`, com ruína, limpando, limpo, desenferrujando, desenferrujado e
funcionando.

## Save

- `centro_vila` "coletores": cada entrada ganhou `fixo`, `etapa`, `pago`, `progresso` (s de engenheiro) e
  `obra`. Está documentado no cabeçalho do `save_manager.gd`.
- **A ruína da cena fica** no load e recebe a etapa dela. Os extras são refeitos.
- **Save antigo com coletor construído** (sem `fixo`): o primeiro coletor **conta como restaurado**. A ruína vai
  para o lugar dele, com o total produzido, e os outros viram extras.
- **Save antigo sem coletor:** recebe a ruína, na etapa 0 e no lugar da cena.
- Obra de coletor (canteiro) pendente num save antigo termina como extra, porque já foi paga.

## Testes

- **`b81_coletor_ruina.gd` (novo, passa):**
  - a ruína na clareira, longe das árvores e navegável;
  - sem operador e sem extras;
  - o menu não mostra o coletor;
  - visual com folhas e entulho;
  - janela com as etapas e o que falta;
  - cada etapa gasta só o recurso dela (madeira / ferro / créditos e ferro);
  - sem engenheiro não anda;
  - as folhas somem com o progresso;
  - estágio mínimo;
  - save no meio de uma etapa;
  - funcionando: aceita operador, produz e libera extras;
  - os dois saves antigos.
- **Ajustados:**
  - `b45_coletor_madeira`: restaura a ruína e testa construir e operar com o segundo coletor;
  - `b47_varios_predios`: o primeiro é a ruína, o segundo é construído.
- **Passaram:** b81, b45, b47, p29 e b39.
