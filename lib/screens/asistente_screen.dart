import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/asistente_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/recetas_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/sin_sesion_view.dart';
import 'detalle_screen.dart';

/// Asistente de cocina. Habla con el proxy propio (que guarda la clave del modelo) y solo
/// puede sugerir recetas de la lista que la persona está viendo.
class AsistenteScreen extends StatefulWidget {
  const AsistenteScreen({super.key});

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  final _campo = TextEditingController();
  final AsistenteController c = Get.find<AsistenteController>();
  final AuthController auth = Get.find<AuthController>();
  final RecetasController recetas = Get.find<RecetasController>();

  static const _sugerencias = ['¿Qué cocino con chicken?', 'Recomiéndame algo para hoy', '¿Cuáles son mis favoritas?'];

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _preguntar([String? texto]) {
    if (texto != null) _campo.text = texto;
    FocusScope.of(context).unfocus();
    c.preguntar(_campo.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente de cocina')),
      body: Obx(() {
        if (!auth.estaAutenticado) return const SinSesionView(mensaje: 'Inicia sesión para usar el asistente.');
        final colores = Theme.of(context).colorScheme;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: colores.secondaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Sugerencia de IA: revisa la receta antes de cocinar. Busca entre las recetas de «${recetas.busqueda.value.isEmpty ? recetas.categoria.value : recetas.busqueda.value}».')),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _campo,
              maxLines: 2,
              maxLength: 500,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _preguntar(),
              decoration: const InputDecoration(labelText: 'Pregunta sobre recetas', border: OutlineInputBorder()),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final s in _sugerencias)
                  ActionChip(label: Text(s), onPressed: c.cargando.value ? null : () => _preguntar(s)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: c.cargando.value ? null : _preguntar,
              icon: c.cargando.value
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: const Text('Preguntar'),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (c.mensajeError.value.isNotEmpty)
              Text(c.mensajeError.value, style: TextStyle(color: colores.error))
            else if (c.respuesta.value.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.respuesta.value),
                      if (c.sugerida.value != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: () => Get.to(() => DetalleScreen(receta: c.sugerida.value!)),
                          icon: const Icon(Icons.restaurant_menu),
                          label: Text('Ver «${c.sugerida.value!.nombre}»'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else if (!c.cargando.value)
              Text('Escribe una pregunta o toca una sugerencia.', style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }),
    );
  }
}
