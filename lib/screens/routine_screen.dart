import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/profile_repository.dart';
import '../utils/constants.dart';
import '../utils/feedback.dart';
import '../widgets/profile_sheet.dart';
import '../widgets/sync_status_button.dart';
import '../widgets/theme_toggle_button.dart';
import 'day_exercises_screen.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  late final ExerciseRepository _exercises;
  late final ProfileRepository _profile;
  late Future<Map<int, List<Exercise>>> _future;
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _exercises = context.read<ExerciseRepository>();
    _profile = context.read<ProfileRepository>();
    _future = _loadAllDays();
    _profileFuture = _loadProfile();
    // Patrón Observer: cualquier pantalla que escriba a través de estos
    // repositorios (agregar un ejercicio, editar el perfil) notifica acá
    // aunque esta pantalla esté "de fondo" dentro del IndexedStack del
    // HomeScreen, sin necesitar reiniciar la app.
    _exercises.addListener(_refresh);
    _profile.addListener(_refresh);
  }

  @override
  void dispose() {
    _exercises.removeListener(_refresh);
    _profile.removeListener(_refresh);
    super.dispose();
  }

  Future<Map<int, List<Exercise>>> _loadAllDays() async {
    final result = <int, List<Exercise>>{};
    for (var day = 1; day <= 7; day++) {
      result[day] = await _exercises.getByDay(day);
    }
    return result;
  }

  Future<UserProfile> _loadProfile() => _profile.get();

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _future = _loadAllDays();
      _profileFuture = _loadProfile();
    });
  }

  /// Saludo según la hora local. Más natural que un "Hola" plano.
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  Future<void> _openProfile(UserProfile profile) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProfileSheet(profile: profile),
    );
    // No hace falta refrescar a mano: si se guardó, ProfileRepository ya
    // notificó a _refresh vía el listener registrado en initState.
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 16,
        title: FutureBuilder<UserProfile>(
          future: _profileFuture,
          builder: (context, snap) {
            final profile = snap.data;
            return _GreetingTitle(
              greeting: _greeting(),
              profile: profile,
              onAvatarTap: profile == null ? null : () => _openProfile(profile),
            );
          },
        ),
        actions: const [SyncStatusButton(), ThemeToggleButton()],
      ),
      body: FutureBuilder<Map<int, List<Exercise>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) showErrorSnackBar(context, snap.error!);
            });
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                FutureBuilder<UserProfile>(
                  future: _profileFuture,
                  builder: (context, profileSnap) {
                    final profile = profileSnap.data;
                    // Sólo se sugiere completar el perfil si ya sabemos que
                    // falta (no mientras carga) — evita un parpadeo.
                    if (profile == null || profile.heightCm != null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProfileNudgeCard(
                        onTap: () => _openProfile(profile),
                      ),
                    );
                  },
                ),
                for (var day = 1; day <= 7; day++)
                  _DayCard(
                    day: day,
                    title: 'Ver detalles',
                    exercises: data[day] ?? const [],
                    isToday: day == today,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DayExercisesScreen(dayOfWeek: day),
                        ),
                      );
                      // Idem: ExerciseRepository ya notificó si hubo cambios.
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Aviso para completar el perfil (estatura, peso, edad) cuando todavía
/// falta — se muestra al entrar a la app hasta que el usuario lo complete,
/// porque el IMC y el seguimiento corporal dependen de esos datos.
class _ProfileNudgeCard extends StatelessWidget {
  const _ProfileNudgeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completa tu perfil',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agrega tu estatura y tu peso para calcular tu IMC y '
                      'llevar un mejor seguimiento.',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: scheme.onTertiaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.title,
    required this.exercises,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final String title;
  final List<Exercise> exercises;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: isToday ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isToday
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        Weekday.shortName(day),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? scheme.onPrimary
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                Weekday.name(day),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'HOY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: scheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                  ],
                ),
                if (exercises.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 56),
                    child: Text(
                      'Sin ejercicios. Toca para agregar.',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 56),
                    child: Text(
                      '${exercises.length} ejercicio${exercises.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header con avatar de iniciales + saludo. Si todavía no hay perfil cargado,
/// muestra un placeholder genérico que invita a configurar el perfil.
class _GreetingTitle extends StatelessWidget {
  const _GreetingTitle({
    required this.greeting,
    required this.profile,
    required this.onAvatarTap,
  });

  final String greeting;
  final UserProfile? profile;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasName = profile?.hasName ?? false;
    final firstName = profile?.firstNameOrEmpty ?? '';
    final initials = profile?.initials ?? '?';

    final mainText = hasName ? '$greeting, $firstName' : '¡Bienvenido!';
    final subText = hasName ? 'Tu rutina semanal' : 'Toca para configurar tu perfil';

    return Row(
      children: [
        // Avatar tappable que abre el perfil
        GestureDetector(
          onTap: onAvatarTap,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              initials,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mainText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subText,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
