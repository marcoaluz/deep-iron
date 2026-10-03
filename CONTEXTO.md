# Contexto do projeto (pra retomar em outra sessão/conta)

Atualizado em 2026-10-03 (madrugada). Branch `isometrico`. O remoto está em `875ae827`: os commits do
Bloco 72 abaixo ainda NÃO foram enviados (push só com ok do Marco).

## AGORA: Bloco 72 — o mapa do jogo igual à referência (em andamento)

Prompt: `Claude outputs/prompt_bloco72_mapa_vs_referencia.md`. Referência:
`docs/arte/referencia_mapa_mundo.jpg`. Relatório: `docs/BLOCO72_MAPA_REFERENCIA.md`.

**O que o Marco quer (palavras dele, 2026-10-03):** o mapa do JOGO (não só uma imagem) com a mesma
estrutura da referência, em escala maior pra jogar: em cima a floresta e a pedreira/vila; a mina descendo
de verdade; cada nível UM EMBAIXO DO OUTRO, DEBAIXO DA VILA (não lá no canto do mapa); forma orgânica de
caverna (nada de quadrado/reto); escada em espiral + elevador + andaimes ligando os níveis. Ele rejeitou a
etapa 4 (lajes retangulares dentro de um bloco de terra reto, com a coluna na ponta leste do mapa).
**Decisões dele (perguntadas):** modelo = imagem B do PixelLab (`docs/arte/bloco72/mapa_pixellab/quadrado.png`);
fazer AS DUAS coisas (a imagem como mapa do mundo F2 + reconstruir os andares no jogo nesse formato);
andares mais compactos (~25% menores por lado), mantendo todas as jazidas. Memória:
`project_bloco72_coluna.md`.

**Commits do Bloco 72:**
- `1a90cd90` passo 0: auditoria, fotos em `docs/arte/bloco72/antes/`. `tests/capturas_bloco72.gd` tira
  fotos + medidas de 13 vistas (rodar COM janela e APPDATA isolado: `-- <pasta de saída>`).
- `e89b6e67` (1) densidade: 51 objetos do Prompt 14 registrados; `NivelMina.decoracao_sorteada`.
- `ac8178be` (2) atmosfera por andar. `172079ab` (3) desempenho (vila cheia ~50 FPS).
- `f3a19d64` (4) terra + paredes subindo + espiral. **Rejeitado na forma** pelo Marco: a ideia das paredes
  subindo e da espiral continua; mudam o lugar (debaixo da vila) e o formato (caverna orgânica).
- `e394ccdd` (5) piloto: faixas S4/S5 do corte + rio de lava (`NivelMina.decalques`). Ficou sem aprovação
  formal (o Marco passou direto pra estrutura).
- `9cb3b514` teste do PixelLab: 2 versões do mapa da referência no estilo do jogo (80 gerações).
- `515b5bfa` **mapa do mundo (F2) = a imagem B** (`assets/game/ui/corte/mapa_mundo.png`;
  `NivelMina.mapa_regiao` = região de cada nível na imagem; lista dos andares ao lado; b63/p20 passam).

**PRÓXIMO — etapa 2 da revisão: reconstruir os andares NA VISTA DO JOGO (nada começado no código).**
Plano já calculado. Só a vista muda: a lógica dos andares continua em retângulos (deep_rect, abyss_rect,
`rect` do .tres), então os saves continuam valendo.
1. `prototipos/camera/arte_iso/mapa/andares.py` (gera `assets/game/iso/mapa/andar_*.png` + `andares.json`):
   trocar o ancoramento no "canto da frente do mapa" por:
   - escala `K = 0.75` em cada andar (px de arte por px da lógica = 1,5 x K);
   - a beira da frente do andar (v=+1) na face sul do mapa: `FACE_AY = OY + NJ*T = 648` (arte), então
     `centro_ay = 648 - hh` (hw, hh = meia largura/altura do andar em arte);
   - a gaiola de cada andar (posição normalizada u=0.86, v=-0.80) na MESMA vertical da torre do elevador
     da superfície (elevador em (580,320) da lógica → `ax - ay = 390` em arte), então
     `centro_ax = centro_ay + 390 - (u*hw - v*hh)`. Assim a coluna fica entre a escavadeira e o elevador,
     debaixo da vila, e não sobrepõe a superfície na tela (conferido nas contas);
   - profundidade (degraus k): nível2 -32, abismo -68, s4 -104, s5 -140 (36 degraus entre andares);
   - chão ORGÂNICO: superelipse p=4 com ruído no raio (R ~0,86..0,94), unida a um círculo em volta da
     gaiola. Ladrilho dentro = chão (zonas, água, ácido como hoje, pela lógica nova). Fora e "atrás"
     (u+v<0.2, numa faixa de ~0,25 além da borda; nada no canto da gaiola u>0.75,v<-0.55) = coluna de
     rocha subindo até a laje do andar de cima (`kc_acima - laje`); o nível2 sobe até a borda de baixo da
     superfície (o recorte de hoje, `borda_de_baixo(x, 0, 0, SUP_KB)`). Fora e na frente = vazio. Chão
     com vizinho da frente vazio ganha a laje embaixo;
   - escrever no json por andar: `centro_arte`, `k`, `contorno` (polígono da caverna na LÓGICA, ~48
     pontos), além de img/tela/rect/z_chao/caixa/z.
2. `scripts/core/environment.gd`: `view_ground` = `(pos - rect.center)*f*k + centro_arte`;
   `logic_from_view` = o inverso; navegação dos andares pelo `contorno` (não mais o retângulo);
   `_deep_spot_free` e a decoração só dentro do contorno; sem as pedras da borda do retângulo
   (`_build_deep`, `_build_abyss`) no mapa novo.
3. `scripts/iso/iso_view.gd`: `art_rect` dos andares e o decalque `ChaoDoJogo` com escala `S*k`. Refazer
   `_build_terra` (hoje 2 placas retas, TerraSO/TerraSE): faixa fina de terra nas faces + um corpo de terra
   orgânico em volta da coluna, afinando no fundo (como a imagem B).
4. Posições na lógica pra alinhar o poço (cena `scenes/game/main.tscn` e os `.tres`):
   Elevador.bottom (482,762); ElevadorAbismo pos (381,917) bottom (413,1476); S4 `ligacao_topo` (298,1644)
   `ligacao_fundo` (378,2172); S5 topo (299,2302) fundo (344,2808). Mover a decoração que conflitar
   (S4 `rampa_2`, S5 `casa_pedra_1`). Conferir que toda jazida/poça/zona/decoração fica dentro do `contorno`.
5. `mapa/espiral.py`: a espiral logo à direita da linha das gaiolas (gaiola + ~200 px), com trilhos do
   elevador do topo ao S5 e um patamar em cada gaiola.
6. Faixa de "galerias" (o nível 1 da imagem) na rocha entre a superfície e o nível 2 (peças `galeria_*`
   do Prompt 7), e a pedreira "descendo" até a boca do poço.
7. Fotos (`tests/capturas_bloco72.gd`) pro Marco conferir; teste novo `b72_*.gd`. Testes que tocam os
   andares: p28_iso, p29_mapa, b63, b67, b68, b69, b70, b71, p20. Rodar em partes: a suíte inteira
   estourou a memória uma vez.

## Antes do Bloco 72: o documento de melhorias (Blocos 49–71) está CONCLUÍDO
Feitos: 49–58, 60–64, 67–71 + itens de arte (59 já era feito; 65 crianças espera decisão do Marco, que
sugeriu deixar pra depois; 66 tutorial vem depois do balanceamento). Relatório final:
`docs/RELATORIO_MELHORIAS_49_71.md`. Fila sugerida pelo Marco depois do 72: balanceamento numa partida
longa simulada (F3 + telemetria), depois o tutorial (66).

## Ferramentas e cuidados
- PixelLab: tier 3, saldo ~9.200 (renova 2026-11-02). Esta conta chama o MCP HTTP pela config de
  `~/.claude.json` (`tools/pixellab/pl.py`, `gen.py` em lote, `chars.py` personagens). Arte nova em
  `prototipos/camera/arte_iso/` (fundo70, fundo71, fundo72, mapa_mundo, relevo/fundo71.py, criaturas/fundo.py).
- **`integra.py` regrava todos os PNGs** (pixels iguais, bytes diferentes). Depois de conferir, limpar com
  `git -c filter.lfs.process= -c filter.lfs.clean=cat -c filter.lfs.smudge=cat -c filter.lfs.required=false update-index --refresh`;
  os que já estão no LFS e continuam marcados: comparar os pixels e `git checkout --` neles.
- PNG/GIF/WAV/JPG vão pro Git LFS (`.gitattributes`). Imagem nova precisa de `--import` no Godot antes
  dos testes.
- Heredoc grande com aspas às vezes quebra no Bash desta máquina: gravar o script com a ferramenta de
  escrever arquivo e rodar com `python <arquivo>`.
- Testes: `tests/blocos/*.gd` (um por bloco, registrado em `tests/test_blocos.gd`, linha no TESTING.md);
  rodar sempre com APPDATA/XDG_DATA_HOME/LOCALAPPDATA em `%TEMP%\deep_iron_testes\fake_appdata`. O save
  real do Marco nunca pode mudar (md5 `76C7403D5697DD29F90480757BEED3F0`). Godot:
  `D:\DEV\Godot\Godot_v4.7.2-stable_win64.exe`. A tela lógica do jogo é 1280x720 (stretch canvas_items).
- Medidas: `tools/bench_cena.ps1 [-Rapido]` (vila cheia ~20 ms / 50 FPS em 2026-10-03).
- Skills do projeto: 21 em `.claude/skills/` (godot-*, game-feel, create-game-assets...).

Isso existe porque o Marco troca entre duas contas do Claude Code (`marco.luz1994@gmail.com` e
`marcoa.luz@hotmail.com`, essa via `claude-luz` com `CLAUDE_CONFIG_DIR` próprio) quando uma bate o limite.
A conversa não passa de uma pra outra: este arquivo é o resumo.

## Arte (pacote de prompts 0–31) — referência
- `docs/arte/CONTRATO_ARTE.md` (regras fixas de estilo), `docs/arte/INVENTARIO.md` (o que foi gerado e
  gasto), `docs/arte/MAPA_VISAO.md`, `docs/arte/promptNN/` (relatórios),
  `docs/Prompt/deep_iron_prompts_arte_completa.md`.
- Todos os prompts de arte 0–31 feitos. Como a arte entra no jogo: `prototipos/camera/arte_iso/integra.py`
  (`predios`, `bonecos`, `props`, `criaturas`, `fx`) → `assets/game/iso/...` com `.json`;
  `scripts/iso/iso_art.gd`, `iso_bonecos.gd` e `iso_billboard.gd` escolhem o desenho pelo estado do jogo.
- Andares de baixo na vista iso: `prototipos/camera/arte_iso/mapa/andares.py` (+ `espiral.py`) →
  `assets/game/iso/mapa/andar_*.png`, `espiral.png`, `andares.json`; lidos por `environment.gd`
  (`level_of`, `view_ground`, `logic_from_view`) e `iso_view.gd` (`_build_terrain`, `_build_terra`).
