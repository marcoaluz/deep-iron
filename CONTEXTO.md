# Contexto do projeto (pra retomar em outra sessão/conta)

Atualizado em 2026-10-01 (Prompt 29 concluído: partes 1 a 6). Branch `isometrico`. Último
commit: `e92362ec adad`; as partes 2–6 estão no working tree, **ainda sem commit** (o Marco valida
antes).

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
- `docs/Prompt/deep_iron_prompts_arte_completa.md` — o texto original de cada prompt (0–31).
- Os prompts de arte são numerados e aplicados **um de cada vez**, com pausa
  pra revisão do Marco antes do próximo (preferência registrada em memória).

## Onde estamos

- **Prompt 29 concluído** (tudo o que já tem arte aprovada está no jogo). Relatórios:
  `docs/arte/prompt29/PROMPT_29_PARTE1_MAPA.md`, `PROMPT_29_PARTE2_PREDIOS.md`,
  `PROMPT_29_PARTES3A6.md`.
- Como a arte nova entra: `prototipos/camera/arte_iso/integra.py` (`predios`, `bonecos`, `props`)
  copia os desenhos pra `assets/game/iso/{predios,bonecos,props}/` com os `.json` (âncora, caixa);
  `scripts/iso/iso_art.gd` (prédios, natureza/objetos, elevadores) e `scripts/iso/iso_bonecos.gd`
  (bonecos, robô) escolhem o desenho pelo estado do jogo; `iso_billboard.gd` troca o desenho
  antigo pelo novo. Prédios têm pegada de navegação do desenho (÷ 1,5).
- Decisões do Marco nesta rodada: portão refeito no eixo i (PixelLab, 80 gerações); casa em
  qualquer lugar da pedreira (raio do Centro desligado); análise: cabem 31 casas a mais, o jogo
  pede no máximo 7 → **não precisa aumentar o mapa** (rever se o Prompt 31 trouxer escola).
- PixelLab: esta conta (`claude-luz`) não tem o MCP; dá pra chamar o servidor HTTP do PixelLab com
  a configuração da outra conta (`~/.claude.json`, `mcpServers.pixellab`). Saldo **1.359**
  (recarga +5.000 em 2026-10-30).
- F3 (vista de cima) saiu do jogo; "Comedouro" virou "Cozinha" nos textos.
- **Sem arte ainda** (fica como "falta" no inventário): invasores (16–17), efeitos (18), UI/ícones/
  fonte (20–22), retratos/ilustrações (23–24), telas (25–26).

## O que falta fazer daqui pra frente

1. **Próximos: Prompt 30** (revisão final: QA visual, consistência de brilho/paleta, desempenho
   com o mapa cheio, limpeza de arte provisória e protótipos não usados, lista do futuro) e
   **Prompt 31** (conteúdo futuro: crianças/escola — precisa de gameplay novo e de gerar arte).
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
