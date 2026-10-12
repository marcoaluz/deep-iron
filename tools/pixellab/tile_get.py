"""Baixa um tile isométrico do PixelLab (espera ficar pronto). Uso: python tile_get.py <tile_id> <saida.png> [espera_s]"""
import json
import os
import re
import sys
import time
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pl


def texto(msgs):
    out = []
    for m in msgs:
        r = m.get("result", m.get("error"))
        if isinstance(r, dict) and "content" in r:
            for c in r["content"]:
                if c.get("type") == "text":
                    out.append(c.get("text", ""))
    return "\n".join(out)


def baixa(tile_id, dest, espera=240):
    t0 = time.time()
    while True:
        t = texto(pl.call("get_isometric_tile", {"tile_id": tile_id}))
        m = re.search(r"download:\s*(https?://\S+)", t)
        if m and "status: completed" in t:
            url = m.group(1).rstrip(").,\"'")
            req = urllib.request.Request(url, headers={"User-Agent": "curl/8.0"})
            with urllib.request.urlopen(req, timeout=120) as r:
                data = r.read()
            os.makedirs(os.path.dirname(os.path.abspath(dest)), exist_ok=True)
            open(dest, "wb").write(data)
            return len(data)
        if time.time() - t0 > espera:
            print("sem imagem ainda:\n" + t[:600])
            return 0
        time.sleep(10)


if __name__ == "__main__":
    n = baixa(sys.argv[1], sys.argv[2], float(sys.argv[3]) if len(sys.argv) > 3 else 240)
    print("baixou", n, "bytes ->", sys.argv[2])
