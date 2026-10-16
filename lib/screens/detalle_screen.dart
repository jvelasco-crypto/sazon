import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/detalle_controller.dart';
import '../controllers/favoritos_controller.dart';
import '../controllers/resenas_controller.dart';
import '../models/estado_carga.dart';
import '../models/receta.dart';
import '../models/resena.dart';
import '../repositories/recetas_repository.dart';
import '../services/resenas_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/estrellas.dart';
import '../widgets/imagen_receta.dart';
import '../widgets/loading_view.dart';
import '../widgets/sin_sesion_view.dart';
import 'resena_form_screen.dart';

/// Registra un controller con `tag` solo si todavía no existe (la pantalla puede reconstruirse).
T _registrar<T>(T Function() crear, String tag) => Get.isRegistered<T>(tag: tag) ? Get.find<T>(tag: tag) : Get.put<T>(crear(), tag: tag);

/// Detalle de una receta: foto, ingredientes, pasos, favorito y reseñas de la comunidad.
class DetalleScreen extends StatefulWidget {
  final RecetaResumen receta;
  const DetalleScreen({super.key, required this.receta});

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  RecetaResumen get receta => widget.receta;

  @override
  void dispose() {
    // Los controllers de esta receta viven mientras su pantalla está abierta.
    Get.delete<DetalleController>(tag: receta.id);
    Get.delete<ResenasController>(tag: 'resenas_${receta.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _registrar(() => DetalleController(Get.find<RecetasRepository>(), receta.id), receta.id);
    final favoritos = Get.find<FavoritosController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(receta.nombre, overflow: TextOverflow.ellipsis),
        actions: [
          Obx(() {
            final es = favoritos.esFavorita(receta.id);
            return IconButton(
              tooltip: es ? 'Quitar de favoritas' : 'Agregar a favoritas',
              icon: Icon(es ? Icons.favorite : Icons.favorite_border),
              onPressed: () => favoritos.alternar(receta),
            );
          }),
        ],
      ),
      body: Obx(() {
        switch (c.estado.value) {
          case EstadoCarga.cargando:
            return const LoadingView(mensaje: 'Cargando receta...');
          case EstadoCarga.error:
            return ErrorView(mensaje: c.mensajeError.value, onReintentar: c.cargar);
          case EstadoCarga.vacio:
            return const EmptyView(mensaje: 'Esta receta ya no está disponible.');
          case EstadoCarga.listo:
            return _Contenido(receta: c.receta.value!);
        }
      }),
    );
  }
}

class _Contenido extends StatelessWidget {
  final RecetaDetalle receta;
  const _Contenido({required this.receta});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return ListView(
      children: [
        ImagenReceta(receta.foto, alto: 230, ancho: double.infinity),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(receta.nombre, style: tema.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  if (receta.categoria.isNotEmpty) Chip(avatar: const Icon(Icons.category, size: 16), label: Text(receta.categoria)),
                  if (receta.origen.isNotEmpty) Chip(avatar: const Icon(Icons.public, size: 16), label: Text(receta.origen)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Ingredientes', style: tema.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final (ing, medida) in receta.ingredientes)
                Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('•  $ing${medida.isEmpty ? '' : ' — $medida'}')),
              const SizedBox(height: AppSpacing.lg),
              Text('Preparación', style: tema.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(receta.instrucciones.isEmpty ? 'La fuente no trae instrucciones para esta receta.' : receta.instrucciones),
              const Divider(height: AppSpacing.xl * 2),
              _SeccionResenas(receta: receta),
            ],
          ),
        ),
      ],
    );
  }
}

/// Reseñas de la receta. Es una funcionalidad protegida: sin sesión se pide iniciarla.
class _SeccionResenas extends StatelessWidget {
  final RecetaDetalle receta;
  const _SeccionResenas({required this.receta});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      if (!auth.estaAutenticado) {
        return const SizedBox(height: 260, child: SinSesionView(mensaje: 'Inicia sesión para leer y escribir reseñas.'));
      }
      final c = _registrar(() => ResenasController(Get.find<ResenasService>(), receta.id, receta.nombre), 'resenas_${receta.id}');
      return _ListaResenas(c: c);
    });
  }
}

class _ListaResenas extends StatelessWidget {
  final ResenasController c;
  const _ListaResenas({required this.c});

  Future<void> _borrar(BuildContext context, Resena r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('¿Eliminar tu reseña?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    final error = await c.eliminar(r);
    if (error != null) Get.snackbar('No se pudo eliminar', error);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Obx(() {
      final resumen = c.resumen.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Reseñas', style: tema.titleMedium)),
              if (resumen?.promedio != null) ...[
                Estrellas(valor: resumen!.promedio!.round()),
                const SizedBox(width: AppSpacing.xs),
                Text('${resumen.promedio} (${resumen.cantidad})'),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () => Get.to(() => ResenaFormScreen(controller: c)),
            icon: Icon(c.mia == null ? Icons.rate_review : Icons.edit),
            label: Text(c.mia == null ? 'Escribir una reseña' : 'Editar mi reseña'),
          ),
          const SizedBox(height: AppSpacing.md),
          switch (c.estado.value) {
            EstadoCarga.cargando => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: LoadingView(mensaje: 'Cargando reseñas...'),
            ),
            EstadoCarga.error => SizedBox(
              height: 220,
              child: ErrorView(mensaje: c.mensajeError.value, onReintentar: c.cargar),
            ),
            EstadoCarga.vacio => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text('Todavía nadie la reseñó. ¡Sé la primera persona!'),
            ),
            EstadoCarga.listo => Column(
              children: [
                for (final r in c.resenas)
                  Card(
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(r.esMia ? 'Tú' : r.autorVisible, style: tema.titleMedium)),
                          Estrellas(valor: r.calificacion, tamano: 16),
                        ],
                      ),
                      subtitle: Text(r.comentario),
                      trailing: r.esMia
                          ? IconButton(tooltip: 'Eliminar mi reseña', icon: const Icon(Icons.delete_outline), onPressed: () => _borrar(context, r))
                          : null,
                    ),
                  ),
              ],
            ),
          },
        ],
      );
    });
  }
}
