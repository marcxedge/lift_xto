import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';
import '../sync/auth_repository.dart';
import '../utils/feedback.dart';
import '../utils/validators.dart';

/// Configuración de perfil obligatoria la primera vez que se entra a la
/// app (sin estatura cargada). La muestra [ProfileGate] en vez de
/// [HomeScreen] hasta que se guarda; a partir de ahí, el resto de la app
/// (IMC, seguimiento corporal) ya tiene los datos que necesita.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ProfileRepository _repo;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _height;
  DateTime? _birthDate;
  String? _gender;
  bool _saving = false;
  bool _birthDateTouched = false;

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
    _birthDate = widget.profile.birthDate;
    _gender = widget.profile.gender;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - Validators.ageMax, now.month, now.day),
      lastDate: DateTime(now.year - Validators.ageMin, now.month, now.day),
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
      _formKey.currentState?.validate();
    }
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    if (!formOk || _birthDate == null) {
      setState(() => _birthDateTouched = true); // recién ahora se marca error
      return;
    }
    final updated = UserProfile(
      id: widget.profile.id,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      heightCm: Validators.parseDecimal(_height.text.trim()),
      birthDate: _birthDate,
      gender: _gender,
    );
    setState(() => _saving = true);
    try {
      await _repo.save(updated);
      // No hace falta navegar: ProfileGate escucha ProfileRepository y en
      // cuanto ve heightCm cargado cambia solo a HomeScreen.
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await context.read<AuthRepository>().signOut();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Completa tu perfil'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.badge_outlined, color: scheme.primary, size: 40),
              const SizedBox(height: 12),
              Text(
                'Antes de empezar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Necesitamos estos datos para calcular tu IMC y llevar un '
                'seguimiento útil de tu progreso. Puedes editarlos cuando '
                'quieras desde Cuerpo → Editar.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
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
                validator: Validators.requiredText,
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
                validator: Validators.requiredText,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _height,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Estatura (cm)',
                  prefixIcon: Icon(Icons.height),
                ),
                validator: (v) => Validators.height(v, required: true),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickBirthDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de nacimiento',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    errorText: _birthDateTouched && _birthDate == null
                        ? 'Selecciona una fecha'
                        : null,
                  ),
                  child: Text(
                    _birthDate == null
                        ? 'Toca para seleccionar'
                        : DateFormat('d MMMM yyyy', 'es').format(_birthDate!),
                    style: _birthDate == null
                        ? TextStyle(color: scheme.onSurfaceVariant)
                        : null,
                  ),
                ),
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
              const SizedBox(height: 28),
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
                      : const Icon(Icons.check),
                  label: const Text('Continuar'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _saving ? null : _signOut,
                  child: const Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
