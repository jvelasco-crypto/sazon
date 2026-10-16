/// Receta en una lista (lo que devuelven `filter.php` y `search.php` de TheMealDB).
class RecetaResumen {
  final String id;
  final String nombre;
  final String foto;
  const RecetaResumen({required this.id, required this.nombre, required this.foto});

  /// Lectura defensiva: un campo faltante no rompe la lista.
  factory RecetaResumen.fromJson(Map<String, dynamic> json) =>
      RecetaResumen(id: '${json['idMeal'] ?? ''}', nombre: (json['strMeal'] as String?) ?? 'Receta sin nombre', foto: (json['strMealThumb'] as String?) ?? '');

  Map<String, dynamic> toMap() => {'id': id, 'nombre': nombre, 'foto': foto};

  factory RecetaResumen.fromMap(Map map) => RecetaResumen(id: '${map['id']}', nombre: '${map['nombre']}', foto: '${map['foto'] ?? ''}');
}

/// Receta completa (`lookup.php`): ingredientes con su medida y los pasos.
class RecetaDetalle {
  final String id;
  final String nombre;
  final String foto;
  final String categoria;
  final String origen;
  final String instrucciones;
  final List<(String, String)> ingredientes;

  const RecetaDetalle({
    required this.id,
    required this.nombre,
    required this.foto,
    required this.categoria,
    required this.origen,
    required this.instrucciones,
    required this.ingredientes,
  });

  RecetaResumen get resumen => RecetaResumen(id: id, nombre: nombre, foto: foto);

  /// TheMealDB guarda los ingredientes en 20 pares de campos `strIngredientN` / `strMeasureN`.
  factory RecetaDetalle.fromJson(Map<String, dynamic> json) {
    final ingredientes = <(String, String)>[];
    for (var i = 1; i <= 20; i++) {
      final ing = (json['strIngredient$i'] as String?)?.trim() ?? '';
      if (ing.isEmpty) continue;
      ingredientes.add((ing, (json['strMeasure$i'] as String?)?.trim() ?? ''));
    }
    return RecetaDetalle(
      id: '${json['idMeal'] ?? ''}',
      nombre: (json['strMeal'] as String?) ?? 'Receta sin nombre',
      foto: (json['strMealThumb'] as String?) ?? '',
      categoria: (json['strCategory'] as String?) ?? '',
      origen: (json['strArea'] as String?) ?? '',
      instrucciones: ((json['strInstructions'] as String?) ?? '').replaceAll('\r', ''),
      ingredientes: ingredientes,
    );
  }
}
