import 'package:flutter_test/flutter_test.dart';
import 'package:lift_xto/models/user_profile.dart';

void main() {
  group('UserProfile — displayName', () {
    test('ambos nombres: "Mario Pérez"', () {
      const p = UserProfile(firstName: 'Mario', lastName: 'Pérez');
      expect(p.displayName, 'Mario Pérez');
    });

    test('solo firstName', () {
      const p = UserProfile(firstName: 'Mario');
      expect(p.displayName, 'Mario');
    });

    test('solo lastName', () {
      const p = UserProfile(lastName: 'Pérez');
      expect(p.displayName, 'Pérez');
    });

    test('vacío cuando no hay nombre', () {
      const p = UserProfile();
      expect(p.displayName, '');
    });

    test('ignora espacios en blanco extra', () {
      const p = UserProfile(firstName: '  Mario  ', lastName: '  Pérez  ');
      expect(p.displayName, 'Mario Pérez');
    });
  });

  group('UserProfile — initials', () {
    test('"MP" cuando hay nombre y apellido', () {
      const p = UserProfile(firstName: 'Mario', lastName: 'Pérez');
      expect(p.initials, 'MP');
    });

    test('solo primera inicial cuando falta el apellido', () {
      const p = UserProfile(firstName: 'Mario');
      expect(p.initials, 'M');
    });

    test('"?" cuando no hay nombre', () {
      const p = UserProfile();
      expect(p.initials, '?');
    });

    test('iniciales en mayúsculas aunque el nombre venga en minúsculas', () {
      const p = UserProfile(firstName: 'mario', lastName: 'pérez');
      expect(p.initials, 'MP');
    });
  });

  group('UserProfile — hasName', () {
    test('true cuando hay al menos un nombre', () {
      const p = UserProfile(firstName: 'Mario');
      expect(p.hasName, isTrue);
    });

    test('false cuando no hay nombre', () {
      const p = UserProfile();
      expect(p.hasName, isFalse);
    });
  });

  group('UserProfile — serialización (toMap / fromMap)', () {
    const profile = UserProfile(
      id: 1,
      firstName: 'Mario',
      lastName: 'Pérez',
      heightCm: 175.5,
      age: 28,
      gender: 'M',
    );

    test('toMap produce el mapa correcto', () {
      final map = profile.toMap();
      expect(map['id'], 1);
      expect(map['first_name'], 'Mario');
      expect(map['last_name'], 'Pérez');
      expect(map['height_cm'], 175.5);
      expect(map['age'], 28);
      expect(map['gender'], 'M');
    });

    test('fromMap reconstruye idéntico', () {
      final rebuilt = UserProfile.fromMap(profile.toMap());
      expect(rebuilt.id, profile.id);
      expect(rebuilt.firstName, profile.firstName);
      expect(rebuilt.lastName, profile.lastName);
      expect(rebuilt.heightCm, profile.heightCm);
      expect(rebuilt.age, profile.age);
      expect(rebuilt.gender, profile.gender);
    });

    test('fromMap con id nulo usa 1 por defecto', () {
      final map = {'first_name': 'Ana'};
      final p = UserProfile.fromMap(map);
      expect(p.id, 1);
      expect(p.firstName, 'Ana');
    });
  });

  group('UserProfile — copyWith', () {
    const original = UserProfile(
      firstName: 'Mario',
      lastName: 'Pérez',
      age: 28,
    );

    test('copia sin cambios es idéntica', () {
      final copy = original.copyWith();
      expect(copy.firstName, original.firstName);
      expect(copy.lastName, original.lastName);
      expect(copy.age, original.age);
    });

    test('solo modifica el campo indicado', () {
      final updated = original.copyWith(age: 29);
      expect(updated.age, 29);
      expect(updated.firstName, original.firstName); // intacto
    });
  });
}
