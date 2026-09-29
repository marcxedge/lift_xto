// Smoke test básico de Lift.xto
//
// Verifica que la aplicación monta sin lanzar excepciones.
// Los tests de lógica de negocio están en test/models/, test/utils/,
// test/database/ y test/sync/.

import 'package:flutter_test/flutter_test.dart';

import 'package:lift_xto/database/database_helper.dart';
import 'package:lift_xto/main.dart';
import 'package:lift_xto/sync/auth_repository.dart';
import 'package:lift_xto/sync/sync_service.dart';

void main() {
  testWidgets(
    'LiftXtoApp monta sin errores y AuthGate muestra LoginScreen sin sesión',
    (WidgetTester tester) async {
      // Firebase no está inicializado en el entorno de test, así que se
      // construye todo con firebaseAvailable: false (igual que un clon
      // fresco del repo sin google-services.json real). El login es
      // obligatorio, así que en ese estado AuthGate tiene que mostrar
      // LoginScreen (con su mensaje de "no configurado"), no HomeScreen.
      final db = DatabaseHelper.instance;
      final auth = AuthRepository(firebaseAvailable: false);
      final sync = SyncService(db: db, auth: auth);

      // Construimos la app — si lanza una excepción el test falla.
      await tester.pumpWidget(
        LiftXtoApp(db: db, authRepository: auth, syncService: sync),
      );

      // La barra de debug no debe mostrarse en la app real.
      expect(find.text('DEBUG'), findsNothing);

      // Sin sesión (y sin Firebase disponible), AuthGate debe quedarse en
      // LoginScreen mostrando el aviso de sincronización no configurada,
      // nunca HomeScreen.
      expect(find.text('Lift.xto'), findsOneWidget);
      expect(
        find.textContaining('sincronización no está configurada'),
        findsOneWidget,
      );
      expect(find.text('Rutina'), findsNothing);
    },
  );
}
