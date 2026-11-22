# Aplicación distribuible — DeclaraUCR

**Proyecto 2 · IF0009 · Entregable 2 (§6 del descriptor)**

## 1. Identificación de la versión

| | |
|---|---|
| Versión a entregar | **2.0.0+7** `[COMPLETAR: confirmar si se entrega esta o una posterior a la socialización]` |
| Commit | `0caae96` (etiqueta `v2.0.0+7`) |
| Archivo | `DeclaraUCR-v2.0.0+7-0caae96.apk` |
| SHA-256 | `15a92747d020e5203e1186f0e94709f6071e98c2706b419264fbda704727b019` |
| Descarga | <https://github.com/CrisSalas07/DeclaraUCR/releases/tag/v2.0.0%2B7> · versiones anteriores: <https://github.com/CrisSalas07/DeclaraUCR/releases> |
| Cómo se ve en la app | Al pie del inicio de sesión y en el perfil: "Versión 2.0.0+7 · 0caae96" |

Versiones ya publicadas: v2.0.0+2, +3 (prelanzamientos), v2.0.0+4, +5 y +6 (19/11/2026), v2.0.0+7 (20/11/2026).

## 2. Entorno de prueba accesible

- **Backend:** Firebase del Proyecto 1 (`declarahorario-b186f`), el mismo de la web DeclaraHorario. El teléfono
  solo necesita internet: no depende de ninguna computadora del equipo.
- **Web del Proyecto 1** (para revisor, RRHH y Coordinación): <https://declarahorario-b186f.web.app>
- **Requisitos del teléfono:** Android 7.0 o superior, unos 60 MB libres, conexión a internet.

## 3. Cuentas de evaluación

Los correos y las contraseñas **no van en este documento ni en el repositorio**: se entregan al docente por
`[COMPLETAR: canal privado, p. ej. mensaje en Mediación Virtual]`.

| Rol | Para qué sirve | Datos con los que viene |
|---|---|---|
| Declarante con revisor y cursos | Recorrer los tres procesos y la firma | Sede del Sur, Informática Empresarial, II Ciclo 2026, cursos asignados por la Coordinación (ficticios) |
| Declarante sin cursos | Ver el mensaje que explica por qué no puede crear la declaración (CP-05) | Misma sede y carrera, sin asignación |
| Revisor | Ver que la app es solo para declarantes; revisar en la web lo firmado desde el teléfono | Revisor de las dos declarantes |
| Declarantes P1, P2, P3 | Sesiones con usuarios (§8): las crea cada participante en la sesión, con su correo y su contraseña (el equipo no las conoce) | Cédula y teléfono ficticios; revisor y los mismos cursos de prueba asignados por el equipo en la web; se desactivan al terminar |

Revisado en el backend el 21/11/2026: las tres cuentas existen y están activas. La declarante con cursos tiene
IF0009 asignado en «II Ciclo - 2026» y su declaración de ese período está **firmada y pendiente de firma del
revisor**. `[COMPLETAR: antes de enviar las cuentas, que el revisor la devuelva desde la web para que el
docente pueda recorrer los tres procesos.]`

## 4. Datos ficticios

Sede, carrera, período, cursos y franjas de clase son ficticios y se crean desde la web del Proyecto 1 con una
cuenta de Administración (pasos en `docs/INSTALACION.md` §6). Para pruebas locales repetibles existen además
los datos de `backend/proyecto1/seed.mjs` (emuladores).

## 5. Instalación, actualización y vuelta atrás

Procedimiento completo: `docs/INSTALACION.md` §1 a §4. Para la persona usuaria, con capturas: la guía de uso
(`entregables/07-guia-uso/`). En resumen:

1. **Instalar:** descargar el APK del release, abrirlo, permitir "instalar apps de fuentes desconocidas" y, si
   aparece Google Play Protect, elegir **Instalar de todas formas**.
2. **Actualizar:** instalar el APK nuevo encima; la sesión se conserva (misma llave de firma y número de versión
   mayor).
3. **Volver a la versión anterior:** desinstalar, descargar el APK anterior del release e instalarlo. No se
   pierde nada: los datos están en Firebase.

## 6. Instalación desde cero en otro dispositivo (§6)

`[COMPLETAR]` con el resultado de CP-08 (`docs/PRUEBAS.md`):

| | |
|---|---|
| Teléfono | `[marca y modelo]` |
| Android | `[versión]` |
| ¿Es el teléfono de desarrollo? | No |
| Fecha | |
| ¿Se instaló sin errores? | |
| ¿Muestra la versión correcta al pie? | |
| ¿Entró con la cuenta de prueba y vio sus datos? | |
| Evidencia | `docs/pruebas/CP-08-1.png` |

## 7. Limitaciones conocidas

Ver `docs/INSTALACION.md` §7 y el informe técnico §8. Las más importantes para quien evalúa:

- La app es solo para personas declarantes; revisión, RRHH y Administración se hacen en la web.
- El zonaje se consulta en el teléfono, pero se solicita en la web.
- Sin conexión no se guarda (la app lo avisa y conserva los cambios en pantalla).
- `VALIDADA` lo calcula el cliente, igual que en la web del Proyecto 1.
