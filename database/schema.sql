-- Base de datos relacional para AI Fitness Coach
-- Motor recomendado: PostgreSQL 17
-- Cliente recomendado para consultas: DBeaver Community

CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    cedula VARCHAR(10) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE perfil_usuario (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER NOT NULL UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    edad INTEGER NOT NULL CHECK (edad BETWEEN 12 AND 100),
    peso NUMERIC(5,2) NOT NULL CHECK (peso > 0),
    patologia_o_alergias TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE objetivos (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    objetivo VARCHAR(200) NOT NULL,
    nivel VARCHAR(50) NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE rutinas (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    fecha_inicio TIMESTAMP NOT NULL DEFAULT NOW(),
    estado VARCHAR(30) NOT NULL DEFAULT 'activa',
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE ejercicios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    categoria VARCHAR(80) NOT NULL,
    descripcion TEXT,
    video_url TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE rutina_ejercicios (
    id SERIAL PRIMARY KEY,
    rutina_id INTEGER NOT NULL REFERENCES rutinas(id) ON DELETE CASCADE,
    ejercicio_id INTEGER NOT NULL REFERENCES ejercicios(id) ON DELETE RESTRICT,
    dia_semana VARCHAR(20) NOT NULL,
    orden_ejercicio INTEGER NOT NULL,
    series INTEGER,
    repeticiones VARCHAR(30),
    descanso_segundos INTEGER,
    observaciones TEXT,
    UNIQUE (rutina_id, dia_semana, orden_ejercicio)
);

CREATE TABLE dieta_diaria (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha DATE NOT NULL,
    objetivo_dieta VARCHAR(200),
    notas TEXT,
    UNIQUE (usuario_id, fecha)
);

CREATE TABLE alimentos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    categoria VARCHAR(80) NOT NULL,
    descripcion TEXT,
    calorias INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE dieta_alimentos (
    id SERIAL PRIMARY KEY,
    dieta_diaria_id INTEGER NOT NULL REFERENCES dieta_diaria(id) ON DELETE CASCADE,
    alimento_id INTEGER NOT NULL REFERENCES alimentos(id) ON DELETE RESTRICT,
    tipo_comida VARCHAR(50) NOT NULL,
    hora_sugerida TIME,
    porcion VARCHAR(50),
    UNIQUE (dieta_diaria_id, tipo_comida, alimento_id)
);

CREATE TABLE coach_mensajes (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    rol VARCHAR(30) NOT NULL CHECK (rol IN ('usuario', 'coach', 'sistema')),
    mensaje TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE progreso_semanal (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha DATE NOT NULL,
    peso_actual NUMERIC(5,2),
    energia INTEGER,
    recuperacion INTEGER,
    observaciones TEXT,
    UNIQUE (usuario_id, fecha)
);

CREATE INDEX idx_perfil_usuario_usuario_id ON perfil_usuario(usuario_id);
CREATE INDEX idx_rutinas_usuario_id ON rutinas(usuario_id);
CREATE INDEX idx_rutina_ejercicios_rutina_id ON rutina_ejercicios(rutina_id);
CREATE INDEX idx_dieta_diaria_usuario_id ON dieta_diaria(usuario_id);
CREATE INDEX idx_coach_mensajes_usuario_id ON coach_mensajes(usuario_id);
CREATE INDEX idx_progreso_usuario_id ON progreso_semanal(usuario_id);

-- Comentarios de diseño:
-- 1) usuarios guarda credenciales de acceso.
-- 2) perfil_usuario guarda datos personales del atleta.
-- 3) objetivos define meta del usuario.
-- 4) rutinas y rutina_ejercicios gestionan la programación del entrenamiento.
-- 5) dieta_diaria y dieta_alimentos almacenan la recomendación nutricional.
-- 6) coach_mensajes permiten conservar conversaciones del asistente IA.
-- 7) progreso_semanal facilita la recalibración del plan y el seguimiento.
