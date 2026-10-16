import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/recetas_controller.dart';
import '../models/estado_carga.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/receta_card.dart';

/// Lista principal: recetas reales de TheMealDB por categoría, con buscador.
class RecetasScreen extends StatefulWidget {
  const RecetasScreen({super.key});

  @override
  State<RecetasScreen> createState() => _RecetasScreenState();
}

class _RecetasScreenState extends State<RecetasScreen> {
  final _busqueda = TextEditingController();
  final RecetasController c = Get.find<RecetasController>();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _limpiarBusqueda() {
    _busqueda.clear();
    c.buscar('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sazón'),
        actions: [IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: c.cargar)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: TextField(
              controller: _busqueda,
              textInputAction: TextInputAction.search,
              onSubmitted: c.buscar,
              decoration: InputDecoration(
                hintText: 'Buscar recetas (en inglés, por ejemplo «pasta»)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => c.busqueda.value.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(tooltip: 'Limpiar búsqueda', icon: const Icon(Icons.close), onPressed: _limpiarBusqueda)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          Obx(() => c.busqueda.value.isNotEmpty || c.categorias.isEmpty ? const SizedBox(height: AppSpacing.sm) : _chips()),
          Obx(() => c.desdeCache.value
              ? MaterialBanner(
                  leading: const Icon(Icons.cloud_off),
                  content: Text('Sin conexión: recetas guardadas (última actualización: ${c.ultimaSincronizacion})'),
                  actions: [TextButton(onPressed: c.cargar, child: const Text('Reintentar'))],
                )
              : const SizedBox.shrink()),
          Expanded(child: Obx(_cuerpo)),
        ],
      ),
    );
  }

  Widget _chips() {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        children: [
          for (final cat in c.categorias)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(cat),
                selected: c.categoria.value == cat,
                onSelected: (_) => c.elegirCategoria(cat),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cuerpo() {
    switch (c.estado.value) {
      case EstadoCarga.cargando:
        return const LoadingView(mensaje: 'Cargando recetas...');
      case EstadoCarga.error:
        return ErrorView(mensaje: c.mensajeError.value, onReintentar: c.cargar);
      case EstadoCarga.vacio:
        return EmptyView(
          icono: Icons.search_off,
          mensaje: c.busqueda.value.isEmpty
              ? 'Esta categoría no tiene recetas.'
              : 'No hay recetas para «${c.busqueda.value}». Prueba con otra palabra en inglés.',
        );
      case EstadoCarga.listo:
        return RefreshIndicator(
          onRefresh: c.cargar,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: c.recetas.length,
            itemBuilder: (_, i) => RecetaCard(receta: c.recetas[i]),
          ),
        );
    }
  }
}
