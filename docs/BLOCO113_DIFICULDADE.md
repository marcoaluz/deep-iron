# Bloco 113 — Dificuldade e nova partida (relatório)

Data: 2026-10-10. Branch `isometrico`. Pedido: "Prompt 5", a tela de nova partida com dificuldade (seção 25 do guia).
O plano foi APROVADO pelo Marco ("pode") com duas definições minhas, aceitas junto:
- **comida inicial** em unidades do comedouro: 300 / 240 / 160 (100 / 80 / 53% do que ele guarda). Antes eu tinha dito que os
  números do pedido (100 / 60 / 40) seriam percentuais com o Normal em 100%, o que não fecha (nessa lista o Tranquilo é que vale
  100). Assim o Normal continua igual ao de hoje;
- **Criativo**: sem invasões (nem os moradores hostis do S2 e do S3), pacote da Fundação x10 e +50.000 créditos; as ondas solares
  continuam (quem quiser desligar usa o Personalizado).

- Teste: `tests/blocos/b113_dificuldade.gd`, 67 verificações, **0 falhas**. Registrado no GUT (`test_b113_dificuldade`, passou).
- Fotos: `docs/arte/bloco113/`, tiradas por `tests/capturas_bloco113.gd`.

## 1) O que entrou

| Item | Como ficou | Onde |
|---|---|---|
| **Perfis** | Recurso `perfil_dificuldade.gd` com um `.tres` por perfil: Tranquilo, Normal, Ferro e Criativo. O **Personalizado** nasce do Normal com os 8 números que o jogador ajusta (as faixas dos sliders ficam em `AJUSTAVEIS`). | `scripts/core/perfil_dificuldade.gd`, `data/dificuldade/*.tres` |
| **O nó Dificuldade** | Grupos "dificuldade" e "modificadores"; guarda o perfil e os números do Personalizado; vai no save. | `scripts/core/dificuldade.gd`, nó `Dificuldade` na `main.tscn` |
| **Como o perfil chega no jogo** | Os valores absolutos (1ª invasão, a cada N dias, vida por onda, chance da onda de verão, ultimato da greve) são escritos **uma vez** nos `@export` de Defesa, Sol e Moral. Fome e preço de venda entram como chaves do `Modificadores` ("fome" e "preco_venda"). O comedouro novo pergunta a comida inicial. | `dificuldade.gd aplica()`, `ipezinho.gd` (fome), `economy.gd price_of`, `comedouro.gd` |
| **Criativo** | `defense.sem_invasao()`: nenhuma noite de invasão, nenhum morador do fundo, `next_invasion_day() == -1` (sem laço infinito). A Fundação traz o pacote x10 e +50.000 cr. A janela da Defesa e o botão não prometem invasão. | `defense.gd`, `founding.gd`, `defense_panel.gd` |
| **Tela de Nova partida** | Mora dentro da moldura do menu inicial (no padrão do painel de Backups): 5 botões de perfil, a descrição, os 8 números (sliders travados fora do Personalizado), o aviso do Criativo, Voltar e Começar. "Novo jogo" abre esta tela (depois da confirmação, quando já há save). O **primeiro jogo, sem save, também passa por ela** (antes nascia direto). | `scripts/ui/nova_partida_panel.gd`, `start_menu.gd` |
| **Entrega da escolha** | `SaveManager.start_new_game(escolha)` guarda em `dificuldade_nova`; o `main.gd` entrega ao nó quando a partida nova começa. Testes, `--smoke` e quem chama sem argumento: Normal. | `save_manager.gd`, `main.gd` |
| **Janela da Defesa** | Duas linhas novas: o **tier das criaturas** (1 base + o que vem da onda + o que vem das pesquisas feitas, com quantas pesquisas faltam ou qual onda sobe o próximo, e o que o tier muda: +12% de vida por tier, fortes viram elite no tier 3) e a **dificuldade da partida** (1ª invasão, a cada N dias, vida por onda). | `defense.gd tier_detalhe()`, `defense_panel.gd` |

## 2) A garantia do Normal

O Normal **nunca escreve nada**: o jogo fica exatamente como era, e os testes antigos que ajustam esses `@export` à mão continuam
valendo. O `normal.tres` documenta os números e o teste confere que ele é igual aos `@export` de hoje:

| Item | Normal | `@export` |
|---|---|---|
| 1ª invasão | dia 3 | `defense.first_invasion_day = 3` |
| Invasão a cada | 2 dias | `defense.invasion_every = 2` |
| Vida por onda | +15% | `defense.hp_growth = 0.15` |
| Onda solar de verão | 50% | `sun.season_wave_chance[1] = 0.5` |
| Ultimato da greve | 300 s | `morale.strike_ultimatum = 300` |
| Comida inicial | 240 | `comedouro.start_food = 240` |
| Fome / preço de venda | x1,0 / x1,0 | (sem multiplicador antes) |

Mudou o balanceamento de lá? Mude o `normal.tres` também (o teste b113 avisa).

**Telemetria:** como o Normal não mudou, não havia dado novo para justificar. Os valores de Tranquilo e Ferro são os do pedido,
**não foram validados com simulação**: só conferi que cada um é aplicado direito. Se quiser, o próximo passo é simular a 1ª
invasão e a comida dos 3 primeiros dias em cada perfil.

## 3) Save

- Chave nova `dificuldade = {perfil, custom}` e `summary.dificuldade` (o nome do perfil, que o "Continuar" mostra). Documentadas no
  cabeçalho do `save_manager.gd`; a versão do save continua 4.
- Save **antigo** (sem a chave): Normal, sem escrever nada. O `apply_pending` chama o `load_save_data` do nó mesmo com a chave
  ausente, então um save antigo nunca herda o perfil de uma partida anterior.
- Perfil desconhecido ou `custom` ilegível: Normal, sem erro. Números do Personalizado fora da faixa são ajustados à faixa.

## 4) Testes rodados (um por vez, em primeiro plano, APPDATA isolado; o save real conferido por md5)

| Teste | Resultado |
|---|---|
| `b113_dificuldade` (direto e pelo GUT) | 0 falhas (67 OK) |
| `b39_economia` | 0 falhas |
| `b62_tiers_chefe` | 0 falhas |
| `b108_politicas` | 0 falhas |
| `p28_save` | 0 falhas |
| `b100_missoes` | 0 falhas |
| `b112_intro_primeiro_dia` | 0 falhas |
| `b52_debug_telemetria` | 0 falhas |
| `b37_fundacao_raio` | **1 falha na primeira vez** ("obras não terminaram") e 0 ao repetir. O teste espera até 400 s por obras do engenheiro, e o Normal não mudou nada; tratei como instabilidade de tempo, mas vale ficar de olho |

`godot --import` rodou limpo. **Não conferidos:** o resto da bateria (seguindo a nota de memória, não rodei tudo).

## 5) Detalhes e achados

- A pele de UI do jogo só desenha o botão dos sliders, sem a barra: o painel põe o trilho e o pedaço cheio (cores em constantes).
- `Modificadores.mult` pede a `SceneTree` como primeiro argumento (nos testes que são `SceneTree`, passar `self`, não `root`).
- O `next_invasion_day()` tinha um `while not is_invasion_night(d)`: sem a trava do Criativo ele nunca sairia.
- Não há arte nova (a tela usa a pele de UI que já existe).

## 6) Pendências

- **Ver a tela jogando** (a escolha, o "Começar" e a primeira partida em cada perfil). As fotos mostram a tela parada.
- Simulação de balanceamento de Tranquilo e Ferro, se o Marco quiser.
