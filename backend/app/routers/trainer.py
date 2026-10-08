from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from app.services.supabase_service import get_supabase_admin_client

router = APIRouter(prefix="/api/trainer", tags=["Trainer"])

class AssignTrainerReq(BaseModel):
    client_id: str
    trainer_id: str

@router.post("/assign")
def assign_trainer(req: AssignTrainerReq):
    admin = get_supabase_admin_client()
    try:
        # Verificar que el entrenador exista y tenga rol 'trainer'
        trainer_res = admin.table("usuarios").select("id, role").eq("id", req.trainer_id).execute()
        if not trainer_res.data or trainer_res.data[0].get("role") != "trainer":
            raise HTTPException(status_code=400, detail="El ID del entrenador no es válido.")

        # Asignar
        res = admin.table("usuarios").update({"trainer_id": req.trainer_id}).eq("id", req.client_id).execute()
        if res.data:
            return {"status": "ok", "message": "Entrenador asignado con éxito."}
        raise HTTPException(status_code=400, detail="No se pudo asignar.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/clients/{trainer_id}")
def get_clients(trainer_id: str):
    admin = get_supabase_admin_client()
    try:
        res = admin.table("usuarios").select("*").eq("trainer_id", trainer_id).execute()
        return res.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

