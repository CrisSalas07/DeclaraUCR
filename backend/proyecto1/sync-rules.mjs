// Copies the security rules of the Proyecto 1 repository (DeclaraHorario)
// into this folder and records the commit they came from in ORIGEN.txt.
//
//   node backend/proyecto1/sync-rules.mjs <path to DeclaraHorario>
//
// The copies are only used by the local emulators. Production always runs
// the rules deployed from DeclaraHorario; this repository never deploys them.
import { copyFileSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const source = process.argv[2];
if (!source) {
  console.error('Uso: node backend/proyecto1/sync-rules.mjs <ruta a DeclaraHorario>');
  process.exit(1);
}

const files = ['firestore.rules', 'storage.rules', 'firestore.indexes.json'];
for (const file of files) {
  copyFileSync(path.join(source, file), path.join(here, file));
}

const git = (...args) =>
  execFileSync('git', ['-C', source, ...args], { encoding: 'utf8' }).trim();
const commit = git('log', '-1', '--format=%H %ad', '--date=short');
const dirty = git('status', '--porcelain', '--', ...files);

writeFileSync(
  path.join(here, 'ORIGEN.txt'),
  `Copiados de DeclaraHorario (Proyecto 1), commit ${commit}\n` +
    (dirty ? 'ATENCIÓN: tenían cambios sin commit al copiarlos.\n' : '') +
    `Archivos: ${files.join(', ')}\n`,
);
console.log(`Reglas copiadas del commit ${commit}${dirty ? ' (con cambios sin commit)' : ''}.`);
