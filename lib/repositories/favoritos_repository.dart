import 'package:hive/hive.dart';

import '../models/receta.dart';

/// Recetas favoritas guardadas en Hive: sobreviven al cierre de la app y funcionan
/// sin sesión ni conexión. La clave es el id de la receta.
class FavoritosRepository {
  FavoritosRepository([Box? caja]) : _caja = caja ?? Hive.box(nombreCaja);

  static const nombreCaja = 'favoritos';
  final Box _caja;

  List<RecetaResumen> todos() => _caja.values.map((m) => RecetaResumen.fromMap(m as Map)).toList();

  Future<void> guardar(RecetaResumen receta) => _caja.put(receta.id, receta.toMap());

  Future<void> quitar(String id) => _caja.delete(id);
}
