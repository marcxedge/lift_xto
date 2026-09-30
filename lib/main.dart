import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'database/database_helper.dart';
import 'models/user_profile.dart';
import 'repositories/body_weight_repository.dart';
import 'repositories/exercise_catalog_repository.dart';
import 'repositories/exercise_log_repository.dart';
import 'repositories/exercise_repository.dart';
import 'repositories/profile_repository.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'sync/auth_repository.dart';
import 'sync/sync_service.dart';
import 'utils/theme.dart';
import 'utils/theme_controller.dart';
import 'widgets/state_views.dart';

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

  // El login con Google es obligatorio (ver LoginScreen/AuthGate), así que
  // Firebase ya no es "opcional" en el sentido de que la app funcione sin
  // él — pero igual envolvemos la inicialización en try/catch: si
  // `google-services.json` es el placeholder de ejemplo (clon fresco del
  // repo sin configurar), la app no crashea, sino que LoginScreen muestra
  // un mensaje claro en vez de un botón de login roto. Ver README →
  // Sincronización.
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
        Provider(create: (_) => ExerciseCatalogRepository()),
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
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// Puerta de acceso: el login con Google es obligatorio, así que acá se
/// decide entre [LoginScreen] y [HomeScreen] según
/// `AuthRepository.isSignedIn`. Al escuchar (`watch`) el repositorio, tanto
/// un login exitoso como un "Cerrar sesión" hacen que este widget cambie de
/// pantalla solo, sin navegación explícita en ningún otro lado.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    return auth.isSignedIn ? const ProfileGate() : const LoginScreen();
  }
}

/// Puerta de perfil: con sesión iniciada, exige completar la estatura
/// antes de dejar pasar al resto de la app (sin eso el IMC y el
/// seguimiento corporal no tienen sentido) — solo aplica la primera vez,
/// ya que después el perfil queda guardado. Mismo patrón que [AuthGate]:
/// escucha `ProfileRepository` y cambia de pantalla sola en cuanto detecta
/// que ya hay una estatura cargada (recién guardada acá, o traída por
/// sync desde otro dispositivo).
class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key});

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late final ProfileRepository _repo;
  late Future<UserProfile> _future;

  @override
  void initState() {
    super.initState();
    _repo = context.read<ProfileRepository>();
    _future = _repo.get();
    _repo.addListener(_refresh);
  }

  @override
  void dispose() {
    _repo.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _future = _repo.get();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: LoadingView());
        }
        final profile = snap.data!;
        return profile.heightCm == null
            ? ProfileSetupScreen(profile: profile)
            : const HomeScreen();
      },
    );
  }
}
