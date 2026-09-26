# AI Fitness Coach 1.0.2

## Atlas anatomico de musculos
- Nueva pestana **Musculos** con un atlas anatomico real del cuerpo humano
  (vista frontal y posterior) en lugar del figureto dibujado a mano.
- El musculo agonista se resalta en rojo y el sinergista en ambar, leyendo
  `primary_muscle` y `secondary_muscle` del plan generado por la IA.
- Se puede tocar cualquier musculo para ver su nombre anatomico.
- La vista 3D sigue disponible en la segunda pestana.

## Rendimiento
- Rutinas y Nutricion ya no tardan: el plan se guarda en el telefono (6 horas)
  y ademas el backend lo cachea 30 minutos.
- Medicion: primera peticion 11 s, siguientes **0,003 s**.
- Boton de refrescar para forzar un plan nuevo cuando quieras.

## Chat del Coach
- El cuadro de escritura crece hacia abajo mientras escribes y empuja los
  mensajes hacia arriba, para poder leer lo que estas escribiendo.
- Enter crea una linea nueva; se envia con el boton.

## Actualizacion desde la misma app
- Busca, descarga e instala el APK sin salir: boton **Buscar actualizaciones**
  en la pantalla de login.
- La version publicada la consulta el backend en `/api/app/latest`.

## Other
- Failover a OpenRouter para no quedarse sin Coach por cuota de Gemini.
- La URL del servidor se puede cambiar desde el login.

Atlas anatomico: CC BY 4.0, Ryan Graves.
