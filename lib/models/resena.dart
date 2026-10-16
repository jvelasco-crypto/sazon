/// Reseña de una receta, tal como la devuelve el backend (`/resenas`).
class Resena {
  final int id;
  final String recetaId;
  final String recetaNombre;
  final int calificacion;
  final String comentario;
  final DateTime? creada;
  final String autor;
  final bool esMia;

  const Resena({
    required this.id,
    required this.recetaId,
    required this.recetaNombre,
    required this.calificacion,
    required this.comentario,
    required this.creada,
    required this.autor,
    required this.esMia,
  });

  factory Resena.fromJson(Map<String, dynamic> json) => Resena(
        id: (json['id'] as num).toInt(),
        recetaId: '${json['receta_id']}',
        recetaNombre: (json['receta_nombre'] as String?) ?? '',
        calificacion: (json['calificacion'] as num?)?.toInt() ?? 0,
        comentario: (json['comentario'] as String?) ?? '',
        creada: DateTime.tryParse('${json['creada']}'),
        autor: (json['autor'] as String?) ?? 'Anónimo',
        esMia: json['es_mia'] == true,
      );

  /// Muestra solo la parte antes de la @: el correo completo no hace falta para leer una reseña.
  String get autorVisible => autor.split('@').first;
}

/// Promedio y cantidad de reseñas de una receta (`GET /resenas/resumen`).
class ResumenResenas {
  final int cantidad;
  final double? promedio;
  const ResumenResenas({required this.cantidad, required this.promedio});

  factory ResumenResenas.fromJson(Map<String, dynamic> json) => ResumenResenas(
        cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
        promedio: (json['promedio'] as num?)?.toDouble(),
      );
}
