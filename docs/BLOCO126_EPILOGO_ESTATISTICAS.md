# Bloco 126 — Epílogo, estatísticas e modo infinito (Prompt 15)

## O que entrou
- **Epílogo** em arquivo editável: `data/epilogo/epilogo.txt` (imagem, título, subtítulo e parágrafos). Usa a ilustração que já existe (`escudo_vitoria`) — nenhuma geração nova do PixelLab. Se o arquivo sumir, a tela usa o epílogo de `data/missoes/capitulo_6.txt` (Bloco 122).
- **Estatísticas completas** (`estatisticas.gd`, nó "Estatisticas", chave de save `estatisticas`): dias de vila, ipezinhos que passaram pela vila (cada ipezinho novo do grupo conta uma vez; vivos agora), mortes e **por causa** (criaturas, radiação, expedições, acidentes na mina, outras; hook `ipezinho._die` → `registra_morte`), invasões vencidas, minério guardado e barras/aço/lingotes produzidos (somados de `armazem.lifetime_stored` e da `produzido` das fornalhas), festivais (hook em `morale.throw_festa`), pedidos cumpridos (inclui encomendas da caravana), a caravana (se já veio) e as linhas das missões (missões, pesquisas, matriarcas, títulos, minério vendido).
- **Tela de vitória** (`ui/victory.gd`): ilustração + epílogo + estatísticas numa tela que rola, e as duas saídas: **"Continuar em modo infinito"** e **"Voltar ao menu inicial"** (salva). O "Continuar jogando" antigo saiu.
- **Modo infinito** (`sun.infinito`, salvo no "sun"): o escudo segue aceso e a vitória não se repete (`win()` continua ignorando), as invasões seguem como antes e os **eventos voltam a rodar** (antes a vitória os travava: `eventos._ocupado`). Sem ondas solares (o escudo as segura).
- **Janela do Sol**: depois da vitória ganha o botão "Ver o epílogo e as estatísticas" (reabre a tela; no modo infinito mostra "Fechar" no lugar de "Continuar").
- Save antigo: sem `estatisticas` (mortes/invasões vêm dos contadores das missões, "passaram" recomeça da população atual) e sem `infinito`.
- Teste `b126_epilogo_estatisticas.gd` (0 falhas). Vizinhos que passaram: b122, b123, b125, b100, b110, b93, b108, p28_save, hud_frostpunk.

## O que NÃO foi verificado
- Nada jogado: a tela com muita estatística não foi vista numa janela real (só em headless; a rolagem existe, o tamanho foi estimado pela altura da janela).
- "Ipezinhos que passaram" conta quem entrou no grupo desde que este bloco existe; partidas antigas começam da população atual. Mortes anteriores ficam só no total (sem causa).
- O modo infinito não escala a dificuldade além do que a Defesa já faz por onda; se ficar fácil demais depois do escudo, é balanceamento a medir.
- A telemetria CSV (Bloco 52) não foi usada como fonte (ela é só de editor); as estatísticas vêm dos contadores do jogo.
