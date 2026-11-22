# Entregables del Proyecto 2 — DeclaraUCR

Una carpeta por cada entregable del §11 del descriptor, en el mismo orden. Las fuentes están en Markdown;
`drive/` tiene las copias en Word para subir y exportar a PDF (se regeneran al final con
`python tool/md2docx.py`, porque hoy están desactualizadas).

Estado al 21/11/2026: ✅ listo · ⏳ falta algo que solo puede hacer el equipo.

## 1. Los ocho entregables

| # | Entregable (§11) | Qué pide el descriptor | Dónde está | Estado |
|---|---|---|---|---|
| 1 | Repositorio de código | Versión final etiquetada, historial, cómo ejecutar y construir | `01-repositorio/repositorio.md` | ⏳ falta la etiqueta final |
| 2 | Aplicación distribuible | APK con versión y commit, entorno de prueba, cuentas de evaluación (§6) | `02-aplicacion-distribuible/aplicacion-distribuible.md` | ⏳ falta CP-08 y enviar las cuentas al docente |
| 3 | Informe técnico | Alcance, arquitectura, decisiones móviles, despliegue | `03-informe-tecnico/informe-tecnico.md` | ✅ (solo actualizar CP-08 en §7) |
| 4 | Matriz de mejoras | Retroalimentación del P1 y de la socialización (§4, §9) | `04-matriz-mejoras/matriz-mejoras.md` | ⏳ falta §3, la de la socialización |
| 5 | Informe de pruebas | Casos técnicos, resultados con usuarios, hallazgos y nueva comprobación (§7, §8) | `05-informe-pruebas/informe-pruebas.md` | ⏳ faltan CP-08 y las 3 sesiones |
| 6 | Material de socialización | Presentación, instrumento y síntesis (§9) | `06-socializacion/` | ⏳ falta grabar y enviar el video, y la síntesis |
| 7 | Guía de uso | Instalar y completar los procesos principales | `07-guia-uso/guia-de-uso.md` | ✅ (revisar contra el APK final) |
| 8 | Registro de participación | Aportes verificables de cada integrante | `08-registro-participacion/registro-participacion.md` | ⏳ faltan las actividades sin commit y los aportes de Lucía |

Material de apoyo que no es un entregable por sí solo:

| Qué | Dónde |
|---|---|
| Kit de las sesiones con usuarios (pasos y tarjetas) | `05-informe-pruebas/sesiones-usuarios/` |
| Bitácora de P1, P2 y P3, un solo documento (se llena durante cada sesión) | `05-informe-pruebas/evidencias/sesiones-usuarios/bitacora-sesiones.md` |
| Capturas del recorrido del 20/11 (R-01 a R-14, D-01) | `05-informe-pruebas/evidencias/recorrido-2026-11-20/` |
| Casos técnicos CP-01 a CP-08 con capturas | `docs/PRUEBAS.md`, `docs/pruebas/` |
| Instalación, actualización, vuelta atrás y limitaciones | `docs/INSTALACION.md` |
| Formulario publicado y su QR | `06-socializacion/formulario-retroalimentacion.md`, `qr-formulario.png` |

## 2. Lo que falta, en orden

Cada paso desbloquea el siguiente. Entre corchetes, la sección del descriptor.

1. **Keity devuelve desde la web la declaración de la cuenta de evaluación** (está en *Pendiente de firma del
   revisor*), para que el docente pueda recorrer los tres procesos. [§6]
2. **CP-08:** instalar el APK 2.0.0+7 desde cero en un teléfono que no sea el de desarrollo; captura
   `docs/pruebas/CP-08-1.png`. De paso, repetir D-01 y D-02 (con TalkBack) en ese teléfono. [§6, §7]
3. **Las tres sesiones** con la 2.0.0+7, siguiendo `05-informe-pruebas/sesiones-usuarios/README.md`. Al menos
   una persona del perfil docente. Cada una termina con el formulario. [§8]
4. **Pasar los resultados** de las bitácoras y del formulario al informe de pruebas §6.3 a §6.6.
5. **Corregir los hallazgos de mayor impacto** y **volver a probarlos con una de las personas** (§6.7). [§8]
6. **Grabar el video** con `06-socializacion/guion-video.md`, con **los tres integrantes**, y enviarlo con el
   enlace del formulario **al docente y a al menos otro equipo**. [§9]
7. **Síntesis y matriz §3:** cada comentario como aceptado, parcialmente aceptado o descartado, con
   justificación. [§9]
8. **Al menos dos mejoras** de la socialización, versión 2.0.0+8 (con T-08 de la matriz), nueva comprobación. [§9]
9. **Cierre:** etiqueta final, completar el registro de participación, regenerar `drive/` y exportar a PDF el
   informe técnico, el informe de pruebas y la guía. [§11]

## 3. Riesgos para la nota

- **Lucía no tiene commits en el Proyecto 2.** La rúbrica evalúa aportes individuales (10 pts) y el §9 pide que
  participen todos. Conviene que guíe o anote una sesión, aparezca en el video y haga una de las dos mejoras de
  la socialización, y que quede anotado en el registro.
- **Otro equipo tiene que responder el formulario.** El §9 pide retroalimentación del docente *y* de al menos
  otro equipo; sin eso, la síntesis queda incompleta.
- **Las sesiones van antes del video**, porque el bloque 8 muestra sus resultados, y el video va antes de las
  mejoras finales.
