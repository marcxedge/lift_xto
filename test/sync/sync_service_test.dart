import 'package:flutter_test/flutter_test.dart';
import 'package:lift_xto/sync/sync_service.dart';

void main() {
  group('remoteWinsConflict (last-write-wins)', () {
    test('gana lo remoto si no hay versión local (fila nueva)', () {
      expect(
        remoteWinsConflict(localUpdatedAt: null, remoteUpdatedAt: '2026-01-01T00:00:00.000Z'),
        isTrue,
      );
    });

    test('nunca gana lo remoto si no trae updatedAt', () {
      expect(
        remoteWinsConflict(localUpdatedAt: '2026-01-01T00:00:00.000Z', remoteUpdatedAt: null),
        isFalse,
      );
      expect(
        remoteWinsConflict(localUpdatedAt: null, remoteUpdatedAt: null),
        isFalse,
      );
    });

    test('gana el más nuevo por timestamp', () {
      expect(
        remoteWinsConflict(
          localUpdatedAt: '2026-01-01T00:00:00.000Z',
          remoteUpdatedAt: '2026-01-02T00:00:00.000Z',
        ),
        isTrue,
        reason: 'remoto es más nuevo',
      );
      expect(
        remoteWinsConflict(
          localUpdatedAt: '2026-01-02T00:00:00.000Z',
          remoteUpdatedAt: '2026-01-01T00:00:00.000Z',
        ),
        isFalse,
        reason: 'local es más nuevo, no se pisa',
      );
    });

    test('en empate exacto gana lo local (no se re-escribe innecesariamente)', () {
      expect(
        remoteWinsConflict(
          localUpdatedAt: '2026-01-01T00:00:00.000Z',
          remoteUpdatedAt: '2026-01-01T00:00:00.000Z',
        ),
        isFalse,
      );
    });
  });
}
