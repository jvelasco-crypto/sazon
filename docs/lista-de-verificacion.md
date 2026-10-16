# Lista de verificación del Proyecto Final

Es la rúbrica de `final-project/rubric.md` convertida en preguntas que puedes comprobar tú antes de subir tu entrega. Márcala con tu proyecto abierto, no de memoria. Cada punto dice **qué mirar**.

> **Estado de Sazón (16-oct-2026):** marcado tras comprobarlo en el emulador y en el código. Evidencia en el README (capturas `docs/capturas/` y `docs/scripts/demo-errores.sh`). Pendientes: el Release (se publica con la etiqueta `v1.0.0`) y probar su APK; la entrega en Moodle es solo el enlace al repositorio (enunciado, sección 5).

## 1. Persistencia remota o funcionalidad colaborativa (20 %)

- [x] Puedo **crear, ver y eliminar** un dato de mi dominio desde la app y queda guardado en mi backend o en Firebase. *Mira:* el registro del servidor o su consola.
- [x] Sin sesión, esa funcionalidad se rechaza (401 o regla de seguridad). *Mira:* cerrar sesión e intentarlo.

## 2. Autenticación (15 %)

- [x] Registro, inicio y cierre de sesión funcionan. *Mira:* hacerlos con un usuario nuevo.
- [x] El token se guarda con almacenamiento seguro y la sesión sobrevive al reinicio.

## 3. Datos reales (15 %)

- [x] La lista principal sale de una fuente real o de al menos 15-20 registros en mi backend, Firebase o Hive; no está escrita a mano en el código.

## 4. Persistencia local (10 %)

- [x] Una funcionalidad (favoritos, historial, borradores) **sobrevive al cierre completo** de la app. *Mira:* cerrar la app de «recientes» y abrirla.

## 5. Estado con GetX (10 %)

- [x] El estado compartido entre pantallas vive en controladores, no repetido con `setState` en cada pantalla. *Mira:* buscar `setState` en `lib/screens/`.

## 6. IA sin secretos (10 %)

- [x] El asistente llama a **mi servidor**, no al proveedor. *Mira:* la dirección que usa la app.
- [x] No hay claves en el repositorio:

  ```bash
  grep -rniE "api[_-]?key|sk-[a-z0-9]{10}|secret" lib .env.example
  ```

- [x] `.env` está en `.gitignore` y nunca se subió:

  ```bash
  git check-ignore -v .env
  git log --all --oneline -- .env
  ```

## 7. Manejo de errores (10 %)

- [x] Cada pantalla con datos muestra **carga, vacío y error** distintos. *Mira:* apagar el backend y recorrer las pantallas.
- [x] Con un backend HTTP: 401, 400, 422, 5xx y «sin conexión» muestran mensajes distintos.
- [x] Un error inesperado no deja una pantalla roja ni blanca (`ReporteErrores.instalar()` o equivalente).

## 8. Arquitectura y legibilidad (5 %)

- [x] Ninguna pantalla llama directo a HTTP o Firestore: pasa por un controlador y un servicio.
- [x] Los nombres siguen la terminología del curso y hay pruebas que pasan:

  ```bash
  flutter test
  ```

## 9. Documentación y entrega (5 %)

- [x] El `README.md` sigue la plantilla (`docs/README-plantilla.md`) y alguien que no conoce mi proyecto podría ejecutarlo.
- [x] El repositorio tiene **historial real de commits** (no uno solo al final).
- [ ] Hay un Release con el APK descargable, generado por GitHub Actions.
- [ ] La entrega en Moodle incluye el enlace al repositorio, el enlace al Release y el README.

## Antes de subir

- [x] Repasé las nueve secciones con la app abierta.
- [ ] Probé el APK en un emulador limpio, siguiendo mi propio README.
