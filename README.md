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
        │
state/                     DeclarationFormState (ChangeNotifier, provider)
        │
domain/                    validator, overlap detector, time and field rules (pure Dart)
data/                      DeclarationRepository (interface) + Firestore impl + mapper
        │
models/                    Declaration, ScheduleInterval, status, weekday (pure Dart)
```

SOLID in practice:

- **S** — the mapper only converts documents, the validator only validates,
  the repository only persists, the state only coordinates.
- **O** — new rules are added as new `ValidationIssueCode`s / validator
  methods without touching the screens.
- **L / I** — `DeclarationRepository` is a small interface; tests swap in a
  fake Firestore or a failing repository.
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
(`FirestoreZonajeRepository`). The app uses the `demo-declaraucr` project,
which only talks to the local Firebase Emulator Suite (no real keys or data).

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
firebase emulators:start          # Firestore on :8080, UI enabled
flutter run                       # Android emulator (host 10.0.2.2)
flutter run --dart-define=EMULATOR_HOST=<PC_IP>   # physical phone
```

Optional institutional assets (see `assets/*/README.txt`): the official UCR
signature (`assets/images/firma_ucr.png`) and the Trueno typeface.

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

## Visual identity decisions

<!-- TODO: add the page numbers of the UCR Visual Identity Manual (2019, 3rd ed.) consulted for each decision. -->

- **Color:** UCR reference palette defined once in `lib/theme/ucr_theme.dart`
  (`UcrColors`) and used only through the theme. Blue `#005DA4` for app bar,
  buttons and titles (white text, 6.5:1); sky blue `#00C0F3` for header
  accents; yellow / green / sky blue for status chips, always with dark text
  because white on them is below 4.5:1.
- **Typography:** Trueno (manual's typeface), Arial fallback.
- **Institutional signature:** official file only, never redrawn or distorted
  (`BoxFit.contain`); text fallback if the file is not bundled.
- **Components:** Material 3 with 48 dp minimum touch targets, labeled fields,
  specific error messages, no horizontal scrolling.

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

1. **What could be reused from the web system?** The domain layer (overlap
   detector, time rules, validation contract, statuses, weekdays) and the
   repository pattern over Firestore, almost unchanged.
2. **Difficulties adapting it to a small screen?** Long status names, time
   entry and showing conflicts next to the field that causes them (see above).
3. **How did the Visual Identity Manual help?** It fixed the palette,
   typeface and signature rules up front, so every screen reads from one theme
   and looks consistent with other UCR systems.
4. **What would full signature and approval integration need?**
   Authentication, server-side validation, versioning (new version → back to
   `BORRADOR`), the remaining status transitions with role-based Firestore
   rules, digital signature integration and notifications to the supervisor
   and HR.
