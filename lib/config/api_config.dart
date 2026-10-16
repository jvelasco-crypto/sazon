/// Direcciones de los servidores. Se definen al ejecutar o compilar con
/// `--dart-define=API_BASE_URL=...` y `--dart-define=PROXY_URL=...`. Los valores por
/// defecto (`10.0.2.2`) son cómo el emulador Android ve el `localhost` de tu computador.
class ApiConfig {
  ApiConfig._();

  /// Backend propio (usuarios y reseñas, con JWT).
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');

  /// Proxy del asistente de IA (guarda la clave del modelo; la app no la conoce).
  static const String proxyUrl = String.fromEnvironment('PROXY_URL', defaultValue: 'http://10.0.2.2:3000');

  /// TheMealDB: API pública de recetas. La clave «1» es la de prueba que el sitio
  /// permite para desarrollo y uso educativo (no es un secreto).
  static const String recetasUrl = String.fromEnvironment('RECETAS_URL', defaultValue: 'https://www.themealdb.com/api/json/v1/1');
}
