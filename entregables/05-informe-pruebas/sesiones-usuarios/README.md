# Kit para las sesiones con usuarios

El §8 del descriptor pide sesiones con **al menos tres personas que no sean del equipo**, todas con **la misma
versión** y **el mismo guion de tres tareas**, observando y anotando cada ayuda. Al menos una persona debe ser
del perfil previsto (docente o alguien que conozca la declaración jurada de jornada). Datos ficticios,
participación voluntaria y permiso antes de grabar.

Este kit tiene lo necesario para hacerlas y para que queden como evidencia:

| Archivo | Para qué |
|---|---|
| `hoja-sesion.md` | Una hoja por participante: consentimiento, perfil, las tres tareas, percepción. Imprimir tres (o llenarla en el teléfono o la compu mientras se observa). |
| `../evidencias/sesiones-usuarios/` | Fotos, capturas y hojas escaneadas de cada sesión, con los nombres de abajo. |
| `../informe-pruebas.md` §6 | Donde se pasan en limpio los resultados de las tres hojas. |

## 1. Antes de la primera sesión (una vez)

- [x] **APK 2.0.0+7** publicado: <https://github.com/CrisSalas07/DeclaraUCR/releases/tag/v2.0.0%2B7> (`DeclaraUCR-v2.0.0+7-0caae96.apk`). Todas las sesiones con esta versión; si sale otra antes
      de terminar, se anota y se explica.
- [ ] **Una cuenta de declarante por participante** en el backend real (P1, P2, P3), cada una con revisor
      asignado y **los mismos cursos y clases fijas** asignados por la Coordinación en el período habilitado
      (`docs/INSTALACION.md` §6). Así las tres personas empiezan igual y nadie ve la declaración de otra.
      Correos y contraseñas por canal privado; nunca en el repo ni en las hojas.
- [ ] Anotar aquí **qué curso y cuántas horas de atención** tienen esas cuentas, porque la tarea T2 los nombra:
      curso `[COMPLETAR, p. ej. IF0009]`, atención `[COMPLETAR, p. ej. 2 h]`, día sugerido `[COMPLETAR, p. ej.
      lunes después de clase]`.
- [ ] Hacer las tres tareas uno mismo con una de las cuentas y **borrar desde la web** lo creado (o usar una
      cuarta cuenta) para confirmar que el guion funciona con esos datos.
- [ ] Imprimir o copiar tres veces `hoja-sesion.md`.
- [ ] Reloj o cronómetro del teléfono para los tiempos.

## 2. Antes de cada sesión

- [ ] La app instalada en el teléfono que se va a usar y con la **sesión ya iniciada** en la cuenta de ese
      participante (la persona no escribe contraseñas: no es parte de las tareas y evita usar datos reales).
- [ ] La cuenta **sin declaración** en el período (si no, T1 no se puede hacer).
- [ ] Revisar al pie del inicio de sesión o en el perfil: "Versión 2.0.0+7 · …". Anotarlo en la hoja.
- [ ] Letra del teléfono como la usa la persona normalmente (si la persona trae su propio teléfono).

## 3. Durante la sesión

1. Leer el párrafo de bienvenida de la hoja tal cual y pedir el consentimiento (y el de grabación, si se
   graba). Si no acepta grabar, no se graba: alcanza con las notas.
2. Dar una tarea a la vez, leyendo la frase de la hoja. No explicar la pantalla.
3. Anotar hora de inicio y de fin, lo que la persona intenta, dónde duda y cada ayuda (qué se le dijo y por qué).
   Solo se ayuda si la persona lo pide o lleva más de un minuto trabada.
4. Al final de cada tarea, **captura de pantalla** de cómo quedó (ver nombres abajo).
5. Al terminar las tres: la pregunta de facilidad (1 a 5) y "¿qué le cambiaría?", con sus palabras.

## 4. Nombres de las evidencias

En `entregables/05-informe-pruebas/evidencias/sesiones-usuarios/`:

| Archivo | Qué es |
|---|---|
| `P1-hoja.pdf` (o `.jpg`) | La hoja de sesión llena (foto o escaneo). Sin nombre ni cédula de la persona. |
| `P1-T1-borrador.png` | Captura al terminar T1: la lista con la declaración en **Borrador**. |
| `P1-T2-resumen.png` | Captura al terminar T2: el resumen con las horas de atención ubicadas. |
| `P1-T3-estado.png` | Captura al terminar T3: el resumen con el estado y lo que falta. |
| `P1-sesion.jpg` | (Opcional) Foto de la sesión **sin la cara** de la persona, o solo de las manos y el teléfono. |
| `P1-grabacion.mp4` | (Opcional, solo con permiso) Grabación de pantalla. Si pesa mucho, va al Drive y aquí solo el enlace. |

Igual para P2 y P3. La nueva comprobación (§6.7 del informe) usa el prefijo `R-` y el participante: por
ejemplo, `R-P1-T2-resumen.png`.

## 5. Después de las tres sesiones

1. Pasar a `informe-pruebas.md` §6.3 a §6.5 lo de las tres hojas.
2. Juntar los problemas en §6.6 (U-01, U-02…): qué se vio, quién y en qué tarea, impacto y prioridad.
3. Corregir los de mayor impacto, subir versión (2.0.0+8), compilar y publicar.
4. **Volver a probar** esos problemas con al menos una de las personas (§6.7) y guardar la evidencia con `R-`.
5. Pasar los hallazgos a la matriz de mejoras si vienen de usuarios, y anotar en el registro de participación
   quién guió y quién anotó cada sesión.
