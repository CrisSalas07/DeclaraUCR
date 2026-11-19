# Pruebas técnicas — DeclaraUCR

Casos de prueba de la §7 del descriptor del Proyecto 2: los tres procesos de la §5.1, datos incompletos o
inválidos, restricciones por rol, persistencia y recuperación, pérdida de conectividad e instalación de la
versión distribuida. Cada caso registra precondiciones, pasos, resultado esperado, resultado obtenido, versión
y evidencia.

| | |
|---|---|
| **Versión evaluada** | 2.0.0+5 · commit `fc21a84` ([release v2.0.0+5](https://github.com/CrisSalas07/DeclaraUCR/releases/tag/v2.0.0%2B5)) |
| **Backend** | Firebase del Proyecto 1 (`declarahorario-b186f`), el mismo de la web DeclaraHorario |
| **Cuentas** | Las de prueba de [INSTALACION.md](INSTALACION.md) §2 (los correos y las contraseñas se entregan aparte) |
| **Datos** | Ficticios (sede, carrera, período y cursos de [INSTALACION.md](INSTALACION.md) §6) |
| **Evidencia** | Capturas en `docs/pruebas/`, con el número del caso (por ejemplo `CP-01-1.png`) |

**Ejecución.** CP-01, CP-02, CP-04, CP-05 y CP-07 se ejecutaron el 2026-11-19 en un Samsung Galaxy A34
(Android 16, letra al 110 %) con un build de desarrollo del **mismo commit `fc21a84`** de la 2.0.0+5, contra los
emuladores con las reglas del Proyecto 1 y los datos ficticios de `backend/proyecto1/seed.mjs` (cuentas
`docente`, `docente2` y `revisor`). Así las capturas no muestran datos de las cuentas reales del equipo y los
casos se pueden repetir desde cero. CP-03, CP-06 y CP-08 se ejecutan con el APK publicado y el backend real.
En las capturas se taparon los íconos de notificaciones de la barra de estado del teléfono.

Cómo llenar cada caso: **Resultado obtenido** describe lo que pasó; **Estado** es *Aprobado*, *Fallido* o
*Pendiente*. Un caso fallido se registra como defecto (sección final), se corrige y se vuelve a ejecutar.

## Resumen

| Caso | Cubre | Estado |
|---|---|---|
| [CP-01](#cp-01) | Proceso 1: crear, editar y recuperar un borrador | Aprobado |
| [CP-02](#cp-02) | Proceso 2: horario, cálculo de horas y traslapes | Aprobado |
| [CP-03](#cp-03) | Proceso 3: resumen, validación y estado (hasta la firma) | Pendiente |
| [CP-04](#cp-04) | Datos incompletos o inválidos | Aprobado |
| [CP-05](#cp-05) | Restricciones de acceso por rol | Aprobado |
| [CP-06](#cp-06) | Persistencia y recuperación | Pendiente |
| [CP-07](#cp-07) | Pérdida de conectividad | Aprobado |
| [CP-08](#cp-08) | Instalación y ejecución de la versión distribuida | Pendiente |

---

## CP-01

**Proceso 1: crear, editar y recuperar una declaración en borrador.**

| | |
|---|---|
| **Precondiciones** | Sesión iniciada con la declarante **con cursos**. Período II Ciclo - 2026 habilitado y sin declaración suya en él. Con conexión |
| **Pasos** | 1. En **Declaraciones**, tocar **Nueva declaración**.<br>2. Elegir el **Puesto** y tocar **Guardar borrador**.<br>3. Cerrar la app por completo (quitarla de las apps recientes) y volver a abrirla.<br>4. En **Inicio**, tocar **Continuar** en la declaración más reciente.<br>5. Agregar un proyecto (por ejemplo, 2 h) y **Guardar borrador**.<br>6. Volver a la lista y abrirla otra vez |
| **Resultado esperado** | 2: aviso "Borrador guardado." y la declaración aparece en la lista como **BORRADOR**, con el período, los cursos de la Coordinación y las clases ya ubicadas.<br>3–4: al reabrir la app, el borrador sigue ahí con el puesto elegido.<br>6: conserva el proyecto agregado. Solo hay una declaración por período |
| **Resultado obtenido** | 2: "Borrador guardado."; en la lista, **BORRADOR** con II Ciclo - 2026, IF0009 e IF4001 y 8 h (las clases de la Coordinación ya ubicadas).<br>3–4: después de cerrar la app por completo (sin proceso), al reabrirla Inicio muestra la declaración en Elaboración con **Continuar**; abre "Editar declaración" con el puesto Interino Licenciado.<br>6: al reabrirla desde la lista conserva "Proyecto de investigacion · 2 h por semana" |
| **Versión** | 2.0.0+5 (`fc21a84`), build de desarrollo contra los emuladores con datos ficticios |
| **Evidencia** | `CP-01-1.png` (lista con el borrador), `CP-01-2.png` (borrador recuperado con el proyecto) |
| **Estado** | Aprobado |

## CP-02

**Proceso 2: registro de horarios, cálculo de horas y detección de traslapes.**

| | |
|---|---|
| **Precondiciones** | El borrador de CP-01. Con conexión |
| **Pasos** | 1. En **Horario semanal**, elegir **IF0009 · Atención** y tocar dos medias horas libres del lunes después de la clase.<br>2. Con **IF0009 · Atención** elegido, tocar una media hora de la clase del lunes (8:00–10:00).<br>3. Ubicar el resto de la atención y la planificación de los dos cursos (mantener presionado y deslizar marca varias medias horas seguidas).<br>4. Tocar **Ver resumen** |
| **Resultado esperado** | 1: el bloque aparece en la cuadrícula y sube "Ubicado: X h de 20 h".<br>2: la clase no cambia y aparece "Las clases las asigna la Coordinación de su carrera: no se mueven." Cada media hora tiene una sola tarea, así que en el teléfono no se puede crear un traslape.<br>4: **Total de horas** y **Horas por categoría** (Clases, Atención, Planificación) suman lo ubicado; cada categoría muestra "x h de y h" según la jornada de cada curso |
| **Resultado obtenido** | 1: la atención queda de 10:00 a 11:00 (1 h) y el día pasa a 3 h.<br>2: la clase no cambia y aparece "Las clases las asigna la Coordinación de su carrera: no se mueven."<br>3: con todas las tareas ubicadas, "Ubicado: 22 h de 22 h" (20 h de los cursos y 2 h del proyecto de CP-01).<br>4: "Sin problemas: la declaración puede validarse.", Total de horas 22 h; Clases 8 h de 8 h, Atención 4 h de 4 h, Planificación 8 h de 8 h, Proyectos 2 h de 2 h; **Validar** habilitado |
| **Versión** | 2.0.0+5 (`fc21a84`), build de desarrollo contra los emuladores con datos ficticios |
| **Evidencia** | `CP-02-1.png` (atención ubicada y mensaje de clase fija), `CP-02-2.png` (horas por categoría en el resumen) |
| **Estado** | Aprobado |

La **detección de traslapes** (por ejemplo, de una declaración editada en la web con dos tareas a la misma
hora, o entre instituciones) la prueba de forma automatizada `test/data/proyecto1_write_test.dart`
("test 02: with an overlap it does not become VALIDADA") y `test/domain/overlap_detector_test.dart`: un
traslape bloquea la validación con el mensaje "Traslape el lunes entre … y …".

## CP-03

**Proceso 3: resumen, validaciones y estado de la declaración.**

| | |
|---|---|
| **Precondiciones** | El borrador de CP-02 con todas las horas ubicadas. Con conexión |
| **Pasos** | 1. En el resumen, revisar el estado y tocar **Validar**.<br>2. Revisar el botón y el ícono rojo del PDF; abrir el PDF.<br>3. Tocar **Firmar y enviar a mi revisor** (tarjeta "Siguiente paso: firmar"), leer el juramento, marcar la casilla y firmar.<br>4. Volver a **Inicio** |
| **Resultado esperado** | 1: "Sin problemas: la declaración puede validarse." → aviso "Declaración validada y guardada." y estado **VALIDADA**.<br>2: el botón dice **Validada** y queda deshabilitado; el PDF muestra la marca "BORRADOR".<br>3: aviso "Declaración firmada y enviada a su revisor."; estado **PENDIENTE_FIRMA_SUPERIOR**.<br>4: el seguimiento muestra Elaboración ✓, Firmada ✓ y **Revisor** resaltado, con "Firmada y enviada: su revisor la está revisando."; el PDF pasa a "COPIA PARA REVISIÓN" con la firma |
| **Resultado obtenido** | |
| **Versión** | 2.0.0+5 |
| **Evidencia** | `CP-03-1.png` (validada), `CP-03-2.png` (firma), `CP-03-3.png` (seguimiento en Inicio) |
| **Estado** | Pendiente |

> La firma queda registrada en el backend real y la persona declarante no puede deshacerla. Para repetir el
> caso, el revisor **devuelve** la declaración desde la web y se corrige como versión nueva.

## CP-04

**Datos incompletos o inválidos.**

| | |
|---|---|
| **Precondiciones** | Sesión de una declarante con cursos y **sin** declaración en el período (otra cuenta, o después de que el revisor devuelva la de CP-03). Con conexión |
| **Pasos** | 1. **Nueva declaración** y, sin elegir el puesto, tocar **Guardar borrador**.<br>2. Tocar **Ver resumen** sin ubicar atención ni planificación.<br>3. Volver, elegir el puesto y abrir de nuevo el resumen |
| **Resultado esperado** | 1: se guarda igual (es un borrador) con el aviso "Borrador guardado. Falta 1 dato obligatorio."; el campo marca "Este campo es obligatorio." y arriba dice "5 de 6 datos obligatorios".<br>2: "Hay N puntos por corregir", con "Falta: Puesto." y cada hora faltante ("Faltan 2 h de atención a estudiantes de IF0009 en el horario.", …); **Validar** deshabilitado.<br>3: desaparece "Falta: Puesto."; siguen las horas faltantes y **Validar** sigue deshabilitado |
| **Resultado obtenido** | 1: "Borrador guardado. Falta 1 dato obligatorio.", el campo **Puesto** en rojo con "Este campo es obligatorio." y "5 de 6 datos obligatorios".<br>2: "Hay 5 puntos por corregir": "Falta: Puesto." y las cuatro horas faltantes ("Faltan 2 h de atención a estudiantes de IF0009 en el horario.", …); **Validar** deshabilitado.<br>3: "Hay 4 puntos por corregir" (desaparece "Falta: Puesto."); **Validar** sigue deshabilitado |
| **Versión** | 2.0.0+5 (`fc21a84`), build de desarrollo contra los emuladores con datos ficticios |
| **Evidencia** | `CP-04-1.png` (campo obligatorio), `CP-04-2.png` (puntos por corregir) |
| **Estado** | Aprobado |

## CP-05

**Restricciones de acceso por rol.**

| | |
|---|---|
| **Precondiciones** | Cuentas de prueba: **revisor o Coordinación** (sin rol de declarante) y **declarante sin cursos**. Con conexión |
| **Pasos** | 1. Iniciar sesión con la cuenta de revisor o Coordinación.<br>2. Cerrar sesión e iniciar con la declarante sin cursos.<br>3. Tocar **Nueva declaración** |
| **Resultado esperado** | 1: pantalla "No puede continuar" con "Esta aplicación es para personas declarantes." y el rol de la cuenta; solo deja **Cerrar sesión**.<br>3: "La Coordinación de su carrera aún no le asignó cursos en II Ciclo - 2026." y no se crea nada |
| **Resultado obtenido** | 1: con la cuenta de revisor, "No puede continuar", "Esta aplicación es para personas declarantes." y "Su cuenta tiene el rol de Revisor. Use el sistema web de declaraciones para sus funciones."; solo **Cerrar sesión**.<br>3: con la declarante sin cursos, "La Coordinación de su carrera aún no le asignó cursos en II Ciclo - 2026." y la lista sigue vacía |
| **Versión** | 2.0.0+5 (`fc21a84`), build de desarrollo contra los emuladores con datos ficticios |
| **Evidencia** | `CP-05-1.png` (cuenta sin rol de declarante), `CP-05-2.png` (sin cursos) |
| **Estado** | Aprobado |

Los mismos controles están en las **reglas del backend**, no solo en la app: `backend/proyecto1/verify.mjs`
comprueba contra las reglas del Proyecto 1 que una persona no lee la declaración, la asignación ni el zonaje
de otra, no crea dos declaraciones en un período y no se salta la firma; `integration_test/sign_rules_test.dart`,
que el revisor lee exactamente lo firmado y que no se firma dos veces.

## CP-06

**Persistencia y recuperación de información.**

| | |
|---|---|
| **Precondiciones** | La declaración firmada de CP-03. Acceso a la web <https://declarahorario-b186f.web.app> |
| **Pasos** | 1. En la web, iniciar sesión con la misma declarante y abrir la declaración.<br>2. En el teléfono, cerrar sesión y volver a iniciarla.<br>3. Abrir la declaración en el teléfono |
| **Resultado esperado** | 1: la web muestra la misma declaración: estado, horario, cursos y la firma de la declarante.<br>2: tras volver a entrar aparecen las mismas declaraciones (los datos están en el servidor, no solo en el teléfono).<br>3: queda de **solo lectura** (firmada): no se editan el puesto ni el horario y no aparece **Guardar borrador** habilitado; el PDF sí se abre |
| **Resultado obtenido** | |
| **Versión** | 2.0.0+5 |
| **Evidencia** | `CP-06-1.png` (la declaración en la web), `CP-06-2.png` (solo lectura en el teléfono) |
| **Estado** | Pendiente |

## CP-07

**Pérdida de conectividad o indisponibilidad del servicio.**

| | |
|---|---|
| **Precondiciones** | Sesión iniciada con un borrador abierto en el formulario. Con conexión al empezar |
| **Pasos** | 1. Activar el **modo avión**.<br>2. Cambiar algo del borrador (por ejemplo, el puesto) y tocar **Guardar borrador**.<br>3. Abrir el PDF de una declaración validada o firmada.<br>4. Desactivar el modo avión y volver a tocar **Guardar borrador** |
| **Resultado esperado** | 1: en todas las pantallas aparece la franja "Sin conexión: ve lo último guardado en el teléfono. Para guardar cambios necesita conexión."<br>2: no se guarda y aparece "Sin conexión. Sus cambios siguen en pantalla: guárdelos cuando vuelva la señal."; el cambio sigue en pantalla.<br>3: "Sin conexión: el PDF se genera con los datos del servidor. …" con **Intentar de nuevo**; la app no se cierra.<br>4: "Borrador guardado." y el cambio queda guardado (al reabrirlo sigue ahí) |
| **Resultado obtenido** | 1: con el modo avión y el Wi-Fi apagados, aparece arriba la franja "Sin conexión: ve lo último guardado en el teléfono. Para guardar cambios necesita conexión."<br>2: al guardar, "Sin conexión. Sus cambios siguen en pantalla: guárdelos cuando vuelva la señal."; el puesto elegido sigue en pantalla.<br>4: al volver la conexión, "Borrador guardado."; al reabrir la declaración desde la lista conserva el puesto.<br>3 (ejecutado después del 4, porque abrir el PDF obliga a salir del formulario): sin conexión, "Sin conexión: el PDF se genera con los datos del servidor. Revise la conexión e intente de nuevo." con **Intentar de nuevo**; la app no se cerró (mismo proceso) |
| **Versión** | 2.0.0+5 (`fc21a84`), build de desarrollo contra los emuladores con datos ficticios |
| **Evidencia** | `CP-07-1.png` (franja y aviso al guardar), `CP-07-2.png` (guardado al volver la señal), `CP-07-3.png` (PDF sin conexión) |
| **Estado** | Aprobado |

## CP-08

**Instalación y ejecución de la versión distribuida.**

| | |
|---|---|
| **Precondiciones** | Un teléfono Android 7.0 o superior **distinto del usado para desarrollar** y sin DeclaraUCR. El APK `DeclaraUCR-v2.0.0+5-fc21a84.apk` del release y, para el paso 4, el de la 2.0.0+4 |
| **Pasos** | 1. Descargar e instalar el APK siguiendo [INSTALACION.md](INSTALACION.md) §1.<br>2. Abrirla y revisar la versión en el inicio de sesión.<br>3. Iniciar sesión con la declarante con cursos y abrir su declaración.<br>4. Volver a la versión anterior y otra vez a la 2.0.0+5 ([INSTALACION.md](INSTALACION.md) §3 y §4) |
| **Resultado esperado** | 1: se instala sin errores de firma.<br>2: al pie, "Versión 2.0.0+5 · fc21a84".<br>3: entra y muestra los datos del backend real.<br>4: cada cambio de versión funciona como indica la guía, sin perder la sesión ni los datos guardados en el servidor |
| **Resultado obtenido** | |
| **Versión** | 2.0.0+5 |
| **Evidencia** | `CP-08-1.png` (versión en el inicio de sesión), modelo del teléfono y versión de Android |
| **Estado** | Pendiente |

---

## Pruebas automatizadas

Reglas de negocio de mayor riesgo (§7), con `flutter test` (107 pruebas, todas pasan en `fc21a84`):

| Qué cubren | Dónde |
|---|---|
| Traslapes (en el día, entre instituciones, por vigencia) | `test/domain/overlap_detector_test.dart`, `test/domain/declaration_validator_test.dart` ("mandatory case: Monday 8:00-12:00 and 11:00-14:00 overlap"), `test/data/proyecto1_write_test.dart` (test 02) |
| Cálculo de horas por curso, jornada y tarea | `test/domain/rules_test.dart` ("a course derives its hours from the workday"), `test/domain/declaration_validator_test.dart` (horas faltantes y de más, más de un tiempo completo) |
| Cuadrícula: almuerzo, máximo por día y clases fijas de la Coordinación | `test/domain/schedule_grid_test.dart` |
| Campos obligatorios y validaciones | `test/widget_test.dart` (test 03), `test/domain/declaration_validator_test.dart` |
| Transiciones de estado y escritura en el esquema del P1 | `test/data/proyecto1_write_test.dart`, `test/data/declaration_signer_test.dart` |
| Huella SHA-256 de la firma, igual a la de la web | `test/domain/content_hash_test.dart` (comparada con un valor de DeclaraHorario) |
| PDF y juramento | `test/data/declaration_document_test.dart` |
| Sin conexión | `test/connectivity_test.dart` |
| Pantalla pequeña sin desbordes (360 × 690 dp) | `test/widget_test.dart` (test 05) |

Contra las **reglas reales del Proyecto 1** en los emuladores (ver `backend/proyecto1/README.md`):
`backend/proyecto1/verify.mjs` (lecturas, procesos 1 a 3 y accesos indebidos) e
`integration_test/sign_rules_test.dart` (la firma desde el código de la app).

## Defectos corregidos y nueva comprobación

Encontrados al probar en un teléfono físico (Samsung Galaxy A34, Android 16) antes de la versión evaluada.

| Defecto | Corrección | Nueva comprobación |
|---|---|---|
| Un período deshabilitado en la web seguía apareciendo al crear una declaración (se leía la copia del teléfono) | `0be0200` (2.0.0+3) | Prueba automatizada "a period closed after a first read is no longer offered"; en el teléfono, el período cerrado ya no aparece |
| La sección de cursos aparecía dos veces en el formulario | `ef42e47` (2.0.0+3) | Revisado en el teléfono: una sola sección |
| La vista previa del PDF no dejaba acercar ni alejar | `4d3184f` (2.0.0+3) | En el teléfono: pellizcar acerca y aleja; doble toque vuelve a la página completa |
| Con la letra del teléfono al 110 %, el seguimiento y la barra inferior cortaban palabras | `f633fb8` (2.0.0+5) | Prueba automatizada actualizada; captura `docs/capturas/01-inicio.png` con la letra al 110 % |

Defectos encontrados al ejecutar los casos de este documento:

| Caso | Defecto | Corrección | Nueva comprobación |
|---|---|---|---|
| CP-01, 02, 04, 05, 07 | Ninguno (2026-11-19) | — | — |
| | | | |
