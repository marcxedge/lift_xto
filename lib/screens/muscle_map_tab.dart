import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/exercise_log_repository.dart';
import '../utils/muscle_groups.dart';
import '../widgets/muscle_map.dart';

/// Tab que muestra el mapa muscular coloreado según el volumen trabajado en
/// los últimos N días. Calcula la intensidad relativa por grupo muscular y
/// la pasa al [MuscleMap].
class MuscleMapTab extends StatefulWidget {
  const MuscleMapTab({super.key});

  @override
  State<MuscleMapTab> createState() => _MuscleMapTabState();
}

class _MuscleMapTabState extends State<MuscleMapTab>
    with AutomaticKeepAliveClientMixin {
  late final ExerciseLogRepository _logs;
  late Future<_MapData> _future;

  /// Días hacia atrás considerados para calcular el volumen.
  int _windowDays = 7;

  @override
  void initState() {
    super.initState();
    _logs = context.read<ExerciseLogRepository>();
    _future = _load();
    _logs.addListener(_refresh);
  }

  @override
  void dispose() {
    _logs.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  bool get wantKeepAlive => true;

  Future<_MapData> _load() async {
    final since = DateTime.now().subtract(Duration(days: _windowDays));
    final rows = await _logs.logsWithExerciseSince(since);

    // volumen acumulado por grupo muscular
    final volume = <MuscleGroup, double>{};
    int totalLogs = 0;

    for (final row in rows) {
      final assignment = MuscleDetector.detect(row.exerciseName);
      if (assignment.isEmpty) continue;

      // Cómputo del "esfuerzo" del log
      double effort;
      if (row.trackingType == 'duration') {
        // Para duración: segundos / 30 da una unidad razonable comparable
        final secs = row.durationSeconds ?? 0;
        if (secs <= 0) continue;
        effort = secs / 30.0;
      } else {
        // Para peso: peso × sets × reps
        final w = row.weightKg ?? 0;
        final s = row.setsCompleted ?? 0;
        final r = row.repsCompleted ?? 0;
        effort = w * s * r;
        if (effort <= 0) continue;
      }

      totalLogs++;
      // Primarios reciben volumen pleno, secundarios la mitad (asistencia)
      for (final g in assignment.primary) {
        volume[g] = (volume[g] ?? 0) + effort;
      }
      for (final g in assignment.secondary) {
        volume[g] = (volume[g] ?? 0) + effort * 0.5;
      }
    }

    // Normalizar al máximo para obtener intensidades 0..1
    final intensities = <MuscleGroup, double>{};
    if (volume.isNotEmpty) {
      final maxV = volume.values.reduce((a, b) => a > b ? a : b);
      if (maxV > 0) {
        for (final entry in volume.entries) {
          intensities[entry.key] = entry.value / maxV;
        }
      }
    }

    return _MapData(
      intensities: intensities,
      volume: volume,
      totalLogs: totalLogs,
    );
  }

  void _setWindow(int days) {
    if (days == _windowDays) return;
    setState(() {
      _windowDays = days;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = _load()),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Selector de rango
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7 días')),
              ButtonSegment(value: 14, label: Text('14 días')),
              ButtonSegment(value: 30, label: Text('30 días')),
            ],
            selected: {_windowDays},
            onSelectionChanged: (s) => _setWindow(s.first),
          ),
          const SizedBox(height: 16),

          FutureBuilder<_MapData>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final data = snap.data!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card del mapa
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                      child: Column(
                        children: [
                          MuscleMap(intensities: data.intensities),
                          const SizedBox(height: 8),
                          _Legend(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mensaje si no hay datos
                  if (data.totalLogs == 0)
                    Card(
                      color: scheme.tertiaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: scheme.onTertiaryContainer),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No hay registros en los últimos $_windowDays días. '
                                    'Registra una sesión y vuelve acá para ver tu mapa.',
                                style: TextStyle(
                                    color: scheme.onTertiaryContainer),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.bar_chart, color: scheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Top músculos',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._topMuscles(data.intensities).map(
                                  (entry) => Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 4),
                                child: _IntensityBar(
                                  group: entry.key,
                                  intensity: entry.value,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<MapEntry<MuscleGroup, double>> _topMuscles(
      Map<MuscleGroup, double> intensities) {
    final entries = intensities.entries
        .where((e) => e.value > 0 && e.key != MuscleGroup.cardio)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }
}

class _MapData {
  final Map<MuscleGroup, double> intensities;
  final Map<MuscleGroup, double> volume;
  final int totalLogs;

  _MapData({
    required this.intensities,
    required this.volume,
    required this.totalLogs,
  });
}

/// Leyenda con la rampa de colores que usa el mapa.
class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Intensidad: ',
            style: TextStyle(
                fontSize: 11, color: scheme.onSurfaceVariant)),
        const SizedBox(width: 6),
        _legendDot(scheme.surfaceContainerHigh, 'Sin'),
        _legendDot(scheme.primaryContainer, 'Baja'),
        _legendDot(scheme.primary, 'Media'),
        _legendDot(scheme.tertiary, 'Alta'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

/// Barra horizontal con etiqueta de músculo + barra de progreso por intensidad.
class _IntensityBar extends StatelessWidget {
  const _IntensityBar({required this.group, required this.intensity});

  final MuscleGroup group;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = intensity >= 0.5
        ? Color.lerp(scheme.primary, scheme.tertiary, (intensity - 0.5) / 0.5)!
        : Color.lerp(scheme.primaryContainer, scheme.primary, intensity / 0.5)!;
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            group.label,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: intensity,
              minHeight: 10,
              backgroundColor: scheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${(intensity * 100).round()}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}