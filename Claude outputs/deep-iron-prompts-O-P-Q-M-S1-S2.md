# DEEP IRON — Prompts O, P, Q, M, S1 e S2

Textos copiados da conversa com o outro Claude. Mande um por sessão, valide jogando, faça o commit e só então passe ao próximo.

Ordem sugerida: 0 → O → P → Q → 1 → 2 → 3 → M → S1 → S2 → ...

---

## Prompt O: obras com material levado pelo engenheiro

Recomendado: Opus 5.5, esforço high (xhigh só na sessão do plano).

```
Leia o CLAUDE.md e o CONTEXTO.md; use o próximo Bloco livre. Leia canteiro.gd, obra_site.gd, obra_estagio.gd, economy.gd (spend, can_afford, metal), armazem.gd, as partes de "building" do ipezinho.gd e o save. Mostre um plano curto com a TABELA de todos os pontos que hoje cobram material na encomenda e espere aprovação. Tarefa: obras realistas, com material levado pelo engenheiro.
1) Ao encomendar, o canteiro nasce com uma LISTA DE MATERIAIS (ferro, madeira, barras, tábuas, pregos etc.), derivada do custo atual. Os créditos continuam cobrados na encomenda. O material fica RESERVADO no armazém (não sai ainda) e a encomenda continua exigindo estoque suficiente.
2) O engenheiro vai ao armazém (o mais perto com estoque, considerando vários armazéns), pega até o LIMITE DE CARGA (@export; ex.: 10 unidades por viagem), leva ao canteiro, entrega e volta, até entregar tudo. A carga aparece no corpo dele (reuse os visuais de carga existentes). Vários engenheiros dividem as viagens sem pegar o mesmo item duas vezes.
3) O progresso da obra fica LIMITADO ao que já foi entregue (fração entregue x total): os estágios (fundação, paredes, prédio cru, pronto) aparecem conforme o material chega. O engenheiro constrói a parte liberada e busca mais material enquanto falta.
4) Visual no canteiro: pilha dos materiais entregues ao lado da obra, que diminui conforme é usada. O cartão da obra mostra entregue/necessário por item, e o estado da obra mostra "buscando material", "levando N/M" ou "falta material no armazém" (sem engenheiro continua "esperando engenheiro"). O texto do engenheiro na janela dele também.
5) Escopo: todos os kinds do Canteiro.KINDS, casas, melhorias do Centro da Vila, peças da escavadeira, etapas do coletor em ruína, igreja, cemitério e consertos grandes. Decoração, caminhos e produção continuam como estão. Se um conserto pequeno (ex.: trilho) não faz sentido com material, mantenha sem e diga qual.
6) Cancelar a obra devolve ao armazém o reservado e o já entregue. Saves antigos: canteiros já pagos contam como material totalmente entregue.
7) Balanceamento: compare com a telemetria o tempo médio de obra antes e depois (a caminhada aumenta). Se ficar lento demais, proponha ajustes (limite de carga, velocidade) sem aplicar sozinho.
Teste do bloco (viagens com limite, progresso limitado, dois engenheiros, cancelar, save antigo) e ajuste dos testes antigos afetados.
```

---

## Prompt P: portão e tochas

Recomendado: Sonnet 5.5, esforço high (se o diagnóstico de navegação travar, passe para Opus medium).

```
Leia o CLAUDE.md e o CONTEXTO.md; use o próximo Bloco livre. Duas correções.
1) PORTÃO DA PALIÇADA. Hoje o portão parece fora da cerca e o pessoal anda ao lado da cerca em vez de passar pelo portão. Investigue com capturas de tela do jogo (environment.gd: palisade_x, gate_y, gate_half_width, o obstáculo e a malha de navegação; iso_view.gd: desenho da paliçada, barricada.gd). Mostre a causa antes de corrigir. Corrija: (a) o sprite do portão alinhado ao vão lógico e à paliçada; (b) o obstáculo da paliçada cobrindo toda a extensão, para a única passagem ser o portão; (c) o caminho entre a floresta e a vila passando pelo vão, com teste de caminhos de pontos aleatórios dos dois lados que sempre cruzam em gate_y ± gate_half_width.
Abrir e fechar: o portão fica ABERTO de dia e FECHA ao anoitecer (a hora vem do DayNight/Schedule, @export; padrão 18:30) e abre ao amanhecer (05:00), com animação (frames de aberto e fechado no estilo da arte atual, PixelLab se precisar, regra 11). Fechado, bloqueia a navegação sem rebake caro (por exemplo, NavigationLink2D ou região ligada e desligada). Compatibilize com o Barricada atual: vida, brecha e invasão continuam funcionando, e a brecha continua abrindo o caminho. Proponha e mostre a regra para quem está fora na hora de fechar (turno extra, guardas, caçador e lenhador atrasados, migrantes esperando do Prompt M, se existir), com padrão sugerido: o portão só fecha depois da hora de voltar, quem ficou fora espera ali e um guarda abre para membros da vila; criaturas e migrantes não passam à noite.
2) TOCHAS. A tocha muda de desenho entre dia e noite. Quero o MESMO desenho sempre. Ache onde isso acontece (iso_art.gd, iso_view.gd, iso_luz.gd, decoracoes.gd, environment.gd) e deixe um desenho só (o aceso, com a chama), mudando apenas a luz e o brilho (ligados à noite, desligados ou fracos de dia). Vale para as tochas sorteadas do mapa, as do jogador, os lampiões e a decoração. Liste outros props que também trocam de desenho entre dia e noite, sem mudar nenhum além das tochas e lampiões.
Capturas de tela de antes e depois (dia e noite) e teste do bloco.
```

---

## Prompt Q: entrada da mina, elevador, escadas e vagonete

Recomendado: Opus 5.5, esforço high (xhigh na auditoria e no plano).

```
Leia o CLAUDE.md e o CONTEXTO.md; use o próximo Bloco livre. Antes de codar, AUDITE como os ipezinhos descem hoje (escavadeira, poço, elevador, espiral, plataforma do abismo, escadas e degraus da montanha, boca da mina, guindaste, estacao_vagonete.gd, trilho.gd, vagonete.gd, work_areas.gd) e mostre um plano com as opções, capturas e a recomendação abaixo. Espere aprovação.
A) ELEVADOR E ESCADAS. Recomendação: o ELEVADOR é a entrada principal, RESTAURÁVEL por etapas (padrão do coletor em ruína, Bloco 81, e da escavadeira), com capacidade por viagem, velocidade, fila de espera, cabine animada, quebra por uso e conserto pelo engenheiro (que leva material, conforme o Bloco de obras com material). A escada em espiral continua como rota LENTA de emergência (se o elevador quebra, ninguém fica preso embaixo sem comida), e as escadas só decorativas que não servem saem. Mostre os prós e os contras e o que sai do mapa. Os ipezinhos passam a entrar na mina e descer pelo elevador (ficam na fila, embarcam, aparecem no andar de destino).
B) VAGONETE E MINERADORES NA MINA. Quando o trilho e o vagonete estão funcionando, o mineiro da área de mina ENTRA pela boca e FICA TRABALHANDO lá dentro (some do mundo, com contador "dentro da mina N/5", brilho e som de picareta na boca). O minério vai para o buffer do vagonete, que sai com CARGAS GRANDES (@export, ex.: de 25 para 80 a 120) em intervalos maiores e entrega no armazém, com o carrinho cheio visível. Os mineiros saem da mina só para as refeições, o fim do expediente e as emergências da agenda. Sem o trilho funcionando ou com o vagonete quebrado, tudo continua como hoje (mineiro carrega na mão, nada trava; o buffer cheio já faz o ponto parar de aceitar). Mantenha acidentes e desgaste do trilho coerentes com o ritmo novo. Vale também para a ferrovia de carga dos andares S2 a S5.
C) Compare a produção de minério por hora ANTES e DEPOIS com a telemetria. Mantenha a renda parecida e mostre os números; qualquer ajuste de balanceamento só depois de eu aprovar.
Arte: nova arte (cabine do elevador, guindaste e boca) no PixelLab, no nível do jogo (regra 11), e a evolução da obra do elevador. Teste do bloco, save com migração e ajuste dos testes antigos (b64, b77, b79 e os de andares).
```

---

## Prompt M: migrantes e população inicial

Recomendado: Opus 5.5, esforço high. Vem depois do Prompt 3 e antes do tutorial (Prompt 4).

```
Leia o CLAUDE.md e o CONTEXTO.md; use o próximo Bloco livre. Mostre um plano curto e espere aprovação (mexe no começo do jogo). Tarefa: acabar com a compra de ipezinhos.
1) Remover o "Recrutar" (tecla R, custo de 150 cr com +50% a cada um, botões e textos). Saves antigos continuam carregando; ajuste os testes afetados.
2) Partida nova começa com 10 ipezinhos: 5 homens e 5 mulheres, nomes e aparências sorteados, todos sem função. Confira se a Fundação e as 3 casas iniciais têm camas para 10 e se a comida inicial aguenta os primeiros dias (10 comem ≈ 240/dia; a horta rende ≈ 189). Mostre os números da telemetria e proponha ajustes, sem aplicá-los sem eu aprovar.
3) A capacidade da vila passa a ser as camas livres (a melhoria Moradias continua somando camas).
4) MIGRANTES: grupos pequenos chegam pela floresta até o portão (o único) e esperam. Aparece um alerta e um cartão com retrato, nome, sexo, condição (saudável, com fome, ferido, doente) e uma função de que gostariam. Botões Aceitar / Recusar / Esperar. Sem resposta no prazo (@export, ~1 dia), vão embora. Aceitar exige cama livre (senão o botão fica desabilitado com a dica "falta cama"): o portão abre, eles entram e ficam sem função. Os feridos e doentes aceitos vão para a enfermaria, onde o médico cuida. Quem fica esperando no portão à noite pode ser atacado por criaturas (risco em @export).
5) Frequência: depende da atratividade da vila (estágio, comida, ânimo médio, camas livres, beleza, missões cumpridas), com intervalo mínimo; nunca sem aviso. Rede de segurança contra espiral da morte: se a vila ficar com menos de N ipezinhos (@export), chega ajuda mesmo assim. Mistura de homens e mulheres; o padre continua sendo único (o migrante não vem como padre).
6) O evento "refugiados" do Prompt 11 passa a ser este sistema.
Arte: reuse o elenco e os retratos existentes; sem arte nova pesada. Ganchos de som para a chegada (arquivos depois). Save, atualização do tutorial e das missões do Capítulo 1 se citarem recrutamento, e teste do bloco.
```

---

## Prompt S1: catálogo, minérios e animais

Recomendado: Opus 5.5, esforço high. Vem depois do layout v2 (Prompt 2) e das missões (Prompt 3).

```
Leia o CLAUDE.md e o CONTEXTO.md; use o próximo Bloco livre. Leia research.gd, laboratorio.gd, o ofício de pesquisador no ipezinho.gd, mineral_node.gd, ores.gd, hunt_spot.gd, finds.gd, diary.gd, a Fornalha e as receitas do Bloco 86. Mostre um plano curto e a tabela de "conhecimento inicial" (o que nasce conhecido e o que precisa ser descoberto) e espere aprovação. Tarefa: o pesquisador como naturalista; sistema de DESCOBERTAS.
1) Modelo de dados: um catálogo (catalogo.gd, nó na cena, grupo "catalogo") com entradas por categoria (minério, animal, criatura, local), cada uma com estados: Desconhecido → Avistado → Estudado. Dados em .tres/.json (id, nome, texto, ícone, categoria, o que libera). Textos editáveis por arquivo. Save e migração: em saves antigos, tudo que o jogo já liberou (andares abertos, minérios já minerados, pesquisas feitas) entra como Estudado.
2) Tarefa de campo do pesquisador: se não houver pesquisa ativa no laboratório, ele sai para CATALOGAR o próximo alvo (veia visível, toca avistada...), com prioridade e distância, vai, estuda com um tempo em @export (animação de anotar: reuse a de pesquisar se existir; senão gere no PixelLab, regra 11), volta e entrega a entrada (balão e toast "Estudou: Cobre"). De dia só; evita áreas perigosas e foge na invasão e na onda solar. Com pesquisa ativa ele fica no laboratório. Várias pesquisadoras/es dividem os alvos sem repetir.
3) MINÉRIOS: jazida desconhecida aparece como "pedra desconhecida". Dá para minerar, mas o minério sai como "minério desconhecido" (preço baixo e sem uso em receitas) até o estudo revelar o tipo. Estudado: nome, uso, receita da fornalha liberada e requisito de ferramenta (picareta de aço, lampião, broca) mostrado. Proponha o conhecimento inicial (sugestão: ferro conhecido, o resto descoberto) para o começo não travar.
4) ANIMAIS: toca desconhecida não aparece para o caçador; estudada, libera a caça ali, com ficha (o que rende, riscos, época).
5) JANELA CATÁLOGO (tecla própria, no estilo do layout v2): abas Minerais, Animais, Criaturas, Locais; entradas desconhecidas em silhueta com "???", estudadas com ícone, texto e "para que serve". Ligue ao diário.
6) DESCOBERTA LIBERA PESQUISA: uma pesquisa pode exigir uma entrada estudada (ex.: Trajes exige o reconhecimento do S2); configure em dados.
7) Plano B: sem pesquisador na vila, o laboratório pode "estudar" uma entrada gastando pontos de pesquisa (mais lento). Estudar também dá uma pequena quantidade de pontos.
Missões: exponha sinais ("entrada_estudada") para o sistema de missões. Teste do bloco e dos saves antigos.
```

---

## Prompt S2: criaturas (corpos e bestiário) e reconhecimento dos andares

Recomendado: Opus 5.5, esforço high. Vem depois do S1. Mande junto com o acréscimo logo abaixo.

```
Leia o CLAUDE.md e o CONTEXTO.md; use o próximo Bloco livre (depois do catálogo). Leia creature.gd (morte e drops), defense.gd e defense_panel.gd, corpo.gd, NivelMina e a lógica dos andares abertos, trajes e equipamentos, o portão. Mostre um plano e espere aprovação. Tarefa:
1) CORPOS DE CRIATURAS: quando uma criatura morre na invasão, o corpo fica no mapa (visual da criatura caída, no estilo do projeto; use o quadro de morte existente ou gere no PixelLab) até o amanhecer seguinte mais N horas (@export) ou até ser estudado. Corpos na vila ou perto do portão causam um pequeno desconforto (@export, opcional). Se não for estudado até o prazo, some.
2) ESTUDAR O CORPO: o pesquisador (de dia, dentro dos horários e com o portão aberto se o corpo estiver fora) vai ao corpo, estuda e revela a FICHA da espécie no Catálogo: nome, descrição, fraqueza, comportamento (ex.: Lumívoro atraído pela luz), o que deixa e o nível de perigo. Os drops raros atuais (Gosma, Magmante) podem passar a ser colhidos no estudo se isso couber sem mudar o balanceamento; mostre antes. Criaturas ainda não estudadas aparecem como "???" na janela da Defesa; estudadas mostram a ficha e a PREVISÃO da próxima invasão (tipos e quantidades). Várias espécies, estudadas uma a uma.
3) RECONHECIMENTO DOS ANDARES: antes de descer a um andar novo (S2 a S5), o pesquisador faz um reconhecimento (vai lá, com o risco real de ferimento e as regras de proteção já existentes) e revela perigos (gás, calor, ácido, lava), as criaturas do andar e o equipamento exigido. Andar não reconhecido aparece como "não reconhecido" na interface; a tentativa de descer sem reconhecimento pede confirmação e aumenta o risco (multiplicador de acidente em @export). As regras duras já existentes (traje de gás, de chumbo, ventilador) continuam: o reconhecimento só as REVELA.
4) Reuse o catálogo do Prompt S1, as pesquisas que dependem de descobertas e o diário. Sinais para as missões ("criatura_estudada", "andar_reconhecido"). Save com migração (corpos pendentes não precisam persistir) e teste do bloco.
```

### Acréscimo ao Prompt S2 (mande junto)

```
Acréscimo ao Prompt S2: a ficha de cada criatura estudada ganha "POR QUE VEIO" e uma pequena história em texto (editável por arquivo). O motivo mostrado tem que corresponder a uma REGRA REAL do jogo (ex.: Lumívoro é atraído pela luz; Ferrugento sai do poço; só afirme algo que o código faça) e vir com uma DICA ACIONÁVEL ("apague as tochas perto do portão"). Mostre a descoberta como cartão narrativo curto e no diário. O pesquisador que fez a descoberta fica realizado: ânimo (@export) e experiência na habilidade, com um balão de comemoração. Se uma regra citada ainda não existir no jogo, liste-a e proponha implementá-la em vez de inventar texto.
```

---

## Lembretes de acréscimo em outros prompts

- Ao mandar os Prompts 3 (missões) e 4 (tutorial), acrescente: "Considere que as obras agora exigem entrega de material pelo engenheiro, e que o portão fecha à noite."
- Ao mandar o Prompt 10 (campanha), acrescente objetivos de descoberta nos capítulos: "estude a pedra de ferro", "estude o primeiro Lumívoro", "reconheça o S2".
- Ao mandar o Prompt 11, peça para ele não criar o evento de refugiados (o Prompt M assume esse papel).
