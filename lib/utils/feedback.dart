import 'package:flutter/material.dart';

import '../core/app_exception.dart';

/// Punto único para mostrarle al usuario que algo falló. Antes, si una
/// escritura a la base fallaba, no pasaba nada visible: el usuario tocaba
/// "Guardar" y no tenía forma de saber que su registro se perdió.
void showErrorSnackBar(BuildContext context, Object error) {
  final message = error is AppException
      ? error.message
      : 'Ocurrió un error inesperado. Intenta de nuevo.';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
