import 'package:flutter/material.dart';

/// Breakpoints y helpers de tamaño compartidos por toda la app, para que
/// ninguna pantalla dependa de medidas fijas en píxeles que se ven bien
/// sólo en el teléfono donde se probaron. Basado en el ancho lógico
/// disponible (`MediaQuery.size.width`), no en el tipo de dispositivo.
class Responsive {
  Responsive._();

  /// Por debajo de esto es un teléfono chico (ej. un Android de gama baja
  /// con pantalla de 5") — hay que achicar un poco texto/paddings para que
  /// nada se corte.
  static const double smallPhoneMaxWidth = 360;

  /// Por encima de esto se considera tablet (incluye tablets chicas en
  /// vertical) — el contenido se centra con un ancho máximo en vez de
  /// estirarse de borde a borde.
  static const double tabletMinWidth = 600;

  static const double _maxContentWidth = 720;

  static bool isSmallPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < smallPhoneMaxWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMinWidth;

  /// Factor multiplicador para tamaños de fuente/íconos: un poco más chico
  /// en teléfonos pequeños, un poco más grande en tablets, 1.0 en el resto.
  static double scale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < smallPhoneMaxWidth) return 0.92;
    if (width >= tabletMinWidth) return 1.08;
    return 1.0;
  }

  /// Tamaño de fuente ya escalado — usar en vez de un `fontSize` fijo en
  /// cualquier `Text`/`TextStyle` que antes tenía un número suelto.
  static double font(BuildContext context, double base) => base * scale(context);

  /// Padding horizontal de pantalla: más angosto en teléfonos chicos, más
  /// ancho en tablets (además del centrado de [withMaxWidth]).
  static double horizontalPadding(BuildContext context) {
    if (isSmallPhone(context)) return 12;
    if (isTablet(context)) return 24;
    return 16;
  }

  /// Envuelve el body de una pantalla: en teléfono lo deja tal cual: en
  /// tablet lo centra con un ancho máximo para que listas/forms no se
  /// estiren de borde a borde y pierdan legibilidad.
  static Widget withMaxWidth(BuildContext context, Widget child) {
    if (!isTablet(context)) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: child,
      ),
    );
  }
}
