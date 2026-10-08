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
        
        # 1. Analyze with Gemini
        genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))
        model = genai.GenerativeModel('gemini-1.5-flash')
        prompt = "Actúa como un entrenador personal experto en recomposición corporal. Analiza esta foto de progreso físico del cliente. Describe brevemente y con tono muy motivador: 1) Puntos fuertes visibles (ej. buena definición en hombros o abdomen), 2) Áreas de oportunidad (ej. enfoque en tren inferior), 3) Un mensaje corto de ánimo para seguir con la rutina."
        
        image_parts = [
            {
                "mime_type": file.content_type or 'image/jpeg',
                "data": file_bytes
            }
        ]
        
        response = model.generate_content([prompt, image_parts[0]])
        analysis_text = response.text

        # 2. Upload to Supabase Storage (assuming bucket 'progress' exists)
        file_path = f"{user_id}/{file.filename}"
        try:
            admin.storage.from_("progress").upload(file_path, file_bytes, {"content-type": file.content_type})
        except Exception:
            pass
            
        public_url = admin.storage.from_("progress").get_public_url(file_path)

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
