import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';
import '../utils/feedback.dart';
import '../utils/validators.dart';

class ProfileSheet extends StatefulWidget {
  const ProfileSheet({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final ProfileRepository _repo;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _height;
  late final TextEditingController _age;
  String? _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repo = context.read<ProfileRepository>();
    _firstName = TextEditingController(text: widget.profile.firstName ?? '');
    _lastName = TextEditingController(text: widget.profile.lastName ?? '');
    _height = TextEditingController(
      text: widget.profile.heightCm == null
          ? ''
          : _fmt(widget.profile.heightCm!),
    );
    _age = TextEditingController(
      text: widget.profile.age?.toString() ?? '',
    );
    _gender = widget.profile.gender;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _height.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final fn = _firstName.text.trim();
    final ln = _lastName.text.trim();
    final updated = UserProfile(
      id: widget.profile.id,
      firstName: fn.isEmpty ? null : fn,
      lastName: ln.isEmpty ? null : ln,
      heightCm: _height.text.trim().isEmpty
          ? null
          : Validators.parseDecimal(_height.text.trim()),
      age: _age.text.trim().isEmpty ? null : int.parse(_age.text.trim()),
      gender: _gender,
    );
    setState(() => _saving = true);
    try {
      await _repo.save(updated);
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
                'Mi perfil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Personaliza tu experiencia',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstName,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    Validators.shortTextMaxLength,
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastName,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    Validators.shortTextMaxLength,
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _height,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Estatura (cm)',
                  prefixIcon: Icon(Icons.height),
                ),
                validator: (v) => Validators.height(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _age,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Edad (años)',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                validator: (v) => Validators.age(v),
              ),
              const SizedBox(height: 16),
              const Text('Sexo (opcional)'),
              const SizedBox(height: 8),
              SegmentedButton<String?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('—')),
                  ButtonSegment(value: 'M', label: Text('Masculino')),
                  ButtonSegment(value: 'F', label: Text('Femenino')),
                ],
                selected: {_gender},
                onSelectionChanged: (s) => setState(() => _gender = s.first),
              ),
              const SizedBox(height: 24),
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
