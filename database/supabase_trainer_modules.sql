-- 1. Tabla para configurar los horarios base del entrenador
CREATE TABLE IF NOT EXISTS public.trainer_schedules (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    trainer_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL, -- 1=Lunes, 7=Domingo
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    max_capacity INT DEFAULT 2,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Tabla para las reservaciones y sesiones activas (El calendario real)
CREATE TABLE IF NOT EXISTS public.workout_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    client_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE,
    trainer_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE,
    schedule_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status VARCHAR(50) DEFAULT 'scheduled', -- 'scheduled', 'in_progress', 'completed'
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Tabla para el Muro de Anuncios del Entrenador
CREATE TABLE IF NOT EXISTS public.trainer_announcements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    trainer_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS (Row Level Security) básico
ALTER TABLE public.trainer_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainer_announcements ENABLE ROW LEVEL SECURITY;

-- Políticas permisivas para desarrollo rápido (luego se pueden restringir)
CREATE POLICY "Permitir todo a usuarios autenticados schedules" ON public.trainer_schedules FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Permitir todo a usuarios autenticados sessions" ON public.workout_sessions FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Permitir todo a usuarios autenticados announcements" ON public.trainer_announcements FOR ALL USING (auth.role() = 'authenticated');
