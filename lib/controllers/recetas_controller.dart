import 'package:get/get.dart';

import '../models/estado_carga.dart';
import '../models/receta.dart';
import '../repositories/recetas_repository.dart';
import '../services/api_exception.dart';

/// Estado de la lista principal: categorías, la categoría elegida y sus recetas, o los
/// resultados de una búsqueda. Lo comparten la pantalla de recetas y el asistente (que
/// usa las recetas visibles como «candidatas»).
class RecetasController extends GetxController {
  RecetasController(this._repo);

  final RecetasRepository _repo;

  final RxList<String> categorias = <String>[].obs;
  final RxString categoria = 'Chicken'.obs;
  final RxList<RecetaResumen> recetas = <RecetaResumen>[].obs;
  final Rx<EstadoCarga> estado = EstadoCarga.cargando.obs;
  final RxString mensajeError = ''.obs;
  final RxBool desdeCache = false.obs;

  /// Texto buscado; vacío = se muestra la categoría elegida.
  final RxString busqueda = ''.obs;

  String get ultimaSincronizacion => _repo.ultimaSincronizacion(categoria.value);

  @override
  void onInit() {
    super.onInit();
    iniciar();
  }

  Future<void> iniciar() async {
    try {
      final (lista, _) = await _repo.categorias();
      categorias.assignAll(lista);
      if (lista.isNotEmpty && !lista.contains(categoria.value)) categoria.value = lista.first;
    } on ApiException {
      // Sin categorías la app sigue: la lista de abajo mostrará el error con su botón de reintentar.
    }
    await cargar();
  }

  Future<void> elegirCategoria(String nueva) async {
    categoria.value = nueva;
    busqueda.value = '';
    await cargar();
  }

  Future<void> buscar(String texto) async {
    busqueda.value = texto.trim();
    await cargar();
  }

  /// Carga la búsqueda o la categoría, pasando por cargando → listo / vacío / error.
  Future<void> cargar() async {
    estado.value = EstadoCarga.cargando;
    mensajeError.value = '';
    try {
      if (busqueda.value.isNotEmpty) {
        recetas.assignAll(await _repo.buscar(busqueda.value));
        desdeCache.value = false;
      } else {
        final (lista, cache) = await _repo.deCategoria(categoria.value);
        recetas.assignAll(lista);
        desdeCache.value = cache;
      }
      estado.value = recetas.isEmpty ? EstadoCarga.vacio : EstadoCarga.listo;
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
      estado.value = EstadoCarga.error;
    }
  }
}
