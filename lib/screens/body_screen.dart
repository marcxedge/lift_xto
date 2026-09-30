import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/body_weight_log.dart';
import '../models/user_profile.dart';
import '../repositories/body_weight_repository.dart';
import '../repositories/profile_repository.dart';
import '../utils/feedback.dart';
import '../widgets/app_menu_button.dart';
import '../widgets/body_weight_sheet.dart';
import '../widgets/profile_sheet.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_status_button.dart';

/// Pantalla de Cuerpo: peso corporal e IMC fusionados en una sola vista
/// (antes eran 2 tabs separadas) — el peso actual y el IMC se ven juntos
/// de entrada, sin tener que cambiar de pestaña para relacionar un dato con
/// el otro.
class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  late final BodyWeightRepository _weightRepo;
  late final ProfileRepository _profileRepo;

  List<BodyWeightLog>? _logs;
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _weightRepo = context.read<BodyWeightRepository>();
    _profileRepo = context.read<ProfileRepository>();
    _load();
    _weightRepo.addListener(_load);
    _profileRepo.addListener(_load);
  }

  @override
  void dispose() {
    _weightRepo.removeListener(_load);
    _profileRepo.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final logs = await _weightRepo.getAll();
      final profile = await _profileRepo.get();
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _addWeight() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BodyWeightSheet(),
    );
  }

  Future<void> _editProfile() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProfileSheet(profile: _profile ?? const UserProfile()),
    );
  }

  Future<void> _deleteWeight(BodyWeightLog log) async {
    if (log.id == null) return;
    try {
      await _weightRepo.delete(log.id!);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuerpo'),
        titleTextStyle: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        actions: const [SyncStatusButton(), AppMenuButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWeight,
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: _loading ? const LoadingView() : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final logs = _logs ?? const [];
    final profile = _profile;
    final latest = logs.isEmpty ? null : logs.last;

    final canCalc = profile?.heightCm != null && latest != null;
    double? bmi;
    if (canCalc) {
      final hM = profile!.heightCm! / 100;
      bmi = latest.weightKg / (hM * hM);
    }
    final category = bmi == null ? null : _bmiCategory(bmi);
    final range = profile?.heightCm == null
        ? null
        : _healthyRange(profile!.heightCm!);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _ProfileCard(profile: profile, onEdit: _editProfile),
          const SizedBox(height: 16),
          // IntrinsicHeight: sin esto, el Row (con stretch) recibe una altura
          // no acotada del ListView y las cards de peso/IMC no se pintan.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _BodyStatCard(
                    label: 'Peso actual',
                    value: latest == null ? '—' : '${_fmt(latest.weightKg)} kg',
                    subtitle: latest == null
                        ? 'Sin registros'
                        : DateFormat('d MMM', 'es').format(latest.date),
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ImcCell(
                    bmi: bmi,
                    category: category,
                    missingHeight: profile?.heightCm == null,
                    missingWeight: latest == null,
                    onTap: _editProfile,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            const EmptyStateView(
              icon: Icons.monitor_weight_outlined,
              title: 'Aún no registras tu peso',
              subtitle:
                  'Toca "Registrar" para empezar tu seguimiento corporal.',
            )
          else ...[
            if (logs.length >= 2) ...[
              Text('Evolución', style: Theme.of(context).textTheme.titleMedium),
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
            if (range != null) ...[
              _BmiScale(bmi: bmi ?? 0),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.health_and_safety_outlined,
                            color: scheme.primary,
                          ),
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
                        'Para tu estatura (${_fmt(profile!.heightCm!)} cm) el '
                        'rango considerado saludable es:',
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
                      const SizedBox(height: 12),
                      _recommendation(latest!.weightKg, range, scheme),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text('Historial', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...logs.reversed.map(
              (l) => _BodyWeightTile(log: l, onDelete: () => _deleteWeight(l)),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            color: scheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Cómo se calcula el IMC?',
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
                    'El IMC es una referencia general; no contempla '
                    'composición corporal (músculo vs grasa). Si haces '
                    'fuerza, compleméntalo con medidas y porcentaje de '
                    'grasa.',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendation(
    double current,
    (double, double) range,
    ColorScheme scheme,
  ) {
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
      return _BmiCategory('Bajo peso', Colors.blue);
    }
    if (bmi < 25) {
      return _BmiCategory('Normal', Colors.green);
    }
    if (bmi < 30) {
      return _BmiCategory('Sobrepeso', Colors.orange);
    }
    return _BmiCategory('Obesidad', Colors.red);
  }
}

class _BmiCategory {
  _BmiCategory(this.label, this.color);
  final String label;
  final Color color;
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onEdit});

  final UserProfile? profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = profile;
    return Card(
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _row(context, 'Nombre', (p?.hasName ?? false) ? p!.displayName : '—'),
            _row(
              context,
              'Estatura',
              p?.heightCm == null ? '—' : '${_fmt(p!.heightCm!)} cm',
            ),
            _row(context, 'Edad', p?.age == null ? '—' : '${p!.age} años'),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
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
                color: highlight ? scheme.onPrimaryContainer : scheme.onSurface,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Celda de IMC para la fila de stats junto al peso actual. Si falta algún
/// dato para calcularlo, se vuelve un aviso tocable que lleva directo a
/// editar el perfil — en vez de una card aparte que hay que ir a buscar.
class _ImcCell extends StatelessWidget {
  const _ImcCell({
    required this.bmi,
    required this.category,
    required this.missingHeight,
    required this.missingWeight,
    required this.onTap,
  });

  final double? bmi;
  final _BmiCategory? category;
  final bool missingHeight;
  final bool missingWeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (bmi != null && category != null) {
      return Card(
        color: category!.color,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IMC',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  bmi!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  category!.label,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final message = missingHeight
        ? 'Agrega tu estatura'
        : 'Registra tu peso';
    return Card(
      color: scheme.tertiaryContainer,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IMC',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onTertiaryContainer.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: scheme.onTertiaryContainer,
                ),
              ),
              Text(
                'Toca para completar',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onTertiaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
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

class _BmiScale extends StatelessWidget {
  const _BmiScale({required this.bmi});

  final double bmi;

  @override
  Widget build(BuildContext context) {
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

  TextStyle _scaleLabelStyle(BuildContext context) =>
      TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant);
}
