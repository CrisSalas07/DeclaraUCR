# Entregables del Proyecto 2 — DeclaraUCR

Una carpeta por cada entregable del §11 del descriptor, en el mismo orden. Cada documento está en el formato
para entregar: **PDF** si lleva capturas, **Word** si no. Las fuentes en Markdown y `tool/md2docx.py`, que
generaba estos archivos, se borraron el 27/11/2026; siguen en el historial de git, en el commit `3d6ca2e`
(`git checkout 3d6ca2e -- 'entregables/*/*.md' tool/md2docx.py`).

## 1. Los ocho entregables

| # | Entregable (§11) | Qué pide el descriptor | Dónde está |
|---|---|---|---|
| 1 | Repositorio de código | Versión final etiquetada, historial, cómo ejecutar y construir | [`01-repositorio/repositorio.docx`](01-repositorio/repositorio.docx) |
| 2 | Aplicación distribuible | APK con versión y commit, entorno de prueba, cuentas de evaluación, instalación, actualización y vuelta atrás, limitaciones (§6) | [`02-aplicacion-distribuible/aplicacion-distribuible.docx`](02-aplicacion-distribuible/aplicacion-distribuible.docx) y [`instalacion.docx`](02-aplicacion-distribuible/instalacion.docx) |
| 3 | Informe técnico | Alcance, arquitectura, decisiones de adaptación móvil, despliegue | [`03-informe-tecnico/informe-tecnico.docx`](03-informe-tecnico/informe-tecnico.docx) y [`comparacion-backend-p1.docx`](03-informe-tecnico/comparacion-backend-p1.docx) |
| 4 | Matriz de mejoras | Seguimiento de la retroalimentación del Proyecto 1 y de la socialización (§4, §9) | [`04-matriz-mejoras/matriz-mejoras.pdf`](04-matriz-mejoras/matriz-mejoras.pdf) |
| 5 | Informe de pruebas | Casos técnicos, resultados con usuarios, hallazgos y comprobación de correcciones (§7, §8) | [`05-informe-pruebas/informe-pruebas.pdf`](05-informe-pruebas/informe-pruebas.pdf) y [`pruebas-tecnicas.pdf`](05-informe-pruebas/pruebas-tecnicas.pdf) |
| 6 | Material de socialización | Presentación, instrumento de retroalimentación y síntesis de resultados (§9) | [`06-socializacion/`](06-socializacion) |
| 7 | Guía de uso | Instrucciones breves para instalar y completar los procesos principales | [`07-guia-uso/guia-de-uso.pdf`](07-guia-uso/guia-de-uso.pdf) |
| 8 | Registro de participación | Aportes verificables de cada integrante | [`08-registro-participacion/registro-participacion.docx`](08-registro-participacion/registro-participacion.docx) |

## 2. Contenido de cada carpeta

```text
entregables/
├── 01-repositorio/
│   └── repositorio.docx             ← cómo ejecutar y construir, etiquetas, historial
├── 02-aplicacion-distribuible/
│   ├── aplicacion-distribuible.docx ← APK, versión, entorno de prueba, cuentas de evaluación
│   └── instalacion.docx             ← instalar, actualizar, volver atrás, compilar
├── 03-informe-tecnico/
│   ├── informe-tecnico.docx         ← alcance, arquitectura, decisiones móviles, despliegue
│   └── comparacion-backend-p1.docx  ← esquema web contra móvil, campo por campo
├── 04-matriz-mejoras/
│   ├── matriz-mejoras.pdf           ← retroalimentación del P1, de las sesiones y de la socialización
│   └── retroalimentacion-p1.png           ← la evaluación del Proyecto 1
├── 05-informe-pruebas/
│   ├── informe-pruebas.pdf          ← recorrido, defectos, pruebas automatizadas y pruebas con usuarios
│   ├── pruebas-tecnicas.pdf         ← casos CP-01 a CP-08 con sus capturas
│   └── sesiones-usuarios/
│       └── bitacora-sesiones.docx         ← bitácora de las sesiones con P1, P2 y P3
├── 06-socializacion/
│   ├── formulario-retroalimentacion.pdf ← instrumento: preguntas, enlace y QR
│   ├── qr-formulario.png
│   ├── respuestas-formulario.pdf    ← respuestas del formulario (P1, P2 y P3)
│   └── sintesis-resultados.docx     ← síntesis de las respuestas del docente y de otro equipo
├── 07-guia-uso/
│   └── guia-de-uso.pdf              ← instalar y usar la app, con capturas
├── 08-registro-participacion/
│   └── registro-participacion.docx  ← quién hizo qué
└── DeclaraUCR.mp4                   ← el video de DeclaraUCR
```

El video está en esta carpeta: [`DeclaraUCR.mp4`](DeclaraUCR.mp4).

Las capturas de pantalla están dentro de cada PDF; las imágenes sueltas siguen en el historial de git.
