import '../models/resena.dart';
import 'api_client.dart';

/// Reseñas en el backend propio. Todas las rutas exigen sesión: el token lo agrega el
/// interceptor de `ApiClient`, y un 401 cierra la sesión en un solo lugar.
class ResenasService {
  ResenasService(this._api);

  final ApiClient _api;

  Future<List<Resena>> deReceta(String recetaId) async {
    final r = await _api.get('/resenas/', query: {'receta_id': recetaId});
    return _lista(r.data);
  }

  Future<List<Resena>> mias() async => _lista((await _api.get('/resenas/mias')).data);

  Future<ResumenResenas> resumen(String recetaId) async {
    final r = await _api.get('/resenas/resumen', query: {'receta_id': recetaId});
    return ResumenResenas.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<Resena> crear({required String recetaId, required String recetaNombre, required int calificacion, required String comentario}) async {
    final r = await _api.post('/resenas/', data: {
      'receta_id': recetaId,
      'receta_nombre': recetaNombre,
      'calificacion': calificacion,
      'comentario': comentario,
    });
    return Resena.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// PATCH: solo los campos que cambian.
  Future<Resena> editar(int id, {required int calificacion, required String comentario}) async {
    final r = await _api.patch('/resenas/$id', data: {'calificacion': calificacion, 'comentario': comentario});
    return Resena.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<void> eliminar(int id) => _api.delete('/resenas/$id');

  List<Resena> _lista(dynamic datos) =>
      datos is List ? datos.map((e) => Resena.fromJson(Map<String, dynamic>.from(e as Map))).toList() : [];
}
