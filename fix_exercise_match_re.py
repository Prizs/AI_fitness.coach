import sys
import re

path = 'mobile_app/lib/widgets/exercise_detail.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

pattern = r'initialExerciseId:\s*_mapAnimKeyToAnatomyId\(animationKey\),'
replacement = 'initialExerciseId: (dynamicExercises != null && dynamicExercises!.isNotEmpty) ? animationKey : _mapAnimKeyToAnatomyId(animationKey),'

text = re.sub(pattern, replacement, text)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
