# AI Fitness Coach 1.0.7

## Correccion: la app no encontraba el servidor (ClientSocketException)
- El APK se estaba compilando sin `--dart-define=API_BASE_URL=...`, por lo que
  quedaba con el valor por defecto `http://127.0.0.1:8000`. En un telefono
  `127.0.0.1` apunta al propio telefono, no a la computadora, y por eso la
  consulta de version fallaba con `ClientSocketException`.
- La PC ya estaba bien: backend escuchando en `0.0.0.0:8000` y respondiendo.
- Nuevo script `scripts/build_and_publish.py`: sube la version, compila con la
  IP local correcta y regenera la pagina, todo en un solo comando.
  ```
  python scripts/build_and_publish.py
  AIFITNESS_HOST=192.168.31.50 python scripts/build_and_publish.py
  ```
- Como el APK guarda la URL en `flutter_secure_storage`, tambien se puede
  cambiar en caliente desde **Login -> "Servidor: ..."**.

---

# AI Fitness Coach 1.0.6

## El icono de perfil vive solo en Inicio
- Inicio tiene ahora una barra superior con el **icono de perfil** en la esquina
  superior derecha: ahi se entra a **Mi Perfil y Salud**.
- Se quito el icono de perfil de la barra del Coach y el boton que estaba en el
  cuerpo de Inicio, para que el acceso al perfil exista en un solo lugar.
- La barra del Coach conserva solo el boton de **Cronograma Semanal**.

## Sigue funcionando el control de actualizaciones
- Panel **Actualizaciones de la app** al final del Perfil, con el boton
  **Descargar e instalar**.
- Comprobacion automatica al abrir la app.
- Chip con la version en la pantalla de login.

---

# AI Fitness Coach 1.0.5

## El icono de perfil se unifica
- El acceso a **Mi Perfil y Salud** quedo disponible tambien desde Inicio.

---

# AI Fitness Coach 1.0.4

## Correccion: el enlace de descarga servia una version vieja
- La pagina de descarga apuntaba a un archivo "instalador" que se creo una sola
  vez y quedo congelado en la 1.0.0, por eso nunca aparecia la version nueva.
- Ahora apunta siempre a `app-release.apk`, que es el archivo que se regenera en
  cada compilacion.
- Nuevo script `scripts/update_download_page.py`: se ejecuta despues de
  `flutter build apk` y escribe la pagina con la version y tamano reales, ademas
  de borrar los APK obsoletos. Evita que el error se repita.

## El verificador de actualizaciones vive en el Perfil
- Al final del perfil esta el panel **Actualizaciones de la app**: muestra la
  version instalada, consulta la publicada y ofrece **Descargar e instalar**.
- El panel se auto-comprueba al abrirlo y el boton permite forzar la consulta.

## Sigue funcionando ademas
- Comprobacion automatica al abrir la app.
- Chip fijo con la version en la pantalla de login.

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
