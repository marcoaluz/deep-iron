# Bloco 130 — O flicker do Armazém e do Centro da Vila, e os pisos (caminhos) com a arte do PixelLab

O pedido veio com "teste b129"; o 129 já era o do arquivo do save, então este é o **b130** (regra do projeto: número antigo vira o
próximo livre). Teste: `b130_pisos_flicker` (52 verificações). Capturas em `docs/arte/bloco130/`.

## 1) O flicker — a causa, mostrada
**Reproduzido** com `tests/capturas_bloco130.gd` (com janela; câmera no Armazém e no Centro, "depósitos" de minério a cada segundo;
a CADA quadro guarda a assinatura do espelho do prédio: textura, quadro, modulate, posição, z_index e visível de cada sprite, a
camada de arte e a ordem de desenho — `docs/arte/bloco130/flicker/diff_antes.txt`).

**A causa** (`scripts/iso/iso_billboard.gd`): quando o prédio de verdade ganha ou perde um **filho** (o "+6" do depósito, a poeira),
o espelho era refeito (`_build_mirror`) e a função **saía na hora**. O espelho novo nascia com o desenho **ANTIGO** (o sprite
`armazem.png` pequeno, a pilha, os rótulos soltos) e a arte nova só voltava na próxima sincronização do prédio — que acontece de 6 em 6
quadros (`STATIC_SYNC_EVERY`). Resultado: a cada depósito o Armazém trocava pelo desenho antigo por ~6 quadros, e de novo quando o
"+6" sumia. A captura mostra: `art_key` vira vazio no q196 e a arte nova só volta no q202
(`antes_depois_armazem.png`: em cima, o quadro 196 antes — o prédio velho no lugar do novo; embaixo, o mesmo instante depois).

**A correção, na raiz:** refazer o espelho e **sincronizar no mesmo quadro** (`_rebuild_e_sincroniza`: refaz e chama `_sync_props`
de novo, que copia as propriedades e põe a arte nova). Vale pra todo prédio e prop que ganha filho (Centro, Oficina, Fornalha,
Escavadeira…): é o espelho de todos.

**As outras hipóteses, conferidas pela captura:**
- (a) `IsoArt.layers` troca de estado a cada quadro? **Não**: as camadas só mudam quando o estado muda (`art_key` estável).
- (b) disputa de ordem de desenho (`iso_order.gd`)? **Não** nessa cena: o z do prédio e os reparos da ordem não mudaram nos quadros
  gravados (`ordem.reparos` constante).
- (c) tremor por posição fracionária? Não apareceu: a posição do espelho e dos sprites não mudou.
- (d) a luz da janela: só aparece o **corte de luz fora da tela** (`cullable_lights`), que acende/apaga a luz quando a câmera troca de
  prédio — comportamento esperado, ~6 quadros; não é o piscar relatado.

**Teste de estabilidade** (`b130`, seção F): 120 quadros sem mudar nada = mesma assinatura; entra um filho (popup) e sai: em NENHUM dos
20 quadros seguintes o desenho muda, no Armazém e no Centro. Sem a correção ele falha (conferido: 3 falhas).

## 2) Pisos (caminhos)
**Antes:** losangos coloridos desenhados por código (`_draw_caminhos`, "PROVISÓRIO"), refazendo todos os polígonos a cada mudança;
o cartão do menu mostrava outra arte.

**Agora:**
- **A arte** é a das folhas que você gerou no PixelLab (`docs/arte/chão`, copiadas pra `docs/arte/bloco130/fontes/`). O piloto que
  eu tinha gerado (ladrilho de 60x60 pelo `create_isometric_tile`) foi **descartado** em favor das suas folhas, que têm 16 variações por
  tipo: terra batida com sulcos (terra), brita e cascalho (cascalho), paralelepípedo e lajes rachadas (pedra). O losango é 64x32 (2:1) e
  a laje 16 px; escolhi 8 variações parecidas entre si por tipo (`ESCOLHA` em `pisos130.py`; os de desenho próprio — o "Y" escuro, as
  faixas, o aro de musgo — ficaram de fora).
- **Emenda pelos vizinhos:** cada célula escolhe a variação (hash da célula, estável) e quais lajes mostrar: entre dois ladrilhos só o
  topo (a trilha lê contínua) e a laje só onde o caminho acaba (esquerda sem vizinho em +y, direita sem vizinho em +x). Os cantos
  chanfrados dos ladrilhos deixavam frestas: o losango inteiro por baixo, no preto do contorno, fecha a trilha como junta.
- **Grade:** a célula passou de 20 px pra **64/3 px** do chão (com a escala 1,5 da vista, o losango da célula é exatamente 64x32 px
  de arte: sem escalar o desenho). Save antigo (grade de 20 px): cada célula velha vai pra célula nova que cobre o centro dela
  (`caminhos.load_save_data`; testado).
- **O mesmo desenho em todo lugar:** o atlas `assets/game/iso/pisos/pisos.png` faz o jogo, o fantasma do pincel e os cartões do
  CONSTRUIR (`cam_terra/cascalho/pedra.png`, 96x64: dois ladrilhos emendados, da mesma arte).
- **Fantasma do pincel:** o ladrilho de verdade na célula do mouse, verde (dá) ou vermelho (não dá), com o custo ("3 cr + 1 ferro")
  ou o que falta escrito em cima (`caminho_placer._fantasma`, `caminhos.motivo_celula`); some quando o pincel termina.
- **Em lote:** UM `MultiMeshInstance2D` (uma instância por célula, ordenadas por profundidade; o dado da peça vai por instância
  num shader pequeno). Só refaz quando `versao` muda. Medido: 3000 células refeitas em ~90 ms (2 quadros).
- **Intactos** (e testados): save compacto, custo por célula, bônus de velocidade (Trilhas batidas multiplica), a rota da hora social.

Capturas: `docs/arte/bloco130/pisos/antes_*.png` e `depois_*.png` (`antes_depois_zoom.png` lado a lado) e
`folha_atlas.png` (a conferência do atlas).

## Também corrigido nesta rodada (achado pela bateria)
- **`social_spot._prepara`**: com a malha de navegação vazia (logo depois de construir um prédio, antes de ela ser refeita) o servidor
  devolve (0, 0) e os lugares do ponto social ficavam **na origem do mapa — pra sempre** (a origem do ponto não muda, então nunca
  recalculava). Agora não guarda lugar inválido e tenta de novo. Era o `b89_caminhos` "o passeio usa os pontos do caminho" que
  falhava desde antes.

## O que não foi verificado
- Nada jogado: a aparência em partida de verdade (as capturas foram em cenas montadas por script).
- As variações escolhidas por tipo (`ESCOLHA`) são palpite meu: se alguma não agradar, é só trocar o índice (0 a 15, linha a linha na
  folha) e rodar `python pisos130.py integra && python pisos130.py cartoes`.
- A laje de 16 px é a dos seus ladrilhos (uma trilha "elevada"); se quiser mais baixa, é uma constante (`ESP`) e o corte.
