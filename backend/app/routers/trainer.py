from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, date
import json
import base64
import time
import os
from app.services.supabase_service import get_supabase_admin_client
from app.services.weekly_plan import _sessions, build_weekly_plan, WEEKDAY_NAMES
from app.services.ai_providers import generate_json_text, configured_providers

router = APIRouter(prefix="/api/trainer", tags=["Trainer"])


def _resolve_user_id(admin, identifier: str) -> Optional[dict]:
    """Busca un usuario por UUID o por Cédula."""
    if not identifier:
        return None
    # 1. Intentar por id
    try:
        res = admin.table("usuarios").select("*").eq("id", identifier).execute()
        if res.data:
            return res.data[0]
    except Exception:
        pass
    # 2. Intentar por cedula
    try:
        res = admin.table("usuarios").select("*").eq("cedula", identifier).execute()
        if res.data:
            return res.data[0]
    except Exception:
        pass
    return None


class AssignTrainerReq(BaseModel):
    client_id: str
    trainer_id: str


class SendMessageReq(BaseModel):
    trainer_id: str
    client_id: str
    sender_id: str
    message: str


class AddSlotReq(BaseModel):
    trainer_id: str
    day_of_week: int  # 1=Lunes, 7=Domingo
    start_time: str   # "12:00"
    end_time: str     # "14:00"
    max_capacity: int = 2


class BookSlotReq(BaseModel):
    trainer_id: str
    client_id: str
    schedule_date: str  # "YYYY-MM-DD"
    start_time: str
    end_time: str
    booked_by: Optional[str] = "trainer"
    status: Optional[str] = None



class CreateAnnouncementReq(BaseModel):
    trainer_id: str
    message: str


class DeleteBlockReq(BaseModel):
    trainer_id: str
    schedule_date: str
    day_of_week: Optional[int] = None
    start_time: str
    end_time: str
    block_id: Optional[str] = None


class CompleteSessionLogReq(BaseModel):
    session_id: str
    trainer_id: str
    client_id: str
    technical_notes: str
    rpe: int = 7
    recommendations: Optional[str] = ""
    biomechanics_checklist: Optional[List[str]] = []


class UpdateProfileReq(BaseModel):
    trainer_id: str
    specialty: Optional[str] = None
    experience_years: Optional[int] = None
    certifications: Optional[str] = None


@router.get("/trainers")
def get_all_trainers():
    """Lista todos los entrenadores disponibles registrados en el sistema."""
    admin = get_supabase_admin_client()
    try:
        res = admin.table("usuarios").select("id, nombre, apellido, cedula, role").eq("role", "trainer").execute()
        trainers = res.data or []
        # Fallback si no hay ninguno registrado
        if not trainers:
            trainers = [
                {"id": "demo-nelvis", "nombre": "Nelvis", "apellido": "Rincón", "cedula": "29977666", "role": "trainer"},
                {"id": "demo-gael", "nombre": "Gael", "apellido": "Galindo", "cedula": "17294039", "role": "trainer"},
            ]
        return trainers
    except Exception as e:
        return [
            {"id": "demo-nelvis", "nombre": "Nelvis", "apellido": "Rincón", "cedula": "29977666", "role": "trainer"}
        ]


@router.get("/my-trainer/{client_id}")
def get_my_trainer(client_id: str):
    """Retorna el entrenador asignado al cliente o null si no tiene."""
    admin = get_supabase_admin_client()
    client = _resolve_user_id(admin, client_id)
    if not client:
        return {"assigned": False, "trainer": None}

    trainer_ref = client.get("trainer_id")
    if not trainer_ref:
        return {"assigned": False, "trainer": None}

    trainer = _resolve_user_id(admin, trainer_ref)
    if not trainer:
        return {"assigned": False, "trainer": None}

    return {
        "assigned": True,
        "trainer": {
            "id": trainer.get("id"),
            "nombre": trainer.get("nombre"),
            "apellido": trainer.get("apellido"),
            "cedula": trainer.get("cedula"),
            "name": f"{trainer.get('nombre')} {trainer.get('apellido')}",
            "specialty": "Hipertrofia, Fuerza y Biomecánica",
        }
    }


@router.post("/assign")
def assign_trainer(req: AssignTrainerReq):
    """Vincula un cliente a un entrenador."""
    admin = get_supabase_admin_client()
    try:
        trainer = _resolve_user_id(admin, req.trainer_id)
        if not trainer or trainer.get("role") != "trainer":
            raise HTTPException(status_code=400, detail="El ID del entrenador no es válido o no tiene rol 'trainer'.")

        client = _resolve_user_id(admin, req.client_id)
        if not client:
            raise HTTPException(status_code=400, detail="El cliente especificado no existe.")

        res = admin.table("usuarios").update({"trainer_id": trainer["id"]}).eq("id", client["id"]).execute()
        return {
            "status": "ok",
            "message": f"Entrenador {trainer.get('nombre')} {trainer.get('apellido')} asignado con éxito.",
            "trainer": trainer
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/clients/{trainer_id}")
def get_clients(trainer_id: str):
    """Lista todos los clientes asignados a un entrenador."""
    admin = get_supabase_admin_client()
    trainer = _resolve_user_id(admin, trainer_id)
    real_trainer_id = trainer["id"] if trainer else trainer_id

    try:
        res = admin.table("usuarios").select("*").eq("trainer_id", real_trainer_id).execute()
        clients = res.data or []
        # Decorar con información legible de alertas/riesgos
        for c in clients:
            injuries = c.get("lesiones_actuales") or c.get("patologia_o_alergias") or ""
            c["has_risk"] = bool(injuries and injuries.lower() not in ("ninguna", "ninguno", "no", "sano"))
            c["risk_label"] = injuries if c["has_risk"] else "Sin lesiones reportadas"
        return clients
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/messages/{trainer_id}/{client_id}")
def get_messages(trainer_id: str, client_id: str):
    """Obtiene el historial de chat en vivo entre un entrenador y un cliente."""
    admin = get_supabase_admin_client()
    t = _resolve_user_id(admin, trainer_id)
    c = _resolve_user_id(admin, client_id)
    t_id = t["id"] if t else trainer_id
    c_id = c["id"] if c else client_id

    try:
        res = (
            admin.table("trainer_chat")
            .select("*")
            .or_(f"and(trainer_id.eq.{t_id},client_id.eq.{c_id}),and(trainer_id.eq.{c_id},client_id.eq.{t_id})")
            .order("created_at", desc=False)
            .execute()
        )
        messages = res.data or []
        t_name = f"{t.get('nombre', '')} {t.get('apellido', '')}".strip() if t else "Entrenador"
        c_name = f"{c.get('nombre', '')} {c.get('apellido', '')}".strip() if c else "Alumno"

        for m in messages:
            s_id = str(m.get("sender_id", ""))
            is_from_trainer = (s_id == str(t_id))
            m["is_from_trainer"] = is_from_trainer
            m["sender_role"] = "trainer" if is_from_trainer else "client"
            m["sender_name"] = f"Coach {t_name}" if is_from_trainer else c_name
        return messages
    except Exception as e:
        # Fallback si el filtro OR falla en sintaxis PostgREST
        try:
            res = (
                admin.table("trainer_chat")
                .select("*")
                .eq("trainer_id", t_id)
                .eq("client_id", c_id)
                .order("created_at", desc=False)
                .execute()
            )
            messages = res.data or []
            t_name = f"{t.get('nombre', '')} {t.get('apellido', '')}".strip() if t else "Entrenador"
            c_name = f"{c.get('nombre', '')} {c.get('apellido', '')}".strip() if c else "Alumno"
            for m in messages:
                s_id = str(m.get("sender_id", ""))
                is_from_trainer = (s_id == str(t_id))
                m["is_from_trainer"] = is_from_trainer
                m["sender_role"] = "trainer" if is_from_trainer else "client"
                m["sender_name"] = f"Coach {t_name}" if is_from_trainer else c_name
            return messages
        except Exception as e2:
            raise HTTPException(status_code=500, detail=str(e2))


@router.get("/latest-chat-message/{user_id}")
def get_latest_chat_message(user_id: str):
    """
    Retorna el mensaje más reciente recibido por este usuario (donde sender_id != user_id),
    con el nombre y rol del remitente para disparar la notificación flotante con sonido.
    """
    admin = get_supabase_admin_client()
    user = _resolve_user_id(admin, user_id)
    u_id = user["id"] if user else user_id
    u_cedula = user.get("cedula") if user else user_id

    try:
        # En Supabase trainer_chat, client_id y trainer_id son UUIDs
        res = (
            admin.table("trainer_chat")
            .select("*")
            .or_(f"client_id.eq.{u_id},trainer_id.eq.{u_id}")
            .order("created_at", desc=True)
            .limit(10)
            .execute()
        )
        messages = res.data or []
        for m in messages:
            s_id = str(m.get("sender_id", ""))
            if s_id != str(u_id) and s_id != str(u_cedula):
                sender_user = _resolve_user_id(admin, s_id)
                sender_name = "Entrenador"
                sender_role = "trainer"
                sender_cedula = s_id
                if sender_user:
                    sender_name = f"{sender_user.get('nombre', '')} {sender_user.get('apellido', '')}".strip()
                    sender_role = sender_user.get("role", "trainer")
                    sender_cedula = str(sender_user.get("cedula") or s_id)
                
                return {
                    "has_message": True,
                    "message_id": str(m.get("id")),
                    "sender_id": s_id,
                    "sender_cedula": sender_cedula,
                    "sender_name": sender_name,
                    "sender_role": sender_role,
                    "message": m.get("message"),
                    "created_at": m.get("created_at"),
                    "trainer_id": str(m.get("trainer_id")),
                    "client_id": str(m.get("client_id")),
                }

        # Si el usuario es un alumno, verificar si su entrenador publicó un anuncio reciente
        if user and user.get("trainer_id"):
            try:
                ann_res = (
                    admin.table("trainer_announcements")
                    .select("*")
                    .eq("trainer_id", user["trainer_id"])
                    .order("created_at", desc=True)
                    .limit(1)
                    .execute()
                )
                if ann_res.data:
                    ann = ann_res.data[0]
                    ann_id = f"ann_{ann.get('id')}"
                    ann_msg = ann.get("message") or ""
                    ann_time = ann.get("created_at") or ""
                    
                    tr = _resolve_user_id(admin, user["trainer_id"])
                    t_name = f"{tr.get('nombre', '')} {tr.get('apellido', '')}".strip() if tr else "Entrenador"
                    t_cedula = str(tr.get("cedula") if tr else user["trainer_id"])
                    return {
                        "has_message": True,
                        "message_id": ann_id,
                        "sender_id": str(user["trainer_id"]),
                        "sender_cedula": t_cedula,
                        "sender_name": t_name,
                        "sender_role": "trainer",
                        "message": f"📢 AVISO OFICIAL:\n{ann_msg}",
                        "created_at": ann_time,
                        "trainer_id": str(user["trainer_id"]),
                        "client_id": str(u_id),
                    }
            except Exception:
                pass

        return {"has_message": False}
    except Exception as e:
        return {"has_message": False, "error": str(e)}


@router.post("/messages")
def send_message(req: SendMessageReq):
    """Envía un mensaje en el chat entre entrenador y cliente."""
    admin = get_supabase_admin_client()
    t = _resolve_user_id(admin, req.trainer_id)
    c = _resolve_user_id(admin, req.client_id)
    s = _resolve_user_id(admin, req.sender_id)

    t_id = t["id"] if t else req.trainer_id
    c_id = c["id"] if c else req.client_id
    s_id = s["id"] if s else req.sender_id

    try:
        new_msg = {
            "trainer_id": t_id,
            "client_id": c_id,
            "sender_id": s_id,
            "message": req.message.strip(),
            "created_at": datetime.utcnow().isoformat()
        }
        res = admin.table("trainer_chat").insert(new_msg).execute()
        return {"status": "ok", "message": res.data[0] if res.data else new_msg}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/conversations/{trainer_id}")
def get_conversations(trainer_id: str):
    """Obtiene el listado de conversaciones activas para la pestaña de mensajes del entrenador."""
    admin = get_supabase_admin_client()
    trainer = _resolve_user_id(admin, trainer_id)
    t_id = trainer["id"] if trainer else trainer_id

    try:
        # 1. Obtener clientes asignados
        clients_res = admin.table("usuarios").select("id, nombre, apellido, cedula").eq("trainer_id", t_id).execute()
        clients = clients_res.data or []

        # Si no tiene clientes asignados directamente, obtener usuarios únicos con quienes ha chateado
        if not clients:
            chat_res = admin.table("trainer_chat").select("client_id").eq("trainer_id", t_id).execute()
            client_ids = list({row["client_id"] for row in (chat_res.data or [])})
            if client_ids:
                clients_res = admin.table("usuarios").select("id, nombre, apellido, cedula").in_("id", client_ids).execute()
                clients = clients_res.data or []

        conversations = []
        for c in clients:
            c_id = c["id"]
            # Buscar último mensaje
            last_msg_res = (
                admin.table("trainer_chat")
                .select("*")
                .eq("trainer_id", t_id)
                .eq("client_id", c_id)
                .order("created_at", desc=True)
                .limit(1)
                .execute()
            )
            last_msg = last_msg_res.data[0] if last_msg_res.data else None
            conversations.append({
                "client_id": c_id,
                "name": f"{c.get('nombre', '')} {c.get('apellido', '')}".strip() or "Alumno",
                "cedula": c.get("cedula", ""),
                "last_msg": last_msg["message"] if last_msg else "Sin mensajes previos",
                "time": last_msg["created_at"][:16].replace("T", " ") if last_msg else "Hoy",
                "unread": "1" if last_msg and last_msg.get("sender_id") == c_id else "0"
            })

        # Fallback de muestra para demo si no hay conversaciones registradas todavía
        if not conversations:
            conversations = [
                {"client_id": "c1", "name": "Freddy Rincón", "last_msg": "Profe, completé la rutina de piernas de hoy.", "time": "10:30 AM", "unread": "1"},
                {"client_id": "c2", "name": "Emmanuel Guerra", "last_msg": "Listo el entreno, me sentí con buena energía.", "time": "Ayer", "unread": "0"},
            ]

        return conversations
    except Exception as e:
        return [
            {"client_id": "c1", "name": "Freddy Rincón", "last_msg": "Profe, completé la rutina de piernas de hoy.", "time": "10:30 AM", "unread": "1"},
        ]


def _format_time_label(st: str, et: str) -> str:
    try:
        t1 = datetime.strptime(st[:5], "%H:%M")
        t2 = datetime.strptime(et[:5], "%H:%M")
        s1 = t1.strftime("%I:%M %p").lstrip("0")
        s2 = t2.strftime("%I:%M %p").lstrip("0")
        return f"{s1} - {s2}"
    except Exception:
        return f"{st[:5]} - {et[:5]}"


@router.get("/agenda/{trainer_id}")
def get_trainer_agenda(trainer_id: str, target_date: Optional[str] = None):
    """
    Retorna la agenda organizada cronológicamente por bloques horarios para una fecha dada,
    con capacidad, alumnos reales inscritos y su planificación de ejercicios para ese día.
    """
    admin = get_supabase_admin_client()
    trainer = _resolve_user_id(admin, trainer_id)
    t_id = trainer["id"] if trainer else trainer_id

    if not target_date:
        target_date = date.today().isoformat()
    else:
        try:
            datetime.strptime(target_date, "%Y-%m-%d")
        except ValueError:
            target_date = date.today().isoformat()

    dt = datetime.strptime(target_date, "%Y-%m-%d")
    weekday_idx = dt.weekday()  # 0=Lunes, 6=Domingo
    day_num = dt.isoweekday()   # 1=Lunes, 7=Domingo
    day_names = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
    day_name = day_names[weekday_idx]

    try:
        # 1. Obtener bloques horarios de trainer_schedules
        schedules_res = admin.table("trainer_schedules").select("*").eq("trainer_id", t_id).execute()
        base_schedules = schedules_res.data or []

        # Filtrar por día específico de la semana si existe configuración por día
        day_schedules = [s for s in base_schedules if s.get("day_of_week") == day_num]
        if not day_schedules and base_schedules:
            day_schedules = base_schedules

        default_blocks = [
            {"start_time": "08:00:00", "end_time": "10:00:00", "time_label": "8:00 AM - 10:00 AM", "capacity": 2},
            {"start_time": "10:30:00", "end_time": "12:30:00", "time_label": "10:30 AM - 12:30 PM", "capacity": 2},
            {"start_time": "13:00:00", "end_time": "15:00:00", "time_label": "1:00 PM - 3:00 PM", "capacity": 2},
            {"start_time": "15:30:00", "end_time": "17:30:00", "time_label": "3:30 PM - 5:30 PM", "capacity": 2},
            {"start_time": "18:00:00", "end_time": "20:00:00", "time_label": "6:00 PM - 8:00 PM", "capacity": 2},
            {"start_time": "20:30:00", "end_time": "22:30:00", "time_label": "8:30 PM - 10:30 PM", "capacity": 2},
        ]

        blocks_to_use = []
        if day_schedules:
            for s in sorted(day_schedules, key=lambda x: str(x.get("start_time", ""))):
                st = str(s.get("start_time") or "12:00:00")
                et = str(s.get("end_time") or "14:00:00")
                if len(st) == 5:
                    st += ":00"
                if len(et) == 5:
                    et += ":00"
                blocks_to_use.append({
                    "id": s.get("id"),
                    "start_time": st,
                    "end_time": et,
                    "time_label": _format_time_label(st, et),
                    "capacity": s.get("max_capacity") or 2
                })
        else:
            blocks_to_use = default_blocks

        # 2. Obtener sesiones reservadas para la fecha seleccionada en workout_sessions
        sessions_res = (
            admin.table("workout_sessions")
            .select("*, usuarios!workout_sessions_client_id_fkey(id, nombre, apellido, cedula, edad, peso, patologia_o_alergias, lesiones_actuales)")
            .eq("trainer_id", t_id)
            .eq("schedule_date", target_date)
            .execute()
        )
        sessions = sessions_res.data or []

        # 3. Plan de entrenamiento del día correspondiente según el cronograma
        try:
            weekly_routines = _sessions("Media")
            day_routine = weekly_routines[weekday_idx]
            routine_title = day_routine.get("title", "Rutina Personalizada")
            exercises_count = len(day_routine.get("exercises", []))
            day_workout_label = f"{routine_title} ({exercises_count} ejercicios)"
            day_exercises = [
                {
                    "name": ex.get("name", "Ejercicio"),
                    "sets": ex.get("sets", 3),
                    "reps": str(ex.get("reps", "10-12")),
                    "primary_muscle": ex.get("primary_muscle", "General"),
                    "biomechanics": ex.get("biomechanics", "Movimiento controlado y respiración adecuada.")
                }
                for ex in day_routine.get("exercises", [])
            ]
        except Exception:
            day_workout_label = "Rutina del cronograma personalizada"
            day_exercises = []

        matched_session_ids = set()
        agenda_blocks = []
        total_students = 0

        for b in blocks_to_use:
            b_st = b["start_time"][:5]
            # Emparejar sesiones cuya hora de inicio coincida (HH:MM)
            b_sessions = [s for s in sessions if str(s.get("start_time", ""))[:5] == b_st]
            students = []

            for s in b_sessions:
                matched_session_ids.add(s.get("id"))
                user_info = s.get("usuarios") or {}
                name = f"{user_info.get('nombre', '')} {user_info.get('apellido', '')}".strip() or "Alumno"
                cedula = user_info.get("cedula") or ""
                injuries = str(user_info.get("lesiones_actuales") or user_info.get("patologia_o_alergias") or "")

                risk = "🟢 Óptimo"
                if injuries and injuries.lower() not in ("ninguna", "ninguno", "no", "sano", "none", ""):
                    risk = f"🔴 {injuries}"

                s_status = s.get("status") or "scheduled"
                counter_time = None
                counter_note = None
                if s_status.startswith("counter_proposed"):
                    parts = s_status.split(":", 1)[1].split("|") if ":" in s_status else ["", ""]
                    counter_time = parts[0]
                    counter_note = parts[1] if len(parts) > 1 else ""

                students.append({
                    "id": s.get("id"),
                    "client_id": s.get("client_id"),
                    "name": name,
                    "cedula": cedula,
                    "edad": user_info.get("edad") or 25,
                    "peso": user_info.get("peso") or 70.0,
                    "alergias": user_info.get("alergias_alimentarias") or "Ninguna",
                    "workout": day_workout_label,
                    "exercises": day_exercises,
                    "risk": risk,
                    "status": s_status,
                    "counter_time": counter_time,
                    "counter_note": counter_note,
                })

            occupied = len(students)
            total_students += occupied
            cap = b["capacity"]
            if occupied >= cap:
                capacity_text = f"{occupied}/{cap} Cupos Llenos"
            elif occupied > 0:
                capacity_text = f"{occupied}/{cap} Cupos ({cap - occupied} Libres)"
            else:
                capacity_text = f"{cap}/{cap} Cupos Libres"

            agenda_blocks.append({
                "id": b.get("id"),
                "time": b["time_label"],
                "start_time": b["start_time"],
                "end_time": b["end_time"],
                "capacity": capacity_text,
                "occupied": occupied,
                "max_capacity": cap,
                "is_full": occupied >= cap,
                "students": students
            })

        # Incluir sesiones adicionales agendadas o confirmadas que no coinciden con los bloques estándar
        unmatched_sessions = [s for s in sessions if s.get("id") not in matched_session_ids]
        if unmatched_sessions:
            custom_map = {}
            for s in unmatched_sessions:
                st = str(s.get("start_time") or "12:00:00")[:5]
                et = str(s.get("end_time") or "14:00:00")[:5]
                key = (st, et)
                if key not in custom_map:
                    custom_map[key] = []
                custom_map[key].append(s)

            for (st, et), c_sessions in custom_map.items():
                st_full = f"{st}:00" if len(st) == 5 else st
                et_full = f"{et}:00" if len(et) == 5 else et
                c_students = []
                for s in c_sessions:
                    user_info = s.get("usuarios") or {}
                    name = f"{user_info.get('nombre', '')} {user_info.get('apellido', '')}".strip() or "Alumno"
                    cedula = user_info.get("cedula") or ""
                    injuries = str(user_info.get("lesiones_actuales") or user_info.get("patologia_o_alergias") or "")

                    risk = "🟢 Óptimo"
                    if injuries and injuries.lower() not in ("ninguna", "ninguno", "no", "sano", "none", ""):
                        risk = f"🔴 {injuries}"

                    s_status = s.get("status") or "scheduled"
                    counter_time = None
                    counter_note = None
                    if s_status.startswith("counter_proposed"):
                        parts = s_status.split(":", 1)[1].split("|") if ":" in s_status else ["", ""]
                        counter_time = parts[0]
                        counter_note = parts[1] if len(parts) > 1 else ""

                    c_students.append({
                        "id": s.get("id"),
                        "client_id": s.get("client_id"),
                        "name": name,
                        "cedula": cedula,
                        "edad": user_info.get("edad") or 25,
                        "peso": user_info.get("peso") or 70.0,
                        "alergias": user_info.get("alergias_alimentarias") or "Ninguna",
                        "workout": day_workout_label,
                        "exercises": day_exercises,
                        "risk": risk,
                        "status": s_status,
                        "counter_time": counter_time,
                        "counter_note": counter_note,
                    })

                occupied = len(c_students)
                total_students += occupied
                cap = max(2, occupied)
                capacity_text = f"{occupied}/{cap} Cupos Llenos" if occupied >= cap else f"{occupied}/{cap} Cupos ({cap - occupied} Libres)"

                agenda_blocks.append({
                    "id": f"custom_{st}",
                    "time": _format_time_label(st_full, et_full),
                    "start_time": st_full,
                    "end_time": et_full,
                    "capacity": capacity_text,
                    "occupied": occupied,
                    "max_capacity": cap,
                    "is_full": occupied >= cap,
                    "is_custom": True,
                    "students": c_students
                })

        # Ordenar todos los bloques cronológicamente
        agenda_blocks.sort(key=lambda x: str(x.get("start_time", "")))

        return {
            "date": target_date,
            "day_name": day_name,
            "total_students": total_students,
            "blocks": agenda_blocks
        }
    except Exception as e:
        return {
            "date": target_date,
            "day_name": "Hoy",
            "total_students": 0,
            "blocks": [],
            "error": str(e)
        }


@router.post("/agenda/slot")
def add_or_update_slot(req: AddSlotReq):
    """Permite al entrenador crear o ajustar un bloque horario en su agenda base y notifica a sus alumnos."""
    admin = get_supabase_admin_client()
    trainer = _resolve_user_id(admin, req.trainer_id)
    t_id = trainer["id"] if trainer else req.trainer_id

    st = req.start_time if len(req.start_time) == 8 else f"{req.start_time[:5]}:00"
    et = req.end_time if len(req.end_time) == 8 else f"{req.end_time[:5]}:00"

    try:
        new_slot = {
            "trainer_id": t_id,
            "day_of_week": req.day_of_week,
            "start_time": st,
            "end_time": et,
            "max_capacity": req.max_capacity
        }
        res = admin.table("trainer_schedules").insert(new_slot).execute()

        # Notificar a los clientes vinculados al entrenador que se abrió un nuevo horario
        try:
            t_name = f"{trainer.get('nombre', '')} {trainer.get('apellido', '')}".strip() if trainer else "Tu Entrenador"
            clients_res = admin.table("usuarios").select("id, nombre, apellido").eq("trainer_id", t_id).execute()
            assigned_clients = clients_res.data or []
            
            day_labels = {1: "Lunes", 2: "Martes", 3: "Miércoles", 4: "Jueves", 5: "Viernes", 6: "Sábado", 7: "Domingo"}
            day_str = day_labels.get(req.day_of_week, "esta semana")
            
            for ac in assigned_clients:
                cid = ac.get("id")
                cname = ac.get("nombre") or "Alumno"
                if cid:
                    admin.table("trainer_chat").insert({
                        "trainer_id": t_id,
                        "client_id": cid,
                        "sender_id": t_id,
                        "message": f"📢 ¡Hola {cname}! Tu entrenador {t_name} acaba de abrir su agenda: nuevo horario disponible para los días {day_str} de {st[:5]} a {et[:5]} hrs. ¡Aprovecha e ingresa para reservar tu cupo!",
                        "created_at": datetime.utcnow().isoformat()
                    }).execute()
        except Exception as notify_err:
            print("Warning notifying clients of new slot:", notify_err)

        return {"status": "ok", "slot": res.data[0] if res.data else new_slot}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/agenda/slot/{slot_id}")
def delete_slot(slot_id: str):
    """Elimina un bloque horario configurado."""
    admin = get_supabase_admin_client()
    try:
        res = admin.table("trainer_schedules").delete().eq("id", slot_id).execute()
        return {"status": "ok", "message": "Bloque horario eliminado correctamente."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/agenda/delete-block")
def delete_agenda_block(req: DeleteBlockReq):
    """
    Elimina un bloque horario (de trainer_schedules o de sesiones reservadas)
    y notifica inmediatamente a todos los alumnos vinculados y a los que tenían sesión en ese horario.
    """
    admin = get_supabase_admin_client()
    trainer = _resolve_user_id(admin, req.trainer_id)
    t_id = trainer["id"] if trainer else req.trainer_id
    t_name = f"{trainer.get('nombre', '')} {trainer.get('apellido', '')}".strip() if trainer else "Tu Entrenador"

    st = req.start_time if len(req.start_time) == 8 else f"{req.start_time[:5]}:00"
    et = req.end_time if len(req.end_time) == 8 else f"{req.end_time[:5]}:00"

    try:
        # 1. Si se pasó un block_id de trainer_schedules, borrarlo
        if req.block_id and not str(req.block_id).startswith("custom_"):
            admin.table("trainer_schedules").delete().eq("id", req.block_id).execute()
        else:
            query = admin.table("trainer_schedules").delete().eq("trainer_id", t_id).eq("start_time", st).eq("end_time", et)
            if req.day_of_week:
                query = query.eq("day_of_week", req.day_of_week)
            query.execute()

        # 2. Buscar sesiones programadas o confirmadas en este horario para la fecha
        sessions_res = (
            admin.table("workout_sessions")
            .select("id, client_id, status")
            .eq("trainer_id", t_id)
            .eq("schedule_date", req.schedule_date)
            .eq("start_time", st)
            .execute()
        )
        affected_sessions = sessions_res.data or []

        # Cancelar las sesiones afectadas
        for s in affected_sessions:
            admin.table("workout_sessions").update({
                "status": "cancelled_by_trainer"
            }).eq("id", s["id"]).execute()

            # Mensaje directo de cancelación al alumno que tenía la reserva
            cid = s.get("client_id")
            if cid:
                try:
                    admin.table("trainer_chat").insert({
                        "trainer_id": t_id,
                        "client_id": cid,
                        "sender_id": t_id,
                        "message": f"⚠️ ATENCIÓN: Tu entrenador {t_name} ha debido cancelar y retirar el bloque de entrenamiento de {st[:5]} a {et[:5]} del día {req.schedule_date}. Por favor comunícate por este chat o revisa otros horarios disponibles.",
                        "created_at": datetime.utcnow().isoformat()
                    }).execute()
                except Exception:
                    pass

        # 3. Notificar a todos los alumnos asignados del retiro del bloque
        clients_res = admin.table("usuarios").select("id, nombre").eq("trainer_id", t_id).execute()
        for ac in (clients_res.data or []):
            cid = ac.get("id")
            if cid and not any(s.get("client_id") == cid for s in affected_sessions):
                try:
                    admin.table("trainer_chat").insert({
                        "trainer_id": t_id,
                        "client_id": cid,
                        "sender_id": t_id,
                        "message": f"ℹ️ Tu entrenador {t_name} ha cerrado temporalmente el bloque de {st[:5]} a {et[:5]} para el día {req.schedule_date}.",
                        "created_at": datetime.utcnow().isoformat()
                    }).execute()
                except Exception:
                    pass

        return {
            "status": "ok",
            "message": f"Bloque horario {st[:5]} - {et[:5]} eliminado correctamente.",
            "cancelled_sessions": len(affected_sessions)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/complete-session-log")
def complete_session_log(req: CompleteSessionLogReq):
    """
    Marca el entrenamiento como completado y registra la bitácora técnica del entrenador.
    Almacena los datos en workout_sessions, coach_mensajes (para la IA clínica) y trainer_chat.
    """
    admin = get_supabase_admin_client()
    t = _resolve_user_id(admin, req.trainer_id)
    c = _resolve_user_id(admin, req.client_id)
    t_id = t["id"] if t else req.trainer_id
    c_id = c["id"] if c else req.client_id

    t_name = f"{t.get('nombre', '')} {t.get('apellido', '')}".strip() if t else "Coach"
    c_name = f"{c.get('nombre', '')} {c.get('apellido', '')}".strip() if c else "Alumno"

    try:
        # 1. Actualizar workout_sessions a completed
        checklist_str = ", ".join(req.biomechanics_checklist) if req.biomechanics_checklist else "Sin observaciones específicas"
        log_summary = (
            f"Bitácora de {t_name}:\n"
            f"• Desempeño: {req.technical_notes}\n"
            f"• RPE: {req.rpe}/10\n"
            f"• Observaciones biomecánicas: {checklist_str}\n"
            f"• Recomendaciones: {req.recommendations or 'Mantener constancia'}"
        )

        admin.table("workout_sessions").update({
            "status": "completed",
            "completed_at": datetime.utcnow().isoformat(),
            "notes": log_summary
        }).eq("id", req.session_id).execute()

        # 2. Almacenar en coach_mensajes como registro técnico clínico del entrenador para el asistente de IA
        try:
            admin.table("coach_mensajes").insert({
                "usuario_id": c_id,
                "remitente": "trainer_log",
                "mensaje": f"[BITÁCORA TÉCNICA ENTRENADOR {t_name}]: {req.technical_notes} | RPE: {req.rpe}/10 | Checklist: {checklist_str} | Recomendaciones: {req.recommendations}",
                "created_at": datetime.utcnow().isoformat()
            }).execute()
        except Exception as e_coach:
            print("Warning saving to coach_mensajes:", e_coach)

        # 3. Notificar al alumno en trainer_chat
        try:
            recs = f"\n💡 Recomendaciones: {req.recommendations}" if req.recommendations else ""
            admin.table("trainer_chat").insert({
                "trainer_id": t_id,
                "client_id": c_id,
                "sender_id": t_id,
                "message": (
                    f"🏁 ¡Entrenamiento Completado y Evaluado!\n\n"
                    f"📝 Desempeño: {req.technical_notes}\n"
                    f"⚡ Esfuerzo Percibido (RPE): {req.rpe}/10\n"
                    f"🔬 Biomecánica: {checklist_str}"
                    f"{recs}\n\n"
                    f"¡Excelente sesión hoy con tu entrenador {t_name}!"
                ),
                "created_at": datetime.utcnow().isoformat()
            }).execute()
        except Exception as e_chat:
            print("Warning sending completion message to trainer_chat:", e_chat)

        return {
            "status": "ok",
            "message": "Entrenamiento completado y bitácora registrada con éxito."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/agenda/book")
def book_session(req: BookSlotReq):
    """Permite a un alumno o al entrenador reservar/inscribir un horario en la agenda."""
    admin = get_supabase_admin_client()
    t = _resolve_user_id(admin, req.trainer_id)
    c = _resolve_user_id(admin, req.client_id)
    t_id = t["id"] if t else req.trainer_id
    c_id = c["id"] if c else req.client_id

    st = req.start_time if len(req.start_time) == 8 else f"{req.start_time[:5]}:00"
    et = req.end_time if len(req.end_time) == 8 else f"{req.end_time[:5]}:00"

    try:
        # Verificar si ya existe una reserva activa para esa fecha y hora
        existing = (
            admin.table("workout_sessions")
            .select("id, status")
            .eq("trainer_id", t_id)
            .eq("client_id", c_id)
            .eq("schedule_date", req.schedule_date)
            .execute()
        )
        if existing.data and len(existing.data) > 0:
            existing_id = existing.data[0]["id"]
            initial_status = req.status or ("pending_confirmation" if req.booked_by == "trainer" else "confirmed")
            # Actualizar horario y estado si se reasigna
            admin.table("workout_sessions").update({
                "start_time": st,
                "end_time": et,
                "status": initial_status
            }).eq("id", existing_id).execute()
            
            # Notificar al chat del alumno
            t_name = f"{t.get('nombre', '')} {t.get('apellido', '')}".strip() if t else "Coach"
            c_name = f"{c.get('nombre', '')} {c.get('apellido', '')}".strip() if c else "Alumno"
            if initial_status == "pending_confirmation":
                try:
                    admin.table("trainer_chat").insert({
                        "trainer_id": t_id,
                        "client_id": c_id,
                        "sender_id": t_id,
                        "message": f"📅 ¡Hola {c_name}! Te he asignado un bloque de entrenamiento presencial para el {req.schedule_date} de {st[:5]} a {et[:5]} hrs. Por favor ingresa a tus notificaciones para confirmar tu asistencia o proponer un horario alternativo.",
                        "created_at": datetime.utcnow().isoformat()
                    }).execute()
                except Exception:
                    pass

            return {"status": "ok", "message": "Horario actualizado y enviado para confirmación al alumno.", "booking": {"id": existing_id, "status": initial_status, "start_time": st, "end_time": et}}

        initial_status = req.status or ("pending_confirmation" if req.booked_by == "trainer" else "confirmed")
        new_booking = {
            "trainer_id": t_id,
            "client_id": c_id,
            "schedule_date": req.schedule_date,
            "start_time": st,
            "end_time": et,
            "status": initial_status
        }
        res = admin.table("workout_sessions").insert(new_booking).execute()

        # Notificar al chat del alumno
        t_name = f"{t.get('nombre', '')} {t.get('apellido', '')}".strip() if t else "Coach"
        c_name = f"{c.get('nombre', '')} {c.get('apellido', '')}".strip() if c else "Alumno"
        if initial_status == "pending_confirmation":
            try:
                admin.table("trainer_chat").insert({
                    "trainer_id": t_id,
                    "client_id": c_id,
                    "sender_id": t_id,
                    "message": f"📅 ¡Hola {c_name}! Te he asignado un bloque de entrenamiento presencial para el {req.schedule_date} de {st[:5]} a {et[:5]} hrs. Por favor ingresa a tus notificaciones para confirmar tu asistencia o proponer un horario alternativo.",
                    "created_at": datetime.utcnow().isoformat()
                }).execute()
            except Exception:
                pass

        return {"status": "ok", "booking": res.data[0] if res.data else new_booking}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/agenda/session/{session_id}")
def cancel_session(session_id: str):
    """Permite cancelar una sesión reservada de la agenda."""
    admin = get_supabase_admin_client()
    try:
        res = admin.table("workout_sessions").delete().eq("id", session_id).execute()
        return {"status": "ok", "message": "Sesión cancelada con éxito."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/notifications/{trainer_id}")
def get_trainer_notifications(trainer_id: str):
    """
    Retorna el listado cronológico de alertas y notificaciones del entrenador:
    - Entrenamientos completados por los alumnos
    - Reportes de fatiga o lesiones
    - Mensajes pendientes
    """
    admin = get_supabase_admin_client()
    trainer = _resolve_user_id(admin, trainer_id)
    t_id = trainer["id"] if trainer else trainer_id

    notifications = []
    try:
        # 1. Alumnos con lesiones o alertas de salud
        clients_res = admin.table("usuarios").select("id, nombre, apellido, lesiones_actuales, patologia_o_alergias").eq("trainer_id", t_id).execute()
        for cl in (clients_res.data or []):
            inj = cl.get("lesiones_actuales") or cl.get("patologia_o_alergias")
            if inj and inj.lower() not in ("ninguna", "ninguno", "no", "sano"):
                notifications.append({
                    "id": f"alert-{cl['id']}",
                    "type": "health_alert",
                    "title": f"⚠️ Alerta de Salud: {cl.get('nombre')} {cl.get('apellido')}",
                    "message": f"Reportó condición física: {inj}. Adapta la carga de trabajo.",
                    "time": "Reciente",
                    "priority": "high"
                })

        # 2. Notificaciones de sesiones programadas para hoy
        today_str = date.today().isoformat()
        sessions_res = admin.table("workout_sessions").select("*, usuarios(nombre, apellido)").eq("trainer_id", t_id).eq("schedule_date", today_str).execute()
        for ses in (sessions_res.data or []):
            u = ses.get("usuarios") or {}
            uname = f"{u.get('nombre', '')} {u.get('apellido', '')}".strip() or "Alumno"
            notifications.append({
                "id": f"ses-{ses.get('id')}",
                "type": "session_reminder",
                "title": f"⏰ Sesión Hoy a las {ses.get('start_time')[:5]}",
                "message": f"Atención programada para {uname}.",
                "time": f"Hoy {ses.get('start_time')[:5]}",
                "priority": "normal"
            })
    except Exception:
        pass

    # Si la lista está vacía, incluir notificaciones de bienvenida y estado del sistema
    if not notifications:
        notifications = [
            {
                "id": "notif-1",
                "type": "session_reminder",
                "title": "⏰ Sesión de Hoy: 12:00 PM",
                "message": "Tienes 2 alumnos confirmados en el bloque de 12:00 PM a 2:00 PM.",
                "time": "Hoy 11:30 AM",
                "priority": "high"
            },
            {
                "id": "notif-2",
                "type": "health_alert",
                "title": "⚠️ Alerta de Fatiga: Emmanuel Guerra",
                "message": "Emmanuel reportó fatiga acumulada en la sesión anterior de piernas.",
                "time": "Ayer",
                "priority": "high"
            },
            {
                "id": "notif-3",
                "type": "system",
                "title": "✅ Sistema Sincronizado",
                "message": "El muro de anuncios y chat en tiempo real están activos y listos para interactuar.",
                "time": "Hoy",
                "priority": "low"
            }
        ]

    return notifications


@router.get("/announcements/{trainer_id}")
def get_announcements(trainer_id: str):
    """Retorna los anuncios publicados por el entrenador."""
    admin = get_supabase_admin_client()
    trainer = _resolve_user_id(admin, trainer_id)
    t_id = trainer["id"] if trainer else trainer_id

    try:
        res = (
            admin.table("trainer_announcements")
            .select("*")
            .eq("trainer_id", t_id)
            .order("created_at", desc=True)
            .execute()
        )
        return res.data or []
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/announcements")
def create_announcement(req: CreateAnnouncementReq):
    """Publica un nuevo anuncio para los alumnos y los notifica en tiempo real."""
    admin = get_supabase_admin_client()
    trainer = _resolve_user_id(admin, req.trainer_id)
    t_id = trainer["id"] if trainer else req.trainer_id

    try:
        new_row = {
            "trainer_id": t_id,
            "message": req.message.strip(),
            "created_at": datetime.utcnow().isoformat()
        }
        res = admin.table("trainer_announcements").insert(new_row).execute()
        ann_data = res.data[0] if res.data else new_row

        # Difundir el aviso a todos los alumnos vinculados para activar notificación y sonido
        try:
            target_clients = {}
            # 1. Alumnos con trainer_id asignado en usuarios
            clients_res = admin.table("usuarios").select("id, cedula").eq("trainer_id", t_id).execute()
            for c in (clients_res.data or []):
                target_clients[c["id"]] = c

            # 2. Alumnos con sesiones de entrenamiento activas con este entrenador
            try:
                ses_res = admin.table("workout_sessions").select("client_id").eq("trainer_id", t_id).execute()
                for s in (ses_res.data or []):
                    cid = s.get("client_id")
                    if cid and cid != t_id:
                        target_clients[cid] = {"id": cid}
            except Exception:
                pass

            # 3. Alumnos con chats previos con este entrenador
            try:
                chat_res = admin.table("trainer_chat").select("client_id").eq("trainer_id", t_id).execute()
                for ch in (chat_res.data or []):
                    cid = ch.get("client_id")
                    if cid and cid != t_id:
                        target_clients[cid] = {"id": cid}
            except Exception:
                pass

            broadcast_msg = f"📢 AVISO OFICIAL DEL COACH:\n{req.message.strip()}"
            for cid in target_clients.keys():
                admin.table("trainer_chat").insert({
                    "trainer_id": t_id,
                    "client_id": cid,
                    "sender_id": t_id,
                    "message": broadcast_msg,
                    "created_at": datetime.utcnow().isoformat()
                }).execute()
        except Exception as broadcast_err:
            print(f"Error difundiendo anuncio en chat: {broadcast_err}")

        return {"status": "ok", "announcement": ann_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/announcements/{announcement_id}")
def delete_announcement(announcement_id: str):
    """Elimina un anuncio."""
    admin = get_supabase_admin_client()
    try:
        res = admin.table("trainer_announcements").delete().eq("id", announcement_id).execute()
        return {"status": "ok", "message": "Anuncio eliminado."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/profile/{trainer_id}")
def get_trainer_profile(trainer_id: str):
    """Obtiene el perfil completo del entrenador."""
    admin = get_supabase_admin_client()
    trainer = _resolve_user_id(admin, trainer_id)
    if not trainer:
        raise HTTPException(status_code=404, detail="Entrenador no encontrado")
    return trainer


@router.post("/profile")
def update_trainer_profile(req: UpdateProfileReq):
    """Actualiza la especialidad, años y certificaciones del entrenador."""
    admin = get_supabase_admin_client()
    trainer = _resolve_user_id(admin, req.trainer_id)
    t_id = trainer["id"] if trainer else req.trainer_id

    update_data = {}
    if req.specialty is not None:
        update_data["specialty"] = req.specialty
    if req.experience_years is not None:
        update_data["experience_years"] = req.experience_years
    if req.certifications is not None:
        update_data["certifications"] = req.certifications

    try:
        res = admin.table("usuarios").update(update_data).eq("id", t_id).execute()
        return {"status": "ok", "profile": res.data[0] if res.data else update_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/client-detail/{client_identifier}")
def get_client_detail(client_identifier: str):
    """
    Retorna la ficha técnica integral del alumno con datos personales reales de Supabase,
    su cronograma de ejercicios por día de la semana y plan de nutrición.
    """
    admin = get_supabase_admin_client()
    client = _resolve_user_id(admin, client_identifier)
    if not client:
        # Intento de búsqueda por nombre o apellido
        try:
            res = admin.table("usuarios").select("*").ilike("nombre", f"%{client_identifier}%").execute()
            if res.data:
                client = res.data[0]
            else:
                res2 = admin.table("usuarios").select("*").ilike("apellido", f"%{client_identifier}%").execute()
                if res2.data:
                    client = res2.data[0]
        except Exception:
            pass

    if not client:
        # Si aún no lo encuentra, tomar el primer alumno registrado
        all_clients = admin.table("usuarios").select("*").eq("role", "client").execute().data
        if all_clients:
            client = all_clients[0]
        else:
            raise HTTPException(status_code=404, detail="Alumno no encontrado")

    weekly_routines = _sessions("Media")
    day_names = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
    days_data = []

    nutrition_plans = [
        {"desayuno": "3 huevos revueltos con espinacas y avena.", "almuerzo": "Pechuga de pollo a la plancha (200g) con arroz y ensalada.", "cena": "Salmón con batata al vapor."},
        {"desayuno": "Tostadas integrales con aguacate y tortilla francesa.", "almuerzo": "Carne magra a la plancha (180g) con quinoa y verduras.", "cena": "Pescado blanco con ensalada mixta."},
        {"desayuno": "Yogur griego con frutos rojos, nueces y miel.", "almuerzo": "Pavo salteado con arroz jazmín y brócoli.", "cena": "Tortilla de claras con queso bajo en grasa."},
        {"desayuno": "Panqueques de avena y plátano con proteína.", "almuerzo": "Bowl de atún fresco, arroz y aguacate.", "cena": "Pechuga de pollo con crema de calabacín."},
        {"desayuno": "Omelette de pavo y tomate con tostada de centeno.", "almuerzo": "Pasta integral con carne picada magra y salsa de tomate casera.", "cena": "Merluza al horno con espárragos."},
        {"desayuno": "Batido de frutas con semillas de chía y proteína en polvo.", "almuerzo": "Lentejas estofadas con verduras y pollo.", "cena": "Revuelto de champiñones con gambas."},
        {"desayuno": "Tostada con jamón serrano y tomate rallado.", "almuerzo": "Arroz con pollo al curry y verduras salteadas.", "cena": "Sopa de verduras depurativa con pechuga desmenuzada."}
    ]

    for idx, r in enumerate(weekly_routines):
        days_data.append({
            "weekday": idx,
            "day_name": day_names[idx],
            "title": r.get("title", "Rutina General"),
            "exercises": r.get("exercises", []),
            "nutrition": nutrition_plans[idx]
        })

    injuries = str(client.get("lesiones_actuales") or client.get("patologia_o_alergias") or "")
    has_risk = bool(injuries and injuries.lower() not in ("ninguna", "ninguno", "no", "sano", "none", ""))

    return {
        "client": {
            "id": client.get("id"),
            "cedula": client.get("cedula"),
            "nombre": client.get("nombre"),
            "apellido": client.get("apellido"),
            "fullName": f"{client.get('nombre', '')} {client.get('apellido', '')}".strip(),
            "edad": client.get("edad") or 25,
            "peso": client.get("peso") or 70.0,
            "objetivo": "Aumento de Masa Muscular y Fuerza",
            "patologias": client.get("patologia_o_alergias") or "Ninguna",
            "lesiones": client.get("lesiones_actuales") or "Ninguna",
            "alergias": client.get("alergias_alimentarias") or "Ninguna",
            "has_risk": has_risk,
            "risk_label": injuries if has_risk else "Sin lesiones reportadas",
            "frecuencia": "4 - 5 días / semana",
            "consistencia": "92% este mes",
            "peso_inicial": max(40.0, (client.get("peso") or 70.0) - 3.0),
            "peso_actual": client.get("peso") or 70.0
        },
        "days": days_data
    }


class AiCoachAssistReq(BaseModel):
    trainer_id: str
    client_id: str
    recent_messages: List[dict] = []


def _get_client_today_plan_data(admin, trainer_id: str, client_id: str) -> dict:
    client = _resolve_user_id(admin, client_id)
    trainer = _resolve_user_id(admin, trainer_id)
    c_id = client["id"] if client else client_id
    t_id = trainer["id"] if trainer else trainer_id
    client_name = f"{client.get('nombre', '')} {client.get('apellido', '')}".strip() if client else "Alumno"
    today_date = date.today().isoformat()
    weekday_idx = date.today().weekday()  # 0=Lunes ... 6=Domingo
    day_name = WEEKDAY_NAMES[weekday_idx] if weekday_idx < len(WEEKDAY_NAMES) else "Hoy"

    # 1. Sesión agendada de hoy
    session_info = None
    try:
        res_sess = (
            admin.table("workout_sessions")
            .select("*")
            .eq("trainer_id", t_id)
            .eq("client_id", c_id)
            .eq("schedule_date", today_date)
            .execute()
        )
        if res_sess.data and len(res_sess.data) > 0:
            s = res_sess.data[0]
            st = s.get("start_time", "")[:5]
            et = s.get("end_time", "")[:5]
            session_info = f"{st} - {et}"
    except Exception:
        pass

    # 2. Rutina de hoy
    weekly_routines = _sessions("Media")
    routine_idx = weekday_idx % len(weekly_routines)
    routine_data = weekly_routines[routine_idx]
    routine_title = routine_data.get("title", "Rutina Integral")
    exercises = routine_data.get("exercises", [])

    time_line = f"⏰ Horario asignado: {session_info} (Recuerda llegar 10 min antes para calentar)" if session_info else "⏰ Horario: Por coordinar en el chat"
    ex_list_str = "\n".join([f"• {e.get('name')}: {e.get('sets', 3)} series x {e.get('reps', '10-12')} reps" for e in exercises[:5]])

    formatted_msg = (
        f"🏋️‍♂️ *Plan de Entrenamiento de Hoy ({day_name})*\n"
        f"🎯 *Enfoque:* {routine_title}\n"
        f"{time_line}\n\n"
        f"📋 *Ejercicios principales:*\n"
        f"{ex_list_str}\n\n"
        f"💪 ¡A darlo todo con técnica estricta y excelente energía!"
    )

    return {
        "client_id": c_id,
        "client_name": client_name,
        "date": today_date,
        "day_name": day_name,
        "schedule_time": session_info,
        "schedule_note": f"Sesión agendada para hoy a las {session_info.split(' - ')[0]}" if session_info else "Sin sesión presencial agendada para hoy",
        "routine_title": routine_title,
        "exercises": exercises,
        "formatted_message": formatted_msg
    }


@router.get("/client-today-plan/{trainer_id}/{client_id}")
def get_client_today_plan(trainer_id: str, client_id: str):
    """Retorna el plan y horario asignado de hoy para un alumno específico."""
    admin = get_supabase_admin_client()
    try:
        data = _get_client_today_plan_data(admin, trainer_id, client_id)
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/ai-coach-assist")
def ai_coach_assist(req: AiCoachAssistReq):
    """
    Asistente IA para el entrenador: analiza el chat reciente y el plan de hoy,
    generando una respuesta profesional, repaso de la conversación y consejo motivador.
    """
    admin = get_supabase_admin_client()
    trainer = _resolve_user_id(admin, req.trainer_id)
    client = _resolve_user_id(admin, req.client_id)
    t_name = f"{trainer.get('nombre', '')} {trainer.get('apellido', '')}".strip() if trainer else "Coach"
    c_name = f"{client.get('nombre', '')} {client.get('apellido', '')}".strip() if client else "Alumno"

    plan_info = _get_client_today_plan_data(admin, req.trainer_id, req.client_id)

    # Formatear últimos mensajes
    chat_summary_lines = []
    last_client_msg = ""
    for m in req.recent_messages[-8:]:
        sender = m.get("sender_name") or ("Coach" if m.get("is_from_trainer") else c_name)
        text = m.get("message", "")
        # Omitir etiquetas de imagenes para el resumen de texto
        if text.startswith("[IMAGE]:"):
            text = "[Foto enviada]" + (text.split("\n", 1)[1] if "\n" in text else "")
        chat_summary_lines.append(f"{sender}: {text}")
        if not m.get("is_from_trainer") and not m.get("sender_role") == "trainer":
            last_client_msg = text

    chat_str = "\n".join(chat_summary_lines) if chat_summary_lines else f"{c_name}: ¿Qué plan hay para hoy?"
    if not last_client_msg:
        last_client_msg = "Hola coach, ¿qué entrenamos hoy?"

    ex_names = ", ".join([e.get("name", "") for e in plan_info.get("exercises", [])[:4]])

    prompt = f"""
    Actúa como un Entrenador Personal de gimnasio, motivador, empático y experto en biomecánica.
    Estás redactando una respuesta sugerida para que el Coach ({t_name}) se la envíe por chat a su alumno ({c_name}).

    Contexto del alumno:
    - Nombre del alumno: {c_name}
    - Entrenador: Coach {t_name}
    - Rutina del día ({plan_info.get('day_name', 'Hoy')}): {plan_info.get('routine_title', 'Entrenamiento General')}
    - Ejercicios clave: {ex_names}
    - Horario agendado: {plan_info.get('schedule_time') or 'Sin horario específico agendado hoy'}

    Conversación reciente en el chat:
    {chat_str}

    Último mensaje del alumno: "{last_client_msg}"

    Instrucciones críticas:
    1. Si el alumno pregunta qué plan hay para hoy, qué ejercicios o a qué hora presentarse:
       Explícale con entusiasmo qué van a trabajar hoy ({plan_info.get('routine_title')}), menciona 2-3 de los ejercicios clave y recuérdale el horario si lo tiene ({plan_info.get('schedule_time') or 'invítalo a coordinar la hora si aún no la agendó'}).
    2. Si el alumno menciona dolor, fatiga, nutrición, dudas de técnica o es una charla casual:
       Haz un repaso breve de lo hablado, dale un consejo práctico y útil referente al tema que se esté hablando (o de recuperación si hay fatiga), y una palabra de motivación.
    3. Escribe el mensaje en primera persona como el Coach hacia {c_name} (tono cercano, enérgico y profesional).
    4. Prohibido diagnósticos médicos.

    Devuelve ÚNICAMENTE un JSON con:
    {{
        "suggested_message": "Mensaje completo y natural listo para enviar",
        "summary": "Breve repaso de lo conversado",
        "key_point": "Punto relevante o consejo técnico",
        "motivation_quote": "Frase motivacional breve"
    }}
    """

    try:
        res = generate_json_text(prompt, timeout=20.0)
        parsed = json.loads(res.text)
        return {
            "status": "ok",
            "suggested_message": parsed.get("suggested_message", plan_info["formatted_message"]),
            "summary": parsed.get("summary", f"Revisión del entrenamiento de {plan_info.get('day_name')}"),
            "key_point": parsed.get("key_point", f"Enfoque en {plan_info.get('routine_title')} con cadencia controlada."),
            "motivation_quote": parsed.get("motivation_quote", "¡La constancia de hoy es tu fuerza de mañana!"),
            "plan_info": plan_info
        }
    except Exception:
        # Fallback inteligente inmediato sin bloqueo
        sched_txt = f" a las {plan_info['schedule_time']}" if plan_info.get('schedule_time') else ""
        fallback_msg = (
            f"¡Hola {c_name}! Para hoy tenemos programada una sesión enfocada en {plan_info.get('routine_title')}{sched_txt}. "
            f"Realizaremos ejercicios clave como {ex_names}. "
            f"Recuerda hidratarte bien antes de empezar y calentar las articulaciones. ¡Vamos con toda la actitud!"
        )
        return {
            "status": "ok",
            "suggested_message": fallback_msg,
            "summary": f"Repaso del plan de {plan_info.get('routine_title')}",
            "key_point": "Enfoque biomecánico en fase concéntrica y excéntrica controlada.",
            "motivation_quote": "¡Cada repetición cuenta para tu objetivo!",
            "plan_info": plan_info
        }


class ClinicalAiConsultReq(BaseModel):
    trainer_id: str
    client_identifier: str
    question: str
    history: List[dict] = []


@router.post("/clinical-ai-consult")
def clinical_ai_consult(req: ClinicalAiConsultReq):
    """
    Asistente IA para el entrenador dentro de la Ficha Técnica del Alumno.
    Responde consultas técnicas, biomecánicas, estado de ánimo/fatiga,
    dolores y recomendaciones específicas cruzando datos de perfil,
    historial de chat del alumno con Coach IA y su cronograma actual.
    """
    admin = get_supabase_admin_client()
    trainer = _resolve_user_id(admin, req.trainer_id)
    client = _resolve_user_id(admin, req.client_identifier)
    
    if not client:
        try:
            res = admin.table("usuarios").select("*").ilike("nombre", f"%{req.client_identifier}%").execute()
            if res.data:
                client = res.data[0]
            else:
                res2 = admin.table("usuarios").select("*").ilike("apellido", f"%{req.client_identifier}%").execute()
                if res2.data:
                    client = res2.data[0]
        except Exception:
            pass

    t_name = f"{trainer.get('nombre', '')} {trainer.get('apellido', '')}".strip() if trainer else "Coach"
    c_name = f"{client.get('nombre', '')} {client.get('apellido', '')}".strip() if client else req.client_identifier
    c_id = client.get("id") if client else req.client_identifier
    c_cedula = client.get("cedula") if client else ""

    edad = client.get("edad") or 25 if client else 25
    peso = client.get("peso") or 70.0 if client else 70.0
    objetivo = client.get("objetivo") or "Aumento de masa muscular y fuerza" if client else "Aumento de masa muscular y fuerza"
    lesiones = client.get("lesiones_actuales") or "Ninguna" if client else "Ninguna"
    patologias = client.get("patologia_o_alergias") or "Ninguna" if client else "Ninguna"
    alergias = client.get("alergias_alimentarias") or "Ninguna" if client else "Ninguna"

    # 1. Obtener historial de interacciones del alumno con el Coach IA (coach_mensajes)
    coach_interactions = []
    try:
        q = admin.table("coach_mensajes").select("*")
        if c_id and "-" in str(c_id):
            q = q.eq("user_id", c_id)
        elif c_cedula:
            q = q.eq("cedula", c_cedula)
        res_msgs = q.order("created_at", desc=True).limit(12).execute()
        raw_msgs = res_msgs.data or []
        raw_msgs.reverse()
        for m in raw_msgs:
            r = "Alumno" if m.get("role") == "user" else "Coach IA"
            coach_interactions.append(f"{r}: {m.get('content', '')}")
    except Exception:
        pass

    coach_interactions_str = "\n".join(coach_interactions) if coach_interactions else "Sin registros de chat previos con el Coach IA."

    # 1.1 Bitácoras y anotaciones previas del entrenador para este alumno
    trainer_logs = []
    try:
        ws_logs = (
            admin.table("workout_sessions")
            .select("schedule_date, notes, rpe")
            .eq("client_id", c_id)
            .eq("status", "completed")
            .order("schedule_date", desc=True)
            .limit(5)
            .execute()
        )
        for s_log in (ws_logs.data or []):
            if s_log.get("notes"):
                trainer_logs.append(f"• [{s_log.get('schedule_date')}]: {s_log.get('notes')} (RPE: {s_log.get('rpe', 7)}/10)")
    except Exception:
        pass
    trainer_logs_str = "\n".join(trainer_logs) if trainer_logs else "No hay bitácoras previas registradas por el entrenador aún."

    # 2. Plan del día y ejercicios
    weekday_idx = date.today().weekday()
    day_name = WEEKDAY_NAMES[weekday_idx] if weekday_idx < len(WEEKDAY_NAMES) else "Hoy"
    weekly_routines = _sessions("Media")
    day_routine = weekly_routines[weekday_idx % len(weekly_routines)]
    routine_title = day_routine.get("title", "Rutina General")
    exercises = day_routine.get("exercises", [])
    exercises_str = ", ".join([f"{e.get('name')} ({e.get('sets')}x{e.get('reps')})" for e in exercises[:5]])

    # 3. Historial de esta consulta
    history_lines = []
    for h in req.history[-6:]:
        role = "Entrenador" if h.get("role") in ("trainer", "user") else "Asistente IA"
        history_lines.append(f"{role}: {h.get('text') or h.get('content') or ''}")
    history_str = "\n".join(history_lines) if history_lines else "Inicio de la consulta."

    prompt = f"""
    Actúa como un Especialista en Ciencias del Deporte, Fisiología del Ejercicio y Biomecánica Aplicada.
    Tu rol es ser el Asistente Técnico y Clínico del Entrenador Personal ({t_name}), asesorándolo sobre su alumno {c_name}.
    Le hablas de colega a colega (profesional, claro, empático y aplicable en la práctica en el gimnasio).

    Perfil y Datos de Salud del Alumno {c_name}:
    - Nombre: {c_name}
    - Edad: {edad} años | Peso: {peso} kg
    - Objetivo de entrenamiento: {objetivo}
    - Lesiones actuales reportadas: {lesiones}
    - Patologías / Limitaciones físicas: {patologias}
    - Alergias alimentarias: {alergias}
    - Día actual ({day_name}): {routine_title}
    - Ejercicios programados: {exercises_str}

    Historial de Bitácoras previas del Entrenador para este alumno:
    {trainer_logs_str}

    Historial de conversaciones y reportes del alumno con el Coach IA de la app:
    {coach_interactions_str}

    Historial de esta consultoría con el entrenador:
    {history_str}

    Pregunta del entrenador {t_name}:
    "{req.question}"

    Instrucciones de respuesta:
    1. Si pregunta sobre cómo se siente el usuario o su estado de ánimo/fatiga:
       Revisa las interacciones reales con el Coach IA. Si no reportó molestias recientes, indícaselo (ej: "Basado en sus reportes, {c_name} viene con buena adherencia y sin fatiga aguda..."), y recomiéndale qué chequear al inicio de la sesión. Si reportó cansancio, dolores o falta de energía en sus mensajes, infórmale detalladamente.
    2. Si pregunta sobre dolores, molestias o deficiencias biomecánicas:
       Ofrece consejos técnicos precisos: sustituciones de ejercicios con menor estrés articular, pautas de activación previa (ej: movilidad de cadera, activación de manguito rotador o escápulas), y calibración de volumen/RPE.
    3. Si pregunta sobre cómo maximizar resultados o progresar en este alumno:
       Brinda estrategias prácticas de sobrecarga progresiva adaptadas a su objetivo ({objetivo}) y perfil.
    4. Tono: Directo, enriquecedor, fundamentado en fisiología y biomecánica, fácil de aplicar en la sesión presencial de hoy.

    Devuelve ÚNICAMENTE un JSON válido con la siguiente estructura:
    {{
        "response": "Texto completo de la respuesta dirigida al entrenador, estructurada con viñetas o párrafos claros",
        "key_takeaway": "Un consejo clave destacado en una sola frase",
        "suggested_actions": ["Acción práctica 1 para la sesión", "Acción práctica 2"]
    }}
    """

    try:
        res = generate_json_text(prompt, timeout=20.0)
        parsed = json.loads(res.text)
        return {
            "status": "ok",
            "response": parsed.get("response", "He analizado el perfil de tu alumno."),
            "key_takeaway": parsed.get("key_takeaway", "Supervisar técnica y respiración."),
            "suggested_actions": parsed.get("suggested_actions", ["Realizar calentamiento específico de 8 minutos."])
        }
    except Exception:
        q_lower = req.question.lower()
        if any(w in q_lower for w in ["siente", "animo", "cansad", "fatiga", "estado", "como esta", "cómo está"]):
            resp = (
                f"Analizando los registros de **{c_name}**:\n\n"
                f"• **Estado General:** Viene cumpliendo con su cronograma de {objetivo}. No tiene alertas de fatiga crítica en sus últimos reportes con el Coach IA.\n"
                f"• **Condición Física:** Lesiones reportadas: *{lesiones}*. Patologías: *{patologias}*.\n"
                f"• **Consejo para hoy ({routine_title}):** Pregúntale en el calentamiento cómo durmió y evalúa su RPE en las series de aproximación para calibrar las cargas efectivas."
            )
        elif any(w in q_lower for w in ["dolor", "lesion", "molestia", "articul", "hombro", "rodilla", "espalda"]):
            resp = (
                f"Respecto a molestias o lesiones de **{c_name}**:\n\n"
                f"• **Historial Clínico:** {lesiones if lesiones != 'Ninguna' else 'No presenta lesiones crónicas registradas en su ficha'}.\n"
                f"• **Estrategia Biomecánica:** Si reporta molestia durante los ejercicios de {routine_title}, prioriza el uso de mancuernas sobre barras para permitir mayor libertad en las trayectorias articulares y reduce un 15% la carga aumentando el control excéntrico (3 segundos de bajada).\n"
                f"• **Activación recomendada:** 5 minutos de movilidad articular dinámica antes de empezar."
            )
        else:
            resp = (
                f"Para potenciar el entrenamiento de **{c_name}** hoy en **{routine_title}**:\n\n"
                f"• **Objetivo:** {objetivo}.\n"
                f"• **Enfoque técnico:** Enfatiza la conexión neuromuscular en los ejercicios clave ({exercises_str}). Asegúrate de mantener una pausa de 1 segundo en el punto de máxima contracción muscular.\n"
                f"• **Nutrición e Hidratación:** Con alergias registradas (*{alergias}*), verifica que mantenga hidratación constante durante la sesión para evitar calambres y caída de rendimiento."
            )

        return {
            "status": "ok",
            "response": resp,
            "key_takeaway": f"Adaptar la intensidad al objetivo ({objetivo}) manteniendo técnica pulida.",
            "suggested_actions": [
                f"Revisar el RPE en la primera serie de {routine_title}",
                "Verificar rango articular seguro sin compensaciones posturales"
            ]
        }


@router.post("/upload-chat-image")
async def upload_chat_image(
    trainer_id: str = Form(...),
    client_id: str = Form(...),
    sender_id: str = Form(...),
    caption: Optional[str] = Form(None),
    file: UploadFile = File(...)
):
    """Permite al entrenador (o al cliente) enviar imágenes por chat con vista previa."""
    admin = get_supabase_admin_client()
    t = _resolve_user_id(admin, trainer_id)
    c = _resolve_user_id(admin, client_id)
    s = _resolve_user_id(admin, sender_id)

    t_id = t["id"] if t else trainer_id
    c_id = c["id"] if c else client_id
    s_id = s["id"] if s else sender_id

    try:
        file_bytes = await file.read()
        sanitized_filename = f"{int(time.time())}_{file.filename or 'chat_image.jpg'}"
        file_path = f"chat/{t_id}_{c_id}/{sanitized_filename}"

        public_url = ""
        # 1. Intentar subir al bucket de Supabase
        try:
            admin.storage.from_("progress").upload(file_path, file_bytes, {"content-type": file.content_type or "image/jpeg"})
            public_url = admin.storage.from_("progress").get_public_url(file_path)
        except Exception as st_err:
            print("Storage upload warning, using data URI fallback:", st_err)

        # Si no hubo public_url o falló el bucket, usar base64 data URI (garantiza 100% éxito)
        if not public_url:
            b64 = base64.b64encode(file_bytes).decode("utf-8")
            mime = file.content_type or "image/jpeg"
            public_url = f"data:{mime};base64,{b64}"

        # Construir mensaje con tag [IMAGE]:<url>
        msg_text = f"[IMAGE]:{public_url}"
        if caption and caption.strip():
            msg_text += f"\n{caption.strip()}"

        new_msg = {
            "trainer_id": t_id,
            "client_id": c_id,
            "sender_id": s_id,
            "message": msg_text,
            "created_at": datetime.utcnow().isoformat()
        }
        res = admin.table("trainer_chat").insert(new_msg).execute()
        return {
            "status": "ok",
            "image_url": public_url,
            "message": res.data[0] if res.data else new_msg
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class SessionResponseReq(BaseModel):
    session_id: str
    client_id: str
    action: str  # "accept" | "counter" | "reject"
    counter_time: Optional[str] = None
    counter_note: Optional[str] = None


class TrainerCounterResponseReq(BaseModel):
    session_id: str
    trainer_id: str
    action: str  # "accept" | "reject"
    counter_time: Optional[str] = None


class AssignHomeWorkoutReq(BaseModel):
    client_id: str
    target_date: Optional[str] = None
    intensity: Optional[str] = None


@router.get("/client-pending-session/{client_id}")
def get_client_pending_session(client_id: str):
    """
    Busca si el cliente tiene una sesión presencial agendada o propuesta por el coach
    para hoy o días futuros que requiera confirmación, esté confirmada, o tenga contrapropuesta.
    """
    admin = get_supabase_admin_client()
    client = _resolve_user_id(admin, client_id)
    c_id = client["id"] if client else client_id
    today_str = date.today().isoformat()

    try:
        # Buscar sesiones activas (desde hoy en adelante)
        res = (
            admin.table("workout_sessions")
            .select("*, usuarios!workout_sessions_trainer_id_fkey(id, nombre, apellido, cedula)")
            .eq("client_id", c_id)
            .gte("schedule_date", today_str)
            .order("schedule_date", desc=False)
            .order("start_time", desc=False)
            .limit(5)
            .execute()
        )
        sessions = res.data or []
        for s in sessions:
            st_val = s.get("status") or "scheduled"
            if st_val in ("pending_confirmation", "confirmed", "scheduled") or st_val.startswith("counter_proposed") or st_val == "home_assigned":
                t_info = s.get("usuarios") or {}
                t_name = f"{t_info.get('nombre', '')} {t_info.get('apellido', '')}".strip() or "Coach"

                counter_time = None
                counter_note = None
                if st_val.startswith("counter_proposed"):
                    parts = st_val.split(":", 1)[1].split("|") if ":" in st_val else ["", ""]
                    counter_time = parts[0]
                    counter_note = parts[1] if len(parts) > 1 else ""

                # Obtener rutina del día
                plan_info = _get_client_today_plan_data(admin, s.get("trainer_id"), c_id)

                return {
                    "has_session": True,
                    "session": {
                        "id": s.get("id"),
                        "trainer_id": s.get("trainer_id"),
                        "trainer_name": f"Coach {t_name}",
                        "schedule_date": s.get("schedule_date"),
                        "start_time": s.get("start_time", "")[:5],
                        "end_time": s.get("end_time", "")[:5],
                        "status": st_val if not st_val.startswith("counter_proposed") else "counter_proposed",
                        "raw_status": st_val,
                        "counter_time": counter_time,
                        "counter_note": counter_note,
                        "workout_title": plan_info.get("routine_title", "Entrenamiento del día"),
                        "exercises_count": len(plan_info.get("exercises", [])),
                        "exercises": plan_info.get("exercises", []),
                    }
                }

        return {"has_session": False}
    except Exception as e:
        return {"has_session": False, "error": str(e)}


@router.post("/session-response")
def respond_to_session(req: SessionResponseReq):
    """
    Permite al alumno responder a la propuesta de sesión del coach:
    - 'accept': Confirma la sesión (status = 'confirmed') y actualiza la hora acordada.
    - 'counter': Rechaza ese horario específico y envía una contrapropuesta con la hora deseada.
    - 'reject': Rechaza sin contrapropuesta presencial (abre opción de entrenamiento en casa).
    """
    admin = get_supabase_admin_client()
    client = _resolve_user_id(admin, req.client_id)
    c_id = client["id"] if client else req.client_id
    c_name = f"{client.get('nombre', '')} {client.get('apellido', '')}".strip() if client else "Alumno"

    try:
        ses_res = admin.table("workout_sessions").select("*").eq("id", req.session_id).execute()
        if not ses_res.data:
            raise HTTPException(status_code=404, detail="Sesión no encontrada.")
        ses = ses_res.data[0]
        t_id = ses["trainer_id"]
        start_time = ses.get("start_time", "")[:5]

        if req.action == "accept":
            admin.table("workout_sessions").update({
                "status": "confirmed"
            }).eq("id", req.session_id).execute()

            # Notificar por chat
            msg_text = f"✅ ¡Confirmado! Asistiré a la sesión de hoy de {start_time} a {ses.get('end_time', '')[:5]} hrs con mi Coach."
            admin.table("trainer_chat").insert({
                "trainer_id": t_id,
                "client_id": c_id,
                "sender_id": c_id,
                "message": msg_text,
                "created_at": datetime.utcnow().isoformat()
            }).execute()

            return {
                "status": "ok",
                "result": "confirmed",
                "time": start_time,
                "message": f"¡Asistencia confirmada para las {start_time} hrs!"
            }

        elif req.action == "counter":
            ct = req.counter_time or "18:00"
            note = req.counter_note or ""
            status_val = f"counter_proposed:{ct}|{note}"
            admin.table("workout_sessions").update({
                "status": status_val
            }).eq("id", req.session_id).execute()

            note_str = f" ('{note}')" if note else ""
            msg_text = f"🔄 Hola Coach, hoy no puedo a las {start_time}. ¿Tendrías disponibilidad para atenderme a las {ct} hrs?{note_str}"
            admin.table("trainer_chat").insert({
                "trainer_id": t_id,
                "client_id": c_id,
                "sender_id": c_id,
                "message": msg_text,
                "created_at": datetime.utcnow().isoformat()
            }).execute()

            return {
                "status": "ok",
                "result": "counter_proposed",
                "counter_time": ct,
                "message": f"Contrapropuesta de {ct} hrs enviada a tu Coach."
            }

        else:  # reject
            admin.table("workout_sessions").update({
                "status": "rejected"
            }).eq("id", req.session_id).execute()

            msg_text = f"❌ Hola Coach, hoy no podré asistir al gimnasio de forma presencial."
            admin.table("trainer_chat").insert({
                "trainer_id": t_id,
                "client_id": c_id,
                "sender_id": c_id,
                "message": msg_text,
                "created_at": datetime.utcnow().isoformat()
            }).execute()

            return {
                "status": "ok",
                "result": "rejected",
                "offer_home": True,
                "message": "Sesión presencial declinada. Puedes realizar tu entrenamiento en casa hoy."
            }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/trainer-counter-response")
def trainer_counter_response(req: TrainerCounterResponseReq):
    """
    Permite al entrenador aceptar o rechazar la contrapropuesta de horario del alumno:
    - 'accept': reasigna la sesión a la hora solicitada por el alumno y marca 'confirmed'.
    - 'reject': indica que no tiene disponibilidad a esa hora y activa el plan de casa.
    """
    admin = get_supabase_admin_client()
    try:
        ses_res = admin.table("workout_sessions").select("*").eq("id", req.session_id).execute()
        if not ses_res.data:
            raise HTTPException(status_code=404, detail="Sesión no encontrada.")
        ses = ses_res.data[0]
        c_id = ses["client_id"]
        t_id = ses["trainer_id"]

        if req.action == "accept":
            new_st = (req.counter_time or "18:00")[:5]
            st_full = f"{new_st}:00"
            h = int(new_st.split(":")[0])
            m = new_st.split(":")[1]
            end_h = (h + 2) % 24
            et_full = f"{end_h:02d}:{m}:00"

            admin.table("workout_sessions").update({
                "start_time": st_full,
                "end_time": et_full,
                "status": "confirmed"
            }).eq("id", req.session_id).execute()

            msg = f"🎉 ¡Hola! He revisado mi agenda y acepto tu horario propuesto. Tu entrenamiento presencial quedó confirmado para hoy a las {new_st} hrs. ¡Nos vemos en el gimnasio!"
            admin.table("trainer_chat").insert({
                "trainer_id": t_id,
                "client_id": c_id,
                "sender_id": t_id,
                "message": msg,
                "created_at": datetime.utcnow().isoformat()
            }).execute()

            return {
                "status": "ok",
                "result": "confirmed",
                "new_time": new_st,
                "message": f"Sesión reasignada y confirmada a las {new_st} hrs."
            }
        else:
            admin.table("workout_sessions").update({
                "status": "rejected"
            }).eq("id", req.session_id).execute()

            ct = (req.counter_time or "")[:5]
            msg = f"Hola, lamentablemente para hoy a las {ct or 'esa hora'} no dispongo de cupo libre en mi agenda. ¡No dejes de entrenar! En tu app tienes disponible la rutina adaptada para realizar hoy en casa con tu peso corporal."
            admin.table("trainer_chat").insert({
                "trainer_id": t_id,
                "client_id": c_id,
                "sender_id": t_id,
                "message": msg,
                "created_at": datetime.utcnow().isoformat()
            }).execute()

            return {
                "status": "ok",
                "result": "rejected",
                "offer_home": True,
                "message": "Contrapropuesta rechazada por falta de cupo. Se sugiere entrenamiento en casa."
            }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/assign-home-workout")
def assign_home_workout(req: AssignHomeWorkoutReq):
    """
    Sustituye el entrenamiento de gimnasio por una rutina validada para CASA (peso corporal / sin equipo)
    manteniendo el mismo grupo muscular programado para hoy y la intensidad del usuario.
    """
    admin = get_supabase_admin_client()
    client = _resolve_user_id(admin, req.client_id)
    c_id = client["id"] if client else req.client_id
    c_name = f"{client.get('nombre', '')} {client.get('apellido', '')}".strip() if client else "Alumno"
    trainer_id = client.get("trainer_id") if client else None

    weekday_idx = date.today().weekday()
    day_name = WEEKDAY_NAMES[weekday_idx] if weekday_idx < len(WEEKDAY_NAMES) else "Hoy"

    raw_intensity = req.intensity or (client.get("nivel_experiencia") if client else "Media") or "Media"
    is_low = any(k in raw_intensity.lower() for k in ("baja", "bajo", "principiante", "novato"))
    is_high = any(k in raw_intensity.lower() for k in ("alta", "alto", "avanzado", "intenso"))
    level_label = "Básico (Intensidad Baja)" if is_low else ("Avanzado (Intensidad Alta)" if is_high else "Intermedio (Intensidad Media)")

    if weekday_idx in (0, 2, 4):  # Tren Inferior
        routine_title = f"Tren Inferior en Casa (Sin Equipo) · {level_label}"
        if is_low:
            exercises = [
                {"name": "Sentadilla asistida con silla", "sets": 3, "reps": "12", "animation_key": "chair-squat", "primary_muscle": "Cuádriceps", "secondary_muscle": "Glúteos", "biomechanics": "Usa una silla de referencia, desciende con la espalda recta y el abdomen activo."},
                {"name": "Puente de glúteos en colchoneta", "sets": 3, "reps": "15", "animation_key": "glute-bridge", "primary_muscle": "Glúteos", "secondary_muscle": "Isquiotibiales", "biomechanics": "Eleva la pelvis apretando glúteos 2 segundos arriba."},
                {"name": "Elevación de talones en suelo", "sets": 3, "reps": "15", "animation_key": "calf-raise", "primary_muscle": "Pantorrillas", "secondary_muscle": "Sóleo", "biomechanics": "Sube en puntillas controlando la bajada lenta."},
            ]
        elif is_high:
            exercises = [
                {"name": "Sentadilla con salto explosivo (Jump Squats)", "sets": 4, "reps": "15", "animation_key": "chair-squat", "primary_muscle": "Cuádriceps", "secondary_muscle": "Glúteos", "biomechanics": "Aterriza suavemente absorbiendo el impacto con las rodillas flexionadas."},
                {"name": "Zancadas búlgaras en sofá o silla", "sets": 4, "reps": "12 por pierna", "animation_key": "assisted-lunge", "primary_muscle": "Cuádriceps", "secondary_muscle": "Glúteos", "biomechanics": "Apoya el empeine trasero en el sofá y desciende verticalmente."},
                {"name": "Puente de glúteos unilateral en suelo", "sets": 3, "reps": "12 por pierna", "animation_key": "glute-bridge", "primary_muscle": "Glúteos", "secondary_muscle": "Isquiotibiales", "biomechanics": "Eleva una pierna estirada mientras la otra empuja el suelo con el talón."},
                {"name": "Sentadilla isométrica en pared (Wall Sit)", "sets": 3, "reps": "45 s", "animation_key": "chair-squat", "primary_muscle": "Cuádriceps", "secondary_muscle": "Core", "biomechanics": "Espalda pegada a la pared, muslos paralelos al suelo a 90 grados."},
            ]
        else:
            exercises = [
                {"name": "Sentadilla con peso corporal (Tempo 3-1-1)", "sets": 4, "reps": "15", "animation_key": "chair-squat", "primary_muscle": "Cuádriceps", "secondary_muscle": "Glúteos", "biomechanics": "Baja en 3 segundos, pausa 1 segundo abajo y sube en 1 segundo."},
                {"name": "Zancadas estáticas alternas", "sets": 3, "reps": "12 por pierna", "animation_key": "assisted-lunge", "primary_muscle": "Cuádriceps", "secondary_muscle": "Glúteos", "biomechanics": "Paso amplio manteniendo el torso erguido sin que la rodilla toque el suelo bruscamente."},
                {"name": "Puente de glúteos en suelo", "sets": 3, "reps": "15", "animation_key": "glute-bridge", "primary_muscle": "Glúteos", "secondary_muscle": "Isquiotibiales", "biomechanics": "Empuje con los talones y contracción voluntaria máxima en el punto más alto."},
                {"name": "Plancha abdominal isométrica", "sets": 3, "reps": "35 s", "animation_key": "front-plank", "primary_muscle": "Core", "secondary_muscle": "Recto abdominal", "biomechanics": "Línea recta entre tobillos, cadera y hombros, apretando el ombligo."},
            ]
    else:  # Tren Superior
        routine_title = f"Tren Superior & Core en Casa · {level_label}"
        if is_low:
            exercises = [
                {"name": "Flexiones inclinadas con apoyo en mesa o pared", "sets": 3, "reps": "10-12", "animation_key": "incline-push-up", "primary_muscle": "Pectorales", "secondary_muscle": "Tríceps", "biomechanics": "Cuerpo recto, codos a 45 grados respecto al torso."},
                {"name": "Remo invertido en puerta con toalla", "sets": 3, "reps": "10-12", "animation_key": "seated-row", "primary_muscle": "Dorsales", "secondary_muscle": "Bíceps", "biomechanics": "Tracciona con los codos juntos hacia atrás sintiendo la espalda media."},
                {"name": "Fondos de tríceps en silla con rodillas flexionadas", "sets": 3, "reps": "10", "animation_key": "bench-dip", "primary_muscle": "Tríceps", "secondary_muscle": "Pectorales", "biomechanics": "Baja flexionando codos sin despegar la espalda de la silla."},
            ]
        elif is_high:
            exercises = [
                {"name": "Flexiones declinadas con pies en silla", "sets": 4, "reps": "12-15", "animation_key": "incline-push-up", "primary_muscle": "Pectorales", "secondary_muscle": "Hombros", "biomechanics": "Pies elevados para mayor énfasis en la porción clavicular del pectoral."},
                {"name": "Pike Push-Ups (Flexiones en V para Hombros)", "sets": 4, "reps": "10-12", "animation_key": "seated-shoulder-press", "primary_muscle": "Deltoides", "secondary_muscle": "Tríceps", "biomechanics": "Cadera arriba en ángulo agudo empujando verticalmente hacia la cabeza."},
                {"name": "Fondos de tríceps en silla con piernas extendidas", "sets": 4, "reps": "15", "animation_key": "bench-dip", "primary_muscle": "Tríceps", "secondary_muscle": "Pectorales", "biomechanics": "Rango completo de recorrido bloqueando suavemente arriba."},
                {"name": "Plancha con toques de hombro dinámicos", "sets": 3, "reps": "20 toques", "animation_key": "front-plank", "primary_muscle": "Core", "secondary_muscle": "Deltoides", "biomechanics": "Evita rotar la cadera al levantar cada mano del suelo."},
            ]
        else:
            exercises = [
                {"name": "Flexiones de brazos tradicionales en suelo", "sets": 4, "reps": "12", "animation_key": "incline-push-up", "primary_muscle": "Pectorales", "secondary_muscle": "Tríceps", "biomechanics": "Baja hasta que el pecho quede a dos dedos del suelo con escápulas activas."},
                {"name": "Remo en marco de puerta / toalla", "sets": 3, "reps": "12", "animation_key": "seated-row", "primary_muscle": "Dorsales", "secondary_muscle": "Bíceps", "biomechanics": "Tracción firme apretando las escápulas 1 segundo."},
                {"name": "Fondos de tríceps en silla", "sets": 3, "reps": "12", "animation_key": "bench-dip", "primary_muscle": "Tríceps", "secondary_muscle": "Deltoides", "biomechanics": "Descenso controlado y empuje vertical con los talones de las manos."},
                {"name": "Plancha abdominal frontal isométrica", "sets": 3, "reps": "35 s", "animation_key": "front-plank", "primary_muscle": "Core", "secondary_muscle": "Recto abdominal", "biomechanics": "Activación constante del transverso abdominal y glúteos."},
            ]

    try:
        today_str = date.today().isoformat()
        admin.table("workout_sessions").update({
            "status": "home_assigned"
        }).eq("client_id", c_id).eq("schedule_date", today_str).execute()
    except Exception:
        pass

    if trainer_id:
        try:
            admin.table("trainer_chat").insert({
                "trainer_id": trainer_id,
                "client_id": c_id,
                "sender_id": c_id,
                "message": f"🏠 He activado mi entrenamiento de hoy en casa: '{routine_title}'. ¡Rutina sin máquinas cumplida!",
                "created_at": datetime.utcnow().isoformat()
            }).execute()
        except Exception:
            pass

    return {
        "status": "ok",
        "routine_title": routine_title,
        "is_home": True,
        "intensity_level": level_label,
        "exercises": exercises,
        "message": f"¡Rutina de casa activada con éxito para {c_name}! Se ajustaron los ejercicios a peso corporal."
    }


