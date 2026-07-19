import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/exercise_providers.dart';
import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/user_providers.dart';
import '../../../application/providers/workout_providers.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/workout_template.dart';

class _DraftExercise {
  final String exerciseId;
  int sets;
  int repMin;
  int repMax;
  int restSec;
  double? weightKg;
  int? supersetGroup;

  _DraftExercise({
    required this.exerciseId,
    this.sets = 3,
    this.repMin = 8,
    this.repMax = 12,
    this.restSec = 90,
    this.weightKg,
    this.supersetGroup,
  });
}

String _supersetLabel(int group) => 'Superset ${String.fromCharCode(64 + group)}';

/// Highly-customizable session builder — set count, rep range, rest time,
/// and optional target weight/RPE per exercise (PARTIE 5/6). Pass an
/// existing [template] to edit it, or omit to create a new one.
class TemplateEditorScreen extends ConsumerStatefulWidget {
  final WorkoutTemplate? template;
  const TemplateEditorScreen({super.key, this.template});

  @override
  ConsumerState<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  late final TextEditingController _nameController;
  late List<_DraftExercise> _drafts;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _drafts = widget.template?.exercises
            .map((e) => _DraftExercise(
                  exerciseId: e.exerciseId,
                  sets: e.targetSets,
                  repMin: e.targetRepRange.min,
                  repMax: e.targetRepRange.max,
                  restSec: e.targetRestSec,
                  weightKg: e.targetWeightKg,
                  supersetGroup: e.supersetGroup,
                ))
            .toList() ??
        [];
  }

  int _nextGroupId() {
    final used = _drafts.map((d) => d.supersetGroup).whereType<int>().toSet();
    var g = 1;
    while (used.contains(g)) {
      g++;
    }
    return g;
  }

  void _toggleSuperset(int index) {
    final a = _drafts[index];
    final b = _drafts[index + 1];
    setState(() {
      if (a.supersetGroup != null && a.supersetGroup == b.supersetGroup) {
        a.supersetGroup = null;
        b.supersetGroup = null;
      } else {
        final group = a.supersetGroup ?? b.supersetGroup ?? _nextGroupId();
        a.supersetGroup = group;
        b.supersetGroup = group;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final selected = await context.push<Exercise>('/exercise-picker');
    if (selected == null) return;
    setState(() => _drafts.add(_DraftExercise(exerciseId: selected.id)));
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _drafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute un nom et au moins un exercice.')),
      );
      return;
    }

    final template = WorkoutTemplate(
      id: widget.template?.id ?? '',
      userId: localUserId,
      name: _nameController.text.trim(),
      createdAt: widget.template?.createdAt ?? DateTime.now(),
      lastUsedAt: widget.template?.lastUsedAt,
      exercises: [
        for (var i = 0; i < _drafts.length; i++)
          WorkoutTemplateExercise(
            exerciseId: _drafts[i].exerciseId,
            order: i,
            targetSets: _drafts[i].sets,
            targetRepRange: RepRange(_drafts[i].repMin, _drafts[i].repMax),
            targetRestSec: _drafts[i].restSec,
            targetWeightKg: _drafts[i].weightKg,
            supersetGroup: _drafts[i].supersetGroup,
          ),
      ],
    );

    await ref.read(workoutRepositoryProvider).saveTemplate(template);
    ref.invalidate(templatesProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? 'Nouvelle séance' : 'Modifier la séance'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom de la séance',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_drafts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Ajoute des exercices avec le bouton +')),
            ),
          for (var i = 0; i < _drafts.length; i++) ...[
            _DraftExerciseCard(
              draft: _drafts[i],
              onRemove: () => setState(() => _drafts.removeAt(i)),
              onChanged: () => setState(() {}),
            ),
            if (i < _drafts.length - 1)
              Center(
                child: TextButton.icon(
                  onPressed: () => _toggleSuperset(i),
                  icon: Icon(
                    _drafts[i].supersetGroup != null &&
                            _drafts[i].supersetGroup == _drafts[i + 1].supersetGroup
                        ? Icons.link
                        : Icons.link_off,
                    size: 16,
                  ),
                  label: Text(
                    _drafts[i].supersetGroup != null &&
                            _drafts[i].supersetGroup == _drafts[i + 1].supersetGroup
                        ? 'Superset lié — délier'
                        : 'Lier en superset',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DraftExerciseCard extends ConsumerWidget {
  final _DraftExercise draft;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _DraftExerciseCard({
    required this.draft,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(draft.exerciseId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: exerciseAsync.when(
                    data: (e) => Text(
                      e?.name ?? draft.exerciseId,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    loading: () => const Text('…'),
                    error: (_, __) => Text(draft.exerciseId),
                  ),
                ),
                if (draft.supersetGroup != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(_supersetLabel(draft.supersetGroup!)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                    ),
                  ),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: onRemove),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _Stepper(
                    label: 'Séries',
                    value: draft.sets,
                    onChanged: (v) {
                      draft.sets = v;
                      onChanged();
                    },
                  ),
                ),
                Expanded(
                  child: _Stepper(
                    label: 'Reps min',
                    value: draft.repMin,
                    onChanged: (v) {
                      draft.repMin = v;
                      onChanged();
                    },
                  ),
                ),
                Expanded(
                  child: _Stepper(
                    label: 'Reps max',
                    value: draft.repMax,
                    onChanged: (v) {
                      draft.repMax = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            _Stepper(
              label: 'Repos (sec)',
              value: draft.restSec,
              step: 15,
              onChanged: (v) {
                draft.restSec = v;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final int step;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: () => onChanged((value - step).clamp(0, 999)),
            ),
            Text('$value'),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () => onChanged(value + step),
            ),
          ],
        ),
      ],
    );
  }
}
