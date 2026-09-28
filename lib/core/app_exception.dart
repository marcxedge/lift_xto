/// Excepción de dominio de la app. Los repositorios atrapan errores de
/// plataforma (SQLite, IO, etc.) y los relanzan como [AppException] con un
/// mensaje pensado para mostrarse directo al usuario en un `SnackBar`, en
/// vez de dejar que excepciones de bajo nivel (con detalles técnicos o
/// potencialmente sensibles) lleguen a la UI o queden silenciadas.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message';
}
