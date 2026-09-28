import 'package:flutter/material.dart';

import '../utils/muscle_groups.dart';

/// Chip compacto que muestra un grupo muscular. Los músculos primarios usan
/// un fondo más saturado, los secundarios un acento más sutil.
class MuscleChip extends StatelessWidget {
  const MuscleChip({
    super.key,
    required this.group,
    this.isPrimary = true,
  });

  final MuscleGroup group;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isPrimary ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = isPrimary ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        group.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

/// Fila horizontal de chips para mostrar todos los músculos de un ejercicio.
/// Si la lista está vacía, no renderiza nada.
class MuscleChipsRow extends StatelessWidget {
  const MuscleChipsRow({super.key, required this.assignment, this.maxChips = 4});

  final MuscleAssignment assignment;
  final int maxChips;

  @override
  Widget build(BuildContext context) {
    if (assignment.isEmpty) return const SizedBox.shrink();
    final chips = <Widget>[];
    for (final m in assignment.primary) {
      if (chips.length >= maxChips) break;
      chips.add(MuscleChip(group: m, isPrimary: true));
    }
    for (final m in assignment.secondary) {
      if (chips.length >= maxChips) break;
      chips.add(MuscleChip(group: m, isPrimary: false));
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: chips,
    );
  }
}