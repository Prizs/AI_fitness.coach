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

SYSTEM_INSTRUCTION = (
    "Eres un transcriptor de voz profesional y estricto para una aplicación de fitness y salud deportiva. "
    "Tu ÚNICA tarea es escribir literalmente y con exactitud lo que el usuario habla en el audio en español. "
    "REGLAS INQUEBRANTABLES:\n"
    "1. Devuelve SOLAMENTE el texto exacto que dijo el usuario.\n"
    "2. NO agregues notas, comentarios, puntuación innecesaria ni prefijos como 'Transcripción:'.\n"
    "3. Si en el audio NO hay voz clara, o hay silencio, estática, o solo sonido de fondo, debes responder ÚNICAMENTE: SILENCIO.\n"
    "4. JAMÁS inventes frases sobre inversiones, propiedades inmobiliarias, alquileres o temas ajenos al audio."
)

@router.post("/transcribe")
async def transcribe_audio(payload: TranscribeRequest):
    api_key = os.getenv("GEMINI_API_KEY", "")
    if not api_key:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY no configurado")

    if not payload.audio_base64 or len(payload.audio_base64.strip()) < 50:
        return {"text": "", "warning": "Audio vacío"}

    try:
        audio_bytes = base64.b64decode(payload.audio_base64)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error decodificando audio base64: {e}")

    # Si el archivo tiene menos de 2500 bytes (~0.2 segundos), se considera silencio o clic accidental
    if len(audio_bytes) < 2500:
        return {"text": "", "warning": "Audio demasiado corto"}

    mime = payload.mime_type.split(";")[0].strip() or "audio/webm"

    try:
        genai.configure(api_key=api_key)
        audio_part = {
            "mime_type": mime,
            "data": audio_bytes,
        }
        prompt = "Transcribe el audio del usuario con máxima exactitud:"

        configured_model = (os.environ.get("GEMINI_MODEL") or "").strip()
        raw_candidates = [configured_model] if (configured_model and "2.5-flash" not in configured_model) else []
        raw_candidates.extend(["gemini-3.1-flash-lite", "gemini-flash-latest", "gemini-3.5-flash-lite", "gemini-3.8-flash"])
        candidates = list(dict.fromkeys(raw_candidates))

        raw_text = ""
        last_err = None
        for model_name in candidates:
            try:
                model = genai.GenerativeModel(
                    model_name,
                    generation_config={"temperature": 0.0},
                    system_instruction=SYSTEM_INSTRUCTION,
                )
                response = model.generate_content([audio_part, prompt])
                raw_text = (response.text or "").strip()
                break
            except Exception as ex:
                last_err = ex
                continue
        else:
            if last_err:
                raise last_err

        # Filtrar respuestas vacías o indicadoras de silencio
        upper_text = raw_text.upper().strip(" .;,")
        if not raw_text or upper_text in ("SILENCIO", "[VACIO]", "VACIO", "SIN AUDIO", "NO AUDIO"):
            return {"text": "", "success": True}

        # Limpiar posibles comillas envolventes
        if raw_text.startswith('"') and raw_text.endswith('"') and len(raw_text) > 1:
            raw_text = raw_text[1:-1].strip()

        # Protección extra contra alucinaciones conocidas de corpora de entrenamiento
        lower = raw_text.lower()
        if "propiedades inmobiliarias" in lower or "bienes raíces" in lower or "subtítulos por" in lower:
            return {"text": "", "warning": "Alucinación filtrada", "success": True}

        return {"text": raw_text, "success": True}
    except Exception as e:
        print(f"[VOICE] Error transcribiendo audio: {e}")
        return {"text": "", "error": str(e), "success": False}
