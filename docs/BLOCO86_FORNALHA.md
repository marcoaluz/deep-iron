# Bloco 86 — ordens de produção, a Fornalha e o fundidor

O pedido veio como "Bloco 55" (teste b55). O número já existe no histórico, então ficou **Bloco 86**, teste `b86`.

**Skills usadas:**
- `godot-gdscript`
- `survival-crafting` (receitas como dados, gasto atômico por unidade)
- `godot-ui-control` (janela)
- `save-systems`
- `create-game-assets` (fornalha provisória)
- `godot-gdscript-headless-testing`

## 1. Ordens de produção (`scripts/core/production_queue.gd`)

É um módulo genérico (RefCounted), baseado na fila da forja do `defense.gd`. O Ferreiro do Bloco 87 usa o mesmo.

- **Nada é produzido sozinho.** O jogador escolhe a **receita** e a **quantidade** e confirma (`encomendar`).
- **O trabalhador faz exatamente essa quantidade.** Quando termina, a ordem sai da fila e ele para.
- **Sem ordem ativa** (`tem_trabalho() = false`), ele não pega material nem produz.
- **Cada unidade paga os insumos só quando COMEÇA** (`comecar_unidades`), tudo ou nada por unidade. Encomendar
  não gasta nada.
- **Faltou insumo:** a ordem fica **PAUSADA**, com o aviso do que falta ("falta 1 carvão"), e **nada mais é
  gasto**. Quando o insumo chega, ela continua.
- **Cancelar a qualquer momento:** as unidades já começadas **devolvem os insumos** ao armazém.
- **Fila com tamanho máximo** (`max_fila`, `@export` de quem usa) e quantidade por ordem até 50.
- **Receita:** `{id, nome, insumos {item: qtd}, produto {item: qtd}, segundos, estagio}`, com os itens do
  catálogo do Bloco 82.

## 2. A Fornalha (`scripts/props/fornalha.gd`, `scenes/props/fornalha.tscn`)

- **Posicionada pelo jogador** (`house_placer`) e **erguida pelo engenheiro** (`Canteiro` kind "fornalha",
  dono: Centro da Vila).
- **Liberada no estágio `fornalha_estagio`** (2, Vilarejo).
- **Custo: só créditos e minério** (180 cr + 50 ferro, sem madeira), para não travar a progressão. Pode ter
  mais de uma; o custo cresce como no Bloco 47.
- **No menu CONSTRUIR**, na aba nova **"Produção"**.
- **Na vista:** acende (boca em brasa, fumaça e luz) quando funde, e a placa mostra o que está fazendo ou
  "PAUSADA: falta…".
- **Janela** (clicando nela ou no botão da coluna):
  - as **receitas**: insumos → produto, segundos, motivo quando não dá;
  - a **quantidade** (−5 / − / + / +5) e **Encomendar**;
  - a **fila** com o progresso da unidade e **Cancelar**;
  - quantos fundidores existem.
- **Receitas (`@export`):**

| Receita | Insumos | Tempo |
|---|---|---|
| Barra de ferro | 2 ferro + 1 carvão | 10 s |
| Barra de cobre | 2 cobre + 1 carvão | 12 s |
| Barra de prata | 2 prata | 14 s |
| Lingote solar | 2 solarita | 18 s |
| Aço (Fundição) | 1 barra de ferro + 1 carvão, **só com a vila no estágio 3** | 20 s |

O aço fica "pra Fundição": a mesma fornalha libera a receita quando a vila chega ao estágio 3. Se quiser a
Fundição como prédio separado ou como melhoria da fornalha, é um próximo passo.

- **Arte:** a fornalha é provisória (`assets/game/fornalha.png`, de `fornalha_provisoria.py`): forno de pedra
  com chaminé, apagado e aceso. A vista isométrica mostra esse desenho em pé até ter "fornalha" no
  `predios.json`.

## 3. O fundidor (função nova, `ipezinho.gd`)

- **Na barra de funções:** botão **"Fundidor"**, tecla **6** (remapeável).
- **O que ele faz** (no horário de trabalho da agenda):
  1. **Vai ao armazém.** Larga as barras que estiver levando e **começa a próxima leva**: pega os insumos de
     até `lote` (2) unidades, que só saem do armazém agora.
  2. **Funde na fornalha** (segundos da receita × o ritmo dele, que já conta ânimo, zanga e refeição
     perdida).
  3. Com as barras na mão, volta ao armazém e repete.
- **Quando para:**
  - com a ordem **pausada** (falta insumo), ou **sem ordem**, ele espera; nada é gasto;
  - fora do horário de trabalho, só **entrega** as barras que tem, sem começar leva nova.
- **Roupa provisória** (como você pediu): a roupa do engenheiro com um **tom de fuligem**. Na vista
  isométrica é a arte do engenheiro com esse tom. Quando houver arte própria: `OUTFIT_FILES`/`JOB_OUTFIT` no
  ipezinho e `OUTFIT_FUNCAO` no `iso_bonecos.gd`.
- **Fornalha no mapa:** entrou na navegação e na limpeza da decoração (`environment.NAV_EXTRA_GROUPS`) e na
  regra "a vila fica a leste da paliçada" (`VILA_SO`).

## Save

- `centro_vila` "fornalhas": [{position, fila}], com a fila de ordens inteira (feitas, começadas, progresso).
- `ipezinho.gd` "barras_mao".
- **Save antigo:** nenhuma fornalha, nada na mão.
- Ordem de receita que não existe mais é ignorada.

## Testes

- **`b86_fornalha.gd` (novo, passa):**
  - estágio 1 trava, estágio 2 libera **sem madeira**;
  - menu Produção;
  - canteiro → o engenheiro ergue;
  - **sem ordem, o fundidor não pega nada**;
  - encomendar não gasta;
  - **3 barras feitas, exatamente 3 × (2 ferro + 1 carvão) gastos**, e ele para;
  - pausa sem carvão sem gastar nada;
  - cancelar devolve a prata das unidades começadas;
  - aço só no estágio 3;
  - fila cheia;
  - a janela (linhas das receitas e da fila);
  - save e load.
- **Passaram também:** p20_interface, b28 e hud_frostpunk (barra de funções) e **b46** (menu).
- **Correção de outro bloco:** o b46 quebrava desde o **Bloco 81**, porque o cartão do coletor só aparece com
  a ruína restaurada. O teste agora restaura antes.

Fotos: `docs/arte/bloco86/fornalha_acesa.png` e `janela_fornalha.png`.
