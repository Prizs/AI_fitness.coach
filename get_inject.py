import os

path = 'mobile_app/lib/services/weekly_plan_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import re
matches = re.findall(r'Future<void> injectCustomPlanForToday.*?\}', text, re.DOTALL)
if matches:
    print(matches[0][:800])
