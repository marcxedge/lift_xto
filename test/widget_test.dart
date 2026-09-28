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
  testWidgets('LiftXtoApp monta sin errores', (WidgetTester tester) async {
    // Firebase no está inicializado en el entorno de test, así que se
    // construye todo con firebaseAvailable: false (igual que un clon
    // fresco del repo sin google-services.json real) — la app tiene que
    // seguir funcionando 100% local.
    final db = DatabaseHelper.instance;
    final auth = AuthRepository(firebaseAvailable: false);
    final sync = SyncService(db: db, auth: auth);

    // Construimos la app — si lanza una excepción el test falla.
    await tester.pumpWidget(
      LiftXtoApp(db: db, authRepository: auth, syncService: sync),
    );

    // La barra de debug no debe mostrarse en la app real.
    expect(find.text('DEBUG'), findsNothing);
  });
}
