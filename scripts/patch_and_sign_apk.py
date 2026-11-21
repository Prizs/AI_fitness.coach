import os
import zipfile
import subprocess
import shutil

ROOT = r"C:\AI_FITNESS_COACH_PROYECTO_COMPLETO"
SOURCE_APK = os.path.join(ROOT, "releases", "app-release.apk")
SCRATCH_DIR = os.path.join(ROOT, "scratch_apk")
UNSIGNED_APK = os.path.join(ROOT, "releases", "AI_Fitness_Coach_v1080_unsigned.apk")
OUT_DIR = os.path.join(ROOT, "releases", "latest")
UBER_JAR = os.path.join(ROOT, "scripts", "uber-apk-signer.jar")

OLD_URL = b"https://ai-fitness-coach-818a.onrender.com"
NEW_URL = b"https://ai-fitness-coach-wlg3.onrender.com"
OLD_HOST = b"ai-fitness-coach-818a.onrender.com"
NEW_HOST = b"ai-fitness-coach-wlg3.onrender.com"

assert len(OLD_URL) == len(NEW_URL), "Lengths must match!"
assert len(OLD_HOST) == len(NEW_HOST), "Host lengths must match!"

print(f"Reading source APK: {SOURCE_APK}")
if os.path.exists(SCRATCH_DIR):
    shutil.rmtree(SCRATCH_DIR)
os.makedirs(SCRATCH_DIR, exist_ok=True)
os.makedirs(OUT_DIR, exist_ok=True)

modified_files = []
total_replacements = 0

with zipfile.ZipFile(SOURCE_APK, 'r') as zin, zipfile.ZipFile(UNSIGNED_APK, 'w', zipfile.ZIP_DEFLATED) as zout:
    for item in zin.infolist():
        # Skip existing signature files in META-INF
        if item.filename.startswith("META-INF/") and (
            item.filename.endswith(".SF") or
            item.filename.endswith(".RSA") or
            item.filename.endswith(".MF") or
            item.filename.endswith(".DSA") or
            item.filename.endswith(".EC")
        ):
            continue

        data = zin.read(item.filename)
        count = data.count(OLD_URL) + data.count(OLD_HOST)
        if count > 0:
            data = data.replace(OLD_URL, NEW_URL)
            data = data.replace(OLD_HOST, NEW_HOST)
            modified_files.append((item.filename, count))
            total_replacements += count

        zout.writestr(item, data)

print(f"Finished repacking unsigned APK. Total replacements: {total_replacements}")
for fname, cnt in modified_files:
    print(f"  - {fname}: {cnt} replacements")

# Now sign with uber-apk-signer
print("\nSigning APK with uber-apk-signer (v1 + v2 + zipalign)...")
cmd = [
    "java", "-jar", UBER_JAR,
    "--allowResign",
    "-a", UNSIGNED_APK,
    "-o", OUT_DIR
]

res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
print(res.stdout)

# Find generated signed APK in OUT_DIR
signed_apks = [f for f in os.listdir(OUT_DIR) if f.endswith(".apk") and "aligned" in f or "signed" in f or "1080" in f]
print("Signed APKs:", signed_apks)

if signed_apks:
    # Pick the most recently modified signed apk in OUT_DIR
    full_signed_paths = [os.path.join(OUT_DIR, f) for f in os.listdir(OUT_DIR) if f.endswith(".apk")]
    full_signed_paths.sort(key=os.path.getmtime, reverse=True)
    final_signed = full_signed_paths[0]
    print(f"Latest signed APK chosen: {final_signed}")

    target_v1080 = os.path.join(ROOT, "releases", "AI_Fitness_Coach_Oficial_v1.0.80.apk")
    target_latest = os.path.join(ROOT, "releases", "app-release.apk")
    web_dist_apk = os.path.join(ROOT, "backend", "app", "web_dist", "AI_Fitness_Coach.apk")
    web_dist_v1080 = os.path.join(ROOT, "backend", "app", "web_dist", "AI_Fitness_Coach_v1.0.80.apk")

    shutil.copy2(final_signed, target_v1080)
    shutil.copy2(final_signed, target_latest)
    shutil.copy2(final_signed, web_dist_apk)
    shutil.copy2(final_signed, web_dist_v1080)
    print(f"Copied signed APK to:\n  {target_v1080}\n  {target_latest}\n  {web_dist_apk}\n  {web_dist_v1080}")
else:
    print("ERROR: No signed APK produced!")
