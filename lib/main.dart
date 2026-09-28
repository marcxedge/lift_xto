import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'database/database_helper.dart';
import 'repositories/body_weight_repository.dart';
import 'repositories/exercise_log_repository.dart';
import 'repositories/exercise_repository.dart';
import 'repositories/profile_repository.dart';
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
  final db = DatabaseHelper.instance;
  await db.database;
  runApp(LiftXtoApp(db: db));
}

class LiftXtoApp extends StatelessWidget {
  const LiftXtoApp({super.key, required this.db});

  final DatabaseHelper db;

  @override
  Widget build(BuildContext context) {
    // Los repositorios se crean una sola vez acá y se inyectan hacia abajo
    // con Provider. Cada uno es un ChangeNotifier: cuando una pantalla
    // escribe (agregar un log, guardar el perfil, etc.) notifica a sus
    // listeners y cualquier otra pantalla suscripta a ese repositorio se
    // refresca sola, incluso si vive en otra tab del IndexedStack.
    return MultiProvider(
      providers: [
        Provider<DatabaseHelper>.value(value: db),
        ChangeNotifierProvider(create: (_) => ExerciseRepository(db)),
        ChangeNotifierProvider(create: (_) => ExerciseLogRepository(db)),
        ChangeNotifierProvider(create: (_) => BodyWeightRepository(db)),
        ChangeNotifierProvider(create: (_) => ProfileRepository(db)),
      ],
      child: ValueListenableBuilder<ThemeMode>(
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
      ),
    );
  }
}
