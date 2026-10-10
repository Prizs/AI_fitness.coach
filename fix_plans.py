import sys

path = 'backend/app/routers/plans.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("\\nclass PlanFeedback", "\nclass PlanFeedback")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
