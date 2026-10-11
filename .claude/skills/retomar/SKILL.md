---
name: retomar
description: Retoma o trabalho do DEEP IRON numa sessão nova ou numa conta nova do Claude Code, a partir do que está no repositório (CLAUDE.md, CONTEXTO.md, git, memória). Use no começo de toda sessão, quando o Marco disser "continua", "retoma", "leia o contexto" ou "estou na outra conta". Lê o estado, confere o git e o Godot, diz em poucas linhas onde parou e continua do próximo passo sem refazer o que já está feito.
---

# Retomar (DEEP IRON)

A sessão anterior (às vezes de outra conta) deixou o estado no repositório. **Leia antes de agir** e **não refaça** o que o `CONTEXTO.md` diz que está feito.

## Passos

1. **Ler**, nesta ordem: `CLAUDE.md` (regras fixas, pastas, sistemas), `CONTEXTO.md` (o topo: onde parou, o que está em andamento, a fila de prompts do Marco), a memória (`MEMORY.md` e os arquivos que ele aponta). Se o Marco mandou um prompt agora, ele vale por cima da fila.
2. **Conferir o chão**:
   - `git status` (o que ficou sem commit) e `git log --oneline -8`; `git log origin/isometrico..HEAD --oneline` mostra o que ainda não foi enviado (só o Marco dá push);
   - o Godot responde? (`D:\DEV\Godot\Godot_v4.7.2-stable_win64.exe --headless --version`); se mexeram em arte ou áudio, `godot --headless --path project.godot --import` antes dos testes;
   - rodar **um** teste do último bloco (`tests/blocos/bNN_*.gd`, com `APPDATA`/`LOCALAPPDATA`/`XDG_DATA_HOME` numa pasta com `fake_appdata`, **um por vez, em primeiro plano**) pra ver que o estado do `CONTEXTO.md` é verdade;
   - jobs do PixelLab pendentes (`list_jobs`) e saldos (PixelLab, ElevenLabs) se o próximo passo gasta crédito.
3. **Dizer em 3 a 5 linhas** onde está: último bloco, o que estava em andamento, o próximo passo, e qualquer divergência achada (teste vermelho, árvore suja, CONTEXTO desatualizado).
4. **Continuar do próximo passo** do `CONTEXTO.md`, com as regras do projeto: skills do projeto (`.claude/skills/`), um Bloco por entrega (teste `bNN`, registro em `tests/test_blocos.gd`, linha no `TESTING.md`, relatório `docs/BLOCONN_*.md`, commit `bloco-NN: ...`), arte só do PixelLab, **push só com o OK do Marco**, atualizar o `CONTEXTO.md` a cada entrega.

## Regras que quase sempre se perdem na troca de conta

- Teste com a pasta de usuário isolada (`fake_appdata`) e o md5 do save real antes e depois; nunca a bateria inteira em segundo plano.
- Função nova traz a roupa dela no mesmo bloco; cartão novo do CONSTRUIR tem imagem; balanceamento é `@export` com comentário.
- Fila de prompts: aplicar na ordem, com o padrão recomendado quando ele não responde; ele valida no fim. Mostrar plano/prompts de arte antes de gastar PixelLab quando o prompt pede.
- `ffmpeg` não está instalado (o áudio fica em WAV); `numpy` é preciso pra `gerar_musica.py` gerar.
- Se o `CONTEXTO.md` e o código discordarem, vale o código; corrija o `CONTEXTO.md` e avise.
