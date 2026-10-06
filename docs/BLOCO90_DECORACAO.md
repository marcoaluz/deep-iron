# Bloco 90 — decoração construída pelo jogador

O pedido veio como "Bloco 59" (teste b59). O número já existe no histórico, então ficou **Bloco 90**, teste `b90`.

**Skills usadas:**
- `godot-gdscript`
- `godot-resources` (catálogo como dados)
- `godot-ui-control` (aba e remover)
- `performance-optimization` (rebuild agrupado, luz e beleza só quando precisa)
- `create-game-assets` (texturas provisórias)
- `save-systems`
- `godot-gdscript-headless-testing`

## Menu organizado

O menu CONSTRUIR agora tem as abas **Produção** (Fornalha, Bloco 86), **Culto** (Igreja, Bloco 88) e
**Decoração**, nesta ordem: Moradia, Alimentação, Saúde, Lazer, Pesquisa, Defesa e equipamento, Coleta automática,
Produção, Culto, Decoração, Vila.

## Catálogo (`scripts/core/decor.gd`, por dados)

| Peça | Custo | Luz | Lugares | Beleza |
|---|---|---|---|---|
| Tocha | 4 cr + 4 madeira | laranja, curta | — | 1 |
| Lampião | 12 cr + 3 ferro + 2 madeira | amarela, longa | — | 1,5 |
| Banco | 10 cr + 8 madeira | — | 2 | 1 |
| Mesa | 14 cr + 12 madeira | — | 4 | 1 |
| Cerca | 4 cr + 6 madeira | — | — | 0,5 |
| Canteiro de flores | 8 cr + 4 madeira | — | — | 2,5 |
| Bandeira | 10 cr + 3 madeira | — | — | 2 |

- **Cada peça** tem id, nome, textura, pegada, custo, luz, lugares e beleza.
- **Texturas provisórias** em `assets/game/decor/<id>.png` (`decor_provisoria.py`). Pra trocar, é só gravar
  outro PNG com o mesmo nome.

## Como funciona

- **Pôr:** o cartão da aba Decoração abre o `house_placer` com a pegada da peça e a opção nova **`repeat`**: dá
  pra pôr **várias em sequência**, e Esc ou o botão direito termina.
  - **Construção instantânea**, sem engenheiro, paga na hora.
  - A peça vira obstáculo pro posicionador: nada fica em cima de outra peça.
- **Remover:** "Remover decoração" liga o modo de clicar numa peça pra tirar, **devolvendo `reembolso` (50%)**
  do custo (créditos, ferro e madeira).
- **Luz:** tochas e lampiões têm `PointLight2D` em `cullable_lights` e **acendem com o `torch_level` do
  DayNight**. A cada 0,25 s, só as peças com luz são atualizadas.
- **Lumívoro:** prefere lugares iluminados. Uma tocha ou lampião aceso conta com a distância dividida por
  `creature.atracao_luz` (2), então pesa como um prédio aceso na metade da distância.
  - **Chegando, ele come a luz:** a peça apaga até o amanhecer.
- **Bancos e mesas viram pontos sociais** (Bloco 85): o banco com 2 lugares, a mesa com 4.
- **Beleza:** a decoração a até `beleza_raio` (110 px) de uma casa dá aos moradores o fator **"casa
  enfeitada"**, que é a soma da beleza das peças, **até `beleza_teto` (6)**. O cálculo é refeito só quando a
  decoração muda.
- **Navegação:**
  - **só as peças grandes** (pegada ≥ 300 px²: mesa, canteiro de flores) entram como obstáculo
    (`decor_obstaculos` em `NAV_EXTRA_GROUPS`);
  - o **`rebuild_navigation` é agrupado**: espera `nav_espera` (0,6 s) depois da última peça grande, e um
    rebuild cobre várias;
  - tochas, bancos, cercas e bandeiras não mexem na navegação.
- **As tochas sorteadas pela seed do `environment.gd` não mudaram.** A decoração do jogador é outra lista,
  gerenciada pelo nó "Decoracoes" (`decoracoes.gd`), que o `main.gd` cria.

## Save

- `decoracoes` = `{pecas: [[id, x, y], ...]}`, uma lista própria.
- **Save antigo:** sem decoração.
- Peça de um id que não existe mais é ignorada.

## Testes

- **`b90_decoracao.gd` (novo, passa):**
  - as 7 peças com todos os campos;
  - abas Decoração, Produção e Culto;
  - 2 tochas em sequência, com o modo continuando, prontas na hora sem canteiro e pagas;
  - tochas não mexem na navegação;
  - luz em `cullable_lights`, apagada de dia e acesa à noite;
  - **o Lumívoro vai na tocha acesa**, não vai se `atracao_luz` for quase zero, apaga a tocha e procura outra,
    e a luz volta no amanhecer;
  - banco é ponto social com 2 lugares;
  - **3 mesas → 1 rebuild só**;
  - canteiro perto de casa → "casa enfeitada", e muita decoração para no teto (6);
  - remover devolve 50%;
  - as tochas da seed não mudaram;
  - save, load e save antigo.
- **Passaram também:** b46 (menu), p17 (criaturas) e b36 (Lumívoros e guardas).

Foto: `docs/arte/bloco90/decoracao_noite.png` (lampiões e tochas acesos, banco, mesa, flores, bandeira, cerca).
