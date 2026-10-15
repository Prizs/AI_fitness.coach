with open('mobile_app/lib/services/weekly_plan_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

import re
matches = re.findall(r'Future<void> _fetchAndSave\(.*?\).*?\{.*?\n  \}', text, re.DOTALL)
if matches:
    print(matches[0][:1500])
else:
    print("No match")
