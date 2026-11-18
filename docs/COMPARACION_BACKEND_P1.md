# Comparación de datos: DeclaraUCR (móvil) vs. DeclaraHorario (Proyecto 1)

Objetivo: conectar la app móvil al Firebase del Proyecto 1 (`declarahorario-b186f`) sin cambiar sus reglas,
para que web y móvil compartan cuentas, roles y declaraciones.

Fuentes revisadas: `DeclaraHorario/docs/MODELO_FIRESTORE.md`, `DeclaraHorario/firestore.rules`,
`DeclaraHorario/lib/repositories/firestore_declaration_repository.dart`,
`firestore_version_content_repository.dart`, `firestore_workflow_service.dart`, y en este repositorio
`lib/data/` y `firestore.rules`.

## 1. Vista general

```
DeclaraUCR (hoy)                         DeclaraHorario (Proyecto 1)
────────────────                         ───────────────────────────
users/{uid}          {name, identification}     users/{uid}  {fullName, identification, identificationType,
identifications/{cédula}                                       phone, email, roles[], active, campusId, unitId,
declarations/{id}    ← todo en un documento                    superiorUid, salaryRegime}
zonajeRequests/{id}                             identifications/{CEDULA_número}
                                                periods/{año}_{ciclo}
                                                workloadAssignments/{periodo}_{uid}   ← cursos asignados por Coordinación
                                                declarationSlots/{periodo}_{uid}      ← una declaración por período
                                                declarations/{id}
                                                  ├─ versions/{versionId}
                                                  │    ├─ appointments/{id}   (nombramiento UCR + bloques)
                                                  │    ├─ externalJobs/{id}   (otra institución + bloques)
                                                  │    └─ signatures/{tipo}
                                                  └─ events/{id}              (auditoría)
                                                zonajeRequests/{periodo}_{uid}
```

## 2. Campo por campo

### Perfil (`users/{uid}`)

| DeclaraUCR | Proyecto 1 | Qué hacer |
|---|---|---|
| `name` | `fullName` | Renombrar |
| `identification` | `identification` + `identificationType` (`CEDULA`/`PASAPORTE`) | Agregar el tipo (`CEDULA` por defecto) |
| — | `phone`, `email` | Pedirlos en el registro |
| — | `roles: ['declarant']`, `active: true` | Fijos al registrarse (las reglas lo exigen) |
| — | `campusId`, `unitId` | "Completa tu perfil": elegir sede y carrera (una sola vez) |
| — | `superiorUid` | Lo asigna administración desde la web. **Sin él no se puede crear una declaración** |
| `identifications/{cédula}` | `identifications/CEDULA_{cédula}` | Cambiar el id de la reserva |
| Solo `@ucr.ac.cr` | `@ucr.ac.cr`, gmail, outlook, hotmail, live, zoho | La regla del P1 manda; ajustar `auth_rules.dart` |

### Declaración

| DeclaraUCR (`declarations/{id}`, plano) | Proyecto 1 | Qué hacer |
|---|---|---|
| `ownerUid` | `declarations.declarantUid` | Renombrar |
| `declarantName` | `declarations.declarantName` + `versions.declarantSnapshot.fullName` | Copiar del perfil |
| `identification` | `versions.declarantSnapshot.identification` | Copiar del perfil |
| `institution` (fija) | `versions.declarantSnapshot.campusName` / `unitName` y `appointments.workplace` | Leer nombres de `campuses` y `units` |
| — | `declarations.periodId` | **Nuevo:** elegir un período habilitado |
| `validFrom`, `validTo` (los elige la persona) | `appointments.startDate/endDate` = fechas del período | Quitar el selector de fechas; vienen del período |
| — | `declarations.superiorUid`, `campusId` | Copiar del perfil |
| `position` | `appointments.position` | Igual |
| `appointmentType` (Interino/Propiedad) | No existe | Se puede guardar como campo extra (las reglas de `appointments` no limitan campos) pero la web no lo muestra. Decidir |
| `courses[]` (los agrega la persona) | `workloadAssignments/{periodo}_{uid}.courses[]` (los asigna la Coordinación) | **Cambio de flujo:** el móvil los **lee**, ya no los crea |
| `projects[]` | `appointments.projects[]` `{name, weeklyMinutes}` | Mismo formato |
| `externalJobs[]` (incrustados) | `versions/{v}/externalJobs/{id}` (subcolección) con `institutionType`, `workload` (`1/8 TC`…`1/2 TC`), `weeklyMinutes` (300/600/900/1200), fechas y `blocks[]` | Un documento por trabajo; las horas por jornada ya coinciden con `WorkloadCatalog` |
| `intervals[]` `{id, day, startMinutes, endMinutes, kind, name}` | `blocks[]` `{day, startMinutes, endMinutes, category?, course?}` dentro del nombramiento o del trabajo externo | Repartir: HC/AE/PyE → bloques del nombramiento con `category` lesson/attention/planning y `course`; PROY → bloque del nombramiento sin `category`; EXT → bloques del `externalJob` |
| `notes` + `observations` | `versions.observations` | Igual (el formato de `ScheduleObservations` ya viene del P1) |
| `status` (lo escribe la app) | `declarations.status` + evento en `events` + `lastEventId` en el mismo lote | Usar las transiciones del P1 (ver §3) |
| `updatedAt` | `updatedAt` = hora del servidor | `FieldValue.serverTimestamp()` |
| — | `versions.hoursSummary`, `validationPassed` | Se escriben al validar |
| — | `declarationSlots/{periodo}_{uid}` | Se escribe al crear (una por período) |

### Estados y transiciones

| Acción en el móvil | Hoy | En el Proyecto 1 |
|---|---|---|
| Crear borrador | `set` con `BORRADOR` | Un lote: declaración + versión 1 + evento `DECLARACION_CREADA` + reserva del período. Requiere período habilitado, asignación de Coordinación y revisor asignado |
| Guardar borrador | `set` del documento completo | Escrituras en la versión (`observations`, `declarantSnapshot`) y en `appointments` / `externalJobs`. Solo en `BORRADOR` |
| Validar | `set` con `VALIDADA` | Transacción `BORRADOR → VALIDADA` con evento `VALIDACION_EJECUTADA` y `hoursSummary` + `validationPassed` en la versión |
| Editar una validada | `set` con `BORRADOR` | Transición `VALIDADA → BORRADOR` con evento `HORARIO_MODIFICADO` |
| Firmar, revisar, RRHH | Fuera del alcance | Siguen en la web. El móvil los **muestra** (solo lectura) |
| `DEVUELTA` | No existe | El móvil puede mostrarla con la observación; crear la versión N+1 se puede dejar en la web |

### Zonaje

| DeclaraUCR | Proyecto 1 |
|---|---|
| Direcciones, distancia escrita, régimen, `weeklyMinutes`, `declarationId` | Además: id `{periodo}_{uid}`, `periodId`, `campusId`, `homeLocation` (mapa), `distanceMethod` (OSRM o línea recta), certificado del TSE en Storage, régimen registrado por RRHH en el perfil |

Son incompatibles: el zonaje del P1 necesita mapa, Storage y el régimen del perfil.

## 3. Qué se conserva sin cambios

- `lib/domain/`: detector de traslapes, cuadrícula, `ScheduleRequirements`, `CourseRules`, `WorkloadCatalog`,
  `ScheduleObservations`, validador. Vienen del P1 y usan las mismas unidades (minutos, días 1–6).
- Pantallas, cuadrícula móvil, tema UCR y casi todas las pruebas de dominio.
- Patrón repositorio: las pantallas no cambian si la interfaz `DeclarationRepository` se mantiene.

## 4. Qué cambia

| Parte | Cambio | Tamaño |
|---|---|---|
| `lib/config/firebase_config.dart` + Android | Registrar la app Android en `declarahorario-b186f` y usar sus opciones en producción | Pequeño |
| `profile_repository.dart` + registro | Campos del P1, reserva `CEDULA_…`, elegir sede y carrera | Medio |
| `declaration_repository.dart` + mapper | Leer y escribir declaración / versión / nombramiento / trabajos externos; transiciones con evento | **Grande** |
| Nuevos repositorios (lectura) | `periods`, `workloadAssignments`, `campuses`, `units` | Medio |
| Formulario | Período en lugar de fechas; cursos de la asignación (solo lectura) | Medio |
| Lista e historial | Mostrar todos los estados del P1; agrupar por período | Pequeño |
| Zonaje | Según la decisión B (§5) | Variable |
| `firestore.rules` de este repo | Ya no se despliegan: mandan las del P1. Pruebas con el emulador cargando las reglas del P1 | Pequeño |

## 5. Decisiones pendientes del equipo

- **A. Cursos.** En el P1 los asigna la Coordinación. Propuesta: el móvil los lee de la asignación y la persona
  solo los ubica en la cuadrícula. (Las reglas no dejan otra opción sin cambiar el P1.)
- **B. Zonaje en el móvil.** Propuesta: **solo consulta** del estado de la solicitud (hecha en la web). Hacerlo
  completo exige mapa, Storage y distancia por carretera, y no es uno de los tres procesos obligatorios.
- **C. Registro.** Propuesta: registro en el móvil con los campos del P1 (nombre, cédula, teléfono, correo) y
  "Completa tu perfil" (sede y carrera). El revisor lo asigna administración en la web.
- **D. Tipo de nombramiento (Interino/Propiedad).** El P1 no lo guarda. Propuesta: quitarlo del móvil, o
  agregarlo al P1 como mejora registrada en la matriz.
- **E. Datos de prueba.** Para recorrer los procesos se necesitan, en el proyecto real: una sede y carrera, un
  período habilitado, una persona declarante con revisor y una asignación de cursos de la Coordinación. Se
  pueden crear desde la web con cuentas de administración y de Coordinación.

## 6. Orden propuesto

1. Registrar la app Android en `declarahorario-b186f` y configurar producción (sin tocar datos).
2. Probar contra el **emulador con las reglas del P1** (`firebase emulators:start` desde `DeclaraHorario`).
3. Perfil y registro (decisión C).
4. Lectura: períodos, asignación, lista de declaraciones con todos los estados.
5. Crear, guardar y recuperar borrador (proceso 1).
6. Horario y traslapes guardados como bloques (proceso 2).
7. Validar y ver resumen y estado (proceso 3).
8. Datos de prueba en producción (decisión E) y generar el APK.
