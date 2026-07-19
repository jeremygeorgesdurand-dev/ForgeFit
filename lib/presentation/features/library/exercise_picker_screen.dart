import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/exercise_providers.dart';
import '../../../core/localization/fr_labels.dart';
import '../../../domain/entities/exercise.dart';

/// Full-screen exercise picker used by the workout template editor.
/// Returns the selected [Exercise] via `Navigator.pop` / `context.pop`.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir un exercice'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher un exercice…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
        ),
      ),
      body: exercisesAsync.when(
        data: (exercises) {
          final filtered = _query.isEmpty
              ? exercises
              : exercises.where((e) => e.name.toLowerCase().contains(_query)).toList();
          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final e = filtered[index];
              return _PickerTile(exercise: e, onTap: () => Navigator.of(context).pop(e));
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  const _PickerTile({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: exercise.media.imagePath != null
            ? AssetImage(exercise.media.imagePath!)
            : null,
        child: exercise.media.imagePath == null ? const Icon(Icons.fitness_center) : null,
      ),
      title: Text(exercise.name),
      subtitle: Text('${exercise.primaryMuscle.labelFr} · ${equipmentLabelFr(exercise.equipment)}'),
      onTap: onTap,
    );
  }
}
