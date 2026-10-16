import 'package:get/get.dart';

import '../models/receta.dart';
import '../repositories/favoritos_repository.dart';

/// Favoritos: Hive los guarda en disco y la `RxList` avisa a cada `Obx` (el corazón de
/// la lista, el del detalle y la pestaña Favoritos se actualizan a la vez).
class FavoritosController extends GetxController {
  FavoritosController(this._repo);

  final FavoritosRepository _repo;
  final RxList<RecetaResumen> favoritos = <RecetaResumen>[].obs;

  @override
  void onInit() {
    super.onInit();
    favoritos.assignAll(_repo.todos());
  }

  bool esFavorita(String id) => favoritos.any((f) => f.id == id);

  Future<void> alternar(RecetaResumen receta) async {
    if (esFavorita(receta.id)) {
      await _repo.quitar(receta.id);
      favoritos.removeWhere((f) => f.id == receta.id);
    } else {
      await _repo.guardar(receta);
      favoritos.add(receta);
    }
  }
}
