import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/muscle_groups.dart';

/// Mapa muscular: silueta humana vista frontal y trasera, con cada zona
/// pintada según la intensidad de trabajo (0.0 a 1.0). Se dibuja con
/// [CustomPainter] usando `Path` para cada grupo, sin assets externos.
///
/// El widget es responsivo: el painter normaliza coordenadas a un viewBox
/// interno (360x420) y escala al tamaño disponible.
class MuscleMap extends StatelessWidget {
  const MuscleMap({super.key, required this.intensities});

  /// Intensidad por grupo (0.0 a 1.0). Grupos no presentes se asumen 0.
  final Map<MuscleGroup, double> intensities;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 360 / 420,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            painter: _MuscleMapPainter(
              intensities: intensities,
              scheme: Theme.of(context).colorScheme,
            ),
          );
        },
      ),
    );
  }
}

/// Coordenadas del viewBox interno usado por el painter.
const double _kVbW = 360;
const double _kVbH = 420;

class _MuscleMapPainter extends CustomPainter {
  _MuscleMapPainter({required this.intensities, required this.scheme});

  final Map<MuscleGroup, double> intensities;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    // Escalar todo al tamaño real
    final scaleX = size.width / _kVbW;
    final scaleY = size.height / _kVbH;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    canvas.save();
    // Centrar
    final tx = (size.width - _kVbW * scale) / 2;
    final ty = (size.height - _kVbH * scale) / 2;
    canvas.translate(tx, ty);
    canvas.scale(scale);

    // Outline gris de fondo (silueta completa)
    final outlinePaint = Paint()
      ..color = scheme.surfaceContainerHigh
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = scheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Vista frontal (centrada en x=90)
    _drawBodyOutline(canvas, outlinePaint, borderPaint, frontal: true, cx: 90);
    // Vista trasera (centrada en x=270)
    _drawBodyOutline(canvas, outlinePaint, borderPaint, frontal: false, cx: 270);

    // Pintar cada músculo con su color de intensidad
    _paintFront(canvas);
    _paintBack(canvas);

    // Etiquetas de vista
    _drawLabel(canvas, 'Frente', 90);
    _drawLabel(canvas, 'Espalda', 270);

    canvas.restore();
  }

  // ─────────────────────────── Helpers ───────────────────────────

  Color _colorFor(MuscleGroup g) {
    final i = (intensities[g] ?? 0).clamp(0.0, 1.0);
    if (i <= 0.001) return scheme.surfaceContainerHigh; // sin trabajar
    // Rampa: container claro -> primary -> tertiary (acento cálido)
    if (i < 0.5) {
      // Lerp container -> primary
      final t = i / 0.5;
      return Color.lerp(scheme.primaryContainer, scheme.primary, t)!;
    } else {
      // Lerp primary -> tertiary (acento)
      final t = (i - 0.5) / 0.5;
      return Color.lerp(scheme.primary, scheme.tertiary, t)!;
    }
  }

  void _fillPath(Canvas canvas, Path path, MuscleGroup g) {
    final paint = Paint()
      ..color = _colorFor(g)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
    final border = Paint()
      ..color = scheme.outline.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, border);
  }

  void _drawLabel(Canvas canvas, String text, double cx) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, 400));
  }

  // ─────────────────────────── Outline base ───────────────────────────

  /// Construye un polígono cerrado con las esquinas redondeadas a partir de
  /// una lista de vértices. Sin esto, el torso/brazos/piernas quedaban como
  /// polígonos de líneas rectas — funcional, pero se leía como un maniquí
  /// robótico en vez de una silueta humana. "Muerde" `radius` unidades de
  /// cada arista antes del vértice y lo reemplaza por una curva cuadrática,
  /// sin tocar las coordenadas originales (que las formas musculares ya
  /// usan como referencia para alinearse encima).
  /// `radius` es un valor único para todos los vértices, o una lista con un
  /// radio por vértice (para, por ejemplo, redondear mucho la curva del
  /// hombro y poco la de la cintura dentro del mismo polígono).
  Path _roundedPolygon(List<Offset> pts, Object radius) {
    final path = Path();
    final n = pts.length;
    final radii = radius is List<double>
        ? radius
        : List<double>.filled(n, (radius as num).toDouble());
    Offset toward(Offset from, Offset to, double dist) {
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len == 0) return from;
      final t = (dist / len).clamp(0.0, 0.5);
      return Offset(from.dx + dx * t, from.dy + dy * t);
    }

    for (var i = 0; i < n; i++) {
      final prev = pts[(i - 1 + n) % n];
      final curr = pts[i];
      final next = pts[(i + 1) % n];
      final r = radii[i];
      final start = toward(curr, prev, r);
      final end = toward(curr, next, r);
      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, end.dx, end.dy);
    }
    path.close();
    return path;
  }

  void _drawBodyOutline(
      Canvas canvas,
      Paint fill,
      Paint stroke, {
        required bool frontal,
        required double cx,
      }) {
    // Cabeza
    final headRect = Rect.fromCenter(center: Offset(cx, 29), width: 36, height: 44);
    canvas.drawOval(headRect, fill);
    canvas.drawOval(headRect, stroke);

    // Cuello + torso como UN SOLO contorno (antes eran dos formas
    // separadas que compartían el mismo borde en la unión — ambos trazos
    // coincidiendo ahí se veían como una costura marcada). El borde
    // superior baja en pendiente desde el cuello hasta la punta de cada
    // hombro, como el trapecio real, en vez de una línea recta.
    final torso = _roundedPolygon([
      Offset(cx - 9, 44),
      Offset(cx - 20, 78),
      Offset(cx - 50, 87),
      Offset(cx - 56, 110),
      Offset(cx - 50, 195),
      Offset(cx - 28, 220),
      Offset(cx + 28, 220),
      Offset(cx + 50, 195),
      Offset(cx + 56, 110),
      Offset(cx + 50, 87),
      Offset(cx + 20, 78),
      Offset(cx + 9, 44),
    ], <double>[5, 8, 20, 12, 12, 12, 12, 12, 12, 20, 8, 5]);
    canvas.drawPath(torso, fill);
    canvas.drawPath(torso, stroke);

    // Brazo izquierdo (desde la perspectiva del observador, izq de la figura)
    final armL = _roundedPolygon([
      Offset(cx - 50, 80),
      Offset(cx - 78, 95),
      Offset(cx - 80, 175),
      Offset(cx - 70, 245),
      Offset(cx - 56, 245),
      Offset(cx - 64, 175),
      Offset(cx - 56, 110),
    ], 9);
    canvas.drawPath(armL, fill);
    canvas.drawPath(armL, stroke);

    // Brazo derecho (espejado)
    final armR = _roundedPolygon([
      Offset(cx + 50, 80),
      Offset(cx + 78, 95),
      Offset(cx + 80, 175),
      Offset(cx + 70, 245),
      Offset(cx + 56, 245),
      Offset(cx + 64, 175),
      Offset(cx + 56, 110),
    ], 9);
    canvas.drawPath(armR, fill);
    canvas.drawPath(armR, stroke);

    // Piernas
    final legL = _roundedPolygon([
      Offset(cx - 28, 220),
      Offset(cx - 32, 280),
      Offset(cx - 30, 360),
      Offset(cx - 18, 388),
      Offset(cx - 4, 388),
      Offset(cx - 6, 280),
      Offset(cx - 4, 220),
    ], 11);
    canvas.drawPath(legL, fill);
    canvas.drawPath(legL, stroke);

    final legR = _roundedPolygon([
      Offset(cx + 28, 220),
      Offset(cx + 32, 280),
      Offset(cx + 30, 360),
      Offset(cx + 18, 388),
      Offset(cx + 4, 388),
      Offset(cx + 6, 280),
      Offset(cx + 4, 220),
    ], 11);
    canvas.drawPath(legR, fill);
    canvas.drawPath(legR, stroke);
  }

  // ─────────────────────────── Vista frontal ───────────────────────────

  void _paintFront(Canvas canvas) {
    const cx = 90.0;

    // Hombros frontales (deltoides anterior) — dos óvalos en los topes del torso
    final shoulderL = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx - 50, 88), width: 26, height: 24));
    final shoulderR = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx + 50, 88), width: 26, height: 24));
    _fillPath(canvas, shoulderL, MuscleGroup.hombroFrontal);
    _fillPath(canvas, shoulderR, MuscleGroup.hombroFrontal);

    // Pecho — dos pectorales
    final pecL = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx - 22, 115), width: 38, height: 34));
    final pecR = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx + 22, 115), width: 38, height: 34));
    _fillPath(canvas, pecL, MuscleGroup.pecho);
    _fillPath(canvas, pecR, MuscleGroup.pecho);

    // Bíceps — frente del brazo, mitad superior
    final bicL = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 67, 140), width: 18, height: 56),
        const Radius.circular(8),
      ));
    final bicR = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 67, 140), width: 18, height: 56),
        const Radius.circular(8),
      ));
    _fillPath(canvas, bicL, MuscleGroup.biceps);
    _fillPath(canvas, bicR, MuscleGroup.biceps);

    // Antebrazo — frente del brazo, mitad inferior
    final faL = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 64, 210), width: 16, height: 56),
        const Radius.circular(7),
      ));
    final faR = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 64, 210), width: 16, height: 56),
        const Radius.circular(7),
      ));
    _fillPath(canvas, faL, MuscleGroup.antebrazo);
    _fillPath(canvas, faR, MuscleGroup.antebrazo);

    // Abdomen — rectángulo central del torso bajo el pecho
    final ab = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 165), width: 36, height: 60),
        const Radius.circular(6),
      ));
    _fillPath(canvas, ab, MuscleGroup.abdomen);

    // Oblicuos — flancos a los lados del abdomen
    final obL = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 30, 175), width: 16, height: 50),
        const Radius.circular(5),
      ));
    final obR = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 30, 175), width: 16, height: 50),
        const Radius.circular(5),
      ));
    _fillPath(canvas, obL, MuscleGroup.oblicuos);
    _fillPath(canvas, obR, MuscleGroup.oblicuos);

    // Cuádriceps — parte alta de las piernas, frente
    final qL = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 18, 265), width: 28, height: 80),
        const Radius.circular(10),
      ));
    final qR = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 18, 265), width: 28, height: 80),
        const Radius.circular(10),
      ));
    _fillPath(canvas, qL, MuscleGroup.cuadriceps);
    _fillPath(canvas, qR, MuscleGroup.cuadriceps);

    // Aductores — entre las piernas
    final ad = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 250), width: 14, height: 50),
        const Radius.circular(5),
      ));
    _fillPath(canvas, ad, MuscleGroup.aductores);

    // Pantorrillas frontales (visible parcialmente como "espinilla")
    final calfFL = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 18, 355), width: 22, height: 50),
        const Radius.circular(8),
      ));
    final calfFR = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 18, 355), width: 22, height: 50),
        const Radius.circular(8),
      ));
    _fillPath(canvas, calfFL, MuscleGroup.pantorrilla);
    _fillPath(canvas, calfFR, MuscleGroup.pantorrilla);
  }

  // ─────────────────────────── Vista trasera ───────────────────────────

  void _paintBack(Canvas canvas) {
    const cx = 270.0;

    // Trapecio — gran triángulo en parte alta de la espalda
    final trap = Path()
      ..moveTo(cx, 75)
      ..lineTo(cx - 38, 80)
      ..lineTo(cx - 18, 130)
      ..lineTo(cx + 18, 130)
      ..lineTo(cx + 38, 80)
      ..close();
    _fillPath(canvas, trap, MuscleGroup.trapecio);

    // Hombros posteriores
    final shoulderL = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx - 50, 88), width: 26, height: 24));
    final shoulderR = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx + 50, 88), width: 26, height: 24));
    _fillPath(canvas, shoulderL, MuscleGroup.hombroPosterior);
    _fillPath(canvas, shoulderR, MuscleGroup.hombroPosterior);

    // Dorsales — alas a los lados del torso, debajo del trapecio
    final latL = Path()
      ..moveTo(cx - 18, 130)
      ..lineTo(cx - 48, 130)
      ..lineTo(cx - 50, 180)
      ..lineTo(cx - 10, 175)
      ..close();
    final latR = Path()
      ..moveTo(cx + 18, 130)
      ..lineTo(cx + 48, 130)
      ..lineTo(cx + 50, 180)
      ..lineTo(cx + 10, 175)
      ..close();
    _fillPath(canvas, latL, MuscleGroup.dorsal);
    _fillPath(canvas, latR, MuscleGroup.dorsal);

    // Tríceps — atrás del brazo, mitad superior
    final triL = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 67, 140), width: 18, height: 56),
        const Radius.circular(8),
      ));
    final triR = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 67, 140), width: 18, height: 56),
        const Radius.circular(8),
      ));
    _fillPath(canvas, triL, MuscleGroup.triceps);
    _fillPath(canvas, triR, MuscleGroup.triceps);

    // Antebrazo (también vista trasera)
    final faL = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 64, 210), width: 16, height: 56),
        const Radius.circular(7),
      ));
    final faR = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 64, 210), width: 16, height: 56),
        const Radius.circular(7),
      ));
    _fillPath(canvas, faL, MuscleGroup.antebrazo);
    _fillPath(canvas, faR, MuscleGroup.antebrazo);

    // Lumbar — parte baja central de la espalda
    final lum = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 195), width: 30, height: 32),
        const Radius.circular(6),
      ));
    _fillPath(canvas, lum, MuscleGroup.lumbar);

    // Glúteos
    final glL = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx - 16, 230), width: 30, height: 36));
    final glR = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx + 16, 230), width: 30, height: 36));
    _fillPath(canvas, glL, MuscleGroup.gluteos);
    _fillPath(canvas, glR, MuscleGroup.gluteos);

    // Isquiotibiales — atrás de la pierna, parte alta
    final isL = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 18, 290), width: 28, height: 70),
        const Radius.circular(10),
      ));
    final isR = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 18, 290), width: 28, height: 70),
        const Radius.circular(10),
      ));
    _fillPath(canvas, isL, MuscleGroup.isquios);
    _fillPath(canvas, isR, MuscleGroup.isquios);

    // Pantorrillas — atrás de la pierna, parte baja
    final calfL = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 18, 355), width: 22, height: 50),
        const Radius.circular(8),
      ));
    final calfR = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 18, 355), width: 22, height: 50),
        const Radius.circular(8),
      ));
    _fillPath(canvas, calfL, MuscleGroup.pantorrilla);
    _fillPath(canvas, calfR, MuscleGroup.pantorrilla);

    // Abductores — externos parte alta de pierna (visibles en vista trasera)
    final abdL = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 32, 250), width: 12, height: 38),
        const Radius.circular(5),
      ));
    final abdR = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 32, 250), width: 12, height: 38),
        const Radius.circular(5),
      ));
    _fillPath(canvas, abdL, MuscleGroup.abductores);
    _fillPath(canvas, abdR, MuscleGroup.abductores);
  }

  @override
  bool shouldRepaint(covariant _MuscleMapPainter old) {
    return old.intensities != intensities || old.scheme != scheme;
  }
}