import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';
import '../widgets/profile_sheet.dart';
import '../widgets/theme_toggle_button.dart';
import 'day_exercises_screen.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  final _db = DatabaseHelper.instance;
  late Future<Map<int, List<Exercise>>> _future;
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _future = _loadAllDays();
    _profileFuture = _db.getProfile();
  }

  Future<Map<int, List<Exercise>>> _loadAllDays() async {
    final result = <int, List<Exercise>>{};
    for (var day = 1; day <= 7; day++) {
      result[day] = await _db.getExercisesByDay(day);
    }
    return result;
  }

  void _refresh() {
    setState(() {
      _future = _loadAllDays();
      _profileFuture = _db.getProfile();
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
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProfileSheet(profile: profile),
    );
    if (saved == true) _refresh();
  }

  static const _dayTitles = {
    1: 'Push + Cardio',
    2: 'Legs + Abs',
    3: 'Descanso o actividad libre',
    4: 'Pull + Cardio',
    5: 'Legs + Abs',
    6: 'Trote / Cardio opcional',
    7: 'Descanso',
  };

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
        actions: const [ThemeToggleButton()],
      ),
      body: FutureBuilder<Map<int, List<Exercise>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: 7,
            itemBuilder: (context, i) {
              final day = i + 1;
              final exercises = data[day] ?? const [];
              final isToday = day == today;
              return _DayCard(
                day: day,
                //title: _dayTitles[day] ?? '',
                title: 'Ver detalles',
                exercises: exercises,
                isToday: isToday,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DayExercisesScreen(dayOfWeek: day),
                    ),
                  );
                  _refresh();
                },
              );
            },
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
    final subText = hasName ? 'Tu rutina semanal' : 'Tocá para configurar tu perfil';

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