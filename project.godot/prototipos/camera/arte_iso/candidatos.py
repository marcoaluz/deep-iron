"""PROTÓTIPO: baixa os candidatos de um create_image_pro e monta a grade pra escolher.
  python candidatos.py <pasta> <job_id> [n=16]
"""
import sys, os, subprocess
from PIL import Image, ImageDraw

pasta, job = sys.argv[1], sys.argv[2]
n = int(sys.argv[3]) if len(sys.argv) > 3 else 16
os.makedirs(os.path.join(pasta, "candidatos"), exist_ok=True)
fs = []
for i in range(n):
    f = os.path.join(pasta, "candidatos", "c%02d.png" % i)
    subprocess.run(["curl", "-s", "-A", "curl/8", "-o", f,
                    "https://api.pixellab.ai/mcp/images/%s/download?index=%d" % (job, i)], check=True)
    fs.append(f)
S = 3
im0 = Image.open(fs[0])
W, H = im0.width * S, im0.height * S
g = Image.new("RGBA", (8 * (W + 6), ((n + 7) // 8) * (H + 18)), (90, 90, 100, 255))
d = ImageDraw.Draw(g)
for i, f in enumerate(fs):
    im = Image.open(f).convert("RGBA").resize((W, H), Image.NEAREST)
    x, y = (i % 8) * (W + 6), (i // 8) * (H + 18)
    g.paste(im, (x, y + 14), im)
    d.text((x + 3, y + 1), str(i), fill=(255, 255, 0))
g.save(os.path.join(pasta, "grade_16.png"))
open(os.path.join(pasta, "job.txt"), "w").write(job)
print(os.path.join(pasta, "grade_16.png"))
