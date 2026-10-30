import os
import sys
import sqlite3
import shutil
import zipfile
import json

CONV_ID = "d1e1171e-d6c3-4ed8-8769-1402d5e1e556"
USERPROFILE = os.environ.get("USERPROFILE", r"C:\Users\miope")
AGY_DIR = os.path.join(USERPROFILE, ".gemini", "antigravity")

conv_db_src = os.path.join(AGY_DIR, "conversations", f"{CONV_ID}.db")
brain_dir_src = os.path.join(AGY_DIR, "brain", CONV_ID)
summaries_db_src = os.path.join(AGY_DIR, "conversation_summaries.db")

print("Checking sources:")
print("conv_db_src exists:", os.path.exists(conv_db_src))
print("brain_dir_src exists:", os.path.exists(brain_dir_src))
print("summaries_db_src exists:", os.path.exists(summaries_db_src))

# Checkpoint SQLite WAL so all data is in .db
try:
    con = sqlite3.connect(conv_db_src)
    con.execute("PRAGMA wal_checkpoint(TRUNCATE);")
    con.close()
    print("Checkpoint conv_db TRUNCATE done.")
except Exception as e:
    print("Checkpoint conv_db error:", e)

try:
    con_sum = sqlite3.connect(summaries_db_src)
    con_sum.execute("PRAGMA wal_checkpoint(TRUNCATE);")
    # Fetch row
    cur = con_sum.cursor()
    cur.execute("SELECT * FROM conversation_summaries WHERE conversation_id = ?", (CONV_ID,))
    summary_row = cur.fetchone()
    cols = [d[0] for d in cur.description]
    con_sum.close()
    print("Fetched summary row. Cols:", len(cols))
except Exception as e:
    print("Fetch summary error:", e)
    summary_row = None
    cols = []

# Create a staging folder
stage_dir = os.path.join(os.getcwd(), "staging_export")
if os.path.exists(stage_dir):
    shutil.rmtree(stage_dir)
os.makedirs(stage_dir, exist_ok=True)

# 1. Copy conv db
shutil.copy2(conv_db_src, os.path.join(stage_dir, f"{CONV_ID}.db"))

# 2. Save metadata JSON
meta = {
    "conversation_id": CONV_ID,
    "columns": cols,
    "row": [r if not isinstance(r, bytes) else list(r) for r in summary_row] if summary_row else []
}
with open(os.path.join(stage_dir, "metadata.json"), "w", encoding="utf-8") as f:
    json.dump(meta, f, ensure_ascii=False)

# 3. Copy brain folder
stage_brain = os.path.join(stage_dir, "brain", CONV_ID)
shutil.copytree(brain_dir_src, stage_brain)

# Zip it with deflate compression
zip_output = os.path.join(os.getcwd(), "MIGRAR_HISTORIAL_A_LAPTOP.zip")
print("Compressing to", zip_output, "...")
with zipfile.ZipFile(zip_output, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
    for root, dirs, files in os.walk(stage_dir):
        for f in files:
            full_path = os.path.join(root, f)
            rel_path = os.path.relpath(full_path, stage_dir)
            zf.write(full_path, rel_path)

shutil.rmtree(stage_dir)
size_mb = os.path.getsize(zip_output) / (1024 * 1024)
print(f"DONE! Zip size: {size_mb:.2f} MB")
