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
| `b44_vestiario.gd` | 44 — Vestiário como prédio físico |
| `p28_iso.gd` | Prompt 28 — vista isométrica no jogo (F3): espelhos, ordem por caixas, clique pelo raio, construir/demolir, prédio em "L", fantasma, câmera/save, desligar |
| `p28_save.gd` | Prompt 28 — save de antes do Prompt 28 carrega igual nas duas vistas (md5 do arquivo, ipezinhos, posições, créditos); com `DEEP_IRON_SAVE_FIXTURE=<cópia de um save antigo>` usa a cópia, sem ela faz o próprio save |
| `p29_mapa.gd` | Prompt 29 — mapa novo: alturas dos terraços e rampa da escada, navegação (escada e portão), construir só em chão plano, ordem com os terraços, andares de baixo empilhados (clique volta pro andar), céu e luz por hora, migração do save |
| `p29_predios.gd` | Prompt 29 parte 2 — prédios com a arte nova: desenho por estado (variação, obra 1/2/3 pelo progresso, estágio do Centro, peças da escavadeira, nível do portão), caixa do desenho, pegada de navegação = desenho ÷ 1,5, camas/slots fora da parede e alcançáveis, posicionador e fantasma novos, migração de prédios sobrepostos, paliçada, ordem sem erro |
| `p19_luz.gd` | Prompt 19 — luz e noite: texturas por tipo, ponto de luz do desenho, janelas acesas só à noite e com o prédio aceso, alcance de z das luzes, tocha/cristal/lanterna, lava, tom por estação |
| `p29_bonecos.gd` | Prompt 29 parte 3 — bonecos com a arte nova: pasta por função × gênero, animação pelo estado, direção, pele por paleta, casaco/traje, picareta e saco nas costas, corpo antigo escondido |
| `p29_natureza.gd` | Prompt 29 partes 4–5 — natureza/objetos pelo desenho antigo (árvores, toco, tocas, horta, jazidas pela quantidade, galeria lacrada, rochas, cristais, tocha), elevadores (gaiola no andar de baixo) e robô |
| `../test_iso.gd` (GUT, rápido) | Prompt 28 — núcleo: projeção, verdade 3D, ordem incremental, raio da câmera, direção de losango |
| `../test_iso_arte.gd` (GUT, rápido) | Prompt 28 — verificador "o sprite cabe na caixa" contra a arte dos prédios; Prompt 29 — toda a arte integrada (`assets/game/iso/predios/predios.json`) |
| `../test_iso_pele.gd` (GUT, rápido) | Prompt 28 — paletas de pele por código (igual ao `tons_de_pele.py`; dados em `tests/data/pele/`) |

**Prompt 29 parte 2 mudou de propósito** `b41_parque`: o lugar do 2º parque sai do posicionador
do parque aberto (pegada do desenho novo), não de uma pegada/bloqueios que tinham sobrado.

(Bloco 44 mudou de propósito o `b42_equipamento`: ele ergue um Vestiário pronto no começo,
porque desde o 44 o equipamento só funciona com o prédio.)

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
- `b27_cacador_cozinheiro` — depois do load confere a matéria-prima TOTAL (armazém +
  mochilas): o jogo segue rodando e o cozinheiro pode pegar um pouco antes da conferência.
- `b36_guarda_caido` — posição do caído com tolerância de 2 px (o save guarda 1 casa
  decimal; comparar arredondado dava diferença de 1 px à toa).
- `test_blocos.gd` — cada bloco começa com a pasta de usuário temporária **limpa**
  (sem save, backup ou `settings.cfg` deixado pelo bloco anterior).

## Rodar tudo com a vista isométrica ligada (Prompt 28)

`DEEP_IRON_ISO=1` faz toda partida começar com a vista iso ligada (o `main.gd` liga no
início). A lógica não pode mudar com a vista, então a bateria inteira tem que passar igual:

```
DEEP_IRON_ISO=1 <Godot>.exe --headless --path . -s addons/gut/gut_cmdln.gd
```

Os Godot filhos de cada bloco herdam a variável.

**Prompt 28 mudou de propósito** `b32_escavadeira_visual` e `b38_centro_por_estagio`: o
"fantasma que fica nítido" saiu e a obra aparece por **estágios** (0–33 / 33–66 / 66–100%,
`scripts/core/obra_estagio.gd`). As checagens de nitidez (alfa) viraram checagens de
estágio.

**Prompt 29 (partes 2–6) mudou de propósito:** `b37_fundacao_raio` (sem o raio do Centro: casa em
qualquer lugar da pedreira, a floresta recusa), `b41_parque` (lugar do parque pelo posicionador aberto,
sem raio), `b48_janela_zoom` (paradas com a densidade da arte nova + a parada "longe"), `p28_iso`
(o F3 saiu: liga/desliga direto e confere que o F3 não troca mais), `b46_menu_construcao` (cartão
"Cozinha").

**Prompt 19 mudou de propósito** `p29_predios`: a camada de janelas acesas não conta como desenho
do prédio. Fotos/GIF do ciclo dia/noite: `tests/ciclo_luz.gd` (com janela, pasta isolada).

## Análise de capacidade (Prompt 29)

`tests/analise_capacidade.gd` (headless, pasta isolada) encaixa casas na pedreira com o
posicionador de verdade até não caber mais e imprime quantas cabem por terraço.

## Capturas pros relatórios (Prompt 29)

`tests/capturas_iso.gd` não é teste: abre a partida, ergue os prédios no layout aprovado, põe
obras em estágios diferentes e salva PNGs. Precisa de JANELA (renderizar) e da pasta isolada:

```
<Godot>.exe --path . -s res://tests/capturas_iso.gd -- <pasta de saída>
```

(com `APPDATA` apontando pra uma pasta com `fake_appdata` no caminho; não rode ao mesmo tempo
que a bateria usando a MESMA pasta: ele apaga o save de lá ao começar.)

## Revisão visual e desempenho (Prompt 30)

Não são testes (não dão OK/FALHOU); precisam de JANELA e da pasta isolada, como as capturas:

- `tests/qa_prompt30.gd -- <pasta>`: vila cheia, as 4 estações, noite, onda solar, invasão,
  obras, nível 2, abismo e o mapa de longe; uma foto de cada e, em `ordem.txt`, quantos pares
  saíram na ordem errada (tem que ser 0);
- `tests/desempenho_iso.gd -- <pasta>`: fps em 1920×1080 em 5 situações (até o mapa cheio).

Da raiz do repositório (Python):

- `python tools/qa_arte.py <saida.json>`: brilho, saturação e contorno de cada desenho, por
  categoria, e o que destoa;
- `python tools/contorno.py`: contorno de 1 px nos desenhos da lista (rodar de novo não muda nada).

**Disco:** em 2026-10-01 o C: encheu (0 GB). Dá pra pôr a pasta isolada e os temporários no D:
(`APPDATA`, `XDG_DATA_HOME`, `TEMP` e `TMP` apontando pra uma pasta no D: com `fake_appdata` no
caminho); o `test_blocos.gd` cria as pastas dos blocos dentro do `TEMP`.

## Conhecido

- `b45_coletor_madeira` às vezes falha em "lenhador manual trabalha em paralelo": o lenhador
  sorteou um acidente cortando árvore e está internado na hora da conferência (visto 1 vez
  em 4 rodadas no Prompt 28; sozinho passou 2 de 2). É o sorteio do jogo, não a regra.
- `b31b_obras_restantes` às vezes falha com "engenheiro preso a caminho de uma obra"
  depois de carregar (visto 2 em 15 rodadas; causa ainda não achada). Se falhar, rode
  de novo; se repetir, vale investigar.
