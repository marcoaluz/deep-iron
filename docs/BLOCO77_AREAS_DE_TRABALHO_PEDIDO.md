# Bloco 77 — pedido do Marco (2026-10-05): áreas de trabalho e alocação de trabalhadores

> Fazer **depois** do Bloco 76 (caminhadas de 8 quadros + rio de lava / cachoeira nas faixas).
> Texto do Marco, na íntegra:

Preciso ajustar e implementar a mecânica de **seleção de áreas de trabalho e alocação de trabalhadores**, seguindo o conceito que definimos inspirado na mecânica de distribuição de trabalhadores do Frostpunk.

Antes de alterar o código, analise como o sistema atual funciona, identifique as estruturas existentes relacionadas a trabalhadores, recursos, árvores, coleta de alimentos e mineração, e aproveite ao máximo a arquitetura já existente. Não recrie sistemas que já existem.

### 1. Área de corte de árvores

Quero que o jogador possa **definir visualmente uma área específica do mapa onde as árvores deverão ser cortadas**.

Fluxo esperado:

* O jogador seleciona a ferramenta/ação de corte de árvores.
* Define uma área no mapa.
* Essa área passa a ser uma **zona de trabalho de corte de árvores**.
* Os trabalhadores designados para essa zona procuram e cortam as árvores existentes dentro dela.
* Cada área de corte de árvores possui um limite máximo de **5 trabalhadores**.
* O jogador pode escolher quantos trabalhadores serão alocados nessa área, de `0` até `5`.
* Se houver menos de 5 trabalhadores disponíveis, obviamente a área trabalha apenas com a quantidade disponível.
* O sistema deve impedir que sejam atribuídos mais de 5 trabalhadores para uma única área.
* O jogador deve conseguir visualizar claramente:
  * área selecionada;
  * quantidade de trabalhadores alocados;
  * capacidade máxima da área (`5/5`, por exemplo);
  * situação da área (ativa, sem trabalhadores, sem árvores disponíveis etc.).

### 2. Área de coleta de alimentos

Aplicar a mesma lógica para **coleta de alimentos**.

O jogador deve:

1. Selecionar a ferramenta de coleta.
2. Definir uma área do mapa onde deseja que os alimentos sejam coletados.
3. Criar uma zona de trabalho.
4. Definir quantos trabalhadores serão enviados para essa área.

Cada área de coleta de alimentos também terá capacidade máxima de **5 trabalhadores**.

Exemplo: `Coleta de alimentos — 3/5 trabalhadores`

Os trabalhadores devem atuar somente dentro da área selecionada.

### 3. Área de mineração

Criar a mesma lógica para a mineração, porém adicionando a mecânica de ativação do **carrinho/estrutura de mineração**.

O jogador deverá:

* Selecionar o local de mineração.
* Definir/criar a área de mineração.
* Ativar a estrutura/carrinho da mina.
* Para que a mineração funcione, será necessário pelo menos **1 mineiro** trabalhando na mina.

A mina deve possuir um estado de funcionamento, por exemplo:

* Desativada
* Sem mineiro
* Operando
* Sem recurso disponível

Quando o jogador colocar pelo menos 1 mineiro na mina, ela poderá entrar em operação, desde que todas as outras condições necessárias estejam atendidas.

### 4. Sistema de trabalhadores inspirado no Frostpunk

Quero utilizar o mesmo conceito de **postos de trabalho com quantidade definida de trabalhadores**, como no Frostpunk.

Cada área/estrutura de trabalho deve possuir:

* tipo de trabalho;
* posição/área no mapa;
* quantidade máxima de trabalhadores;
* quantidade atual de trabalhadores;
* trabalhadores atribuídos;
* estado da atividade;
* produção/coleta correspondente.

Exemplo:

**Área de madeira** — `Trabalhadores: 4/5` — `Status: Trabalhando`

**Área de alimentos** — `Trabalhadores: 5/5` — `Status: Trabalhando`

**Mina** — `Mineiros: 2/5` — `Status: Operando`

O jogador deve conseguir aumentar ou diminuir a quantidade de trabalhadores diretamente nessa área, sem precisar controlar individualmente cada trabalhador para determinar sua função.

### 5. Regras importantes

A quantidade de trabalhadores deve ser realmente vinculada ao funcionamento da atividade.

Se uma área de madeira possui `5/5 trabalhadores`, ela deve ter capacidade de produção correspondente a 5 trabalhadores. Se o jogador reduzir para `2/5 trabalhadores`, a produção deve ser recalculada de acordo com os 2 trabalhadores.

Não quero apenas uma informação visual. A quantidade de trabalhadores deve realmente afetar a produção/coleta da atividade.

### 6. Trabalhadores disponíveis

Deve existir uma lógica de trabalhadores: **Trabalhadores disponíveis → trabalhadores alocados nas atividades**

Quando um trabalhador for colocado em uma área:

* ele deixa de estar disponível para outras atividades;
* passa a contar como trabalhador daquela função.

Quando for removido:

* volta para a quantidade de trabalhadores disponíveis;
* pode ser utilizado em outra atividade.

O sistema deve impedir que o jogador atribua mais trabalhadores do que realmente possui.

### 7. Interface

A interface deve deixar muito claro para o jogador:

* qual área foi selecionada;
* qual recurso está sendo produzido/coletado;
* quantos trabalhadores estão trabalhando;
* qual é o limite da área;
* quantos trabalhadores ainda estão disponíveis.

```text
TRABALHADORES

Disponíveis: 8

Madeira
[ - ]  5 / 5  [ + ]

Alimentos
[ - ]  2 / 5  [ + ]

Mina
[ - ]  1 / 5  [ + ]
```

Os controles devem respeitar os limites automaticamente.

### 8. Comportamento dos trabalhadores

Os trabalhadores não precisam ser controlados manualmente pelo jogador. O jogador define **"Esta é a área onde quero trabalhar"** e **"Quero X trabalhadores trabalhando aqui"**. A IA/sistema de trabalhadores deve então fazer com que os trabalhadores se dirijam à área e executem a atividade correspondente. Eles devem respeitar a área definida pelo jogador e não começar a trabalhar aleatoriamente em outro local.

### 9. Importante sobre implementação

1. Analise o código atual.
2. Identifique como os trabalhadores estão sendo controlados atualmente.
3. Identifique como árvores, alimentos, recursos e mineração estão implementados.
4. Verifique se já existe algum sistema de áreas, zonas, jobs, workers ou resource nodes que possa ser reutilizado.
5. Não duplique sistemas existentes.
6. Preserve as mecânicas que já funcionam.
7. Faça as alterações de forma modular para que posteriormente possamos adicionar outras profissões/áreas, como agricultura, caça, construção, pesca etc.

A arquitetura deve permitir futuramente algo como `WorkArea` (tipo, posição/área, capacidade, trabalhadores atribuídos, produção, estado), e novos tipos de trabalho poderão utilizar a mesma estrutura.

### 10. Critérios de conclusão

* Eu conseguir selecionar uma área de árvores para corte.
* Eu conseguir definir quantos trabalhadores irão trabalhar nela, respeitando o limite de 5.
* Eu conseguir selecionar uma área de coleta de alimentos.
* Eu conseguir definir quantos trabalhadores irão trabalhar nela, respeitando o limite de 5.
* Eu conseguir selecionar uma área de mineração.
* A mina exigir pelo menos um mineiro para funcionar.
* Eu conseguir aumentar e diminuir a quantidade de trabalhadores.
* Trabalhadores alocados deixarem de aparecer como disponíveis.
* Trabalhadores removidos voltarem a ficar disponíveis.
* A quantidade de trabalhadores realmente influenciar a produção.
* Os trabalhadores atuarem somente na área/função para a qual foram designados.
* O sistema impedir alocações inválidas.
* As áreas e trabalhadores permanecerem consistentes após salvar/recarregar o jogo.
* A implementação não quebrar as mecânicas existentes.

**Não fazer apenas mockup ou interface visual**: a mecânica precisa estar funcional e integrada ao sistema atual do jogo.

Ao finalizar, informar: (1) arquivos alterados; (2) sistemas reutilizados; (3) novas estruturas/mecânicas; (4) como a alocação funciona; (5) testes realizados; (6) pontos de atenção/pendências.
