# Prompt 29, parte 2: os prédios com a arte nova

Data: 2026-10-01. Branch `isometrico`. Sem geração no PixelLab (saldo **1.439**).

A 2ª parte do Prompt 29 troca a arte antiga dos **prédios** pela arte isométrica aprovada
(Prompts 10–13), no mapa novo da parte 1. Bonecos, árvores, pedras, jazidas e os andares de
baixo continuam com a arte antiga: vêm nas próximas partes.

## Como testar

Abra o jogo (a vista iso já abre no mapa novo).

**O que olhar:**

- as **3 casas** (com variação), Centro da Vila, armazém, oficina, enfermaria e comedouro com o
  desenho novo, no tamanho real;
- construa uma **taverna**, um **laboratório** etc.: a obra sobe pelos desenhos **obra_1 → obra_2
  → obra_3** (0–33 / 33–66 / 66–100% do engenheiro) e vira o prédio pronto;
- **Centro da Vila**: um desenho por estágio (barraca → cidade com torre); expandindo, aparece o
  andaime do próximo estágio;
- **Escavadeira**: plataforma vazia → estrutura → cada peça instalada aparece no lugar dela; a peça
  em montagem sobe pelo corte; pronta, o reator aparece embaixo do convés;
- **Escudo**: uma etapa por vez (fundação, bobinas, núcleo, emissor);
- **taverna ampliada** e **enfermaria ampliada** (nível 2) com o desenho de 2 andares;
- **comedouro** vazio / com comida;
- **portão da floresta** (quebrado e níveis 1–3) e a **paliçada** inteira entre a floresta e a vila;
- os bonecos **não atravessam mais as paredes**: a pegada de cada prédio é a do desenho (a casa
  antiga bloqueava uma faixa de 48×14; a nova bloqueia 89×76). Camas, postos de trabalho e o lugar
  do engenheiro ficam na frente da parede;
- **posicionar** casa/prédio: o fantasma é o desenho novo e a pegada é a nova (não dá mais pra
  colar uma casa na outra).

## Como ficou

Capturas nesta pasta: `p2_vila_oeste.png` (casas, Centro estágio 3, casa em obra),
`p2_vila_leste.png` (laboratório, enfermaria, coreto do parque), `p2_terraco_meio.png` (armazém,
comedouro, arsenal), `p2_obras.png` (taverna, laboratório e comedouro em obra), `p2_centro.png`
(Centro de perto), `p2_escavadeira.png` (estrutura + motor, cabine em montagem),
`p2_portao_palicada.png` (portão e paliçada).

As capturas saem de `tests/capturas_iso.gd` (com janela, pasta de usuário isolada).

## Decisões

| Decisão | Por quê |
|---|---|
| **Um registro só** da arte nova: `python integra.py predios` copia os desenhos pra `assets/game/iso/predios/<prédio>/<estado>.png` e grava o `predios.json` (por estado: imagem, âncora, caixa) | a regra do contrato (cada desenho com a sua caixa e a sua âncora) num arquivo que o jogo lê; pastas e nomes em minúsculas |
| Caixas que faltavam (obras e níveis sem contrato, máquinas, portão, paliçada) encaixadas pelo mesmo método do `predio.py` (parede de trás fixa, ≤ 4 px fora) | o verificador do jogo (`iso_art_check.gd`) confere todas: 75 desenhos, todos ≤ 4 px fora |
| `scripts/iso/iso_art.gd` decide o desenho **só olhando o estado do jogo** (obra, progresso, nível, estágio, peças, comida) | nenhum sistema de jogo mudou pra isso; a vista espelha o estado |
| No espelho, o desenho antigo some e a arte nova entra **no tamanho dela** (px de arte), na âncora; rótulos ficam logo acima do telhado novo; luzes e fumaça vão pra proporção do desenho | a escala 1,5 do mapa vale pra lógica, não pra arte nova (já desenhada em escala real) |
| **Pegada de navegação = a do pronto ÷ 1,5** (e os slots na beira dela, + 12 px) | o layout aprovado no Prompt 27 já previa os prédios nesse tamanho (0 sobreposição entre os prédios da cena); com a pegada antiga, os bonecos andavam por dentro das paredes e a ordem de desenho quebrava |
| A **área de interação** de cada estação cresce até cobrir os slots novos, inclusive nas de raio fixo (laboratório, arsenal, campo de treino, coletor, taverna, enfermaria, oficina, Centro, escavadeira) | nessas, só "trabalha" quem está dentro da área: com os slots na beira do prédio novo, a pesquisa/o treino parariam |
| Ponto de trabalho do engenheiro e porta do médico: **na frente da pegada** (`IsoArt.front`) | os 26–40 px de antes caíam dentro do prédio novo (inalcançável) |
| **Invasores** atacam/saqueiam um prédio ao chegar a `attack_range + 10` da **parede** (pegada nova), não mais do centro | o centro do prédio novo fica a ~55 px da parede: o invasor encostava e nunca alcançava (sem saque no armazém, sem ataque a casa acesa). Achado pela bateria (b36) |
| O espelho de um prédio **já nasce** com a caixa do desenho novo | trocar a caixa no 1º quadro forçava uma reordenação completa (achado pelo p28_iso) |
| Posicionador: pegada do desenho + degrau da porta; o Centro reserva a pegada do **estágio 5** | o Centro cresce no lugar: uma casa posta perto dele no estágio 1 não pode ficar embaixo do estágio 5 |
| Obra **com** desenhos (casa, taverna, armazém...): obra_1/2/3 pelo progresso. **Sem** desenhos (coletor, peças da escavadeira, etapas do escudo): o desenho pronto subindo pelo corte do Prompt 28 | regra do contrato (estágios pelo progresso, nunca o fantasma) com o que existe |
| Centro expandindo: o desenho de **obra** do próximo estágio (andaime sobre o de agora) durante toda a expansão | o Prompt 10 fez 1 obra entre estágios |
| Escavadeira: estrutura + **cada peça como camada** (a região dela recortada do pronto, `regioes.json`) | o jogo instala as peças em qualquer ordem; as etapas do Prompt 13 eram numa ordem fixa |
| **Portão espelhado** (eixo i) | foi desenhado no eixo j, mas a paliçada do mapa corre no eixo i. Muro fino: a troca de luz quase não aparece (mesma regra da reta_j do Prompt 12). **Desvio do contrato** (espelho), aceito pra muro fino; reportado |
| Paliçada: um trecho do muro nível 1 por tile ao longo da linha da navegação, um danificado a cada 7; entra na ordem como caixa fina, sem clique | a parte 1 tinha só a parede invisível da navegação |
| **Migração** (save antigo): prédio posto pelo jogador que ficou em cima de outro com a pegada nova vai pro ponto livre mais perto (chão plano), anotado em `environment.migrated`; os da cena ficam | a regra antiga deixava casas a ~60 px uma da outra; com a pegada nova elas se sobrepõem |
| Taverna ampliada = `nivel_2` com nível 2; enfermaria ampliada = `nivel_2` com a melhoria Enfermaria ≥ 2 | o jogo não tem "ampliação" da enfermaria como estado próprio; escolhi a metade das melhorias |

## Mudanças por arquivo

| Arquivo | O quê |
|---|---|
| `prototipos/camera/arte_iso/integra.py` (novo) | `python integra.py predios [nomes]`: copia a arte, encaixa as caixas que faltam, peças e reatores da escavadeira, grava o `predios.json` |
| `assets/game/iso/predios/` (novo) | 15 prédios (o Centro com os 5 estágios) + portão + paliçada, 75 desenhos, `predios.json` |
| `scripts/iso/iso_art.gd` (novo) | o registro: estado → camadas, caixa, pegada de navegação, ponto da frente, pegada e fantasma do posicionador |
| `scripts/iso/iso_billboard.gd` | modo arte nova: camadas no lugar do desenho antigo, caixa do desenho, rótulos/luzes levados, barrinha da obra em cima do desenho novo |
| `scripts/iso/iso_view.gd` | paliçada; fantasma do posicionador com o desenho novo; a paliçada não pega clique |
| `scripts/props/station.gd` | pegada de navegação e slots pela arte nova (slot na direção dele, logo fora da parede) |
| `scripts/props/canteiro.gd`, `escudo.gd`, `parque.gd`, `vestiario.gd` | pegada pela arte nova (o parque agora bloqueia o coreto inteiro, não só um poste) |
| `casa.gd`, `oficina.gd`, `arsenal.gd`, `centro_vila.gd`, `escavadeira.gd`, `enfermaria.gd`, `canteiro.gd`, `escudo.gd` | ponto do engenheiro / porta do médico na frente da pegada |
| `scripts/core/house_placer.gd` | pegada e bloqueios pela arte nova; `art_name` pro fantasma |
| `scripts/core/environment.gd` | migração de prédios sobrepostos |
| `scripts/creatures/creature.gd` | alcance do ataque até a parede do prédio novo |
| `tests/blocos/b41_parque.gd` | **mudado de propósito**: o lugar do 2º parque sai do posicionador do parque aberto (pegada nova e bloqueios atuais); antes usava a pegada e os bloqueios que tinham sobrado de outra colocação, e o parque nascia colado num prédio |
| `tests/blocos/p29_predios.gd` (novo), `tests/test_blocos.gd` | o teste desta parte |
| `tests/test_iso_arte.gd` | toda arte integrada cabe na caixa |
| `tests/capturas_iso.gd` (novo) | capturas pros relatórios |

## Testes

Tudo com a pasta de usuário isolada; md5 do save real conferido antes e depois.

| Bateria | Resultado |
|---|---|
| `p29_predios` (novo) | casas (2+ variações), armazém, oficina, enfermaria, comedouro e Centro com a arte nova; caixa = a do desenho; desenho antigo some; pegada = desenho ÷ 1,5 e a navegação contorna; **0 camas dentro da parede e 0 sem caminho**; **todos os slots dentro da área de interação** (casas, armazém, comedouro, enfermaria, laboratório, arsenal, campo, coletor, taverna); slots do armazém e engenheiro do Centro fora da pegada; **0 sobreposições** entre os prédios da cena; 66 trechos de paliçada; obra 10/50/90% = obra_1/2/3; casa a 83% = obra_3; coletor no corte; Centro estágios 1–5 e o andaime; escavadeira vazia / estrutura + motor + cabine em montagem; portões; posicionador com pegada nova recusa colar numa casa; fantasma novo; migração separa 2 casas sobrepostas pra chão plano; **0 pares na ordem errada** |
| `test_iso_arte` | os 75 desenhos integrados cabem na caixa (≤ 4 px) |
| `p29_mapa` | continua passando (432 pares com a paliçada, 0 errados) |
| GUT completo (30 blocos + 12 testes rápidos) | 1ª rodada **39/42**: achou 2 defeitos desta parte (invasor não alcançava a parede nova: b36; caixa trocando no 1º quadro: p28_iso) e 1 teste com pegada velha (b41). Corrigidos. 2ª rodada **41/42**: a falha foi o `b45_coletor_madeira` conhecido (o lenhador sorteou um acidente e estava internado na conferência, ver TESTING.md); sozinho passou 2 de 2 |
| Save real | md5 igual antes e depois de todas as rodadas (`savegame.json` f70b569b…) |

## Limites e desvios

1. **Ainda arte antiga:** bonecos, criaturas, robô, animais, árvores, pedras, cristais, jazidas,
   tochas e objetos; o nível 2 e o abismo (bordas, elevadores, poço). Próximas partes.
2. **Elevadores** (do poço e do abismo) ficam pra parte dos andares de baixo: eles têm uma ponta
   em cima e outra embaixo, e o poço entre as lajes ainda não existe.
3. **Portão espelhado** (desvio do contrato, ver Decisões). A âncora dele saiu da prancha do
   `muro.py`; a caixa ficou 84×42 (o desenho tem os mourões de lado).
4. **Coletor de madeira, peças da escavadeira e escudo** não têm desenhos de obra: sobem pelo corte.
5. **Casa nível 2/3** existem na arte, mas o jogo não tem nível de casa: ficam guardadas.
6. **"Comedouro" → "Cozinha"** (pedido do inventário) ainda não: são ~15 textos de interface; entra
   junto com a parte da interface.
7. O aviso da navegação "1 edge error" já aparecia antes desta parte (conferido desligando a
   pegada nova).
