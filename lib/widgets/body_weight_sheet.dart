import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/body_weight_log.dart';
import '../repositories/body_weight_repository.dart';
import '../utils/feedback.dart';
import '../utils/validators.dart';
import '../utils/weight_unit.dart';

class BodyWeightSheet extends StatefulWidget {
  const BodyWeightSheet({super.key});

  @override
  State<BodyWeightSheet> createState() => _BodyWeightSheetState();
}

class _BodyWeightSheetState extends State<BodyWeightSheet> {
  final _formKey = GlobalKey<FormState>();
  late final BodyWeightRepository _repo;
  final _weight = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;
  final WeightUnit _unit = WeightUnitController.instance.unit.value;

  @override
  void initState() {
    super.initState();
    _repo = context.read<BodyWeightRepository>();
    _prefillLast();
  }

  Future<void> _prefillLast() async {
    final last = await _repo.getLatest();
    if (last != null && mounted) {
      _weight.text = _fmt(_unit.fromKg(last.weightKg));
    }
  }

  @override
  void dispose() {
    _weight.dispose();
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
    final log = BodyWeightLog(
      date: _date,
      weightKg: _unit.toKg(Validators.parseDecimal(_weight.text.trim())!),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    setState(() => _saving = true);
    try {
      await _repo.add(log);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showErrorSnackBar(context, e);
      }
    }
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Registrar peso corporal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _weight,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Peso (${_unit.suffix})',
                  prefixIcon: const Icon(Icons.monitor_weight),
                ),
                validator: (v) => Validators.weightInUnit(
                  v,
                  _unit,
                  minKg: Validators.bodyWeightMin,
                  maxKg: Validators.bodyWeightMax,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLength: Validators.notesMaxLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                ),
              ),
              const SizedBox(height: 20),
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
