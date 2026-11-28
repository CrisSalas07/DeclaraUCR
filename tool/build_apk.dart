// Builds the APK to hand out, identified by version and commit (Proyecto 2,
// section 6):
//
//   dart run tool/build_apk.dart
//
// It refuses to build from uncommitted changes (the commit would not
// describe the APK) or without the team's release key (updates would fail
// on phones that have a build signed with another key). Override with
// --allow-dirty or --allow-debug-key, only for local tries.
//
// Output in dist/: DeclaraUCR-v{version}-{commit}.apk and a .txt with the
// version, commit, backend, signature and SHA-256 of the file.
import 'dart:io';

Future<void> main(List<String> args) async {
  final allowDirty = args.contains('--allow-dirty');
  final allowDebugKey = args.contains('--allow-debug-key');
  final windows = Platform.isWindows;

  Future<String> run(String exe, List<String> arguments) async {
    final result = await Process.run(exe, arguments, runInShell: windows);
    if (result.exitCode != 0) {
      stderr.writeln('Falló: $exe ${arguments.join(' ')}\n${result.stderr}');
      exit(1);
    }
    return (result.stdout as String).trim();
  }

  // 1. A committed tree, so the commit names exactly this APK.
  final dirty = await run('git', ['status', '--porcelain']);
  if (dirty.isNotEmpty && !allowDirty) {
    stderr.writeln(
      'Hay cambios sin commit. Haga commit antes de compilar la versión '
      'que se va a entregar (o use --allow-dirty para una prueba local).',
    );
    exit(1);
  }
  final commit = await run('git', ['rev-parse', '--short', 'HEAD']);

  // 2. The version of pubspec.yaml ("2.0.0+2": name + build number).
  final pubspec = await File('pubspec.yaml').readAsString();
  final version = RegExp(
    r'^version:\s*(\S+)',
    multiLine: true,
  ).firstMatch(pubspec)?.group(1);
  if (version == null) {
    stderr.writeln('No se encontró "version:" en pubspec.yaml.');
    exit(1);
  }

  // 3. The team's release key.
  final hasKey = File('android/key.properties').existsSync();
  if (!hasKey && !allowDebugKey) {
    stderr.writeln(
      'Falta android/key.properties con la llave de release del equipo '
      '(ver entregables/02-aplicacion-distribuible/instalacion.docx). Sin ella el APK se firma con la llave de '
      'debug de esta computadora y no actualizaría a las versiones firmadas '
      'con la del equipo. Use --allow-debug-key solo para pruebas locales.',
    );
    exit(1);
  }

  // 4. Build against the real backend, stamping version and commit.
  stdout.writeln('Compilando DeclaraUCR $version ($commit)...');
  final build = await Process.start(
    'flutter',
    [
      'build',
      'apk',
      '--release',
      '--dart-define=FIREBASE_ENV=production',
      '--dart-define=APP_VERSION=$version',
      '--dart-define=GIT_COMMIT=$commit${dirty.isEmpty ? '' : '-sin-commit'}',
    ],
    runInShell: windows,
    mode: ProcessStartMode.inheritStdio,
  );
  if (await build.exitCode != 0) exit(1);

  // 5. Named copy in dist/, with its fingerprint.
  final name = 'DeclaraUCR-v$version-$commit';
  final apk = File('build/app/outputs/flutter-apk/app-release.apk');
  await Directory('dist').create();
  final out = await apk.copy('dist/$name.apk');
  final sha256 = windows
      ? (await run('certutil', ['-hashfile', out.path, 'SHA256']))
            .split('\n')[1]
            .replaceAll(' ', '')
            .trim()
      : (await run('shasum', ['-a', '256', out.path])).split(' ').first;
  final info = [
    'DeclaraUCR $version',
    'Commit: $commit${dirty.isEmpty ? '' : ' (con cambios sin commit)'}',
    'Backend: Firebase del Proyecto 1 (declarahorario-b186f)',
    'Firma: ${hasKey ? 'llave de release del equipo' : 'llave de debug de esta computadora'}',
    'Tamaño: ${(await out.length() / (1024 * 1024)).toStringAsFixed(1)} MB',
    'SHA-256: $sha256',
    'Compilado: ${DateTime.now().toIso8601String()}',
  ].join('\n');
  await File('dist/$name.txt').writeAsString('$info\n');

  stdout
    ..writeln('\n$info')
    ..writeln('\nListo: ${out.path}')
    ..writeln(
      'Siguiente: git tag v$version && git push origin v$version, y '
      'publique el APK (ver entregables/02-aplicacion-distribuible/instalacion.docx).',
    );
}
