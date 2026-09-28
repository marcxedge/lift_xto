import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../repositories/exercise_log_repository.dart';
import '../repositories/exercise_repository.dart';
import '../utils/constants.dart';
import '../utils/feedback.dart';
import '../widgets/theme_toggle_button.dart';
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
  late Future<List<ExerciseProgress>> _future;
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _exercises = context.read<ExerciseRepository>();
    _logs = context.read<ExerciseLogRepository>();
    _future = _logs.progressSummary();
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

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _future = _logs.progressSummary();
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
        actions: const [ThemeToggleButton()],
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
    return FutureBuilder<List<ExerciseProgress>>(
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
        final all = snap.data!;
        final withLogs = all.where((p) => p.logCount > 0).toList();
        final withoutLogs = all.where((p) => p.logCount == 0).toList();

        if (all.isEmpty) {
          return const Center(
            child: Text('Sin ejercicios registrados.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
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
        );
      },
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
      prText = '${_fmtWeight(progress.prWeight!)} kg';
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

  String _fmtWeight(double w) =>
      w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(1);

  String _fmtSeconds(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    if (m == 0) return '${s}s';
    if (r == 0) return '${m}min';
    return '${m}min ${r}s';
  }
}
