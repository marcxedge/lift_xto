import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/body_measurement.dart';
import '../repositories/body_measurement_repository.dart';
import '../utils/feedback.dart';
import '../utils/validators.dart';

/// Carga una "sesión" de medidas corporales — todas las zonas son
/// opcionales (el usuario puede medirse sólo cintura, por ejemplo), pero
/// hace falta al menos una para guardar.
class BodyMeasurementSheet extends StatefulWidget {
  const BodyMeasurementSheet({super.key});

  @override
  State<BodyMeasurementSheet> createState() => _BodyMeasurementSheetState();
}

class _BodyMeasurementSheetState extends State<BodyMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  late final BodyMeasurementRepository _repo;
  final _notes = TextEditingController();
  final _controllers = {
    for (final f in MeasurementField.values) f: TextEditingController(),
  };
  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _triedSubmit = false;

  @override
  void initState() {
    super.initState();
    _repo = context.read<BodyMeasurementRepository>();
  }

  @override
  void dispose() {
    _notes.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
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

  double? _val(MeasurementField f) {
    final text = _controllers[f]!.text.trim();
    return text.isEmpty ? null : Validators.parseDecimal(text);
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    final measurement = BodyMeasurement(
      date: _date,
      waistCm: _val(MeasurementField.waist),
      chestCm: _val(MeasurementField.chest),
      hipCm: _val(MeasurementField.hip),
      bicepCm: _val(MeasurementField.bicep),
      thighCm: _val(MeasurementField.thigh),
      calfCm: _val(MeasurementField.calf),
      neckCm: _val(MeasurementField.neck),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    if (!formOk || !measurement.hasAnyValue) {
      setState(() => _triedSubmit = true);
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.add(measurement);
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
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final noneEntered = _triedSubmit &&
        MeasurementField.values.every((f) => _val(f) == null);
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
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Registrar medidas corporales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Completa sólo las zonas que te mediste.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
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
              if (noneEntered)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Completa al menos una medida.',
                    style: TextStyle(color: scheme.error, fontSize: 12),
                  ),
                ),
              for (final field in MeasurementField.values) ...[
                TextFormField(
                  controller: _controllers[field],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: '${field.label} (cm)',
                    prefixIcon: const Icon(Icons.straighten),
                  ),
                  validator: (v) => Validators.circumference(v),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _notes,
                maxLength: Validators.notesMaxLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
