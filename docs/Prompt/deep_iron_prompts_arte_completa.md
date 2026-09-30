# DEEP IRON — Pacote completo de prompts de arte isométrica (PixelLab + Opus local)

Como usar: aplique um prompt por vez, na ordem. Teste, valide, e só então passe pro próximo. Cada prompt é independente e pode ser colado direto no Claude Code local.

O **Prompt 0 vem primeiro, obrigatoriamente**. Ele grava no repositório o contrato de arte e o inventário de tudo que o jogo tem. Todos os outros prompts mandam o Opus ler esses dois arquivos antes de começar, então não é preciso repetir as regras em cada um.

Os prompts 1 e 6 podem já estar em andamento por causa do handoff anterior (elenco e tiles de relevo). Nesse caso, o Opus só completa o que falta.

Sobre crédito: o saldo atual (~1.481 gerações até 29/10) não cobre tudo. Cada prompt manda o Opus estimar o custo antes de gerar e parar no limite, reportando o que ficou faltando. O que não couber neste ciclo continua depois da renovação.

Os prompts **1 a 27 são só arte** (isolada em `prototipos/camera/arte_iso/`, sem mexer no jogo). Os prompts **28 a 30 integram tudo no jogo principal**. O prompt 31 é conteúdo futuro.

| # | Prompt | Checkpoint com Marco? |
|---|---|---|
| 0 | Contrato de arte + inventário + plano de crédito | Sim (aprovar plano) |
| 1 | Elenco humano completo | Não |
| 2 | Animações comuns do elenco | Não |
| 3 | Roupas, casaco e trajes de perigo | Não |
| 4 | Ferramentas e armas | Não |
| 5 | Robô antigo | Não |
| 6 | Terreno da superfície (relevo + estações) | Não |
| 7 | Terreno da mina (subterrâneo) | Não |
| 8 | Jazidas, minérios e rochas | Não |
| 9 | Vegetação e horta | Não |
| 10 | Prédios: vila e moradia | Não |
| 11 | Prédios: alimentação, saúde e lazer | Não |
| 12 | Prédios: pesquisa, defesa e equipamento | Não |
| 13 | Máquinas e grandes estruturas (escavadeira etc.) | Não |
| 14 | Objetos e props | Não |
| 15 | Animais | Não |
| 16 | Criaturas/inimigos — conceito | **Sim** |
| 17 | Criaturas/inimigos — produção | Não |
| 18 | Efeitos visuais e clima | Não |
| 19 | Luz e noite | Não |
| 20 | Interface (UI) — sistema visual | **Sim** |
| 21 | Ícones | Não |
| 22 | Fonte pixel | **Sim** |
| 23 | Retratos e diálogo | Não |
| 24 | Ilustrações de eventos e achados | Não |
| 25 | Tela "Corte da mina" | **Sim** |
| 26 | Título, logo, splash, loading, vitória/derrota | **Sim** |
| 27 | Montagem do mapa com relevo (level design) | **Sim** |
| 28 | Integração 1: motor isométrico no jogo principal | Sim (testar jogando) |
| 29 | Integração 2: troca de toda a arte + saves + janela/zoom | Sim (testar jogando) |
| 30 | Revisão final: QA visual, desempenho, limpeza | Sim |
| 31 | Conteúdo futuro (crianças/escola etc.) | Quando o gameplay existir |

---

## PROMPT 0 — Contrato de arte, inventário e plano de crédito

```
DEEP IRON — Prompt 0: consolidar contrato de arte, inventário de assets e
plano de crédito (NÃO gerar arte nesta etapa)

Contexto: vamos gerar TODA a arte do jogo em isométrico (Rota A), em uma
sequência de ~30 prompts que Marco vai aplicar um por vez. Todos eles vão
começar mandando você ler dois arquivos que você cria agora. Eles precisam
ser completos e ser a fonte única de verdade.

1. Criar docs/arte/CONTRATO_ARTE.md juntando tudo que já foi decidido e
   aprovado (ver ENDURECIMENTO_rota_A.md, CHECKPOINT_2.md, memória do fluxo
   PixelLab e deep-iron-dev-log). Deve conter, no mínimo:
   ESTILO
   - Referência: CraftPix (docs/pixellab_teste/referencia_estilo/) + as 3
     imagens isométricas de referência. Tom "dark/sujo": paleta terrosa,
     brilho médio ~0,22-0,23, desgaste, fuligem, remendos.
   - Texto de estilo obrigatório em toda geração: "Crisp 1px near-black
     outline".
   - Escala: o minerador isométrico aprovado é a régua. Porta de prédio =
     altura do minerador. Prédios em escala real.
   - Sem gore: ferimento, morte e combate sempre sóbrios, sem sangue.
   TÉCNICA
   - Imagem-guia 2:1 desenhada no PixelLab antes de toda geração.
   - Caixa (pegada + altura) declarada antes de gerar cada desenho; no
     máximo 4 px fora da caixa; fundo da caixa fixo na parede de trás.
   - Âncora anotada na exportação; mesma âncora em todas as variações e
     estágios de um mesmo objeto.
   - Personagens e criaturas: 4 direções de losango (2 desenhos + espelho
     por animação); as 8 poses paradas que o PixelLab dá de graça ficam
     guardadas.
   - Animação: skeleton-v3 primeiro; interpolação v3 entre estados quando
     precisar; v3 com texto só se as outras falharem.
   - Tileset: paredes externas de buraco não desenhadas; borda da frente
     tão grossa quanto o buraco é fundo; peças para os 4 lados + cantos.
   REGRAS DE CONTEÚDO
   - Toda estrutura construível tem estágios de obra: obra_1 (fundação e
     material solto), obra_2 (esqueleto/andaime), obra_3 (paredes e
     telhado incompletos) e pronto. Upgrade de prédio (nível 1→2→3)
     também tem obra entre os níveis. No jogo, o desenho troca por
     progresso do engenheiro (0-33 / 33-66 / 66-100%). Nunca o "fantasma
     que fica nítido".
   - Diversidade: todo humano cobre homens e mulheres e pele branca, parda
     e negra (paletas_pele.json, troca de paleta no código).
   - Picareta híbrida: overlay nas costas (atrás do corpo de frente pra
     câmera, na frente de costas); embutida na animação de golpe.
   - Machucado do elenco: ícone de curativo/tala sobreposto + pose parada
     com respiração por código.
   - Estações: o que é natural (chão, árvores, vegetação, telhados) tem
     variante por estação, se o jogo usar estação nesse elemento.
   PROCESSO (vale pra TODO prompt de arte)
   - Ler este contrato e o INVENTARIO.md antes de começar.
   - Estimar o custo em gerações antes de gerar. Se passar do saldo do
     ciclo, gerar só o que cabe, pela prioridade do inventário, e parar
     reportando o que faltou e quanto custa.
   - Gerar 1 peça-piloto de cada tipo novo e passar no verificador
     automático (cena de estresse + ordem por caixas). Se passar e seguir
     o contrato, continuar sem esperar Marco, EXCETO nos prompts marcados
     com CHECKPOINT MARCO.
   - Tudo isolado em prototipos/camera/arte_iso/<categoria>/. Nada
     integrado ao jogo principal antes dos prompts de integração.
   - Reportar desvios do contrato em vez de contornar sozinho.
   - Entrega: prancha lado a lado, GIF das animações, custo, desvios e
     INVENTARIO.md atualizado.

2. Criar docs/arte/INVENTARIO.md: varrer o código, as cenas, os dados de
   prédios/pesquisa/itens/eventos e a pasta assets/game/, e listar TODO
   asset visual que o jogo usa hoje ou tem reservado ("em breve"):
   personagens e funções, trajes/roupas, ferramentas/armas, robô,
   invasores, animais, prédios (com estágios visuais), máquinas, reatores,
   terreno (superfície e mina, por nível), jazidas/minérios, vegetação,
   horta, objetos, efeitos, luzes, UI (HUD, menus, cartões, cursores),
   ícones (recursos, necessidades, status, pesquisa, itens), fontes,
   retratos, imagens de evento, telas (título, loading, vitória/derrota).
   Pra cada item: prompt que o gera (1 a 31), status (falta / piloto /
   gerado / aprovado / integrado), quantas variações, direções,
   animações e estimativa de gerações.
   Itens que já estão prontos (minerador isométrico, casa com obra e 4
   variações) entram como "aprovado".

3. Plano de crédito: somar a estimativa total, comparar com o saldo atual
   e com o ciclo que renova em 29/10, e propor o que entra em cada ciclo,
   priorizando o que o jogo precisa pra rodar com a arte nova (elenco,
   terreno, prédios base, UI básica) antes de enfeite (splash, variações
   extras).

CHECKPOINT MARCO: parar e mostrar o inventário + o plano de crédito.
Não gerar nenhuma arte neste prompt.
```

---

## PROMPT 1 — Elenco humano completo

```
DEEP IRON — Prompt 1: elenco humano completo (isométrico)

Antes de começar: ler docs/arte/CONTRATO_ARTE.md e docs/arte/INVENTARIO.md.
Se parte do elenco já foi gerada pelo handoff anterior, só completar o que
falta. Ao terminar, atualizar o INVENTARIO.md.

Gerar, pra cada função do jogo (confirmar a lista no código: minerador,
engenheiro, guarda, médico, cozinheiro, caçador, lenhador, pesquisador e as
demais), a versão masculina e a feminina:
- Corpo com a roupa de trabalho típica da função, silhueta que diferencia
  uma função da outra de longe (chapéu, avental, colete, jaleco, capuz...).
- 4 direções de losango: parado e andar.
- 1 animação de trabalho característica da função, nas 4 direções:
  minerador minerando (já existe no top-down, refazer em iso), engenheiro
  martelando/construindo, guarda em guarda/atacando, médico atendendo,
  cozinheiro mexendo panela, caçador atirando/armando, lenhador cortando,
  pesquisador mexendo em bancada, etc.
- Arte "neutra" pra receber as 3 paletas de pele e variações de cabelo/
  roupa por código. Confirmar que as 3 paletas ficam boas em cada um
  (prancha com as 3 peles lado a lado).
- Distribuir cabelos/rostos de forma variada entre as funções (não fazer
  todos com a mesma cara).

Entrega: prancha do elenco inteiro com as 3 peles, GIFs de andar e de
trabalho, custo, inventário atualizado.
```

---

## PROMPT 2 — Animações comuns do elenco

```
DEEP IRON — Prompt 2: animações comuns do elenco

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Contexto: as animações de trabalho de cada função já existem (Prompt 1).
Agora, as animações que todo ipezinho usa na rotina, conforme os sistemas
que o jogo já tem (confirmar no código quais estados existem de verdade):
- Carregar recurso andando (caixa/saco/pedra/tora nos braços ou nas
  costas), 4 direções.
- Comer (sentado ou em pé no comedouro/refeitório).
- Dormir/descansar (deitado, pose parada + respiração por código).
- Sentar e beber (taverna) e sentar no parque.
- Comemorar (festa).
- Protestar (greve): braços cruzados/placa.
- Machucado leve: andar mancando (4 direções).
- Machucado grave/incapacitado: pose sentada ou caída, parada, com tala
  (respiração por código). Sem gore.
- Morte por fome/frio: pose caída sóbria. Sem gore.

Economia: avaliar se dá pra gerar essas animações uma vez por corpo base
(masculino/feminino) e reaproveitar entre funções com troca de roupa por
paleta/overlay. Se ficar ruim, gerar por função só as que aparecem muito
(carregar, comer, dormir) e usar corpo base no resto. Reportar a escolha.

Entrega: GIFs, custo, inventário atualizado.
```

---

## PROMPT 3 — Roupas, casaco de inverno e trajes de perigo

```
DEEP IRON — Prompt 3: equipamento vestível (casaco, couro, trajes de perigo)

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Contexto: o jogo tem equipamento (Bloco 42): casaco de inverno, 3 trajes
de perigo (gás, calor, radiação), couro, auto-equipar e desgaste em uso.

Gerar:
- Trajes de perigo: como cobrem o corpo inteiro, fazer 1 personagem por
  traje (masculino e feminino), não 1 por função. Cada um com parado,
  andar, trabalhar (minerar, que é onde ele é usado) e carregar, nas 4
  direções. Cores bem distintas pra ler de longe: gás (amarelo com
  máscara/filtro), calor (prateado/aluminizado), radiação (verde-oliva
  com visor). Conferir nomes/cores com o que o jogo já mostra.
- Casaco de inverno e peças de couro: decidir a forma mais barata que lê
  bem: overlay por cima do corpo da função, versão por corpo base, ou
  versão por função. Reportar a escolha e o custo de cada opção antes de
  gerar em massa.
- Estados de desgaste visíveis (novo, gasto, quase rasgado), se o custo
  couber; senão, desgaste só por ícone na UI.
- Ícones de inventário/vestiário de cada peça (podem vir da própria arte
  reduzida, sem gerar de novo).

Entrega: prancha, GIFs, custo, inventário atualizado.
```

---

## PROMPT 4 — Ferramentas e armas

```
DEEP IRON — Prompt 4: ferramentas e armas

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Gerar, pra cada ferramenta/arma que o jogo usa (confirmar no código):
- Picareta (e níveis de upgrade, se existirem): overlay nas costas nas 2
  configurações (atrás/na frente do corpo) + versão na mão.
- Machado do lenhador, arma/arco/lança do caçador, ferramentas do
  engenheiro, maleta do médico, utensílios do cozinheiro, armas do guarda
  e do Arsenal.
- Armas com os estados de desgaste do jogo (nova, gasta, quebrada).
- Versão "no chão" (item largado) e ícone de UI de cada uma.

Seguir a mesma regra de overlay da picareta pra qualquer ferramenta que
fica nas costas/cinto quando o personagem não está usando.

Entrega: prancha, custo, inventário atualizado.
```

---

## PROMPT 5 — Robô antigo

```
DEEP IRON — Prompt 5: robô antigo

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Contexto: o robô antigo é achado na exploração, trazido, consertado e vira
guarda especial. Tecnologia de antes do colapso solar: metal velho,
ferrugem, peças remendadas, uma luz de "olho" que acende quando ativo.

Gerar:
- Achado: robô desligado, meio enterrado/caído (objeto estático).
- Em conserto: desligado, aberto, com peças e ferramentas em volta
  (2-3 estágios, como uma obra).
- Ativo: 4 direções, parado, andar, atacar, sofrer dano, desligado/
  derrubado (sem explosão exagerada).
- Retrato (pra ser usado no Prompt 23) e ícone.

Entrega: prancha, GIFs, custo, inventário atualizado.
```

---

## PROMPT 6 — Terreno da superfície (relevo + estações)

```
DEEP IRON — Prompt 6: tileset da superfície com relevo e estações

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Se parte já foi
gerada pelo handoff anterior (tiles de relevo), completar o que falta. Ao
terminar, atualizar o INVENTARIO.md.

Gerar um tileset isométrico pro TileMapLayer (terrain sets/autotile), com
transições sem emenda (usar create_topdown/isometric tileset encadeando os
terrenos pelo base_tile_id):
- Pisos: grama, grama alta/seca, terra, trilha de terra batida, cascalho,
  lama, pedra/laje, chão de obra/canteiro. Água só se o jogo tiver.
- Relevo: platôs em 2-3 alturas, paredão/penhasco de rocha (4 lados +
  cantos internos e externos), rampas, escadas de pedra e de madeira,
  beira de buraco (regras do contrato), boca de mina aberta na parede do
  penhasco (com vigas de madeira), clareira.
- Variações de cada piso (pelo menos 3) pra quebrar repetição.
- Estações: variante de verão, outono, inverno (neve) e primavera dos
  pisos naturais, se o jogo usar estação no chão (Bloco 40).

Testar na cena de estresse: platôs em sequência, rampas, buracos, com
ipezinhos andando e o clique por raio funcionando em cada face.

Entrega: prancha do tileset, mini-mapa de teste montado, custo,
inventário atualizado.
```

---

## PROMPT 7 — Terreno da mina (subterrâneo)

```
DEEP IRON — Prompt 7: tileset da mina e dos níveis subterrâneos

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Contexto: o jogo tem galerias por estágio, galerias lacradas, nível 2,
abismo e zonas de gás, calor e radiação (Bloco 42). Cada nível precisa de
identidade visual própria, ficando mais perigoso e estranho quanto mais
fundo (ver imagem de referência 3: poeira → gás verde → calor/lava → fundo).

Gerar, por nível/zona (confirmar a lista no código):
- Piso de galeria, parede de rocha da mina, vigas/escoras de madeira,
  teto rebaixado/borda.
- Galeria lacrada e os estágios de abertura (lacrada → sendo aberta →
  aberta), como uma obra.
- Zona de gás (musgo/rocha esverdeada, poças), zona de calor (rocha
  rachada com brilho de lava), zona de radiação (cristais com brilho),
  abismo (borda seguindo a regra de buraco do contrato).
- Poço da escavadeira e poço do elevador (buraco vertical visto de cima).
- Trilhos no chão da mina (retos, curvas, junções, fim de linha).

Entrega: prancha por nível, mini-cena de teste, custo, inventário
atualizado.
```

---

## PROMPT 8 — Jazidas, minérios e rochas

```
DEEP IRON — Prompt 8: jazidas, minérios, rochas e achados

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Gerar:
- Uma jazida pra cada tipo de minério que o jogo vende/usa (confirmar
  lista na economia), com 4 estados de esgotamento: cheia, meia, quase
  vazia, esgotada. Cada minério com cor/brilho próprio e legível de longe.
- Animação curta de golpe na jazida (lascas saindo) — ou spritesheet de
  lascas pro efeito do Prompt 18.
- Rochas grandes (obstáculo/decoração) em 3-4 formatos, pedregulhos,
  pedras soltas, rochas cobertas de musgo; variante da superfície e da
  mina.
- Cristais das camadas fundas.
- Ponto de achado de exploração (algo meio enterrado brilhando) e o
  entulho que sobra depois de escavar.
- Minério solto no chão/no vagonete e pilha de minério (3 tamanhos).

Entrega: prancha, custo, inventário atualizado.
```

---

## PROMPT 9 — Vegetação e horta

```
DEEP IRON — Prompt 9: árvores, vegetação e horta

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Gerar:
- Árvores (3-4 espécies, incluindo pinheiro e uma árvore grande de copa
  larga), cada uma com: inteira, sendo cortada, caída/tora, toco,
  rebrotando. Caixa bem declarada (a copa é alta e o boneco passa atrás).
- Arbustos, moitas, flores silvestres, grama alta, troncos caídos,
  cogumelos, raízes. Tudo em 3+ variações.
- Variante por estação (verão, outono, inverno com neve, primavera) se o
  jogo usar estação na vegetação.
- Horta: canteiro vazio, preparado, plantado, crescendo, pronto pra
  colher, colhido, pra cada cultura que o jogo tem (confirmar).
- Madeira: tora, lenha empilhada, pilha de tábuas (3 tamanhos).

Entrega: prancha, custo, inventário atualizado.
```

---

## PROMPT 10 — Prédios: vila e moradia

```
DEEP IRON — Prompt 10: prédios da vila e moradia

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

A Casa nível 1 já está aprovada (4 variações + 3 estágios de obra). Usar
ela como referência de escala e estilo.

Gerar, cada um com obra_1, obra_2, obra_3 e pronto (regra do contrato):
- Centro da Vila: os 5 estágios visuais que o jogo tem (Bloco 38), com
  obra entre um estágio e o próximo.
- Armazém: pronto + variantes de lotação (vazio, médio, cheio, com
  pilhas visíveis na frente/porta).
- Casa nível 2 e nível 3: upgrade com obra a partir do nível anterior
  (obra por cima da casa existente, não do zero).
- Oficina (hoje vem fixa na cena; gerar com obra mesmo assim, pro caso de
  ela virar construível).
- Variações de acabamento (2-4) nos prédios que se repetem muito.

Pra cada prédio: declarar pegada/altura antes, imagem-guia 2:1, testar na
ordem por caixas com ipezinhos passando em volta.

Entrega: prancha por prédio (obra → pronto), GIF da obra, custo,
inventário atualizado.
```

---

## PROMPT 11 — Prédios: alimentação, saúde e lazer

```
DEEP IRON — Prompt 11: prédios de alimentação, saúde e lazer

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Gerar, cada um com os 3 estágios de obra + pronto:
- Cozinha/refeitório e comedouros (com estado vazio e com comida).
- Enfermaria (com cruz/símbolo legível, macas visíveis se der).
- Taverna (com mesas/bancos na frente, lampião).
- Parque (área aberta com bancos, árvores, caminhos — pode ser montado
  com peças do Prompt 9 e 14 + 1 peça central).
- Estruturas da horta (cerca, galpão de ferramentas, espantalho).
- Qualquer outro prédio desta categoria que o menu de construção tenha
  (conferir as abas Alimentação, Saúde e Lazer do Bloco 46).

Entrega: prancha, GIF da obra, custo, inventário atualizado.
```

---

## PROMPT 12 — Prédios: pesquisa, defesa e equipamento

```
DEEP IRON — Prompt 12: prédios de pesquisa, defesa e equipamento

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Gerar, cada um com os 3 estágios de obra + pronto:
- Laboratório de pesquisa.
- Arsenal (com armas penduradas/estante visível).
- Vestiário.
- Campo de treino dos guardas (bonecos de treino, alvos).
- Barricadas/muro: peças modulares (reta, canto, ponta, portão), com
  estados de dano (inteira, danificada, brecha aberta — a "brecha" do
  roubo), e barricada comprida testada na ordem por caixas.
- Torre de vigia ou qualquer outra defesa que o jogo tenha (conferir aba
  Defesa e equipamento do menu).

Entrega: prancha, GIF da obra, custo, inventário atualizado.
```

---

## PROMPT 13 — Máquinas e grandes estruturas

```
DEEP IRON — Prompt 13: escavadeira, reatores, elevador, coletores,
satélite e escudo solar

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Contexto: são as peças-símbolo do jogo ("engenheiro improvisando pra salvar
o mundo"). Máquinas pesadas, industriais, remendadas, parecidas com as
torres de perfuração, guindastes e brocas das imagens de referência.

Gerar (todas com obra quando forem construídas pelo jogador):
- Escavadeira: plataforma + broca, estados desligada, ligada perfurando
  (animação em loop), sem reator/parada. Lembrar: não tem operador.
- Reatores: cada tipo que o jogo tem (confirmar; o design previa ~5),
  visual distinto por tipo, com luz/pulso quando ativo.
- Elevador: torre/poço + cabine, animação subindo e descendo.
- Coletor de madeira: parado e operando (animado).
- Coletor de minério (reservado "em breve" no menu): parado e operando.
- Satélite de comunicação: obra + pronto + antena girando.
- Escudo solar (vitória): obra longa (mais estágios se fizer sentido),
  pronto e ativado (cúpula/campo de energia, efeito no Prompt 18).
- Guindaste/torre de perfuração decorativa, como nas referências, se
  couber no saldo.

Entrega: prancha, GIFs das máquinas funcionando, custo, inventário
atualizado.
```

---

## PROMPT 14 — Objetos e props

```
DEEP IRON — Prompt 14: objetos soltos e props do mapa

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Gerar com create_map_object (ou equivalente), com caixa e âncora:
- Caixotes (vários), barris, sacos, pilhas de tábuas, sucata, pneus/
  rodas velhas, correntes, cordas.
- Trilhos da superfície (retos, curvas, junções, fim de linha) e
  vagonete (vazio e cheio, andando nas 4 direções).
- Tochas de parede e de chão (chama animada), lampiões, fogueira
  (animada), braseiro.
- Placas de aviso usando pictogramas (caveira, raio, gás) em vez de texto
  escrito, cercas modulares, postes, andaime solto, escadas de mão.
- Mobília externa: bancos, mesas, varal, poço d'água, carrinho de mão,
  bigorna, ferramentas encostadas.
- Pilhas de recurso em 3 tamanhos pra cada recurso do jogo (madeira,
  pedra, cada minério, comida, couro).
- Ossos/restos antigos e destroços pré-colapso (placas de metal, carcaça
  de máquina) pra decoração e achados.

Entrega: prancha, GIFs, custo, inventário atualizado.
```

---

## PROMPT 15 — Animais

```
DEEP IRON — Prompt 15: animais de caça e fauna

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Gerar:
- Animais de caça que o caçador caça (confirmar no código; se não houver
  lista, propor: javali, coelho, cervo, ave grande): 4 direções, parado,
  andar, fugir, abatido (pose caída, sem sangue).
- Carcaça/carne pra carregar e ícone de carne/couro.
- Fauna de ambiente sem gameplay (se couber no saldo): pássaros voando,
  coelhos pulando entre arbustos, ratos na mina, morcegos nas galerias.
- Toca/ninho como objeto do mapa.

Entrega: prancha, GIFs, custo, inventário atualizado.
```

---

## PROMPT 16 — Criaturas/inimigos: conceito (CHECKPOINT)

```
DEEP IRON — Prompt 16: conceito das criaturas e inimigos (só conceito)

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md.

Contexto: as invasões já existem no jogo (Arsenal, desgaste de armas,
guarda caído, roubo pela brecha) e ficam mais fortes com o tempo, mas o
design visual dos invasores nunca foi definido. Universo: mundo
tecnológico que colapsou após uma grande explosão solar; sobreviventes
numa "idade das trevas"; radiação solar como ameaça.

1. Ver no código o que os invasores são hoje (humanos? criaturas? quantos
   tipos? têm níveis?) e quais estados/animações a lógica usa.
2. Propor 3 linhas de conceito coerentes com o universo, por exemplo:
   saqueadores humanos de outras colônias; criaturas mutadas pela
   radiação; coisas vindas das profundezas da mina. Pra cada linha, 2-3
   tipos (fraco, médio, forte) que mostrem a escalada ao longo do jogo.
3. Gerar só imagens de conceito (1 imagem parada por tipo, create_image_pro
   com as referências de estilo), no mesmo tom dark/sujo, legíveis na
   escala do minerador.
4. Montar prancha comparando as linhas, com a silhueta de cada tipo ao
   lado do minerador e do guarda.

CHECKPOINT MARCO: parar e mostrar as propostas. Não gerar personagens
animados antes de Marco escolher.
```

---

## PROMPT 17 — Criaturas/inimigos: produção

```
DEEP IRON — Prompt 17: produção das criaturas/inimigos aprovados

Antes de começar: ler CONTRATO_ARTE.md, INVENTARIO.md e a decisão de Marco
sobre o conceito (Prompt 16). Ao terminar, atualizar o INVENTARIO.md.

Pra cada tipo aprovado:
- 4 direções: parado, andar, correr/investir, atacar, sofrer dano,
  derrubado/morto (sem gore; pode desfazer em poeira/fumaça se for
  criatura).
- Variante de nível/força, se o jogo escalar a invasão por tier (mudança
  visível: armadura, tamanho, cor, brilho).
- Animação de roubo/carregar item (a lógica de "roubo pela brecha").
- Ícone de alerta de invasão e retrato (se entrar em evento).

Entrega: prancha, GIFs, custo, inventário atualizado.
```

---

## PROMPT 18 — Efeitos visuais e clima

```
DEEP IRON — Prompt 18: efeitos visuais, partículas e clima

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Gerar spritesheets de efeito (animate_image ou create_image com quadros),
e decidir com critério o que fica melhor como partícula do Godot usando
textura pequena gerada:
- Trabalho: poeira e lascas de picareta, faíscas (forja/arsenal/oficina),
  serragem do machado, poeira de obra, martelada.
- Fogo e fumaça: chama pequena/média/grande, fumaça de chaminé, fumaça
  escura (máquina/incêndio), vapor.
- Mina: nuvem de gás verde, ondulação de calor, brilho de radiação,
  gotas caindo, pedra caindo (acidente).
- Grandes eventos: onda solar (luz forte/distorção no céu/tela), escudo
  solar ativando e ativo, satélite transmitindo.
- Clima: chuva, neve caindo, neblina, vento (folhas voando), por estação.
- Festa: fogos, bandeirinhas, confete. Greve: fumaça/placas.
- Interface no mundo: círculo de seleção no chão (iso), marcador de
  destino, marcador de construção válida/inválida, brilho de achado,
  indicador de "ferido" sobre o personagem.

Entrega: GIF de cada efeito, custo, inventário atualizado.
```

---

## PROMPT 19 — Luz e noite

```
DEEP IRON — Prompt 19: iluminação, dia/noite e janelas acesas

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Contexto: o jogo tem ciclo dia/noite. Na arte nova, a noite deve ter clima
(referência: lampiões e janelas acesas das imagens de referência).

Gerar/produzir:
- Texturas de luz (PointLight2D) pra tocha, lampião, fogueira, forja,
  lanterna do capacete, reator, cristais, lava.
- Máscara de janelas acesas pra cada prédio com janela (overlay que
  acende à noite), gerada a partir da arte dos prédios, sem gerar prédio
  novo.
- Ponto de luz anotado por peça (regra do endurecimento: 1 ponto por
  peça, vem com a arte).
- Proposta de cor/intensidade por período (amanhecer, dia, entardecer,
  noite) e por estação, testada numa cena com vila + mina.

Entrega: GIF de um ciclo dia/noite na cena de teste, custo, inventário
atualizado.
```

---

## PROMPT 20 — Interface (UI): sistema visual (CHECKPOINT)

```
DEEP IRON — Prompt 20: sistema visual da interface

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Contexto: a UI precisa combinar com a arte nova (madeira velha, metal
enferrujado, rebites, couro, tom escuro), mas continuar legível em tela
cheia 1080p e maior. Usar UI Template Pro do PixelLab, gerando peças
9-slice reutilizáveis.

Gerar:
- Moldura de painel/janela (grande e pequena), barra de título, separador.
- Botões: normal, hover, pressionado, desabilitado; botão de ícone
  quadrado; botão de aba (8 abas do menu de construção).
- Barra inferior do HUD e barra de recursos.
- Cartão do menu de construção (normal, bloqueado, "em breve").
- Tooltip, janela de evento/decisão, caixa de confirmação.
- Barras de progresso (obra, fome, ânimo, saúde, pesquisa), slider,
  checkbox, campo de lista/rolagem.
- Controles de velocidade (pausa, 1x, 2x, 3x).
- Cursor do mouse: normal, construir, proibido, atacar, selecionar.
- Painel de seleção de personagem e de prédio.

Montar mockup de 3 telas (jogo com HUD, menu de construção aberto,
janela de evento) com a arte nova ao fundo.

CHECKPOINT MARCO: mostrar o mockup antes de gerar o restante das peças.
```

---

## PROMPT 21 — Ícones

```
DEEP IRON — Prompt 21: ícones do jogo

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md (a lista de ícones
está lá). Ao terminar, atualizar o INVENTARIO.md.

Gerar em um tamanho base único (definir: 32 ou 48 px) e no mesmo estilo
da UI aprovada:
- Recursos: créditos, madeira, pedra, cada minério, cada comida, couro,
  e qualquer outro recurso da economia.
- Necessidades e status: fome, ânimo, saúde, frio, cansaço, ferido leve,
  ferido grave (curativo/tala — o mesmo usado sobre o personagem), greve,
  doente se existir.
- Funções (as 9), equipamentos e trajes, ferramentas e armas.
- Pesquisa: um ícone por tecnologia dos 3 ramos (Mina, Vila, Sol).
- Alertas: invasão, onda solar, falta de comida, obra parada, reator
  sem combustível.
- Prédios pro menu de construção: reaproveitar a arte pronta de cada
  prédio (render reduzido), sem gerar de novo.

Onde der, reaproveitar a arte já gerada reduzida pra economizar crédito.

Entrega: folha de ícones, custo, inventário atualizado.
```

---

## PROMPT 22 — Fonte pixel (CHECKPOINT)

```
DEEP IRON — Prompt 22: fonte pixel do jogo

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Gerar com Create Font:
- Fonte de texto corrido, legível em tamanho pequeno, com TODOS os
  caracteres do português: á à â ã é ê í ó ô õ ú ç (maiúsculas e
  minúsculas), pontuação, números com largura fixa pro HUD, símbolos
  (%, +, -, /, :, $).
- Fonte de título, mais pesada/estilizada, combinando com o tom
  industrial/dark (será usada no logo DEEP IRON e em cabeçalhos).
- Exportar num formato que o Godot usa (.ttf/.otf ou fonte bitmap) e
  testar nos componentes da UI aprovada.

Montar amostra com textos reais do jogo (nomes de prédios, descrições de
cartão, números do HUD, uma janela de evento).

CHECKPOINT MARCO: mostrar a amostra antes de trocar a fonte no projeto.
```

---

## PROMPT 23 — Retratos e diálogo

```
DEEP IRON — Prompt 23: retratos de personagens e expressões

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Gerar com Create Portrait Character, a partir do elenco aprovado (mesma
roupa, cabelo e rosto do sprite):
- Retrato por função, masculino e feminino, compatível com as 3 paletas
  de pele (regra de diversidade).
- Expressões: neutro, contente, cansado/triste, bravo (greve), ferido.
- Retrato do robô antigo e dos tipos de invasor que aparecerem em
  eventos.
- Animação de fala (Create Vocal Animation) só pro que aparecer em evento
  com diálogo, se couber no saldo.

Uso: painel de seleção de personagem e janelas de evento.

Entrega: prancha de retratos com as 3 peles, custo, inventário atualizado.
```

---

## PROMPT 24 — Ilustrações de eventos e achados

```
DEEP IRON — Prompt 24: ilustrações de eventos, expedições e achados

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Contexto: o design prevê que expedições e eventos mostrem uma imagem da
situação pra o jogador decidir arriscar ou não.

1. Listar no código todos os eventos, achados e decisões que mostram (ou
   deveriam mostrar) uma imagem.
2. Gerar 1 ilustração por evento (create_image_pro, formato de cartão
   horizontal, mesmo estilo e paleta), incluindo: expedição, achado do
   robô, achado de reator, acidente na mina, invasão chegando, greve,
   festa, onda solar se aproximando, escudo ativado (vitória), colônia
   colapsando (derrota). Sem gore.
3. Onde o evento tiver resultado bom/ruim, avaliar se vale uma segunda
   imagem pro resultado.

Entrega: galeria das ilustrações, custo, inventário atualizado.
```

---

## PROMPT 25 — Tela "Corte da mina" (CHECKPOINT)

```
DEEP IRON — Prompt 25: tela "Corte da mina" (vista lateral)

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Contexto: a imagem de referência 3 (corte tipo formigueiro) vira uma tela
separada, aberta sob demanda: vista de lado com todos os níveis empilhados
(superfície, poeira, gás, calor, fundo/abismo), ligados por elevador e
escada, mostrando onde estão os ipezinhos e a escavadeira. O mapa já
empilha os níveis no eixo Y (fundo a partir de y≈700, abismo a partir de
y≈1420), então os dados já existem.

1. Propor layout da tela (o que mostra, o que é clicável, se tem
   minimapa), sem gerar arte ainda.
2. Gerar a arte de lado: fundo de cada camada (create_sidescroller_tileset
   ou create_image_pro), elevador e escada em corte, ícones/mini-bonecos
   dos ipezinhos por função, escavadeira em corte, zonas de perigo.
3. Mockup da tela com dados reais de um save.

CHECKPOINT MARCO: mostrar o layout (passo 1) antes de gerar a arte.
```

---

## PROMPT 26 — Título, logo, splash, loading, vitória e derrota (CHECKPOINT)

```
DEEP IRON — Prompt 26: tela de título, logo, splash art e telas
especiais

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Gerar:
- Logo "DEEP IRON" em pixel art (metal pesado, ferrugem, brilho quente),
  usando a fonte de título do Prompt 22 como base.
- Splash/key art: a grande ilustração da capa. Cena ampla no estilo das
  imagens de referência: vila no platô, mina no penhasco, escavadeira
  perfurando, céu com o sol ameaçador. Aqui SIM é uma imagem única
  pintada (não modular).
- Fundo animado do menu principal (camadas com leve movimento/parallax,
  fumaça, luz).
- 2-3 telas de loading com dicas.
- Tela de vitória (escudo solar ativado) e de derrota (fome, invasão,
  colapso por insatisfação), sem gore.

CHECKPOINT MARCO: mostrar 2-3 propostas de key art antes de finalizar.
```

---

## PROMPT 27 — Montagem do mapa com relevo (CHECKPOINT)

```
DEEP IRON — Prompt 27: montagem do mapa (level design com relevo)

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Ao terminar,
atualizar o INVENTARIO.md.

Contexto: com terreno, vegetação, rochas, prédios e objetos prontos, o
mapa precisa ser redesenhado com relevo de verdade (hoje ele é plano).
Isso mexe em rota e em onde dá pra construir, então é decisão de design.

1. Propor o layout do mapa da superfície e da entrada da mina, no
   espírito das referências: vila num platô, paredão com as bocas de mina,
   clareira de madeira, floresta com caça, trilhas, rampas e escadas
   ligando as alturas. Respeitar as regras que o gameplay já usa: raio do
   Centro da Vila pra casas, clareira pro lenhador/coletor, área da horta,
   rota dos invasores e da brecha, posição da escavadeira e do elevador.
2. Montar o mapa no TileMapLayer (prototipo) com a arte nova e decoração.
3. Testar: navegação de todos os pontos, clique por raio, construção nas
   áreas válidas, invasão chegando pelo caminho previsto, desempenho com
   o mapa cheio.

CHECKPOINT MARCO: mostrar o layout (passo 1, pode ser um esboço/mockup)
antes de montar; e mostrar o mapa montado antes da integração.
```

---

## PROMPT 28 — Integração 1: motor isométrico no jogo principal

```
DEEP IRON — Prompt 28: integrar o motor isométrico no jogo principal

Antes de começar: ler CONTRATO_ARTE.md, ENDURECIMENTO_rota_A.md e
INVENTARIO.md. Esta é a primeira etapa que mexe no jogo de verdade.
Trabalhar em branch própria.

Levar do protótipo pro jogo principal, SEM trocar a arte ainda (pode usar
as caixas provisórias):
- Camada de projeção (tela = (x−y, (x+y)/2)) e a inversa pro mouse; a
  lógica continua no chão cartesiano.
- Ordem por caixas incremental, com os itens que ficaram pendentes:
  reordenar só o pedaço afetado ao construir/demolir (sem o tranco de
  ~100 ms), verificador de sprite-cabe-na-caixa, prédio em "L" como 2
  caixas.
- Clique por raio da câmera; clique em parede redireciona/recusa.
- Posicionador (fantasma) em isométrico, e a troca do "fantasma que fica
  nítido" pelos estágios de obra por progresso (0-33 / 33-66 / 66-100%).
- Direções do personagem: 4 de losango + regra da picareta/ferramenta
  nas costas.
- Paletas de pele por código.
- Relevo como mapa de altura (sem ponte/túnel sobre caminho).

Critérios: todos os testes GUT passando; saves atuais carregando
(conferir por md5 num save de teste, nunca no save real); nenhum sistema
de gameplay com comportamento diferente.

Entrega: relatório, lista do que mudou por arquivo, testes. Marco testa
jogando antes do Prompt 29.
```

---

## PROMPT 29 — Integração 2: troca da arte, mapa novo, saves e janela/zoom

```
DEEP IRON — Prompt 29: trocar toda a arte, integrar o mapa novo e ajustar
janela/zoom

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Depende do
Prompt 28 aprovado.

- Trocar toda a arte provisória pela arte aprovada (personagens, trajes,
  ferramentas, robô, invasores, animais, prédios com obra, máquinas,
  terreno, jazidas, vegetação, objetos, efeitos, luzes, UI, ícones,
  fonte, retratos, ilustrações). Mover pra assets/game/ seguindo a
  convenção de pastas (minúsculas, sem problema de case no export).
- Colocar o mapa novo do Prompt 27.
- Migração de saves: posições antigas continuam válidas no chão
  cartesiano; conferir o que cai em penhasco/área inválida no mapa novo e
  resolver com regra (realocar pro ponto válido mais próximo) + aviso no
  relatório.
- Rever o Bloco 48 (janela, tela cheia, zoom em pixel inteiro) pro
  isométrico e pra escala nova: zoom mínimo/máximo, zoom inteiro sem
  borrar pixel, tela cheia fora da aba Game embutida do editor.
- Tela "Corte da mina", tela de título, loading, vitória/derrota.
- Marcar tudo como "integrado" no INVENTARIO.md.

Critérios: testes GUT passando, save de teste migrado sem erro, jogo
rodando em tela cheia 1080p sem queda de desempenho perceptível.

Entrega: relatório + vídeo/GIF de uma partida curta. Marco testa jogando.
```

---

## PROMPT 30 — Revisão final: QA visual, desempenho e limpeza

```
DEEP IRON — Prompt 30: revisão final da arte integrada

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md.

1. QA visual: percorrer o jogo (todas as estações, dia/noite, todos os
   níveis da mina, uma invasão, uma onda solar, construção de cada
   prédio) e listar: ordem de desenho errada, pixel borrado, âncora
   torta, cor fora da paleta, contorno diferente, ícone ilegível, texto
   cortado, emenda de tile.
2. Consistência: comparar brilho/paleta entre categorias geradas em
   momentos diferentes e corrigir as que destoam.
3. Desempenho: medir com o mapa cheio (muitos ipezinhos, invasão, clima,
   luzes) e otimizar (atlas, partículas, luzes).
4. Limpeza: apagar arte provisória e protótipos que não são mais usados
   (manter os relatórios em docs/), conferir que INVENTARIO.md está todo
   "integrado".
5. Lista final do que ficou pro futuro.

Entrega: relatório com antes/depois das correções.
```

---

## PROMPT 31 — Conteúdo futuro (quando o gameplay existir)

```
DEEP IRON — Prompt 31: arte de conteúdo futuro

Antes de começar: ler CONTRATO_ARTE.md e INVENTARIO.md. Usar só quando o
sistema de gameplay correspondente existir (ou for começar), pra não gerar
arte que ninguém usa.

Itens previstos no backlog:
- Escola (com obra) e crianças: masculino e feminino, 3 peles, 4
  direções, andar, brincar, estudar; proporção infantil clara ao lado
  dos adultos.
- Casas nível 2/3 e Coletor de minério, se ainda não foram gerados.
- Oficina construível (se sair do fixo da cena).
- Novos tipos de reator, picaretas/armas de nível mais alto, novos
  trajes.
- Novos tipos de invasor/criatura das fases mais fundas.
- Novos eventos e ilustrações.

Cada item segue o contrato inteiro (obra, diversidade, 4 direções,
imagem-guia, caixa/âncora).
```
