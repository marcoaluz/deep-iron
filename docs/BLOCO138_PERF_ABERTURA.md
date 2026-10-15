# Bloco 138 — Performance de abertura, a trava do "pular" e o jogo que "fechava" ao construir

Pedido do Marco: o "Bloco 73". Esse número já existe; o último era o 137, então este virou o **138**, com o teste do
mesmo número. Branch `perf-abertura`, criado a partir do `isometrico`, com um commit por correção. Teste
`tests/blocos/b138_perf_abertura.gd` (28 OK; registrado no GUT). Não mexi em arte, gameplay nem balanceamento.

Máquina: i3-8100 (4 núcleos), 16 GB de RAM, Radeon RX 580 de 4 GB, Godot 4.7.2 com Forward+/D3D12.
- **C:** SSD de 120 GB com **7,1 GB livres**. Aqui ficam o `user://` e os logs.
- **D:** **HDD** de 1 TB. Aqui fica o projeto.

## Passo 0 — o diagnóstico (aprovado pelo Marco: "pode implementar")

### O "fechou ao construir"

**A causa:** um erro de script em `guia.gd:338`, não um crash.
- A linha era `if a is Control and not is_instance_valid(a)`. O `is` rodava num objeto já liberado ANTES da conferência.
- As setas do guia do primeiro dia são redesenhadas a cada quadro, mas a lista de alvos só é refeita a cada 0,25 s.
- Quando o CONSTRUIR troca de aba (`_show_tab` libera os cartões), a seta fica apontando pra um cartão liberado.
- Rodando pelo editor, o erro de script **pausa o jogo no debugger** e a janela embutida dá lugar ao editor. Parecia que o
  jogo tinha fechado.

**As evidências:**
- O último log do jogo (14/10, 13:00–13:02) termina exatamente nesse erro, 2 minutos depois de uma partida nova.
- Reproduzi o mesmo erro num script isolado.

**O que não era a causa:**
- Teste de estresse com janela e navegação assíncrona: 52 prédios e 140 decorações postos e 20 bakes, sem crash; o pior
  movimento do fantasma levou 15,7 ms. O posicionador e a navegação não são o problema.
- Houve UM crash nativo de verdade, em 12/10 13:31 (`0xc0000374`, heap corruption em ntdll). Não há dump, e o relatório do
  Windows exige admin. **Não foi reproduzido.**
- No mesmo log havia 9484 erros `set_frame out of bounds` vindos do rato, do morcego e da sombra (folha de um quadro só),
  um por quadro. No editor, essa enxurrada enche o debugger.

### A trava do "pular"

`intro_terminou` chamava `change_scene_to_file(main.tscn)`, que carrega a cena inteira, com os scripts e os `preload`,
de forma SÍNCRONA no mesmo quadro. A tela de carregamento nem chegava a ser desenhada.

### A abertura lenta

Medi com o profiler local do Godot (`-d --profiling`) e com janela (scripts em `scratchpad/diag`, fora do repositório).
- **No primeiro quadro da partida:**
  - o terreno da vista iso: `_em_blocos` chamava `tex.get_image()` nas 45 texturas, lendo-as de volta da VRAM a cada
    abertura (0,75 s), mais o `load` delas (0,66 s);
  - o HUD montando as 34 janelas (0,6 s).
- **No segundo quadro:** o bake SÍNCRONO da navegação no `environment._ready` (1,24 s). Ele é jogado fora, porque a
  fundação e o save refazem a malha logo depois.
- **No boot:** `audio_slots.arquivos` fazia até 27 `ResourceLoader.exists` por slot (0,4 s).
- **Na primeira abertura com o disco frio:** são 7611 PNGs importados lidos do HDD.

## O que mudou

1. **`guia.gd`:** os alvos liberados saem da lista ANTES do `is` (pelo `typeof`).
   - **`house_placer.begin`:** textura nula vira a da casa, `hframes` 0 vira 1, e sem ação de confirmar não começa; cada um
     desses casos vira `push_warning`, nunca erro.
   - **`creature.gd`:** a criatura de um quadro só não pede o quadro 1.
2. **`environment._build_navigation`:** a 1ª malha vai pelo pedido agrupado do Bloco 131.
   - No jogo, sai fora do quadro e se junta ao pedido da fundação ou do save.
   - Em headless continua síncrona.
3. **Terreno:** `prototipos/camera/arte_iso/mapa/blocos.py` grava `assets/game/iso/mapa/blocos.json` com os blocos não
   vazios de cada PNG (45 imagens, 938 blocos).
   - O `monta.py exporta` e o `andares.py` já chamam o script no fim.
   - O `iso_view._em_blocos` usa a lista (`IsoView.blocos_guardados`). Se a imagem não está lá, ou mudou de tamanho, cai no
     jeito antigo.
   - O b138 confere que a lista bate com os PNGs. **Mudou um PNG do terreno? Rode `python blocos.py`.**
4. **`audio_slots.arquivos`:** um índice por pasta (`ResourceLoader.list_directory`, uma vez; vale no jogo exportado).
   O `limpa_cache` esquece o índice.
5. **Carregamento em segundo plano:**
   - `SaveManager._vai_pra_partida` substitui os três `change_scene_to_file(MAIN_SCENE)`: partida nova, carregar save e a
     intro "ver".
   - `Carregando.troca_quando_pronto` pede `main.tscn` com `load_threaded_request`, mostra a barra e troca com
     `change_scene_to_packed` quando tudo chega. Se o pedido falha, cai no `change_scene_to_file` de antes.
   - A intro já pede a partida e as 45 texturas do terreno assim que começa (`pre_carrega_partida`).
   - A tela some quando a partida ASSENTA (8 quadros curtos seguidos, no máximo 12 s), não depois de 1 s fixo.
   - Em headless continua síncrono; o teste liga `SaveManager.carregamento_assincrono_forcado`.

**Não feito:**
- **Janelas do HUD criadas sob demanda:** o `_panels` é usado em 26 lugares e o menu "Janelas" consulta todas. O ganho seria
  0,45 s, e esse tempo já fica escondido pela tela de carregamento.
- **Compressão das texturas do mapa na VRAM** (326 MB, o item 4 do relatório): ficou de fora; o Marco aprovou só os itens
  1 a 3.
- **Chunks/streaming e navegação por região:** o posicionador não era o gargalo.

## Antes x depois (com janela, RX 580, 1280x720)

| Etapa | Antes | Depois |
|---|---|---|
| "Pular": a janela congelada | **5,7 s** (20,8 s na 1ª abertura fria) | **7 ms** (a janela responde; tela com barra) |
| Pular logo no começo da intro → partida estável | 12,1 s | 8,4 s, sendo 7,0 s de carregamento com a janela respondendo |
| Pular depois de ~10 s de intro → partida estável | 12,1 s | **2,7 s** (a partida carregou durante a intro) |
| Quadros longos depois da troca (debaixo da tela) | 3,4 s + 2,5 s | 1,2 s + 0,9 s |
| Até o menu jogável (quente) | 2,8 s | 2,5 s |
| Boot (motor + autoloads, quente) | 1,5 s | 1,3–1,4 s |
| Sem cache de shader: pular → estável | — | 9,3 s (o pular volta em 8 ms) |
| Vila inicial | 75 FPS | 75 FPS |
| Vila cheia à noite / hora social (`bench_picos`) | 44 / 47 FPS (commit base, medido agora) | 44 / 48 FPS |
| RAM / VRAM na partida | 294 MB / 824 MB | 293 MB / 749–804 MB |

- **A 1ª abertura com o disco frio (15 s até o menu)** vem do HDD. Não dá pra repetir sem esvaziar o cache de arquivos do
  Windows, o que exige admin.
- **O alvo de "≥ 46 FPS na vila cheia"** vinha do Bloco 53/69. A vila cheia à noite já dava 44 no Bloco 131 e continua 44:
  este bloco não mexeu no custo por quadro.

## Conferido

- **Testes um por um, 0 falhas:** b138 e os dos sistemas mexidos:
  - b112 e b129 (intro, guia, save);
  - b131 (navegação);
  - b114, b115, b116, b117, b118 e b121 (som);
  - b124 (criaturas);
  - b130, b132 e b134 (terreno e grade);
  - p28_iso e p28_save.
- **Save antigo:** o backup de 14/10 (dia 62, 12 ipezinhos), copiado pra pasta falsa, carrega pelo caminho novo. O md5 da
  cópia ficou igual.
- **Build:** exportado e com o teste de fumaça OK (28 s; o save real não foi tocado). O `tools/build_windows.ps1` para no
  stderr do Godot, porque o PowerShell 5.1 trata o stderr como erro; rodei a fumaça à mão. Esse problema já existia e não foi
  corrigido aqui.
- **A suíte GUT inteira NÃO foi conferida:** a rodada em segundo plano foi derrubada pelo sistema por falta de memória (16 GB, só 2,4 GB livres). Rodaram só os 20 testes listados acima, um por vez. Falta rodar `tools/run_tests.sh` em primeiro plano, com pouca coisa aberta.
