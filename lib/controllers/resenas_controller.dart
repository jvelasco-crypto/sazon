import 'package:get/get.dart';

import '../models/estado_carga.dart';
import '../models/resena.dart';
import '../services/api_exception.dart';
import '../services/resenas_service.dart';

/// Reseñas de UNA receta (se registra con `tag: recetaId`): las de todos los usuarios,
/// el promedio y las acciones sobre la propia (crear, editar, borrar).
class ResenasController extends GetxController {
  ResenasController(this._servicio, this.recetaId, this.recetaNombre);

  final ResenasService _servicio;
  final String recetaId;
  final String recetaNombre;

  final RxList<Resena> resenas = <Resena>[].obs;
  final Rxn<ResumenResenas> resumen = Rxn<ResumenResenas>();
  final Rx<EstadoCarga> estado = EstadoCarga.cargando.obs;
  final RxString mensajeError = ''.obs;
  final RxBool guardando = false.obs;

  Resena? get mia => resenas.firstWhereOrNull((r) => r.esMia);

  @override
  void onInit() {
    super.onInit();
    cargar();
  }

  Future<void> cargar() async {
    estado.value = EstadoCarga.cargando;
    mensajeError.value = '';
    try {
      final lista = await _servicio.deReceta(recetaId);
      resenas.assignAll(lista);
      resumen.value = await _servicio.resumen(recetaId);
      estado.value = lista.isEmpty ? EstadoCarga.vacio : EstadoCarga.listo;
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
      estado.value = EstadoCarga.error;
    }
  }

  /// Crea o edita la reseña propia. Devuelve el error del servidor, o null si salió bien.
  /// Después se vuelve a leer la lista: lo que se ve es lo que dice el servidor.
  Future<String?> guardar({required int calificacion, required String comentario}) async {
    guardando.value = true;
    try {
      final actual = mia;
      if (actual == null) {
        await _servicio.crear(recetaId: recetaId, recetaNombre: recetaNombre, calificacion: calificacion, comentario: comentario);
      } else {
        await _servicio.editar(actual.id, calificacion: calificacion, comentario: comentario);
      }
      await cargar();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } finally {
      guardando.value = false;
    }
  }

  Future<String?> eliminar(Resena resena) async {
    try {
      await _servicio.eliminar(resena.id);
      await cargar();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }
}
