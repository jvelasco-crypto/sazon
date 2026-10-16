import 'package:get/get.dart';

import '../models/estado_carga.dart';
import '../models/receta.dart';
import '../repositories/recetas_repository.dart';
import '../services/api_exception.dart';

/// Detalle de una receta (uno por receta abierta: se registra con `tag: id`).
class DetalleController extends GetxController {
  DetalleController(this._repo, this.recetaId);

  final RecetasRepository _repo;
  final String recetaId;

  final Rxn<RecetaDetalle> receta = Rxn<RecetaDetalle>();
  final Rx<EstadoCarga> estado = EstadoCarga.cargando.obs;
  final RxString mensajeError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    cargar();
  }

  Future<void> cargar() async {
    estado.value = EstadoCarga.cargando;
    try {
      receta.value = await _repo.detalle(recetaId);
      estado.value = receta.value == null ? EstadoCarga.vacio : EstadoCarga.listo;
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
      estado.value = EstadoCarga.error;
    }
  }
}
