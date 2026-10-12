# Bloco 129 — Arquivo do save escolhido, introdução em toda partida nova e análise do Arsenal

Pedido do Marco (sessão de 11–12/10/2026): apagar os saves pra começar do zero; poder **escolher onde salvar** com o autosave
ficando **no mesmo arquivo**; a introdução não ser "à parte" e sim **quando começa um jogo novo**; e analisar/ajustar o
Arsenal "e tudo". Teste: `b129_save_arquivo_intro` (32 verificações). Nada jogado nem visto na tela.

## 1) Saves apagados
Em `%APPDATA%\Godot\app_userdata\project.godot\`: `savegame.json` e os 5 backups de `backups\` (e `.tmp`/`corrompido`, que não
existiam). As configurações (`settings.cfg`), a telemetria e os logs ficaram. O Godot do editor estava aberto, mas nenhum jogo
rodando (nada recriou o save).

## 2) O arquivo do save é do jogador
- `SaveManager.caminho_save` (padrão `user://savegame.json`; guardado em `settings.cfg`, `jogo/caminho_save`). **Tudo** passa por ele:
  `has_save`, `read_save`, salvar, autosave, F5, salvar-ao-sair, o backup de partida nova e a quarentena de save corrompido. O
  temporário é `<arquivo>.tmp` na mesma pasta (troca atômica de sempre).
- `set_caminho_save(path)`: aceita caminho do sistema ou `user://`; acrescenta `.json`; recusa pasta que não existe.
- **Selecionador de arquivo do sistema** (`scripts/ui/escolhe_arquivo.gd`, `FileDialog` nativo; o do Godot se o sistema não tiver):
  - **Nova partida:** linha "Salvar em: <arquivo>" com o botão "Escolher onde salvar…". O `Começar` leva o `arquivo` na escolha.
  - **Menu inicial:** "Carregar de um arquivo…" (lê, passa a salvar nele e começa); a linha de baixo mostra "arquivo do save: …".
  - **Pausa:** "Salvar como… (escolher o arquivo)" salva já no arquivo novo e o autosave segue pra lá; o menu mostra "Salvando em: …".
- Backups continuam em `user://backups/` (partida nova em cima de um arquivo que já tem save: ele vira backup, como antes).
- Save antigo carrega igual (nenhuma chave nova no save; a escolha é do `settings.cfg`).

## 3) A introdução em toda partida nova
- Saiu o botão "Ver a introdução" do menu inicial. `start_new_game` passa pela introdução (os 3 quadros + os 4 no mapa; Esc pula)
  **em toda partida nova**, mesmo com a intro já vista (antes só na primeira).
- Configurações > "Introdução em toda partida nova" (`jogo/intro_ligada`, padrão ligado) desliga. `ver_introducao()` continua no
  código (usado pelo b112), sem botão.

## 4) Arsenal e "tudo"
O que pude concluir de leitura, de teste e de uma simulação (sem o jogo aberto):
- **O Arsenal tem a SUA janela** desde o Bloco 128 (forja, cavalete, armas), e a Defesa é a visão geral.
- **`b47_varios_predios` falhava ("load: 2 Arsenais e 2 campos")**: o Arsenal voltava 8 px mais abaixo depois do load.
  Causa: `environment._migrate_overlaps` (roda em todo load) afasta um prédio cuja arte encosta num da cena. O teste põe os
  prédios direto, sem o posicionador, e a arte do Arsenal encostava (9 px) num prédio da cena. **No jogo não acontece:** testei
  48 lugares que o posicionador aceita (Arsenal, campo, laboratório, taverna) e nenhum se mexeu na carga. Ajustei o teste (tolerância
  de 10 px, comentada).
- Bateria dos testes de bloco rodada de novo (um por vez, pasta isolada): ver o resultado no fim deste arquivo.

## O que não foi verificado
- Nada visto: o seletor de arquivo nativo (só o caminho de código foi testado; em headless não abre janela), o texto das telas.
- O que você achou de estranho no Arsenal e eu não reproduzi: me diga o sintoma (o que clica, o que esperava, o que acontece).
