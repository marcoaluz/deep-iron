---
name: passagem
description: Passa o trabalho do DEEP IRON pra outra sessão ou outra conta do Claude Code (o Marco troca de terminal quando o limite de uso de uma conta acaba). Use quando o limite de uso estiver perto, quando o Marco disser "vou trocar de conta", "passa o bastão", "salva o contexto", "fecha a sessão", ou ao fim de um conjunto de blocos. Atualiza o CONTEXTO.md, deixa a árvore do git limpa e escreve o que falta, pra a outra sessão retomar sem perguntar nada.
---

# Passagem (DEEP IRON)

O Marco trabalha em duas contas do Claude Code e troca quando uma bate o limite. A outra conta **não vê esta conversa**: só vê o repositório. Então tudo que importa tem que estar nele.

## O que fazer (nesta ordem)

1. **Terminar ou fechar a ponta solta.** Nada pela metade: ou o bloco está testado e commitado, ou o que falta está escrito no passo 3. Não deixe teste vermelho sem dizer qual e por quê.
2. **`git status` e `git log --oneline -8`.** Árvore limpa (nada sem commit que importe). Commit por caminho explícito, `bloco-NN: ...`, com a linha de atribuição. **Não dê push**: só o Marco (`! git push origin isometrico`). Liste os commits ainda não enviados (`git log origin/isometrico..HEAD --oneline`).
3. **Atualizar o `CONTEXTO.md`** (o arquivo de passagem do projeto), no topo, sem apagar o histórico:
   - a linha "Atualizado em ..." (data, branch, último bloco, o que está sem push);
   - uma seção curta por bloco feito (o que é, relatório `docs/BLOCONN_*.md`, teste `bNN_*`, o que NÃO foi verificado);
   - **o que está em andamento** e o **próximo passo exato** (o prompt da fila que vem agora, a decisão que espera o Marco, o comando que ia rodar);
   - **a fila de prompts** que o Marco já mandou e ainda não foram feitos, na ordem, com o número do bloco que cada um vai virar;
   - decisões que ele tomou e o motivo (pra a outra conta não perguntar de novo).
4. **`CLAUDE.md`**: o "último existente é bNN; o próximo é bNN+1" e a linha do sistema novo, se mudou.
5. **Memória** (`C:\Users\...\.claude\projects\...\memory\`): só o que a outra conta não acha no repositório (preferências novas do Marco, regras que ele corrigiu). Um fato por arquivo, e a linha no `MEMORY.md`.
6. **Custos e saldos**: o que sobrou no PixelLab (`mcp__pixellab__get_balance` ou `python tools/pixellab/...`) e no ElevenLabs (`python tools/elevenlabs/gerar_sons.py --saldo`), e o que está gerando em segundo plano (jobs do PixelLab pendentes: `list_jobs`).
7. **Dizer ao Marco**, em poucas linhas: o que está pronto, o que falta, o comando do push, e "na outra conta, comece por `/retomar`".

## O que NÃO fazer

- Não afirmar que passou o que não rodou. Testes que não foram rodados vão listados como "não conferidos".
- Não apagar nem reescrever o histórico do `CONTEXTO.md`: acrescente.
- Não deixar segredo no repositório (a chave do ElevenLabs fica no `.env`, ignorado pelo git).
- Não iniciar um bloco novo grande bem na hora da passagem: feche o que está aberto.

## Modelo da entrada no topo do CONTEXTO.md

```
Atualizado em AAAA-MM-DD. Branch `isometrico`. Último bloco: NN. Sem push: <commits>.
## EM ANDAMENTO / PRÓXIMO PASSO
- <o que estava fazendo e o próximo comando>
## FILA DO MARCO
1. Prompt X -> Bloco NN ...
```
