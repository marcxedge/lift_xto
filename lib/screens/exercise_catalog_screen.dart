import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog_exercise.dart';
import '../repositories/exercise_catalog_repository.dart';
import '../utils/muscle_groups.dart';
import '../widgets/catalog_exercise_media.dart';
import '../widgets/muscle_chip.dart';
import '../widgets/state_views.dart';

/// Explorador del catálogo de referencia (~1300 ejercicios): buscar por
/// nombre, filtrar por grupo muscular, y elegir uno para precargar nombre +
/// músculo en `AddEditExerciseScreen`. Al tocar un resultado se abre una
/// vista previa con instrucciones y GIF antes de confirmar.
class ExerciseCatalogScreen extends StatefulWidget {
  const ExerciseCatalogScreen({super.key});

  @override
  State<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends State<ExerciseCatalogScreen> {
  late final ExerciseCatalogRepository _repo;
  final _searchController = TextEditingController();
  Timer? _debounce;
  MuscleGroup? _filter;
  List<CatalogExercise>? _results;

  @override
  void initState() {
    super.initState();
    _repo = context.read<ExerciseCatalogRepository>();
    _runSearch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _runSearch);
  }

  Future<void> _runSearch() async {
    final results = await _repo.search(
      query: _searchController.text,
      muscleGroup: _filter,
    );
    if (mounted) setState(() => _results = results);
  }

  Future<void> _openPreview(CatalogExercise exercise) async {
    final chosen = await Navigator.of(context).push<CatalogExercise>(
      MaterialPageRoute(
        builder: (_) => _CatalogExercisePreview(exercise: exercise),
      ),
    );
    if (chosen != null && mounted) Navigator.of(context).pop(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de ejercicios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar ejercicio...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _runSearch();
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: _filter == null,
                  onTap: () {
                    setState(() => _filter = null);
                    _runSearch();
                  },
                ),
                for (final group in MuscleGroup.values)
                  _FilterChip(
                    label: group.label,
                    selected: _filter == group,
                    onTap: () {
                      setState(() => _filter = group);
                      _runSearch();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: results == null
                ? const LoadingView()
                : results.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.search_off,
                        title: 'Sin resultados',
                        subtitle: 'Prueba con otro nombre o quita el filtro.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: results.length,
                        itemBuilder: (context, i) {
                          final ex = results[i];
                          return _CatalogExerciseTile(
                            exercise: ex,
                            onTap: () => _openPreview(ex),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _CatalogExerciseTile extends StatelessWidget {
  const _CatalogExerciseTile({required this.exercise, required this.onTap});

  final CatalogExercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: CatalogExerciseMedia(fileName: exercise.image),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.nameEs,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.equipmentEs} · ${exercise.bodyPartEs}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (exercise.muscleGroup != null) ...[
                      const SizedBox(height: 6),
                      MuscleChip(group: exercise.muscleGroup!),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vista previa de un ejercicio del catálogo antes de usarlo: GIF animado,
/// instrucciones en español, y botón para confirmar la elección (hace
/// `pop` con el [CatalogExercise] elegido hasta `AddEditExerciseScreen`).
class _CatalogExercisePreview extends StatelessWidget {
  const _CatalogExercisePreview({required this.exercise});

  final CatalogExercise exercise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(exercise.nameEs)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: CatalogExerciseMedia(
                fileName: exercise.gif ?? exercise.image,
                animated: exercise.gif != null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exercise.name,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (exercise.muscleGroup != null)
                MuscleChip(group: exercise.muscleGroup!),
              Chip(label: Text(exercise.equipmentEs)),
              Chip(label: Text(exercise.bodyPartEs)),
            ],
          ),
          if (exercise.instructionsEs.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Cómo hacerlo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (exercise.stepsEs.isNotEmpty)
              ...exercise.stepsEs.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${e.key + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(e.value)),
                        ],
                      ),
                    ),
                  )
            else
              Text(exercise.instructionsEs),
            const SizedBox(height: 12),
            Text(
              '© Gym visual — https://gymvisual.com/',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(exercise),
          icon: const Icon(Icons.check),
          label: const Text('Usar este ejercicio'),
        ),
      ),
    );
  }
}
