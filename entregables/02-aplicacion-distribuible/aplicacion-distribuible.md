# Aplicación distribuible — DeclaraUCR

**Proyecto 2 · IF0009 · Entregable 2 (§6 del descriptor)**

## 1. Identificación de la versión

| | |
|---|---|
| Versión a entregar | **2.0.0+11** (observaciones y PDF como el formulario oficial, sobre el horario de las clases, el juramento oficial, el recorrido guiado, las correcciones de las sesiones y el rol «Superior») |
| Commit | `b64791b` (etiqueta `v2.0.0+11`) |
| Archivo | `DeclaraUCR-v2.0.0+11-b64791b.apk` |
| SHA-256 | `c5b2df657d749bef62a7d5fadf5413c18b4048f0719ed670d9f2a36601e3e93a` |
| Descarga | <https://github.com/CrisSalas07/DeclaraUCR/releases/tag/v2.0.0%2B11> · versiones anteriores: <https://github.com/CrisSalas07/DeclaraUCR/releases> |
| Cómo se ve en la app | Al pie del inicio de sesión y en el perfil: "Versión 2.0.0+11 · b64791b" |

Versiones ya publicadas: v2.0.0+2, +3 (prelanzamientos), v2.0.0+4, +5 y +6 (19/11/2026), v2.0.0+7 (20/11/2026), v2.0.0+8, +9, +10 y +11 (27/11/2026).

## 2. Entorno de prueba accesible

- **Backend:** Firebase del Proyecto 1 (`declarahorario-b186f`), el mismo de la web DeclaraHorario. El teléfono
  solo necesita internet: no depende de ninguna computadora del equipo.
- **Web del Proyecto 1** (para superior, RRHH y Coordinación): <https://declarahorario-b186f.web.app>
- **Requisitos del teléfono:** Android 7.0 o superior, unos 60 MB libres, conexión a internet.

## 3. Cuentas de evaluación

Los correos y las contraseñas **no van en este documento ni en el repositorio**: se entregan al docente por
mensaje privado al docente en **Mediación Virtual**.

| Rol | Para qué sirve | Datos con los que viene |
|---|---|---|
| Declarante con superior y curso | Recorrer los tres procesos y la firma | Sede del Sur, Informática Empresarial; en **III Ciclo - 2027**, IF0009 *Base de datos II* (20 h por semana) con clases el martes de 7:30 a 12:00 y el viernes de 13:30 a 17:00, asignadas por la Coordinación; sin declaración todavía |
| Coordinación y superior | En la web: asignar cursos y revisar lo firmado desde el teléfono; en la app, ver que es solo para declarantes | Superior de la declarante; asignó su curso |
| Declarantes P1, P2, P3 | Sesiones con usuarios (§8): las crea cada participante en la sesión, con su correo y su contraseña (el equipo no las conoce) | Cédula y teléfono ficticios; superior y los mismos cursos de prueba asignados por el equipo en la web; se desactivan al terminar |

El 27/11/2026 se limpió el backend (solo quedó la cuenta de Administración y los catálogos) y se crearon estas
cuentas. Revisado ese día en Firebase: la declarante tiene superior y su curso en «III Ciclo - 2027», y no tiene
ninguna declaración, así que el docente puede recorrer los tres procesos desde cero. Si se firma una, no se
deshace: para repetir, el superior la devuelve desde la web. No hay cuenta de declarante sin cursos: CP-05 se
probó con los datos ficticios de los emuladores (`entregables/05-informe-pruebas/pruebas-tecnicas.pdf`).

## 4. Datos ficticios

Sede, carrera, período, cursos y franjas de clase son ficticios y se crean desde la web del Proyecto 1 con una
cuenta de Administración (pasos en `entregables/02-aplicacion-distribuible/instalacion.docx` §6). Para pruebas locales repetibles existen además
los datos de `backend/proyecto1/seed.mjs` (emuladores).

## 5. Instalación, actualización y vuelta atrás

Procedimiento completo: `entregables/02-aplicacion-distribuible/instalacion.docx` §1 a §4. Para la persona usuaria, con capturas: la guía de uso
(`entregables/07-guia-uso/`). En resumen:

1. **Instalar:** descargar el APK del release, abrirlo, permitir "instalar apps de fuentes desconocidas" y, si
   aparece Google Play Protect, elegir **Instalar de todas formas**.
2. **Actualizar:** instalar el APK nuevo encima; la sesión se conserva (misma llave de firma y número de versión
   mayor).
3. **Volver a la versión anterior:** desinstalar, descargar el APK anterior del release e instalarlo. No se
   pierde nada: los datos están en Firebase.

## 6. Instalación desde cero en otro dispositivo (§6)

La instalación desde cero en un teléfono distinto del de desarrollo (CP-08) no se ejecutó antes de esta entrega. El procedimiento, los resultados esperados y la evidencia que se debe tomar están en `entregables/05-informe-pruebas/pruebas-tecnicas.pdf` (CP-08) y el paso a paso en §1 a §4 de esta guía.

## 7. Limitaciones conocidas

Ver `entregables/02-aplicacion-distribuible/instalacion.docx` §7 y el informe técnico §8. Las más importantes para quien evalúa:

- La app es solo para personas declarantes; revisión, RRHH y Administración se hacen en la web.
- El zonaje se consulta en el teléfono, pero se solicita en la web.
- Sin conexión no se guarda (la app lo avisa y conserva los cambios en pantalla).
- `VALIDADA` lo calcula el cliente, igual que en la web del Proyecto 1.
