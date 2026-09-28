import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/exercise.dart';
import '../utils/constants.dart';

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
  final _db = DatabaseHelper.instance;

  late final TextEditingController _name;
  late final TextEditingController _sets;
  late final TextEditingController _repsMin;
  late final TextEditingController _repsMax;
  late final TextEditingController _durationMin;
  late final TextEditingController _durationMax;
  late final TextEditingController _notes;
  late String _trackingType;

  bool get _isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
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
    );

    if (_isEditing) {
      await _db.updateExercise(exercise);
    } else {
      await _db.insertExercise(exercise);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDuration = _trackingType == TrackingType.duration;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar ejercicio' : 'Nuevo ejercicio'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: Form(
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
              decoration: const InputDecoration(
                labelText: 'Nombre del ejercicio',
                prefixIcon: Icon(Icons.fitness_center),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresa un nombre'
                  : null,
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
              validator: _intValidator(min: 1, required: true),
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
                      validator: _intValidator(min: 1),
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
                      validator: _intValidator(min: 1),
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
                      validator: _intValidator(min: 1),
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
                      validator: _intValidator(min: 1),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Guardar cambios' : 'Crear ejercicio'),
            ),
          ],
        ),
      ),
    );
  }

  String? Function(String?) _intValidator({int? min, bool required = false}) {
    return (v) {
      if (v == null || v.trim().isEmpty) {
        return required ? 'Requerido' : null;
      }
      final n = int.tryParse(v.trim());
      if (n == null) return 'Número inválido';
      if (min != null && n < min) return 'Mínimo $min';
      return null;
    };
  }
}