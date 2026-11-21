from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Response
from fastapi.responses import RedirectResponse
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, date
import google.generativeai as genai
import os
import io
import json
import re
import time
import base64
import httpx
from app.services.supabase_service import get_supabase_admin_client

router = APIRouter(prefix="/api/progress", tags=["Progress"])


def parse_numeric(val, default=20.0) -> float:
    """
    Convierte cualquier valor a un float seguro.
    Si recibe strings como '35-40%' o '-1.5%', calcula el promedio o extrae el número con su signo.
    """
    if isinstance(val, (int, float)):
        return float(val)
    if isinstance(val, str):
        nums = re.findall(r"[-+]?\d*\.\d+|[-+]?\d+", val)
        if len(nums) == 1:
            try:
                return float(nums[0])
            except Exception:
                pass
        elif len(nums) >= 2:
            try:
                return (float(nums[0]) + float(nums[1])) / 2.0
            except Exception:
                pass
    return float(default)


def _get_db_conn():
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        return None
    try:
        import psycopg2
        import psycopg2.extras
        return psycopg2.connect(db_url, connect_timeout=8)
    except Exception as e:
        print("Database connection error in progress:", e)
        return None


def resolve_user_context(user_id: str, admin):
    """
    Resuelve el UUID real de la tabla usuarios para evitar el error 22P02 de PostgreSQL
    en columnas de tipo UUID como progress_photos.user_id. Prioriza conexión directa a PostgreSQL.
    """
    user_info = None
    u_str = str(user_id).strip()

    # 1. Intentar primero por PostgreSQL directo
    conn = _get_db_conn()
    if conn:
        try:
            import psycopg2.extras
            with conn:
                with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                    cur.execute(
                        "SELECT * FROM usuarios WHERE id::text = %s OR cedula = %s LIMIT 1;",
                        (u_str, u_str)
                    )
                    row = cur.fetchone()
                    if row:
                        user_info = dict(row)
        except Exception as e_pg:
            print("Aviso resolviendo contexto via Postgres:", e_pg)
        finally:
            conn.close()

    # 2. Si no se encontró por Postgres, intentar con Supabase REST
    if not user_info:
        try:
            if "-" in u_str and len(u_str) >= 32:
                res = admin.table("usuarios").select("*").eq("id", u_str).execute()
                if res.data:
                    user_info = res.data[0]
            if not user_info:
                res_ced = admin.table("usuarios").select("*").eq("cedula", u_str).execute()
                if res_ced.data:
                    user_info = res_ced.data[0]
        except Exception as e_res:
            print("Aviso resolviendo contexto de usuario en Supabase:", e_res)

    u_id = str(user_info["id"]) if user_info else u_str
    u_cedula = str(user_info.get("cedula", u_str)) if user_info else u_str
    u_name = f"{user_info.get('nombre', '')} {user_info.get('apellido', '')}".strip() if user_info else "Atleta"
    u_weight = float(user_info.get("peso", 70.0) if user_info else 70.0)
    u_goal = user_info.get("objetivo", "Recomposición corporal y definición muscular") if user_info else "Recomposición corporal"
    return u_id, u_cedula, u_name, u_weight, u_goal


def _db_get_user_info(u_str: str):
    conn = _get_db_conn()
    if not conn:
        return None
    try:
        import psycopg2.extras
        with conn:
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute(
                    "SELECT * FROM usuarios WHERE id::text = %s OR cedula = %s LIMIT 1;",
                    (u_str, u_str)
                )
                row = cur.fetchone()
                return dict(row) if row else None
    except Exception as e:
        print("Error en _db_get_user_info:", e)
        return None
    finally:
        conn.close()


def _db_update_user_weight(u_id: str, weight: float):
    conn = _get_db_conn()
    if not conn:
        return
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute("UPDATE usuarios SET peso = %s WHERE id::text = %s;", (weight, u_id))
    except Exception as e:
        print("Error en _db_update_user_weight:", e)
    finally:
        conn.close()


def _db_insert_coach_message(u_id: str, u_cedula: str, role: str, category: str, content: str, plan_dict: dict):
    conn = _get_db_conn()
    if not conn:
        return
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO coach_mensajes (user_id, cedula, role, category, content, plan, created_at)
                    VALUES (%s, %s, %s, %s, %s, %s, NOW());
                    """,
                    (u_id, u_cedula, role, category, content, json.dumps(plan_dict, ensure_ascii=False))
                )
    except Exception as e:
        print("Error en _db_insert_coach_message:", e)
    finally:
        conn.close()


def _db_insert_progress_photo(u_id: str, photo_url: str, ai_analysis_json: str, photo_base64: Optional[str] = None):
    conn = _get_db_conn()
    if not conn:
        return None
    try:
        import psycopg2.extras
        with conn:
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute(
                    """
                    INSERT INTO progress_photos (user_id, photo_url, ai_analysis, photo_base64, created_at)
                    VALUES (%s, %s, %s, %s, NOW())
                    RETURNING id, user_id, photo_url, ai_analysis, photo_base64, created_at;
                    """,
                    (u_id, photo_url, ai_analysis_json, photo_base64)
                )
                row = cur.fetchone()
                if row:
                    item = dict(row)
                    row_id = str(item["id"])
                    if not photo_url or "placehold.co" in photo_url:
                        official_url = f"/api/progress/photo/{row_id}"
                        cur.execute("UPDATE progress_photos SET photo_url = %s WHERE id = %s;", (official_url, row_id))
                        item["photo_url"] = official_url
                    return item
                return None
    except Exception as e:
        print("Error en _db_insert_progress_photo:", e)
        return None
    finally:
        conn.close()


def _db_get_progress_photos(u_id: str):
    conn = _get_db_conn()
    if not conn:
        return []
    try:
        import psycopg2.extras
        with conn:
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute(
                    "SELECT id, user_id, photo_url, ai_analysis, photo_base64, created_at FROM progress_photos WHERE user_id::text = %s ORDER BY created_at ASC;",
                    (u_id,)
                )
                rows = cur.fetchall()
                result = []
                for r in rows:
                    item = dict(r)
                    row_id = str(item["id"])
                    p_url = item.get("photo_url") or ""
                    if item.get("photo_base64") and ("placehold.co" in p_url or not p_url):
                        item["photo_url"] = f"/api/progress/photo/{row_id}"
                    elif not p_url:
                        item["photo_url"] = f"/api/progress/photo/{row_id}"
                    item.pop("photo_base64", None)
                    result.append(item)
                return result
    except Exception as e:
        print("Error en _db_get_progress_photos:", e)
        return []
    finally:
        conn.close()


def _db_delete_demo_flash(u_id: str):
    conn = _get_db_conn()
    if not conn:
        return 0
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    DELETE FROM progress_photos
                    WHERE user_id::text = %s
                      AND (ai_analysis LIKE '%is_demo_flash%' OR ai_analysis LIKE '%Prueba Flash%' OR photo_url LIKE '%unsplash.com%');
                    """,
                    (u_id,)
                )
                return cur.rowcount
    except Exception as e:
        print("Error en _db_delete_demo_flash:", e)
        return 0
    finally:
        conn.close()


def _db_get_coach_metrics(u_id: str, u_cedula: str):
    conn = _get_db_conn()
    if not conn:
        return []
    try:
        import psycopg2.extras
        with conn:
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute(
                    """
                    SELECT * FROM coach_mensajes
                    WHERE category = 'body_metric'
                      AND (user_id::text = %s OR cedula = %s)
                    ORDER BY created_at ASC;
                    """,
                    (u_id, u_cedula)
                )
                rows = cur.fetchall()
                return [dict(r) for r in rows]
    except Exception as e:
        print("Error en _db_get_coach_metrics:", e)
        return []
    finally:
        conn.close()


def extract_scale_weight_from_image(img_bytes: bytes, mime_type: str = "image/jpeg", model_instance=None) -> tuple[float | None, str]:
    """
    Usa IA Vision para leer la pantalla digital o el dial de una balanza/báscula y extraer el peso numérico en kg.
    """
    if not img_bytes:
        return None, "Imagen vacía"
    prompt = """
    Actúa como un sistema OCR y de visión artificial de alta precisión médica especializado en balanzas digitales y básculas mecánicas de pesaje corporal.
    Observa detalladamente la imagen de la balanza / báscula.
    1. Localiza el display digital (LED/LCD) o la aguja indicadora que muestra el peso corporal de la persona.
    2. Extrae el número del peso.
    3. Si la unidad visible está en libras (lb o lbs), conviértela a kilogramos (kg) dividiendo entre 2.20462. Si está en kg, usa el número directamente.
    4. Devuelve ÚNICAMENTE un objeto JSON válido con este formato exacto:
    {
      "detected_weight_kg": 76.5,
      "confidence": 0.95,
      "raw_reading": "76.5 kg",
      "notes": "Lectura clara de display digital"
    }
    Si la imagen no contiene una balanza o no se distingue ningún número, devuelve:
    {
      "detected_weight_kg": null,
      "confidence": 0.0,
      "raw_reading": null,
      "notes": "No se detectó lectura numérica clara de balanza"
    }
    Devuelve SOLO JSON.
    """
    try:
        if model_instance is None:
            vision_model_name = os.environ.get("GEMINI_MODEL") or "gemini-3.1-flash-lite"
            model_instance = genai.GenerativeModel(vision_model_name)
        resp = model_instance.generate_content([
            prompt,
            {"mime_type": mime_type, "data": img_bytes}
        ])
        txt = (resp.text or "").strip()
        cleaned = txt
        if "```json" in cleaned:
            cleaned = cleaned.split("```json")[1].split("```")[0].strip()
        elif "```" in cleaned:
            cleaned = cleaned.split("```")[1].split("```")[0].strip()
        parsed = json.loads(cleaned)
        w_val = parsed.get("detected_weight_kg")
        if w_val is not None:
            w_float = parse_numeric(w_val, 0.0)
            if 25.0 <= w_float <= 300.0:
                return round(w_float, 2), parsed.get("notes", "Detectado por IA")
        return None, parsed.get("notes", "Lectura no concluyente")
    except Exception as e:
        print("Aviso extrayendo peso de balanza con IA:", e)
        return None, str(e)


@router.post("/upload")
async def upload_progress_photo(
    user_id: str = Form(...),
    file: Optional[UploadFile] = File(None),
    scale_file: Optional[UploadFile] = File(None),
    photo_type: Optional[str] = Form("body"),  # 'body', 'scale', 'both'
):
    admin = get_supabase_admin_client()
    try:
        # Resolver contexto de usuario
        u_id, u_cedula, u_name, u_weight, u_goal = resolve_user_context(user_id, admin)

        # Si no vino file pero sí scale_file, o si el tipo es 'scale'
        if file is None and scale_file is None:
            raise HTTPException(status_code=400, detail="Debe subir al menos una imagen (corporal o de balanza).")

        # Configurar IA Vision
        api_key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
        if api_key:
            genai.configure(api_key=api_key)
        vision_model_name = os.environ.get("GEMINI_MODEL") or "gemini-3.1-flash-lite"
        try:
            model = genai.GenerativeModel(vision_model_name)
        except Exception:
            model = genai.GenerativeModel("gemini-3.1-flash-lite")

        detected_weight: Optional[float] = None
        scale_notes: str = ""

        # 1. Procesar foto de Balanza / Báscula si se adjuntó
        target_scale_upload = scale_file if scale_file is not None else (file if photo_type == "scale" else None)
        if target_scale_upload is not None:
            scale_bytes = await target_scale_upload.read()
            s_mime = target_scale_upload.content_type or "image/jpeg"
            if s_mime not in ["image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"]:
                s_mime = "image/jpeg"
            detected_weight, scale_notes = extract_scale_weight_from_image(scale_bytes, s_mime, model)
            if detected_weight:
                u_weight = detected_weight
                # Actualizar peso oficial en usuarios via Postgres
                _db_update_user_weight(u_id, detected_weight)
                # Registrar métrica en coach_mensajes via Postgres
                _db_insert_coach_message(
                    u_id=u_id,
                    u_cedula=u_cedula,
                    role="system",
                    category="body_metric",
                    content=f"Balanza IA: {detected_weight} kg registrados ({scale_notes})",
                    plan_dict={
                        "weight": detected_weight,
                        "notes": f"Identificado por IA Vision en balanza: {scale_notes}",
                        "source": "scale_photo",
                        "measured_at": date.today().isoformat()
                    }
                )

        # Si el usuario SOLO subió la foto de la balanza
        if photo_type == "scale" or (file is None and scale_file is not None):
            sanitized_name = f"scale_{int(time.time())}.jpg"
            file_path = f"{u_id}/{sanitized_name}"
            public_url = ""
            scale_bytes = scale_bytes if 'scale_bytes' in locals() else await target_scale_upload.read()
            scale_b64 = base64.b64encode(scale_bytes).decode("utf-8")
            try:
                admin.storage.from_("progress").upload(file_path, scale_bytes, {"content-type": "image/jpeg"})
                public_url = admin.storage.from_("progress").get_public_url(file_path)
            except Exception as e_st:
                print("Aviso storage Supabase (scale):", e_st)
                public_url = ""

            analysis_dict = {
                "headline": f"⚖️ Peso de {detected_weight or u_weight} kg identificado y registrado exitosamente en balanza.",
                "photo_stage": "Registro en Balanza",
                "photo_number": 1,
                "detected_weight_kg": detected_weight or u_weight,
                "estimated_body_fat": 22.0,
                "muscle_definition_score": 6.0,
                "posture_score": 7.5,
                "biotype": "Evaluación por Báscula Digital",
                "scale_notes": scale_notes or "Lectura registrada",
                "positive_changes": [f"Peso corporal actualizado a {detected_weight or u_weight} kg", "Historial biométrico sincronizado"],
                "areas_to_improve": ["Monitorear el pesaje en ayunas para consistencia", "Acompañar con foto de postura corporal"],
                "physiological_composition": f"Registro de peso corporal oficial capturado por IA: {detected_weight or u_weight} kg.",
                "training_plan_feedback": "El Coach IA ajustará la intensidad según tu nuevo registro de peso.",
                "motivational_quote": "Cada pesaje consciente te acerca a tu meta.",
            }

            inserted_rec = _db_insert_progress_photo(
                u_id=u_id,
                photo_url=public_url,
                ai_analysis_json=json.dumps(analysis_dict, ensure_ascii=False),
                photo_base64=scale_b64
            )
            if inserted_rec and not public_url:
                public_url = inserted_rec.get("photo_url") or f"/api/progress/photo/{inserted_rec.get('id')}"

            return {
                "status": "ok",
                "detected_weight_kg": detected_weight or u_weight,
                "weight_updated": bool(detected_weight),
                "analysis": analysis_dict["headline"],
                "structured_analysis": analysis_dict,
                "photo_url": public_url
            }

        # 2. Si hay foto corporal, procesar con Cineantropometría
        file_bytes = await file.read()
        mime = file.content_type or "image/jpeg"
        if mime not in ["image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"]:
            mime = "image/jpeg"

        # Historial de fotos para contextualizar via Postgres
        prev_photos = _db_get_progress_photos(u_id)
        photo_number = len(prev_photos) + 1

        is_first = photo_number == 1
        prev_analysis = None
        prev_fat = 26.0
        prev_def = 4.0
        prev_posture = 7.0
        prev_date = ""
        prev_img_bytes = None

        if not is_first and prev_photos:
            last_record = prev_photos[-1]
            prev_date = str(last_record.get("created_at") or "")[:10]
            raw_p = last_record.get("ai_analysis") or ""
            if raw_p.startswith("{"):
                try:
                    prev_analysis = json.loads(raw_p)
                    prev_fat = parse_numeric(prev_analysis.get("estimated_body_fat"), 26.0)
                    prev_def = parse_numeric(prev_analysis.get("muscle_definition_score"), 4.0)
                    prev_posture = parse_numeric(prev_analysis.get("posture_score"), 7.0)
                except Exception:
                    pass

            prev_url = last_record.get("photo_url")
            if prev_url and prev_url.startswith("http"):
                try:
                    r_prev = httpx.get(prev_url, timeout=12.0)
                    if r_prev.status_code == 200:
                        prev_img_bytes = r_prev.content
                except Exception as e_dl:
                    print("Aviso descargando foto previa para comparativa:", e_dl)

        content_parts = []
        if prev_img_bytes:
            content_parts.append({"mime_type": "image/jpeg", "data": prev_img_bytes})
        content_parts.append({"mime_type": mime, "data": file_bytes})

        if is_first:
            stage_desc = (
                "FOTO #1: FOTO INICIAL / BASELINE (DÍA 1). "
                "El usuario está iniciando hoy su plan de entrenamiento de 30 días. "
                "Establece su estado inicial de compostura fisiológica, grasa corporal estimada, postura y base anatómica."
            )
            compare_instructions = ""
            default_stage = "Foto Inicial (Día 1)"
        else:
            default_stage = (
                f"Evaluación Quincenal (Foto #{photo_number})" if photo_number == 2
                else (f"Evaluación Mensual (Foto #{photo_number})" if photo_number == 3
                else f"Jornada de Progreso (Foto #{photo_number})")
            )
            stage_desc = (
                f"FOTO #{photo_number}: JORNADA DE EVALUACIÓN COMPARATIVA ({default_stage}). "
                f"El usuario viene completando sus rutinas y planes de entrenamiento. "
                f"Registro anterior ({prev_date}): {prev_fat}% grasa estimada, {prev_def}/10 definición muscular, {prev_posture}/10 postura."
            )
            if prev_img_bytes:
                compare_instructions = (
                    "¡IMPORTANTE: SE ADJUNTAN DOS FOTOGRAFÍAS REALES DEL MISMO ATLETA! "
                    f"- FOTO 1 (Adjunta primero): Fotografía anterior tomada el {prev_date}. "
                    f"- FOTO 2 (Adjunta segundo): Fotografía actual tomada hoy. "
                    "Compara rigurosamente y con la máxima precisión clínica milímetro a milímetro: "
                    "1. Diferencia real de adiposidad en abdomen medio, pliegue periumbilical y pectorales. "
                    "2. Incremento o mantenimiento en firmeza, tono y vascularización en brazos, hombros y torso. "
                    "3. Cambios en la postura y alineación de hombros/cintura escapular. "
                    "4. Calcula y reporta los deltas reales exactos en comparison_with_previous."
                )
            else:
                compare_instructions = (
                    f"Compara este nuevo registro con el registro anterior del {prev_date} ({prev_fat}% grasa, {prev_def}/10 definición) "
                    "y reporta los cambios observados."
                )

        comparison_example = ""
        if not is_first:
            comparison_example = f'''"comparison_with_previous": {{
                "previous_date": "{prev_date}",
                "body_fat_delta": -1.5,
                "muscle_definition_delta": 0.8,
                "posture_delta": 0.3,
                "clinical_comparison": "Explicación clínica detallada y contrastada de los cambios anatómicos reales respecto a la foto previa...",
                "specific_anatomical_changes": [
                    "Reducción visible en el pliegue periumbilical inferior",
                    "Mayor firmeza en la base de los pectorales"
                ]
            }},'''

        scale_context_str = f" [Peso en Balanza Oficial: {u_weight} kg ({scale_notes})]" if detected_weight else f" [Peso registrado: {u_weight} kg]"

        prompt = f"""
        Actúa como un Especialista en Cineantropometría, Biomecánica y Recomposición Corporal.
        Estás evaluando la fotografía de progreso físico de {u_name} (Peso actual: {u_weight} kg, Objetivo: {u_goal}){scale_context_str}.
        Contexto del momento: {stage_desc}.
        {compare_instructions}

        Analiza rigurosa y visualmente la imagen:
        1. Estima el % de grasa corporal visible aproximado (como número decimal).
        2. Califica de 1.0 a 10.0 el Tono y Definición Muscular.
        3. Califica de 1.0 a 10.0 la Alineación Postural y Simetría.
        4. Identifica cambios positivos y fortalezas visibles.
        5. Identifica puntos a mejorar o zonas a enfatizar en sus entrenamientos para el próximo ciclo.
        6. Brinda una explicación detallada de su compostura fisiológica y biotipo.
        7. Proporciona una recomendación para sus rutinas actuales.

        Devuelve ÚNICAMENTE un JSON válido con esta estructura:
        {{
            "headline": "Frase resumen de impacto clínico y motivacional",
            "photo_stage": "{default_stage}",
            "photo_number": {photo_number},
            "detected_weight_kg": {u_weight},
            "estimated_body_fat": 24.0,
            "muscle_definition_score": 5.5,
            "posture_score": 7.5,
            "biotype": "Endomorfo con base mesomórfica",
            {comparison_example}
            "positive_changes": [
                "Estructura ósea sólida y clavículas niveladas",
                "Buena base de soporte para iniciar sobrecarga progresiva"
            ],
            "areas_to_improve": [
                "Priorizar déficit calórico moderado para reducir tejido adiposo periumbilical",
                "Enfocar hipertrofia en tren superior (deltoides y dorsales)"
            ],
            "physiological_composition": "Análisis clínico y visual detallado de la compostura física...",
            "training_plan_feedback": "Ajuste específico para sus rutinas de entrenamiento asignadas...",
            "motivational_quote": "Mensaje inspirador para mantener la constancia en este mes de entrenamiento."
        }}
        """

        structured_analysis = None
        analysis_raw = ""
        try:
            response = model.generate_content([prompt] + content_parts)
            resp_text = (response.text or "").strip()
            cleaned = resp_text
            if "```json" in cleaned:
                cleaned = cleaned.split("```json")[1].split("```")[0].strip()
            elif "```" in cleaned:
                cleaned = cleaned.split("```")[1].split("```")[0].strip()

            parsed = json.loads(cleaned)
            if isinstance(parsed, dict):
                parsed["detected_weight_kg"] = round(float(u_weight), 2)
                parsed["estimated_body_fat"] = parse_numeric(parsed.get("estimated_body_fat"), 22.0)
                parsed["muscle_definition_score"] = min(10.0, max(1.0, parse_numeric(parsed.get("muscle_definition_score"), 6.0)))
                parsed["posture_score"] = min(10.0, max(1.0, parse_numeric(parsed.get("posture_score"), 7.5)))

                if parsed.get("comparison_with_previous") and isinstance(parsed["comparison_with_previous"], dict):
                    comp = parsed["comparison_with_previous"]
                    comp["body_fat_delta"] = round(parse_numeric(comp.get("body_fat_delta"), parsed["estimated_body_fat"] - prev_fat), 1)
                    comp["muscle_definition_delta"] = round(parse_numeric(comp.get("muscle_definition_delta"), parsed["muscle_definition_score"] - prev_def), 1)
                    comp["posture_delta"] = round(parse_numeric(comp.get("posture_delta"), parsed["posture_score"] - prev_posture), 1)
                    if not isinstance(comp.get("specific_anatomical_changes"), list):
                        comp["specific_anatomical_changes"] = [str(comp.get("specific_anatomical_changes") or "Evolución anatómica positiva")]

                if isinstance(parsed.get("positive_changes"), str):
                    parsed["positive_changes"] = [parsed["positive_changes"]]
                elif not isinstance(parsed.get("positive_changes"), list):
                    parsed["positive_changes"] = ["Alineación anatómica adecuada", "Buena base de soporte muscular"]

                if isinstance(parsed.get("areas_to_improve"), str):
                    parsed["areas_to_improve"] = [parsed["areas_to_improve"]]
                elif not isinstance(parsed.get("areas_to_improve"), list):
                    parsed["areas_to_improve"] = ["Mantener adherencia y sobrecarga progresiva controlada"]

                structured_analysis = parsed
                analysis_raw = json.dumps(parsed, ensure_ascii=False)
        except Exception as e_ai:
            print("Warning AI Vision JSON parsing, creating fallback:", e_ai)

        if not structured_analysis:
            cur_fat = 24.5 if not is_first else 26.0
            cur_def = 4.2 if not is_first else 3.5
            structured_analysis = {
                "headline": f"Jornada #{photo_number}: Progreso y Recomposición Corporal Activa",
                "photo_stage": default_stage,
                "photo_number": photo_number,
                "detected_weight_kg": round(float(u_weight), 2),
                "estimated_body_fat": cur_fat,
                "muscle_definition_score": cur_def,
                "posture_score": 7.0,
                "biotype": "Endomorfo con base mesomórfica",
                "positive_changes": [
                    "Alineación simétrica de columna y postura frontal",
                    "Excelente predisposición para recomposición corporal con los planes del Coach"
                ],
                "areas_to_improve": [
                    "Mantener tempo controlado en cada repetición",
                    "Controlar ingesta calórica para reducir grasa abdominal"
                ],
                "physiological_composition": f"Compostura física en progreso activo con peso registrado de {u_weight} kg.",
                "training_plan_feedback": "Ejecuta los planes asignados respetando los descansos y la técnica recomendada.",
                "motivational_quote": "Cada jornada suma hacia la mejor versión de tu físico."
            }
            if not is_first:
                structured_analysis["comparison_with_previous"] = {
                    "previous_date": prev_date,
                    "body_fat_delta": round(cur_fat - prev_fat, 1),
                    "muscle_definition_delta": round(cur_def - prev_def, 1),
                    "posture_delta": 0.0,
                    "clinical_comparison": f"Al comparar con la foto del {prev_date}, se observa progresión en la adaptación muscular y recomposición.",
                    "specific_anatomical_changes": [
                        "Avance consistente en la firmeza del tronco",
                        "Mayor control postural durante la toma fotográfica"
                    ]
                }
            analysis_raw = json.dumps(structured_analysis, ensure_ascii=False)

        # Guardar foto en Base64 de forma infalible en PostgreSQL
        b64_photo = base64.b64encode(file_bytes).decode("utf-8")

        # Intentar respaldo en Supabase Storage
        sanitized_filename = f"{int(time.time())}_{file.filename or 'photo.jpg'}"
        file_path = f"{u_id}/{sanitized_filename}"
        public_url = ""
        try:
            admin.storage.from_("progress").upload(file_path, file_bytes, {"content-type": mime})
            public_url = admin.storage.from_("progress").get_public_url(file_path)
        except Exception as storage_err:
            print("Aviso storage Supabase (usando PostgreSQL storage):", storage_err)
            public_url = ""

        # Guardar en Base de Datos via Postgres con photo_base64
        inserted_rec = _db_insert_progress_photo(u_id, public_url, analysis_raw, photo_base64=b64_photo)
        if inserted_rec and not public_url:
            public_url = inserted_rec.get("photo_url") or f"/api/progress/photo/{inserted_rec.get('id')}"

        # Sincronizar automáticamente en coach_mensajes via Postgres
        try:
            est_fat = structured_analysis.get("estimated_body_fat")
            if est_fat:
                _db_insert_coach_message(
                    u_id=u_id,
                    u_cedula=u_cedula,
                    role="system",
                    category="body_metric",
                    content=f"Estimación IA Vision: {u_weight} kg | {est_fat}% grasa corporal",
                    plan_dict={
                        "weight": u_weight,
                        "body_fat": est_fat,
                        "notes": f"Estimado por IA Vision ({structured_analysis.get('photo_stage')})",
                        "measured_at": date.today().isoformat()
                    }
                )
        except Exception as e_sync:
            print("Aviso sincronizando métricas con coach_mensajes:", e_sync)

        return {
            "status": "ok",
            "detected_weight_kg": detected_weight,
            "weight_updated": bool(detected_weight),
            "analysis": structured_analysis.get("headline", "Análisis completado"),
            "structured_analysis": structured_analysis,
            "photo_url": public_url
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/photo/{photo_id}")
async def get_progress_photo(photo_id: str):
    conn = _get_db_conn()
    if not conn:
        raise HTTPException(status_code=500, detail="Error conectando a la base de datos")
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT photo_base64, photo_url FROM progress_photos WHERE id::text = %s LIMIT 1;", (photo_id,))
            row = cur.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="Fotografía no encontrada")
            b64_data, p_url = row[0], row[1]
            if b64_data:
                if "," in b64_data:
                    b64_data = b64_data.split(",", 1)[1]
                raw_bytes = base64.b64decode(b64_data)
                media_type = "image/jpeg"
                if raw_bytes.startswith(b"\x89PNG"):
                    media_type = "image/png"
                elif raw_bytes.startswith(b"RIFF") and b"WEBP" in raw_bytes[:16]:
                    media_type = "image/webp"
                return Response(
                    content=raw_bytes,
                    media_type=media_type,
                    headers={
                        "Cache-Control": "public, max-age=86400",
                        "Content-Type": media_type
                    }
                )
            elif p_url and p_url.startswith("http") and "placehold.co" not in p_url:
                return RedirectResponse(url=p_url)
            raise HTTPException(status_code=404, detail="No hay imagen disponible para esta evaluación")
    finally:
        conn.close()


@router.get("/{user_id}")
def get_progress_photos(user_id: str):
    admin = get_supabase_admin_client()
    try:
        u_id, u_cedula, u_name, u_weight, u_goal = resolve_user_context(user_id, admin)

        photos = _db_get_progress_photos(u_id)

        processed_photos = []
        evolution_chart = []

        for idx, p in enumerate(photos, 1):
            raw_analysis = p.get("ai_analysis") or ""
            parsed_dict = None
            if raw_analysis.startswith("{"):
                try:
                    parsed_dict = json.loads(raw_analysis)
                except Exception:
                    pass

            if not parsed_dict:
                parsed_dict = {
                    "headline": raw_analysis[:120] if raw_analysis else "Evaluación de condición física",
                    "photo_stage": f"Foto #{idx}" if idx > 1 else "Foto Inicial (Día 1)",
                    "photo_number": idx,
                    "estimated_body_fat": 25.0 - (idx - 1) * 0.8,
                    "muscle_definition_score": 4.5 + (idx - 1) * 0.5,
                    "posture_score": 7.0 + (idx - 1) * 0.2,
                    "biotype": "Endomorfo con base mesomórfica",
                    "positive_changes": [
                        "Alineación simétrica y postura adecuada",
                        "Respuesta positiva al plan de entrenamiento"
                    ],
                    "areas_to_improve": [
                        "Continuar con la sobrecarga progresiva en los ejercicios compuestos",
                        "Enfocar la porción media del abdomen y descanso nocturno"
                    ],
                    "physiological_composition": raw_analysis or "Compostura física en progreso activo.",
                    "training_plan_feedback": "Ajuste continuo a las rutinas asignadas en la app.",
                    "motivational_quote": "La constancia en cada sesión marca la diferencia semana a semana."
                }
            else:
                # Asegurar tipos flotantes
                parsed_dict["estimated_body_fat"] = parse_numeric(parsed_dict.get("estimated_body_fat"), 22.0)
                parsed_dict["muscle_definition_score"] = min(10.0, max(1.0, parse_numeric(parsed_dict.get("muscle_definition_score"), 6.0)))
                parsed_dict["posture_score"] = min(10.0, max(1.0, parse_numeric(parsed_dict.get("posture_score"), 7.5)))

            p["structured_analysis"] = parsed_dict
            processed_photos.append(p)

            date_str = str(p.get("created_at", ""))[:10]
            w_val = parsed_dict.get("detected_weight_kg") or parsed_dict.get("weight") or u_weight
            evolution_chart.append({
                "date": date_str,
                "photo_number": idx,
                "body_fat": parsed_dict.get("estimated_body_fat", 22.0),
                "definition_score": parsed_dict.get("muscle_definition_score", 6.0),
                "posture_score": parsed_dict.get("posture_score", 7.5),
                "weight": round(float(w_val), 1),
            })

        # Resumen comparativo global si hay 2 o más fotos
        comparative_summary = None
        if len(processed_photos) >= 2:
            baseline = processed_photos[0]  # La primera (antigua)
            latest = processed_photos[-1]    # La más reciente
            base_ana = baseline.get("structured_analysis") or {}
            latest_ana = latest.get("structured_analysis") or {}

            base_fat = base_ana.get("estimated_body_fat", 26.0)
            cur_fat = latest_ana.get("estimated_body_fat", 24.0)

            base_def = base_ana.get("muscle_definition_score", 3.5)
            cur_def = latest_ana.get("muscle_definition_score", 4.5)

            base_posture = base_ana.get("posture_score", 6.5)
            cur_posture = latest_ana.get("posture_score", 7.0)

            base_w = base_ana.get("detected_weight_kg") or base_ana.get("weight") or u_weight
            cur_w = latest_ana.get("detected_weight_kg") or latest_ana.get("weight") or u_weight

            comparative_summary = {
                "has_comparison": True,
                "baseline_date": str(baseline.get("created_at") or "")[:10],
                "latest_date": str(latest.get("created_at") or "")[:10],
                "baseline_fat": base_fat,
                "latest_fat": cur_fat,
                "fat_delta": round(cur_fat - base_fat, 1),
                "baseline_definition": base_def,
                "latest_definition": cur_def,
                "definition_delta": round(cur_def - base_def, 1),
                "baseline_posture": base_posture,
                "latest_posture": cur_posture,
                "posture_delta": round(cur_posture - base_posture, 1),
                "baseline_weight": round(float(base_w), 1),
                "latest_weight": round(float(cur_w), 1),
                "weight_delta": round(float(cur_w) - float(base_w), 1),
                "clinical_notes": (latest_ana.get("comparison_with_previous") or {}).get("clinical_comparison", "")
            }

        # Mostrar la más reciente primero en la lista de fotos
        processed_photos.reverse()

        return {
            "photos": processed_photos,
            "evolution_chart": evolution_chart,
            "comparative_summary": comparative_summary,
            "total_photos": len(processed_photos),
            "has_photos": len(processed_photos) > 0
        }
    except Exception as e:
        print("Error obteniendo fotos de progreso:", e)
        return {
            "photos": [],
            "evolution_chart": [],
            "comparative_summary": None,
            "total_photos": 0,
            "has_photos": False,
            "error": str(e)
        }


@router.post("/demo-flash/{user_id}")
def generate_demo_flash_progress(user_id: str):
    """
    Genera una prueba flash simulando la evaluación de progreso tras 1 mes (Día 30)
    de entrenamiento, vinculando la comparativa real con la foto inicial del usuario.
    """
    admin = get_supabase_admin_client()
    u_id, u_cedula, u_name, u_weight, u_goal = resolve_user_context(user_id, admin)
    if "-" not in str(u_id) or len(str(u_id)) < 32:
        raise HTTPException(status_code=404, detail="Usuario no encontrado. Inicie sesión para generar la prueba.")

    prev_photos = _db_get_progress_photos(u_id)

    base_fat = 26.0
    base_def = 3.5
    base_posture = 6.5
    base_date = date.today().isoformat()

    if prev_photos:
        first_rec = prev_photos[0]
        base_date = str(first_rec.get("created_at") or "")[:10]
        raw_first = first_rec.get("ai_analysis") or ""
        if raw_first.startswith("{"):
            try:
                p_first = json.loads(raw_first)
                base_fat = parse_numeric(p_first.get("estimated_body_fat"), 26.0)
                base_def = parse_numeric(p_first.get("muscle_definition_score"), 3.5)
                base_posture = parse_numeric(p_first.get("posture_score"), 6.5)
            except Exception:
                pass

    # Calcular métricas realistas tras 1 mes de entrenamiento
    cur_fat = round(max(10.0, base_fat - 2.8), 1)
    cur_def = round(min(10.0, base_def + 1.7), 1)
    cur_posture = round(min(10.0, base_posture + 1.3), 1)
    fat_delta = round(cur_fat - base_fat, 1)
    def_delta = round(cur_def - base_def, 1)
    posture_delta = round(cur_posture - base_posture, 1)

    photo_number = len(prev_photos) + 1
    demo_url = "https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?q=80&w=800&auto=format&fit=crop"

    demo_analysis = {
        "headline": f"Evaluación Mes 1: Notable reducción de {abs(fat_delta)}% de grasa periumbilical y aumento visible en tono muscular",
        "photo_stage": "Evaluación Mes 1 (Día 30 · Prueba Flash)",
        "photo_number": photo_number,
        "is_demo_flash": True,
        "estimated_body_fat": cur_fat,
        "muscle_definition_score": cur_def,
        "posture_score": cur_posture,
        "biotype": "Mesomorfo atlético en recomposición activa",
        "comparison_with_previous": {
            "previous_date": base_date,
            "body_fat_delta": fat_delta,
            "muscle_definition_delta": def_delta,
            "posture_delta": posture_delta,
            "clinical_comparison": f"Tras 30 días continuos con el plan de fuerza y cardio, {u_name} muestra una evolución evidente. La convexidad periumbilical se contrajo significativamente, el contorno de la cintura disminuyó y la musculatura pectoral y deltoidea superior presenta mayor firmeza, relieve y vascularización incipiente.",
            "specific_anatomical_changes": [
                f"Reducción de {abs(fat_delta)}% en grasa periumbilical y flancos lumbares",
                f"Aumento de +{def_delta} puntos en definición y separación pectoral",
                "Mayor tono y corte lateral en deltoides y tríceps",
                f"Alineación escapular corregida (+{posture_delta} pts en postura)"
            ]
        },
        "positive_changes": [
            "Excelente respuesta metabólica al déficit calórico y sobrecarga",
            "Cintura visiblemente más compacta y definida",
            "Aumento en densidad muscular sin pérdida de masa magra"
        ],
        "areas_to_improve": [
            "Iniciar fase de sobrecarga progresiva en sentadillas y press inclinado",
            "Mantener la ingesta proteica y 3 sesiones semanales de cardio moderado"
        ],
        "physiological_composition": f"{u_name} ha culminado su primer mes con éxito rotundo. La recomposición corporal es palpable: el porcentaje graso descendió de {base_fat}% a {cur_fat}%, mientras que el tono muscular saltó de {base_def} a {cur_def}/10. Su base mesomórfica responde con rapidez.",
        "training_plan_feedback": "Avanzar a microciclo de hipertrofia con rangos de 8-12 repeticiones efectivas y descansos de 90 segundos.",
        "motivational_quote": "¡30 días de disciplina transformaron tu cuerpo! Este es solo el primer escalón de tu mejor versión."
    }

    inserted_record = _db_insert_progress_photo(
        u_id=u_id,
        photo_url=demo_url,
        ai_analysis_json=json.dumps(demo_analysis, ensure_ascii=False)
    )

    return {
        "status": "ok",
        "message": "Prueba flash de Mes 1 generada con éxito.",
        "analysis": demo_analysis,
        "record": inserted_record
    }


@router.delete("/demo-flash/{user_id}")
def clear_demo_flash(user_id: str):
    """
    Elimina las fotos generadas como prueba flash para dejar limpio el historial real.
    """
    admin = get_supabase_admin_client()
    u_id, _, _, _, _ = resolve_user_context(user_id, admin)
    if "-" not in str(u_id) or len(str(u_id)) < 32:
        return {"status": "ok", "deleted_count": 0}

    deleted_count = _db_delete_demo_flash(u_id)

    return {"status": "ok", "deleted_count": deleted_count}


class BodyMetricReq(BaseModel):
    user_id: str  # Cédula o UUID del usuario
    weight: float
    body_fat: Optional[float] = None
    muscle_mass: Optional[float] = None
    chest: Optional[float] = None
    waist: Optional[float] = None
    neck: Optional[float] = None
    hip: Optional[float] = None
    height: Optional[float] = None
    arm: Optional[float] = None
    thigh: Optional[float] = None
    notes: Optional[str] = None
    measured_at: Optional[str] = None  # YYYY-MM-DD


@router.post("/metrics")
def record_body_metric(req: BodyMetricReq):
    """
    Registra una nueva medición corporal (peso, % grasa, perímetros en cm)
    y actualiza el peso oficial del perfil del alumno.
    """
    admin = get_supabase_admin_client()
    measured_date = req.measured_at or date.today().isoformat()
    
    # Resolver usuario por cédula o id
    u_id, u_cedula, _, _, _ = resolve_user_context(req.user_id, admin)

    # 1. Actualizar peso en tabla usuarios via Postgres
    if req.weight > 0:
        _db_update_user_weight(u_id, req.weight)

    # 2. Persistir en coach_mensajes como registro métrico estructurado via Postgres
    metric_record = {
        "weight": round(float(req.weight), 2),
        "body_fat": round(float(req.body_fat), 1) if req.body_fat is not None else None,
        "muscle_mass": round(float(req.muscle_mass), 1) if req.muscle_mass is not None else None,
        "chest": round(float(req.chest), 1) if req.chest is not None else None,
        "waist": round(float(req.waist), 1) if req.waist is not None else None,
        "neck": round(float(req.neck), 1) if req.neck is not None else None,
        "hip": round(float(req.hip), 1) if req.hip is not None else None,
        "height": round(float(req.height), 1) if req.height is not None else None,
        "arm": round(float(req.arm), 1) if req.arm is not None else None,
        "thigh": round(float(req.thigh), 1) if req.thigh is not None else None,
        "notes": req.notes or "",
        "measured_at": measured_date,
    }

    _db_insert_coach_message(
        u_id=u_id,
        u_cedula=u_cedula,
        role="system",
        category="body_metric",
        content=f"Registro Métrico: {req.weight} kg" + (f" | {req.body_fat}% grasa" if req.body_fat else ""),
        plan_dict=metric_record,
    )

    return {
        "status": "ok",
        "message": "Medición corporal registrada con éxito.",
        "metric": metric_record
    }


@router.get("/metrics/{user_id}")
def get_body_metrics(user_id: str):
    """
    Obtiene el historial cronológico de mediciones corporales y el cálculo de evolución (deltas).
    """
    admin = get_supabase_admin_client()
    try:
        u_id, u_cedula, _, _, _ = resolve_user_context(user_id, admin)
        raw_list = _db_get_coach_metrics(u_id, u_cedula)

        metrics = []
        for r in raw_list:
            p = r.get("plan")
            if isinstance(p, dict):
                m_date = p.get("measured_at") or str(r.get("created_at", ""))[:10]
                p["measured_at"] = m_date
                metrics.append(p)
            elif r.get("content"):
                metrics.append({
                    "measured_at": str(r.get("created_at", ""))[:10],
                    "weight": 70.0,
                    "notes": r.get("content")
                })

        # Si no hay mediciones, buscar el peso inicial en usuarios via Postgres
        if not metrics:
            u_info = _db_get_user_info(u_id)
            if u_info:
                init_w = float(u_info.get("peso") or 70.0)
                init_d = str(u_info.get("created_at") or date.today().isoformat())[:10]
                metrics.append({
                    "weight": init_w,
                    "body_fat": 18.0,
                    "waist": 82.0,
                    "chest": 98.0,
                    "arm": 33.0,
                    "thigh": 55.0,
                    "notes": "Peso inicial de registro en plataforma",
                    "measured_at": init_d
                })

        # Calcular evolución y deltas
        summary = {
            "total_measurements": len(metrics),
            "initial_weight": metrics[0]["weight"] if metrics else 70.0,
            "current_weight": metrics[-1]["weight"] if metrics else 70.0,
            "weight_delta": round((metrics[-1]["weight"] - metrics[0]["weight"]), 2) if metrics else 0.0,
            "initial_body_fat": metrics[0].get("body_fat") if metrics else None,
            "current_body_fat": metrics[-1].get("body_fat") if metrics else None,
            "body_fat_delta": round(metrics[-1]["body_fat"] - metrics[0]["body_fat"], 1) if metrics and metrics[0].get("body_fat") and metrics[-1].get("body_fat") else None,
            "latest_date": metrics[-1]["measured_at"] if metrics else date.today().isoformat()
        }

        return {
            "status": "ok",
            "metrics": metrics,
            "summary": summary
        }
    except Exception as e:
        return {
            "status": "error",
            "metrics": [],
            "summary": {},
            "error": str(e)
        }
