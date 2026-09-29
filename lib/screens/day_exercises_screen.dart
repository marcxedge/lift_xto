import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';
import '../utils/constants.dart';
import '../utils/feedback.dart';
import '../widgets/muscle_chip.dart';
import '../widgets/state_views.dart';
import 'add_edit_exercise_screen.dart';
import 'exercise_detail_screen.dart';

class DayExercisesScreen extends StatefulWidget {
  const DayExercisesScreen({super.key, required this.dayOfWeek});

  final int dayOfWeek;

  @override
  State<DayExercisesScreen> createState() => _DayExercisesScreenState();
}

class _DayExercisesScreenState extends State<DayExercisesScreen> {
  late final ExerciseRepository _repo;
  late Future<List<Exercise>> _future;

  @override
  void initState() {
    super.initState();
    _repo = context.read<ExerciseRepository>();
    _future = _repo.getByDay(widget.dayOfWeek);
    _repo.addListener(_refresh);
  }

  @override
  void dispose() {
    _repo.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _future = _repo.getByDay(widget.dayOfWeek);
    });
  }

  Future<void> _addExercise() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditExerciseScreen(dayOfWeek: widget.dayOfWeek),
      ),
    );
  }

  Future<void> _editExercise(Exercise exercise) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditExerciseScreen(
          dayOfWeek: widget.dayOfWeek,
          exercise: exercise,
        ),
      ),
    );
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar ejercicio?'),
        content: Text(
          'Se eliminará "${exercise.name}" y todo su historial de registros.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.errorContainer,
              foregroundColor: Theme.of(ctx).colorScheme.onErrorContainer,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && exercise.id != null) {
      try {
        await _repo.delete(exercise.id!);
      } catch (e) {
        if (mounted) showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Weekday.name(widget.dayOfWeek))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExercise,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: FutureBuilder<List<Exercise>>(
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
          final exercises = snap.data!;
          if (exercises.isEmpty) {
            return const EmptyStateView(
              icon: Icons.sports_gymnastics,
              title: 'Día libre',
              subtitle:
                  'Toca el botón "Agregar" para incluir ejercicios en este día.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: exercises.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final ex = exercises[i];
              return _ExerciseTile(
                exercise: ex,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExerciseDetailScreen(exerciseId: ex.id!),
                    ),
                  );
                },
                onEdit: () => _editExercise(ex),
                onDelete: () => _deleteExercise(ex),
              );
            },
          );
        },
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDuration = exercise.trackingType == TrackingType.duration;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDuration ? Icons.timer_outlined : Icons.fitness_center,
                  color: scheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercise.repsLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Builder(
                      builder: (_) {
                        final assignment = exercise.muscleAssignment;
                        if (assignment.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: MuscleChipsRow(assignment: assignment),
                        );
                      },
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Eliminar'),
                      contentPadding: EdgeInsets.zero,
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
}
