class UserProfile {
  final int id; // Siempre 1, perfil único
  final String? firstName;
  final String? lastName;
  final double? heightCm;
  final int? age;
  final String? gender; // 'M' | 'F' | null

  const UserProfile({
    this.id = 1,
    this.firstName,
    this.lastName,
    this.heightCm,
    this.age,
    this.gender,
  });

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
    int? age,
    String? gender,
  }) {
    return UserProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
      gender: gender ?? this.gender,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'height_cm': heightCm,
      'age': age,
      'gender': gender,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: (map['id'] as int?) ?? 1,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      age: map['age'] as int?,
      gender: map['gender'] as String?,
    );
  }
}