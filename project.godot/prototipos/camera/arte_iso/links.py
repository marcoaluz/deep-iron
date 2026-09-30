"""PROTÓTIPO: monta <pasta>/links.json a partir do id do personagem e dos ids da caminhada.
  python links.py <pasta> <character_id> <anim_SE> <anim_NE>
(os ids de animação são o trecho .../animations/<id>/<direção>/ do get_character)
<anim_NE> pode vir como "NO:<id>": a caminhada de trás é a NW e a NE sai por espelho.
"""
import sys, os, json
B = "https://backblaze.pixellab.ai/file/pixellab-characters/731c5e37-851f-4127-aec6-b6ac884bc069/%s/"
DIRS = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
pasta, cid, se, ne = sys.argv[1:5]
b = B % cid
os.makedirs(pasta, exist_ok=True)
json.dump({"rotacoes": {d: b + "rotations/%s.png" % d for d in DIRS},
           "caminhada": {"SE": [b + "animations/%s/south-east/%d.png" % (se, i) for i in range(4)],
                         **({"NO": [b + "animations/%s/north-west/%d.png" % (ne[3:], i) for i in range(4)]}
                            if ne.startswith("NO:") else
                            {"NE": [b + "animations/%s/north-east/%d.png" % (ne, i) for i in range(4)]})}},
          open(os.path.join(pasta, "links.json"), "w"), indent=1)
