import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../repositories/exercise_log_repository.dart';
import '../repositories/exercise_repository.dart';
import '../utils/constants.dart';
import '../utils/feedback.dart';
import '../utils/overtraining.dart';
import '../utils/responsive.dart';
import '../utils/weight_unit.dart';
import '../widgets/app_menu_button.dart';
import '../widgets/sync_status_button.dart';
import 'muscle_map_tab.dart';
import 'exercise_detail_screen.dart';

/// Resumen agregado del progreso: PRs por ejercicio y últimos registros.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late final ExerciseRepository _exercises;
  late final ExerciseLogRepository _logs;
  late Future<_ProgressData> _future;
  late final TabController _tab;
  bool _dismissedOvertraining = false;

  @override
  void initState() {
    super.initState();
    _exercises = context.read<ExerciseRepository>();
    _logs = context.read<ExerciseLogRepository>();
    _future = _load();
    _tab = TabController(length: 2, vsync: this);
    // El resumen depende tanto de la lista de ejercicios como de sus logs,
    // así que escuchamos ambos repositorios (patrón Observer).
    _exercises.addListener(_refresh);
    _logs.addListener(_refresh);
  }

  @override
  void dispose() {
    _exercises.removeListener(_refresh);
    _logs.removeListener(_refresh);
    _tab.dispose();
    super.dispose();
  }

  Future<_ProgressData> _load() async {
    final all = await _logs.progressSummary();
    final candidates = all.where(
      (p) => p.exercise.trackingType == TrackingType.weight && p.logCount >= 3,
    );
    final logsByExercise = await Future.wait(
      candidates.map((p) => _logs.logsForExercise(p.exercise.id!)),
    );
    final signal = computeOvertrainingSignal(logsByExercise);
    return _ProgressData(all: all, signal: signal);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso'),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        actions: const [SyncStatusButton(), AppMenuButton()],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Por ejercicio'),
            Tab(text: 'Mapa muscular'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildPRsTab(),
          const MuscleMapTab(),
        ],
      ),
    );
  }

  Widget _buildPRsTab() {
    return ValueListenableBuilder<WeightUnit>(
      valueListenable: WeightUnitController.instance.unit,
      builder: (context, _, __) => FutureBuilder<_ProgressData>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) showErrorSnackBar(context, snap.error!);
          });
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data!.all;
        final signal = snap.data!.signal;
        final withLogs = all.where((p) => p.logCount > 0).toList();
        final withoutLogs = all.where((p) => p.logCount == 0).toList();

        if (all.isEmpty) {
          return const Center(
            child: Text('Sin ejercicios registrados.'),
          );
        }

        return Responsive.withMaxWidth(
          context,
          RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context),
              8,
              Responsive.horizontalPadding(context),
              24,
            ),
            children: [
              if (signal.triggered && !_dismissedOvertraining) ...[
                _OvertrainingBanner(
                  signal: signal,
                  onDismiss: () => setState(() => _dismissedOvertraining = true),
                ),
                const SizedBox(height: 12),
              ],
              if (withLogs.isEmpty)
                Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Theme.of(context)
                              .colorScheme
                              .onTertiaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Empieza a registrar pesos en tus ejercicios para '
                                'ver aquí tu progreso.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (withLogs.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Récords personales',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...withLogs.map(
                      (p) => _ProgressTile(
                    progress: p,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ExerciseDetailScreen(
                            exerciseId: p.exercise.id!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (withoutLogs.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: Text(
                    'Sin registros aún',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...withoutLogs.map(
                      (p) => _ProgressTile(
                    progress: p,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ExerciseDetailScreen(
                            exerciseId: p.exercise.id!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        );
      },
      ),
    );
  }
}

class _ProgressData {
  const _ProgressData({required this.all, required this.signal});
  final List<ExerciseProgress> all;
  final OvertrainingSignal signal;
}

/// Alerta de posible sobreentrenamiento: estadística simple sobre los
/// registros ya guardados (ver `computeOvertrainingSignal`), nada de IA.
/// Se puede descartar — vuelve a aparecer si se vuelve a cumplir la
/// condición en una visita futura a la pantalla.
class _OvertrainingBanner extends StatelessWidget {
  const _OvertrainingBanner({required this.signal, required this.onDismiss});

  final OvertrainingSignal signal;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Posible estancamiento',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${signal.stagnantCount} de ${signal.totalChecked} ejercicios no '
                    'mejoraron su 1RM estimado en las últimas sesiones. Puede ser '
                    'normal, pero si se repite considera una semana de descarga '
                    '(bajar volumen/intensidad).',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onErrorContainer.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: scheme.onErrorContainer, size: 18),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({required this.progress, required this.onTap});

  final ExerciseProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ex = progress.exercise;
    final isDuration = ex.trackingType == TrackingType.duration;

    String prText = '—';
    if (isDuration && progress.prDuration != null) {
      prText = _fmtSeconds(progress.prDuration!);
    } else if (progress.prWeight != null) {
      prText = WeightUnitController.instance.format(progress.prWeight!);
    }

    String lastText = '';
    if (progress.lastDate != null) {
      lastText = 'Último: ${DateFormat('d MMM', 'es').format(progress.lastDate!)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: progress.logCount > 0
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isDuration ? Icons.timer : Icons.emoji_events,
                  color: progress.logCount > 0
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Weekday.shortName(ex.dayOfWeek)} · ${progress.logCount} sesión${progress.logCount == 1 ? '' : 'es'}'
                          '${lastText.isEmpty ? '' : ' · $lastText'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    prText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: progress.logCount > 0
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    isDuration ? 'récord' : 'PR',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtSeconds(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    if (m == 0) return '${s}s';
    if (r == 0) return '${m}min';
    return '${m}min ${r}s';
  }
}
