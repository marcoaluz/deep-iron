# Skills de arte instaladas no projeto

Instaladas em 2026-10-07, no nível do projeto (`.claude/skills/`), por cópia manual dos arquivos
auditados (sem `npx` e sem `-g`: os comandos dos próprios repositórios instalam global ou em `.agents/`).

**Precedência:** em qualquer conflito, `docs/arte/CONTRATO_ARTE.md` e a skill `deep-iron-arte` vencem. Os
dois SKILL.md de fora ganharam uma nota no topo dizendo isso (a `pixel-art` mandava "corrigir o usuário"
quando o pedido conflitasse com ela).

## ai-game-art-pipeline

- Origem: https://github.com/ybuild-ai/ai-game-art-pipeline-skill
- Commit: `ed4a2ce1a94370d5962c7d079cd9404a863e02c7` (2026-06-18)
- Licença: MIT (`LICENSE` copiado junto)
- Copiado: `SKILL.md`, `LICENSE`, `references/`, `scripts/`
- Mudança nossa: a nota de precedência no topo do SKILL.md e aspas na `description` do cabeçalho (o
  `: ` sem aspas quebrava o YAML e a skill aparecia sem descrição).
- Ficou de fora: `media/` (4 .jpg de ilustração, ~866 KB, iriam pro LFS), `examples/` (adaptadores HTTP de
  provedores de imagem/vídeo), `.github/`, README/CHANGELOG/CONTRIBUTING.
- Scripts: `sheet_contact.py` (prancha numerada pra curadoria), `chroma_key_magenta.py` (tira fundo
  magenta), `extract_video_frames.py` (precisa do ffmpeg), `provider_stub.py` (interface vazia). Nenhum
  acessa a rede, pede chave ou instala dependência.

**Usamos:** `sheet_contact.py` na curadoria; "reaproveitar o canônico antes de regerar"; "impacto e efeito
ficam no código"; conferir no jogo, na escala real; fundos master-first.

**Ignoramos:** tudo de vídeo (Veo/Seedance, video-to-frames), provedores genéricos, fundo magenta + chroma
key (o PixelLab já entrega transparente), grade 2D a partir de quadro-chave (nosso fluxo é skeleton-v3 →
interpolação → v3 com texto, sempre com imagem-guia 2:1) e a âncora "centro da cabeça + pé" (a nossa é por
direção, no `contrato.json`, igual em todos os estágios).

## pixel-art

- Origem: https://github.com/omer-metin/skills-for-antigravity (pasta `skills/pixel-art`)
- Commit: `e8dcf4e8737921a10088bd5c9eb65e81f74c051f` (2026-01-22)
- Licença: Apache 2.0 (`LICENSE` do repositório copiado junto, como a licença pede)
- Copiado: `SKILL.md`, `references/` (patterns, sharp_edges, validations), `LICENSE`
- Mudança nossa: a nota de precedência no topo do SKILL.md.
- Só texto: sem scripts, URLs, comandos ou chaves.

**Usamos:** os anti-padrões como checklist de revisão das peças do PixelLab (pillow shading, banding,
apêndice de 1 px, antialiasing contra o fundo, mistura de escalas, pontilhado demais).

**Ignoramos (o contrato vence):**

| A skill diz | Nós fazemos |
|---|---|
| contorno seletivo (selout) | "Crisp 1px near-black outline"; sem contorno nas bordas que emendam no terreno |
| andar com 4–6 quadros | 8 quadros (skeleton-v3 / v3) |
| 8 direções; tiles de 16/48 | 4 direções de losango (2 desenhos + espelho); tile 32, losango 64×32 |
| só escala inteira | a vista usa 1,5 px de arte por px do mundo |
| 8–16 cores por personagem | paleta terrosa travada na de origem do PixelLab |
| Phaser, Canvas, limites de NES/SNES | — (não se aplica) |

## deep-iron-arte

Não é de fora: estava só como `.claude/skills/deep-iron-arte.skill` (um zip), que o Claude Code não carrega.
Foi extraída pra `.claude/skills/deep-iron-arte/` (`SKILL.md` + `references/checklist-qa.md`), sem mudança
no conteúdo. O zip ficou onde estava.
