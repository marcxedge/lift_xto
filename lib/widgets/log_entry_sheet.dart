import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/exercise.dart';
import '../models/exercise_log.dart';
import '../utils/constants.dart';

class LogEntrySheet extends StatefulWidget {
  const LogEntrySheet({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<LogEntrySheet> createState() => _LogEntrySheetState();
}

class _LogEntrySheetState extends State<LogEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper.instance;

  final _weight = TextEditingController();
  final _sets = TextEditingController();
  final _reps = TextEditingController();
  final _duration = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();

  ExerciseLog? _lastLog;

  @override
  void initState() {
    super.initState();
    _prefillFromLast();
    _sets.text = widget.exercise.sets.toString();
  }

  Future<void> _prefillFromLast() async {
    final last = await _db.getLastLog(widget.exercise.id!);
    if (last == null || !mounted) return;
    setState(() {
      _lastLog = last;
      if (widget.exercise.trackingType == TrackingType.weight) {
        if (last.weightKg != null) _weight.text = _fmt(last.weightKg!);
        if (last.repsCompleted != null) _reps.text = '${last.repsCompleted}';
        if (last.setsCompleted != null) _sets.text = '${last.setsCompleted}';
      } else {
        if (last.durationSeconds != null) {
          _duration.text = '${last.durationSeconds}';
        }
      }
    });
  }

  @override
  void dispose() {
    _weight.dispose();
    _sets.dispose();
    _reps.dispose();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isDuration = widget.exercise.trackingType == TrackingType.duration;
    final log = ExerciseLog(
      exerciseId: widget.exercise.id!,
      date: _date,
      weightKg: isDuration
          ? null
          : double.parse(_weight.text.trim().replaceAll(',', '.')),
      setsCompleted: int.tryParse(_sets.text.trim()),
      repsCompleted:
      isDuration ? null : int.tryParse(_reps.text.trim()),
      durationSeconds:
      isDuration ? int.tryParse(_duration.text.trim()) : null,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    await _db.insertExerciseLog(log);
    if (mounted) Navigator.of(context).pop(true);
  }

  String _fmt(double w) {
    return w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDuration = widget.exercise.trackingType == TrackingType.duration;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.exercise.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Objetivo: ${widget.exercise.repsLabel}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (_lastLog != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Último: ${_summarizeLast(_lastLog!, isDuration)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('EEEE d MMM yyyy', 'es').format(_date),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!isDuration) ...[
                TextFormField(
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9.,]'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    final n = double.tryParse(v.trim().replaceAll(',', '.'));
                    if (n == null || n < 0) return 'Inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sets,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Sets realizados',
                        ),
                        validator: _intValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _reps,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Reps por set',
                        ),
                        validator: _intValidator,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextFormField(
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Duración (segundos)',
                    helperText: '60 = 1 min, 120 = 2 min, etc.',
                    prefixIcon: Icon(Icons.timer),
                  ),
                  validator: _intValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sets,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Sets / repeticiones',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar registro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _intValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    final n = int.tryParse(v.trim());
    if (n == null || n < 0) return 'Inválido';
    return null;
  }

  String _summarizeLast(ExerciseLog last, bool isDuration) {
    final fmt = DateFormat('d MMM', 'es').format(last.date);
    if (isDuration && last.durationSeconds != null) {
      return '${last.durationSeconds}s ($fmt)';
    }
    final w = last.weightKg ?? 0;
    final wStr = _fmt(w);
    return '$wStr kg · ${last.setsCompleted ?? "?"}x${last.repsCompleted ?? "?"} ($fmt)';
  }
}