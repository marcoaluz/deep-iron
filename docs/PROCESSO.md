# Processo de trabalho

## Blocos e prompts

- **Blocos** (código/jogo) são numerados (`docs/blocoNN/`, `deep-iron-prompts-melhorias.md` traz os
  49–71). **Prompts de arte** (0–31) estão em `docs/Prompt/deep_iron_prompts_arte_completa.md`,
  com um relatório por prompt em `docs/arte/promptNN/`.
- Formato de cada um: Contexto → Passo 0 (revisar e reportar antes de codar) → Implementar → Fora de
  escopo → Checklist.

## Commits e branches

- **Um commit por bloco**: `bloco-NN: resumo` (ou `prompt-NN: resumo` na arte).
- Mudanças grandes ou arriscadas (motor, mapa) em **branch própria**; a de trabalho hoje é
  `isometrico`, a principal é `main`.
- Antes de apagar/migrar algo, commit de checkpoint.
- Binários (PNG, GIF, WAV, OGG, MP3, PSD, Aseprite, TTF) vão pro **Git LFS** desde o Bloco 49 (só
  dali pra frente: o histórico antigo não foi reescrito). Quem clonar precisa do `git lfs install`.

## Testes antes de fechar um bloco

- A suíte GUT inteira (`tools/run_tests.ps1` / `.sh`) tem que continuar passando; teste novo pra
  o que o bloco cria (`tests/blocos/<id>.gd`, registrado em `tests/test_blocos.gd`).
- Os testes rodam com a pasta de usuário **isolada** e conferem o md5 do save real antes/depois.

## Onde ficam as ferramentas

| Ferramenta | Pra quê |
|---|---|
| `tools/run_tests.ps1`, `tools/run_tests.sh` | roda a suíte toda (headless, pasta isolada), sai ≠0 se falhar |
| `tools/build_windows.ps1` | exporta o executável Windows e faz o teste de fumaça |
| `tools/pixellab/` | ajudantes do PixelLab (`pl.py`, `gen.py`, `chars.py`); a chave vem do `~/.claude.json`, nunca do repo |
| `tools/contorno.py`, `tools/qa_arte.py` | contorno de 1 px e QA da arte |
| `tools/resumo_telemetria.py` | resumo dos CSV de telemetria (balanceamento) |
| `project.godot/prototipos/camera/arte_iso/integra.py` | leva a arte aprovada pro jogo |

## Arte em paralelo

A arte é gerada (PixelLab) e aprovada em `project.godot/prototipos/camera/arte_iso/` e só entra no
jogo pelo `integra.py`. O chat de jogo não mexe nessa pasta sem combinar.
