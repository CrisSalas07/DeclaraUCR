# Emuladores con las reglas del Proyecto 1

Para desarrollar y probar la app móvil contra el **mismo esquema y las mismas reglas** que el backend real
del Proyecto 1 (`declarahorario-b186f`), pero en local y con datos ficticios.

| Archivo | Qué es |
|---|---|
| `firestore.rules`, `storage.rules`, `firestore.indexes.json` | Copias de DeclaraHorario. El commit de origen está en `ORIGEN.txt` |
| `firebase.json` | Emuladores de Auth (9099), Firestore (8080), Storage (9199) y la interfaz (4000), abiertos a la red local para probar desde un teléfono |
| `seed.mjs` | Borra los emuladores y carga los datos de prueba |
| `verify.mjs` | Comprueba que las reglas del Proyecto 1 están activas |
| `sync-rules.mjs` | Vuelve a copiar las reglas desde DeclaraHorario |

**Este repositorio nunca despliega estas reglas.** En producción mandan las que se publican desde
DeclaraHorario. Los scripts se niegan a correr si no apuntan a emuladores locales y a un proyecto `demo-*`.

Requisitos: Node.js 18+, Java 11+ y `firebase-tools`. No hace falta `npm install`.

## Uso (desde la raíz del repositorio)

**1. Cargar los datos de prueba** (la primera vez, o para volver a empezar):

```
firebase emulators:exec --config backend/proyecto1/firebase.json --project demo-declaraucr --only auth,firestore --export-on-exit=backend/proyecto1/emulator-data "node backend/proyecto1/seed.mjs"
```

**2. Levantar los emuladores con esos datos** (deje la terminal abierta; la interfaz queda en
<http://127.0.0.1:4000>):

```
firebase emulators:start --config backend/proyecto1/firebase.json --project demo-declaraucr --only auth,firestore --import=backend/proyecto1/emulator-data --export-on-exit=backend/proyecto1/emulator-data
```

**3. Correr la app** en otra terminal, como siempre: `flutter run` (emulador de Android) o
`flutter run --dart-define=EMULATOR_HOST=<IP de la PC>` (teléfono en la misma red Wi-Fi).

Con `--export-on-exit`, lo que se haga en la app se guarda al cerrar con Ctrl+C. Para volver a los datos
iniciales, repita el paso 1.

**Comprobar las reglas** (opcional, con los emuladores cerrados):

```
firebase emulators:exec --config backend/proyecto1/firebase.json --project demo-declaraucr --only auth,firestore "node backend/proyecto1/seed.mjs && node backend/proyecto1/verify.mjs"
```

**Probar la firma de la persona declarante contra las reglas** (opcional, con los emuladores cerrados). Corre el
código de la app en Windows: crea, valida y firma como `docente@ucr.ac.cr`, y el superior lee lo firmado. La
primera vez, `flutter create --platforms=windows .` (no se sube al repositorio):

```
firebase emulators:exec --config backend/proyecto1/firebase.json --project demo-declaraucr --only auth,firestore "node backend/proyecto1/seed.mjs && flutter test integration_test/sign_rules_test.dart -d windows --dart-define=EMULATOR_HOST=127.0.0.1"
```

**Probar la lista y la edición del perfil contra las reglas** (opcional, con los emuladores cerrados y un
emulador de Android abierto). Usa el SDK real de Firestore, con su caché: la lista se actualiza al guardar un
borrador (T-08, T-09) y la persona corrige nombre, cédula y teléfono (U-07). Cada prueba de integración necesita
datos recién cargados, porque `verify.mjs` y la otra prueba dejan un borrador:

```
firebase emulators:exec --config backend/proyecto1/firebase.json --project demo-declaraucr --only auth,firestore "node backend/proyecto1/seed.mjs && flutter test integration_test/release_8_rules_test.dart"
```

**Actualizar las reglas** cuando cambien en DeclaraHorario:

```
node backend/proyecto1/sync-rules.mjs <ruta a DeclaraHorario>
```

## Datos de prueba

Todas las cuentas tienen la contraseña `123456` y el correo ya verificado.

| Correo | Rol | Para qué |
|---|---|---|
| `docente@ucr.ac.cr` | Declarante | Tiene superior y 2 cursos asignados (1/2 TC): puede crear su declaración |
| `docente2@ucr.ac.cr` | Declarante | Sin cursos asignados: la app debe explicar por qué no puede crear la declaración |
| `superior@ucr.ac.cr` | Superior (`superior`) | Superior de las dos personas docentes |
| `coordinacion@ucr.ac.cr` | Coordinación de carrera | Asignó los cursos |
| `rrhh@ucr.ac.cr` | RRHH | Para pruebas de acceso por rol |
| `admin@ucr.ac.cr` | Administración | Para pruebas de acceso por rol |

Además: sede **Sede del Sur** (con ubicación), carrera **Informática Empresarial**, período **II Ciclo - 2026**
(`2026_II`, habilitado) y los cursos IF0009 *Desarrollo de Software IV* (lunes y miércoles 8–10) e IF4001
*Sistemas Operativos* (martes y jueves 13–15), 1/4 TC cada uno.

Para ver la lista y el historial con algo: el período **I Ciclo - 2026** (`2026_I`, cerrado), con una
declaración **FINALIZADA** de `docente@ucr.ac.cr` (IF0009, 1/4 TC, versión 1 firmada y aprobada por RRHH) y
una solicitud de zonaje **RECHAZADA** con la observación de RRHH.

Las personas son ficticias y las cédulas solo cumplen el formato.
