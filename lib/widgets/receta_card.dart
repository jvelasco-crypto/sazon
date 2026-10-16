import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/favoritos_controller.dart';
import '../models/receta.dart';
import '../screens/detalle_screen.dart';
import '../theme/app_theme.dart';
import 'imagen_receta.dart';

/// Fila de una receta: foto, nombre y corazón de favorito. Al tocarla se abre el detalle.
class RecetaCard extends StatelessWidget {
  final RecetaResumen receta;
  const RecetaCard({super.key, required this.receta});

  @override
  Widget build(BuildContext context) {
    final favoritos = Get.find<FavoritosController>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: InkWell(
        onTap: () => Get.to(() => DetalleScreen(receta: receta)),
        child: Row(
          children: [
            ImagenReceta(receta.foto, alto: 84, ancho: 84),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(receta.nombre, style: Theme.of(context).textTheme.titleMedium)),
            Obx(() {
              final es = favoritos.esFavorita(receta.id);
              return IconButton(
                tooltip: es ? 'Quitar de favoritas' : 'Agregar a favoritas',
                icon: Icon(es ? Icons.favorite : Icons.favorite_border, color: AppTheme.terracota),
                onPressed: () => favoritos.alternar(receta),
              );
            }),
          ],
        ),
      ),
    );
  }
}
