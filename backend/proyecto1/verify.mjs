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
