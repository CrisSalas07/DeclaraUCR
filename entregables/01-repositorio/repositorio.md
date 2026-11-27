# Repositorio de código — DeclaraUCR

**Proyecto 2 · IF0009 · Entregable 1**

| | |
|---|---|
| Repositorio de la app móvil | <https://github.com/CrisSalas07/DeclaraUCR> |
| Repositorio del Proyecto 1 (web y reglas) | <https://github.com/dayanachavarriasteller-maker/DeclaraHorario> |
| Rama principal | `main` (cada cambio entra por pull request) |
| Versión final | [`v2.0.0+10`](https://github.com/CrisSalas07/DeclaraUCR/releases/tag/v2.0.0%2B10) (commit `60d5813`) |
| Versión base del Proyecto 1 | [`p1-entrega`](https://github.com/dayanachavarriasteller-maker/DeclaraHorario/releases/tag/p1-entrega) en DeclaraHorario (`2661da2`) (ver matriz de mejoras §1) |

## Qué hay en el repositorio

| Ruta | Contenido |
|---|---|
| `lib/` | Código de la app (presentación, estado, dominio, datos, modelos) |
| `test/` | 121 pruebas automatizadas |
| `integration_test/` | Firma contra las reglas reales del P1 en los emuladores |
| `backend/proyecto1/` | Copia de las reglas del P1, datos ficticios y verificación, solo para emuladores |
| `tool/build_apk.dart` | Compila el APK identificado por versión y commit |
| `entregables/02-aplicacion-distribuible/instalacion.md` | Instalar, actualizar, volver atrás, compilar y preparar el backend |
| `entregables/05-informe-pruebas/pruebas-tecnicas.md` | Casos técnicos CP-01 a CP-08 con evidencia |
| `entregables/03-informe-tecnico/comparacion-backend-p1.md` | Comparación de esquemas web y móvil |
| `entregables/` | Los ocho entregables del Proyecto 2 |

## Requisitos, ejecución y construcción

Están en el `README.md` de la raíz (secciones *Running* y *Tests*) y en `entregables/02-aplicacion-distribuible/instalacion.md` §5:

```bash
flutter pub get
flutter analyze
flutter test
dart run tool/build_apk.dart      # APK firmado, identificado por versión y commit
```

Requisitos: Flutter 3.x estable (se usó 3.47.0), JDK 17 o superior para Android, Node.js 18+ y
`firebase-tools` para los emuladores.

## Historial de cambios

El historial está en los commits y en los releases de GitHub. Hitos del Proyecto 2:

| Fecha | Versión | Qué entró |
|---|---|---|
| 12/11/2026 | — | Módulo del laboratorio: declaraciones, cursos, proyectos, zonaje, historial, identidad visual UCR |
| 18/11/2026 | 2.0.0+2 | Conexión al backend del Proyecto 1, perfil y registro, lectura y escritura de declaraciones, clases fijas, zonaje, conectividad, firma del APK |
| 19/11/2026 | 2.0.0+3 | Períodos del servidor, PDF, seguimiento en Inicio, botón Validar |
| 19/11/2026 | 2.0.0+4 | Firma de la declarante desde el teléfono |
| 19/11/2026 | 2.0.0+5 | Etiquetas con letra grande, capturas, casos técnicos |
| 19/11/2026 | 2.0.0+6 | Estados legibles, CP-03 y CP-06 ejecutados |
| 20/11/2026 | 2.0.0+7 | Aviso al salir sin guardar (D-01), cuadrícula accesible con TalkBack (D-02), chips de horas (D-03) |
| 27/11/2026 | 2.0.0+8 | Rol «Superior» (P1-03); correcciones de las sesiones con usuarios: qué se ubica en la cuadrícula (U-03), firmar después de validar (U-04, U-05), recorrido de primer uso (U-06), editar mis datos (U-07) |
| 27/11/2026 | 2.0.0+9 | Recorrido guiado sobre las pantallas reales con una docente de ejemplo (U-06 rehecho); la lista ya no se salta un borrador recién guardado (T-09) |
| 27/11/2026 | 2.0.0+10 | Horario de las clases de cada curso arriba de los días del editor; juramento del formulario oficial en el PDF y en la firma (PR #37) |

## Revisión de seguridad del repositorio

- No hay secretos: `android/.gitignore` ignora `key.properties`, `*.jks` y `*.keystore`. Las claves de API de
  Firebase en `lib/config/firebase_config.dart` son identificadores públicos; la seguridad la dan Auth y las
  reglas.
- Las cuentas de prueba usan correos del equipo, por eso no están en el repositorio.
- El plan interno de entregables (`Plan_Entregables_Proyecto2_Lucia_Cristopher.docx`) se queda fuera del
  repositorio: es un documento de trabajo del equipo, no un entregable.

## Cómo etiquetar la versión final

```bash
git tag v2.0.0+10         # versión final
git push origin v2.0.0+10
```

Luego se publica el release en GitHub con el APK y el `.txt` (pasos en `entregables/02-aplicacion-distribuible/instalacion.md` §5).
