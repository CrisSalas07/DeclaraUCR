# DeclaraUCR — Sworn Declarations mobile app

Android app (Flutter) for the declarant side of the *Sistema de Declaraciones
Juradas de Horario y Jornada de Trabajo* (IF0009 Desarrollo de Software IV,
UCR Sede del Sur). It is the **Proyecto 2**: it takes the web system of the
Proyecto 1 ([DeclaraHorario](https://github.com/dayanachavarriasteller-maker/DeclaraHorario),
<https://declarahorario-b186f.web.app>) to the phone and works against **the
same Firebase backend, schema and rules**.

On the phone a declarant signs up, creates a declaration for the open period,
places the coordination's courses and their attention and planning hours on a
half-hour grid, validates it, signs it and sends it to the reviewer; they can
also see the PDF, the history and the zonaje requests. Reviewer, HR,
coordination and administration stay in the web.

Code and technical docs are in English; everything the user sees, and the
Proyecto 2 deliverables, are in Spanish.

## Current status (22/11/2026)

- **Version 2.0.0+7**, released on GitHub (`v2.0.0+7`), signed with the team
  key, against the real Proyecto 1 backend.
- 109 automated tests pass; technical cases CP-01 to CP-07 passed, CP-08
  (clean install on another phone) pending.
- Next: the three user sessions, the socialization video, at least two
  improvements from the feedback (2.0.0+8) and the final tag. The detailed
  to-do list is in `entregables/README.md` §4.

## Where to find what

Each README covers only its folder; this one is the entry point.

| Document | What it is for |
|---|---|
| `entregables/README.md` | The eight Proyecto 2 deliverables: map of the folder, what to use for the user sessions and the video, what is left and the risks |
| `entregables/05-informe-pruebas/sesiones-usuarios/README.md` | Kit to run the user sessions, step by step |
| `entregables/05-informe-pruebas/evidencias/sesiones-usuarios/LEAME.md` | What goes in the session evidence folder |
| `entregables/03-informe-tecnico/informe-tecnico.md` | Scope, architecture, mobile decisions, integration, deployment and known limitations (for the professor) |
| `docs/INSTALACION.md` | Install, update and roll back the APK; build and release a version; prepare the real backend |
| `docs/PRUEBAS.md` | Technical test cases CP-01 to CP-08 with evidence (`docs/pruebas/`) |
| `docs/COMPARACION_BACKEND_P1.md` | Field-by-field comparison of the mobile and the Proyecto 1 data |
| `backend/proyecto1/README.md` | Firebase emulators with the Proyecto 1 rules and fictitious data |
| `docs/capturas/README.txt` | The app screenshots and what each one shows |
| `assets/fonts/README.txt`, `assets/images/README.txt` | Origin and license of the Trueno typeface and the UCR signature |

## Code map

| Feature | Where |
|---|---|
| Sections Inicio · Declaraciones · Zonaje · Historial | `lib/screens/shell_screen.dart`, `home_screen.dart`, `declarations_screen.dart`, `zonaje_screen.dart`, `history_screen.dart` |
| Sign-in, sign-up (cédula, phone), campus and career, account notice | `lib/screens/auth/` |
| Declaration form: position, courses, projects, other jobs | `lib/screens/declaration_form_screen.dart`, `lib/widgets/workload_dialogs.dart` |
| Weekly half-hour grid (one day at a time, TalkBack) | `lib/widgets/schedule_editor.dart`, `lib/domain/schedule_grid.dart`, `schedule_requirements.dart` |
| Validation: hours per task, overlaps, required fields | `lib/domain/declaration_validator.dart`, `overlap_detector.dart`, `field_rules.dart` |
| Course hours and workdays | `lib/domain/course_rules.dart`, `workload_catalog.dart` |
| Summary, Validar and the 5-step tracking | `lib/screens/summary_screen.dart`, `lib/widgets/declaration_progress.dart` |
| Signature and PDF | `lib/screens/sign_declaration_screen.dart`, `lib/data/proyecto1/declaration_signer.dart`, `lib/pdf/declaration_pdf.dart` |
| Reads and writes in the Proyecto 1 schema | `lib/data/proyecto1/` |
| Offline strip and save rules | `lib/data/network_status.dart`, `lib/widgets/offline_banner.dart`, `lib/state/declaration_form_state.dart` |
| Backend selection (emulators or production) | `lib/config/firebase_config.dart` |
| Theme and UCR colors | `lib/theme/ucr_theme.dart` |

## Architecture

Layered, dependencies point inward only:

```
screens/ widgets/ theme/   presentation (Flutter widgets, Spanish texts)
        │
state/                     DeclarationFormState (ChangeNotifier), Loadable<T>
        │
domain/                    pure Dart rules (validator, grid, course rules…)
data/                      small interfaces + Firestore implementations
        │
models/                    pure Dart entities
```

Everything per person (repositories, profile, declarations, requests) is
provided above the `MaterialApp` and keyed by user (`lib/main.dart`), so
signing out drops every screen and stream of the previous session. Widgets
get repositories from `Provider`, never from Firestore directly; tests swap
in a fake Firestore, auth or network (`test/support/`).

Why each layer and what was reused from the Proyecto 1: informe técnico §3.
How the data maps to the Proyecto 1 schema: `docs/COMPARACION_BACKEND_P1.md`.

### Rules to keep when changing code

- Validate at every boundary: form limits → `FieldRules` and the validator
  (authoritative in the app) → the Proyecto 1 `firestore.rules`.
- Stored documents are untrusted: mappers type-check every field and throw
  `FormatException`; a malformed document is skipped and logged.
- Exceptions go to `debugPrint`; the user only sees a Spanish message.
- Every save reads from the server first and waits at most 15 s, so without a
  connection it fails at once instead of queueing writes.
- This repository **never deploys Firestore rules**: the real ones are
  published from DeclaraHorario; `backend/proyecto1/` is a copy for the
  emulators only.
- No secrets in code: `android/key.properties` and the release key stay
  local.

## Backends

Chosen at build time (`lib/config/firebase_config.dart`):

- **Default — emulators:** project `demo-declaraucr`, which only talks to the
  local Firebase Emulator Suite (no real keys or data).
- **`--dart-define=FIREBASE_ENV=production`:** on Android, the Proyecto 1
  backend `declarahorario-b186f` (app "DeclaraUCR (Android)"). On web, the
  earlier lab version at https://declaraucr.web.app (project
  `cristopher-desarrollo-iv`, without the Proyecto 1 schema, so a web build
  of the current code does not work there; the phone app is the deliverable).

## Running

```bash
flutter pub get
firebase emulators:start --only auth,firestore   # Auth :9099, Firestore :8080, UI :4000
flutter run                                      # Android emulator (host 10.0.2.2)
flutter run --dart-define=EMULATOR_HOST=<PC_IP>  # physical phone, same Wi-Fi
flutter run --dart-define=FIREBASE_ENV=production # Android against the Proyecto 1 backend
```

With the Proyecto 1 rules and test data: `backend/proyecto1/README.md`.

APK to hand out (team release key, Proyecto 1 backend, named by version and
commit): `dart run tool/build_apk.dart`. Releasing, installing and rolling
back: `docs/INSTALACION.md`.

## Tests

```bash
flutter analyze
flutter test
```

Unit and widget tests in `test/` (domain, data against a fake Firestore,
connectivity, a 360×690 dp screen that fails on any overflow);
`integration_test/sign_rules_test.dart` signs against the real Proyecto 1
rules in the emulators. The manual technical cases are in `docs/PRUEBAS.md`.
All test data is fictitious.

## Visual identity decisions

Sources: *Manual de identidad visual*, Universidad de Costa Rica, Oficina de
Divulgación e Información, 3rd ed., January 2019 (pages as printed, equal to
the PDF pages); and *Aplicación accesible de la paleta institucional en
medios digitales de la UCR*, Centro de Informática, 2025 ("CI palette").

| Decision | Where in the app | Manual |
|----------|------------------|--------|
| **Colors.** Main colors Celeste UCR `#00C0F3`, Azul UCR `#005DA4` and white; Amarillo `#FFE06A` and Verde `#6DC067` only as accents (status chips). Defined once in `UcrColors` and read through the theme. Dark blue `#0C344E` (Azul 1) and text gray `#232323` (Gris 3) come from the CI palette. | `lib/theme/ucr_theme.dart` | p. 28 (main colors and codes), p. 31 (hierarchy: celeste, azul and white predominate); CI palette p. 3 |
| **Contrast.** White on Azul UCR 6.8:1; Gris 3 on celeste 7.4:1, on yellow 12.1:1, on green 7.0:1 (WCAG 2 AA, 4.5:1). White text is never placed on celeste, yellow or green (2.1:1 on celeste). | buttons, app bars, status chips | p. 31 ("contraste adecuado… accesibilidad"); CI palette pp. 5–7 |
| **Typography.** Trueno (Regular, SemiBold, Bold) bundled under the SIL OFL 1.1, Arial as fallback. | `assets/fonts/`, `pubspec.yaml`, theme `fontFamily` | p. 24 (institutional families; Arial replaces Myriad Pro), p. 25 (Trueno: free license, for web and electronic devices) |
| **Signature.** Official horizontal two-line signature, color version on a light background, from the SVG published by the Oficina de Comunicación Institucional, rendered without changes; never cropped or distorted (`BoxFit.contain`). | `assets/images/firma_ucr.png`, `UcrSignature` (login, Inicio) | p. 32 (every product carries a signature), p. 33 and 39 (horizontal two-line signature), p. 35 (fixed proportions), p. 49 (color version on light backgrounds) |
| **Signature size and space.** At least 106 dp high, so the base of the shield is about 1.5 cm; nothing else inside its protection area. | `UcrSignature.minHeight` | p. 36 (protection area), p. 37 (minimum size 1.5 cm) |
| **App icon.** Own identifier (a declaration sheet with a check) on Azul UCR, with a one-tone version for Android themed icons; the shield is not used as an icon. | `android/app/src/main/res` (adaptive icon), `web/icons/` | p. 122 (icon: own identifier, color and monochrome versions) |
| **Flat design.** Hero areas are flat Azul UCR, no gradients or decorative shadows; Material 3 components follow the Android standard. | `UcrColors.hero`, `BrandMark` | p. 122 (other screens follow the platform standard; clean look, measured use of gradients and shadows; flat designs) |
| **Components.** 48 dp minimum touch targets, labeled fields, specific error messages, no horizontal scrolling. | whole app | p. 122 ("Otros elementos": platform guidelines) |

Not done: the loading screen with the promotional signature inside the
horizon (p. 122, pp. 34 and 57). The promotional signature is only in the
"Elementos gráficos" package of the ODI, which requires an institutional
login; it cannot be redrawn (p. 35), so the app keeps the platform's plain
loading screen.

