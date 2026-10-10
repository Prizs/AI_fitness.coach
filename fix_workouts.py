import sys

path = 'mobile_app/lib/screens/workouts_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

import_stmt = "import 'package:mobile_app/widgets/plan_options_sheet.dart';"
if import_stmt not in text:
    text = text.replace("import 'package:mobile_app/models/anatomy_exercise.dart';", "import 'package:mobile_app/models/anatomy_exercise.dart';\\n" + import_stmt)

old_refresh1 = "onPressed: () =>\\n                  _service.refresh(AuthService.instance.loggedInUser),"
new_refresh1 = "onPressed: () => showPlanOptionsSheet(context),"
text = text.replace(old_refresh1, new_refresh1)

old_refresh2 = "onRetry: () => _service.ensureLoaded(AuthService.instance.loggedInUser),"
new_refresh2 = "onRetry: () => showPlanOptionsSheet(context),"
text = text.replace(old_refresh2, new_refresh2)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
