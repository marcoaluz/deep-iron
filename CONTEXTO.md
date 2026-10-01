# Contexto do projeto (pra retomar em outra sessão/conta)

Atualizado em 2026-10-01 (fim do Prompt 29 parte 2). Branch `isometrico`. Último commit:
`e92362ec adad`; a parte 2 está no working tree, **ainda sem commit** (o Marco revisa antes).

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

- Motor isométrico (Prompt 28), mapa novo jogável (Prompt 29 parte 1) e **prédios com a arte
  nova (Prompt 29 parte 2)** estão no jogo, branch `isometrico`. Relatório mais recente:
  `docs/arte/prompt29/PROMPT_29_PARTE2_PREDIOS.md`.
- Como a arte nova entra: `prototipos/camera/arte_iso/integra.py predios` copia os desenhos
  pra `assets/game/iso/predios/` + `predios.json` (estado → imagem, âncora, caixa);
  `scripts/iso/iso_art.gd` escolhe o desenho pelo estado do jogo e dá a pegada de navegação
  (desenho ÷ 1,5); `iso_billboard.gd` troca o desenho antigo pelas camadas novas. As próximas
  partes (bonecos, natureza...) devem seguir o mesmo caminho (acrescentar ao `integra.py` e ao
  `iso_art.gd`).
- **Ainda arte antiga**: bonecos (elenco, trajes, ferramentas), robô, criaturas, animais,
  árvores, pedras, cristais, jazidas, tochas, objetos; nível 2 e abismo (bordas, elevadores,
  poço). Os elevadores ficaram pra parte dos andares de baixo.
- Saldo de geração no PixelLab: **1.439** (conferido no PixelLab; recarga de
  +5.000 prevista para 2026-10-30). Prompts de código (28-29) não gastam
  geração.
- A vista de cima (F3) continua só como conferência temporária e sai no fim
  do Prompt 29.
- Pendências anotadas: "Comedouro" → "Cozinha" nos textos; sobreposição de lotação do armazém;
  satélite do laboratório; animação da escavadeira perfurando.

## O que falta fazer daqui pra frente

1. **Prompt 29, partes 3+** (proposta, uma por vez com revisão): 3 = bonecos (elenco nas 4
   direções, caminhada/trabalho, pele por paleta, trajes, ferramenta nas costas); 4 = natureza
   e objetos (árvores, vegetação, pedras, cristais, jazidas, minérios, tochas, animais, robô);
   5 = nível 2 e abismo (bordas, coluna de rocha, poço, elevadores); 6 = janela/zoom (Bloco 48)
   + remover a vista de cima (F3). Invasores, efeitos, UI, ícones, fonte, retratos e telas
   dependem dos prompts 16–26 (arte ainda não feita).
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
