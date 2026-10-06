"""Gera docs/DEEP_IRON_Guia_completo_e_Analise.docx (python-docx): o guia de todas as mecânicas + a análise.
  python tools/documento_guia/gera_doc.py   (depois, abrir no Word e atualizar o sumário: botão direito > Atualizar campo)
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from doc_base import doc, RODAPE
from doc_parte1 import parte1
from doc_parte2 import parte2

parte1()
parte2()
RODAPE("DEEP IRON — Guia completo do jogo e análise  •  outubro de 2026")
saida = r"D:\DEV\deep-iron\docs\DEEP_IRON_Guia_completo_e_Analise.docx"
doc.save(saida)
print("ok", saida, os.path.getsize(saida) // 1024, "KB")
