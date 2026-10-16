import 'package:flutter/material.dart';

/// Foto de una receta con su propio estado de carga y de error: nunca deja un hueco en blanco.
class ImagenReceta extends StatelessWidget {
  final String url;
  final double? alto;
  final double? ancho;
  const ImagenReceta(this.url, {super.key, this.alto, this.ancho});

  @override
  Widget build(BuildContext context) {
    final fondo = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget marco(Widget hijo) => Container(height: alto, width: ancho, color: fondo, alignment: Alignment.center, child: hijo);
    if (url.isEmpty) return marco(const Icon(Icons.restaurant, size: 32));
    return Image.network(
      url,
      height: alto,
      width: ancho,
      fit: BoxFit.cover,
      loadingBuilder: (context, hijo, progreso) =>
          progreso == null ? hijo : marco(const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      errorBuilder: (context, error, pila) => marco(const Icon(Icons.broken_image_outlined, size: 32)),
    );
  }
}
