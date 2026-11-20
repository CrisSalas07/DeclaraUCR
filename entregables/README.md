# Entregables del Proyecto 2 — DeclaraUCR

Los ocho entregables del §11 del descriptor, cada uno en su carpeta. Las fuentes están en Markdown (se
versionan con el código); en `drive/` están las mismas en Word, para subir al Drive y exportar a PDF.

Todo lo marcado `[COMPLETAR]` depende de algo que solo el equipo puede hacer. El resto ya está hecho y con
evidencia.

| # | Entregable | Archivo | Estado |
|---|---|---|---|
| 1 | Repositorio de código | `01-repositorio/repositorio.md` | Listo; falta la etiqueta final |
| 2 | Aplicación distribuible | `02-aplicacion-distribuible/aplicacion-distribuible.md` | Falta compilar y publicar la 2.0.0+7, CP-08 y confirmar las cuentas |
| 3 | Informe técnico | `03-informe-tecnico/informe-tecnico.md` | Listo; falta 1 párrafo de contexto del P1 |
| 4 | Matriz de mejoras | `04-matriz-mejoras/matriz-mejoras.md` | Falta copiar la retroalimentación del P1 y, después, la de la socialización |
| 5 | Informe de pruebas | `05-informe-pruebas/informe-pruebas.md` | Casos técnicos y automatizadas listos; faltan CP-08 y las 3 sesiones con usuarios |
| 6 | Material de socialización | `06-socializacion/` | Guion, formulario y plantilla de síntesis listos; faltan las diapositivas y aplicarlo |
| 7 | Guía de uso | `07-guia-uso/guia-de-uso.md` | Lista; revisar contra el APK final |
| 8 | Registro de participación | `08-registro-participacion/registro-participacion.md` | Falta confirmar identidades de git y anotar lo que no tiene commit |

## Lista de control de cierre

Del plan de entregables, con lo que ya se cumplió:

- [x] Instrucciones de ejecución y construcción (README, `docs/INSTALACION.md`)
- [ ] Tag final en el repositorio
- [ ] APK 2.0.0+7 con versión y commit (compilar con `dart run tool/build_apk.dart` **después** del commit)
- [x] Backend accesible fuera de la computadora de desarrollo (Firebase del P1)
- [ ] Cuentas de prueba y datos ficticios confirmados en el backend real
- [ ] Instalación desde cero en otro teléfono (CP-08)
- [x] Informe técnico actualizado (falta un párrafo)
- [ ] Matriz con las observaciones del P1
- [x] 8 casos técnicos documentados (7 ejecutados y aprobados)
- [x] Pruebas automatizadas de las reglas de mayor riesgo (109, todas pasan)
- [ ] Sesiones con 3 personas externas al equipo (guion y tablas listos)
- [ ] Hallazgos de usuarios y nueva comprobación
- [ ] Presentación, formulario aplicado y síntesis
- [ ] Al menos 2 mejoras después de la socialización
- [x] Guía de uso (revisar contra el APK final)
- [ ] Registro de participación confirmado
- [x] Limitaciones conocidas documentadas

## Orden sugerido para lo que falta

1. Hacer commit de las correcciones del 20/11 (D-01 a D-03 y versión 2.0.0+7), compilar el APK y publicar el
   release.
2. CP-08 en un teléfono que no sea el de desarrollo.
3. Las tres sesiones con usuarios, todas con la 2.0.0+7 (guion en el informe de pruebas §6).
4. Copiar la retroalimentación del P1 a la matriz.
5. Diapositivas a partir del guion, el formulario en Google Forms y la socialización.
6. Dos mejoras de la socialización, nueva versión, nueva comprobación y etiqueta final.
7. Exportar a PDF el informe técnico, el informe de pruebas y la guía.

## Evidencias

- Casos técnicos: `docs/pruebas/CP-*.png`
- Capturas de la app (Android, 2.0.0+4): `docs/capturas/`
- Recorrido exploratorio y defectos del 20/11/2026: `05-informe-pruebas/evidencias/recorrido-2026-11-20/`
