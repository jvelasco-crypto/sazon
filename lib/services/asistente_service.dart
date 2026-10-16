import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/receta.dart';
import 'api_client.dart';

/// Lo que responde el asistente: texto y, a veces, una receta sugerida.
class RespuestaAsistente {
  final String respuesta;
  final String? recetaId;
  const RespuestaAsistente(this.respuesta, this.recetaId);
}

/// Cliente del proxy del asistente. La app NO conoce ninguna clave de IA: solo la
/// dirección del proxy. Envía datos mínimos (la pregunta, los nombres de las favoritas y
/// las recetas de la categoría que se está viendo) y el token de la sesión en la cabecera.
class AsistenteService {
  AsistenteService(this._api, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.proxyUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
            ));

  final ApiClient _api;
  final Dio _dio;

  Future<RespuestaAsistente> preguntar(String consulta, {required List<String> favoritos, required List<RecetaResumen> candidatas}) async {
    try {
      final r = await _dio.post(
        '/asistente',
        data: {
          'consulta': consulta,
          'favoritos': favoritos.take(20).toList(),
          'candidatas': candidatas.take(30).map((c) => {'id': c.id, 'nombre': c.nombre}).toList(),
        },
        options: Options(headers: {if (_api.token != null) 'Authorization': 'Bearer ${_api.token}'}),
      );
      final datos = Map<String, dynamic>.from(r.data as Map);
      final texto = (datos['respuesta'] as String?)?.trim() ?? '';
      if (texto.isEmpty) throw ApiException('El asistente no devolvió una respuesta. Inténtalo de nuevo.');
      // La respuesta de la IA es un dato: solo se acepta una receta que estaba entre las candidatas.
      final id = datos['receta_id'];
      final valida = id is String && candidatas.any((c) => c.id == id);
      return RespuestaAsistente(texto, valida ? id : null);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw ApiException('No se pudo conectar con el asistente. Revisa que el proxy esté encendido.');
      }
      throw ApiException.desde(e);
    }
  }
}
