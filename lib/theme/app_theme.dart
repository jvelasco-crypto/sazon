import 'package:flutter/material.dart';

/// Tema visual de Sazón: un solo lugar para colores, tipografía y espaciado.
/// Paleta de cocina: terracota (primario), oliva (acento) y fondo crema.
class AppTheme {
  AppTheme._();

  static const Color terracota = Color(0xFFB8492A);
  static const Color oliva = Color(0xFF5E7330);
  static const Color cafe = Color(0xFF3B2A20);
  static const Color crema = Color(0xFFFBF6EE);

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(seedColor: terracota, primary: terracota, secondary: oliva, surface: Colors.white);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: crema,
      appBarTheme: const AppBarTheme(backgroundColor: cafe, foregroundColor: Colors.white, elevation: 0),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cafe),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cafe),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF2A2A2A)),
        bodySmall: TextStyle(fontSize: 12),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: terracota, foregroundColor: Colors.white, minimumSize: const Size(48, 48)),
      ),
      navigationBarTheme: NavigationBarThemeData(indicatorColor: terracota.withValues(alpha: 0.18)),
    );
  }
}

/// Tema oscuro (extensión opcional): misma semilla terracota con `Brightness.dark`.
/// No fija colores de texto ni de fondo: Flutter genera la paleta oscura completa.
extension AppThemeOscuro on AppTheme {
  static ThemeData get oscuro {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppTheme.terracota, secondary: AppTheme.oliva, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(backgroundColor: AppTheme.cafe, foregroundColor: Colors.white, elevation: 0),
      cardTheme: CardThemeData(elevation: 1, clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    );
  }
}

/// Espaciados de toda la app, en vez de números sueltos en cada widget.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}
