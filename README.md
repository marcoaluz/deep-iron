# DEEP IRON

Colônia de mineração depois de uma explosão solar: os ipezinhos cavam uma pedreira, erguem a vila
dentro dela, descem pros andares de baixo (nível 2, abismo) e precisam aguentar invasões, ondas
solares e greves até construir o escudo solar. Vista isométrica em pixel art, Godot 4.7.

## Abrir e jogar

1. Godot **4.7.2** (o binário usado: `Godot_v4.7.2-stable_win64.exe`).
2. Abrir a pasta `project.godot/` no Godot (Importar → `project.godot`).
3. F5 roda pelo menu inicial (`scenes/ui/start_menu.tscn`).

Atalhos no jogo: `H` mostra a lista; `F2` abre o corte da mina; `Espaço` o menu de construção.

## Testes

Ver [`TESTING.md`](TESTING.md). Resumo:

```
# tudo (GUT headless, cada bloco num Godot separado, com a pasta de save isolada)
tools/run_tests.ps1        (Windows)   |   tools/run_tests.sh   (bash)
```

**Nunca** rodar testes que abram a partida sem a pasta de usuário isolada (`APPDATA`/
`XDG_DATA_HOME` apontando pra uma pasta com `fake_appdata` no caminho): os testes abortam sozinhos
fora dela, pra não tocar no save de verdade.

## Pastas

| Pasta | O quê |
|---|---|
| `project.godot/scripts/core` | sistemas do jogo (economia, defesa, ânimo, save, sol, pesquisa, HUD e painéis) |
| `project.godot/scripts/workers` | o ipezinho (IA, funções, necessidades) |
| `project.godot/scripts/props` | prédios e objetos |
| `project.godot/scripts/creatures` | invasores |
| `project.godot/scripts/iso` | a vista isométrica (espelhos, ordem de desenho, arte nova, luz, efeitos) |
| `project.godot/scripts/ui` | pele da interface, ícones, retratos, menus, corte da mina |
| `project.godot/assets/game/iso` | arte isométrica integrada (prédios, bonecos, props, luz, efeitos) |
| `project.godot/assets/game/ui` | arte da interface (9-slice, ícones, retratos, ilustrações, título) |
| `project.godot/prototipos/camera/arte_iso` | o pipeline da arte (o que veio do PixelLab + `integra.py`, que leva pro jogo) |
| `project.godot/tests` | testes (`test_blocos.gd` roda cada `tests/blocos/*.gd` num processo isolado) |
| `tools/` | scripts de apoio (testes, build, contorno da arte, ajudantes do PixelLab) |
| `docs/` | relatórios dos blocos e dos prompts de arte, contrato de arte, inventário |

Contexto pra retomar o trabalho: [`CONTEXTO.md`](CONTEXTO.md). Como o trabalho é organizado:
[`docs/PROCESSO.md`](docs/PROCESSO.md).
