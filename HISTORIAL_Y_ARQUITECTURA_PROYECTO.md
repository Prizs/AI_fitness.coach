# HISTORIAL COMPLETO, REQUERIMIENTOS Y ARQUITECTURA DEL PROYECTO
## AI Fitness Coach (Entrenador Inteligente y Nutrición Adaptativa)

Este documento registra todas las especificaciones técnicas, decisiones de arquitectura y módulos desarrollados a lo largo del proyecto para garantizar la total continuidad y comprensión del sistema.

---

### 1. OBJETIVO DEL SISTEMA
Plataforma integral de entrenamiento deportivo, planificación nutricional y acompañamiento con Inteligencia Artificial. Conecta a usuarios con rutinas hiper-personalizadas y permite la supervisión en tiempo real por parte de entrenadores personales certificados.

---

### 2. ARQUITECTURA Y FLUJOS PRINCIPALES

#### A. Flujo del Coach IA y Memoria Inteligente
1. **Cuestionario Inicial ("Enviar Estado Actual")**:
   - En lugar de generar rutinas genéricas a ciegas, el usuario completa un check-in rápido:
     * Estado Físico: *Bien / Enérgetico* o reporte de *Molestia / Dolor*.
     * Entorno y Equipo: *Gimnasio Comercial*, *Herramientas en Casa* o *Sin Herramientas*.
     * Intensidad Deseada: *Baja / Media / Alta*.
     * Nivel de Experiencia: *Novato / Intermedio / Avanzado*.
2. **Reconocimiento Empático Inmediato**:
   - La IA recibe el estado y nunca vuelve a preguntar datos ya respondidos.
   - Si el usuario reporta una molestia o lesión, la IA la aborda de entrada, excluyendo ejercicios que carguen esa articulación y sugiriendo trabajo correctivo.
3. **Preguntas de Seguimiento Clave**:
   - *Herramientas exactas*: Solo si entrena en casa y no estaban guardadas previamente.
   - *Grupo muscular a priorizar*: Qué área desea reforzar hoy (pecho, espalda, piernas, etc.).
   - *Tiempo disponible*: Duración de la sesión para calcular volumen y descansos (ej. 30 min, 45 min, 1 hora).
   - *Horarios de comidas*: Horas en las que come para sincronizar carbohidratos y proteínas pre/post entreno.
4. **Memoria Persistente de Herramientas por Usuario**:
   - Al indicar sus herramientas (ej. mancuernas de 10 kg), la IA las extrae (`extracted_equipment`) y la app las almacena en `user_equipment_<cedula>`.
   - En sesiones futuras, la IA recuerda automáticamente este equipo y **nunca vuelve a preguntarlo**, salvo que el usuario declare haber comprado equipo nuevo o ir al gimnasio.
   - **Regla estricta de coherencia biomecánica**: Si el usuario entrena en casa con mancuernas, la IA jamás propone caminadoras, poleas o prensas; solo mancuernas o calistenia.
5. **Planificación Multi-Semana Anticipada**:
   - Si el usuario ya tiene un plan activo en la semana actual (ej. 12/10 al 18/10), la IA reconoce las fechas vigentes y programa el nuevo plan para el ciclo siguiente sin pisar el entrenamiento en curso.
6. **Tarjetas Interactivas de Rutina y Nutrición**:
   - La respuesta del Coach renderiza ejercicios con previsualización biomecánica (GIFs) y botones de acción rápida: *"Agregar a Cronograma y Nutrición"* y *"Ver en 3D"*.

---

#### B. Módulo del Entrenador Personal (B2B / Supervisión)
1. **Ficha Técnica del Alumno en Tiempo Real**:
   - El entrenador asignado puede ver en detalle el cronograma de ejercicios y el menú alimenticio de su alumno.
2. **Alertas Visuales de Riesgo en Vivo (🔴)**:
   - Si un alumno reporta una molestia o lesión en su perfil o check-in, su nombre en la agenda y lista de alumnos del entrenador muestra una etiqueta de alerta roja inmediata para advertir al profesional antes de la sesión.
3. **Agenda y Solicitudes de Asesoría**:
   - Gestión de citas, confirmación de horarios y chat directo alumno-entrenador.

---

#### C. Nutrición y Sinergia Alimenticia
1. **Compatibilidad Bidireccional de Datos**:
   - Tanto la pantalla de *Nutrición* del usuario como la pestaña en la *Ficha del Entrenador* soportan de manera transparente tanto el formato de lista base del backend como el formato estructurado del Coach IA (`desayuno`, `almuerzo`, `cena`).
2. **Sinergia con la Intensidad**:
   - Alta intensidad = aumento de carbohidratos complejos y proteína magra post-entrenamiento.
   - Descanso o baja intensidad = menú ligero con grasas saludables y vegetales.

---

#### D. Sistema Dinámico de Notificaciones
1. **Aviso Anticipado de Caducidad de Plan**:
   - Al aproximarse el fin de semana (viernes, sábado o domingo), la app alerta al usuario que su ciclo está por terminar para que programe la siguiente semana con anticipación.
2. **Aviso de Cronograma Vacío**:
   - Si el usuario no tiene plan activo, la campana de inicio muestra un punto rojo y genera una alerta con acceso directo al Coach IA.
3. **Sesión de Hoy**:
   - Notificación diaria indicando la rutina asignada y la cantidad de ejercicios.

---

#### E. Seguridad, Failover y Autenticación
1. **Contraseña Universal de Auditoría**: `prueba123` activa para cualquier cuenta existente con soporte case-insensitive y sin conflicto de espacios.
2. **Failover de Servidores (Local <-> Render)**:
   - La aplicación móvil detecta caídas y permite alternar fluidamente entre `http://localhost:8000` y `https://ai-fitness-coach-818a.onrender.com`.
3. **Resiliencia de IA**:
   - Modo JSON nativo en Gemini + Regex extractor + Captura de texto libre en caso de anomalías para garantizar 100% de disponibilidad sin errores 503.
