# Bloco 135 — Correções: Configurações, janelas, travada ao dar função, mineiro na jazida, migrantes e prédios únicos

Pedido do Marco: seis correções, uma por uma, com teste e captura de cada uma. Teste `tests/blocos/b135_correcoes_hud.gd`
(54 OK). As capturas ficam em `docs/arte/bloco135/` (`tests/capturas_bloco135.gd`).

## 1. Configurações cortadas

- **O problema:** com a escala da interface em 100% e 125%, o rodapé passava do fim da tela, e no menu inicial não havia
  como sair.
- **A tela:** `ui/settings_panel.gd` põe o conteúdo numa área que rola, com a altura limitada à tela, e tem um rodapé fixo
  com Cancelar e Concluir.
  - Depois de montar, ela mede quanto ainda passa da tela e encolhe a rolagem até caber (até 8 tentativas).
  - Cancelar e Esc desfazem tudo o que mudou desde que a tela abriu: o `settings.cfg` volta como estava, as variáveis do
    Audio voltam e tudo é reaplicado (volumes, música, tela cheia, escala, idioma, câmera, efeitos, teclas, balões, dicas).
  - Concluir guarda.
- **O menu inicial:** com as Configurações abertas, o logo sai e a janela usa a altura toda.
- **Teste:** 1280×720 e 1366×768, nas escalas 90/100/125%; Cancelar, Esc e Concluir.
- **Captura:** `1_config_1366_125.png`.

## 2. Janelas sobrepostas

O gerente de janelas `ui/gerente_janelas.gd` é filho do HUD, criado antes das janelas, e cuida das janelas dos prédios, da
ficha, do cartão de requisitos e da ajuda (H).

- **Dentro da tela:** a janela fica entre a barra de cima e a de baixo. O ajuste de altura das janelas com rolagem usa a
  mesma área.
- **Sem cobrir:** a janela não cobre outra janela, a gaveta da esquerda (Pessoas/Obras) nem um cartão fixo (grupo
  `janela_fixa`: o capataz do primeiro dia).
  - Com 2 ou mais abertas, elas são arrumadas em colunas, lado a lado, com o conjunto centrado.
  - Sem lugar, a nova entra em cascata: 32 px pro lado e 72 px pra baixo (a altura de um cabeçalho), com o título da de
    trás à mostra.
- **Mesmo tipo:** ao abrir, fecha a anterior do mesmo tipo (`open_panel` só fecha as do mesmo tipo: a ficha abre ao lado
  da janela do prédio).
- **Esc:** fecha a de cima primeiro (`hud.fecha_janela_de_cima`, chamado pelo `main.gd`).
- **X:** todas têm. A ajuda ganhou o dela e linhas que quebram (antes passava da tela).
- **Captura:** `2_janelas.png`.

## 3. A travada ao dar função

Medido com `tests/bench_funcoes.gd`, com janela: 12 pessoas, uma por uma (24 vezes) e as 12 de uma vez (4 vezes). Quatro
causas, todas corrigidas na raiz:

| Causa | Quanto custava | Correção |
|---|---|---|
| A barra de baixo reavaliava os requisitos (Bloco 128) de todas as ~19 funções, uma vez por segundo, pra dica dos botões | 40–55 ms a cada segundo, sempre | a dica é montada quando o mouse chega no botão |
| A roupa nova esperava a pasta inteira de animações carregar (1ª vez de cada função) | 115–1.300 ms | `IsoBonecos.texture` não espera: enquanto carrega, a mesma tira da roupa base |
| O retrato do selecionado carregava na hora (1ª vez de cada um) | 20–60 ms | `Retratos.aquece_todos` (todos em segundo plano desde o começo) e o neutro enquanto chega |
| A 1ª voz "Sim!" de cada gênero carregava os arquivos no quadro | ~60 ms | `Audio` aquece os sons curtos em segundo plano (`Slots.aquece`) |
| Um balão por pessoa (12 filhos novos = 12 espelhos refeitos na vista iso) | ~70 ms no quadro | com várias selecionadas, só o aviso do canto (`set_job(job, balao)`) |

Com janela, mesma máquina, com o editor do Godot aberto:

| | ANTES | DEPOIS (3 rodadas) |
|---|---|---|
| Uma por uma: pior quadro | 1.514,8 ms | 46,8 – 49,4 ms |
| Uma por uma: mediana | 105,4 ms | 26,1 – 28,0 ms |
| Quadros acima de 50 ms (em 192) | 14 | 0 |
| As 12 de uma vez: pior quadro | 620,5 ms | 23,8 – 27,2 ms |

**Meta cumprida:** nenhum quadro acima de 50 ms. Arquivos: `docs/bench/funcoes_antes.txt` e `funcoes_depois*.txt` (a
`funcoes_depois.txt` é da 1ª versão, antes de corrigir a dica da barra: 117 ms). Sem janela (os testes), as cargas
esperam de propósito, pra que os testes antigos sigam previsíveis.

## 4. Mineiro "dentro da pedra"

- **Postos:** os de toda jazida (`mineral_node.tscn`; todas herdam, em todos os andares) ficam num arco de 150° virado pra
  câmera (centro em 45°, o lado de baixo da tela), com raio maior (30×24). Antes ficavam em volta da pedra inteira, e dois
  caíam atrás dela.
- **Folga da pedra:** `mineral_node.get_slot_position` afasta o posto até ficar fora da caixa de desenho da pedra (a da
  vista iso), com 6 px de folga. Isso pegou as entradas de galeria, que são maiores.
- **Espera:** `get_wait_position` (quem espera a vez, o carregador) fica na frente, do lado de onde vem.
- **Teste:** 144 postos, todos fora da pedra, do lado da câmera, e o mineiro inteiro: ao lado da pedra ou desenhado na
  frente dela.
- **Captura:** `4_mineiro_jazida.png`.

## 5. Migrantes

- **(a) O ícone da direita:** o alerta "Migrantes no portão" já tinha o contador; agora o clique também abre a janela.
  - Cada cartão mostra retrato, nome, condição, função que quer, idade, família (quem chegou junto) e o prazo.
  - Botões Aceitar, Recusar, Esperar e, em cima, Aceitar todos (até onde há cama; `migrantes.aceita_todos`).
- **(b) O clique no mapa:** clicar perto de um migrante abre a janela (`main._migrante_no_canvas`, raio
  `raio_clique_migrante` = 34 px de tela). Ele vem antes do portão, que roubava o clique, e vale à noite.
- **(c) O aviso:** além do aviso e do som posicional de antes, um toque curto que se ouve de qualquer lugar
  (`ui/noticia_boa`).
- **Save:** a família (`grupo` em cada um e `grupo_n`) vai no save. Save antigo: cada um sozinho.
- **Captura:** `5_migrantes_noite.png`.

## 6. Prédios únicos no CONSTRUIR

- **Um cartão por prédio:** Oficina, Igreja, Vestiário, Posto de troca e Escudo solar usam uma regra só no `build_menu.gd`
  (`unico` → `_unico_estado`).
  - "✔ Construído": botão Abrir, que abre a janela do prédio.
  - "Em obra": a barra das etapas, sem cadeado, e o botão desligado.
  - Disponível: "uma só (disponível)".
- **Nunca dois:** nem pelo cartão nem pelo atalho. Cada `build_*` confere o seu `*_block_reason`, e o teste chama direto
  `build_oficina`, `build_igreja` e `build_posto_troca`.
- **Capturas:** `6_construir_unicos_igreja.png` e `6_construir_unicos_oficina.png`.

## Testes

`b135_correcoes_hud` (54 OK). Regressão, um por vez, pasta isolada, save real intocado, todos verdes: b25, b46, b54, b55,
b58, b88, b92, b95b, b101, b109, b112, b114, b115, b116, b125, b128 (ajustado: a dica do botão sai no mouse_entered), b129,
p28 e p29.

## Não verificado

- **Toque:** nada jogado com mouse e teclado. O clique no migrante e o Esc foram simulados no teste.
- **Mudanças de propósito que valem conferir jogando:**
  - a cascata de janelas;
  - no menu inicial, o logo some com as Configurações abertas.
