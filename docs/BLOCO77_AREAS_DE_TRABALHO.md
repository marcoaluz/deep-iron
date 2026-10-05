# Bloco 77 — áreas de trabalho e alocação de trabalhadores (o esquema do Frostpunk)

Pedido do Marco na íntegra: `docs/BLOCO77_AREAS_DE_TRABALHO_PEDIDO.md`.

## Como joga

1. **Tecla 5** (ou o botão "Trabalhadores" na coluna da direita) abre a janela **TRABALHADORES**:
   `Disponíveis: N` (= ipezinhos sem função) e as áreas marcadas.
2. **+ Área de madeira / alimentos / mina**: a janela fecha e o mouse vira a ferramenta. Arraste com o
   botão esquerdo no mapa (aparece o losango verde; vermelho = não vale, com o motivo no topo). Soltar
   cria a área e reabre a janela com ela destacada. Esc ou botão direito cancela.
3. Em cada área: **[ - ]  3 / 5  [ + ]**. O "+" pega o disponível mais perto da área, e o "-" devolve um
   pros disponíveis. Os botões se travam sozinhos: "-" no zero, "+" com a área cheia ou sem ninguém
   disponível.
4. A **mina** nasce **desligada**. O botão "Ligar o carrinho" liga a mina. Estados possíveis:
   Desativada, Sem mineiro, Sem recurso disponível e Operando. O vagonete só anda com ela **operando**,
   ou seja, ligada, com pelo menos 1 mineiro e com jazida.
5. No mapa, cada área tem o chão tingido na cor do tipo, o contorno e uma plaquinha no meio
   ("Madeira 1  4/5 · Trabalhando"). Clicar no chão de uma área, sem ninguém selecionado, abre a janela
   nela. "Ver" leva a câmera até a área e "Apagar" desfaz a área (todo mundo volta a ficar disponível).
6. Na lista da Força de Trabalho, quem está numa área mostra o nome dela ("lenhador · Madeira 1").

## Regras

- **Disponível = sem função.** Ao entrar numa área, o ipezinho ganha a função do tipo: lenhador
  (madeira), caçador (alimentos: colhe na horta e, com arco, caça nas tocas de dentro) ou minerador
  (mina). Com isso ele deixa de ser disponível. Ao sair, volta a ser sem função e entrega antes o que
  estiver carregando, como em qualquer troca de função.
- **Só dentro da área.** A busca de trabalho dele (árvore, horta, toca, jazida) só aceita o que está
  dentro do retângulo. Sem trabalho lá dentro (sem árvore, mina desligada), ele **espera na área**, não
  volta pro Centro da Vila. O armazém, o comedouro, a cama e o resto continuam normais.
- **O que está dentro de uma área é dela.** Quem tem a função dada à mão (teclas 1, 2, L…) continua
  trabalhando onde achar, como antes, mas não usa o recurso de dentro de área nenhuma. Mina desligada
  ninguém usa.
- **Trocar a função à mão** (tecla) de quem está numa área tira ele da área.
- **Produção de verdade.** Cada um corta, colhe ou minera no seu slot, no ritmo dele. Por isso 5
  trabalhadores rendem o de 5 e 2 rendem o de 2. No teste: 27,2 contra 16,0 de madeira em 30 s de jogo,
  na mesma área com 3 árvores. A janela mostra a produção do último minuto e o total da área.
- **Limites.** No máximo 5 por área, e nunca mais do que os disponíveis. Não vale área minúscula (menos
  de 40 px de lado), área que pega dois andares, nem área em cima de outra do mesmo tipo.
- **Sem área nenhuma no mapa, o jogo é exatamente o de antes.**

## Arquitetura (o que foi reaproveitado e o que é novo)

Reaproveitado, sem duplicar nada:

| Sistema | Arquivo | Uso nas áreas |
|---|---|---|
| Funções do ipezinho | `ipezinho.gd`: `job`, `set_job`, `_choose_state` | A área só escolhe a função e, por ela, o que o ipezinho faz. |
| Estações e slots | `station.gd`, `tree_node.gd`, `food_source.gd`, `hunt_spot.gd`, `mineral_node.gd` | A produção. Cada trabalhador ocupa um slot e extrai no ritmo dele. |
| Busca de trabalho | `_find_best_station` / `_has_usable_station` / `_station_ok_for` | Ganhou um filtro: `_area_permite`. |
| Vagonete da mina | `estacao_vagonete.gd`, Bloco 64/74 | É o "carrinho" da mina, agora com `parar_por_area`. |
| Janelas do HUD | `_add_panel`, estilo e botões do `hud.gd` | A janela TRABALHADORES. |
| Ferramenta de posicionar | Padrão do `house_placer.gd` | Base do `area_placer.gd`. |
| Desenho no chão da vista iso | Padrão dos trilhos em `iso_view.gd` | Tingido e contorno das áreas. |
| Save | `save_manager.gd`, `get_save_data` / `load_save_data`; religar como o operador do coletor (Bloco 45/57) | Áreas e o vínculo de cada ipezinho. |

Novo:

- **`scripts/core/work_areas.gd`**: o nó `WorkAreas` (grupo `work_areas`), criado pelo `main.gd`.
  - A classe **`WorkArea`** tem: `tipo`, `rect` (na lógica), `capacidade`, `trabalhadores`, `ativa`,
    a produção (baldes do último minuto e `total`) e o `estado`.
  - **`TIPOS`** é o registro dos tipos. Cada um diz o nome, a função do ipezinho, os grupos de estação
    que contam como o recurso, a cor, se precisa ativar e o texto de "sem recurso".
  - Pra criar um tipo novo (caça, agricultura, pesca, construção), basta mais uma entrada em `TIPOS`.
    Se o tipo pedir uma função nova, ela entra no `ipezinho.gd`, como sempre.
  - A API: `criar`, `apagar`, `adicionar`, `remover`, `definir(area, n)`, `disponiveis`, `ativar`,
    `estado`, `funcionando`, `pode_usar(worker, ponto, grupo)`, `carrinhos`, `religar` e o save.
- **`scripts/core/area_placer.gd`**: a ferramenta de marcar (grupo `area_placer`).
- **`scripts/core/work_panel.gd`**: a janela TRABALHADORES (id `trabalho`, tecla `painel_trabalho` = 5).

## Arquivos

- Novos: `scripts/core/work_areas.gd`, `scripts/core/area_placer.gd`, `scripts/core/work_panel.gd`,
  `tests/blocos/b77_areas.gd`, `tests/capturas_bloco77.gd` e este documento.
- Alterados:
  - `scripts/workers/ipezinho.gd`: `work_area`, entrar/sair, o filtro da busca, o ocioso na área, o
    registro da produção e o `area_id` no save.
  - `scripts/props/estacao_vagonete.gd`: `parar_por_area`.
  - `scripts/core/main.gd`: cria o sistema e a ferramenta, a tecla 5 e o clique na área.
  - `scripts/core/hud.gd`: a janela, a dica do H e a área na lista.
  - `scripts/core/teclas.gd`: tecla 5.
  - `scripts/iso/iso_view.gd`: o desenho das áreas e da área sendo marcada.
  - `scripts/core/save_manager.gd`: `areas_trabalho`.
  - `tests/test_blocos.gd` e `TESTING.md`.

## Testes

- `tests/blocos/b77_areas.gd` (59 checagens): criar arrastando, área inválida, o limite de 5, os
  disponíveis, alocar e devolver, a restrição dos dois lados, a troca manual, a mina com o carrinho, a
  produção rodando (5 contra 2) e o save/load.
- A bateria inteira de blocos (59) rodou depois da mudança: tudo passou. A única falha foi no
  `hud_frostpunk.gd` e era antiga: o próprio teste deixava `show_hints=true` nas configurações e
  alternava entre passar e falhar a cada rodada. Foi corrigido pra zerar no começo e devolver no fim.
- Fotos: `docs/arte/bloco77/`.

## Pontos de atenção

- **A janela de produção é por minuto de jogo.** Em velocidade 4x ela enche 4x mais rápido.
- **A área é um retângulo da lógica**, então na vista iso aparece como losango. Não dá pra desenhar
  forma livre.
- **Área de alimentos usa o caçador.** Ele colhe e, se tiver arco, caça nas tocas de dentro da área.
  Uma área "só caça" ou "só horta" seria outro tipo em `TIPOS`.
- **Quem morre ou é recrutado não mexe na área sozinho.** A área fica com um a menos, e o jogador põe
  outro no "+". Não há reposição automática, de propósito, pra o jogador decidir.
- **Mina sem carrinho dentro também funciona.** O botão só liga e desliga a mineração ("a mina, sem
  carrinho nesta área"). Os pontos de carga contam se estiverem até 80 px da borda da área.
- **Mais de uma área do mesmo tipo** pode existir, mas nunca uma em cima da outra.
