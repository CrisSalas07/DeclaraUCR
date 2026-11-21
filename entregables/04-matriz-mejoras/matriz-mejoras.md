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
| Retroalimentación recibida | `[COMPLETAR: adjuntar el documento o la captura de la revisión del docente en esta carpeta, como retroalimentacion-p1.pdf]` |

La app móvil usa el backend de esa versión: las reglas copiadas en `backend/proyecto1/` vienen del commit
`5f68958` de DeclaraHorario (ver `backend/proyecto1/ORIGEN.txt`).

## 2. Observaciones de la revisión del Proyecto 1

> **Cómo llenar esta sección.** Copie cada observación del docente **tal como la escribió** (una por fila,
> aunque parezca menor: §4 dice que todas se registran). Luego decida la acción. Si la observación ya está
> resuelta por algo que la app móvil hizo, use esa evidencia; abajo hay una lista de lo que ya existe para
> facilitarlo.

| # | Observación (textual) | Acción concreta | Prioridad | Evidencia | Estado | Justificación / propuesta (si no está verificada) |
|---|---|---|---|---|---|---|
| P1-01 | `[COMPLETAR]` | | | | | |
| P1-02 | `[COMPLETAR]` | | | | | |
| P1-03 | `[COMPLETAR]` | | | | | |
| P1-04 | `[COMPLETAR]` | | | | | |
| P1-05 | `[COMPLETAR]` | | | | | |

### Evidencia que ya existe y puede responder a observaciones típicas

Úsela solo si corresponde a una observación real; no invente la observación para usar la evidencia.

| Si el docente señaló… | Lo que ya hay | Evidencia |
|---|---|---|
| Que la validación (`VALIDADA`) la decide el cliente | Sigue igual en web y móvil; las reglas validan formato y permisos | Pendiente con justificación: requiere una Cloud Function (plan Blaze de Firebase). Propuesta: función `onVersionWrite` que recalcule horas y traslapes y rechace un `VALIDADA` inválido. Ver README, sección *Security* |
| Accesos indebidos entre personas | Las reglas del P1 impiden leer o escribir lo de otra persona; la app no tiene rutas para otros roles | `backend/proyecto1/verify.mjs`; CP-05 (`docs/pruebas/CP-05-*.png`) |
| Traslapes y cálculo de horas | Mismo validador del P1, con pruebas | `test/domain/overlap_detector_test.dart`, `declaration_validator_test.dart`; CP-02 |
| Pérdida de datos si se cae la conexión | No se guarda sin red, se avisa y los cambios quedan en pantalla; tiempo máximo de 15 s | `test/connectivity_test.dart`; CP-07 |
| Identidad visual UCR | Paleta, tipografía Trueno, firma oficial y tamaño mínimo según el manual | README, *Visual identity decisions*; `docs/capturas/` |
| Firma y huella del contenido | La firma de la declarante desde el teléfono usa la misma huella SHA-256 que la web | `test/domain/content_hash_test.dart`; CP-03, CP-06 |

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

`[COMPLETAR al cierre]` Total de observaciones: __ del P1 (__ verificadas, __ en proceso, __ pendientes con
justificación) y __ de la socialización (__ aceptadas, __ parcialmente, __ descartadas; __ mejoras
implementadas).
