# DeclaraUCR — Sworn Declarations mobile module

Flutter module of the *Sistema de Declaraciones Juradas de Horario y Jornada de
Trabajo* (IF0009 Desarrollo de Software IV, UCR Sede del Sur). It captures and
validates work information, records the weekly schedule, keeps drafts and shows
a summary of the declaration.

Code and technical docs are in English; everything the user sees is in Spanish.

## Requirements covered

| Req. | Where |
|------|-------|
| R1 Home screen (list + statuses, new / open draft) | `lib/screens/shell_screen.dart` (sections Inicio, Declaraciones, Zonaje, Historial), `home_screen.dart`, `declarations_screen.dart` |
| R2 Declaration form with required-field validation | `lib/screens/declaration_form_screen.dart`: name and cédula from the profile, fixed institution, positions and appointment type from lists, validity of at least one month (`period_rules.dart`) |
| R3 Weekly schedule (Mon–Sat), interval duration and total hours | `lib/widgets/schedule_editor.dart` (half-hour grid, one day at a time), `lib/domain/schedule_grid.dart`, `schedule_requirements.dart` |
| R4 End after start, no overlaps on the same day (any institution) | `lib/domain/declaration_validator.dart`, `overlap_detector.dart` |
| R5 Draft persistence and recovery through the existing repository | `lib/data/` |
| R6 Summary with data, schedule, total, validation result and status | `lib/screens/summary_screen.dart` |

Beyond the lab, from the main project: career courses with their lesson,
attention and planning hours (`course_rules.dart`, `workload_catalog.dart`),
projects, jobs at other institutions, observations written from the
schedule (`schedule_observations.dart`), a simple zonaje request
(`zonaje_eligibility.dart`) and the history by year
(`declarant_history.dart`).

Out of scope (per the lab): digital signature, hierarchical approval and HR
reception. The app never shows a declaration as signed, and `firestore.rules`
rejects any status other than `BORRADOR` and `VALIDADA`.

## Architecture

Layered, dependencies point inward only:

```
screens/ widgets/ theme/   presentation (Flutter widgets, Spanish texts)
  shell_screen             sections: Inicio · Declaraciones · Zonaje · Historial
  auth/                    login, sign-up (with cédula), complete profile
        │
state/                     DeclarationFormState (ChangeNotifier), Loadable<T>
        │
domain/                    pure Dart rules: validator, overlap detector,
                           schedule grid and requirements, course rules,
                           workload catalog, period, observations, zonaje,
                           history, field and auth rules
data/                      interfaces + Firestore implementations:
                           Auth, Profile (with cédula reservation),
                           Declaration (+ mapper), Zonaje
        │
models/                    Declaration, ScheduleInterval, ScheduleTask,
                           CourseLoad, ProjectHours, ExternalJob,
                           ZonajeRequest, status, weekday (pure Dart)
```

Everything per person (repositories, profile, declarations and requests)
is provided above the `MaterialApp` and keyed by user (`lib/main.dart`), so
signing out drops every screen and stream of the previous session.

SOLID in practice:

- **S** — the mapper only converts documents, the validator only validates,
  the repository only persists, the state only coordinates.
- **O** — new rules are added as new `ValidationIssueCode`s / validator
  methods without touching the screens.
- **L / I** — `AuthRepository`, `ProfileRepository`, `DeclarationRepository`
  and `ZonajeRepository` are small interfaces; tests swap in a fake
  Firestore, a fake auth or a failing repository.
- **D** — `DeclarationFormState` receives the repository and validator in its
  constructor; widgets get the repository from `Provider`, never from
  Firestore directly.

## Reused components (from the web system / DeclaraHorario)

- `OverlapDetector`, `ScheduleSlot`, `TimeRules` — same overlap and time rules
  as the original project.
- `ValidationIssue`, `ValidationIssueCode`, `ValidationSeverity` — same
  validation contract, so messages say the day, the intervals and the exact
  conflict time.
- `DeclarationStatus` — same status names (`BORRADOR`, `VALIDADA`,
  `PENDIENTE_FIRMA_DECLARANTE`, …).
- `Weekday` — same Monday–Saturday enumeration stored as 1..6.
- Repository pattern — UI and state depend on an interface, not on Firebase.
- `WorkloadCatalog` and `CourseRules` — workdays 1/8 to 1 TC; a course's
  workday fixes its hours: lessons 2 of every 5 h, attention 30 min per
  lesson hour, planning the rest (VD-12928-2024, VD-13015-2024). Here the
  declarant adds the courses instead of the career coordinator.
- `TeachingSchedule` / `ExternalSchedule` → `ScheduleRequirements`: every
  course (HC, AE, PyE), project and other institution ends with exactly its
  hours; the grid never takes more.
- `ScheduleObservations` — the observations in the official format
  (`IF0009 HC: L 8 am a 10 am. AE: …`), plus notes after
  `Otras observaciones:`.
- `PeriodRules.addOneMonth` — the validity lasts at least one calendar month.
- `ZonajeEligibility` (R16–R19) and `DeclarantHistory`.
- `PositionField` lists and `IdentificationType.nationalId` format (9 digits).

## Persistence

Cloud Firestore through repositories: `users/{uid}` (name and cédula,
`FirestoreProfileRepository`), `declarations`
(`FirestoreDeclarationRepository`) and `zonajeRequests`
(`FirestoreZonajeRepository`), with `identifications/{cédula}` reserving
each cédula for one account.

Two backends, chosen at build time (`lib/config/firebase_config.dart`):

- **Default — emulators:** project `demo-declaraucr`, which only talks to the
  local Firebase Emulator Suite (no real keys or data). Used on Android.
- **`--dart-define=FIREBASE_ENV=production`:** the web version hosted at
  https://declaraucr.web.app on `cristopher-desarrollo-iv` (web only).

- *Guardar borrador* saves with status `BORRADOR` even if fields are missing.
- *Validar* (summary) saves as `VALIDADA` only when there are no missing fields
  and no problems. Editing a `VALIDADA` declaration sends it back to
  `BORRADOR`.
- Opening an item from the list reloads it from Firestore (`getById`), so what
  you see is what was stored.

## Security

- **Input validation at every boundary:** form limits (`maxLength`, input
  filters) → domain validator (`FieldRules`, authoritative) → `firestore.rules`
  (schema, types, sizes, allowed statuses, no deletes).
- **Untrusted storage:** `DeclarationMapper.fromMap` type-checks every field and
  throws `FormatException`; a malformed document is skipped and logged instead
  of breaking the list.
- **No information leaks:** exceptions go to `debugPrint`; the user only sees a
  generic Spanish message.
- **No secrets in code:** demo project options only.
- **Ownership:** only `@ucr.ac.cr` accounts; each person reads and writes
  only their own profile, declarations and requests. The cédula cannot change
  once registered, and a declaration must carry the cédula of the profile.
- **Zonaje on the server:** `firestore.rules` repeats R16–R19 and requires the
  source declaration to be the person's own and `VALIDADA`.
- **Known gaps:** `VALIDADA` and the workday sent with a zonaje request are
  still computed by the client; a Cloud Function should recompute them.
- **Unique cédula:** `identifications/{cédula}` = {uid} is written in the same
  transaction as the profile (as DeclaraHorario); the rules accept the
  profile only with its reservation and never update or delete one, so a
  taken cédula cannot be registered again. A person can only read a free
  cédula or their own, which says it is taken without saying whose it is.

## Running

```bash
flutter pub get
firebase emulators:start --only auth,firestore   # Auth :9099, Firestore :8080, UI :4000
flutter run                                      # Android emulator (host 10.0.2.2)
flutter run --dart-define=EMULATOR_HOST=<PC_IP>  # physical phone, same Wi-Fi
```

Web, for testing on a phone browser:

```bash
flutter build web --release --dart-define=FIREBASE_ENV=production
firebase deploy --only hosting:declaraucr,firestore:rules -P prod
```

Institutional assets are bundled: the official UCR signature
(`assets/images/firma_ucr.png`) and the Trueno typeface (`assets/fonts/`,
SIL OFL 1.1); their origin is in `assets/*/README.txt`.

## Tests

```bash
flutter analyze
flutter test
```

| Lab test | Automated test |
|----------|----------------|
| 01 Valid declaration | `persistence_test.dart` — saves a draft and recovers it unchanged |
| 02 Overlapping schedules | `declaration_validator_test.dart` — mandatory case Mon 8:00–12:00 vs 11:00–14:00; `persistence_test.dart` — does not become VALIDADA until fixed |
| 03 Incomplete data | `widget_test.dart` — saving without data flags the required fields |
| 04 Persistence | `persistence_test.dart` — reopened draft equals the saved one |
| 05 Mobile view | `widget_test.dart` — 360×690 dp screen, any overflow fails the test |

Also covered: a course and its hours placed on the grid up to the summary,
hours that cannot exceed what a task has, missing and extra hours, a
validity shorter than a month, the cédula at sign-up and for older accounts,
zonaje eligibility and requests, the history by year, malformed stored
documents, and a save failure that must not leak the exception.
All test data is fictitious.

## Evidence

Screenshots from the Android app, in `docs/capturas/`:

| Screen | File |
|--------|------|
| Inicio (R1) | `docs/capturas/01-inicio.png` |
| Declaraciones with statuses (R1) | `docs/capturas/02-declaraciones.png` |
| Courses and their hours (R2/R3) | `docs/capturas/03-cursos.png` |
| Weekly schedule grid (R3) | `docs/capturas/04-horario.png` |
| Overlap / missing hours flagged (R4, test 02) | `docs/capturas/05-validacion.png` |
| Summary (R6) | `docs/capturas/06-resumen.png` |
| Zonaje | `docs/capturas/07-zonaje.png` |

Video (up to 2 minutes): <!-- link to the video -->

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

## Difficulties

- Fitting the long status `PENDIENTE_FIRMA_DECLARANTE` in a list row: it was
  moved below the title.
- Entering times on a small screen: the half-hour grid of the web system,
  shown one day at a time with full-width rows; tap marks a half hour,
  long-press and slide marks a range, and a day can be copied to others.
- Overlaps: one task per half hour on the grid, so they cannot be entered;
  the validator still checks stored data.
- Fewer typing errors: everything but names is picked from a list or placed
  on the grid, and the observations are written from the schedule.

## Technical reflection

1. **What could be reused from the web system?** Most of the domain layer,
   almost unchanged: overlap detector, time rules, validation contract,
   statuses, weekdays, the half-hour grid, the workday catalog and course
   rules (lesson, attention and planning hours), project and external-job
   hours, the observations format, the one-month period rule, the zonaje
   eligibility rules, the history by year, the position lists and the
   cédula reservation. Also the repository pattern over Firestore. The
   screens were rewritten for a phone.
2. **Difficulties adapting it to a small screen?** The weekly grid (one day
   at a time, long-press to mark ranges, copy a day to others), long status
   names, and avoiding typing errors: on a phone everything but names is
   picked from a list or placed on the grid, and the observations are
   written from the schedule (see Difficulties).
3. **How did the Visual Identity Manual help?** It fixed the palette,
   typeface and signature rules up front, so every screen reads from one theme
   and looks consistent with other UCR systems. Reading it closely also
   changed the design: the hero gradients became flat Azul UCR (p. 122), the
   signature got a minimum size (p. 37) and the app got its own icon in color
   and one-tone versions (p. 122). The CI accessible palette added the dark
   blue and gray used for text, checked against WCAG contrast.
4. **What would full signature and approval integration need?**
   Authentication and per-person data already exist. Missing: roles
   (declarant, supervisor, HR) in the profile and in `firestore.rules`;
   validation recomputed on the server (a Cloud Function) instead of
   trusting the client's `VALIDADA`; versioning (a new version goes back to
   `BORRADOR`); the remaining status transitions
   (`PENDIENTE_FIRMA_DECLARANTE` → … → `FINALIZADA`); digital signature
   integration; the PDF of the declaration; and notifications to the
   supervisor and HR. The zonaje request would need the same HR review.
