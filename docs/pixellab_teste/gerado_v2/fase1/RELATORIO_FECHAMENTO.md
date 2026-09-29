# Fase 1 — fechamento (pronta para aprovação)

Data: 2026-09-29. Complementa o `RELATORIO_FASE1.md`. Nada foi integrado ao jogo; nenhum
código, cena ou save foi alterado.

**Página de revisão com as pranchas e os GIFs:** `docs/pixellab_teste/revisao_fase1.html`
(abre direto no navegador).

## Checklist do fechamento

| Item | Status | Resultado |
|---|---|---|
| Casa em escala real (2×) | ✅ | Canvas **256×224**, conteúdo **250×202 px**, porta **~66 px** para um minerador de 71 px (antes: 119×105 px, porta ~33 px) |
| Texto de estilo padrão | ✅ | "Crisp 1px near-black outline…" virou o padrão, salvo no fluxo (memória) e na receita abaixo |
| Guarda regerado com o contorno corrigido | ✅ | Borda escura **84% → 95%** (minerador 100%, CraftPix 95%). Parado e caminhada |
| Gesto de chegada (uma tentativa) | ✅ **resolvido por animação** | A 2ª interpolação estabilizou. Não é preciso corte por código |
| Machucado grave | ✅ definido | Pose parada sentada com tala + respiração por código. Nenhuma tentativa nova de animação de IA |
| Página de comparação | ✅ | `revisao_fase1.html` |

## 1. Casa em escala real

- **Geração:** `create_image_pro` 256×224 com o texto de estilo padrão e o minerador como
  referência de escala. Acima de 170 px a ferramenta devolve **1 candidato por chamada**
  (20 gerações). Saiu bom de primeira; não houve segunda chamada.
- **Tamanho final:** 250×202 px de conteúdo, num canvas de 256×224. É ~2,1× a casa reduzida
  e ~2,8× a altura do minerador.
- **Escala:** a porta tem ~66 px até a soleira. Com o minerador na porta, o arco chega na
  altura do capacete (`casa_escala_real_com_minerador.png`).
- **Estilo:** o mesmo da versão reduzida (ardósia com musgo, chapa enferrujada com buraco,
  base de pedra, tábuas, caixote e cano), com o contorno escuro nítido do texto novo.
- **Ajuste de câmera e zoom:** não tratado aqui, fica para o Bloco 48 e a Fase 3. Referência:
  a casa ocupa 250×202 px de arte **nativa**, e o jogo hoje mostra a arte ampliada 2×.

Arquivos: `teste_consistencia/fechamento/casa_2x.png`, `casa_escala_real_vs_reduzida.png` e
`casa_escala_real_com_minerador.png`.

## 2. Texto de estilo padrão (usar em toda geração daqui pra frente)

> Grimy, dark, desaturated earthy palette: dark browns, rust, lead grey, soot black; [um
> acento, se houver]. Darker and dirtier than the references. **Crisp 1px near-black outline
> around the silhouette like the references; interior detail drawn with darker shades of the
> local color rather than black lines.** Clear form shading with light from top-left, low
> color count, clean readable pixel clusters.

Nunca mais usar "not pure black". O contorno da CraftPix é quase preto (95% da borda).

**Canvas padrão de personagem: 48×84.** O modelo estica o boneco até a altura do canvas.

## 3. Guarda regerado

- **Prompt:** idêntico ao da Fase 1, trocando só a frase do contorno. Canvas 48×84,
  16 candidatos, todos inteiros (nenhum cortado); **escolhido o 0**.
- **Borda escura:** 95% no escolhido; os 16 candidatos variam de 88% a 97%. O guarda antigo
  tinha 84%.
- **Personagem v3:** 8 direções coerentes; o sul difere do candidato em apenas 2 pixels.
- **Caminhada** (skeleton-v3 `walking-4-frames`): estável, mesmo boneco nos 4 quadros.

Arquivos: `teste_consistencia/fechamento/guarda_antigo_vs_novo_vs_minerador.png`,
`guarda_v2b_8_direcoes.png`, `guarda_v2b_caminhada_skeleton.gif` e `guarda_contorno_grade_16.png`.
ID no PixelLab: `eaf95051-d3ca-4573-82be-f6c8bc20db87` (o guarda antigo `260cfe31…` pode ser
apagado).

## 4. Gesto de chegada: **resolvido por animação (1 tentativa)**

- **Método:** interpolação v3 do estado "picareta nas costas" (leste) até o estado "erguida"
  (leste). Mudanças em relação à 1ª tentativa:
  - 6 quadros em vez de 4;
  - descrição focada no braço: a mão sobe, pega o cabo e traz a picareta por cima do ombro;
  - pedido explícito de que a picareta nunca some.
- **Resultado:** a picareta aparece em todos os quadros. Ela sobe pelas costas, a mão pega o
  cabo, ela passa por cima do ombro e assenta nele. O boneco é o mesmo do início ao fim.
- **Único defeito:** a lanterna oscilava entre laranja e amarelo. Corrigi com a mesma troca
  de cores pela paleta de origem usada no golpe (29–43 px por quadro).
- **Custo:** 1 geração. **Não é preciso corte por código.** Se algum dia a chegada for
  cortada por desempenho, a troca instantânea entre os estados continua disponível.

Arquivos: `gerado_v2/fase1/anim_chegada_tentativa2_paleta/` (7 quadros),
`anim_chegada_tentativa2_paleta.gif` e `anim_chegada_tentativa2_paleta_tira.png`.
Sequência completa do minerador: caminhada com a picareta nas costas → **chegada** →
golpe em ciclo.

## 5. Machucado grave: pose parada + respiração por código

- **Arte:** o estado "machucado grave" (72×80, 8 direções), sentado, com tala e cabeça
  baixa, sem sangue.
- **Movimento:** feito pelo código, sem animação de IA. Ciclo de ~1,6 s em que o tronco e a
  cabeça sobem 1 px (ou escala vertical de 1–2% com pivô no quadril), com quadril e pernas
  parados. Simulação local: `gerado_v2/fase1/grave_respiracao_codigo.gif`.
- **Nenhuma nova tentativa de animação de IA** foi feita. As duas da Fase 1 ficam registradas
  como descartadas (skeleton levanta o personagem; v3 texto muda o rosto).

## Custo do fechamento

Medido pelo saldo: **45 gerações** (272 → 317 usadas; sobram **1683** até 2026-10-29).

| Item | Custo anunciado |
|---|---|
| Casa 2× (`create_image_pro` 256×224, 1 candidato) | 20 |
| Guarda com contorno (`create_image_pro` 48×84, 16 candidatos) | 25 |
| Guarda → personagem v3 | 1 |
| Chegada, tentativa 2 (v3 interpolação) | 1 |
| Caminhada do guarda (skeleton-v3) | 2–4 (a doc não dá valor exato) |

Somando os anunciados, daria 49–51. O saldo registrou 45; considero o saldo o valor real.
Total do redesenho até aqui: **317 gerações** (teste v2 25 + Fase 1 247 + fechamento 45).

## Fase 1: pronta para aprovação

Entregue e validado:
- **Minerador v2 corrigido:** parado nas 8 direções e 6 estados.
- **Animações estáveis do minerador:** caminhada, caminhada com a picareta (embutida e
  sobreposta), chegada, golpe e machucado leve.
- **Machucado grave:** pose parada, com a respiração a cargo do código.
- **Guarda:** parado nas 8 direções e caminhada.
- **Casa nível 1** em escala real.
- **Fluxo padrão documentado:** texto de estilo, canvas e ferramentas por tipo de animação.

## O que vai para a Fase 2 (elenco completo)

Base: o jogo hoje tem **9 funções × 2 gêneros (menino/menina) × 6 variações** de
roupa/cabelo/pele (`ipezinho.gd`: `JOB_OUTFIT`, `GENDERS`, `LOOKS_PER_GENDER`). Regra do
projeto: toda função tem traje próprio.

### 2a. Personagens base (parado nas 8 direções + caminhada)
| Função | Menino | Menina |
|---|---|---|
| Minerador | ✅ feito | a fazer |
| Guarda | ✅ feito | a fazer |
| Sem função (civil) | a fazer | a fazer |
| Cozinheiro | a fazer | a fazer |
| Lenhador | a fazer | a fazer |
| Pesquisador | a fazer | a fazer |
| Caçador | a fazer | a fazer |
| Médico | a fazer | a fazer |
| Engenheiro | a fazer | a fazer |

São **16 personagens**, a ~30 gerações cada (`create_image_pro` 25 + v3 1 + skeleton ~4):
**≈ 480 gerações**.

### 2b. Ferramentas e armas sobrepostas (mesma lógica da picareta)
- **Lista:** machado, arco, cesto de coleta, martelo, porrete, lança, besta, lança de prata e
  picareta de aço (a Oficina já troca o visual da picareta). A picareta de ferro final
  substitui a de teste.
- **Custo:** ~10 sprites × 25 gerações (64 candidatos em até 42 px; armas longas podem
  precisar de canvas maior) **≈ 250**.

### 2c. Animações de trabalho, uma por função
- **Técnica:** a mesma do golpe de minerar (estado de início + estado de fim + interpolação),
  com a ferramenta embutida:
  - lenhador: machadada;
  - cozinheiro: mexer a panela;
  - caçador: atirar com o arco;
  - médico: atender;
  - engenheiro: martelar;
  - pesquisador: escrever ou ler;
  - guarda: golpe;
  - minerador: menina.
- **Custo:** ~41 gerações por personagem (2 estados + interpolação).
  **Minerador menina + 7 funções × 2 gêneros ≈ 15 personagens ≈ 615 gerações.**
- Pode entrar também o gesto de pegar e guardar a ferramenta (1 geração por personagem),
  se o Marco quiser.

### 2d. Machucados para todo o elenco
- **Por personagem:** estado leve + animação v3 (~21) e estado grave parado (~20),
  ≈ 41 gerações. **17 personagens ≈ 700 gerações.**
- **Alternativa mais barata:** manter o curativo como ícone sobreposto (como o jogo já faz)
  e reservar os estados de machucado ao minerador e ao guarda.

### Decisões que a Fase 2 precisa do Marco
1. **Variações de roupa, cabelo e pele (6 por gênero hoje).** Recomendo fazê-las por **troca
   de paleta no código** (as cores dos sprites gerados são poucas e agrupadas), e não
   gerando personagens novos. Gerar custaria ~20 gerações por variação: 18 × 5 × 20 ≈ 1800.
2. **Orçamento.** 2a + 2b + 2c + 2d ≈ **2045 gerações**, acima das 1683 que sobram neste
   ciclo. Sugestão: fazer 2a + 2b + 2c (≈1345) neste ciclo, com checkpoint no meio (depois de
   2a), e 2d no próximo ciclo (renova em 2026-10-29) ou na versão com ícone.
3. **Machucados:** estados completos para todos ou ícone sobreposto.

Fora da Fase 2 (fases seguintes): prédios em geral (Fase 3, já em escala real), chão e
tileset, criaturas, rochas, tocha, UI, e a integração ao jogo (câmera e zoom no Bloco 48).
