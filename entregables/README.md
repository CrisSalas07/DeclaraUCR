# Entregables del Proyecto 2 — DeclaraUCR

Una carpeta por cada entregable del §11 del descriptor, en el mismo orden. Cada documento está en Markdown y,
al lado, en el formato para entregar: **PDF** si lleva capturas, **Word** si no. Se regeneran desde el
Markdown con `python tool/md2docx.py entregables` (el PDF lo hace Word).

## 1. Los ocho entregables

| # | Entregable (§11) | Qué pide el descriptor | Dónde está |
|---|---|---|---|
| 1 | Repositorio de código | Versión final etiquetada, historial, cómo ejecutar y construir | [`01-repositorio/repositorio.md`](01-repositorio/repositorio.md) |
| 2 | Aplicación distribuible | APK con versión y commit, entorno de prueba, cuentas de evaluación, instalación, actualización y vuelta atrás, limitaciones (§6) | [`02-aplicacion-distribuible/aplicacion-distribuible.md`](02-aplicacion-distribuible/aplicacion-distribuible.md) y [`instalacion.md`](02-aplicacion-distribuible/instalacion.md) |
| 3 | Informe técnico | Alcance, arquitectura, decisiones de adaptación móvil, despliegue | [`03-informe-tecnico/informe-tecnico.md`](03-informe-tecnico/informe-tecnico.md) y [`comparacion-backend-p1.md`](03-informe-tecnico/comparacion-backend-p1.md) |
| 4 | Matriz de mejoras | Seguimiento de la retroalimentación del Proyecto 1 y de la socialización (§4, §9) | [`04-matriz-mejoras/matriz-mejoras.md`](04-matriz-mejoras/matriz-mejoras.md) |
| 5 | Informe de pruebas | Casos técnicos, resultados con usuarios, hallazgos y comprobación de correcciones (§7, §8) | [`05-informe-pruebas/informe-pruebas.md`](05-informe-pruebas/informe-pruebas.md) y [`pruebas-tecnicas.md`](05-informe-pruebas/pruebas-tecnicas.md) |
| 6 | Material de socialización | Presentación, instrumento de retroalimentación y síntesis de resultados (§9) | [`06-socializacion/`](06-socializacion) |
| 7 | Guía de uso | Instrucciones breves para instalar y completar los procesos principales | [`07-guia-uso/guia-de-uso.md`](07-guia-uso/guia-de-uso.md) |
| 8 | Registro de participación | Aportes verificables de cada integrante | [`08-registro-participacion/registro-participacion.md`](08-registro-participacion/registro-participacion.md) |

## 2. Contenido de cada carpeta

```text
entregables/
├── 01-repositorio/
│   └── repositorio.md / .docx             ← cómo ejecutar y construir, etiquetas, historial
├── 02-aplicacion-distribuible/
│   ├── aplicacion-distribuible.md / .docx ← APK, versión, entorno de prueba, cuentas de evaluación
│   └── instalacion.md / .docx             ← instalar, actualizar, volver atrás, compilar
├── 03-informe-tecnico/
│   ├── informe-tecnico.md / .docx         ← alcance, arquitectura, decisiones móviles, despliegue
│   └── comparacion-backend-p1.md / .docx  ← esquema web contra móvil, campo por campo
├── 04-matriz-mejoras/
│   ├── matriz-mejoras.md / .pdf           ← retroalimentación del P1, de las sesiones y de la socialización
│   └── retroalimentacion-p1.png           ← la evaluación del Proyecto 1
├── 05-informe-pruebas/
│   ├── informe-pruebas.md / .pdf          ← recorrido, defectos, pruebas automatizadas y pruebas con usuarios
│   ├── pruebas-tecnicas.md / .pdf         ← casos CP-01 a CP-08 con sus capturas
│   ├── capturas/                          ← evidencias: CP-…, R-…, D-01-…, P1-T0-…
│   └── sesiones-usuarios/
│       └── bitacora-sesiones.docx         ← bitácora de las sesiones con P1, P2 y P3
├── 06-socializacion/
│   ├── guion-video.md / .docx             ← presentación: guion del video y de la demostración
│   ├── formulario-retroalimentacion.md / .pdf ← instrumento: preguntas, enlace y QR
│   ├── qr-formulario.png / .svg
│   └── sintesis-resultados.md / .docx     ← síntesis de las respuestas del docente y de otro equipo
├── 07-guia-uso/
│   ├── guia-de-uso.md / .pdf              ← instalar y usar la app, con capturas
│   └── capturas/                          ← pantallas de la app
└── 08-registro-participacion/
    └── registro-participacion.md / .docx  ← quién hizo qué
```

El video de la socialización está en el Drive del equipo, no en el repositorio (es público); su enlace se
anota en [`06-socializacion/guion-video.md`](06-socializacion/guion-video.md).
