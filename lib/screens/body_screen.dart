import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/body_weight_log.dart';
import '../models/user_profile.dart';
import '../repositories/body_weight_repository.dart';
import '../repositories/profile_repository.dart';
import '../utils/feedback.dart';
import '../widgets/body_weight_sheet.dart';
import '../widgets/profile_sheet.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_status_button.dart';
import '../widgets/theme_toggle_button.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuerpo'),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        actions: const [SyncStatusButton(), ThemeToggleButton()],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Peso corporal'),
            Tab(text: 'IMC'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _BodyWeightTab(),
          _BmiTab(),
        ],
      ),
    );
  }
}

// ───────────────────────── BODY WEIGHT TAB ─────────────────────────

class _BodyWeightTab extends StatefulWidget {
  const _BodyWeightTab();

  @override
  State<_BodyWeightTab> createState() => _BodyWeightTabState();
}

class _BodyWeightTabState extends State<_BodyWeightTab>
    with AutomaticKeepAliveClientMixin {
  late final BodyWeightRepository _repo;
  late Future<List<BodyWeightLog>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _repo = context.read<BodyWeightRepository>();
    _future = _repo.getAll();
    _repo.addListener(_refresh);
  }

  @override
  void dispose() {
    _repo.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _future = _repo.getAll());
  }

  Future<void> _add() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BodyWeightSheet(),
    );
  }

  Future<void> _delete(BodyWeightLog log) async {
    if (log.id == null) return;
    try {
      await _repo.delete(log.id!);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: FutureBuilder<List<BodyWeightLog>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) showErrorSnackBar(context, snap.error!);
            });
          }
          if (!snap.hasData) {
            return const LoadingView();
          }
          final logs = snap.data!;
          if (logs.isEmpty) {
            return const EmptyStateView(
              icon: Icons.monitor_weight_outlined,
              title: 'Aún no registras tu peso',
              subtitle:
                  'Empieza tu seguimiento corporal con un primer registro.',
            );
          }

          final last = logs.last;
          final first = logs.first;
          final delta = last.weightKg - first.weightKg;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
              Row(
                children: [
                  Expanded(
                    child: _BodyStatCard(
                      label: 'Actual',
                      value: '${_fmt(last.weightKg)} kg',
                      subtitle: DateFormat('d MMM', 'es').format(last.date),
                      highlight: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BodyStatCard(
                      label: 'Cambio total',
                      value:
                      '${delta >= 0 ? '+' : ''}${_fmt(delta)} kg',
                      subtitle: 'desde ${DateFormat('d MMM', 'es').format(first.date)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (logs.length >= 2) ...[
                Text(
                  'Evolución',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
                      child: _BodyWeightChart(logs: logs),
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
              ...logs.reversed.map(
                    (l) => _BodyWeightTile(log: l, onDelete: () => _delete(l)),
              ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _BodyStatCard extends StatelessWidget {
  const _BodyStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String subtitle;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: highlight ? scheme.primaryContainer : null,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: highlight
                    ? scheme.onPrimaryContainer.withValues(alpha: 0.8)
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color:
                highlight ? scheme.onPrimaryContainer : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: highlight
                    ? scheme.onPrimaryContainer.withValues(alpha: 0.7)
                    : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyWeightChart extends StatelessWidget {
  const _BodyWeightChart({required this.logs});

  final List<BodyWeightLog> logs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spots = <FlSpot>[];
    for (var i = 0; i < logs.length; i++) {
      spots.add(FlSpot(i.toDouble(), logs[i].weightKg));
    }
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.2 + 0.5;

    return LineChart(
      LineChartData(
        minY: (minY - pad),
        maxY: maxY + pad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: scheme.outlineVariant, strokeWidth: 1),
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
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('d/M').format(logs[i].date),
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
                return Text(
                  value.toStringAsFixed(0),
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

class _BodyWeightTile extends StatelessWidget {
  const _BodyWeightTile({required this.log, required this.onDelete});

  final BodyWeightLog log;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final w = log.weightKg;
    final wStr =
    w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(1);
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
          '$wStr kg',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${DateFormat('d MMM yyyy', 'es').format(log.date)}'
              '${log.notes != null && log.notes!.isNotEmpty ? ' · ${log.notes}' : ''}',
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: scheme.outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

// ───────────────────────────── BMI TAB ─────────────────────────────

class _BmiTab extends StatefulWidget {
  const _BmiTab();

  @override
  State<_BmiTab> createState() => _BmiTabState();
}

class _BmiTabState extends State<_BmiTab> with AutomaticKeepAliveClientMixin {
  late final ProfileRepository _profileRepo;
  late final BodyWeightRepository _weightRepo;
  UserProfile? _profile;
  BodyWeightLog? _latestWeight;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _profileRepo = context.read<ProfileRepository>();
    _weightRepo = context.read<BodyWeightRepository>();
    _load();
    _profileRepo.addListener(_load);
    _weightRepo.addListener(_load);
  }

  @override
  void dispose() {
    _profileRepo.removeListener(_load);
    _weightRepo.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await _profileRepo.get();
      final w = await _weightRepo.getLatest();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _latestWeight = w;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _editProfile() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProfileSheet(profile: _profile ?? const UserProfile()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const LoadingView();
    }
    final scheme = Theme.of(context).colorScheme;
    final p = _profile;
    final w = _latestWeight;

    final canCalc = p?.heightCm != null && w != null;
    double? bmi;
    if (canCalc) {
      final hM = p!.heightCm! / 100;
      bmi = w.weightKg / (hM * hM);
    }
    final category = bmi == null ? null : _bmiCategory(bmi);
    final range = p?.heightCm == null ? null : _healthyRange(p!.heightCm!);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, color: scheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Mi perfil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _profileRow('Nombre',
                    (p?.hasName ?? false) ? p!.displayName : '—'),
                _profileRow('Estatura',
                    p?.heightCm == null ? '—' : '${_fmt(p!.heightCm!)} cm'),
                _profileRow(
                    'Peso actual', w == null ? '—' : '${_fmt(w.weightKg)} kg'),
                _profileRow('Edad', p?.age == null ? '—' : '${p!.age} años'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!canCalc)
          Card(
            color: scheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p?.heightCm == null
                          ? 'Agrega tu estatura en "Editar" para calcular tu IMC.'
                          : 'Registra tu peso corporal en la pestaña anterior para calcular tu IMC.',
                      style: TextStyle(color: scheme.onTertiaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          _BmiResultCard(bmi: bmi!, category: category!),
          const SizedBox(height: 16),
          _BmiScale(bmi: bmi),
          const SizedBox(height: 16),
        ],
        if (range != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.health_and_safety_outlined,
                          color: scheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Peso saludable recomendado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Para tu estatura (${_fmt(p!.heightCm!)} cm) el rango '
                        'considerado saludable es:',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_fmt(range.$1)} – ${_fmt(range.$2)} kg',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                  if (w != null) ...[
                    const SizedBox(height: 12),
                    _recommendation(w.weightKg, range, scheme),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          color: scheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Cómo se calcula?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'IMC = peso (kg) / estatura² (m)\n'
                      'Rango saludable: 18.5 – 24.9.\n\n'
                      'El IMC es una referencia general; no contempla composición '
                      'corporal (músculo vs grasa). Si haces fuerza, complementa '
                      'con medidas y porcentaje de grasa.',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _recommendation(double current, (double, double) range,
      ColorScheme scheme) {
    final (lo, hi) = range;
    if (current < lo) {
      final diff = lo - current;
      return Text(
        'Estás ${_fmt(diff)} kg por debajo del rango saludable.',
        style: TextStyle(color: scheme.onSurface),
      );
    }
    if (current > hi) {
      final diff = current - hi;
      return Text(
        'Estás ${_fmt(diff)} kg por encima del rango saludable.',
        style: TextStyle(color: scheme.onSurface),
      );
    }
    return Row(
      children: [
        Icon(Icons.check_circle, color: scheme.primary, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('Tu peso actual está dentro del rango saludable.'),
        ),
      ],
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  static (double, double) _healthyRange(double heightCm) {
    final hM = heightCm / 100;
    return (18.5 * hM * hM, 24.9 * hM * hM);
  }

  static _BmiCategory _bmiCategory(double bmi) {
    if (bmi < 18.5) {
      return _BmiCategory('Bajo peso', Colors.blue, 'Por debajo del rango.');
    }
    if (bmi < 25) {
      return _BmiCategory('Normal', Colors.green, 'Rango saludable.');
    }
    if (bmi < 30) {
      return _BmiCategory(
          'Sobrepeso', Colors.orange, 'Por encima del rango saludable.');
    }
    return _BmiCategory('Obesidad', Colors.red, 'Riesgo elevado.');
  }
}

class _BmiCategory {
  final String label;
  final Color color;
  final String description;
  _BmiCategory(this.label, this.color, this.description);
}

class _BmiResultCard extends StatelessWidget {
  const _BmiResultCard({required this.bmi, required this.category});

  final double bmi;
  final _BmiCategory category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu IMC',
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BmiScale extends StatelessWidget {
  const _BmiScale({required this.bmi});

  final double bmi;

  @override
  Widget build(BuildContext context) {
    // Visual scale: bajo peso < 18.5, normal 18.5-24.9, sobrepeso 25-29.9, obesidad >= 30
    // Mapeamos a barra de 0 a 1 con bmi entre 15 y 40.
    const min = 15.0;
    const max = 40.0;
    final pos = ((bmi - min) / (max - min)).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escala IMC',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return SizedBox(
                  height: 36,
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: ((18.5 - min) * 100).round(),
                            child: _segment(Colors.blue, 'Bajo'),
                          ),
                          Expanded(
                            flex: ((25 - 18.5) * 100).round(),
                            child: _segment(Colors.green, 'Normal'),
                          ),
                          Expanded(
                            flex: ((30 - 25) * 100).round(),
                            child: _segment(Colors.orange, 'Sobre'),
                          ),
                          Expanded(
                            flex: ((max - 30) * 100).round(),
                            child: _segment(Colors.red, 'Obeso'),
                          ),
                        ],
                      ),
                      Positioned(
                        left: pos * w - 6,
                        top: -4,
                        child: Container(
                          width: 12,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('15', style: _scaleLabelStyle(context)),
                Text('18.5', style: _scaleLabelStyle(context)),
                Text('25', style: _scaleLabelStyle(context)),
                Text('30', style: _scaleLabelStyle(context)),
                Text('40+', style: _scaleLabelStyle(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(Color color, String label) {
    return Container(
      decoration: BoxDecoration(color: color),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  TextStyle _scaleLabelStyle(BuildContext context) => TextStyle(
    fontSize: 10,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}
