# Contexto do projeto (pra retomar em outra sessão/conta)

Atualizado em 2026-10-01 (Prompt 19 feito; Prompt 31 verificado). Branch `isometrico`. Último
commit: `30a60c51 Prompt 30`; o Prompt 19, o relatório do 31 e as atualizações de docs estão no
working tree, **ainda sem commit**.

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
- **Prompt 30 concluído** (`docs/arte/prompt30/PROMPT_30_REVISAO.md`): QA visual com fotos, contorno
  de 1 px (`tools/contorno.py`, chamado pelo `integra.py`), clima visível na vista iso, decoração
  da montagem aprovada no mapa, tiras dos bonecos carregando em segundo plano, limpeza do
  protótipo (`docs/arte/limpeza_prompt30.json`). Testes: rodar com `APPDATA`/`XDG_DATA_HOME`/
  `TEMP`/`TMP` no D: se o C: apertar (ver TESTING.md).
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

1. **Prompt 19 feito** (`docs/arte/prompt19/PROMPT_19_LUZ.md`, sem geração): luz por tipo, janelas
   acesas, pontos de luz no desenho, lava, tom por estação; 5 defeitos de luz da vista iso
   corrigidos. Próximos da ordem sugerida: rascunhos dos checkpoints 16/20/25 (sem gastar) e
   16→17, 18 com o saldo.
1. **Prompt 31 verificado** (`docs/arte/prompt31/PROMPT_31_CONTEUDO_FUTURO.md`): nenhum item do
   backlog tem gameplay ainda (escola/crianças, casa nível 2/3, coletor de minério = "em breve") →
   **nada gerado**. Refazer o 31 quando algum desses entrar no jogo.
   **Prompts sem fazer: 16 a 26** (+ pendências pequenas dos 2, 14 e 29). Ordem sugerida no
   relatório do 31: 19 (luz, quase só código) e os rascunhos dos checkpoints 16/20/25 sem gastar;
   16→17 (criaturas) e 18 com o saldo de agora; 20–26 depois da recarga de 30/10.
   **Disco C:** limpo em 2026-10-01 (Temp antiga: 361 MB → ~6,1 GB livres). Plugins sem uso
   (limboai, godotsteam, phantom_camera, dialogue_manager, state_charts, ~300 MB): o Marco pediu
   pra **não mexer** por enquanto.
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
