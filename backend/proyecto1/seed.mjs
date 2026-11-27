// Leaves the LOCAL EMULATORS with fictitious data of the Proyecto 1 schema,
// enough to walk the three mobile processes: a campus and career, an open
// period, a declarant with a superior and the courses the coordination
// assigned. It erases everything in the emulators first.
//
// It only talks to the emulators: it refuses to run unless
// FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST point to this
// machine (`firebase emulators:exec` sets them). Writes use the emulators'
// "owner" access, which skips the rules, like an administrator preparing
// data from the web. Uses only Node's fetch: no packages.
const PASSWORD = '123456';
const CAMPUS_ID = 'sede-sur';
const UNIT_ID = 'informatica-empresarial';
const PERIOD_ID = '2026_II';

// Fictitious people. Cédulas are valid for the rules (9 digits, no leading 0).
const PEOPLE = {
  admin: {
    email: 'admin@ucr.ac.cr', fullName: 'Ana Administración', identification: '100000001',
    roles: ['admin'],
  },
  superior: {
    email: 'superior@ucr.ac.cr', fullName: 'Rodrigo Superior', identification: '100000002',
    roles: ['superior'],
  },
  coordinacion: {
    email: 'coordinacion@ucr.ac.cr', fullName: 'Carla Coordinación', identification: '100000003',
    roles: ['careerCoordinator'], unit: true,
  },
  rrhh: {
    email: 'rrhh@ucr.ac.cr', fullName: 'Raúl Recursos Humanos', identification: '100000004',
    roles: ['hr'],
  },
  // Has a superior and courses assigned: can create a declaration.
  docente: {
    email: 'docente@ucr.ac.cr', fullName: 'Daniela Docente', identification: '100000005',
    roles: ['declarant'], unit: true, superior: 'superior', salaryRegime: 'COMPUESTO',
  },
  // No courses assigned in the period: the app must explain why it cannot
  // create a declaration (and the rules reject it).
  sinAsignacion: {
    email: 'docente2@ucr.ac.cr', fullName: 'Diego Sin Asignación', identification: '100000006',
    roles: ['declarant'], unit: true, superior: 'superior',
  },
};

const COURSES = [
  { id: 'if0009', code: 'IF0009', name: 'Desarrollo de Software IV', credits: 4, weeklyHours: 4 },
  { id: 'if4001', code: 'IF4001', name: 'Sistemas Operativos', credits: 4, weeklyHours: 4 },
];

// 1/4 TC (600 min) per course: lessons 2/5 of the load (240 min), attention
// 30 min per lesson hour, planning the rest (CourseRules / VD-12928-2024).
// Two courses = 1/2 TC, which also meets the zonaje half-time rule.
const ASSIGNED = [
  {
    course: COURSES[0], workloadMinutes: 600, lessonMinutes: 240,
    slots: [{ day: 1, startMinutes: 8 * 60, endMinutes: 10 * 60 },
            { day: 3, startMinutes: 8 * 60, endMinutes: 10 * 60 }],
  },
  {
    course: COURSES[1], workloadMinutes: 600, lessonMinutes: 240,
    slots: [{ day: 2, startMinutes: 13 * 60, endMinutes: 15 * 60 },
            { day: 4, startMinutes: 13 * 60, endMinutes: 15 * 60 }],
  },
];

/** Host of [name], or exits when it is missing or not this machine. */
function emulatorHost(name) {
  const host = process.env[name];
  if (!host) {
    console.error(`${name} no está definida: este script solo corre contra los emuladores.`);
    process.exit(1);
  }
  const hostname = host.replace(/:\d+$/, '').replace(/^\[|\]$/g, '');
  if (!['localhost', '::1', '0.0.0.0'].includes(hostname) && !/^127\.\d+\.\d+\.\d+$/.test(hostname)) {
    console.error(`${name}=${host} no es un emulador local; no se toca nada.`);
    process.exit(1);
  }
  return `http://${host.replace(/^0\.0\.0\.0/, '127.0.0.1')}`;
}

async function call(method, url, body) {
  const response = await fetch(url, {
    method,
    headers: { Authorization: 'Bearer owner', 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (!response.ok) {
    throw new Error(`${method} ${url}: ${response.status} ${await response.text()}`);
  }
  const type = response.headers.get('content-type') || '';
  return type.includes('json') ? response.json() : {};
}

/** Firestore REST value. Integers stay integers (the rules check `is int`). */
function value(v) {
  if (v === null) return { nullValue: null };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(value) } };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') {
    return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  }
  if (typeof v === 'object') return { mapValue: { fields: fields(v) } };
  return { stringValue: v };
}

function fields(data) {
  return Object.fromEntries(Object.entries(data).map(([key, v]) => [key, value(v)]));
}

async function main() {
  const firestore = emulatorHost('FIRESTORE_EMULATOR_HOST');
  const auth = emulatorHost('FIREBASE_AUTH_EMULATOR_HOST');
  const project = process.env.GCLOUD_PROJECT || 'demo-declaraucr';
  if (!project.startsWith('demo-')) {
    console.error(`El proyecto ${project} no es demo-*: no se toca nada.`);
    process.exit(1);
  }
  const documents = `${firestore}/v1/projects/${project}/databases/(default)/documents`;
  const put = (docPath, data) => call('PATCH', `${documents}/${docPath}`, { fields: fields(data) });
  const now = new Date();

  // 1. Everything is erased.
  await call('DELETE', `${auth}/emulator/v1/projects/${project}/accounts`);
  await call('DELETE', `${firestore}/emulator/v1/projects/${project}/databases/(default)/documents`);

  // 2. Accounts, with the email already verified and the name the app sets
  // when someone signs up (Inicio greets with it).
  const uid = {};
  for (const [key, person] of Object.entries(PEOPLE)) {
    const account = await call(
      'POST',
      `${auth}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=emulator`,
      { email: person.email, password: PASSWORD, returnSecureToken: true },
    );
    await call('POST', `${auth}/identitytoolkit.googleapis.com/v1/projects/${project}/accounts:update`, {
      localId: account.localId,
      emailVerified: true,
      displayName: person.fullName,
    });
    uid[key] = account.localId;
  }

  // 3. Campus (with its location, needed by zonaje), career and period.
  await put(`campuses/${CAMPUS_ID}`, {
    name: 'Sede del Sur', active: true, location: { lat: 8.64, lng: -83.18 },
  });
  await put(`units/${UNIT_ID}`, {
    name: 'Informática Empresarial', active: true, campusId: CAMPUS_ID,
  });
  await put(`periods/${PERIOD_ID}`, {
    name: 'II Ciclo - 2026', cycle: 'II', year: 2026,
    startDate: new Date('2026-08-10T06:00:00Z'), endDate: new Date('2026-12-05T06:00:00Z'),
    enabled: true, createdBy: uid.admin,
  });

  // 4. Profiles, as they are after an administrator assigned roles, career
  // and superior, with the reservation of each identification.
  for (const [key, person] of Object.entries(PEOPLE)) {
    await put(`users/${uid[key]}`, {
      fullName: person.fullName,
      identification: person.identification,
      identificationType: 'CEDULA',
      phone: '88880000',
      email: person.email,
      roles: person.roles,
      active: true,
      createdAt: now,
      campusId: CAMPUS_ID,
      ...(person.unit ? { unitId: UNIT_ID } : {}),
      ...(person.superior ? { superiorUid: uid[person.superior] } : {}),
      ...(person.salaryRegime ? { salaryRegime: person.salaryRegime } : {}),
    });
    await put(`identifications/CEDULA_${person.identification}`, { uid: uid[key] });
    if (person.roles.includes('declarant')) {
      await put(`teacherDirectory/${uid[key]}`, {
        fullName: person.fullName, unitId: UNIT_ID,
        identification: person.identification, updatedAt: now,
      });
    }
  }

  // 5. Course catalog of the career, with the reservation of each code.
  for (const c of COURSES) {
    await put(`courses/${c.id}`, {
      code: c.code, name: c.name, credits: c.credits, weeklyHours: c.weeklyHours,
      unitId: UNIT_ID, campusId: CAMPUS_ID, active: true, createdAt: now, updatedAt: now,
    });
    await put(`courseCodes/${CAMPUS_ID}_${c.code}`, { courseId: c.id });
  }

  // 6. The coordination's assignment for "docente" in the period.
  await put(`workloadAssignments/${PERIOD_ID}_${uid.docente}`, {
    declarantUid: uid.docente,
    periodId: PERIOD_ID,
    courses: ASSIGNED.map((a) => ({
      name: a.course.name, courseId: a.course.id, code: a.course.code,
      lessonMinutes: a.lessonMinutes, workloadMinutes: a.workloadMinutes,
    })),
    courseIds: ASSIGNED.map((a) => a.course.id),
    campusId: CAMPUS_ID,
    unitId: UNIT_ID,
    slots: ASSIGNED.flatMap((a) => a.slots.map((s) => ({ ...s, course: a.course.name }))),
    lessonMinutes: ASSIGNED.reduce((sum, a) => sum + a.lessonMinutes, 0),
    workloadMinutes: ASSIGNED.reduce((sum, a) => sum + a.workloadMinutes, 0),
    assignedBy: uid.coordinacion,
    updatedAt: now,
  });

  // 7. A closed earlier period with a FINALIZADA declaration of "docente",
  // as the web leaves it after both signatures and HR approval: something
  // to see in the list and the history.
  const PAST = '2026_I';
  const past = ASSIGNED[0];
  await put(`periods/${PAST}`, {
    name: 'I Ciclo - 2026', cycle: 'I', year: 2026,
    startDate: new Date('2026-03-09T06:00:00Z'), endDate: new Date('2026-07-04T06:00:00Z'),
    enabled: false, createdBy: uid.admin,
  });
  await put(`workloadAssignments/${PAST}_${uid.docente}`, {
    declarantUid: uid.docente, periodId: PAST,
    courses: [{
      name: past.course.name, courseId: past.course.id, code: past.course.code,
      lessonMinutes: past.lessonMinutes, workloadMinutes: past.workloadMinutes,
    }],
    courseIds: [past.course.id], campusId: CAMPUS_ID, unitId: UNIT_ID,
    slots: past.slots.map((s) => ({ ...s, course: past.course.name })),
    lessonMinutes: past.lessonMinutes, workloadMinutes: past.workloadMinutes,
    assignedBy: uid.coordinacion, updatedAt: now,
  });
  const DECL = 'seed-2026-I-docente';
  const VERSION = 'v1';
  const docente = PEOPLE.docente;
  const name = past.course.name;
  await put(`declarations/${DECL}`, {
    declarantUid: uid.docente, declarantName: docente.fullName, periodId: PAST,
    superiorUid: uid.superior, campusId: CAMPUS_ID, status: 'FINALIZADA',
    currentVersionId: VERSION, currentVersionNumber: 1,
    hrResult: 'FINALIZADA', hrResultAt: now, lastEventId: 'seed-cierre',
    createdAt: now, updatedAt: now,
  });
  await put(`declarationSlots/${PAST}_${uid.docente}`, { declarationId: DECL });
  await put(`declarations/${DECL}/versions/${VERSION}`, {
    number: 1,
    declarantSnapshot: {
      fullName: docente.fullName, identification: docente.identification,
      phone: '88880000', email: docente.email,
      unitName: 'Informática Empresarial', campusName: 'Sede del Sur',
    },
    observations: 'IF0009 HC: L 8 am a 10 am; K 8 am a 10 am. AE: V 8 am a 10 am. PyE: V 10 am a 12 md; J 8 am a 10 am.',
    hoursSummary: { expectedMinutes: 600, declaredMinutes: 600, differenceMinutes: 0 },
    validationPassed: true, isLocked: true, lockedAt: now, contentHash: 'seed',
    createdAt: now, createdBy: uid.docente,
  });
  // 240 lesson (fixed slots) + 120 attention + 240 planning = 600 (1/4 TC).
  await put(`declarations/${DECL}/versions/${VERSION}/appointments/a1`, {
    workplace: 'Universidad de Costa Rica · Sede del Sur', position: 'Adjunto',
    workload: '1/4 TC',
    startDate: new Date('2026-03-09T06:00:00Z'), endDate: new Date('2026-07-04T06:00:00Z'),
    blocks: [
      ...past.slots.map((s) => ({ ...s, category: 'lesson', course: name })),
      { day: 5, startMinutes: 8 * 60, endMinutes: 10 * 60, category: 'attention', course: name },
      { day: 5, startMinutes: 10 * 60, endMinutes: 12 * 60, category: 'planning', course: name },
      { day: 4, startMinutes: 8 * 60, endMinutes: 10 * 60, category: 'planning', course: name },
    ],
  });
  await put(`declarations/${DECL}/events/seed-cierre`, {
    type: 'CIERRE', userId: uid.rrhh, timestamp: now, version: 1,
    previousStatus: 'ENVIADA_A_RRHH', newStatus: 'FINALIZADA',
  });

  // 8. A zonaje request of that closed period, rejected by HR: the mobile
  // app only shows zonaje (no map in the phone; requests are made in the
  // web).
  await put(`zonajeRequests/${PAST}_${uid.docente}`, {
    declarantUid: uid.docente, declarantName: docente.fullName, campusId: CAMPUS_ID,
    year: 2026, periodId: PAST, declarationId: DECL, salaryRegime: 'COMPUESTO',
    weeklyMinutes: 1200,
    previousAddress: 'San José, Montes de Oca, San Pedro',
    currentAddress: 'Puntarenas, Golfito, Golfito',
    homeLocation: { lat: 9.93, lng: -84.05 }, distanceMethod: 'LINEA_RECTA',
    declaredDistanceKm: 280.5,
    tseCertificatePath: `zonaje/${uid.docente}/${PAST}/tse.pdf`,
    status: 'RECHAZADA', createdAt: now,
    hrObservation: 'La certificación del TSE no es legible. Adjunte una nueva.',
    reviewedBy: uid.rrhh, reviewedAt: now,
  });

  console.log(`Emuladores del proyecto ${project} con datos de prueba (contraseña de todas: ${PASSWORD}):`);
  for (const person of Object.values(PEOPLE)) {
    console.log(`  ${person.email.padEnd(24)} ${person.roles.join(', ')}`);
  }
  console.log(`Período ${PERIOD_ID} habilitado; docente@ucr.ac.cr tiene 2 cursos asignados (1/2 TC)`);
  console.log(`y una declaración FINALIZADA y una solicitud de zonaje RECHAZADA del período ${PAST} (cerrado).`);
}

main().catch((error) => {
  console.error('No se pudieron cargar los datos de prueba:', error.message);
  process.exit(1);
});
