import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/receta.dart';
import 'api_exception.dart';

/// Acceso a TheMealDB (API pública de recetas). Usa su propio `dio`: esta API no lleva
/// el token de la persona, así que no pasa por los interceptores del backend.
class RecetasApiService {
  RecetasApiService({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConfig.recetasUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 15)));

  final Dio _dio;

  /// Nombres de las categorías (Beef, Chicken, Dessert…).
  Future<List<String>> categorias() async {
    final datos = await _get('/categories.php');
    final lista = datos['categories'];
    if (lista is! List) return [];
    return lista.map((c) => '${(c as Map)['strCategory']}').where((c) => c.isNotEmpty).toList();
  }

  Future<List<RecetaResumen>> porCategoria(String categoria) => _lista('/filter.php', {'c': categoria});

  Future<List<RecetaResumen>> buscar(String texto) => _lista('/search.php', {'s': texto});

  Future<RecetaDetalle?> detalle(String id) async {
    final datos = await _get('/lookup.php', {'i': id});
    final meals = datos['meals'];
    if (meals is! List || meals.isEmpty) return null;
    return RecetaDetalle.fromJson(Map<String, dynamic>.from(meals.first as Map));
  }

  /// TheMealDB responde `{"meals": null}` cuando no hay resultados: eso es «vacío», no un error.
  Future<List<RecetaResumen>> _lista(String ruta, Map<String, dynamic> query) async {
    final datos = await _get(ruta, query);
    final meals = datos['meals'];
    if (meals is! List) return [];
    return meals.map((m) => RecetaResumen.fromJson(Map<String, dynamic>.from(m as Map))).toList();
  }

  Future<Map<String, dynamic>> _get(String ruta, [Map<String, dynamic>? query]) async {
    try {
      final r = await _dio.get(ruta, queryParameters: query);
      if (r.data is! Map) throw ApiException('El servicio de recetas respondió con un formato inesperado.');
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException catch (e) {
      throw ApiException.desde(e);
    }
  }
}
