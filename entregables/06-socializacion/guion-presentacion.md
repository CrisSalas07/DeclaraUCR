# Socialización — guion de la presentación

**15 minutos de presentación y demostración + 10 minutos de preguntas (§9).**
Participan todas las personas del equipo: `[COMPLETAR: quién presenta cada bloque]`.

Este guion se convierte en diapositivas (una fila = una diapositiva). Lo que va entre comillas es lo que se
dice; no hace falta leerlo literal, pero sí cubrir cada punto que pide el descriptor.

| # | Min | Diapositiva | Qué mostrar | Qué decir (idea central) | Cubre del §9 |
|---|---|---|---|---|---|
| 1 | 0:00 | **DeclaraUCR** — su declaración jurada desde el teléfono | Firma UCR, nombre, equipo | "Llevamos al teléfono la parte del sistema que usa la persona docente." | — |
| 2 | 0:30 | El problema y quién lo vive | Una docente con dos cursos: clases, atención, planificación, un proyecto | "Cada ciclo la docente declara bajo juramento su horario. Los errores típicos: horas que no cuadran con la jornada y horarios que se traslapan." | Problema y personas usuarias |
| 3 | 1:30 | Qué cambió desde el Proyecto 1 | La evaluación del P1 no pidió cambios; se muestra lo que el equipo encontró al revisarlo (matriz §2: llevarlo al teléfono, `VALIDADA` en el cliente) y las correcciones de las pruebas (T-01 a T-07) | "El docente no nos pidió cambios, así que revisamos nosotros el sistema: lo más importante que le faltaba era poder usarse desde el teléfono." | Mejoras del P1 |
| 4 | 3:00 | Qué hace la app y qué no | Tabla de procesos P1 → móvil (informe técnico §2.1) | "Los tres procesos de la declarante están completos en el teléfono; revisión y RRHH siguen en la web, que es donde tiene sentido." | Alcance |
| 5 | 4:00 | **Demo en vivo** (6 min) | Teléfono proyectado (scrcpy o cámara) | Ver guion de demo abajo | Demostración |
| 6 | 10:00 | Cómo instalarla y entrar | QR al release, los 4 pasos de instalación, versión al pie del login | "Es un APK, no está en la tienda: así se instala, así se actualiza y así se vuelve a la versión anterior." | Instalación y acceso |
| 7 | 11:00 | Pruebas técnicas | 8 casos (7 aprobados + CP-08), 109 pruebas automatizadas, defectos D-01 y D-02 con antes y después | "El recorrido encontró que salir con Atrás perdía cambios sin avisar; ahora la app pregunta." | Resultados técnicos |
| 8 | 12:00 | Pruebas con usuarios | Perfil de las 3 personas, éxito por tarea, facilidad promedio, el hallazgo principal y su corrección | `[COMPLETAR con los resultados de las sesiones]` | Resultados con usuarios |
| 9 | 13:30 | Lo que queda pendiente y por qué | `VALIDADA` en el cliente, zonaje solo consulta, sin conexión no se guarda | "Son decisiones, no olvidos: esto es lo que haríamos después y por qué no entró." | Dificultades y decisiones |
| 10 | 14:30 | Gracias + formulario | QR al formulario de retroalimentación | "Su opinión cambia la versión final: al menos dos mejoras van a salir de este formulario." | Instrumento |

## Guion de la demo (6 minutos)

Preparación: el teléfono con la **2.0.0+7** instalada, sesión iniciada con la **declarante con cursos**, una
declaración del período **en borrador y sin puesto**, el modo avión a mano y la web del Proyecto 1 abierta con
el revisor en otra pestaña. **Ensayar una vez antes con la misma cuenta**, porque la firma no se puede deshacer.

| Min | Paso | Qué se ve |
|---|---|---|
| 0:00 | Inicio | Seguimiento en *Elaboración*, horas por tipo |
| 0:30 | Abrir la declaración, elegir el puesto y tocar **Atrás** | Aparece *"¿Salir sin guardar?"* → **Seguir editando** → **Guardar borrador** |
| 1:15 | Horario: elegir *Atención*, tocar una media hora, luego mantener y deslizar | Sube "x h de y h"; tocar una clase muestra que no se mueve |
| 2:30 | **Ver resumen** con horas faltantes | "Hay N puntos por corregir", Validar apagado |
| 3:00 | Completar lo que falta (o abrir una ya completa) y **Validar** | Estado *Validada* |
| 3:45 | Modo avión → cambiar algo → **Guardar borrador** | Franja sin conexión, aviso y cambios en pantalla; quitar modo avión y guardar |
| 4:45 | **Firmar y enviar a mi revisor** | Juramento, firma, seguimiento en *Revisor* |
| 5:30 | En la web, con el revisor | La misma declaración, versión y bitácora |

Plan B si falla la red del aula: capturas de `docs/pruebas/` en las diapositivas 7 y 8, y el video
`[COMPLETAR: enlace]`.

## Preguntas que conviene tener preparadas

- *¿Por qué el revisor no puede usar la app?* Porque su trabajo es revisar el PDF y varias declaraciones a la
  vez; en el teléfono eso sería peor que en la web. Y la app lo dice en lugar de dejarle entrar a medias.
- *¿Qué pasa si se cae la conexión a media declaración?* CP-07: no se guarda, se avisa y nada se pierde
  mientras la app siga abierta.
- *¿Quién garantiza que las horas son correctas?* El validador del P1 en la app, y las reglas de Firestore para
  el formato y los permisos. La pieza que falta es recalcular en el servidor (limitación conocida).
- *¿Es accesible?* Contraste AA con la paleta del Centro de Informática, letra grande sin cortes y, desde la
  2.0.0+7, la cuadrícula funciona con TalkBack.
