// Checks that the emulators run the Proyecto 1 rules with the seed data
// (run after seed.mjs, inside `firebase emulators:exec`). Signs in as the
// fictitious declarant and tries reads and writes that the rules must
// allow or reject. Exits with 1 when any result is not the expected one.
const firestore = `http://${process.env.FIRESTORE_EMULATOR_HOST}`.replace('0.0.0.0', '127.0.0.1');
const auth = `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`.replace('0.0.0.0', '127.0.0.1');
const project = process.env.GCLOUD_PROJECT || 'demo-declaraucr';
const documents = `${firestore}/v1/projects/${project}/databases/(default)/documents`;

async function signUp(email) {
  const response = await fetch(
    `${auth}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=emulator`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: '123456', returnSecureToken: true }),
    },
  );
  if (!response.ok) throw new Error(`No se pudo crear la cuenta ${email}`);
  return response.json();
}

/** Firestore REST fields for strings, booleans and lists of strings. */
const fields = (data) => Object.fromEntries(Object.entries(data).map(([key, v]) => [
  key,
  Array.isArray(v) ? { arrayValue: { values: v.map((x) => ({ stringValue: x })) } }
    : typeof v === 'boolean' ? { booleanValue: v } : { stringValue: v },
]));
const docName = (path) => `projects/${project}/databases/(default)/documents/${path}`;

/** Several writes in one atomic commit, as a batch or transaction of the app. */
async function commit(token, writes) {
  const response = await fetch(`${documents}:commit`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ writes }),
  });
  return response.status;
}

async function signIn(email) {
  const response = await fetch(
    `${auth}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=emulator`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: '123456', returnSecureToken: true }),
    },
  );
  if (!response.ok) throw new Error(`No se pudo iniciar sesión con ${email}`);
  return response.json();
}

async function request(method, path, token, body) {
  const response = await fetch(`${documents}/${path}`, {
    method,
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return response.status;
}

async function ownerGet(path) {
  const response = await fetch(`${documents}/${path}`, { headers: { Authorization: 'Bearer owner' } });
  return response.json();
}

const docente = await signIn('docente@ucr.ac.cr');
const profile = await ownerGet(`users/${docente.localId}`);
const revisorUid = profile.fields.superiorUid.stringValue;

const checks = [
  ['Lee su propio perfil', 200,
    await request('GET', `users/${docente.localId}`, docente.idToken)],
  ['Lee su asignación de cursos del período', 200,
    await request('GET', `workloadAssignments/2026_II_${docente.localId}`, docente.idToken)],
  ['Lee el período', 200,
    await request('GET', 'periods/2026_II', docente.idToken)],
  ['No lee el perfil de otra persona (revisor)', 403,
    await request('GET', `users/${revisorUid}`, docente.idToken)],
  // The current mobile schema: the Proyecto 1 rules must reject it.
  ['Rechaza una declaración con el formato actual del móvil', 403,
    await request('PATCH', 'declarations/prueba-formato-movil', docente.idToken, {
      fields: {
        ownerUid: { stringValue: docente.localId },
        status: { stringValue: 'BORRADOR' },
        intervals: { arrayValue: { values: [] } },
      },
    })],
];

// The writes of the mobile sign-up and "Complete su perfil"
// (FirestoreProfileRepository.create and chooseWorkplace), byte for byte.
const nuevo = await signUp(`nuevo${Date.now()}@ucr.ac.cr`);
const cedula = String(200000000 + Math.floor(Math.random() * 99999999));
const signUpWrites = (account, id) => [
  { update: { name: docName(`users/${account.localId}`), fields: fields({
    fullName: 'Nora Nueva', identification: id, identificationType: 'CEDULA',
    phone: '88881234', email: account.email, roles: ['declarant'], active: true,
  }) } },
  { update: { name: docName(`identifications/CEDULA_${id}`), fields: fields({ uid: account.localId }) } },
];
checks.push(['Registro desde el móvil (perfil + reserva de cédula)', 200,
  await commit(nuevo.idToken, signUpWrites(nuevo, cedula))]);

const otro = await signUp(`otro${Date.now()}@ucr.ac.cr`);
checks.push(['Rechaza registrar una cédula ya reservada', 403,
  await commit(otro.idToken, signUpWrites(otro, cedula))]);

checks.push(['Rechaza un registro que se asigna otro rol', 403,
  await commit(otro.idToken, [
    { update: { name: docName(`users/${otro.localId}`), fields: fields({
      fullName: 'Otro', identification: '299999999', identificationType: 'CEDULA',
      phone: '88881234', email: otro.email, roles: ['admin'], active: true,
    }) } },
    { update: { name: docName('identifications/CEDULA_299999999'), fields: fields({ uid: otro.localId }) } },
  ])]);

checks.push(['Elige sede y carrera, y queda en el directorio de docentes', 200,
  await commit(nuevo.idToken, [
    {
      update: { name: docName(`users/${nuevo.localId}`),
        fields: fields({ campusId: 'sede-sur', unitId: 'informatica-empresarial' }) },
      updateMask: { fieldPaths: ['campusId', 'unitId'] },
    },
    {
      update: { name: docName(`teacherDirectory/${nuevo.localId}`), fields: fields({
        fullName: 'Nora Nueva', unitId: 'informatica-empresarial', identification: cedula,
      }) },
      updateTransforms: [{ fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }],
    },
  ])]);

checks.push(['Rechaza cambiar la sede ya elegida', 403,
  await commit(nuevo.idToken, [{
    update: { name: docName(`users/${nuevo.localId}`), fields: fields({ campusId: 'otra-sede' }) },
    updateMask: { fieldPaths: ['campusId'] },
  }])]);

// The reads of the declaration list (Proyecto1DeclarationRepository and
// FirestorePeriodRepository).
async function query(token, collectionId, field, value) {
  const response = await fetch(`${documents}:runQuery`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ structuredQuery: {
      from: [{ collectionId }],
      where: { fieldFilter: { field: { fieldPath: field }, op: 'EQUAL', value } },
    } }),
  });
  return response.status;
}
const seeded = 'declarations/seed-2026-I-docente';
const docente2 = await signIn('docente2@ucr.ac.cr');
checks.push(
  ['Lista sus declaraciones (filtradas por declarantUid)', 200,
    await query(docente.idToken, 'declarations', 'declarantUid', { stringValue: docente.localId })],
  ['Rechaza listar las declaraciones de otra persona', 403,
    await query(docente2.idToken, 'declarations', 'declarantUid', { stringValue: docente.localId })],
  ['Lista los períodos habilitados', 200,
    await query(docente.idToken, 'periods', 'enabled', { booleanValue: true })],
  ['Lee la versión y el nombramiento de su declaración', 200,
    Math.max(
      await request('GET', `${seeded}/versions/v1`, docente.idToken),
      await request('GET', `${seeded}/versions/v1/appointments/a1`, docente.idToken),
    )],
  ['No lee la declaración de otra persona', 403,
    await request('GET', seeded, docente2.idToken)],
  ['No lee la asignación de cursos de otra persona', 403,
    await request('GET', `workloadAssignments/2026_II_${docente.localId}`, docente2.idToken)],
);

// Process 1 of the mobile app (Proyecto1DeclarationRepository): create the
// draft (createDraft batch + content), save it again, validate it
// (markValidated) and edit it after validating (reopen). Same documents and
// fields the app writes; server times as REQUEST_TIME transforms.
{
  const raw = (v) => {
    if (v === null) return { nullValue: null };
    if (Array.isArray(v)) return { arrayValue: { values: v.map(raw) } };
    if (typeof v === 'boolean') return { booleanValue: v };
    if (typeof v === 'number') return { integerValue: String(v) };
    if (typeof v === 'object' && v.ts) return { timestampValue: v.ts };
    if (typeof v === 'object') return { mapValue: { fields: rawFields(v) } };
    return { stringValue: v };
  };
  const rawFields = (data) =>
    Object.fromEntries(Object.entries(data).map(([k, v]) => [k, raw(v)]));
  const serverTime = (...paths) =>
    paths.map((fieldPath) => ({ fieldPath, setToServerValue: 'REQUEST_TIME' }));
  const set = (path, data, times = []) => ({
    update: { name: docName(path), fields: rawFields(data) },
    ...(times.length ? { updateTransforms: serverTime(...times) } : {}),
  });
  const patch = (path, data, times = []) => ({
    ...set(path, data, times),
    updateMask: { fieldPaths: Object.keys(data) },
  });

  const uid = docente.localId;
  const period = (await ownerGet('periods/2026_II')).fields;
  const dates = {
    startDate: { ts: period.startDate.timestampValue },
    endDate: { ts: period.endDate.timestampValue },
  };
  const id = `movil-${Date.now()}`;
  const decl = `declarations/${id}`;
  const version = `${decl}/versions/v1`;
  const course = 'Desarrollo de Software IV';
  const appointment = (blocks) => set(`${version}/appointments/a1`, {
    workplace: 'Universidad de Costa Rica · Sede del Sur · Informática Empresarial',
    position: 'Adjunto', workload: '1/2 TC', ...dates, blocks,
  });
  const lessons = [
    { day: 1, startMinutes: 480, endMinutes: 600, category: 'lesson', course },
    { day: 3, startMinutes: 480, endMinutes: 600, category: 'lesson', course },
  ];
  const event = (eventId, data) => set(`${decl}/events/${eventId}`, {
    userId: uid, version: 1, ...data,
  }, ['timestamp']);
  const transition = (eventId, from, to, extra = []) => commit(docente.idToken, [
    event(eventId, { type: to === 'VALIDADA' ? 'VALIDACION_EJECUTADA' : 'HORARIO_MODIFICADO', previousStatus: from, newStatus: to }),
    patch(decl, {
      status: to, lastEventId: eventId,
      currentResponsibleUid: uid, currentResponsibleRole: 'declarant',
    }, ['updatedAt']),
    ...extra,
  ]);

  checks.push(['Proceso 1: crea el borrador (declaración, versión, evento, reserva y nombramiento)', 200,
    await commit(docente.idToken, [
      set(decl, {
        declarantUid: uid, declarantName: 'Daniela Docente', periodId: '2026_II',
        superiorUid: profile.fields.superiorUid.stringValue, campusId: 'sede-sur',
        status: 'BORRADOR', currentVersionId: 'v1', currentVersionNumber: 1,
        currentResponsibleUid: uid, currentResponsibleRole: 'declarant', lastEventId: 'e1',
      }, ['createdAt', 'updatedAt']),
      set(version, {
        number: 1,
        declarantSnapshot: {
          fullName: 'Daniela Docente', identification: '100000005', phone: '88880000',
          email: 'docente@ucr.ac.cr', unitName: 'Informática Empresarial', campusName: 'Sede del Sur',
        },
        observations: 'IF0009 HC: L 8 am a 10 am; K 8 am a 10 am.',
        isLocked: false, createdBy: uid,
      }, ['createdAt']),
      event('e1', { type: 'DECLARACION_CREADA', newStatus: 'BORRADOR' }),
      set(`declarationSlots/2026_II_${uid}`, { declarationId: id }),
      appointment(lessons),
      set(`${version}/externalJobs/x1`, {
        institution: 'MEP', institutionType: 'public', position: 'Docente',
        workload: '1/8 TC', weeklyMinutes: 300, ...dates,
        blocks: [{ day: 6, startMinutes: 480, endMinutes: 780 }],
      }),
    ])]);

  checks.push(['Proceso 1: rechaza una segunda declaración en el mismo período', 403,
    await commit(docente.idToken, [
      set(`declarations/${id}-2`, {
        declarantUid: uid, declarantName: 'Daniela Docente', periodId: '2026_II',
        superiorUid: profile.fields.superiorUid.stringValue, campusId: 'sede-sur',
        status: 'BORRADOR', currentVersionId: 'v1', currentVersionNumber: 1, lastEventId: 'e1',
      }, ['createdAt', 'updatedAt']),
      set(`declarations/${id}-2/versions/v1`, { number: 1, isLocked: false }),
      set(`declarations/${id}-2/events/e1`, { userId: uid, version: 1, type: 'DECLARACION_CREADA', newStatus: 'BORRADOR' }, ['timestamp']),
      set(`declarationSlots/2026_II_${uid}`, { declarationId: `${id}-2` }),
    ])]);

  const placed = [
    ...lessons,
    { day: 2, startMinutes: 480, endMinutes: 600, category: 'attention', course },
    { day: 4, startMinutes: 480, endMinutes: 720, category: 'planning', course },
  ];
  checks.push(['Proceso 2: guarda el horario del borrador (versión y nombramiento)', 200,
    await commit(docente.idToken, [
      patch(version, { observations: 'IF0009 HC: L 8 am a 10 am. AE: K 8 am a 10 am.' }),
      appointment(placed),
    ])]);

  checks.push(['Proceso 2: rechaza un nombramiento con otra vigencia que la del período', 403,
    await commit(docente.idToken, [
      set(`${version}/appointments/a1`, {
        workplace: 'UCR', position: 'Adjunto', workload: '1/2 TC',
        startDate: { ts: '2026-01-01T00:00:00Z' }, endDate: dates.endDate, blocks: placed,
      }),
    ])]);

  checks.push(['Proceso 3: valida (BORRADOR → VALIDADA, evento y horas de la versión)', 200,
    await transition('e2', 'BORRADOR', 'VALIDADA', [
      patch(version, {
        hoursSummary: { expectedMinutes: 600, declaredMinutes: 600, differenceMinutes: 0 },
        validationPassed: true,
      }),
    ])]);

  checks.push(['Proceso 3: rechaza editar el horario de una declaración VALIDADA', 403,
    await commit(docente.idToken, [appointment(lessons)])]);

  checks.push(['Proceso 1: al editarla vuelve a BORRADOR (HORARIO_MODIFICADO)', 200,
    await transition('e3', 'VALIDADA', 'BORRADOR')]);

  checks.push(['Proceso 3: rechaza que la persona se salte la firma (→ ENVIADA_A_RRHH)', 403,
    await commit(docente.idToken, [
      event('e4', { type: 'FIRMA_REGISTRADA', previousStatus: 'BORRADOR', newStatus: 'ENVIADA_A_RRHH' }),
      patch(decl, { status: 'ENVIADA_A_RRHH', lastEventId: 'e4' }, ['updatedAt']),
    ])]);
}

let failed = 0;
for (const [name, expected, actual] of checks) {
  const ok = expected === actual;
  if (!ok) failed++;
  console.log(`${ok ? '✔' : '✘'} ${name} (esperado ${expected}, obtenido ${actual})`);
}
if (failed) {
  console.error(`${failed} comprobación(es) fallaron.`);
  process.exit(1);
}
console.log('Las reglas del Proyecto 1 están activas en los emuladores.');
