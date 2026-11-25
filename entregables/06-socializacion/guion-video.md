# Socialización — guion del video

**Un video de unos 15 minutos para el docente, en lugar de la exposición en vivo (§9), con la autorización del docente.** Las preguntas y la
retroalimentación llegan por el formulario, que se envía junto con el enlace al video.
Participan todas las personas del equipo: `[COMPLETAR: quién narra o aparece en cada bloque]`.

Cada fila es un bloque del video. Lo que va entre comillas es la idea que se dice; no hace falta leerlo
literal, pero sí cubrir cada punto que pide el descriptor. Lo que se ve puede ser el teléfono grabado, una
captura de `entregables/07-guia-uso/capturas/` o del repositorio, o la persona hablando a cámara.

| # | Min | Bloque | Qué se ve | Qué decir (idea central) | Cubre del §9 |
|---|---|---|---|---|---|
| 1 | 0:00 | **DeclaraUCR**: su declaración jurada desde el teléfono | Ícono de la app, nombre, integrantes | "Llevamos al teléfono la parte del sistema que usa la persona docente." | — |
| 2 | 0:30 | El problema y quién lo vive | Una docente con dos cursos: clases, atención, planificación, un proyecto | "Cada ciclo la docente declara bajo juramento su horario. Los errores típicos: horas que no cuadran con la jornada y horarios que se traslapan." | Problema y personas usuarias |
| 3 | 1:30 | Qué cambió desde el Proyecto 1 | La matriz de mejoras §2 y §4 | "El docente nos pidió un nombre de rol que la gente reconozca: «Revisor» pasó a llamarse «Superior». Además revisamos nosotros el sistema: lo más importante que le faltaba era poder usarse desde el teléfono." | Mejoras del P1 |
| 4 | 3:00 | Qué hace la app y qué no | Tabla de procesos P1 → móvil (informe técnico §2.1) | "Los tres procesos de la declarante están completos en el teléfono; revisión y RRHH siguen en la web, que es donde tiene sentido." | Alcance |
| 5 | 4:00 | **Demostración** (6 min) | Pantalla del teléfono grabada (grabador de pantalla de Android o scrcpy) | Ver guion de la demostración abajo | Demostración |
| 6 | 10:00 | Cómo instalarla y entrar | Página del release v2.0.0+8, los pasos de instalación, la versión al pie del inicio de sesión | "Es un APK, no está en la tienda: así se instala, así se actualiza y así se vuelve a la versión anterior." | Instalación y acceso |
| 7 | 11:00 | Pruebas técnicas | 8 casos, 109 pruebas automatizadas, D-01 antes y después | "El recorrido encontró que salir con Atrás perdía cambios sin avisar; ahora la app pregunta." | Resultados técnicos |
| 8 | 12:00 | Pruebas con usuarios | Perfil de las 3 personas, éxito por tarea, facilidad promedio y **una frase textual** de una persona participante, tomada de la bitácora | `[COMPLETAR con los resultados de las sesiones]` | Resultados con usuarios |
| 9 | 13:30 | Lo que queda pendiente y por qué | `VALIDADA` en el cliente, zonaje solo consulta, sin conexión no se guarda | "Son decisiones, no olvidos: esto es lo que haríamos después y por qué no entró." | Dificultades y decisiones |
| 10 | 14:30 | Cierre y formulario | Enlace y QR del formulario en pantalla (`qr-formulario.svg`) | "Su opinión cambia la versión final: al menos dos mejoras van a salir de este formulario." | Instrumento |

**Publicación:** subir el video al Drive del equipo (o a YouTube como *no listado*) y enviar al docente, en un
mismo mensaje, el enlace al video y el del formulario. Anotar aquí: video `[COMPLETAR: enlace]`, enviado el
`[COMPLETAR: fecha]`.

## Guion de la demostración (6 minutos de video)

Preparación: el teléfono con la **2.0.0+8** instalada (ya dice «Superior»), sesión iniciada con la **declarante con cursos**, una
declaración del período **en borrador y sin puesto**, el modo avión a mano y la web del Proyecto 1 abierta con
el superior en otra pestaña. **Grabar la firma al final**, cuando todo lo demás ya salió bien: no se puede deshacer. Si un tramo sale mal se graba de nuevo; no hace falta una sola toma.

| Min | Paso | Qué se ve |
|---|---|---|
| 0:00 | Inicio | Seguimiento en *Elaboración*, horas por tipo |
| 0:30 | Abrir la declaración, elegir el puesto y tocar **Atrás** | Aparece *"¿Salir sin guardar?"* → **Seguir editando** → **Guardar borrador** |
| 1:15 | Horario: elegir *Atención*, tocar una media hora, luego mantener y deslizar | Sube "x h de y h"; tocar una clase muestra que no se mueve |
| 2:30 | **Ver resumen** con horas faltantes | "Hay N puntos por corregir", Validar apagado |
| 3:00 | Completar lo que falta (o abrir una ya completa) y **Validar** | Estado *Validada* |
| 3:45 | Modo avión → cambiar algo → **Guardar borrador** | Franja sin conexión, aviso y cambios en pantalla; quitar modo avión y guardar |
| 4:45 | **Firmar y enviar a mi superior** | Juramento, firma, seguimiento en *Superior* |
| 5:30 | En la web, con el superior | La misma declaración, versión y bitácora |

En la edición se pueden acelerar las esperas y marcar con un recuadro lo que se toca.

## Preguntas que conviene responder en el video

No hay ronda de preguntas en vivo, así que vale la pena contestarlas de una vez (en los bloques 4 y 9):

- *¿Por qué el superior no puede usar la app?* Porque su trabajo es revisar el PDF y varias declaraciones a la
  vez; en el teléfono eso sería peor que en la web. Y la app lo dice en lugar de dejarle entrar a medias.
- *¿Qué pasa si se cae la conexión a media declaración?* CP-07: no se guarda, se avisa y nada se pierde
  mientras la app siga abierta.
- *¿Quién garantiza que las horas son correctas?* El validador del P1 en la app, y las reglas de Firestore para
  el formato y los permisos. La pieza que falta es recalcular en el servidor (limitación conocida).
- *¿Es accesible?* Contraste AA con la paleta del Centro de Informática, letra grande sin cortes y, desde la
  2.0.0+7, la cuadrícula funciona con TalkBack.
