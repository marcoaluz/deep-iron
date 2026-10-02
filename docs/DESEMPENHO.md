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
