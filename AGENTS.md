# AGENTS.md — reglas del proyecto Sazón

Este archivo lo leen los agentes de código (Claude Code, Codex, Antigravity…) al abrir esta carpeta. Es el contexto mínimo para trabajar bien aquí.

## Qué es el proyecto

Sazón es una app Flutter (Android) de recetas: lista recetas reales de TheMealDB por categoría o búsqueda, guarda favoritas en el teléfono, permite escribir reseñas que ven todos los usuarios y tiene un asistente de cocina con IA. Estado con GetX, datos remotos con `dio`, caché y favoritos en Hive, token en `flutter_secure_storage`.

El repositorio tiene tres partes:

- `lib/`, `test/` — la app Flutter.
- `backend/` — API FastAPI + PostgreSQL (usuarios con JWT y reseñas), con Docker.
- `proxy/` — proxy del asistente en Node (sin dependencias). Es el único lugar que conoce la clave del modelo de IA.

## Dónde está cada cosa (app)

- `lib/screens/` y `lib/widgets/` — pantallas y piezas de interfaz. Ninguna pantalla llama a HTTP ni a Hive.
- `lib/controllers/` — estado compartido (controladores GetX).
- `lib/repositories/` y `lib/services/` — acceso a TheMealDB, al backend, al proxy y a Hive.
- `lib/models/`, `lib/utils/`, `lib/config/` — modelos, utilidades y direcciones (`--dart-define`).

## Cómo verificar (siempre, antes de dar un cambio por terminado)

```bash
flutter analyze
flutter test
node --test proxy/proxy.test.js
```

Si tocas `backend/`, corre también sus pruebas (ver README). Si algo falla, corrige el código; no desactives el análisis ni borres pruebas.

## Convenciones

- Pantalla → controller GetX → repositorio/servicio → fuente de datos. Sin `setState` para estado compartido.
- Cada pantalla con datos cubre cargando, vacío y error.
- Todo texto visible va en español neutro. Los nombres de las recetas vienen en inglés desde la fuente y no se traducen en el código.
- Las respuestas de la IA son datos: se validan (una receta sugerida debe estar entre las candidatas).
- Cambios pequeños, con su prueba.

## Prohibido

- Escribir claves, tokens o contraseñas en el código, en los registros o en este archivo. No leer ni modificar ningún `.env`.
- Poner una clave de un proveedor de IA dentro de la app.
- Agregar dependencias sin avisar antes y explicar por qué hacen falta.
- Ejecutar `git push` o crear etiquetas: eso lo hace la persona después de revisar el cambio.

## Reglas del estudiante

- Escribe todo (textos de la app, comentarios y respuestas) en español neutro: «tú / puedes / mira», nunca voseo ni modismos rioplatenses.
- Nunca leas ni muestres variables de entorno con claves (por ejemplo `GEMINI_API_KEY`) ni archivos personales como `~/.zshrc`; si algo parece necesitar una clave, detente y pregunta.
