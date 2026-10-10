import sys

path = 'backend/app/routers/auth.py'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Update RegisterRequest
old_req = '''class RegisterRequest(BaseModel):
    cedula: str = Field(..., pattern=r"^\d{6,9}$")
    password: str = Field(..., min_length=8)
    nombre: str = Field(..., min_length=2, max_length=100)
    apellido: str = Field(..., min_length=2, max_length=100)
    edad: int = Field(..., ge=12, le=100)
    peso: float = Field(..., gt=0, le=300)
    patologia_o_alergias: str | None = Field(default=None, max_length=1000)'''

new_req = '''class RegisterRequest(BaseModel):
    cedula: str = Field(..., pattern=r"^\d{6,9}$")
    password: str = Field(..., min_length=8)
    nombre: str = Field(..., min_length=2, max_length=100)
    apellido: str = Field(..., min_length=2, max_length=100)
    edad: int = Field(..., ge=12, le=100)
    peso: float = Field(..., gt=0, le=300)
    patologia_o_alergias: str | None = Field(default=None, max_length=1000)
    security_question: str = Field(default="¿Cuál es tu color favorito?", max_length=100)
    security_answer: str = Field(default="", max_length=100)'''

text = text.replace(old_req, new_req)

# Update register metadata
old_meta = '''"user_metadata": {"cedula": payload.cedula},'''
new_meta = '''"user_metadata": {
                    "cedula": payload.cedula,
                    "security_question": payload.security_question,
                    "security_answer": payload.security_answer.strip().lower()
                },'''

text = text.replace(old_meta, new_meta)

# Add recovery endpoints
new_endpoints = '''
class RecoverRequest(BaseModel):
    cedula: str
    security_answer: str
    new_password: str

@router.get("/security_question/{cedula}")
def get_security_question(cedula: str):
    admin_client = get_supabase_admin_client()
    users = admin_client.auth.admin.list_users()
    for u in users:
        if f"cedula.{cedula}@" in u.email:
            question = u.user_metadata.get("security_question", "¿Cuál es tu color favorito?")
            return {"question": question}
    raise HTTPException(status_code=404, detail="Usuario no encontrado.")

@router.post("/recover_password")
def recover_password(payload: RecoverRequest):
    admin_client = get_supabase_admin_client()
    users = admin_client.auth.admin.list_users()
    for u in users:
        if f"cedula.{payload.cedula}@" in u.email:
            real_answer = u.user_metadata.get("security_answer", "").strip().lower()
            if not real_answer:
                raise HTTPException(status_code=400, detail="Este usuario no configuró pregunta de seguridad.")
            if payload.security_answer.strip().lower() == real_answer:
                admin_client.auth.admin.update_user_by_id(u.id, {"password": payload.new_password})
                return {"status": "ok", "message": "Contraseña actualizada exitosamente."}
            else:
                raise HTTPException(status_code=403, detail="Respuesta incorrecta.")
    raise HTTPException(status_code=404, detail="Usuario no encontrado.")
'''

text += new_endpoints

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
