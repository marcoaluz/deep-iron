"""Bloco 111: a ESCOLA no PixelLab, na receita dos prédios do jogo (regra 11 do CLAUDE.md: obra 1 -> 2 -> 3 -> pronto). É o
predios107.py com a escola (este script só troca a tabela e o registro dos jobs).

  python predios111.py guia escola      -> escola/predio.json + escola/guia.png (a guia 2:1)
  python predios111.py pronto escola    -> escola/pronto.png (guia + a oficina e a casa aprovadas + o minerador)
  python predios111.py obra escola      -> escola/obra_2.png (o esqueleto no mesmo quadro) e jobs.json
  python obras.py escola                -> obra_1 e obra_3
  python predios111.py menu escola      -> assets/game/ui/icones/predios/escola.png
  python predios111.py legado escola    -> assets/game/escola.png
"""
import os, sys
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import predios107 as p  # noqa: E402

p.JOBS = os.path.join(AQUI, "predios111_jobs.json")
p.ESTRUTURAS.clear()
p.ESTRUTURAS.update({
    "escola": {
        "caixa": (120.0, 90.0, 58.0, 44.0, (30.0, 40.0)),
        "ref": "oficina",
        "pronto": ("A small village SCHOOLHOUSE for a gritty isometric mining colony that survived a solar catastrophe, exactly "
                   "filling the isometric 2:1 box of the guide: a one-room schoolhouse of dark weathered timber planks on a low "
                   "fieldstone base, a pitched roof of patched dark shingles and rusty tin with a tiny open wooden bell tower on "
                   "the ridge holding a small dull brass bell, two small square windows with cracked panes, a plain wooden door "
                   "at the front where the orange outline is, a slate CHALKBOARD hanging on the wall beside the door with a few "
                   "chalk letters and an abacus, a short wooden bench under it, a rope swing hanging from a rough post at one "
                   "corner and a little patch of worn ground for playing, a stack of old books tied with string on the bench. It "
                   "must clearly read as a humble village SCHOOL for children. " + p.SEM + p.FIM % "one accent: chalk white and "
                   "dull brass"),
        "obra": ("CONSTRUCTION of the SAME small schoolhouse as the reference, exactly on the same footprint, position, size and "
                 "angle in the canvas: only the low fieldstone base and the bare timber frame (posts, beams and roof rafters) "
                 "standing, a few wall planks nailed on the lower part, no roof covering, no bell; a pile of planks, a ladder, a "
                 "sawhorse and a bucket of nails around it. No characters, no background, no ground tiles. Same art style, "
                 "palette and pixel size as the reference; crisp 1px near-black outline; light from top-left.")},
})

if __name__ == "__main__":
    {"guia": p.guia, "pronto": p.pronto, "obra": p.obra, "legado": p.legado, "menu": p.menu}[sys.argv[1]](sys.argv[2])
