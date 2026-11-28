# Socialización — guion del video

**Un video de unos 15 minutos para el docente, en lugar de la exposición en vivo (§9), con la autorización del docente.** Las preguntas y la
retroalimentación llegan por el formulario, que se envía junto con el enlace al video.
Participan las tres personas del equipo, cada una con unos 4 a 7 minutos:

| Integrante | Bloques | Tiempo aprox. | Por qué |
|---|---|---|---|
| **Cristopher** | 1 Presentación · 3 Mejoras desde el P1 · 4 Alcance · 7 Pruebas técnicas | 4 min | Hizo la matriz de mejoras, el informe técnico y el recorrido que encontró D-01 |
| **Lucía** | 2 El problema · 8 Pruebas con usuarios · 9 Pendientes · 10 Cierre | 4 min | Así aparece en el video con bloques propios; el 8 le toca si guía o anota una sesión |
| **Keity** | 5 Demostración · 6 Instalación | 7 min | Es la única con teléfono Android; además hizo la firma del release y el script del APK |

Cada fila es un bloque del video. Lo que va entre comillas es la idea que se dice; no hace falta leerlo
literal, pero sí cubrir cada punto que pide el descriptor. Lo que se ve puede ser el teléfono grabado, una
captura de `entregables/07-guia-uso/capturas/` o del repositorio, o la persona hablando a cámara.

| # | Min | Quién | Bloque | Qué se ve | Qué decir (idea central) | Cubre del §9 |
|---|---|---|---|---|---|---|
| 1 | 0:00 | Cristopher | **DeclaraUCR**: su declaración jurada desde el teléfono | Ícono de la app, nombre, integrantes | "Llevamos al teléfono la parte del sistema que usa la persona docente." | — |
| 2 | 0:30 | Lucía | El problema y quién lo vive | Una docente con dos cursos: clases, atención, planificación, un proyecto | "Cada ciclo la docente declara bajo juramento su horario. Los errores típicos: horas que no cuadran con la jornada y horarios que se traslapan." | Problema y personas usuarias |
| 3 | 1:30 | Cristopher | Qué cambió desde el Proyecto 1 | La matriz de mejoras §2 y §4 | "El docente nos pidió un nombre de rol que la gente reconozca: «Revisor» pasó a llamarse «Superior». Además revisamos nosotros el sistema: lo más importante que le faltaba era poder usarse desde el teléfono." | Mejoras del P1 |
| 4 | 3:00 | Cristopher | Qué hace la app y qué no | Tabla de procesos P1 → móvil (informe técnico §2.1) | "Los tres procesos de la declarante están completos en el teléfono; revisión y RRHH siguen en la web, que es donde tiene sentido." | Alcance |
| 5 | 4:00 | Keity | **Demostración** (6 min) | Pantalla del teléfono grabada (grabador de pantalla de Android o scrcpy) | Ver guion de la demostración abajo | Demostración |
| 6 | 10:00 | Keity | Cómo instalarla y entrar | Página del release v2.0.0+10, los pasos de instalación, la versión al pie del inicio de sesión | "Es un APK, no está en la tienda: así se instala, así se actualiza y así se vuelve a la versión anterior." | Instalación y acceso |
| 7 | 11:00 | Cristopher | Pruebas técnicas | 8 casos, 121 pruebas automatizadas, D-01 antes y después | "El recorrido encontró que salir con Atrás perdía cambios sin avisar; ahora la app pregunta." | Resultados técnicos |
| 8 | 12:00 | Lucía | Pruebas con usuarios | Perfil de las 3 personas, éxito por tarea, facilidad promedio y **una frase textual**: la de P3, docente: «como es celular se me perdía el tema de las horas de clase […] no sabía qué día ni qué hora me asignaron las HC»; después, la matriz U-03 a U-07 | `[COMPLETAR con los resultados de las sesiones]` y "Con lo que vimos cambiamos la app: el recorrido guiado, qué se ubica con cada toque, firmar justo después de validar y editar mis datos (versiones 2.0.0+8 a +10). Una docente que llenó esta declaración por años en Excel la hizo sin ayuda con el recorrido, y por lo que nos dijo agregamos el horario de sus clases arriba de los días y el juramento del formulario oficial." | Resultados con usuarios |
| 9 | 13:30 | Lucía | Lo que queda pendiente y por qué | `VALIDADA` en el cliente, zonaje solo consulta, sin conexión no se guarda | "Son decisiones, no olvidos: esto es lo que haríamos después y por qué no entró." | Dificultades y decisiones |
| 10 | 14:30 | Lucía | Cierre y formulario | Enlace y QR del formulario en pantalla (`qr-formulario.svg`) | "Su opinión cambia la versión final: al menos dos mejoras van a salir de este formulario." | Instrumento |

**Publicación:** subir el video al Drive del equipo (o a YouTube como *no listado*) y enviar al docente, en un
mismo mensaje, el enlace al video y el del formulario. Anotar aquí: video `[COMPLETAR: enlace]`, enviado el
`[COMPLETAR: fecha]`.

## Guion de la demostración (6 minutos de video)

Preparación: el teléfono con la **2.0.0+10** instalada (ya dice «Superior»), sesión iniciada con la **declarante con cursos**
(una cuenta del equipo, **no** la que se le entrega al docente: la firma no se deshace), una
declaración del período **III Ciclo - 2027** **en borrador y sin puesto**, el modo avión a mano y la web del Proyecto 1 abierta con
el superior en otra pestaña. **Grabar la firma al final**, cuando todo lo demás ya salió bien: no se puede deshacer. Si un tramo sale mal se graba de nuevo; no hace falta una sola toma.

**La graba y la narra Keity** (es la única con Android). Lo más cómodo: grabar primero la pantalla sin hablar
y después ponerle la voz encima en la edición. La narración es una frase corta por paso; no hay que llenar
cada segundo.

| Min | Paso | Qué se ve | Qué decir (idea central) |
|---|---|---|---|
| 0:00 | Recorrido guiado | Perfil › **Cómo funciona**: dos o tres pasos, una parte enfocada y el resto oscurecido | "La primera vez, la app enseña cada pantalla con una docente de ejemplo; se puede repetir desde el perfil." |
| 0:20 | Inicio | Seguimiento en *Elaboración*, horas por tipo | "Esta es la pantalla de inicio de una docente con sus cursos. Arriba ve en qué etapa va su declaración y cuántas horas lleva de cada tipo." |
| 0:30 | Abrir la declaración, elegir el puesto y tocar **Atrás** | Aparece *"¿Salir sin guardar?"* → **Seguir editando** → **Guardar borrador** | "Elijo el puesto y, sin querer, toco Atrás. Antes esto perdía los cambios sin avisar; ahora la app pregunta. Sigo editando y guardo el borrador." |
| 1:15 | Horario: tarjeta **Horario de sus clases**, elegir *Atención*, tocar una media hora, luego mantener y deslizar | Arriba, los días y horas de cada curso; sube "x h de y h"; tocar una clase muestra que no se mueve | "Arriba veo cuándo son mis clases, y toco un horario para abrir ese día. Para llenar el horario elijo el tipo de actividad, en este caso atención a estudiantes, y toco o deslizo sobre las medias horas. Arriba se ve cuánto llevo de lo que me corresponde. Las clases vienen fijas de la Coordinación, por eso no se pueden mover." |
| 2:30 | **Ver resumen** con horas faltantes | "Hay N puntos por corregir", Validar apagado | "Si reviso el resumen antes de terminar, la app me dice exactamente qué falta y no me deja validar todavía." |
| 3:00 | Completar lo que falta (o abrir una ya completa) y **Validar** | Estado *Validada* | "Completo las horas que faltaban y ahora sí puedo validar. Son las mismas reglas que usa el sistema web del Proyecto 1." |
| 3:45 | Modo avión → cambiar algo → **Guardar borrador** | Franja sin conexión, aviso y cambios en pantalla; quitar modo avión y guardar | "¿Y si se cae la conexión? Pongo modo avión y hago un cambio. La app avisa que no se pudo guardar, pero no pierdo nada: al volver la señal, guardo y listo." |
| 4:45 | **Firmar y enviar a mi superior** | Juramento, firma, seguimiento en *Superior* | "Por último, firmo bajo juramento y la envío a mi superior. El seguimiento ya muestra que está en manos del superior." |
| 5:30 | En la web, con el superior | La misma declaración, versión y bitácora | "Y así la ve el superior en la web: la misma declaración, con su versión y su bitácora. La app y la web comparten los mismos datos." |

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
