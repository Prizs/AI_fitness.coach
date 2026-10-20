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
