import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/exercise_log.dart';
import '../repositories/exercise_log_repository.dart';
import '../repositories/exercise_repository.dart';
import '../utils/constants.dart';
import '../utils/feedback.dart';
import '../utils/responsive.dart';
import '../utils/weight_unit.dart';
import '../widgets/log_entry_sheet.dart';
import '../widgets/muscle_chip.dart';
import '../widgets/state_views.dart';

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final int exerciseId;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late final ExerciseRepository _exercises;
  late final ExerciseLogRepository _logs;
  Exercise? _exercise;
  List<ExerciseLog> _logsData = const [];
  bool _loading = true;
  _ChartMetric _metric = _ChartMetric.weight;

  @override
  void initState() {
    super.initState();
    _exercises = context.read<ExerciseRepository>();
    _logs = context.read<ExerciseLogRepository>();
    _load();
    _logs.addListener(_load);
  }

  @override
  void dispose() {
    _logs.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ex = await _exercises.getById(widget.exerciseId);
      final logs = await _logs.logsForExercise(widget.exerciseId);
      if (!mounted) return;
      setState(() {
        _exercise = ex;
        _logsData = logs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _addLog() async {
    if (_exercise == null) return;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LogEntrySheet(exercise: _exercise!),
    );
    // ExerciseLogRepository ya notificó y _load() se disparó solo.
  }

  Future<void> _deleteLog(ExerciseLog log) async {
    if (log.id == null) return;
    try {
      await _logs.delete(log.id!);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView());
    }
    final ex = _exercise;
    if (ex == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Ejercicio no encontrado')),
      );
    }

    final isDuration = ex.trackingType == TrackingType.duration;
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<WeightUnit>(
      valueListenable: WeightUnitController.instance.unit,
      builder: (context, unit, _) {
        return Scaffold(
      appBar: AppBar(title: Text(ex.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addLog,
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: Responsive.withMaxWidth(
        context,
        ListView(
        padding: EdgeInsets.fromLTRB(
          Responsive.horizontalPadding(context),
          8,
          Responsive.horizontalPadding(context),
          96,
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDuration ? Icons.timer : Icons.fitness_center,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ex.repsLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Weekday.name(ex.dayOfWeek),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (ex.notes != null && ex.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      ex.notes!,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  Builder(
                    builder: (_) {
                      final assignment = ex.muscleAssignment;
                      if (assignment.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: MuscleChipsRow(
                          assignment: assignment,
                          maxChips: 8,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _StatsRow(logs: _logsData, isDuration: isDuration, unit: unit),
          const SizedBox(height: 16),
          if (_logsData.length >= 2) ...[
            Row(
              children: [
                Text(
                  'Progreso',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (!isDuration)
                  DropdownButton<_ChartMetric>(
                    value: _metric,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: _ChartMetric.weight,
                        child: Text('Peso'),
                      ),
                      DropdownMenuItem(
                        value: _ChartMetric.volume,
                        child: Text('Volumen'),
                      ),
                      DropdownMenuItem(
                        value: _ChartMetric.oneRm,
                        child: Text('1RM estimado'),
                      ),
                    ],
                    onChanged: (m) {
                      if (m != null) setState(() => _metric = m);
                    },
                  ),
              ],
            ),
            if (!isDuration && _metric != _ChartMetric.weight) ...[
              const SizedBox(height: 4),
              Text(
                _metric == _ChartMetric.volume
                    ? 'Volumen = peso × series × repeticiones de cada sesión.'
                    : '1RM estimado (fórmula de Epley): peso × (1 + reps ÷ 30).',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
                  child: _ProgressChart(
                    logs: _logsData,
                    isDuration: isDuration,
                    metric: isDuration ? _ChartMetric.weight : _metric,
                    unit: unit,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Historial',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_logsData.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: EmptyStateView(
                  icon: Icons.timeline,
                  title: 'Sin registros aún',
                  subtitle:
                      'Toca "Registrar" para empezar tu sobrecarga progresiva.',
                ),
              ),
            )
          else
            ..._logsData.reversed.map(
                  (log) => _LogTile(
                log: log,
                isDuration: isDuration,
                unit: unit,
                onDelete: () => _deleteLog(log),
              ),
            ),
        ],
      ),
      ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.logs,
    required this.isDuration,
    required this.unit,
  });

  final List<ExerciseLog> logs;
  final bool isDuration;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    String last = '—';
    String pr = '—';
    String count = logs.length.toString();

    if (logs.isNotEmpty) {
      final l = logs.last;
      if (isDuration && l.durationSeconds != null) {
        last = _fmtSeconds(l.durationSeconds!);
      } else if (l.weightKg != null) {
        last = WeightUnitController.instance.format(l.weightKg);
      }

      if (isDuration) {
        final maxDur = logs
            .where((e) => e.durationSeconds != null)
            .map((e) => e.durationSeconds!)
            .fold<int?>(null, (m, v) => m == null || v > m ? v : m);
        if (maxDur != null) pr = _fmtSeconds(maxDur);
      } else {
        final maxW = logs
            .where((e) => e.weightKg != null)
            .map((e) => e.weightKg!)
            .fold<double?>(null, (m, v) => m == null || v > m ? v : m);
        if (maxW != null) pr = WeightUnitController.instance.format(maxW);
      }
    }

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Último',
            value: last,
            icon: Icons.history,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: isDuration ? 'Récord' : 'PR',
            value: pr,
            icon: Icons.emoji_events,
            highlight: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Sesiones',
            value: count,
            icon: Icons.checklist,
          ),
        ),
      ],
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: highlight ? scheme.primaryContainer : null,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: highlight ? scheme.onPrimaryContainer : scheme.primary,
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                  highlight ? scheme.onPrimaryContainer : scheme.onSurface,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: highlight
                    ? scheme.onPrimaryContainer.withValues(alpha: 0.8)
                    : scheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Métrica que se grafica en [_ProgressChart] para ejercicios con carga.
/// El peso solo no siempre refleja sobrecarga progresiva real: si las reps
/// suben y el peso se mantiene, esa línea se ve plana aunque sí hubo
/// progreso — volumen y 1RM estimado lo capturan.
enum _ChartMetric { weight, volume, oneRm }

class _ProgressChart extends StatelessWidget {
  const _ProgressChart({
    required this.logs,
    required this.isDuration,
    this.metric = _ChartMetric.weight,
    required this.unit,
  });

  final List<ExerciseLog> logs;
  final bool isDuration;
  final _ChartMetric metric;
  final WeightUnit unit;

  /// El peso de cada log siempre se guarda en kg; acá se convierte a la
  /// unidad activa antes de graficar. Como volumen y 1RM son lineales en
  /// el peso (peso × constante), convertir el resultado final da el mismo
  /// número que convertir el peso de cada set antes de calcular.
  double _valueFor(ExerciseLog l) {
    if (isDuration) return l.durationSeconds?.toDouble() ?? 0;
    final weight = unit.fromKg(l.weightKg ?? 0);
    switch (metric) {
      case _ChartMetric.weight:
        return weight;
      case _ChartMetric.volume:
        final sets = l.setsCompleted ?? 0;
        final reps = l.repsCompleted ?? 0;
        return weight * sets * reps;
      case _ChartMetric.oneRm:
        final reps = l.repsCompleted ?? 0;
        return weight * (1 + reps / 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spots = <FlSpot>[];
    for (var i = 0; i < logs.length; i++) {
      final value = _valueFor(logs[i]);
      if (value > 0) spots.add(FlSpot(i.toDouble(), value));
    }
    if (spots.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.15;

    return LineChart(
      LineChartData(
        minY: (minY - pad).clamp(0, double.infinity),
        maxY: maxY + pad + 0.0001,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (logs.length / 4).ceilToDouble().clamp(1, 999),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= logs.length) return const SizedBox.shrink();
                final d = logs[i].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('d/M').format(d),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value == meta.max || value == meta.min) {
                  return const SizedBox.shrink();
                }
                final txt = isDuration
                    ? '${(value / 60).toStringAsFixed(0)}m'
                    : value >= 1000
                        ? '${(value / 1000).toStringAsFixed(1)}k'
                        : value.toStringAsFixed(0);
                return Text(
                  txt,
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: scheme.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: scheme.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.log,
    required this.isDuration,
    required this.unit,
    required this.onDelete,
  });

  final ExerciseLog log;
  final bool isDuration;
  final WeightUnit unit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('d MMM yyyy', 'es');

    String title;
    if (isDuration && log.durationSeconds != null) {
      final m = log.durationSeconds! ~/ 60;
      final s = log.durationSeconds! % 60;
      title = m > 0 ? '$m min ${s > 0 ? '$s s' : ''}'.trim() : '${s}s';
    } else {
      final wStr = WeightUnitController.instance.formatNumber(log.weightKg ?? 0);
      final reps = log.repsCompleted ?? 0;
      final sets = log.setsCompleted ?? 0;
      title = '$wStr ${unit.suffix} · ${sets}x$reps';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            DateFormat('d').format(log.date),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${dateFmt.format(log.date)}${log.notes != null && log.notes!.isNotEmpty ? ' · ${log.notes}' : ''}',
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: scheme.outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
