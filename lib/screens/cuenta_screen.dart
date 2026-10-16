import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/mis_resenas_controller.dart';
import '../models/estado_carga.dart';
import '../models/receta.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/estrellas.dart';
import '../widgets/loading_view.dart';
import '../widgets/sin_sesion_view.dart';
import 'detalle_screen.dart';

/// Cuenta: quién inició sesión, sus reseñas y el botón para cerrar sesión.
class CuentaScreen extends StatelessWidget {
  const CuentaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final mis = Get.find<MisResenasController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi cuenta'),
        actions: [
          Obx(
            () => auth.estaAutenticado
                ? IconButton(tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout), onPressed: auth.cerrarSesion)
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (!auth.estaAutenticado) return const SinSesionView(mensaje: 'Inicia sesión o crea una cuenta para escribir reseñas y usar el asistente.');
        return RefreshIndicator(
          onRefresh: mis.cargar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(auth.usuario.value!.email),
                subtitle: const Text('Sesión iniciada'),
              ),
              const Divider(),
              Text('Mis reseñas', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              switch (mis.estado.value) {
                EstadoCarga.cargando => const SizedBox(height: 160, child: LoadingView(mensaje: 'Cargando tus reseñas...')),
                EstadoCarga.error => SizedBox(
                  height: 240,
                  child: ErrorView(mensaje: mis.mensajeError.value, onReintentar: mis.cargar),
                ),
                EstadoCarga.vacio => const SizedBox(
                  height: 200,
                  child: EmptyView(icono: Icons.rate_review_outlined, mensaje: 'Todavía no escribiste reseñas.'),
                ),
                EstadoCarga.listo => Column(
                  children: [
                    for (final r in mis.resenas)
                      Card(
                        child: ListTile(
                          title: Text(r.recetaNombre),
                          subtitle: Text(r.comentario, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Estrellas(valor: r.calificacion, tamano: 14),
                          onTap: () async {
                            await Get.to(
                              () => DetalleScreen(
                                receta: RecetaResumen(id: r.recetaId, nombre: r.recetaNombre, foto: ''),
                              ),
                            );
                            mis.cargar();
                          },
                        ),
                      ),
                  ],
                ),
              },
            ],
          ),
        );
      }),
    );
  }
}
