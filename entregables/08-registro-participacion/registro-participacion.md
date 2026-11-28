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
| Cristopher Mora Salas | `Salas07` (commits), `CrisSalas07` (merges de PR) | 55 + 27 merges (12 al 27/11) | 139 + 52 |
| Keity Chavarría Steller | `Keity` (commits), `dayanachavarriasteller-maker` (merges de PR) | 39 + 11 merges (18 al 27/11) | 75 + 38 |
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
| 19/11/2026 | Keity | Firma de la declarante | Firmar y enviar al superior desde el teléfono | `d397cf0` |
| 19/11/2026 | Keity | Accesibilidad con letra grande | Etiquetas que no parten palabras | `f633fb8` |
| 19/11/2026 | Keity | Pruebas técnicas | Casos CP-01 a CP-08; ejecución de CP-01 a CP-07 con capturas | `aa461cf`, `a3b8640`, `9e07aab`, `e3e8790` |
| 19/11/2026 | Keity | Revisión e integración | Revisión y merge de los PR #1 a #7 | PR #1–#7 en GitHub |
| 20/11/2026 | Cristopher | Recorrido exploratorio y correcciones | D-01 (aviso al salir sin guardar), D-02 (cuadrícula con TalkBack), D-03; 2 pruebas nuevas; versión 2.0.0+7 | `afeb1ee` (PR #8); `entregables/05-informe-pruebas/` |
| 20/11/2026 | Cristopher | Documentación de entregables | Informe técnico, matriz, informe de pruebas, guía, material de socialización | `94cb429` (PR #8); `entregables/` |
| 20/11/2026 | Cristopher | Kit de sesiones con usuarios y socialización | Guion de tareas, hoja de sesión, guion del video, formulario, matriz sin observaciones del P1 | PR #9–#15 |
| 21/11/2026 | Cristopher | Preparación de las sesiones | Nota del P1, tarjetas ficticias, datos del backend, formulario publicado con QR, ensayo de T1–T3 | PR #16, #17, #19 |
| 22/11/2026 | Cristopher | Orden de los entregables | Mapa de entregables y README raíz como entrada | PR #20, #21 |
| 24/11/2026 | Keity | Sesiones sin grabación y CP-08 con la 2.0.0+7 | Kit sin audio; CP-08 con el APK publicado; registro de la sesión P1 | `2cfd459`, `912f737`, `cc7cc5b` (PR #22, #23) |
| 24/11/2026 | Cristopher | Una sola carpeta de entregables | Bitácora en Word, capturas dentro de los PDF, revisión contra el descriptor | `77fae16` (PR #24) |
| 24/11/2026 | Cristopher | Retroalimentación del P1: rol «Superior» | «Revisor» pasa a «Superior» en estados, seguimiento, botón de firma, avisos y PDF; pruebas actualizadas (matriz P1-03) | `68da1f3` (PR #25) |
| 24/11/2026 | Cristopher | Registro de las sesiones P1 y P2 | Bitácora, informe de pruebas §6 y matriz U-01 a U-07, con capturas, formulario y horas de Firebase | PR #26 a #31 |
| 24/11/2026 | Cristopher | «Superior» en los entregables | Guion del video, informe de pruebas y registro con el nombre nuevo del rol | `575ed74` (PR #32) |
| 26/11/2026 | Keity | Guion del video y demostración | Bloques del video repartidos entre el equipo, guion de la demostración, captura de inicio de sesión con la 2.0.0+7 | `fbebdf9`, `e7539b0`, `ad0108a` (PR #33) |
| 27/11/2026 | Cristopher | Correcciones de las sesiones, versión 2.0.0+8 | U-03 a U-07 en la app y en los entregables; release de la 2.0.0+8 | `abc5818`, `aaeb992` (PR #34) |
| 27/11/2026 | Cristopher | Borrador recién guardado en la lista (T-09) | La lista lee de la copia del teléfono lo que el servidor aún no confirma; prueba contra las reglas | `096dcbd` (PR #35) |
| 27/11/2026 | Cristopher | Recorrido guiado, versión 2.0.0+9 | Recorrido sobre las pantallas reales con una docente de ejemplo (U-06 rehecho); capturas nuevas de la guía | `7ea44f2`, `2bad858` (PR #36) |
| 27/11/2026 | Keity | Horario de las clases y juramento oficial, versión 2.0.0+10 | Tarjeta «Horario de sus clases» arriba de los días; juramento del formulario oficial en el PDF y la firma; capturas 04, 09 y 10 de la guía; versión final 2.0.0+10 y sus documentos | `4c913e6`, `372d224`, `a40d61d`, `60d5813` (PR #37) |
| 27/11/2026 | Keity | Revisión e integración | Merge de los PR #22, #23, #33 y #37 | PR en GitHub |
| 27/11/2026 | Cristopher | Entregables al día, sesión P3 y formato oficial, versión 2.0.0+11 | Entregables con la 2.0.0+10 y sin «revisor»; sesión P3 en la bitácora, el informe y la matriz (U-08 a U-10); observaciones y PDF como el formulario oficial; comentarios del código; release de la 2.0.0+11 | `69f50a3`, `567c699` y otros (PR #38) |

### Actividades sin commit

| Fecha | Integrante | Actividad | Aporte | Evidencia |
|---|---|---|---|---|
| `[ ]` | `[ ]` | Instalación desde cero (CP-08) | | `entregables/05-informe-pruebas/capturas/CP-08-1.png` |
| 24/11/2026 | Keity | Sesión con usuario P1 | Guió y anotó la sesión (T0–T3, perfil y formulario) | Bitácora §3 y capturas `P1-T0` a `P1-T3` |
| 24/11/2026 | Cristopher | Sesión con usuario P2 | Guió y anotó la sesión, asignó superior y curso en la web | Bitácora §4 y capturas `P2-T0` a `P2-T3` |
| 27/11/2026 | Cristopher | Sesión con usuario P3 | Guió y anotó la sesión con una docente (T0–T3, formulario, machote oficial) | Bitácora §5 |
| 27/11/2026 | Cristopher | Backend de producción y cuentas de evaluación | Limpieza de cuentas y datos de prueba; cuentas nuevas con superior y curso en III Ciclo - 2027 | Aplicación distribuible §3 |
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
