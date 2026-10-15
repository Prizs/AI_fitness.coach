path = 'mobile_app/lib/screens/coach_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import_statement = "import 'package:mobile_app/services/weekly_plan_service.dart';\n"
if "weekly_plan_service.dart" not in text:
    text = import_statement + text
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)
    print("Added import to coach_screen.dart")
else:
    print("Already imported")
