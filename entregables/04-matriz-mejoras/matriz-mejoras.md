# Matriz de mejoras — DeclaraUCR

**Proyecto 2 · IF0009 · UCR Sede del Sur**

La matriz sigue la estructura del descriptor (§4): **observación → acción → prioridad → evidencia → estado**.
Se le agregan dos columnas que el descriptor exige para los pendientes: **origen** y **justificación /
propuesta de atención**.

- **Prioridad:** Alta (impide completar un proceso, compromete datos o permite accesos indebidos; se corrige
  antes de las pruebas con usuarios, §4), Media, Baja.
- **Estado:** Pendiente, En proceso, Verificada.
- **Evidencia:** commit, prueba (automatizada o caso CP-xx) o captura con nombre de archivo.

## 1. Versión base del Proyecto 1

| | |
|---|---|
| Repositorio | DeclaraHorario (sistema web del Proyecto 1) |
| Versión base propuesta | `main` en `2661da2` (merge del PR #94, 10/11/2026) `[COMPLETAR: confirmar que es lo que se entregó en el P1]` |
| Etiqueta | `[COMPLETAR: crear y subir la etiqueta]` → `git tag p1-entrega 2661da2 && git push origin p1-entrega` |
| Retroalimentación recibida | La revisión del docente **no pidió cambios** al Proyecto 1. Se adjunta igual: `[COMPLETAR: captura o PDF de la nota y los comentarios de la evaluación del P1, en esta carpeta como retroalimentacion-p1.pdf]` |

La app móvil usa el backend de esa versión: las reglas copiadas en `backend/proyecto1/` vienen del commit
`5f68958` de DeclaraHorario (ver `backend/proyecto1/ORIGEN.txt`).

## 2. Observaciones de la revisión del Proyecto 1

La evaluación del Proyecto 1 **no señaló observaciones que obligaran a cambiar el sistema** (ver la
retroalimentación adjunta en §1). Por eso no hay filas del docente que atender.

Para que la continuidad no quede vacía, el equipo revisó por su cuenta la versión base y registra aquí lo que
encontró. Solo se anotan puntos reales y comprobables; no se inventan observaciones.

| # | Origen | Observación | Acción concreta | Prioridad | Evidencia | Estado |
|---|---|---|---|---|---|---|
| P1-01 | Revisión del equipo | El sistema solo se usaba desde la computadora; la persona declarante no podía llenar ni firmar desde el teléfono | Módulo móvil con los tres procesos y la firma de la declarante, sobre el mismo backend | Alta | Este proyecto: release v2.0.0+7; CP-01 a CP-07 (`docs/PRUEBAS.md`) | Verificada |
| P1-02 | Revisión del equipo | El estado `VALIDADA` lo decide el cliente; las reglas validan formato y permisos, no recalculan horas | Pendiente con justificación: requiere una Cloud Function (plan Blaze de Firebase). Propuesta: función que recalcule horas y traslapes y rechace un `VALIDADA` inválido | Media | README, sección *Security*; `docs/INSTALACION.md` §7 | Pendiente con justificación |
| P1-03 | Revisión del equipo | `[COMPLETAR o borrar la fila: otro punto que el equipo haya notado en la web del P1]` | | | | |

## 3. Observaciones de la socialización

> Se llenan después de la socialización (§9), con lo que se recoja en el formulario (`06-socializacion/`) y lo
> que diga el docente en los 10 minutos de preguntas. Cada fila se marca **Aceptada**, **Parcialmente
> aceptada** o **Descartada**, siempre con justificación. Hay que implementar **al menos dos** mejoras; si hay
> menos de dos acciones pertinentes, se atienden todas y se explica por qué.

| # | Quién la hizo | Observación | Decisión | Acción concreta | Prioridad | Evidencia | Estado | Justificación |
|---|---|---|---|---|---|---|---|---|
| S-01 | `[Docente / Equipo X]` | | | | | | | |
| S-02 | | | | | | | | |
| S-03 | | | | | | | | |
| S-04 | | | | | | | | |

## 4. Otras mejoras registradas durante el Proyecto 2

No vienen de la revisión ni de la socialización, sino de las pruebas propias. Se registran aquí para que la
trazabilidad quede completa.

| # | Origen | Observación | Acción | Prioridad | Evidencia | Estado |
|---|---|---|---|---|---|---|
| T-01 | Prueba en teléfono (2.0.0+3) | Un período cerrado en la web seguía apareciendo al crear una declaración | Leer los períodos del servidor, no de la copia del teléfono | Alta | Commit `0be0200`; prueba "a period closed after a first read is no longer offered" | Verificada |
| T-02 | Prueba en teléfono (2.0.0+3) | La sección de cursos aparecía dos veces | Mostrarla una sola vez | Media | Commit `ef42e47` | Verificada |
| T-03 | Prueba en teléfono (2.0.0+3) | La vista previa del PDF no permitía acercar | Zoom con pellizco y doble toque | Media | Commit `4d3184f` | Verificada |
| T-04 | Prueba en teléfono (2.0.0+5) | Con la letra del sistema al 110 % se cortaban palabras en el seguimiento | Etiquetas que nunca parten una palabra | Media | Commit `f633fb8`; `docs/capturas/01-inicio.png` | Verificada |
| T-05 | Recorrido 20/11/2026 (D-01) | Salir con Atrás perdía los cambios sin avisar | Diálogo "¿Salir sin guardar?" | Alta | Prueba "leaving with unsaved changes asks first (D-01)"; `05-informe-pruebas/evidencias/recorrido-2026-11-20/D-01-*.png`; commit `afeb1ee` (PR #8) | Verificada |
| T-06 | Recorrido 20/11/2026 (D-02) | La cuadrícula no se podía usar con TalkBack | Cada media hora es un botón con día, hora y contenido | Alta | Prueba "with TalkBack, each half hour says what it has and places (D-02)"; commit `afeb1ee` (PR #8) | Verificada (falta repetirla en el teléfono) |
| T-07 | Recorrido 20/11/2026 (D-03) | Chips de horas leídos como casillas | Leerlos como texto | Baja | `lib/screens/home_screen.dart` (`_HoursChip`); commit `afeb1ee` (PR #8) | Verificada |

## 5. Resumen

`[COMPLETAR al cierre]` Revisión del P1: sin observaciones del docente; __ de la revisión del equipo (__ verificadas, __ pendientes con
justificación) y __ de la socialización (__ aceptadas, __ parcialmente, __ descartadas; __ mejoras
implementadas).
