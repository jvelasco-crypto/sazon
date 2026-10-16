import 'package:get/get.dart';

import '../models/receta.dart';
import '../services/api_exception.dart';
import '../services/asistente_service.dart';
import 'favoritos_controller.dart';
import 'recetas_controller.dart';

/// Conversación con el asistente: una pregunta a la vez, su respuesta y, si la IA
/// sugiere una receta, cuál es (siempre una de las que la persona está viendo).
class AsistenteController extends GetxController {
  AsistenteController(this._servicio);

  final AsistenteService _servicio;

  final RxBool cargando = false.obs;
  final RxString respuesta = ''.obs;
  final RxString mensajeError = ''.obs;
  final Rxn<RecetaResumen> sugerida = Rxn<RecetaResumen>();

  Future<void> preguntar(String consulta) async {
    final texto = consulta.trim();
    if (texto.isEmpty || cargando.value) return;
    cargando.value = true;
    mensajeError.value = '';
    respuesta.value = '';
    sugerida.value = null;
    try {
      final candidatas = Get.find<RecetasController>().recetas.toList();
      final favoritos = Get.find<FavoritosController>().favoritos.map((f) => f.nombre).toList();
      final r = await _servicio.preguntar(texto, favoritos: favoritos, candidatas: candidatas);
      respuesta.value = r.respuesta;
      sugerida.value = r.recetaId == null ? null : candidatas.firstWhereOrNull((c) => c.id == r.recetaId);
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
    } finally {
      cargando.value = false;
    }
  }

  void limpiar() {
    respuesta.value = '';
    mensajeError.value = '';
    sugerida.value = null;
  }
}
