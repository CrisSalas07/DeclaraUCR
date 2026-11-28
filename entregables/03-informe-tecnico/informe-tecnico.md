# Informe técnico — DeclaraUCR

**Proyecto 2 · IF0009 Desarrollo de Software IV · UCR Sede del Sur**
Evolución del Sistema de Declaraciones Juradas de Horario y Jornada de Trabajo hacia una aplicación móvil.

Versión descrita: **2.0.0+11** · Repositorio: <https://github.com/CrisSalas07/DeclaraUCR> ·
Sistema web del Proyecto 1: DeclaraHorario (<https://declarahorario-b186f.web.app>).

---

## 1. Contexto y propósito

Cada ciclo, el personal docente de la Sede del Sur tiene que declarar bajo juramento su horario y su jornada:
las clases que le asignó la Coordinación, las horas de atención a estudiantes y de planificación que se derivan
de cada curso, los proyectos y cualquier trabajo en otra institución. El resultado es el formulario oficial de
Recursos Humanos. Los dos errores que el sistema busca evitar son las horas que no cuadran con la jornada y los
horarios que se traslapan.

El Proyecto 1 (DeclaraHorario) llevó el trámite completo a un sistema web: la Coordinación asigna cursos, la
persona declarante llena su horario en una cuadrícula que valida horas y traslapes, firma, y la declaración
pasa al superior y a RRHH.

El Proyecto 2 lleva **la parte de la persona declarante** al teléfono. La declaración se llena cuando la
Coordinación ya asignó los cursos del ciclo; con la app, la persona puede empezarla, revisar qué le falta y
firmarla desde donde esté, sin depender de una computadora. Lo que hacen el superior,
RRHH y Administración sigue en la web, donde tiene más sentido: son revisiones largas con el PDF y varias
declaraciones abiertas a la vez.

## 2. Alcance y procesos

### 2.1 Procesos del Proyecto 1 y su implementación móvil

| Proceso en el Proyecto 1 (web) | En el móvil | Cómo se adaptó |
|---|---|---|
| Registro y perfil (cédula, teléfono, sede, carrera) | **Sí** | Mismo esquema `users/{uid}` y reserva de cédula `identifications/CEDULA_{n}`; sede y carrera se eligen una vez; nombre, cédula y teléfono se corrigen desde el perfil (U-07) |
| **Crear, editar y recuperar una declaración en borrador** (§5.1-1) | **Sí — proceso 1** | Un período abierto, una declaración por período; nombre, cédula, institución, período y vigencia vienen del perfil y del período; la persona solo elige el puesto |
| **Registro de horarios, cálculo de horas y traslapes** (§5.1-2) | **Sí — proceso 2** | La cuadrícula de medias horas de la web, un día a la vez; clases fijas de la Coordinación; cada tarea muestra "x h de y h" y nunca toma más |
| **Resumen, validaciones y estado** (§5.1-3) | **Sí — proceso 3** | Resumen con horas por categoría, lista de puntos por corregir y botón **Validar** que solo se activa sin problemas; seguimiento de 5 pasos en Inicio |
| Firma de la persona declarante | **Sí** | Misma huella SHA-256 del contenido y mismo registro de la firma; el juramento es el del formulario oficial, o la plantilla de Administración si existe (matriz U-08); envía al superior |
| PDF de la declaración | **Sí** (consulta) | Mismo formulario oficial: vista previa "BORRADOR", copia en revisión y documento final |
| Historial por año | **Sí** | Declaraciones y solicitudes de zonaje de todos los períodos |
| Zonaje | **Consulta** | Estado, distancias y respuesta de RRHH; la solicitud se hace en la web (necesita mapa y la certificación del TSE) |
| Asignación de cursos (Coordinación) | No | Se hace en la web |
| Revisión y firma del superior, devolución | No | Se hace en la web |
| Recepción, PDF final y cierre (RRHH) | No | Se hace en la web |
| Administración de usuarios, sedes, carreras y períodos | No | Se hace en la web |

Los tres procesos de §5.1 están completos de punta a punta en el teléfono: se capturan o consultan datos, se
validan, se guardan en el backend del Proyecto 1 y se muestra el resultado. El inicio de sesión y la navegación
no se cuentan como procesos.

### 2.2 Roles

La app es para **personas declarantes**. Una cuenta de superior, Coordinación, RRHH o Administración que inicie
sesión ve "No puede continuar" con su rol y una indicación de usar la web (CP-05). El control no está solo en la
app: las reglas de Firestore del Proyecto 1 impiden que una persona lea o escriba la declaración, la asignación o
el zonaje de otra.

## 3. Arquitectura

### 3.1 Vista general

```
 Teléfono Android (Flutter)                          Firebase del Proyecto 1 (declarahorario-b186f)
 ┌──────────────────────────────────────┐            ┌────────────────────────────────────────────┐
 │ screens/ widgets/ theme/             │            │ Firebase Auth (correo y contraseña)        │
 │   Inicio · Declaraciones · Zonaje ·  │            │                                            │
 │   Historial · formulario · resumen · │   HTTPS    │ Cloud Firestore + firestore.rules del P1   │
 │   firma · PDF                        │◄──────────►│   users, identifications, periods,         │
 │ state/  (ChangeNotifier)             │            │   workloadAssignments, declarationSlots,   │
 │ domain/ (reglas puras en Dart)       │            │   declarations/{id}/versions/…/events,     │
 │ data/   (repositorios)               │            │   zonajeRequests                           │
 │ models/                              │            └────────────────────────────────────────────┘
 └──────────────────────────────────────┘                          ▲
                                                                    │ mismo backend, mismas reglas
                                                     ┌──────────────┴─────────────┐
                                                     │ Web DeclaraHorario (P1):   │
                                                     │ superior, RRHH, Coordinación │
                                                     │ y Administración            │
                                                     └─────────────────────────────┘
```

Web y móvil comparten cuentas, roles y declaraciones. Una declaración que la docente firma en el teléfono le
aparece al superior en la web con la misma versión, la misma bitácora y la misma huella (CP-06).

### 3.2 Capas

Las dependencias apuntan hacia adentro:

| Capa | Qué contiene | Ejemplos |
|---|---|---|
| Presentación | Pantallas y componentes en español, tema UCR | `shell_screen.dart`, `declaration_form_screen.dart`, `schedule_editor.dart`, `summary_screen.dart` |
| Estado | Coordina pantalla y datos; no conoce Firebase | `DeclarationFormState` (guardar, validar, cambios sin guardar), `Loadable<T>` |
| Dominio | Reglas de negocio en Dart puro, probadas sin Firebase | `OverlapDetector`, `DeclarationValidator`, `ScheduleGrid`, `CourseRules`, `WorkloadCatalog`, `ContentHash` |
| Datos | Interfaces y su implementación sobre Firestore | `DeclarationRepository` → `Proyecto1DeclarationRepository`, `DeclarationSigner`, `ZonajeRepository` |
| Modelos | Estructuras sin dependencias | `Declaration`, `ScheduleInterval`, `DeclarationStatus` |

Todo lo que pertenece a una persona (repositorios, perfil, flujos) se crea por encima del `MaterialApp` y se
indexa por su `uid`. Al cerrar sesión se descarta entero, así que no queda ningún dato ni suscripción de la
sesión anterior.

### 3.3 Reutilización del Proyecto 1

La capa de dominio vino casi sin cambios de la web: detección de traslapes, reglas de tiempo, el contrato de
validación (los mensajes dicen el día, los intervalos y la hora exacta del choque), los nombres de estado, la
cuadrícula de medias horas, el catálogo de jornadas y las horas de cada curso (VD-12928-2024, VD-13015-2024),
el formato de observaciones y la huella SHA-256. Lo que se reescribió fueron las pantallas. Desde la 2.0.0+11 las
observaciones unen los horarios con «y», como el machote oficial (matriz U-10); la web del P1 sigue usando coma.

## 4. Decisiones de adaptación móvil

| Problema en un teléfono | Decisión | Por qué |
|---|---|---|
| La cuadrícula semanal de la web no cabe en 360 dp | Un día a la vez, filas de media hora a todo el ancho; pestañas de Lun a Sáb con las horas de cada día | Cada media hora ocupa todo el ancho de la pantalla, así que el blanco táctil es grande aunque la fila mida 40 dp de alto |
| Marcar horas una por una es lento | Tocar marca una media hora; **mantener presionado y deslizar** marca un rango; **Copiar a otros días** repite un día | Mantener presionado no compite con el desplazamiento de la página, como sí lo haría un arrastre simple |
| Traslapes | En la cuadrícula cada media hora tiene una sola tarea, así que en el teléfono no se puede crear un traslape. El validador igual revisa lo guardado (por ejemplo, algo editado en la web) | Prevenir es mejor que avisar después |
| Errores de digitación | Todo salvo los nombres se elige de una lista o se ubica en la cuadrícula; las observaciones se escriben solas a partir del horario | El teclado del teléfono es la mayor fuente de errores |
| Estados largos (`PENDIENTE_FIRMA_DECLARANTE`) | Etiquetas legibles ("Pendiente de firma del superior") debajo del título, nunca al lado | Con letra grande no se cortan |
| Zonaje necesita mapa y un archivo del TSE | Solo consulta en el teléfono | Elegir un punto en un mapa y adjuntar un PDF en un teléfono es frágil; la web ya lo resuelve |
| Salir sin guardar (D-01) | El formulario pregunta antes de descartar cambios | §5: nada se pierde sin que la persona lo sepa |
| Lector de pantalla (D-02) | Cada media hora es un botón para TalkBack con día, hora y contenido | La cuadrícula era el único paso que no se podía hacer sin ver |
| Primer uso (U-06) | Recorrido guiado sobre las pantallas reales con una docente de ejemplo; enfoca una parte a la vez y se repite desde el perfil («Cómo funciona») | En las sesiones, sin guía no se entendía la cuadrícula; el recorrido no guarda nada |
| Ubicar horas alrededor de las clases (U-09, pedido por una docente en las pruebas) | Arriba de los días, **Horario de sus clases** muestra los días y horas de cada curso; tocar uno abre ese día | Un día a la vez oculta el resto de la semana |

## 5. Integración con autenticación, servicios y persistencia

- **Autenticación:** Firebase Auth con correo y contraseña. El dominio permitido es el del Proyecto 1. Tras
  iniciar sesión, la app lee `users/{uid}`: si el perfil está incompleto pide sede y carrera; si la cuenta no
  es declarante o está inactiva, no deja continuar.
- **Escritura en el esquema del Proyecto 1:** la app escribe como lo hace la web. Crear un borrador es un solo
  lote (declaración, versión 1, evento, reserva del período y contenido). Validar pasa `BORRADOR → VALIDADA`
  con el evento `VALIDACION_EJECUTADA` y el resumen de horas; editar algo validado lo devuelve a `BORRADOR`
  con `HORARIO_MODIFICADO`. La firma registra los eventos y la firma con id fijo, y bloquea la versión con la
  huella.
- **Reglas:** las del Proyecto 1, sin cambios. Este repositorio nunca las despliega: se publican desde
  DeclaraHorario. La copia en `backend/proyecto1/` solo se usa con los emuladores.
- **Conectividad:** una franja en todas las pantallas avisa cuando no hay red. Cada guardado lee primero del
  servidor, así que sin red falla de inmediato en lugar de quedar en cola; espera como máximo 15 s y, si no hay
  respuesta, lo dice. Los cambios quedan en pantalla para guardarlos cuando vuelva la señal (CP-07).
- **Datos que no se confían:** cada documento leído se revisa campo por campo; uno mal formado se salta y se
  registra en el log en lugar de romper la lista. Los detalles técnicos de un error nunca llegan a la pantalla.

## 6. Despliegue de prueba

| Elemento | Cómo está |
|---|---|
| Backend | Firebase del Proyecto 1, accesible desde cualquier teléfono con internet; no depende de la computadora de desarrollo |
| APK | `dart run tool/build_apk.dart`: se niega a compilar con cambios sin commit o sin la llave del equipo, y deja `dist/DeclaraUCR-v{versión}-{commit}.apk` con un `.txt` que trae versión, commit, backend, firma y SHA-256 |
| Distribución | GitHub Releases, una por versión (`v2.0.0+2` a `v2.0.0+6` publicadas el 18 y 19/11/2026, `v2.0.0+7` el 20/11/2026 y `v2.0.0+8` a `v2.0.0+11` el 27/11/2026) |
| Firma | Llave de release del equipo, fuera del repositorio. Todas las versiones con la misma llave, así que actualizar encima funciona |
| Actualizar | Instalar el APK nuevo encima; se conserva la sesión |
| Volver atrás | Desinstalar e instalar el APK anterior del release; no se pierde nada porque los datos están en Firebase |
| Cuentas de prueba | Declarante con cursos, declarante sin cursos y superior, con datos ficticios en el backend real (`entregables/02-aplicacion-distribuible/instalacion.md` §6). Correos y contraseñas por canal privado |
| Entorno local reproducible | Emuladores de Firebase con las reglas del P1 y datos ficticios (`backend/proyecto1/README.md`) |

El procedimiento paso a paso está en `entregables/02-aplicacion-distribuible/instalacion.md`, y la guía para la persona usuaria en
`entregables/07-guia-uso/`.

## 7. Calidad y pruebas

- 124 pruebas automatizadas, todas pasan; `flutter analyze` sin problemas.
- 8 casos técnicos; CP-01 a CP-07 aprobados, CP-08 (instalación desde cero) `[COMPLETAR]`.
- Detalle en `entregables/05-informe-pruebas/informe-pruebas.md`.

## 8. Limitaciones conocidas

- `VALIDADA` lo calcula el cliente, igual que en la web del Proyecto 1. Las reglas validan formato y permisos,
  no recalculan horas. Propuesta: una Cloud Function que recalcule y rechace una validación inválida.
- La firma es la firma electrónica interna del sistema, no una firma digital certificada.
- Sin conexión no se guarda; si se cierra la app sin señal, se pierde lo que estaba en pantalla.
- Un nombramiento por declaración: si en la web se agregó más de uno, el teléfono edita el primero y deja los
  demás como están.
- No incluido en el móvil: verificación del correo, registro con pasaporte, revisión, RRHH y Administración.
- Las observaciones no llevan el **grupo** del curso («IF0004 G2» en el machote oficial): el esquema del P1 no lo
  guarda. Agregarlo es un cambio de la web y del esquema (matriz U-10).
- La pantalla de carga con la firma promocional (manual de identidad, p. 122) no se hizo: ese recurso solo está
  en el paquete privado de la ODI.

## 9. Referencias

- Descriptor del Proyecto 2, IF0009, II ciclo 2026.
- *Manual de identidad visual*, Universidad de Costa Rica, ODI, 3.ª ed., 2019.
- *Aplicación accesible de la paleta institucional en medios digitales de la UCR*, Centro de Informática, 2025.
- `entregables/03-informe-tecnico/comparacion-backend-p1.md` (comparación de esquemas web y móvil).
