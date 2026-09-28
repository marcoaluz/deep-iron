"""Regressão dos sprites: compara project.godot/assets/game com uma cópia tirada ANTES
de rodar tools/gen_sprites.py (o gerador é determinístico: o que não foi mexido tem que
sair idêntico, byte a byte). Rodar da raiz do repositório:

    mkdir -p /tmp/antes && cp project.godot/assets/game/*.png /tmp/antes/
    python tools/gen_sprites.py
    python tools/sprite_regress.py /tmp/antes

Esperado: só mudam/aparecem os sprites que o bloco mexeu; "DEVIAM SER IGUAIS" = nenhum.
(Versionado no Bloco 43.)"""
import sys
import hashlib
from pathlib import Path
from PIL import Image

before = Path(sys.argv[1])
after = Path("project.godot/assets/game")
MUST_EQUAL = {"coin.png", "anger.png", "bandage.png", "strike_sign.png", "note.png", "shadow_blob.png",
              "find_bobina.png", "find_cristal.png", "find_peca.png", "find_solar.png"}


def md5(p):
    return hashlib.md5(p.read_bytes()).hexdigest()


changed, same, size_bad, missing, new = [], [], [], [], []
for p in sorted(before.glob("*.png")):
    q = after / p.name
    if not q.exists():
        missing.append(p.name)
        continue
    if Image.open(p).size != Image.open(q).size:
        size_bad.append(f"{p.name} {Image.open(p).size}->{Image.open(q).size}")
    (same if md5(p) == md5(q) else changed).append(p.name)
for q in sorted(after.glob("*.png")):
    if not (before / q.name).exists():
        new.append(f"{q.name} {Image.open(q).size}")

bad_equal = [n for n in MUST_EQUAL if n in changed]
print(f"mudaram: {len(changed)}  iguais: {len(same)}  novos: {len(new)}")
print("iguais:", same)
print("novos:", new)
print("TAMANHO MUDOU:", size_bad or "nenhum")
print("SUMIRAM:", missing or "nenhum")
print("DEVIAM SER IGUAIS E MUDARAM:", bad_equal or "nenhum")
