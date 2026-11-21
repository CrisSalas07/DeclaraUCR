# Entregables del Proyecto 2 — DeclaraUCR

Los ocho entregables del §11 del descriptor, cada uno en su carpeta. Las fuentes están en Markdown (se
versionan con el código); en `drive/` están las mismas en Word, para subir al Drive y exportar a PDF.

Todo lo marcado `[COMPLETAR]` depende de algo que solo el equipo puede hacer. El resto ya está hecho y con
evidencia.

| # | Entregable | Archivo | Estado |
|---|---|---|---|
| 1 | Repositorio de código | `01-repositorio/repositorio.md` | Listo; falta la etiqueta final |
| 2 | Aplicación distribuible | `02-aplicacion-distribuible/aplicacion-distribuible.md` | APK 2.0.0+7 publicado; faltan CP-08 y confirmar las cuentas |
| 3 | Informe técnico | `03-informe-tecnico/informe-tecnico.md` | Listo; falta 1 párrafo de contexto del P1 |
| 4 | Matriz de mejoras | `04-matriz-mejoras/matriz-mejoras.md` | El P1 no tuvo observaciones de cambio: falta adjuntar esa evidencia y, después, la retroalimentación de la socialización |
| 5 | Informe de pruebas | `05-informe-pruebas/informe-pruebas.md` | Casos técnicos y automatizadas listos; kit de sesiones con usuarios listo (`sesiones-usuarios/`); faltan CP-08 y aplicar las 3 sesiones |
| 6 | Material de socialización | `06-socializacion/` | Guion del video, formulario y plantilla de síntesis listos; faltan grabar el video y enviarlo |
| 7 | Guía de uso | `07-guia-uso/guia-de-uso.md` | Lista; revisar contra el APK final |
| 8 | Registro de participación | `08-registro-participacion/registro-participacion.md` | Falta confirmar identidades de git y anotar lo que no tiene commit |

## Lista de control de cierre

Del plan de entregables, con lo que ya se cumplió:

- [x] Instrucciones de ejecución y construcción (README, `docs/INSTALACION.md`)
- [ ] Tag final en el repositorio
- [x] APK 2.0.0+7 con versión y commit (release v2.0.0+7, `0caae96`)
- [x] Backend accesible fuera de la computadora de desarrollo (Firebase del P1)
- [ ] Cuentas de prueba y datos ficticios confirmados en el backend real
- [ ] Instalación desde cero en otro teléfono (CP-08)
- [x] Informe técnico actualizado (falta un párrafo)
- [ ] Evidencia de la evaluación del P1 adjunta (no pidió cambios) y etiqueta `p1-entrega`
- [x] 8 casos técnicos documentados (7 ejecutados y aprobados)
- [x] Pruebas automatizadas de las reglas de mayor riesgo (109, todas pasan)
- [ ] Cuentas de declarante P1, P2 y P3 en el backend real (kit §1)
- [ ] Sesiones con 3 personas externas al equipo (kit y hoja de sesión listos)
- [ ] Hallazgos de usuarios y nueva comprobación
- [ ] Video enviado al docente con el formulario, y síntesis
- [ ] Al menos 2 mejoras después de la socialización
- [x] Guía de uso (revisar contra el APK final)
- [ ] Registro de participación confirmado
- [x] Limitaciones conocidas documentadas

## Orden sugerido para lo que falta

1. ~~Commit de D-01 a D-03, APK y release 2.0.0+7~~ (hecho: <https://github.com/CrisSalas07/DeclaraUCR/releases/tag/v2.0.0%2B7>).
2. CP-08 en un teléfono que no sea el de desarrollo.
3. Las tres sesiones con usuarios, todas con la 2.0.0+7: seguir `05-informe-pruebas/sesiones-usuarios/README.md`
   e imprimir `hoja-sesion.md` tres veces.
4. Adjuntar a la matriz la captura de la evaluación del P1 (sin cambios pedidos) y crear la etiqueta `p1-entrega`.
5. Grabar el video con `06-socializacion/guion-video.md`, publicar el formulario y enviar los dos enlaces al docente.
6. Dos mejoras de la socialización, nueva versión, nueva comprobación y etiqueta final.
7. Exportar a PDF el informe técnico, el informe de pruebas y la guía.

## Evidencias

- Casos técnicos: `docs/pruebas/CP-*.png`
- Capturas de la app (Android, 2.0.0+4): `docs/capturas/`
- Recorrido exploratorio y defectos del 20/11/2026: `05-informe-pruebas/evidencias/recorrido-2026-11-20/`
- Sesiones con usuarios (hojas, capturas): `05-informe-pruebas/evidencias/sesiones-usuarios/`
