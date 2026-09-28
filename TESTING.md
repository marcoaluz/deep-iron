# Testes do DEEP IRON

Os testes ficam em `project.godot/tests/` e rodam pelo **GUT** (já instalado em
`addons/gut`), pelo painel do editor ou pela linha de comando.

## Como funciona

- `tests/blocos/*.gd` — um teste por bloco. Cada um abre a partida inteira
  (`main.tscn`), mexe nela (ordens, save/load, obras…) e imprime `OK` / `FALHOU` e no
  fim `FALHAS: N`. São scripts `SceneTree`, não testes GUT.
- `tests/test_blocos.gd` — o teste **GUT**: um `test_…` por bloco. Cada um roda o
  script do bloco num **Godot headless separado** e confere a saída.
- `.gutconfig.json` (na raiz do projeto) — aponta o GUT pra `res://tests/`.

**O save de verdade nunca é tocado:** o Godot de cada bloco roda com a pasta de
usuário trocada por uma temporária (`%TEMP%/deep_iron_testes/fake_appdata`), e os
próprios testes abortam (`ABORTADO`) se não estiverem nela.

**Leva tempo:** cada bloco joga um pedaço da partida (≈ 1 a 4 min). A bateria
inteira leva uns **15 minutos**. Pra conferir só um bloco, rode só o teste dele.

## Pelo painel do GUT (editor)

1. Abra o painel **GUT** (aba embaixo do editor).
2. Na primeira vez: em **Settings → Directories**, adicione `res://tests`
   (o painel guarda isso por usuário, fora do Git).
3. **Run All** roda todos. Pra um só, abra `tests/test_blocos.gd` e rode o teste
   (ex.: `test_b35_arsenal_desgaste`).
4. Se algum falhar, o painel mostra as linhas `FALHOU` e o fim da saída do bloco.

## Pela linha de comando

Da pasta `project.godot/` (troque o caminho do Godot pelo seu):

```
# todos
<Godot>.exe --headless --path . -s addons/gut/gut_cmdln.gd

# só um bloco (filtra pelo nome do teste)
<Godot>.exe --headless --path . -s addons/gut/gut_cmdln.gd -gunit_test_name=b35

# um bloco direto, sem GUT (mostra toda a saída do teste)
<Godot>.exe --headless --path . -s res://tests/blocos/b35_arsenal_desgaste.gd
```

> No último jeito (direto, sem GUT), a trava de segurança exige a pasta isolada: rode
> com `APPDATA` apontando pra uma pasta que tenha `fake_appdata` no caminho, senão o
> teste só imprime `ABORTADO` e sai (de propósito).

## Regressão dos sprites

`tools/sprite_regress.py` confere que o gerador de sprites (`tools/gen_sprites.py`,
determinístico) só mudou o que o bloco pretendia — instruções no topo do arquivo.

## O que tem teste versionado

| Arquivo | Bloco |
|---|---|
| `manut_backups.gd` | Backups rotativos do save |
| `b25_funcoes.gd`, `b25_troca_funcao.gd` | 25 — função única por ipezinho |
| `b26_outfits.gd` | 26 — roupa por função |
| `b27_cacador_cozinheiro.gd` | 27 — caçador e cozinheiro que prepara |
| `b28_cacador_outfit.gd` | 28 — roupa do caçador, HUD, fallback de caça |
| `hud_frostpunk.gd` | HUD estilo Frostpunk |
| `b29_30_item_mao_medico.gd` | 29 e 30 — item na mão, médico |
| `b31_obras_engenheiro.gd`, `b31b_obras_restantes.gd` | 31 e 31b — engenheiro e obras |
| `b32_…` a `b42_…` | 32 a 42 (um arquivo por bloco) |

**Sem teste versionado:** os blocos **1 a 24** (os testes daquela época não foram
guardados — sobraram só sondas de depuração, que não dão OK/FALHOU e ficaram de fora)
e o próprio **Bloco 43**. Não foram recriados.

## Manutenção feita no Bloco 43

Os testes vieram do jeito que estavam, com três ajustes mecânicos pra rodar hoje
(trava do save isolado onde faltava; partida sem a fundação do Bloco 37; troca de cena
de verdade no load) e **checagens atualizadas** onde um bloco posterior mudou o
comportamento de propósito (cada troca está comentada com `(Bloco 43)` no arquivo):

- `b25_funcoes` — aceita "já entregou" além de "indo entregar" (o teste pegava o
  ipezinho já no armazém; a regra em si é coberta por `b25_troca_funcao`).
- `b26_outfits` — guarda e pesquisador com roupa própria (Bloco 28); cozinheiro com a
  cesta, guarda com a arma, pesquisador sem picareta fora da mina (Bloco 29).
- `b27_cacador_cozinheiro` — arco na mão só caçando (Bloco 29).
- `b28_cacador_outfit` e `b29_30_item_mao_medico` — HUD novo (seções e contagem por
  função na barra de funções); guarda novo começa com porrete (Bloco 35); o médico
  "some do mapa" confere `_inside` (o desenho some um quadro depois).

## Conhecido

- `b31b_obras_restantes` às vezes falha com "engenheiro preso a caminho de uma obra"
  depois de carregar (visto 2 em 15 rodadas; causa ainda não achada). Se falhar, rode
  de novo; se repetir, vale investigar.
