class UserProfile {
  final int id; // Siempre 1, perfil único
  final String? firstName;
  final String? lastName;
  final double? heightCm;
  final DateTime? birthDate;
  final String? gender; // 'M' | 'F' | null

  const UserProfile({
    this.id = 1,
    this.firstName,
    this.lastName,
    this.heightCm,
    this.birthDate,
    this.gender,
  });

  /// Edad calculada a partir de [birthDate] — ya no se ingresa a mano, para
  /// que no se desactualice con el tiempo. `null` si no hay fecha cargada.
  int? get age {
    final b = birthDate;
    if (b == null) return null;
    final now = DateTime.now();
    var years = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) {
      years--;
    }
    return years;
  }

  /// Nombre completo, o cadena vacía si no hay nada cargado.
  String get displayName {
    final parts = <String>[
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!.trim(),
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!.trim(),
    ];
    return parts.join(' ');
  }

  /// Solo el primer nombre (útil para saludos cortos: "Hola, Mario").
  String get firstNameOrEmpty => firstName?.trim() ?? '';

  /// Iniciales para mostrar en avatares. "?" si todavía no hay nombre.
  String get initials {
    final f = firstName?.trim() ?? '';
    final l = lastName?.trim() ?? '';
    if (f.isEmpty && l.isEmpty) return '?';
    final fi = f.isNotEmpty ? f[0].toUpperCase() : '';
    final li = l.isNotEmpty ? l[0].toUpperCase() : '';
    return '$fi$li';
  }

  bool get hasName => displayName.isNotEmpty;

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    double? heightCm,
    DateTime? birthDate,
    String? gender,
  }) {
    return UserProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      heightCm: heightCm ?? this.heightCm,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'height_cm': heightCm,
      'birth_date': birthDate == null
          ? null
          : '${birthDate!.year.toString().padLeft(4, '0')}-'
              '${birthDate!.month.toString().padLeft(2, '0')}-'
              '${birthDate!.day.toString().padLeft(2, '0')}',
      'gender': gender,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: (map['id'] as int?) ?? 1,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      birthDate: map['birth_date'] == null
          ? null
          : DateTime.tryParse(map['birth_date'] as String),
      gender: map['gender'] as String?,
    );
  }
}
