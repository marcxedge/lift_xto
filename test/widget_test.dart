// Smoke test básico de Lift.xto
//
// Verifica que la aplicación monta sin lanzar excepciones.
// Los tests de lógica de negocio están en test/models/ y test/utils/.

import 'package:flutter_test/flutter_test.dart';
import 'package:lift_xto/main.dart';

void main() {
  testWidgets('LiftXtoApp monta sin errores', (WidgetTester tester) async {
    // Construimos la app — si lanza una excepción el test falla.
    await tester.pumpWidget(const LiftXtoApp());

    // La barra de debug no debe mostrarse en la app real.
    expect(find.text('DEBUG'), findsNothing);
  });
}
