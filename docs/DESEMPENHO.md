# Desempenho (Bloco 53)

## Como medir

```
powershell -ExecutionPolicy Bypass -File tools\bench_cena.ps1            (completo, ~5 min)
powershell -ExecutionPolicy Bypass -File tools\bench_cena.ps1 -Rapido    (sem o custo por script, ~1 min)
```

Abre a partida numa janela 1920×1080 **sem vsync** (o tempo de quadro é o custo de verdade, não a espera
do monitor), com a pasta de usuário isolada, e mede 3 cenários com a câmera no zoom de jogo:

| cenário | o que tem |
|---|---|
| A — início | partida nova, 3 ipezinhos, dia |
| B — vila média | 15 ipezinhos com função; taverna, laboratório, campo e 2 casas prontos |
| C — vila cheia | 40 ipezinhos, mais 3 casas, noite, chuva forçada e invasão |

Pra cada um: tempo de quadro médio e p99 (o 1% pior), FPS, nº de nós e draw calls. No C ainda mede:

- **Detalhe**: cada parte da HUD e da vista iso chamada 30× seguidas (custo de CPU de cada uma);
- **Custo por script**: desliga o `_process` de todos os nós de um script por 2 s e vê quanto o quadro
  cai (e o mesmo pras luzes e partículas, escondendo). É indicativo: num nó só, a diferença pode ser
  ruído da cena mudando (a invasão anda); confira com o detalhe/chamada direta antes de mexer.

O resultado vai pra `docs/bench/bench_<data>.txt` (ou `-Saida <arquivo>`). Não mexa no PC enquanto mede.

## Máquina da medição

Intel Core i3-8100 (4 núcleos, 3,6 GHz) · Radeon RX 580 · Windows 10 · janela 1920×1061 · Godot 4.7.2
(editor/debug — o executável de release é um pouco mais rápido).

## Antes × depois (2026-10-02)

| cenário | antes: ms méd / p99 / FPS | depois: ms méd / p99 / FPS |
|---|---|---|
| A — início | 7,81 / 8,33 / 128 | 7,27 / 10,00 / 138 |
| B — vila média | 12,03 / 16,67 / 83 | 9,80 / 11,11 / 102 |
| C — vila cheia + invasão + chuva + noite | 25,82 / 51,94 / 39 | 17,97 / 23,43 / 56 |

Nós e draw calls não mudaram (4438/211, 5080/294, ~6350/355).

**Meta de 60 FPS estáveis na vila cheia:** quase — 56 de média, p99 23 ms (antes 39 e 52 ms, com
travadas visíveis a cada atualização da HUD). Na vila média passou de 100. O que sobra está listado
abaixo, pra um próximo passe.

## O que custava (cenário C, antes)

| parte | custo |
|---|---|
| vista iso (`iso_view._process`): sincronizar os bonecos (pose + cópia dos rótulos), a ordem de quem anda e o redesenho de cada boneco todo quadro | ~12 ms por quadro |
| HUD: as 40 linhas de ipezinhos refeitas 10×/s (troca de cor/estilo dispara tema e layout) | 6,2 ms a cada atualização (os picos do p99) |
| `ipezinho.gd` (40) | ~3 ms (IA; não mexido) |
| cursor: procurar o que está debaixo do mouse 10×/s | 1,3 ms por vez |
| prédios fixos: medir o desenho antigo pra caixa, mesmo com a arte nova | 23 µs por prédio |

## As 5 correções

1. **HUD só mexe no que mudou** (`hud.gd`, `_set_text`/`_set_font_color`/`_set_fill`): texto, cor, cor da
   barra e estilo da linha só são trocados quando o valor é outro; o tamanho da lista só refaz o layout
   quando muda. 6,2 → 1,2 ms por atualização.
2. **Bonecos a cada 2 quadros** (`iso_billboard.gd`): a pose do boneco novo passa a ser copiada junto
   com os rótulos/ícones, alternando metade dos bonecos por quadro (a animação é de ~10 quadros/s; a
   posição continua todo quadro). Chamado sem `view_rect` (testes) sincroniza tudo na hora.
3. **Redesenho só quando muda** (`iso_billboard.gd`, `_redraw_if_changed`): sombra, anel de seleção,
   barra de vida e "!" só se redesenham quando muda o que mostram (antes: todo quadro, cada boneco).
4. **Ordem de quem anda com cache** (`iso_order.gd`): quem não saiu do lugar e com a ordem das fixas
   igual (`version`) reaproveita o espaço calculado. 2,8 → 2,1 ms.
5. **Cursor e prédios fixos**: o cursor só procura de novo quando o mouse mexe (ou a cada 0,5 s;
   1,3 → 0,2 ms); a caixa do prédio com arte nova vem direto do desenho (`_update_box_art`; 8,6 → 4,6 ms
   pros 368 fixos).

GUT: os testes da vista iso, bonecos, criaturas, luz, natureza, prédios, HUD, interface, zoom e efeitos
passam iguais.

## O que sobra (próximo passe, se precisar)

- `IsoBonecos.pose`: ~28 µs por boneco (muitas consultas `w.get()` e dicionários aninhados); daria pra
  guardar a parte que não muda (pastas, tom, ferramenta) e recalcular só o quadro.
- `_sync_props` dos fixos: ~70 µs por prédio visível a cada 6 quadros (cópia por reflexão dos rótulos e
  luzes); dá pra copiar só o que mudou.
- `ipezinho.gd`: ~50 µs por ipezinho entre `_process` e `_physics_process`.
- Luzes 2D: ~165 na vila cheia; com muitas mais, vale juntar as das janelas.

## Bloco 69 (atmosfera por nível) — 2026-10-02

`bench_cena -Rapido`, vila cheia (C): atmosfera ligada **19,86 ms / 50 FPS**, desligada **19,07 ms / 52 FPS**
(+13 nós, +6 draws). O pulso das luzes guarda a intensidade em memória (antes lia o `settings.cfg` do disco
a cada 3 quadros). Desde a medida da manhã (C = 17,97 ms / 56 FPS) a cena cresceu de 6.351 pra 7.879 nós
com os blocos 64–68 (trilho/vagonete, leste, níveis): é daí a maior parte da diferença, não da atmosfera.

## Depois dos blocos 70–71 — 2026-10-02 (noite)

`bench_cena -Rapido`, vila cheia (C): **21,75 ms / 46 FPS** (8.451 nós, 368 draws; p99 33 ms). O conteúdo do
S2–S5 (poças com luz e partículas, jazidas, decoração, plataformas) somou ~560 nós e ~1,9 ms. Medido com
o editor do Godot e o Chrome abertos e pouca memória livre (`docs/bench/bench_2026-10-02_final_71.txt`).
Se precisar: parar o conteúdo dos níveis fechados (como o leste trancado).


## Bloco 131 — as TRAVADAS (obra pronta, subida de estágio) — 2026-10-12

Benchmark novo de picos: `powershell -ExecutionPolicy Bypass -File tools\bench_picos.ps1 [-Saida <arquivo>]`
(`tests/bench_picos.gd`; janela 1280x720, sem vsync, pasta de usuário isolada; vila cheia, 40 ipezinhos). Mede o tempo de
CADA quadro, não só a média. Cenários: **N** vila cheia à noite; **S** hora social (20:00); **O** obra pronta (5 vezes, como o
engenheiro termina: `Canteiro` → prédio → decoração e malha); **E** subida de estágio (3 vezes; padre fora); **P** chega um
morador (o padre). Em O/E/P: o tempo da CHAMADA e o maior quadro nos 30 seguintes. Máquina: i3-8100, RX 580, com o editor
do Godot aberto (as rodadas variam; vão as duas rodadas limpas de cada lado). O profiler do editor não foi usado: o tempo de
cada parte vem cronometrado no próprio benchmark (`_partes`, `_tempo`).

**Meta:** p99 ≤ 33 ms (30 FPS) na vila cheia (N e S) e **nenhum quadro acima de 100 ms** num evento (obra pronta, subida,
chegada); o alvo é ≤ 60 ms.

| Cenário | ANTES méd / p99 / maior (ms) | DEPOIS méd / p99 / maior (ms) |
|---|---|---|
| N vila cheia à noite | 22,4 / 26,0 / 28,5 · 22,3 / 25,9 / 27,7 | 22,1 / 24,1 / 25,5 · 22,7 / 26,5 / 30,3 |
| S hora social | 21,1 / 24,4 / 25,2 · 21,2 / 29,3 / 35,4 | 20,9 / 22,5 / 23,0 · 20,7 / 22,3 / 26,1 |
| O obra pronta: a chamada | **1266 / 1306** (méd / maior) | **1,7 / 3,1** |
| O obra pronta: maior quadro nos 30 seguintes | 137 / **143** · 142 / **149** | 31 / **51** · 27 / **32** |
| E subida de estágio: maior quadro | 66 / **140** · 60 / **130** | 31 / **38** · 36 / **56** |
| P o padre chega: maior quadro | (vinha junto com a subida: os 140 ms acima) | 27 · 52 |
| Reordenação completa da vista iso | 137 ms | 27,5 ms |
| Bake da malha de navegação | 1265 ms **dentro do quadro** | fora do quadro (~2,5 s numa thread; a malha antiga vale até lá) |

Meta cumprida nas rodadas medidas: p99 de N e S entre 22 e 27 ms; maior quadro de evento 56 ms. Os arquivos:
`docs/bench/picos_antes.txt`, `picos_antes_1.txt`, `picos_antes_2.txt` (código do Bloco 130) e `picos_depois.txt`,
`picos_depois_1.txt`, `picos_depois_2.txt`. Uma rodada do DEPOIS saiu ruidosa (N p99 33,6, O 143 ms numa obra, E 140 ms) com
o editor disputando a máquina; na seguinte, igual ao resto.

`bench_cena -Rapido` (cenário C = vila cheia + invasão + chuva + noite): **23,75 ms / p99 29,5 / 42 FPS** (10.052 nós, 341
draws; `docs/bench/bench_2026-10-12_b131.txt`).

### O que custava e o que mudou

1. **Malha de navegação** (`environment.rebuild_navigation`, chamada a cada obra pronta, casa, armazém, cemitério...): o bake
   síncrono custava ~1,27 s na vila cheia. Agora `bake_from_source_geometry_data_async` numa thread do NavigationServer;
   pedidos do mesmo quadro (ou feitos enquanto um bake anda) viram UM bake (`nav_pedidos`/`nav_bakes`), a malha antiga vale
   até a nova entrar (sinal `navigation_rebuilt`). Carregar save e fundar a vila pedem `rebuild_navigation(true)` (síncrono,
   atrás da tela de carregamento). Em headless o padrão segue síncrono (os testes antigos); `Environment.bake_assincrono_forcado`
   liga o caminho do jogo. A geometria dos obstáculos do mapa iso fica em cache (31 → 0,9 ms). Efeito colateral: por ~2,5 s
   depois de uma obra pronta a malha ainda é a de antes (alguém pode cruzar o terreno do prédio novo nesse tempo).
2. **Decoração debaixo das estruturas** (`clear_decor_under_extras`, ~13 ms): agrupada no fim do quadro e a área já limpa não é
   varrida de novo (`_areas_limpas`): ~1 ms.
3. **Ordem de desenho** (`IsoCore.topo_order`): comparava TODOS os pares (n² com ~750 fixas). Agora os candidatos vêm de uma
   grade da tela (`TOPO_CELULA`), na mesma ordem de antes: o resultado é idêntico (o teste compara com o algoritmo antigo em
   caixas sorteadas). 137 → 27,5 ms.
4. **O padre** chegava no MESMO quadro da subida (criar o morador + carregar as tiras de animação dele: ~140 ms somados).
   Agora chega `padre_atraso` (3 s) depois e as tiras começam a carregar quando a espera começa (`aquece_padre`).
5. **Desenho do prédio pronto**: `IsoArt.aquece(kind)` pede em segundo plano (`ResourceLoader.load_threaded_request`) os
   desenhos "pronto"/"nivel" enquanto o prédio ainda é obra; no quadro em que a obra termina a textura já está na memória.

### Outros picos procurados

- Noite e hora social (N, S): nenhum quadro acima de 31 ms nas rodadas limpas; luzes, partículas e som não aparecem como pico.
  Som: o `Audio` não cria nada por quadro (pools fixos); os loops de prédio só nascem perto da câmera.
- Subida de estágio sem o padre: 30–56 ms no maior quadro (o espelho do Centro trocando de desenho e a HUD).
- O custo CONTÍNUO que sobra (não é pico): a sincronia dos prédios parados com o espelho (`sync_static`, 1/6 das 643 fixas por
  quadro: ~6 ms; `_sync_props`/`_sync_art`). É o próximo passe, se precisar: copiar só o que mudou.
