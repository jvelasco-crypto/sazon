import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:hive/hive.dart';
import 'package:sazon/controllers/auth_controller.dart';
import 'package:sazon/controllers/favoritos_controller.dart';
import 'package:sazon/controllers/recetas_controller.dart';
import 'package:sazon/models/estado_carga.dart';
import 'package:sazon/models/receta.dart';
import 'package:sazon/repositories/favoritos_repository.dart';
import 'package:sazon/repositories/recetas_repository.dart';
import 'package:sazon/screens/detalle_screen.dart';
import 'package:sazon/screens/recetas_screen.dart';
import 'package:sazon/services/api_client.dart';
import 'package:sazon/services/asistente_service.dart';
import 'package:sazon/services/recetas_api_service.dart';
import 'package:sazon/services/resenas_service.dart';
import 'package:sazon/utils/validadores.dart';

ResponseBody _json(Object cuerpo, int codigo) => ResponseBody.fromString(
  jsonEncode(cuerpo),
  codigo,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

/// TheMealDB falso: dos categorías, tres recetas de pollo, una búsqueda sin resultados y un detalle.
/// Con `caido = true` responde 503, como si el servicio no estuviera disponible.
class _MealDbFalso implements HttpClientAdapter {
  bool caido = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? cuerpo,
    Future<void>? cancelar,
  ) async {
    if (caido) return _json({'error': 'no disponible'}, 503);
    switch (o.path) {
      case '/categories.php':
        return _json({
          'categories': [
            {'strCategory': 'Chicken'},
            {'strCategory': 'Dessert'},
          ],
        }, 200);
      case '/filter.php':
        return _json({
          'meals': [
            {'idMeal': '1', 'strMeal': 'Chicken Curry', 'strMealThumb': ''},
            {'idMeal': '2', 'strMeal': 'Ayam Percik', 'strMealThumb': ''},
            {'idMeal': '3', 'strMeal': 'Chicken Mandi', 'strMealThumb': ''},
          ],
        }, 200);
      case '/search.php':
        return _json({'meals': null}, 200);
      case '/lookup.php':
        return _json({
          'meals': [
            {
              'idMeal': '2',
              'strMeal': 'Ayam Percik',
              'strCategory': 'Chicken',
              'strArea': 'Malaysian',
              'strInstructions': 'Asar.',
              'strIngredient1': 'Chicken',
              'strMeasure1': '6',
            },
          ],
        }, 200);
    }
    return _json({'error': 'ruta no prevista'}, 404);
  }

  @override
  void close({bool force = false}) {}
}

/// Backend falso: inicio de sesión y reseñas de otra persona y propias.
class _BackendFalso implements HttpClientAdapter {
  final creadas = <Map<String, dynamic>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? cuerpo,
    Future<void>? cancelar,
  ) async {
    switch ((o.method, o.path)) {
      case ('POST', '/usuarios/token'):
        return _json({'access_token': 'tok', 'token_type': 'bearer'}, 200);
      case ('GET', '/usuarios/me'):
        return _json({'id': 1, 'email': 'yo@sazon.com'}, 200);
      case ('GET', '/resenas/'):
        return _json([
          {
            'id': 9,
            'receta_id': '2',
            'receta_nombre': 'Ayam Percik',
            'calificacion': 5,
            'comentario': 'Deliciosa',
            'creada': '2026-10-16T10:00:00',
            'autor': 'ana@sazon.com',
            'es_mia': false,
          },
        ], 200);
      case ('GET', '/resenas/resumen'):
        return _json({'receta_id': '2', 'cantidad': 1, 'promedio': 5.0}, 200);
      case ('POST', '/resenas/'):
        creadas.add(Map<String, dynamic>.from(o.data as Map));
        return _json({
          ...o.data as Map,
          'id': 10,
          'creada': '2026-10-16T11:00:00',
          'autor': 'yo@sazon.com',
          'es_mia': true,
        }, 201);
    }
    return _json({'detail': 'ruta no prevista: ${o.method} ${o.path}'}, 404);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _MealDbFalso mealdb;
  late _BackendFalso backend;

  setUpAll(
    () => Hive.init(Directory.systemTemp.createTempSync('hive_sazon').path),
  );

  Future<void> montar({
    bool conSesion = false,
    bool servicioCaido = false,
  }) async {
    Get.reset();
    Get.testMode = true;
    await Hive.deleteFromDisk();
    await Hive.openBox(RecetasRepository.nombreCaja);
    await Hive.openBox(FavoritosRepository.nombreCaja);
    FlutterSecureStorage.setMockInitialValues({});
    mealdb = _MealDbFalso()..caido = servicioCaido;
    backend = _BackendFalso();
    final api = Get.put(
      ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend'))
          ..httpClientAdapter = backend,
      ),
    );
    Get.put(ResenasService(api));
    Get.put(
      RecetasRepository(
        RecetasApiService(
          dio: Dio(BaseOptions(baseUrl: 'http://mealdb'))
            ..httpClientAdapter = mealdb,
        ),
      ),
    );
    final auth = Get.put(AuthController());
    Get.put(FavoritosController(FavoritosRepository()));
    Get.put(RecetasController(Get.find()));
    // Espera a que termine la carga inicial: si no, seguiría escribiendo en Hive cuando la
    // prueba siguiente borra las cajas.
    final recetas = Get.find<RecetasController>();
    for (
      var i = 0;
      i < 300 && recetas.estado.value == EstadoCarga.cargando;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    if (conSesion) await auth.iniciarSesion('yo@sazon.com', 'clave-1234');
  }

  /// Alterna tiempo real (peticiones falsas y disco) con avance del reloj de la prueba.
  Future<void> esperarRed(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 40));
    }
  }

  testWidgets(
    'La lista muestra las recetas de la categoría (datos de la fuente, no escritos en la app)',
    (tester) async {
      await tester.runAsync(montar);
      await tester.pumpWidget(const GetMaterialApp(home: RecetasScreen()));
      await esperarRed(tester);
      expect(find.text('Chicken Curry'), findsOneWidget);
      expect(find.text('Ayam Percik'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Dessert'), findsOneWidget);
    },
  );

  testWidgets(
    'Sin servicio y sin caché se ve el error con su botón de reintentar',
    (tester) async {
      await tester.runAsync(() => montar(servicioCaido: true));
      await tester.pumpWidget(const GetMaterialApp(home: RecetasScreen()));
      await esperarRed(tester);
      expect(
        find.text('El servidor tuvo un problema. Inténtalo más tarde.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
    },
  );

  testWidgets(
    'Si el servicio cae después de una carga, se usa la caché y se avisa',
    (tester) async {
      await tester.runAsync(montar);
      await tester.pumpWidget(const GetMaterialApp(home: RecetasScreen()));
      await esperarRed(tester);
      mealdb.caido = true;
      await tester.runAsync(() => Get.find<RecetasController>().cargar());
      await esperarRed(tester);
      expect(
        find.textContaining('Sin conexión: recetas guardadas'),
        findsOneWidget,
      );
      expect(find.text('Chicken Mandi'), findsOneWidget);
    },
  );

  testWidgets('Una búsqueda sin resultados muestra el estado vacío', (
    tester,
  ) async {
    await tester.runAsync(montar);
    await tester.pumpWidget(const GetMaterialApp(home: RecetasScreen()));
    await esperarRed(tester);
    await tester.runAsync(() => Get.find<RecetasController>().buscar('zzz'));
    await esperarRed(tester);
    expect(find.textContaining('No hay recetas para «zzz»'), findsOneWidget);
  });

  test('Los favoritos se guardan en Hive y sobreviven a un controller nuevo (reinicio)', () async {
    await montar();
    const receta = RecetaResumen(id: '2', nombre: 'Ayam Percik', foto: '');
    await Get.find<FavoritosController>().alternar(receta);
    final otraVez = FavoritosController(FavoritosRepository())..onInit();
    expect(otraVez.esFavorita('2'), isTrue);
  });

  testWidgets(
    'Sin sesión, las reseñas piden iniciar sesión (funcionalidad protegida)',
    (tester) async {
      await tester.runAsync(montar);
      await tester.pumpWidget(
        const GetMaterialApp(
          home: DetalleScreen(
            receta: RecetaResumen(id: '2', nombre: 'Ayam Percik', foto: ''),
          ),
        ),
      );
      await esperarRed(tester);
      await tester.scrollUntilVisible(
        find.text('Inicia sesión para leer y escribir reseñas.'),
        300,
      );
      expect(
        find.text('Inicia sesión para leer y escribir reseñas.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Con sesión se ven las reseñas de otras personas y el botón para escribir la propia',
    (tester) async {
      await tester.runAsync(() => montar(conSesion: true));
      await tester.pumpWidget(
        const GetMaterialApp(
          home: DetalleScreen(
            receta: RecetaResumen(id: '2', nombre: 'Ayam Percik', foto: ''),
          ),
        ),
      );
      await esperarRed(tester);
      await tester.scrollUntilVisible(find.text('Deliciosa'), 300);
      expect(find.text('ana'), findsOneWidget);
      expect(find.text('Escribir una reseña'), findsOneWidget);
    },
  );

  test('Crear una reseña envía la receta, la calificación y el comentario al backend', () async {
    await montar(conSesion: true);
    await Get.find<ResenasService>().crear(
      recetaId: '2',
      recetaNombre: 'Ayam Percik',
      calificacion: 4,
      comentario: 'Rica',
    );
    expect(backend.creadas.single, {
      'receta_id': '2',
      'receta_nombre': 'Ayam Percik',
      'calificacion': 4,
      'comentario': 'Rica',
    });
  });

  test('Los errores HTTP tienen mensajes distintos (401, 400, 422 y 5xx)', () {
    ApiException de(int codigo, Object cuerpo, [String ruta = '/resenas/']) =>
        ApiException.desde(
          DioException(
            requestOptions: RequestOptions(path: ruta),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: ruta),
              statusCode: codigo,
              data: cuerpo,
            ),
          ),
        );
    expect(de(401, {}).mensaje, 'Tu sesión caducó, inicia sesión de nuevo.');
    expect(
      de(400, {
        'detail': 'Ya escribiste una reseña para esta receta; puedes editarla',
      }).mensaje,
      contains('Ya escribiste'),
    );
    expect(
      de(422, {
        'detail': [
          {
            'loc': ['body', 'calificacion'],
            'msg': 'debe ser menor o igual a 5',
          },
        ],
      }).mensaje,
      startsWith('Datos inválidos — calificacion'),
    );
    expect(
      de(503, {}).mensaje,
      'El servidor tuvo un problema. Inténtalo más tarde.',
    );
  });

  test(
    'El asistente no acepta una receta que no estaba entre las candidatas',
    () async {
      final proxy = Dio(BaseOptions(baseUrl: 'http://proxy'))
        ..httpClientAdapter = _ProxyFalso();
      final servicio = AsistenteService(ApiClient(dio: Dio()), dio: proxy);
      const candidatas = [
        RecetaResumen(id: '1', nombre: 'Chicken Curry', foto: ''),
      ];
      final r = await servicio.preguntar(
        '¿qué cocino?',
        favoritos: const [],
        candidatas: candidatas,
      );
      expect(r.respuesta, 'Prueba la 999');
      expect(r.recetaId, isNull);
    },
  );

  test(
    'El registro valida correo y contraseña antes de llamar al servidor',
    () {
      expect(Validadores.correo('no-es-correo'), isNotNull);
      expect(Validadores.correo('ana@sazon.com'), isNull);
      expect(Validadores.password('corta'), isNotNull);
      expect(Validadores.password('suficiente'), isNull);
    },
  );
}

/// Proxy falso que «inventa» una receta fuera de la lista.
class _ProxyFalso implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? cuerpo,
    Future<void>? cancelar,
  ) async => _json({'respuesta': 'Prueba la 999', 'receta_id': '999'}, 200);

  @override
  void close({bool force = false}) {}
}
