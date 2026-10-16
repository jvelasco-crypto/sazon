import 'package:flutter/material.dart';

/// Calificación de 1 a 5. Con `alCambiar` se puede tocar para elegir; sin él, solo muestra.
class Estrellas extends StatelessWidget {
  final int valor;
  final double tamano;
  final ValueChanged<int>? alCambiar;
  const Estrellas({super.key, required this.valor, this.tamano = 18, this.alCambiar});

  @override
  Widget build(BuildContext context) {
    final color = Colors.amber.shade700;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          alCambiar == null
              ? Icon(i <= valor ? Icons.star : Icons.star_border, size: tamano, color: color)
              : IconButton(
                  tooltip: '$i de 5',
                  onPressed: () => alCambiar!(i),
                  icon: Icon(i <= valor ? Icons.star : Icons.star_border, size: tamano, color: color),
                ),
      ],
    );
  }
}
