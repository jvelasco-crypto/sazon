import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/resenas_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/estrellas.dart';

/// Crear o editar la reseña propia. Si el servidor rechaza los datos, el formulario
/// queda abierto con lo escrito y muestra su mensaje.
class ResenaFormScreen extends StatefulWidget {
  final ResenasController controller;
  const ResenaFormScreen({super.key, required this.controller});

  @override
  State<ResenaFormScreen> createState() => _ResenaFormScreenState();
}

class _ResenaFormScreenState extends State<ResenaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _comentario;
  late int _calificacion;
  String? _error;

  ResenasController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    final mia = c.mia;
    _comentario = TextEditingController(text: mia?.comentario ?? '');
    _calificacion = mia?.calificacion ?? 0;
  }

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_calificacion == 0) {
      setState(() => _error = 'Elige de 1 a 5 estrellas.');
      return;
    }
    final error = await c.guardar(calificacion: _calificacion, comentario: _comentario.text.trim());
    if (!mounted) return;
    if (error == null) {
      Get.back();
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(c.mia == null ? 'Nueva reseña' : 'Editar reseña')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(c.recetaNombre, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            const Text('Tu calificación'),
            Estrellas(valor: _calificacion, tamano: 32, alCambiar: (v) => setState(() => _calificacion = v)),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _comentario,
              maxLength: 500,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Comentario', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un comentario' : null,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Obx(() => FilledButton(
                  onPressed: c.guardando.value ? null : _guardar,
                  child: c.guardando.value
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Guardar'),
                )),
          ],
        ),
      ),
    );
  }
}
