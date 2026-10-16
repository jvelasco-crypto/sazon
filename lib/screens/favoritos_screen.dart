import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/favoritos_controller.dart';
import '../widgets/empty_view.dart';
import '../widgets/receta_card.dart';

/// Recetas favoritas, leídas de Hive: siguen aquí después de cerrar la app.
class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FavoritosController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritas')),
      body: Obx(() => c.favoritos.isEmpty
          ? const EmptyView(icono: Icons.favorite_border, mensaje: 'Aún no tienes favoritas.\nToca el corazón de una receta para guardarla aquí.')
          : ListView.builder(itemCount: c.favoritos.length, itemBuilder: (_, i) => RecetaCard(receta: c.favoritos[i]))),
    );
  }
}
