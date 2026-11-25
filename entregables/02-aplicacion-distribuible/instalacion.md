# Instalación, actualización y entrega del APK

Guía de la app móvil **DeclaraUCR** para el despliegue de prueba del Proyecto 2 (§6 del descriptor). El
despliegue es académico: el APK se instala directamente, sin Google Play.

- **Backend:** Firebase del Proyecto 1 (`declarahorario-b186f`), el mismo de la web DeclaraHorario. El teléfono
  solo necesita internet; no depende de ninguna computadora.
- **Requisitos del teléfono:** Android 7.0 o superior, unos 60 MB libres y conexión a internet.
- **Identificación:** cada APK se llama `DeclaraUCR-v{versión}-{commit}.apk`, y la app muestra lo mismo en el
  inicio de sesión y en el perfil (por ejemplo, «Versión 2.0.0+2 · 78dd6ee»).

## 1. Instalar

1. Descargue el APK en el teléfono, desde el enlace del equipo (GitHub Releases).
2. Ábralo desde las notificaciones o desde la app **Archivos › Descargas**.
3. La primera vez, Android pide permiso para **instalar apps de fuentes desconocidas** para el navegador o la
   app de archivos: actívelo y vuelva atrás.
4. Toque **Instalar**. Si aparece *Google Play Protect*, elija **Instalar de todas formas**: la app no está en
   Google Play, por eso no la conoce.
5. Abra **DeclaraUCR** y compruebe la versión al pie del inicio de sesión.

## 2. Acceder

Inicie sesión con una cuenta de prueba (tabla siguiente) o cree una con **Crear cuenta**: queda como persona
declarante y pide elegir sede y carrera. Una cuenta nueva **no puede crear declaraciones** hasta que
Administración le asigne superior y la Coordinación le asigne cursos, desde la web.

| Rol | Para qué |
|---|---|
| Declarante con superior y cursos asignados | Recorrer los tres procesos |
| Declarante sin cursos asignados | Ver el mensaje que lo explica |
| Superior, RRHH o administración | Ver que la app es solo para declarantes |

Las cuentas de prueba usan correos reales del equipo, porque el registro verifica el correo. Por eso los
correos y las contraseñas se entregan aparte y no van en este documento. Los demás datos (sede, carrera,
cursos) son ficticios.

Para evaluar la app basta la cuenta de declarante con cursos; el equipo la entrega con su contraseña.

## 3. Actualizar a una versión nueva

1. Descargue el APK nuevo.
2. Ábralo e instálelo **encima** de la app actual: Android la reemplaza y conserva la sesión.
3. Compruebe la versión nueva al pie del inicio de sesión o en el perfil.

Funciona porque todas las versiones se firman con la **misma llave del equipo** y el número de versión siempre
sube. Si Android responde «App no instalada» o «conflicto de firma», el APK se firmó con otra llave: desinstale
la app e instale el APK nuevo (no se pierde nada, ver abajo).

## 4. Volver a la versión anterior

Android no instala una versión más vieja encima de una más nueva, así que:

1. Mantenga presionado el ícono de DeclaraUCR › **Desinstalar**.
2. Descargue el APK anterior desde GitHub Releases (cada versión queda publicada).
3. Instálelo (paso 1) e inicie sesión de nuevo.

**No se pierde información:** las declaraciones, el perfil y las solicitudes están en Firebase, no en el
teléfono. Solo se pierde lo que estuviera en pantalla sin guardar.

## 5. Compilar y publicar una versión (equipo)

### Una sola vez: la llave de release del equipo

La llave firma todos los APK; con ella cualquiera del equipo puede compilar y las actualizaciones funcionan.
**Nunca va al repositorio** (`android/.gitignore` ignora `key.properties`, `*.jks` y `*.keystore`).

1. Créela (una persona, una vez):

   ```
   keytool -genkey -v -keystore declaraucr-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias declaraucr
   ```

   `keytool` viene con Java (el JDK de Android Studio sirve). Pide una contraseña y unos datos (pueden ser los
   del equipo y la UCR).
2. Guarde el `.jks` y la contraseña en un lugar **privado y compartido** del equipo (gestor de contraseñas o
   carpeta privada). **Si se pierde, no se pueden publicar actualizaciones**: habría que desinstalar en todos los
   teléfonos.
3. En cada computadora que compile, copie `android/key.properties.example` a `android/key.properties` y
   complételo con la ruta al `.jks`, el alias y las contraseñas.

### En cada versión

1. Suba la versión en `pubspec.yaml`: `version: 2.0.1+3`. El número después de `+` **debe subir siempre**, o
   Android no aceptará la actualización.
2. Haga commit de todo.
3. Compile:

   ```
   dart run tool/build_apk.dart
   ```

   Se niega si hay cambios sin commit o si falta la llave. Deja en `dist/` el APK y un `.txt` con versión,
   commit, backend, firma y SHA-256.
4. Etiquete y suba la etiqueta: `git tag v2.0.1+3` y `git push origin v2.0.1+3`.
5. Publíquelo en **GitHub › Releases › Draft a new release**: elija la etiqueta, adjunte el APK y pegue el `.txt`
   y los cambios de la versión.
6. Instálelo desde cero en un teléfono que **no** sea de desarrollo y anote el resultado como evidencia (§6).

## 6. Preparar el backend real (equipo)

Los datos de prueba del emulador (`backend/proyecto1/seed.mjs`) **no** llegan al backend real, a propósito.
Para recorrer los procesos en el teléfono, desde la **web del Proyecto 1** con una cuenta de administración:

1. Una **sede** con su ubicación y una **carrera** de esa sede.
2. Un **período habilitado** (por ejemplo, II Ciclo - 2026).
3. Cuentas ficticias: una de **superior**, una de **Coordinación** de la carrera y dos de **declarante**.
4. A las declarantes, asignarles **superior** (Administración › Usuarios).
5. Con la cuenta de Coordinación, **asignar cursos** y franjas de clase en el período a **una** de las
   declarantes (la otra queda sin cursos, para el caso de prueba).
   En las sesiones con usuarios, cada participante crea su propia cuenta y el equipo le asigna en la web el
   superior y los mismos cursos y franjas (ver `entregables/05-informe-pruebas/sesiones-usuarios/`).
6. Entregar al equipo los correos y contraseñas de las cuentas por un canal privado, no en el repositorio.

## 7. Limitaciones conocidas

- **Firma de la persona declarante:** en el teléfono o en la web, con el mismo juramento y la misma huella del
  contenido. Firmada, queda de solo lectura en el teléfono.
- **Revisión, RRHH y correcciones** se hacen en la web: la aprobación del superior y de Recursos Humanos, y una
  declaración devuelta se corrige en la web (versión nueva).
- **PDF:** la vista previa ("BORRADOR"), la copia en revisión y el documento final se ven en el teléfono, con el
  mismo formulario que la web.
- **Zonaje** es de consulta: la solicitud (mapa y certificación del TSE) se hace en la web.
- **Un nombramiento por declaración:** si en la web se agregó más de uno, el teléfono muestra y edita el primero
  y deja los demás como están.
- **Sin conexión no se guarda:** la app lo avisa y conserva los cambios en pantalla; si se cierra la app sin
  señal, lo no guardado se pierde.
- **No incluido en el móvil:** verificación del correo, registro con pasaporte y perfiles creados por
  Administración antes del registro.
- `VALIDADA` lo calcula el cliente, igual que en la web del Proyecto 1 (las reglas validan el formato y los
  permisos, no recalculan las horas).
