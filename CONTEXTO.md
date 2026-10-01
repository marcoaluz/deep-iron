# Contexto do projeto (pra retomar em outra sessão/conta)

Atualizado em 2026-10-01. Branch `isometrico`. Último commit: `e92362ec adad`
(working tree limpo nesse momento).

Isso existe porque estamos trocando entre duas contas do Claude Code
(`marco.luz1994@gmail.com` e `marcoa.luz@hotmail.com`, essa segunda via
`claude-luz` com `CLAUDE_CONFIG_DIR` próprio) quando uma bate o limite de uso.
O código fica na pasta, mas a conversa de cada sessão não passa de uma pra
outra — este arquivo é o resumo pra colar/apontar na sessão nova.

## Onde estão os arquivos do pacote de prompts (arte)

- `docs/arte/CONTRATO_ARTE.md` — regras fixas de estilo/arte (ler antes de
  aplicar qualquer prompt de arte).
- `docs/arte/INVENTARIO.md` — o que já foi gerado no PixelLab, saldo de
  gerações restante, e a ordem/estimativa dos prompts que faltam.
- `docs/arte/MAPA_VISAO.md` — visão do mapa (floresta → portão quebrado →
  vila da pedreira → boca da mina → torre de perfuração/elevadores).
- `docs/arte/promptNN/` (01 a 15, 27, 28, 29) — uma pasta por prompt de arte
  já feito, com o relatório (`PROMPT_NN_*.md`) e as imagens geradas.
- Os prompts de arte são numerados e aplicados **um de cada vez**, com pausa
  pra revisão do Marco antes do próximo (preferência registrada em memória).

## Onde estamos

- Motor isométrico (Prompt 28) e mapa novo jogável (Prompt 29, parte 1) estão
  no jogo, na branch `isometrico`. Relatório mais recente:
  `docs/arte/prompt29/PROMPT_29_PARTE1_MAPA.md`.
- O mapa novo (vila em terraços, escadas, paliçada, céu por hora, andares de
  baixo em camadas) já está jogável e testado (GUT 40/40 + `p29_mapa`).
- **A arte em pé (prédios, bonecos, árvores, pedras, jazidas) ainda é a
  antiga**, só redimensionada 1,5× pra caber no mapa novo — essa troca é a
  parte 2 em diante do Prompt 29.
- Nível 2 e abismo usam o chão novo, mas a decoração deles (bordas, cristais,
  jazidas, elevadores) ainda é antiga, sem coluna de rocha nem poço entre as
  lajes.
- Saldo de geração no PixelLab: **1.439** (conferido no PixelLab; recarga de
  +5.000 prevista para 2026-10-30). Prompts de código (28-29) não gastam
  geração.
- A vista de cima (F3) continua só como conferência temporária e sai no fim
  do Prompt 29.

## O que falta fazer daqui pra frente

1. **Prompt 29, partes 2+**: trocar a arte em pé (prédios, personagens,
   árvores, pedras, jazidas) pela arte nova no mapa novo; dar uma decoração
   nova pro nível 2 e pro abismo (bordas, cristais, jazidas, coluna de rocha,
   poço, elevadores); remover a vista de cima (F3) quando o mapa novo estiver
   completo.
2. Seguir a ordem dos prompts restantes listada em `docs/arte/INVENTARIO.md`
   (ferramentas/armas, robô, terreno, mina, jazidas, vegetação, prédios,
   máquinas, objetos, animais, criaturas, efeitos, luz, UI, ícones, fonte,
   retratos, eventos, telas, mapa), respeitando o saldo de geração restante.
3. Conteúdo futuro (Prompt 31, mais andares além de nível 2/abismo) fica pra
   depois — precisa de gameplay novo, não só arte.
4. Cada prompt de arte: ler `CONTRATO_ARTE.md` + `INVENTARIO.md`, aplicar
   **um prompt por vez**, parar pra revisão do Marco antes do próximo.
5. Toda rodada headless de teste (`main.tscn`/GUT) precisa isolar o
   `APPDATA`/pasta de usuário (fake + checagem de hash) pra não tocar no save
   real do jogador — já é prática seguida nos testes atuais
   (`tests/blocos/`, `test_blocos.gd`).

## Onde ver o estado dos testes

- `TESTING.md` na raiz: lista todos os blocos de teste, o que cada um cobre,
  problemas conhecidos (`b45_coletor_madeira` e `b31b_obras_restantes` têm
  falhas intermitentes já identificadas e documentadas) e como rodar tudo
  com a vista iso ligada (`DEEP_IRON_ISO=1`).
