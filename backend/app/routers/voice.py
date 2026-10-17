import base64
import os
from pathlib import Path
from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import google.generativeai as genai

load_dotenv(Path(__file__).resolve().parents[3] / ".env")

router = APIRouter()

class TranscribeRequest(BaseModel):
    audio_base64: str
    mime_type: str = "audio/webm"

@router.post("/transcribe")
async def transcribe_audio(payload: TranscribeRequest):
    api_key = os.getenv("GEMINI_API_KEY", "")
    if not api_key:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY no configurado")

    if not payload.audio_base64 or len(payload.audio_base64.strip()) < 10:
        return {"text": "", "warning": "Audio vacío"}

    try:
        audio_bytes = base64.b64decode(payload.audio_base64)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error decodificando audio base64: {e}")

    # Detect clean mime type
    mime = payload.mime_type.split(";")[0].strip() or "audio/webm"
    if mime not in ("audio/webm", "audio/wav", "audio/mp4", "audio/mpeg", "audio/ogg", "audio/aac"):
        mime = "audio/webm"

    try:
        genai.configure(api_key=api_key)
        # Usamos gemini-2.5-flash o gemini-1.5-flash
        model_name = (os.getenv("GEMINI_MODEL", "") or "").strip() or "gemini-2.5-flash"
        model = genai.GenerativeModel(model_name)

        audio_part = {
            "mime_type": mime,
            "data": audio_bytes,
        }
        prompt = (
            "Escucha este audio del usuario y transcríbelo exactamente en español. "
            "Devuelve ÚNICAMENTE el texto que la persona dijo, tal cual. "
            "No agregues introducciones ni explicaciones ni notas como 'Aquí está la transcripción'. "
            "No agregues comillas extras. Si el audio está vacío o solo contiene ruido o silencio, devuelve cadena vacía."
        )

        response = model.generate_content([audio_part, prompt])
        transcribed_text = (response.text or "").strip()

        # Limpiar posibles comillas envolventes
        if transcribed_text.startswith('"') and transcribed_text.endswith('"') and len(transcribed_text) > 1:
            transcribed_text = transcribed_text[1:-1].strip()

        return {"text": transcribed_text, "success": True}
    except Exception as e:
        # Fallback a gemini-1.5-flash si 2.5 da error de modelo
        try:
            model = genai.GenerativeModel("gemini-1.5-flash")
            response = model.generate_content([audio_part, prompt])
            transcribed_text = (response.text or "").strip()
            if transcribed_text.startswith('"') and transcribed_text.endswith('"') and len(transcribed_text) > 1:
                transcribed_text = transcribed_text[1:-1].strip()
            return {"text": transcribed_text, "success": True}
        except Exception as e2:
            return {"text": "", "error": f"Error transcribiendo: {e2}", "success": False}
