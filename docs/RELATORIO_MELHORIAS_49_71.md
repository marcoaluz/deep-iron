# Relatório — documento de melhorias (Blocos 49–71 + itens de arte)

Data: 2026-10-02. Branch `isometrico`. Documento: `deep-iron-prompts-melhorias.md`. Um commit por bloco
(`bloco-NN: ...`); cada bloco tem teste em `project.godot/tests/blocos/` e linha no `TESTING.md`.

## O que foi feito

| Bloco | O quê | Commit | Onde ler |
|---|---|---|---|
| 49 | Saúde do repositório (LFS pros binários novos) | `83a46f04` | `.gitattributes` |
| 50 | Export, build do Windows + teste de fumaça, script único de testes | `6942d233` | `TESTING.md` |
| 51 | Vigia do engenheiro preso a caminho + teste de estresse | `0fd2f6e4` | `b51_engenheiro_estresse.gd` |
| 52 | Painel de debug (F3), telemetria em CSV, lista de balanceamento | `a0521f22` | `docs/BALANCEAMENTO.md` |
| 53 | Passe de desempenho (vila cheia 39 → 56 FPS na época) | `08f1b78f` | `docs/DESEMPENHO.md` |
| 54 | Configurações, acessibilidade, teclas, base de idioma | `bb708cf7` | `docs/IDIOMAS.md` |
| 55 | Passe de áudio | `a0906bbc` | `docs/AUDIO.md` |
| 56 | Casas nível 2 e 3 | `1ebb71c0` | — |
| 57 | Coletor de minério | `2efb1c73` | — |
| 58 | Oficina construível | `7c0c45ec` | — |
| 59 | (já estava feito: a Rota A / vista iso) | — | — |
| 60 | Pesquisas: dinamite e rádio | `f6175fba` | — |
| 61 | Fauna com gameplay | `82c357c2` | — |
| 62 | Invasores: tiers, elite e o chefe (Matriarca, arte nova) | `073834a4` | — |
| 63 | Corte da mina (F2): galerias, reatores, legenda | `2fa9c060` | — |
| 64 | Trilho e vagonete | `29a4ff4c` | — |
| 65 | **Escola e crianças — espera decisão sua** (abaixo) | — | — |
| 66 | Tutorial — adiado pelo próprio documento | — | — |
| 67 | Mapa ~2,9× pro leste (trancado até desbravar) | `6c4e00a0` | `docs/MAPA_LESTE.md` |
| 68 | Níveis temáticos por dados (`data/niveis/*.tres`) + viagem nas gaiolas | `3639229b` | — |
| 69 | Camadas de desenho + atmosfera por nível | `0cee8431` | `docs/arte/CAMADAS.md` |
| 70 | S2 (ácido) e S3 (lava): poças, cristal verde/rubro, ventilador, Gosma e Magmante | `d1ff09b0`, `8cb96ab3` | `docs/NIVEIS_S2_S3.md` |
| 71 | S4 (cachoeira e lava) e S5 (lago azul) jogáveis por dados | `d1a32f6d` | `docs/NIVEIS_S4_S5.md` |
| — | Itens de arte novos (vila antiga do leste, passarelas, ponte, rampa, rocha com ácido, borda do lago) | `e4d775c8` | `docs/NIVEIS_S4_S5.md` |

## Pra você decidir / revisar

1. **Bloco 65 — crianças.** O documento pede a decisão antes do código. Opções:
   - **A. Só visual**: crianças andando pela vila (sem comer, sem trabalhar). Barato; dá vida à vila.
   - **B. População que cresce**: nascem com casa com cama sobrando + ânimo alto, comem, vão à escola e
     viram trabalhadores depois de N dias. Mexe em comida, moradia e ânimo (balanceamento).
   - **C. Nada por enquanto**: a escola continua "em breve" no menu.
   Arte nos dois primeiros: 1–2 crianças (personagem + andar) e a escola (prédio com obra).
2. **Arte nova dos blocos 70/71** (relatórios de cada um têm as fotos e os números): Gosma e Magmante,
   poças, cristais, ventilador, pisos do S4/S5, cachoeira, casinhas, vila antiga. Fora da faixa de brilho
   do contrato, de propósito: lava (0,40–0,43, é a luz do nível) e a Gosma (0,31, o acento ácido). A
   morte da Gosma é por script (o PixelLab não derreteu em duas tentativas).
3. **Balanceamento novo** (tudo em `@export`): preços (cristal verde 10, rubro 18, gema 30), o tempo
   pra queimar (ácido 5 s, lava 2,5 s), as ondas da Gosma (onda 2+) e do Magmante (onda 3+), o custo
   das plataformas do S4/S5. Nada foi jogado de ponta a ponta numa partida longa.
4. Os pontos dos Prompts 16–26 que já estavam no CONTEXTO (forma forte das criaturas, fonte pixel só em
   cabeçalhos, controle de velocidade, faixa de acidente) continuam valendo.

## Testes, save e build

- **Suíte inteira (GUT, 65 testes, 23,5 min):** 64 passaram. A que falhou (`p20_interface`: "4 andares
  empilhados") era o teste desatualizado pelo Bloco 71 (o corte agora tem 6 andares); corrigido e
  rodado de novo: passa. A rodada foi pelo `tools/run_tests.sh`; o Claude Code encerrou o shell que
  envolvia a suíte por falta de memória no sistema perto do fim, mas o Godot dos testes terminou a
  rodada e o log ficou completo (`%TEMP%/deep_iron_testes/gut_ultimo.log`).
- **Save real:** intacto — última gravação 15:57 (antes de todas as rodadas de teste), md5
  `76C7403D5697DD29F90480757BEED3F0` igual antes e depois do build.
- **Build do Windows + fumaça** (`tools/build_windows.ps1`): `build/windows/DeepIron.exe` (pacote 36,3 MB,
  sem `tests/`); abre, começa partida, salva, carrega (3 ipezinhos), sem o painel de debug no release.
- **Desempenho** (`tools/bench_cena.ps1 -Rapido`, i3-8100 + RX 580, 1920×1080 sem vsync), vila cheia
  com invasão, chuva e noite: **21,75 ms / 46 FPS** (8.451 nós). Depois do Bloco 69 eram 19,9 ms / 50 FPS
  (7.892 nós): o conteúdo do S2–S5 custou ~1,9 ms. A medida foi feita com o editor do Godot e o Chrome
  abertos e pouca memória livre. Próximo passe, se precisar: deixar parado (sem processar/desenhar) o
  conteúdo dos níveis ainda fechados, como o leste trancado já faz.

## PixelLab

Tier 3 (10.000 no ciclo, renova em 2026-11-02). Gasto nesta rodada (blocos 70, 71 e itens de arte):
~570 (saldo 9.888 → 9.320) gerações. Arte em `project.godot/prototipos/camera/arte_iso/fundo70`, `fundo71`,
`relevo/fundo71.py`, `criaturas/fundo.py`.
