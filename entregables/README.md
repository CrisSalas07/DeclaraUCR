# Entregables del Proyecto 2 — DeclaraUCR

Una carpeta por cada entregable del §11 del descriptor, en el mismo orden; todo lo del proyecto está aquí.
Las fuentes están en Markdown y al lado de cada una queda el documento para subir: **PDF** si lleva capturas,
**Word** si no. Se regeneran con `python tool/md2docx.py entregables` (el PDF lo hace Word).

Estado al 21/11/2026: ✅ listo · ⏳ falta algo que solo puede hacer el equipo.

## 1. Los ocho entregables

| # | Entregable (§11) | Qué pide el descriptor | Dónde está | Estado |
|---|---|---|---|---|
| 1 | Repositorio de código | Versión final etiquetada, historial, cómo ejecutar y construir | [`01-repositorio/repositorio.md`](01-repositorio/repositorio.md) | ⏳ falta la etiqueta final |
| 2 | Aplicación distribuible | APK con versión y commit, entorno de prueba, cuentas de evaluación (§6) | [`02-aplicacion-distribuible/aplicacion-distribuible.md`](02-aplicacion-distribuible/aplicacion-distribuible.md) | ⏳ falta CP-08 y enviar las cuentas al docente |
| 3 | Informe técnico | Alcance, arquitectura, decisiones móviles, despliegue | [`03-informe-tecnico/informe-tecnico.md`](03-informe-tecnico/informe-tecnico.md) | ✅ (solo actualizar CP-08 en §7) |
| 4 | Matriz de mejoras | Retroalimentación del P1 y de la socialización (§4, §9) | [`04-matriz-mejoras/matriz-mejoras.md`](04-matriz-mejoras/matriz-mejoras.md) | ⏳ falta §3, la de la socialización |
| 5 | Informe de pruebas | Casos técnicos, resultados con usuarios, hallazgos y nueva comprobación (§7, §8) | [`05-informe-pruebas/informe-pruebas.md`](05-informe-pruebas/informe-pruebas.md) | ⏳ faltan CP-08 y las 3 sesiones |
| 6 | Material de socialización | Presentación, instrumento y síntesis (§9) | `06-socializacion/` | ⏳ falta grabar y enviar el video, y la síntesis |
| 7 | Guía de uso | Instalar y completar los procesos principales | [`07-guia-uso/guia-de-uso.md`](07-guia-uso/guia-de-uso.md) | ✅ (revisar contra el APK final) |
| 8 | Registro de participación | Aportes verificables de cada integrante | [`08-registro-participacion/registro-participacion.md`](08-registro-participacion/registro-participacion.md) | ⏳ faltan las actividades sin commit y los aportes de Lucía |

## 2. Dónde está cada cosa

```text
entregables/
├── README.md                              ← este archivo: mapa, qué usar y qué falta
├── 01-repositorio/
│   └── repositorio.md / .docx             ← cómo ejecutar y construir, etiquetas, historial
├── 02-aplicacion-distribuible/
│   ├── aplicacion-distribuible.md / .docx ← APK, versión, entorno de prueba, cuentas de evaluación
│   └── instalacion.md / .docx             ← instalar, actualizar, volver atrás, compilar
├── 03-informe-tecnico/
│   ├── informe-tecnico.md / .docx         ← alcance, arquitectura, decisiones móviles, despliegue
│   └── comparacion-backend-p1.md / .docx  ← esquema web contra móvil, campo por campo
├── 04-matriz-mejoras/
│   ├── matriz-mejoras.md / .pdf           ← retro del P1 y de la socialización, mejoras
│   └── retroalimentacion-p1.png
├── 05-informe-pruebas/
│   ├── informe-pruebas.md / .pdf          ← recorrido, defectos y §6 resultados con usuarios
│   ├── pruebas-tecnicas.md / .pdf         ← casos CP-01 a CP-08 con sus capturas
│   ├── capturas/                          ← TODAS las capturas de pruebas: CP-…, R-…, D-01-…, P1-T0-…
│   └── sesiones-usuarios/
│       ├── bitacora-sesiones.docx         ← la bitácora de P1, P2 y P3 (se llena en Word, con capturas)
│       └── README.md / kit-sesiones-usuarios.docx ← pasos antes, durante y después de cada sesión
├── 06-socializacion/
│   ├── guion-video.md / .docx             ← guion del video: 10 bloques y la demostración
│   ├── guion-video-presentacion.pdf
│   ├── formulario-retroalimentacion.md / .pdf ← preguntas, enlace y QR del formulario
│   ├── qr-formulario.png / .svg
│   └── sintesis-resultados.md / .docx     ← se llena con las respuestas del docente y del otro equipo
├── 07-guia-uso/
│   ├── guia-de-uso.md / .pdf              ← instalar y usar la app, con capturas
│   └── capturas/                          ← pantallas de la app (también para el video)
└── 08-registro-participacion/
    └── registro-participacion.md / .docx  ← quién hizo qué
```

El video va al **Drive del equipo**, nunca al repositorio (es público).

## 3. Qué se usa para cada tarea

### Las sesiones con los 3 usuarios (bitácora)

| Momento | Qué usar |
|---|---|
| Preparar (una vez y antes de cada sesión) | [`05-informe-pruebas/sesiones-usuarios/README.md`](05-informe-pruebas/sesiones-usuarios/README.md) §1 y §2 |
| Dar los datos ficticios a la persona | La línea «Tarjeta» de su sección en la bitácora |
| Leer el guion y anotar T0–T3 mientras observa | [`05-informe-pruebas/sesiones-usuarios/bitacora-sesiones.docx`](05-informe-pruebas/sesiones-usuarios/bitacora-sesiones.docx) §2 y la sección de P1, P2 o P3 |
| Paso a paso durante la sesión | [`05-informe-pruebas/sesiones-usuarios/README.md`](05-informe-pruebas/sesiones-usuarios/README.md) §3 |
| Tomar los tiempos | La hora del reloj al inicio y al fin de cada tarea, anotada en la bitácora (las sesiones no se graban) |
| Capturas al final de cada tarea | En [`05-informe-pruebas/capturas/`](05-informe-pruebas/capturas), con los nombres de [`05-informe-pruebas/sesiones-usuarios/README.md`](05-informe-pruebas/sesiones-usuarios/README.md) §4 |
| Formulario al terminar | El enlace o [`06-socializacion/qr-formulario.png`](06-socializacion/qr-formulario.png); la persona marca su número (P1, P2, P3) |
| Después de las tres | [`05-informe-pruebas/sesiones-usuarios/README.md`](05-informe-pruebas/sesiones-usuarios/README.md) §5: pasar todo a [`05-informe-pruebas/informe-pruebas.md`](05-informe-pruebas/informe-pruebas.md) §6 |

### El video final de la presentación

| Qué | Dónde |
|---|---|
| El guion (qué se ve y qué se dice en cada bloque) | [`06-socializacion/guion-video.md`](06-socializacion/guion-video.md) |
| Bloque 3: mejoras desde el P1 | [`04-matriz-mejoras/matriz-mejoras.md`](04-matriz-mejoras/matriz-mejoras.md) §2 y §4 |
| Bloque 4: alcance | [`03-informe-tecnico/informe-tecnico.md`](03-informe-tecnico/informe-tecnico.md) §2.1 |
| Bloque 5: demostración (6 min) | La app 2.0.0+7 en el teléfono; pasos en [`06-socializacion/guion-video.md`](06-socializacion/guion-video.md) (guion de la demostración) |
| Bloque 6: instalación | [Página del release v2.0.0+7](https://github.com/CrisSalas07/DeclaraUCR/releases/tag/v2.0.0%2B7) y [`entregables/02-aplicacion-distribuible/instalacion.md`](02-aplicacion-distribuible/instalacion.md) |
| Bloque 7: pruebas técnicas | [`entregables/05-informe-pruebas/pruebas-tecnicas.md`](05-informe-pruebas/pruebas-tecnicas.md) y las capturas D-01 de [`05-informe-pruebas/capturas/`](05-informe-pruebas/capturas) |
| Bloque 8: pruebas con usuarios | [`05-informe-pruebas/informe-pruebas.md`](05-informe-pruebas/informe-pruebas.md) §6 (ya lleno tras las sesiones) y una frase textual de la bitácora |
| Bloque 9: pendientes | [`03-informe-tecnico/informe-tecnico.md`](03-informe-tecnico/informe-tecnico.md) §8 (limitaciones conocidas) |
| Bloque 10: cierre | [`06-socializacion/qr-formulario.svg`](06-socializacion/qr-formulario.svg) en pantalla |
| Pantallas de apoyo | [`entregables/07-guia-uso/capturas/`](07-guia-uso/capturas) |
| Al terminar | Subir al Drive (o YouTube no listado), enviar video y formulario al docente y a otro equipo, y anotar enlace y fecha en [`06-socializacion/guion-video.md`](06-socializacion/guion-video.md) |

## 4. Lo que falta, en orden

Cada paso desbloquea el siguiente. Entre corchetes, la sección del descriptor.

1. **Keity devuelve desde la web la declaración de la cuenta de evaluación** (está en *Pendiente de firma del
   revisor*), para que el docente pueda recorrer los tres procesos. [§6]
2. **CP-08:** instalar el APK 2.0.0+7 desde cero en un teléfono que no sea el de desarrollo; captura
   `entregables/05-informe-pruebas/capturas/CP-08-1.png`. De paso, repetir D-01 y D-02 (con TalkBack) en ese teléfono. [§6, §7]
3. **Las tres sesiones** con la 2.0.0+7, siguiendo [`05-informe-pruebas/sesiones-usuarios/README.md`](05-informe-pruebas/sesiones-usuarios/README.md). Al menos
   una persona del perfil docente. Cada una termina con el formulario. [§8]
4. **Pasar los resultados** de las bitácoras y del formulario al informe de pruebas §6.3 a §6.6.
5. **Corregir los hallazgos de mayor impacto** y **volver a probarlos con una de las personas** (§6.7). [§8]
6. **Grabar el video** con [`06-socializacion/guion-video.md`](06-socializacion/guion-video.md), con **los tres integrantes**, y enviarlo con el
   enlace del formulario **al docente y a al menos otro equipo**. [§9]
7. **Síntesis y matriz §3:** cada comentario como aceptado, parcialmente aceptado o descartado, con
   justificación. [§9]
8. **Al menos dos mejoras** de la socialización, versión 2.0.0+8 (con T-08 de la matriz), nueva comprobación. [§9]
9. **Cierre:** etiqueta final, completar el registro de participación, regenerar los documentos con
   `python tool/md2docx.py entregables` y exportar a PDF la bitácora. [§11]

## 5. Riesgos para la nota

- **Lucía no tiene commits en el Proyecto 2.** La rúbrica evalúa aportes individuales (10 pts) y el §9 pide que
  participen todos. Conviene que guíe o anote una sesión, aparezca en el video y haga una de las dos mejoras de
  la socialización, y que quede anotado en el registro.
- **Otro equipo tiene que responder el formulario.** El §9 pide retroalimentación del docente *y* de al menos
  otro equipo; sin eso, la síntesis queda incompleta.
- **Las sesiones van antes del video**, porque el bloque 8 muestra sus resultados, y el video va antes de las
  mejoras finales.
