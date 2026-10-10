-- 1. Añadir roles y vinculación a la tabla 'usuarios' existente
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'client',
ADD COLUMN IF NOT EXISTS trainer_id VARCHAR(50);

-- 2. Crear tabla para almacenar las fotos de progreso y el análisis de la IA
CREATE TABLE IF NOT EXISTS public.progress_photos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES public.usuarios(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    ai_analysis TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Crear tabla para el chat en vivo entre Entrenador y Cliente
CREATE TABLE IF NOT EXISTS public.trainer_chat (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id VARCHAR(50) REFERENCES public.usuarios(id) ON DELETE CASCADE,
    trainer_id VARCHAR(50) REFERENCES public.usuarios(id) ON DELETE CASCADE,
    sender_id VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
