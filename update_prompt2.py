# -*- coding: utf-8 -*-
with open('backend/app/routers/coach.py', 'r', encoding='utf-8') as f:
    content = f.read()

old_prompt_marker = '"Eres un Coach de Fitness y Nutricion altamente interactivo.'
if old_prompt_marker in content:
    # Let's do a more robust regex or exact replace by just reconstructing the prompt block.
    # Actually, it's easier to just use regex to replace the entire prompt = (...) block.
    pass
