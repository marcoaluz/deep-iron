# Bloco 119 — A arte própria do carregador e do mecânico (relatório)

Data: 2026-10-11. Branch `isometrico`. Pedido do Marco: "verifique porque, quando coloco um ipezinho como carregador ele fica com a roupa igual a quando está sem função, e a roupa do mecânico também parece que não muda".
Teste: `tests/blocos/b119_arte_carregador_mecanico.gd`, **0 falhas**, registrado no GUT (`test_b119_arte_carregador_mecanico`).

## 1) A causa

Os dois ofícios entraram no Bloco 105 **sem arte própria**: o Marco queria aprovar o piloto antes do lote (só o carregador homem foi feito, com a folha em `docs/arte/bloco105/`), e a integração ficou esperando.
Enquanto isso o jogo usava `iso_bonecos.PROVISORIO = {"carregador": "civil", "mecanico": "engenheiro"}`: o carregador vestia o **civil** (a roupa de quem está sem função) e o mecânico vestia o **engenheiro**.
Era o comportamento previsto, não um erro de código; a regra do projeto ("função nova traz a roupa dela no mesmo bloco") ficou pendente.

## 2) O que foi feito (PixelLab, a receita do elenco: `oficios105.py`, a mesma do `oficios92.py`)

| Personagem | Gerações aproximadas | Resultado |
|---|---|---|
| Carregadora | candidatos (16) → v3 "high top-down" → caminhada de 8 quadros, comer, ferido, deitar, mancar, carregar → casaco de inverno (caminhada + carregar) → retrato | pronta |
| Mecânico | o mesmo, com o trabalho "consertar" | pronto |
| Mecânica | o mesmo | pronta |
| Carregador (homem) | já existia (piloto do Bloco 105) | integrado agora |

Candidatos escolhidos: carregadora c00, mecânico c06 (silhueta limpa, sem a chave na mão), mecânica c00. Retratos: 5 expressões (neutro, contente, cansado, bravo, ferido) × 3 tons de pele, para os quatro.
O `integra.py` ganhou as duas funções (`FUNCOES`: carregador → carregador/carregadora/carregar; mecanico → mecanico/mecanica/consertar) e o `retratos.py` as notas da carregadora, do mecânico e da mecânica (para o modelo não inventar chapéu).
Folhas de conferência em `docs/arte/bloco119/` (`carregadora_conferencia.png`, `mecanico_conferencia.png`, `mecanica_conferencia.png`: as 8 poses, o casaco e o retrato).

## 3) No jogo

O `bonecos.json` agora tem as funções `carregador` e `mecanico`, então o `PROVISORIO` **deixa de valer sozinho** (ele só vale para função que não está no `bonecos.json`). Cada ipezinho com a função usa o boneco dela (homem e mulher), o casaco de inverno da função no frio,
a animação do trabalho (carregar / consertar) e o retrato próprio na ficha, no cartão e nos eventos. Sem função continua o civil (diferente do carregador).

## 4) Testes

`b119_arte_carregador_mecanico` (0 falhas): as 4 pastas e os 4 casacos no `bonecos.json` com todas as animações nas 4 direções; `outfit()` e `funcao_de` devolvem a função própria; homem e mulher usam a pasta certa; o casaco; o civil continua diferente; os retratos com as 5 expressões nos 3 tons.
Vizinhos (um por vez, APPDATA isolado): b92, b94, b104, b105, b107, b111, b109 (ver a seção final do commit).

## 5) O que NÃO foi feito / não verificado

- **Ícone da barra de funções** do carregador e do mecânico: seguem os ícones provisórios do Bloco 105 (`it_mochila` / `it_ferragem`); a arte dos ícones (`oficios105.py icones`) fica para quando você pedir.
- Nada foi visto numa partida de verdade (só as folhas e os testes). O "carregar" **de frente** do carregador (homem) perde um pouco a armação da mochila (defeito apontado no Bloco 105; a carregadora saiu melhor).
- O retrato neutro da mecânica não mostra a bandana vermelha (as expressões mostram): é como o modelo desenhou o neutro.
- Custo do PixelLab: umas 100 gerações (saldo era 5.487).
