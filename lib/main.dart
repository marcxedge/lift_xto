import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'database/database_helper.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';
import 'utils/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  await initializeDateFormatting('es', null);
  // Cargamos la preferencia de tema antes de levantar la UI para evitar un
  // flash entre claro/oscuro al iniciar.
  await ThemeController.instance.load();
  // Disparamos la creación de la BD al iniciar para que la rutina por defecto
  // ya esté lista cuando se renderice la primera pantalla.
  await DatabaseHelper.instance.database;
  runApp(const LiftXtoApp());
}

class LiftXtoApp extends StatelessWidget {
  const LiftXtoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Lift.xto',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
