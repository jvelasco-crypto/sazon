import 'package:get/get.dart';

import '../models/estado_carga.dart';
import '../models/resena.dart';
import '../services/api_exception.dart';
import '../services/resenas_service.dart';

/// Las reseñas de la persona con sesión (pestaña Cuenta).
class MisResenasController extends GetxController {
  MisResenasController(this._servicio);

  final ResenasService _servicio;
  final RxList<Resena> resenas = <Resena>[].obs;
  final Rx<EstadoCarga> estado = EstadoCarga.cargando.obs;
  final RxString mensajeError = ''.obs;

  Future<void> cargar() async {
    estado.value = EstadoCarga.cargando;
    try {
      resenas.assignAll(await _servicio.mias());
      estado.value = resenas.isEmpty ? EstadoCarga.vacio : EstadoCarga.listo;
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
      estado.value = EstadoCarga.error;
    }
  }

  void limpiar() {
    resenas.clear();
    estado.value = EstadoCarga.cargando;
  }
}
