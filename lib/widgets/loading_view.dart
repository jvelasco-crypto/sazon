import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estado de carga reutilizable: toda pantalla que espera datos muestra este mismo widget.
class LoadingView extends StatelessWidget {
  final String mensaje;
  const LoadingView({super.key, this.mensaje = 'Cargando...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(mensaje, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
