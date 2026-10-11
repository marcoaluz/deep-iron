"""Bloco 125: o POSTO DE TROCA no PixelLab (obra 1 -> 2 -> 3 -> pronto), na receita do predios111.py.

  python predios125.py guia posto_troca      -> posto_troca/predio.json + guia.png
  python predios125.py pronto posto_troca    -> posto_troca/pronto.png
  python predios125.py obra posto_troca      -> posto_troca/obra_2.png e jobs.json
  python obras.py posto_troca                -> obra_1 e obra_3
  python predios125.py menu posto_troca      -> assets/game/ui/icones/predios/posto_troca.png
  python predios125.py legado posto_troca    -> assets/game/posto_troca.png
"""
import os, sys
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import predios107 as p  # noqa: E402

p.JOBS = os.path.join(AQUI, "predios125_jobs.json")
p.ESTRUTURAS.clear()
p.ESTRUTURAS.update({
    "posto_troca": {
        "caixa": (120.0, 90.0, 52.0, 44.0, (30.0, 40.0)),
        "ref": "oficina",
        "pronto": ("A small TRADING POST for a gritty isometric mining colony that survived a solar catastrophe, exactly filling the "
                   "isometric 2:1 box of the guide: a long low open-fronted market building of dark weathered timber with a wide "
                   "plank counter along the front, a sagging canvas awning in faded rust-red and ochre stripes over the counter, "
                   "wooden crates, barrels and burlap sacks stacked beside it, a hanging brass balance scale and a small iron "
                   "strongbox on the counter, a hand-painted wooden sign hanging from the awning with a crossed pickaxe and a "
                   "coin (no letters), an unlit iron lantern on a hook, a sturdy hitching post with a loose cart wheel leaning "
                   "next to it, a plank door at the back where the orange outline is. It must read clearly as a humble "
                   "village TRADING POST where travelling merchants set up. " + p.SEM + p.FIM % "one accent: faded rust-red and ochre canvas"),
        "obra": ("CONSTRUCTION of the SAME small trading post as the reference, exactly on the same footprint, position, size and "
                 "angle in the canvas: only the low stone footing and the bare timber frame (posts, beams and roof rafters) "
                 "standing, the plank counter half built, no awning, no goods; a pile of planks, a ladder, a sawhorse and a "
                 "bucket of nails around it. No characters, no background, no ground tiles. Same art style, palette and pixel "
                 "size as the reference; crisp 1px near-black outline; light from top-left.")},
})

if __name__ == "__main__":
    {"guia": p.guia, "pronto": p.pronto, "obra": p.obra, "legado": p.legado, "menu": p.menu}[sys.argv[1]](sys.argv[2])
