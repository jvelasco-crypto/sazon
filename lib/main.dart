import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'controllers/asistente_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/favoritos_controller.dart';
import 'controllers/mis_resenas_controller.dart';
import 'controllers/recetas_controller.dart';
import 'repositories/favoritos_repository.dart';
import 'repositories/recetas_repository.dart';
import 'screens/asistente_screen.dart';
import 'screens/cuenta_screen.dart';
import 'screens/favoritos_screen.dart';
import 'screens/recetas_screen.dart';
import 'services/api_client.dart';
import 'services/asistente_service.dart';
import 'services/recetas_api_service.dart';
import 'services/resenas_service.dart';
import 'theme/app_theme.dart';
import 'utils/reporte_errores.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ReporteErrores.instalar();
  await Hive.initFlutter();
  await Hive.openBox(FavoritosRepository.nombreCaja);
  await Hive.openBox(RecetasRepository.nombreCaja);
  registrarDependencias();
  runApp(const SazonApp());
}

/// Todas las dependencias en un solo lugar: servicios → repositorios → controllers.
/// Las pruebas registran sus propias versiones (con servidores falsos) en vez de llamar a esto.
void registrarDependencias() {
  final api = Get.put(ApiClient(), permanent: true);
  Get.put(ResenasService(api), permanent: true);
  Get.put(RecetasRepository(RecetasApiService()), permanent: true);
  Get.put(AsistenteService(api), permanent: true);
  final auth = Get.put(AuthController(), permanent: true);
  Get.put(FavoritosController(FavoritosRepository()), permanent: true);
  Get.put(RecetasController(Get.find()), permanent: true);
  final mis = Get.put(MisResenasController(Get.find()), permanent: true);
  final asistente = Get.put(AsistenteController(Get.find()), permanent: true);
  auth.alCerrarSesion
    ..add(mis.limpiar)
    ..add(asistente.limpiar);
  // Al iniciar sesión (o restaurarla al abrir la app) se cargan las reseñas propias.
  ever(auth.usuario, (usuario) {
    if (usuario != null) mis.cargar();
  });
}

class SazonApp extends StatelessWidget {
  const SazonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Sazón',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: const Locale('es', 'EC'),
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: const [Locale('es', 'EC'), Locale('en', 'US')],
      home: const RaizScreen(),
    );
  }
}

/// Navegación inferior. El índice de la pestaña es estado local de esta pantalla
/// (no se comparte), por eso vive aquí y no en un controller.
class RaizScreen extends StatefulWidget {
  const RaizScreen({super.key});

  @override
  State<RaizScreen> createState() => _RaizScreenState();
}

class _RaizScreenState extends State<RaizScreen> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indice, children: const [RecetasScreen(), FavoritosScreen(), AsistenteScreen(), CuentaScreen()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Recetas'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favoritas'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Asistente'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Cuenta'),
        ],
      ),
    );
  }
}
