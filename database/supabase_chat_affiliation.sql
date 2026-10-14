-- 1. Tabla para afiliaciones (Requests y Activos)
CREATE TABLE IF NOT EXISTS public.trainer_clients (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    client_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE,
    trainer_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'active', 'rejected'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(client_id, trainer_id)
);

-- 2. Tabla para mensajería (Chat Entrenador - Alumno)
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    sender_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Permisos
ALTER TABLE public.trainer_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir todo a usuarios autenticados trainer_clients" ON public.trainer_clients FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Permitir todo a usuarios autenticados chat_messages" ON public.chat_messages FOR ALL USING (auth.role() = 'authenticated');
