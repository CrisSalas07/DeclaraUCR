# Registro de participación — Proyecto 2

**IF0009 · Entregable 8: aportes verificables de cada integrante.**

Cada fila dice quién hizo qué y dónde se puede comprobar (commit, PR, documento, captura o prueba). Lo que no
deja rastro en git (sesiones con usuarios, la socialización, revisión de documentos) también se anota, con la
evidencia que sí exista: la tabla del informe, el formulario o la fecha.

## 1. Identidades en git

En los commits aparecen estos nombres. Cada integrante usó más de una identidad (la de la terminal y la de
GitHub al hacer merge); el correo de los commits confirma que son la misma persona.

| Integrante | Identidad en git | Commits en DeclaraUCR (P2) | Commits en DeclaraHorario (P1) |
|---|---|---|---|
| Cristopher Mora Salas | `Salas07` (commits), `CrisSalas07` (merges de PR) | 22 + 12 merges (12 al 21/11) | 139 + 52 |
| Keity Chavarría Steller | `Keity` (commits), `dayanachavarriasteller-maker` (merges de PR) | 28 + 7 merges (18 y 19/11) | 75 + 38 |
| Lucía Palacios | `Lucia`, `luciaapalacio608-dot` | — | 25 + 2 |

Para ver el detalle: `git log --format='%h %ad %an %s' --date=short`.

## 2. Aportes del Proyecto 2

### Desarrollo de la app móvil (DeclaraUCR)

| Fecha | Integrante | Actividad | Aporte | Evidencia |
|---|---|---|---|---|
| 12/11/2026 | Cristopher | Módulo base del laboratorio | Declaraciones, formulario, horario, borradores, resumen | `ce2a8ff` |
| 12/11/2026 | Cristopher | Autenticación y carga docente | Registro con cédula, cursos de carrera, proyectos, zonaje, historial | `f1942cf` |
| 12/11/2026 | Cristopher | Identidad visual UCR | Paleta, Trueno, firma oficial, ícono propio, ajustes Android | `6f270f4` |
| 18/11/2026 | Cristopher | Inicio de sesión | Rendimiento y diseño del login | `07b39d6` |
| 18/11/2026 | Keity | Conexión al backend del P1 | Android contra `declarahorario-b186f`; emuladores con reglas y datos del P1 | `c9aa1de`, `24ed31a` |
| 18/11/2026 | Keity | Migración de datos al esquema del P1 | Perfil y registro; lectura y escritura de declaraciones; clases fijas de la Coordinación; zonaje | `680a0fa`, `4799ae6`, `7f2600b`, `7fea736`, `689824d` |
| 18/11/2026 | Keity | Conectividad | Sin pérdida silenciosa al perder la señal | `78dd6ee` |
| 18/11/2026 | Keity | Distribución | Firma de release, versión 2.0.0+2 y script del APK | `0d5753f` |
| 19/11/2026 | Keity | Correcciones tras probar en el teléfono | Períodos del servidor, cursos una vez, PDF, seguimiento, Validar | `0be0200`, `ef42e47`, `4d3184f`, `1ca1bba`, `9c75d17` |
| 19/11/2026 | Keity | Firma de la declarante | Firmar y enviar al revisor desde el teléfono | `d397cf0` |
| 19/11/2026 | Keity | Accesibilidad con letra grande | Etiquetas que no parten palabras | `f633fb8` |
| 19/11/2026 | Keity | Pruebas técnicas | Casos CP-01 a CP-08; ejecución de CP-01 a CP-07 con capturas | `aa461cf`, `a3b8640`, `9e07aab`, `e3e8790` |
| 19/11/2026 | Keity | Revisión e integración | Revisión y merge de los PR #1 a #7 | PR #1–#7 en GitHub |
| 20/11/2026 | Cristopher | Recorrido exploratorio y correcciones | D-01 (aviso al salir sin guardar), D-02 (cuadrícula con TalkBack), D-03; 2 pruebas nuevas; versión 2.0.0+7 | `afeb1ee` (PR #8); `entregables/05-informe-pruebas/` |
| 20/11/2026 | Cristopher | Documentación de entregables | Informe técnico, matriz, informe de pruebas, guía, material de socialización | `94cb429` (PR #8); `entregables/` |
| 20/11/2026 | Cristopher | Kit de sesiones con usuarios y socialización | Guion de tareas, hoja de sesión, guion del video, formulario, matriz sin observaciones del P1 | PR #9–#15 |
| 21/11/2026 | Cristopher | Preparación de las sesiones | Nota del P1, tarjetas ficticias, datos del backend, formulario publicado con QR, ensayo de T1–T3 | PR #16, #17, #19 |

### Actividades sin commit

| Fecha | Integrante | Actividad | Aporte | Evidencia |
|---|---|---|---|---|
| `[ ]` | `[ ]` | Instalación desde cero (CP-08) | | `docs/pruebas/CP-08-1.png` |
| 24/11/2026 | Keity | Sesión con usuario P1 | Guió y anotó la sesión (T0–T3, perfil y formulario) | Bitácora §3 y capturas `P1-T0` a `P1-T3` |
| `[ ]` | `[ ]` | Sesión con usuario P2 | | Informe de pruebas §6 |
| `[ ]` | `[ ]` | Sesión con usuario P3 | | Informe de pruebas §6 |
| 21/11/2026 | Cristopher | Formulario de retroalimentación | Creación y publicación en Google Forms | `06-socializacion/formulario-retroalimentacion.md` |
| 21/11/2026 | Cristopher | Ensayo completo de la sesión | T1–T3 en el emulador con la 2.0.0+7; encontró T-08 | Matriz de mejoras T-08 |
| `[ ]` | `[ ]` | Video de socialización | Grabó, narró o editó el bloque ___ | Enlace al video |
| `[ ]` | `[ ]` | Mejoras posteriores a la socialización | | `[commit]` |
| `[ ]` | `[ ]` | Revisión cruzada de documentos | Revisó ___ | Comentarios en el documento |

## 3. Continuidad con el Proyecto 1

La app usa el backend, las reglas y buena parte del dominio de DeclaraHorario. Los aportes del Proyecto 1 se
documentaron en esa entrega (nota 95). Los tres integrantes trabajaron en él, con los roles A (Keity), B (Lucía)
y C (Cristopher) del README de DeclaraHorario; la versión entregada es la etiqueta `p1-entrega` (`2661da2`).

## 4. Revisión cruzada

| Integrante | Revisó el registro de | Fecha | Conforme |
|---|---|---|---|
| | | | |
| | | | |
