from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from app.services.supabase_service import get_supabase_admin_client
import google.generativeai as genai
import os
import io

router = APIRouter(prefix="/api/progress", tags=["Progress"])

@router.post("/upload")
async def upload_progress_photo(user_id: str = Form(...), file: UploadFile = File(...)):
    admin = get_supabase_admin_client()
    try:
        file_bytes = await file.read()
        
        # 1. Analyze with Gemini Vision
        genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))
        vision_model_name = os.environ.get("GEMINI_MODEL") or "gemini-2.5-flash"
        try:
            model = genai.GenerativeModel(vision_model_name)
        except Exception:
            model = genai.GenerativeModel("gemini-2.5-flash")

        prompt = (
            "Actúa como un entrenador personal y experto en biomecánica y recomposición corporal. "
            "Analiza con atención esta fotografía de progreso físico del cliente. Responde en español con tono muy motivador, científico y positivo:\n"
            "1) **Puntos Fuertes Visibles**: Describe la postura, simetría o tono muscular observado.\n"
            "2) **Áreas de Oportunidad**: Pautas para hipertrofia, postura o definición recomendadas.\n"
            "3) **Plan de Acción Rápido**: Consejo práctico para su siguiente entrenamiento.\n"
            "4) **Mensaje de Ánimo**: Frase motivadora para mantener la disciplina y constancia."
        )

        image_parts = [
            {
                "mime_type": file.content_type or "image/jpeg",
                "data": file_bytes,
            }
        ]

        response = model.generate_content([prompt, image_parts[0]])
        analysis_text = response.text or "Análisis completado. Mantén la consistencia y la técnica estricta en cada repetición."

        # 2. Upload to Supabase Storage (bucket 'progress')
        import time
        sanitized_filename = f"{int(time.time())}_{file.filename or 'photo.jpg'}"
        file_path = f"{user_id}/{sanitized_filename}"
        public_url = ""
        try:
            admin.storage.from_("progress").upload(file_path, file_bytes, {"content-type": file.content_type or "image/jpeg"})
            public_url = admin.storage.from_("progress").get_public_url(file_path)
        except Exception as storage_err:
            print("Aviso storage Supabase:", storage_err)
            public_url = f"https://placehold.co/600x400/1E293B/1FAE87.png?text=Foto+Progreso+{int(time.time())}"

        # 3. Save to DB
        db_res = admin.table("progress_photos").insert({
            "user_id": user_id,
            "photo_url": public_url,
            "ai_analysis": analysis_text
        }).execute()

        return {"status": "ok", "analysis": analysis_text, "photo_url": public_url}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{user_id}")
def get_progress_photos(user_id: str):
    admin = get_supabase_admin_client()
    res = admin.table("progress_photos").select("*").eq("user_id", user_id).order("created_at", desc=True).execute()
    return res.data


from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, date


class BodyMetricReq(BaseModel):
    user_id: str  # Cédula o UUID del usuario
    weight: float
    body_fat: Optional[float] = None
    chest: Optional[float] = None
    waist: Optional[float] = None
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
    user_row = None
    try:
        if "-" in req.user_id:
            u_res = admin.table("usuarios").select("id, cedula, nombre, peso").eq("id", req.user_id).execute()
        else:
            u_res = admin.table("usuarios").select("id, cedula, nombre, peso").eq("cedula", req.user_id).execute()
        if u_res.data:
            user_row = u_res.data[0]
    except Exception:
        pass

    uid = user_row["id"] if user_row else req.user_id
    cedula = user_row.get("cedula", req.user_id) if user_row else req.user_id

    # 1. Actualizar peso en tabla usuarios
    if user_row and req.weight > 0:
        try:
            admin.table("usuarios").update({"peso": req.weight}).eq("id", uid).execute()
        except Exception as e_up:
            print("Warning updating peso in usuarios:", e_up)

    # 2. Persistir en coach_mensajes como registro métrico estructurado
    metric_record = {
        "weight": round(float(req.weight), 2),
        "body_fat": round(float(req.body_fat), 1) if req.body_fat is not None else None,
        "chest": round(float(req.chest), 1) if req.chest is not None else None,
        "waist": round(float(req.waist), 1) if req.waist is not None else None,
        "arm": round(float(req.arm), 1) if req.arm is not None else None,
        "thigh": round(float(req.thigh), 1) if req.thigh is not None else None,
        "notes": req.notes or "",
        "measured_at": measured_date,
    }

    try:
        admin.table("coach_mensajes").insert({
            "user_id": uid,
            "cedula": cedula,
            "role": "system",
            "category": "body_metric",
            "content": f"Registro Métrico: {req.weight} kg" + (f" | {req.body_fat}% grasa" if req.body_fat else ""),
            "plan": metric_record,
            "created_at": datetime.utcnow().isoformat()
        }).execute()
    except Exception as e_msg:
        print("Warning saving metric to coach_mensajes:", e_msg)

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
        q = admin.table("coach_mensajes").select("*").eq("category", "body_metric")
        if "-" in user_id:
            q = q.eq("user_id", user_id)
        else:
            q = q.eq("cedula", user_id)
        res = q.order("created_at", desc=False).execute()
        raw_list = res.data or []

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

        # Si no hay mediciones, buscar el peso inicial en usuarios
        if not metrics:
            try:
                u_q = admin.table("usuarios").select("peso, created_at")
                if "-" in user_id:
                    u_q = u_q.eq("id", user_id)
                else:
                    u_q = u_q.eq("cedula", user_id)
                u_res = u_q.execute()
                if u_res.data:
                    init_w = float(u_res.data[0].get("peso") or 70.0)
                    init_d = str(u_res.data[0].get("created_at") or date.today().isoformat())[:10]
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
            except Exception:
                pass

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
