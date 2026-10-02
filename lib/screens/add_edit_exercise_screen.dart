import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/catalog_exercise.dart';
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';
import '../utils/constants.dart';
import '../utils/feedback.dart';
import '../utils/muscle_groups.dart';
import '../utils/responsive.dart';
import '../utils/validators.dart';
import 'exercise_catalog_screen.dart';

class AddEditExerciseScreen extends StatefulWidget {
  const AddEditExerciseScreen({
    super.key,
    required this.dayOfWeek,
    this.exercise,
  });

  final int dayOfWeek;
  final Exercise? exercise;

  @override
  State<AddEditExerciseScreen> createState() => _AddEditExerciseScreenState();
}

class _AddEditExerciseScreenState extends State<AddEditExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ExerciseRepository _repo;

  late final TextEditingController _name;
  late final TextEditingController _sets;
  late final TextEditingController _repsMin;
  late final TextEditingController _repsMax;
  late final TextEditingController _durationMin;
  late final TextEditingController _durationMax;
  late final TextEditingController _notes;
  late String _trackingType;
  MuscleGroup? _muscleGroup;
  bool _saving = false;

  bool get _isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    _repo = context.read<ExerciseRepository>();
    final ex = widget.exercise;
    _name = TextEditingController(text: ex?.name ?? '');
    _sets = TextEditingController(text: ex?.sets.toString() ?? '3');
    _repsMin = TextEditingController(text: ex?.repsMin?.toString() ?? '');
    _repsMax = TextEditingController(text: ex?.repsMax?.toString() ?? '');
    // Convertimos de segundos a "segundos en input" (en el caso de cardio
    // el usuario puede preferir minutos; lo mostramos en segundos para
    // mantener simplicidad pero el formato es claro).
    _durationMin = TextEditingController(
      text: ex?.durationSecondsMin?.toString() ?? '',
    );
    _durationMax = TextEditingController(
      text: ex?.durationSecondsMax?.toString() ?? '',
    );
    _notes = TextEditingController(text: ex?.notes ?? '');
    _trackingType = ex?.trackingType ?? TrackingType.weight;
    _muscleGroup = ex?.muscleGroup;
  }

  @override
  void dispose() {
    _name.dispose();
    _sets.dispose();
    _repsMin.dispose();
    _repsMax.dispose();
    _durationMin.dispose();
    _durationMax.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickFromCatalog() async {
    final chosen = await Navigator.of(context).push<CatalogExercise>(
      MaterialPageRoute(builder: (_) => const ExerciseCatalogScreen()),
    );
    if (chosen == null) return;
    setState(() {
      _name.text = chosen.nameEs;
      if (chosen.muscleGroup != null) _muscleGroup = chosen.muscleGroup;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final exercise = Exercise(
      id: widget.exercise?.id,
      dayOfWeek: widget.dayOfWeek,
      name: _name.text.trim(),
      sets: int.parse(_sets.text.trim()),
      repsMin: _trackingType == TrackingType.weight
          ? int.tryParse(_repsMin.text.trim())
          : null,
      repsMax: _trackingType == TrackingType.weight
          ? int.tryParse(_repsMax.text.trim())
          : null,
      durationSecondsMin: _trackingType == TrackingType.duration
          ? int.tryParse(_durationMin.text.trim())
          : null,
      durationSecondsMax: _trackingType == TrackingType.duration
          ? int.tryParse(_durationMax.text.trim())
          : null,
      trackingType: _trackingType,
      orderIndex: widget.exercise?.orderIndex ?? 0,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      muscleGroup: _muscleGroup,
    );

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await _repo.update(exercise);
      } else {
        await _repo.add(exercise);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDuration = _trackingType == TrackingType.duration;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar ejercicio' : 'Nuevo ejercicio'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: Responsive.withMaxWidth(
        context,
        Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              Weekday.name(widget.dayOfWeek),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [
                LengthLimitingTextInputFormatter(
                  Validators.shortTextMaxLength,
                ),
              ],
              decoration: const InputDecoration(
                labelText: 'Nombre del ejercicio',
                prefixIcon: Icon(Icons.fitness_center),
              ),
              validator: Validators.requiredText,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickFromCatalog,
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Elegir del catálogo'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MuscleGroup>(
              initialValue: _muscleGroup,
              decoration: const InputDecoration(
                labelText: 'Parte del cuerpo',
                prefixIcon: Icon(Icons.accessibility_new),
              ),
              items: [
                for (final group in MuscleGroup.values)
                  DropdownMenuItem(value: group, child: Text(group.label)),
              ],
              onChanged: (value) => setState(() => _muscleGroup = value),
              validator: (v) =>
                  v == null ? 'Elige qué parte del cuerpo trabaja' : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: TrackingType.weight,
                  label: Text('Peso'),
                  icon: Icon(Icons.fitness_center, size: 18),
                ),
                ButtonSegment(
                  value: TrackingType.duration,
                  label: Text('Duración'),
                  icon: Icon(Icons.timer, size: 18),
                ),
              ],
              selected: {_trackingType},
              onSelectionChanged: (s) =>
                  setState(() => _trackingType = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sets,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Sets',
                prefixIcon: Icon(Icons.repeat),
              ),
              validator: (v) => Validators.sets(v),
            ),
            const SizedBox(height: 16),
            if (!isDuration) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _repsMin,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Reps mín.',
                      ),
                      validator: (v) => Validators.reps(v, required: false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _repsMax,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Reps máx.',
                      ),
                      validator: (v) => Validators.reps(v, required: false),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationMin,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Duración mín. (s)',
                        helperText: 'En segundos',
                      ),
                      validator: (v) =>
                          Validators.durationSeconds(v, required: false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationMax,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Duración máx. (s)',
                        helperText: 'En segundos',
                      ),
                      validator: (v) =>
                          Validators.durationSeconds(v, required: false),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              maxLength: Validators.notesMaxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isEditing ? 'Guardar cambios' : 'Crear ejercicio'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
