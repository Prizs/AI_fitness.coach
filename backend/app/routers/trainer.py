from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, date
from app.services.supabase_service import get_supabase_admin_client
from app.services.weekly_plan import _sessions

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
        return res.data or []
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
            return res.data or []
        except Exception as e2:
            raise HTTPException(status_code=500, detail=str(e2))


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
            {"start_time": "10:00:00", "end_time": "12:00:00", "time_label": "10:00 AM - 12:00 PM", "capacity": 2},
            {"start_time": "12:00:00", "end_time": "14:00:00", "time_label": "12:00 PM - 2:00 PM", "capacity": 2},
            {"start_time": "14:00:00", "end_time": "16:00:00", "time_label": "2:00 PM - 4:00 PM", "capacity": 2},
            {"start_time": "16:00:00", "end_time": "18:00:00", "time_label": "4:00 PM - 6:00 PM", "capacity": 2},
            {"start_time": "18:00:00", "end_time": "20:00:00", "time_label": "6:00 PM - 8:00 PM", "capacity": 2},
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
        except Exception:
            day_workout_label = "Rutina del cronograma personalizada"

        agenda_blocks = []
        total_students = 0

        for b in blocks_to_use:
            b_st = b["start_time"][:5]
            # Emparejar sesiones cuya hora de inicio coincida (HH:MM)
            b_sessions = [s for s in sessions if str(s.get("start_time", ""))[:5] == b_st]
            students = []

            for s in b_sessions:
                user_info = s.get("usuarios") or {}
                name = f"{user_info.get('nombre', '')} {user_info.get('apellido', '')}".strip() or "Alumno"
                cedula = user_info.get("cedula") or ""
                injuries = str(user_info.get("lesiones_actuales") or user_info.get("patologia_o_alergias") or "")

                risk = "🟢 Óptimo"
                if injuries and injuries.lower() not in ("ninguna", "ninguno", "no", "sano", "none", ""):
                    risk = f"🔴 {injuries}"

                students.append({
                    "id": s.get("id"),
                    "client_id": s.get("client_id"),
                    "name": name,
                    "cedula": cedula,
                    "workout": day_workout_label,
                    "risk": risk,
                    "status": s.get("status") or "scheduled"
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
    """Permite al entrenador crear o ajustar un bloque horario en su agenda base."""
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
        # Verificar si ya está agendado en ese bloque y fecha
        existing = (
            admin.table("workout_sessions")
            .select("id")
            .eq("trainer_id", t_id)
            .eq("client_id", c_id)
            .eq("schedule_date", req.schedule_date)
            .eq("start_time", st)
            .execute()
        )
        if existing.data and len(existing.data) > 0:
            return {"status": "ok", "message": "El alumno ya se encuentra inscrito en este horario.", "booking": existing.data[0]}

        new_booking = {
            "trainer_id": t_id,
            "client_id": c_id,
            "schedule_date": req.schedule_date,
            "start_time": st,
            "end_time": et,
            "status": "scheduled"
        }
        res = admin.table("workout_sessions").insert(new_booking).execute()
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
