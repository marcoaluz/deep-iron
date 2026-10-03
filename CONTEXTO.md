# Contexto do projeto (pra retomar em outra sessão/conta)

Atualizado em 2026-10-03 (manhã). Branch `isometrico`. O remoto está em `875ae827`: os commits do
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

**Etapa 2 da revisão FEITA (`f8d6c4d1`):** os andares no jogo são cavernas uma embaixo da outra,
debaixo da vila, com o poço do elevador reto (4 gaiolas na vertical da torre) e a espiral ao lado; terra
em volta da coluna. Gerador: `prototipos/camera/arte_iso/mapa/andares.py` (escala K=0,75, contorno da
caverna no `andares.json`); `environment.gd` (`view_ground`, `logic_from_view`, `contorno_do_andar`,
`dentro_da_caverna`, navegação pelo contorno); `iso_view.gd` (`_build_terra` lê terra/poço/espiral do
json; névoa no formato da caverna). Teste `tests/blocos/b72_coluna.gd`. Comparação com a referência:
`docs/arte/bloco72/coluna/comparativo.jpg`. Os saves valem (a lógica dos andares não mudou).
**O Marco conferiu e disse que ainda está muito diferente** (2026-10-03, tarde) e pediu: como resolver
(pode usar Blender e PixelLab), o layout do jogo mais perto da referência, e MAIS ESPAÇO NA VILA pra
construir. Diagnóstico: a referência é um corte de frente (andares = faixas largas e rasas, parede alta
cheia de coisa atrás, empilhadas sem vão); o jogo mostra chão visto de cima (losango), com vão escuro
grande entre andares e paredes lisas. Maquete da proposta no Blender (`prototipos/camera/arte_iso/
blender/coluna_maquete.py`, Blender em `D:/Blender/blender.exe`, roda com `-b -P ... -- <saida.png>`):
`docs/arte/bloco72/maquete/coluna_blender.png` e `comparativo_maquete.jpg`. Plano proposto: andares
viram faixas (chão andável = polígono da faixa na lógica, conteúdo remapeado), arte de cada andar
renderizada no Blender na câmera do jogo + detalhe/pixelização no PixelLab; vila: juntar terraços e
recuar a paliçada.

**O Marco APROVOU a direção da maquete** ("aí sim o mapa tá ficando exatamente como a gente tá querendo")
e pediu a superfície em 3 áreas: floresta | vila (só construção, mais espaço, sem jazida dentro) | uma
área de MINA pequena: montanha com a boca da mina, os minérios iniciais nela; o mineiro muda de função e
põe o minério num vagonete que corre no trilho, sozinho, da boca da mina até o armazém (que fica logo na
frente). Os andares de baixo continuam como na maquete. **Maquete v2 feita** (`coluna_maquete.py`):
`docs/arte/bloco72/maquete/coluna_v2.png`, `superficie_v2_legenda.jpg` (com nomes), `comparativo_v2.jpg`.
Na v2 o poço do elevador foi pra X=34 e as salas acabam em X=31 (abre lugar pra mina à direita).
Minérios na montanha: carvão, cobre e ferro (hoje as jazidas iniciais do jogo são cobre e carvão; o
ferro está no leste) — confirmar com ele. **Esperando o ok do Marco na v2** pra começar a passar pro
jogo (ordem proposta: vila/mina na superfície + vagonete; piloto do S3 jogável; os outros andares).
O que ainda falta (lista em `docs/BLOCO72_MAPA_REFERENCIA.md`, fim):
andares mais juntos (~24 degraus em vez de 36), faixa de galerias de madeira abaixo da superfície,
detalhe nas paredes (lampiões, lava escorrendo, cachoeira descendo, cristais), coluna mais larga
(escala 0,85?).

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
