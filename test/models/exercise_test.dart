import 'package:flutter_test/flutter_test.dart';
import 'package:lift_xto/models/exercise.dart';
import 'package:lift_xto/utils/constants.dart';

void main() {
  group('Exercise — serialización', () {
    const exercise = Exercise(
      id: 1,
      dayOfWeek: 1,
      name: 'Press de banca',
      sets: 4,
      repsMin: 8,
      repsMax: 12,
      trackingType: TrackingType.weight,
      orderIndex: 0,
    );

    test('toMap incluye todos los campos', () {
      final map = exercise.toMap();
      expect(map['id'], 1);
      expect(map['day_of_week'], 1);
      expect(map['name'], 'Press de banca');
      expect(map['sets'], 4);
      expect(map['reps_min'], 8);
      expect(map['reps_max'], 12);
      expect(map['tracking_type'], TrackingType.weight);
      expect(map['order_index'], 0);
    });

    test('fromMap reconstruye el objeto correctamente', () {
      final map = exercise.toMap();
      final rebuilt = Exercise.fromMap(map);
      expect(rebuilt.id, exercise.id);
      expect(rebuilt.dayOfWeek, exercise.dayOfWeek);
      expect(rebuilt.name, exercise.name);
      expect(rebuilt.sets, exercise.sets);
      expect(rebuilt.repsMin, exercise.repsMin);
      expect(rebuilt.repsMax, exercise.repsMax);
      expect(rebuilt.trackingType, exercise.trackingType);
    });

    test('toMap omite el id cuando es null', () {
      const noId = Exercise(dayOfWeek: 2, name: 'Sentadilla', sets: 3);
      final map = noId.toMap();
      expect(map.containsKey('id'), isFalse);
    });

    test('fromMap sin tracking_type usa "weight" por defecto', () {
      final map = {
        'day_of_week': 1,
        'name': 'Jalón al pecho',
        'sets': 3,
      };
      final ex = Exercise.fromMap(map);
      expect(ex.trackingType, TrackingType.weight);
    });
  });

  group('Exercise — repsLabel', () {
    test('tipo weight con rango de reps: "4 x 8-12"', () {
      const ex = Exercise(
        dayOfWeek: 1,
        name: 'Press de banca',
        sets: 4,
        repsMin: 8,
        repsMax: 12,
        trackingType: TrackingType.weight,
      );
      expect(ex.repsLabel, '4 x 8-12');
    });

    test('tipo weight con solo repsMin: "4 x 8"', () {
      const ex = Exercise(
        dayOfWeek: 1,
        name: 'Press de banca',
        sets: 4,
        repsMin: 8,
        trackingType: TrackingType.weight,
      );
      expect(ex.repsLabel, '4 x 8');
    });

    test('tipo weight sin reps: "4 sets"', () {
      const ex = Exercise(
        dayOfWeek: 1,
        name: 'Descanso activo',
        sets: 4,
        trackingType: TrackingType.weight,
      );
      expect(ex.repsLabel, '4 sets');
    });

    test('tipo duration con rango: "3 x 30-60s"', () {
      const ex = Exercise(
        dayOfWeek: 1,
        name: 'Plancha',
        sets: 3,
        durationSecondsMin: 30,
        durationSecondsMax: 60,
        trackingType: TrackingType.duration,
      );
      expect(ex.repsLabel, '3 x 30-60s');
    });

    test('tipo duration con solo min: "3 x 30s"', () {
      const ex = Exercise(
        dayOfWeek: 1,
        name: 'Plancha',
        sets: 3,
        durationSecondsMin: 30,
        trackingType: TrackingType.duration,
      );
      expect(ex.repsLabel, '3 x 30s');
    });

    test('tipo duration sin duración: "3 sets"', () {
      const ex = Exercise(
        dayOfWeek: 1,
        name: 'Plancha',
        sets: 3,
        trackingType: TrackingType.duration,
      );
      expect(ex.repsLabel, '3 sets');
    });
  });

  group('Exercise — copyWith', () {
    const original = Exercise(
      id: 5,
      dayOfWeek: 3,
      name: 'Curl de bíceps',
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      trackingType: TrackingType.weight,
    );

    test('copia sin cambios es idéntica', () {
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.sets, original.sets);
    });

    test('solo cambia el campo modificado', () {
      final modified = original.copyWith(sets: 4, name: 'Curl martillo');
      expect(modified.sets, 4);
      expect(modified.name, 'Curl martillo');
      // El resto se mantiene
      expect(modified.id, original.id);
      expect(modified.dayOfWeek, original.dayOfWeek);
      expect(modified.repsMin, original.repsMin);
    });
  });
}
