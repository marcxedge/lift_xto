import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../repositories/exercise_log_repository.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/profile_repository.dart';
import '../utils/constants.dart';
import '../utils/feedback.dart';
import '../utils/responsive.dart';
import '../widgets/app_menu_button.dart';
import '../widgets/profile_sheet.dart';
import '../widgets/sync_status_button.dart';
import 'day_exercises_screen.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  late final ExerciseRepository _exercises;
  late final ProfileRepository _profile;
  late final ExerciseLogRepository _logs;
  late Future<Map<int, List<Exercise>>> _future;
  late Future<UserProfile> _profileFuture;
  late Future<int> _streakFuture;

  @override
  void initState() {
    super.initState();
    _exercises = context.read<ExerciseRepository>();
    _profile = context.read<ProfileRepository>();
    _logs = context.read<ExerciseLogRepository>();
    _future = _loadAllDays();
    _profileFuture = _loadProfile();
    _streakFuture = _logs.currentStreak();
    // Patrón Observer: cualquier pantalla que escriba a través de estos
    // repositorios (agregar un ejercicio, editar el perfil) notifica acá
    // aunque esta pantalla esté "de fondo" dentro del IndexedStack del
    // HomeScreen, sin necesitar reiniciar la app.
    _exercises.addListener(_refresh);
    _profile.addListener(_refresh);
    _logs.addListener(_refresh);
  }

  @override
  void dispose() {
    _exercises.removeListener(_refresh);
    _profile.removeListener(_refresh);
    _logs.removeListener(_refresh);
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
      _streakFuture = _logs.currentStreak();
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
        title: Row(
          children: [
            Expanded(
              child: FutureBuilder<UserProfile>(
                future: _profileFuture,
                builder: (context, snap) {
                  final profile = snap.data;
                  return _GreetingTitle(
                    greeting: _greeting(),
                    profile: profile,
                    onAvatarTap:
                        profile == null ? null : () => _openProfile(profile),
                  );
                },
              ),
            ),
            FutureBuilder<int>(
              future: _streakFuture,
              builder: (context, snap) {
                final streak = snap.data ?? 0;
                if (streak <= 0) return const SizedBox.shrink();
                return _StreakBadge(streak: streak);
              },
            ),
          ],
        ),
        actions: const [SyncStatusButton(), AppMenuButton()],
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
          return Responsive.withMaxWidth(
            context,
            RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  Responsive.horizontalPadding(context),
                  8,
                  Responsive.horizontalPadding(context),
                  24,
                ),
                children: [
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
            ),
          );
        },
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
                              Flexible(
                                child: Text(
                                  Weekday.name(day),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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

/// Racha de días consecutivos entrenados según lo programado en la rutina
/// (ver `computeStreak()` en `lib/utils/streak.dart`). Sólo se muestra si
/// hay racha activa (>0) — no tiene sentido mostrar "0" como si fuera un
/// logro.
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Racha: $streak día${streak == 1 ? '' : 's'} seguidos '
          'entrenando según tu rutina',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 16,
              color: scheme.onTertiaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onTertiaryContainer,
                fontSize: 14,
              ),
            ),
          ],
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
