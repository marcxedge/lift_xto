import 'package:flutter/material.dart';

/// Ícono de Google para el botón de "Iniciar sesión con Google": una "G"
/// azul sobre círculo blanco, en vez de intentar replicar el logo de
/// cuatro colores con un `CustomPainter` (no hay asset ni paquete de
/// íconos de marca en el proyecto para el logo oficial, y a mano libre el
/// resultado terminaba pareciendo un molinillo en vez de una "G").
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Text(
        'G',
        style: TextStyle(
          fontSize: size * 0.72,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}
