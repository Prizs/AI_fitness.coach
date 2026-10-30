import os
import sys
import sqlite3
import shutil
import zipfile
import json
import urllib.parse

def main():
    print("===============================================================================")
    print("      IMPORTADOR AUTOMATICO DE HISTORIAL DE ANTIGRAVITY (AGY) PARA LAPTOP      ")
    print("===============================================================================\n")

    current_dir = os.path.dirname(os.path.abspath(__file__))
    zip_path = os.path.join(current_dir, "MIGRAR_HISTORIAL_A_LAPTOP.zip")

    if not os.path.exists(zip_path):
        print(f"[ERROR] No se encontro el archivo '{zip_path}'.")
        print("Asegurate de haber copiado MIGRAR_HISTORIAL_A_LAPTOP.zip a esta carpeta.")
        return 1

    user_profile = os.environ.get("USERPROFILE")
    if os.path.exists(r"C:\Users\USUARIO"):
        user_profile = r"C:\Users\USUARIO"
    elif not user_profile:
        user_profile = r"C:\Users\USUARIO"

    agy_dir = os.path.join(user_profile, ".gemini", "antigravity")
    if not os.path.exists(agy_dir):
        print(f"[AVISO] Creando directorio Antigravity en: {agy_dir}")
        os.makedirs(agy_dir, exist_ok=True)

    conversations_dir = os.path.join(agy_dir, "conversations")
    brain_dir = os.path.join(agy_dir, "brain")
    os.makedirs(conversations_dir, exist_ok=True)
    os.makedirs(brain_dir, exist_ok=True)

    temp_extract = os.path.join(current_dir, "_temp_import_history")
    if os.path.exists(temp_extract):
        shutil.rmtree(temp_extract)
    os.makedirs(temp_extract, exist_ok=True)

    print("[1/4] Descomprimiendo historial...")
    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(temp_extract)

    with open(os.path.join(temp_extract, "metadata.json"), "r", encoding="utf-8") as f:
        meta = json.load(f)

    conv_id = meta["conversation_id"]
    cols = meta["columns"]
    row_data = meta["row"]

    print(f"[2/4] Copiando base de datos de conversacion ({conv_id}.db)...")
    src_db = os.path.join(temp_extract, f"{conv_id}.db")
    dest_db = os.path.join(conversations_dir, f"{conv_id}.db")
    shutil.copy2(src_db, dest_db)

    print(f"[3/4] Copiando artefactos y memoria cerebral (brain/{conv_id})...")
    src_brain = os.path.join(temp_extract, "brain", conv_id)
    dest_brain = os.path.join(brain_dir, conv_id)
    os.makedirs(dest_brain, exist_ok=True)
    shutil.copytree(src_brain, dest_brain, dirs_exist_ok=True)

    print("[4/4] Registrando conversacion en el indice de Antigravity (conversation_summaries.db)...")
    summaries_db_path = os.path.join(agy_dir, "conversation_summaries.db")
    
    # Adapt workspace URI to laptop current path
    laptop_ws_uri = "file:///" + urllib.parse.quote(current_dir.replace("\\", "/"))
    
    con = sqlite3.connect(summaries_db_path)
    cur = con.cursor()

    # Reconstruct row with bytes if needed
    final_values = []
    for c, val in zip(cols, row_data):
        if c == "workspace_uris":
            final_values.append(json.dumps([laptop_ws_uri]))
        elif isinstance(val, list) and all(isinstance(x, int) for x in val):
            final_values.append(bytes(val))
        else:
            final_values.append(val)

    # Check if table exists
    cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='conversation_summaries'")
    if cur.fetchone():
        placeholders = ", ".join(["?"] * len(cols))
        col_names = ", ".join(cols)
        cur.execute("DELETE FROM conversation_summaries WHERE conversation_id = ?", (conv_id,))
        cur.execute(f"INSERT INTO conversation_summaries ({col_names}) VALUES ({placeholders})", final_values)
        con.commit()
        print("  -> Registrado exitosamente en conversation_summaries.")
    else:
        print("  -> Antigravity creara la tabla automaticamente al abrirse.")

    con.close()

    shutil.rmtree(temp_extract)
    print("\n===============================================================================")
    print("  [EXITO] HISTORIAL MIGRADO AL 100% CON EXITO!")
    print("===============================================================================")
    print("Pasos finales:")
    print("1. Abre o reinicia Antigravity en tu laptop.")
    print("2. En la barra lateral izquierda veras la conversacion:")
    print("   'Resumen De Stack Tecnologico E IA'")
    print("3. Haz clic en ella y tendras el historial COMPLETO, todas las imagenes,")
    print("   mensajes, correcciones y archivos tal como los tenias en la PC principal.")
    print("===============================================================================\n")
    return 0

if __name__ == "__main__":
    sys.exit(main())
