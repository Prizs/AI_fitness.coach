import os
import zipfile
import subprocess
import shutil

ROOT = r"C:\AI_FITNESS_COACH_PROYECTO_COMPLETO"
SOURCE_APK = os.path.join(ROOT, "releases", "app-release.apk")
SCRATCH_DIR = os.path.join(ROOT, "scratch_apk")
UNSIGNED_APK = os.path.join(ROOT, "releases", "AI_Fitness_Coach_v1079_unsigned.apk")
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

with zipfile.ZipFile(SOURCE_APK, 'r') as zin, zipfile.ZipFile(UNSIGNED_APK, 'w', compression=zipfile.ZIP_DEFLATED) as zout:
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
signed_apks = [f for f in os.listdir(OUT_DIR) if f.endswith(".apk")]
print("Signed APKs:", signed_apks)

if signed_apks:
    final_signed = os.path.join(OUT_DIR, signed_apks[0])
    target_v1079 = os.path.join(ROOT, "releases", "AI_Fitness_Coach_Oficial_v1.0.79.apk")
    target_latest = os.path.join(ROOT, "releases", "app-release.apk")
    web_dist_apk = os.path.join(ROOT, "backend", "app", "web_dist", "AI_Fitness_Coach.apk")
    web_dist_v1079 = os.path.join(ROOT, "backend", "app", "web_dist", "AI_Fitness_Coach_v1.0.79.apk")

    shutil.copy2(final_signed, target_v1079)
    shutil.copy2(final_signed, target_latest)
    shutil.copy2(final_signed, web_dist_apk)
    shutil.copy2(final_signed, web_dist_v1079)
    print(f"\n✔ APK v1.0.79 Generado y Firmado con Éxito en:")
    print(f"  1. {target_v1079} ({os.path.getsize(target_v1079)/(1024*1024):.1f} MB)")
    print(f"  2. {target_latest} ({os.path.getsize(target_latest)/(1024*1024):.1f} MB)")
    print(f"  3. {web_dist_apk} ({os.path.getsize(web_dist_apk)/(1024*1024):.1f} MB)")
    print(f"  4. {web_dist_v1079} ({os.path.getsize(web_dist_v1079)/(1024*1024):.1f} MB)")
