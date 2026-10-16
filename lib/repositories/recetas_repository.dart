import 'package:hive/hive.dart';

import '../models/receta.dart';
import '../services/api_exception.dart';
import '../services/recetas_api_service.dart';

/// Decide de dónde salen las recetas: primero TheMealDB y, solo si falla la red o el
/// servidor, la última copia guardada en Hive. Las recetas son datos públicos (no de la
/// persona), así que la caché es una sola caja para todos y no se borra al cerrar sesión.
class RecetasRepository {
  RecetasRepository(this._api, [Box? caja]) : _caja = caja ?? Hive.box(nombreCaja);

  static const nombreCaja = 'recetas_cache';

  final RecetasApiService _api;
  final Box _caja;

  Future<(List<String>, bool)> categorias() async {
    try {
      final lista = await _api.categorias();
      await _caja.put('categorias', lista);
      return (lista, false);
    } on ApiException catch (e) {
      final guardadas = _caja.get('categorias');
      if (!_esFallaDeRed(e) || guardadas is! List) rethrow;
      return (guardadas.cast<String>(), true);
    }
  }

  /// Devuelve las recetas y `true` si vienen de la caché.
  Future<(List<RecetaResumen>, bool)> deCategoria(String categoria) async {
    final clave = 'cat_$categoria';
    try {
      final lista = await _api.porCategoria(categoria);
      await _caja.put(clave, lista.map((r) => r.toMap()).toList());
      await _caja.put('sync_$categoria', DateTime.now().toIso8601String());
      return (lista, false);
    } on ApiException catch (e) {
      final guardadas = _caja.get(clave);
      if (!_esFallaDeRed(e) || guardadas is! List) rethrow;
      return (guardadas.map((m) => RecetaResumen.fromMap(m as Map)).toList(), true);
    }
  }

  Future<List<RecetaResumen>> buscar(String texto) => _api.buscar(texto);

  Future<RecetaDetalle?> detalle(String id) => _api.detalle(id);

  String ultimaSincronizacion(String categoria) {
    final fecha = DateTime.tryParse('${_caja.get('sync_$categoria')}')?.toLocal();
    if (fecha == null) return 'desconocida';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)} ${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  /// Solo las fallas de infraestructura (sin red, tiempo agotado, 5xx) usan la caché.
  bool _esFallaDeRed(ApiException e) => e.statusCode == null || e.statusCode! >= 500;
}
