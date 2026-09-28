import 'package:firebase_core/firebase_core.dart';
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
import 'sync/auth_repository.dart';
import 'sync/sync_service.dart';
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

  // La sincronización con Firebase es opcional: si `google-services.json`
  // no está configurado con un proyecto real (por ejemplo, en un clon
  // fresco del repo con el placeholder de ejemplo), Firebase.initializeApp
  // falla acá y la app sigue funcionando 100% local — sólo se deshabilita
  // el botón de cuenta/sincronización. Ver README → Sincronización.
  var firebaseAvailable = true;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    firebaseAvailable = false;
    debugPrint(
      'Firebase no disponible (¿falta configurar google-services.json?): $e',
    );
  }

  final authRepository = AuthRepository(firebaseAvailable: firebaseAvailable);
  final syncService = SyncService(db: db, auth: authRepository);
  // Secuencial y ya con `db.database` abierta arriba: no compite con las
  // lecturas iniciales que van a disparar las pantallas al montar.
  await syncService.refreshPendingCount();

  runApp(
    LiftXtoApp(
      db: db,
      authRepository: authRepository,
      syncService: syncService,
    ),
  );
}

class LiftXtoApp extends StatelessWidget {
  const LiftXtoApp({
    super.key,
    required this.db,
    required this.authRepository,
    required this.syncService,
  });

  final DatabaseHelper db;
  final AuthRepository authRepository;
  final SyncService syncService;

  @override
  Widget build(BuildContext context) {
    // Los repositorios se crean una sola vez acá y se inyectan hacia abajo
    // con Provider. Cada uno es un ChangeNotifier: cuando una pantalla
    // escribe (agregar un log, guardar el perfil, etc.) notifica a sus
    // listeners y cualquier otra pantalla suscripta a ese repositorio se
    // refresca sola, incluso si vive en otra tab del IndexedStack. Además,
    // cada escritura le avisa a `syncService` (vía el parámetro opcional
    // de cada repositorio) para que intente empujarla a Firestore si hay
    // sesión y conexión.
    return MultiProvider(
      providers: [
        Provider<DatabaseHelper>.value(value: db),
        ChangeNotifierProvider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider<SyncService>.value(value: syncService),
        ChangeNotifierProvider(
          create: (_) => ExerciseRepository(db, syncService),
        ),
        ChangeNotifierProvider(
          create: (_) => ExerciseLogRepository(db, syncService),
        ),
        ChangeNotifierProvider(
          create: (_) => BodyWeightRepository(db, syncService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileRepository(db, syncService),
        ),
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
