# Prompt 1: elenco humano completo (isométrico)

Data: 2026-09-30. Arte em `project.godot/prototipos/camera/arte_iso/<personagem>/`. Nada
integrado ao jogo.

## Funções (conferidas no código)

`ipezinho.gd → JOBS`: sem função (civil), minerador, cozinheiro, lenhador, guarda,
pesquisador, caçador, médico, engenheiro. São **9 funções × homem/mulher = 18 personagens.**

## O que cada um tem

| | Pronto |
|---|---|
| Corpo com a roupa da função (silhueta própria de longe: capacete, touca, chapéu de chef, jaleco, capa, colete, gorro) | 18 ✅ |
| 8 poses paradas (4 de losango + as 4 retas, de graça) | 18 ✅ |
| Caminhada em 4 direções (SE e NE + espelho) | 18 ✅ |
| **1 animação de trabalho em 4 direções (8 quadros)** | **16 ✅** (sem função não tem trabalho) |
| 3 peles por troca de paleta | 18 ✅ (prancha) |

| Função | Trabalho |
|---|---|
| Minerador | golpe de picareta (a picareta embutida no golpe, como manda a regra da picareta híbrida) |
| Engenheiro | martelar na altura da cintura |
| Guarda | golpe com porrete e volta à guarda (sem sangue) |
| Médico | ajoelhar e fazer curativo (o paciente é do leito, não do desenho) |
| Cozinheiro | bater massa numa tigela de madeira no braço |
| Caçador | armar e atirar com o arco. **Só usada quando a Oficina libera o arco**; antes disso ele coleta (Prompt 2) |
| Lenhador | golpe de machado de lado |
| Pesquisador | mexer em instrumentos na bancada (a bancada é do laboratório) |

## Entregas (nesta pasta)

- `elenco_3_peles.png`: os 18 em original, clara, parda e negra.
- `caminhada_18.gif`: os 18 andando, SE e NE.
- `trabalho_16.gif`: as 16 animações de trabalho, SE e NE.
- `alturas_antes_depois.png`: a correção de altura.
- Por personagem, em `arte_iso/<personagem>/`:
  - `caminhada_4dir.gif` e `<trabalho>_4dir.gif`: as 4 direções;
  - `<trabalho>_folha.png`: os quadros SE e NE;
  - `prancha_8_direcoes_iso.png`: as 8 poses paradas.

## Custo

| Etapa | Gerações |
|---|---|
| Piloto do minerador (v3 texto; teste sem ajuste + versão final) | 6 |
| 15 animações de trabalho (2 por direção) | 60 |
| Refeitas: engenheira NE, guarda (3×), guarda mulher NE, lenhador NE, cozinheiros (2×) | 29 |
| Teste de esqueleto `cross-punch` no guarda | 2 |
| **Total do Prompt 1** | **97** (saldo 846 → **749**) |

O elenco em si (corpo, 8 direções, caminhada) já estava pronto do handoff anterior (515).

## Diversidade

- **Rostos e cabelos variados entre as funções:**
  - barba grisalha (caçador), bigode (cozinheiro), barba cheia (lenhador);
  - coque (pesquisadora), trança (caçadora e lenhadora), cabelo solto (mineradora);
  - lenço (civil mulher), barba por fazer (civil).
- **Corpo:** lenhador forte, civil magro, cozinheiro gordinho, civil mulher cheinha. Nas
  mulheres, curva discreta.
- **Alturas (Marco pediu, aprovado):** algumas mulheres tinham saído mais altas que o homem da
  mesma função. Com o corte de linhas, ficaram 3–4 px mais baixas:

  | Função | Mulher: antes → depois |
  |---|---|
  | Mineradora | 79 → 71 |
  | Guarda | 78 → 72 |
  | Cozinheira | 78 → 72 |
  | Engenheira | 80 → 76 |
  | Pesquisadora | 74 → 71 |
  | Lenhadora | 75 → 72 |

  Os originais ficaram em `_original/`.
- **3 peles:** funcionam nos 18.
  - No civil, a gola da camisa ocre muda um pouco junto com o rosto.
  - No caçador, a troca é fraca (rosto pequeno sob a barba).
  - Na integração vale a máscara de pele por quadro (CONTRATO §3).

## Desvios (reportando)

1. **Técnica.** O contrato manda tentar primeiro esqueleto, depois interpolação, depois v3 com
   texto. Pra trabalho não existe modelo de esqueleto; o `cross-punch` testado no guarda virou
   soco sem arma. A interpolação custaria 20–40 por personagem. Fiquei com **v3 com texto +
   limpeza automática**: corpo e roupa estáveis, 2 gerações por direção. Registrado no
   contrato.
2. **A IA desenha efeito e objeto mesmo pedindo pra não desenhar** (rastro branco, sopro,
   vapor, pedra, toco, panela no fogão):
   - o `trabalho.py` apaga rastro e sopro sozinho;
   - onde o objeto insistia, troquei a ação (cozinheiro com tigela no braço);
   - sobraram **cavacos voando** no golpe do lenhador (SE). Não dá pra tirar sem cortar o
     machado, que fica solto do corpo naquele quadro. Leem naturais.
3. **Direção de trás girando.** O guarda virava de frente no meio do golpe. Resolvi animando
   a **NO** e espelhando, como a caminhada da pesquisadora. As pesquisadoras também usam NO.
4. **Minerador.** A animação dele tem o quadro 0 de referência (sem picareta), porque foi a
   piloto. No jogo o ciclo usa os quadros 1–8.
5. As tentativas descartadas ficaram guardadas em `atacar_lote1/`, `cozinhar_lote1/` e
   `cozinhar_lote2/`.

## Ferramentas criadas

| Script | O que faz |
|---|---|
| `arte_iso/trabalho.py` | baixa pelo zip do personagem, limpa, corta a altura, espelha, calcula a âncora, monta GIF e folha |
| `arte_iso/encolhe.py` | corte de altura por linhas, com a tabela aprovada |
| `arte_iso/aplica_corte.py` | aplica o corte num personagem já pronto, guardando o original |
| `arte_iso/paletas_pele.json` | as 3 rampas de pele (fonte única) |
