# Bloco 74 — a superfície da maquete v3 no jogo

O Marco aprovou a `superficie_v3_legenda.jpg` (2026-10-04: "estou aprovando este superficie_v3_legenda, para
fazer e podemos aplicar no jogo"). A superfície do jogo agora tem as 3 áreas da maquete, de oeste pra leste:
**FLORESTA | VILA | MINA**. Comparação: `docs/arte/bloco74/comparativo.jpg`; fotos no jogo na mesma pasta.

## Como ficou

| Na maquete | No jogo |
|---|---|
| Floresta à esquerda (as criaturas vêm daqui) | Faixa do oeste (x < -300): mata fechada no fundo (50 árvores de enfeite), uma clareira junto da paliçada (onde vão os coletores de madeira), as 6 árvores que dão madeira, o pomar silvestre do caçador, as tocas (coelhos perto, javalis no fundo) e a vegetação rasteira. Os Lumívoros nascem no fundo dela. |
| Paliçada: o único portão | A paliçada corre de norte a sul na divisa, com o portão no meio, na estrada (a arte da paliçada e do portão vira de lado). O caminho da floresta pra vila passa por ele; os guardas ficam do lado da vila. |
| Vila: Centro, igreja, casas, poço, horta, lotes livres | Chão plano (acabaram os terraços e as escadas da vila), 860 × 1472 px: a praça de laje com o Centro da Vila, ruas de terra batida, casas, oficina, cozinha, enfermaria, a horta com espantalho, poço, bancos, a igreja ao norte e muito espaço livre pra construir. **Sem jazida dentro.** |
| Elevador entre a vila e a mina | A torre do elevador continua no mesmo lugar (a coluna dos andares de baixo não mudou). |
| Mina: paredão em degraus | A montanha de pedra em 3 degraus (6, 12 e 18 de altura), com material novo de pedra cinza (`relevo/montanha.py`). |
| Boca da mina + trilho + vagonete + armazém na frente | A boca principal no pé (as bocas são a parede de pedra com a porta de madeira da arte da boca), com dois lampiões; o vagonete fixo sai do batente, desce reto e vira pra porta do armazém, que fica logo na frente. O minerador entrega no vagonete quando é mais perto; o vagonete leva sozinho. |
| 2ª e 3ª aberturas, escadas, andaime, guindaste, casinha de pedra | As galerias ficam nas bocas: Oeste e Sudeste no pé, Norte na 2ª abertura (1º degrau), Nordeste na 3ª (2º degrau). Duas escadas de pedra sobem a montanha. Andaime, escada de mão, guindaste no 2º degrau, casinha de pedra, vagonete na 2ª abertura, pinheiros no alto. |
| Carvão à esquerda da boca, cobre à direita | Isso. E o **ferro** na frente da montanha (ver decisão abaixo). |

## Decisão que precisa do teu ok: o ferro

Na conversa de antes ficou "só carvão e cobre", a partir da informação de que as jazidas iniciais eram
cobre e carvão. **Essa informação estava errada:** as 6 jazidas que o jogo começa são de **ferro**, e o ferro é
o minério de base (armas, pesquisa, vestiário, taverna, parque, conserto). Sem ferro no começo a partida
trava. Então a montanha tem carvão (esquerda), cobre (direita) e o ferro espalhado na frente. Se quiser o
ferro só no leste, dá pra fazer, mas aí precisa rebalancear os custos.

## O que mais mudou por causa do mapa novo

- **Fundação:** o armazém é da mina (o vagonete descarrega nele), então a fundação escolhe só o Centro da
  Vila (começa no meio da vila).
- **Saves antigos:** o que o jogador construiu e agora cairia na floresta (a vila antiga ficava no oeste) vai
  pro lugar livre mais perto do lado da vila; o armazém da fundação vai pra frente da mina. Fica anotado em
  `environment.migrated`. O save do Marco não é alterado (só lido).
- **Clima** vale na superfície toda (antes só na clareira). **Som:** céu aberto na floresta e na vila;
  na área da mina, o som da mina.
- **Leste trancado (Bloco 67):** continua, agora começando onde a mina acaba (x ≈ 1245). A primeira jazida
  dele foi pra x=1620 (antes caía dentro da mina).
- **Montanha anda:** o "degrau 4 = paredão" do mapa antigo saiu; os degraus da montanha andam (as escadas
  ligam) e não dá pra construir neles.
- **Trilho:** desenhado com bitola e dormentes no chão (antes eram traços finos na tela).
- **A "Horta" da cena é o pomar silvestre do caçador** (Bloco 34: o caçador sem arco colhe fruta lá, sem
  sair da floresta): ficou na floresta. A horta da maquete, na vila, é enfeite (horta e espantalho).

## O teu save no mapa novo

Carreguei uma CÓPIA do teu save (o original não foi tocado) no mapa novo: carrega normal. A vila dele
ficava no oeste, que agora é floresta — o Centro da Vila e uma casa estavam bem em cima da linha da
paliçada nova. O que era da vila foi pro lado de dentro da paliçada (encostado nela, na mesma altura do
mapa); o coletor de madeira e o pomar continuam na floresta; o armazém foi pra frente da mina. Funciona,
só que nesse save a vila fica enfileirada junto da paliçada e a praça nova fica vazia (numa partida nova
o Centro nasce na praça). Foto: `docs/arte/bloco74/save_marco_mapa_novo.jpg`.

## Pra ficar de olho no balanceamento

- O **lenhador anda mais**: a floresta está no oeste e o único armazém na mina, no leste (~1,7x a caminhada
  de antes). O coletor de madeira não muda (manda direto pro armazém). Se pesar, dá pra pôr um depósito de
  madeira na vila (ou o armazém mais perto da divisa, com o trilho do vagonete mais comprido).
- O caçador e o cozinheiro também levam/buscam no armazém.

## Desempenho

Vila cheia (40 ipezinhos, noite, chuva, invasão): **19,2 ms / 52 FPS** (antes do bloco: 20,2 ms / 50 FPS).
`docs/bench/bench_2026-10-04_bloco74.txt`.

## Testes antigos ajustados ao mapa novo

Os que testavam a geografia antiga (terraços 96/64, escada em x=640, paredão do oeste, fundação em 2
passos, Centro em (-300, -300)) passaram a testar a nova: `p29_mapa`, `b37_fundacao_raio`, `b67_mapa_leste`
(a área conta a partir do mapa de antes do Bloco 67), `b55_audio` (o som da mina é o da área da mina).
Outros só esbarravam no lugar novo das coisas: `p28_iso` e `b47` (prédios de teste perto do Centro, que
cresce), `b57` (com as jazidas juntas a broca pula pra próxima; o teste escolhe a dele), `b64` (o vagonete
fixo da mina entrava na contagem), `b69` (um enfeite do S1 caía em cima da paliçada).

Rodada final (2026-10-04): os 57 testes de bloco passam. Rodando 3 ao mesmo tempo, `b45` (o lenhador
manual pego no meio de outro estado) e `p29_predios` (1 par de caixas com o z de um boneco atrasado)
falharam uma vez cada e passaram sozinhos — ficam de olho como intermitentes.

## Como refazer

```
cd project.godot/prototipos/camera/arte_iso/relevo && python montanha.py      # material da montanha
cd ../mapa && python monta.py exporta                                         # terreno + mapa.json
<Godot> --headless --path . --import                                          # texturas novas
```

O layout está nas constantes do topo do `monta.py` (PALICADA_X, PORTAO_Y, MINA_X0/X1, DEGRAUS, BOCAS,
ESCADAS_MONTE); a decoração da superfície em `environment.gd` (MAP_DECOR_V3, FOREST_TREES); as posições
das coisas da cena em `scenes/game/main.tscn`.

Testes: `tests/blocos/b74_superficie.gd` (as áreas, o conteúdo de cada uma, o portão, a montanha e as
escadas até as galerias, o vagonete levando até o armazém, guardas, criaturas, clima, construir, save antigo).
Capturas: `tests/capturas_bloco74.gd`.

## Ainda diferente da maquete (próximas rodadas)

- Os **lotes livres** marcados com estaca e corda não foram feitos (a vila tem o espaço, sem marcação).
- A **boca da escada em espiral** na superfície (a casinha coberta à direita da mina) ainda não existe: a
  espiral está só na coluna.
- A faixa das **galerias de madeira** logo abaixo da superfície e os andares como faixas (a coluna da maquete)
  são a próxima etapa do Bloco 72.
