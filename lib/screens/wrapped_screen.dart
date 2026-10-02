import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../repositories/exercise_log_repository.dart';
import '../utils/feedback.dart';
import '../utils/muscle_groups.dart';
import '../utils/responsive.dart';
import '../utils/weight_unit.dart';
import '../utils/wrapped_summary.dart';
import '../widgets/state_views.dart';

/// Resumen tipo "Wrapped" de todo el historial de entrenamiento — agrega
/// datos que ya existen (nada nuevo que registrar) en una tarjeta
/// compartible: kg totales movidos, racha máxima, PRs destacados y el
/// músculo más trabajado.
class WrappedScreen extends StatefulWidget {
  const WrappedScreen({super.key});

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  final _captureKey = GlobalKey();
  late Future<WrappedSummary> _future;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<WrappedSummary> _load() async {
    final logs = context.read<ExerciseLogRepository>();
    final allLogs = await logs.logsWithExerciseSince(DateTime(2000));
    final progress = await logs.progressSummary();
    final longestStreak = await logs.longestStreakEver();
    final totalSessions = await logs.totalSessionDays();
    return computeWrappedSummary(
      allLogs: allLogs,
      progress: progress,
      longestStreak: longestStreak,
      totalSessions: totalSessions,
    );
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary =
          _captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/lift_xto_wrapped.png');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Mi resumen de entrenamiento en Lift.xto 💪',
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu resumen')),
      body: Responsive.withMaxWidth(
        context,
        FutureBuilder<WrappedSummary>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const LoadingView();
            }
            final summary = snap.data!;
            if (!summary.hasData) {
              return const EmptyStateView(
                icon: Icons.insights,
                title: 'Todavía no hay suficiente historial',
                subtitle:
                    'Registra algunas sesiones para desbloquear tu resumen.',
              );
            }
            return ListView(
              padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
              children: [
                RepaintBoundary(
                  key: _captureKey,
                  child: _WrappedCard(summary: summary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: _sharing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share),
                    label: const Text('Compartir'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WrappedCard extends StatelessWidget {
  const _WrappedCard({required this.summary});

  final WrappedSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF7C3AED)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Lift.xto — Tu resumen',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            DateFormat('MMMM yyyy', 'es').format(DateTime.now()),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 24),
          _bigStat(
            WeightUnitController.instance.format(summary.totalVolumeKg),
            'levantados en total',
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _smallStat(
                  '${summary.totalSessions}',
                  'sesión${summary.totalSessions == 1 ? '' : 'es'} registrada'
                  '${summary.totalSessions == 1 ? '' : 's'}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _smallStat(
                  '${summary.longestStreak}',
                  'racha máxima (día${summary.longestStreak == 1 ? '' : 's'})',
                ),
              ),
            ],
          ),
          if (summary.topMuscleGroup != null) ...[
            const SizedBox(height: 16),
            _smallStat(summary.topMuscleGroup!.label, 'músculo más trabajado'),
          ],
          if (summary.topPrs.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Récords destacados',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            for (final pr in summary.topPrs)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pr.exerciseName,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      WeightUnitController.instance.format(pr.weightKg),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _bigStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  Widget _smallStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
