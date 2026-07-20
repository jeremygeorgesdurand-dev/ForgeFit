import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/exercise_providers.dart';
import '../../../application/providers/live_session_controller.dart';
import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/training_program_providers.dart';
import '../../../application/providers/user_providers.dart';
import '../../../application/providers/workout_providers.dart';
import '../../../core/localization/fr_labels.dart';
import '../../../domain/entities/ai_program.dart';
import '../../../domain/entities/training_program.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/workout_template.dart';
import '../../widgets/confirm_dialog.dart';
import '../../../domain/services/program_generator.dart';

/// Rule-based program generation only (PARTIE 6) — no LLM. A generated
/// [AIProgram] can be added day-by-day to Mes séances, or saved whole as a
/// [TrainingProgram] so its split stays grouped in "Mes programmes".
class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  TrainingGoal _goal = TrainingGoal.hypertrophy;
  int _frequency = 3;
  final Set<String> _equipment = {};
  AIProgram? _generated;
  bool _savingProgram = false;

  Future<void> _generate() async {
    final exercises = await ref.read(allExercisesProvider.future);
    final profile = await ref.read(currentUserProvider.future);
    final program = ProgramGenerator.generate(
      goal: _goal,
      level: profile?.level ?? TrainingLevel.beginner,
      weeklyFrequency: _frequency,
      availableEquipment: _equipment,
      allExercises: exercises,
    );
    await ref.read(userRepositoryProvider).saveEquipmentProfile(
          EquipmentProfile(userId: localUserId, availableEquipment: _equipment),
        );
    setState(() => _generated = program);
  }

  Future<void> _addDayToTemplates(ProgramDay day) async {
    await ref.read(workoutRepositoryProvider).saveTemplate(
          WorkoutTemplate(
            id: '',
            userId: localUserId,
            name: day.name,
            createdAt: DateTime.now(),
            exercises: day.exercises,
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${day.name}" ajouté à Mes séances')),
    );
  }

  Future<void> _saveWholeProgram() async {
    final generated = _generated;
    if (generated == null) return;
    setState(() => _savingProgram = true);
    try {
      final profile = await ref.read(currentUserProvider.future);
      final templateIds = <String>[];
      for (final day in generated.days) {
        if (day.exercises.isEmpty) continue;
        final saved = await ref.read(workoutRepositoryProvider).saveTemplate(
              WorkoutTemplate(
                id: '',
                userId: localUserId,
                name: '${generated.name} — ${day.name}',
                createdAt: DateTime.now(),
                exercises: day.exercises,
              ),
            );
        templateIds.add(saved.id);
      }
      if (templateIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun jour exploitable à enregistrer.')),
          );
        }
        return;
      }
      await ref.read(trainingProgramRepositoryProvider).saveProgram(
            TrainingProgram(
              id: '',
              userId: localUserId,
              name: generated.name,
              goal: generated.goal,
              level: profile?.level ?? generated.level,
              createdAt: DateTime.now(),
              templateIds: templateIds,
            ),
          );
      ref.invalidate(trainingProgramsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${generated.name}" enregistré dans Mes programmes')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingProgram = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentAsync = ref.watch(equipmentOptionsProvider);
    final savedProgramsAsync = ref.watch(trainingProgramsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Programmes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Objectif', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final goal in TrainingGoal.values)
                ChoiceChip(
                  label: Text(goal.labelFr),
                  selected: _goal == goal,
                  onSelected: (_) => setState(() => _goal = goal),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Fréquence hebdomadaire', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => setState(() => _frequency = (_frequency - 1).clamp(1, 6)),
              ),
              Text('$_frequency× / semaine', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _frequency = (_frequency + 1).clamp(1, 6)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Équipement disponible', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            'Le poids du corps est toujours inclus.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          equipmentAsync.when(
            data: (options) {
              final sorted = [...options]
                ..sort((a, b) => equipmentLabelFr(a).compareTo(equipmentLabelFr(b)));
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final equipment in sorted)
                    FilterChip(
                      label: Text(equipmentLabelFr(equipment)),
                      selected: _equipment.contains(equipment),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _equipment.add(equipment);
                        } else {
                          _equipment.remove(equipment);
                        }
                      }),
                    ),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Erreur: $err'),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Générer le programme'),
          ),
          if (_generated != null) ...[
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(_generated!.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  onPressed: _savingProgram ? null : _saveWholeProgram,
                  icon: _savingProgram
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Enregistrer le programme'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final day in _generated!.days)
              _ProgramDayCard(
                day: day,
                onAdd: () => _addDayToTemplates(day),
              ),
          ],
          const SizedBox(height: 32),
          Text('Mes programmes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          savedProgramsAsync.when(
            data: (programs) => programs.isEmpty
                ? Text(
                    'Aucun programme enregistré pour le moment.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  )
                : Column(children: [for (final p in programs) _SavedProgramCard(program: p)]),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Erreur: $err'),
          ),
        ],
      ),
    );
  }
}

class _ProgramDayCard extends ConsumerWidget {
  final ProgramDay day;
  final VoidCallback onAdd;
  const _ProgramDayCard({required this.day, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day.name, style: Theme.of(context).textTheme.titleSmall),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            if (day.exercises.isEmpty)
              const Text('Pas assez d\'exercices disponibles avec cet équipement.'),
            for (final ex in day.exercises)
              Consumer(
                builder: (context, ref, _) {
                  final exerciseAsync = ref.watch(exerciseByIdProvider(ex.exerciseId));
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: exerciseAsync.when(
                      data: (e) => Text(
                        '${e?.name ?? ex.exerciseId} — ${ex.targetSets}×${ex.targetRepRange.min}-${ex.targetRepRange.max}',
                      ),
                      loading: () => const Text('…'),
                      error: (_, __) => Text(ex.exerciseId),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SavedProgramCard extends ConsumerStatefulWidget {
  final TrainingProgram program;
  const _SavedProgramCard({required this.program});

  @override
  ConsumerState<_SavedProgramCard> createState() => _SavedProgramCardState();
}

class _SavedProgramCardState extends ConsumerState<_SavedProgramCard> {
  bool _expanded = false;

  Future<void> _delete() async {
    final confirmed = await confirmDialog(
      context,
      title: 'Supprimer ce programme ?',
      message: '"${widget.program.name}" sera définitivement supprimé. '
          'Les séances déjà ajoutées à Mes séances resteront disponibles.',
    );
    if (!confirmed) return;
    await ref.read(trainingProgramRepositoryProvider).deleteProgram(widget.program.id);
    ref.invalidate(trainingProgramsProvider);
  }

  Future<void> _start(WorkoutTemplate template) async {
    await ref.read(liveSessionControllerProvider.notifier).start(template: template);
    if (mounted) context.go('/live');
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: widget.program.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer le programme'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == widget.program.name) return;

    await ref.read(trainingProgramRepositoryProvider).saveProgram(
          TrainingProgram(
            id: widget.program.id,
            userId: widget.program.userId,
            name: newName,
            goal: widget.program.goal,
            level: widget.program.level,
            createdAt: widget.program.createdAt,
            templateIds: widget.program.templateIds,
          ),
        );
    ref.invalidate(trainingProgramsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.program.name, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: [
                          Chip(
                            label: Text(widget.program.goal.labelFr),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text(widget.program.level.labelFr),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text('${widget.program.templateIds.length} jours'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Renommer',
                  onPressed: _rename,
                ),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  onPressed: _delete,
                ),
              ],
            ),
            if (_expanded)
              templatesAsync.when(
                data: (templates) {
                  final byId = {for (final t in templates) t.id: t};
                  return Column(
                    children: [
                      for (final id in widget.program.templateIds)
                        if (byId[id] != null)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(byId[id]!.name),
                            subtitle: Text('${byId[id]!.exercises.length} exercices'),
                            onTap: () => context.push<void>(
                              '/builder/${byId[id]!.id}/edit',
                              extra: byId[id],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () => _start(byId[id]!),
                            ),
                          ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
                error: (err, stack) => Text('Erreur: $err'),
              ),
          ],
        ),
      ),
    );
  }
}
