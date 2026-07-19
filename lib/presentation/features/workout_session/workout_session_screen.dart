import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/exercise_providers.dart';
import '../../../application/providers/live_session_controller.dart';
import '../../../application/providers/user_providers.dart';
import '../../../application/providers/workout_providers.dart';
import '../../../core/units/weight_units.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/workout_session.dart';
import '../../../domain/entities/workout_template.dart';
import '../../../domain/services/next_session_suggestion.dart';
import '../../../domain/services/warmup_calculator.dart';

String _supersetLabelFor(int group) => 'Superset ${String.fromCharCode(64 + group)}';

/// Live execution screen: one exercise at a time, rest timer overlay,
/// set validation, and "last time vs today" comparison (PARTIE 7).
class WorkoutSessionScreen extends ConsumerWidget {
  const WorkoutSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveState = ref.watch(liveSessionControllerProvider);

    if (liveState.session == null) {
      return const _TemplatePickerView();
    }

    return _ActiveSessionView(state: liveState);
  }
}

class _TemplatePickerView extends ConsumerWidget {
  const _TemplatePickerView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Démarrer une séance')),
      body: templatesAsync.when(
        data: (templates) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final t in templates)
              Card(
                child: ListTile(
                  title: Text(t.name),
                  subtitle: Text('${t.exercises.length} exercices'),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => ref.read(liveSessionControllerProvider.notifier).start(template: t),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ref.read(liveSessionControllerProvider.notifier).start(),
              icon: const Icon(Icons.fitness_center),
              label: const Text('Séance libre'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}

class _ActiveSessionView extends ConsumerStatefulWidget {
  final LiveSessionState state;
  const _ActiveSessionView({required this.state});

  @override
  ConsumerState<_ActiveSessionView> createState() => _ActiveSessionViewState();
}

class _ActiveSessionViewState extends ConsumerState<_ActiveSessionView> {
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  Exercise? _freeExercise;
  bool _isWarmup = false;
  double? _rpe;
  SetLog? _editingSet;

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickFreeExercise() async {
    final selected = await context.push<Exercise>('/exercise-picker');
    if (selected != null) setState(() => _freeExercise = selected);
  }

  Future<void> _logSet() async {
    final reps = int.tryParse(_repsController.text);
    final weight = double.tryParse(_weightController.text);
    if (reps == null || weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renseigne des reps et un poids valides.')),
      );
      return;
    }

    final editing = _editingSet;
    if (editing != null) {
      await ref.read(liveSessionControllerProvider.notifier).updateSet(
            SetLog(
              id: editing.id,
              setIndex: editing.setIndex,
              targetReps: editing.targetReps,
              actualReps: reps,
              weightKg: weight,
              rpe: _rpe,
              isWarmup: _isWarmup,
              completedAt: editing.completedAt,
              restTakenSec: editing.restTakenSec,
            ),
          );
      setState(() => _editingSet = null);
    } else {
      await ref.read(liveSessionControllerProvider.notifier).logSet(
            actualReps: reps,
            weightKg: weight,
            freeExerciseId: _freeExercise?.id,
            isWarmup: _isWarmup,
            rpe: _rpe,
          );
    }
    _repsController.clear();
    _weightController.clear();
    if (_isWarmup) setState(() => _isWarmup = false);
    if (_rpe != null) setState(() => _rpe = null);
  }

  void _startEditingSet(SetLog set) {
    setState(() {
      _editingSet = set;
      _isWarmup = set.isWarmup;
      _rpe = set.rpe;
      _repsController.text = set.actualReps.toString();
      _weightController.text = set.weightKg.toStringAsFixed(1);
    });
  }

  void _cancelEditingSet() {
    setState(() {
      _editingSet = null;
      _isWarmup = false;
      _rpe = null;
      _repsController.clear();
      _weightController.clear();
    });
  }

  void _applyWarmupSuggestion(WarmupSet suggestion) {
    setState(() {
      _isWarmup = true;
      _weightController.text = suggestion.weightKg.toStringAsFixed(1);
      _repsController.text = suggestion.reps.toString();
    });
  }

  Future<void> _finishSession() async {
    final completed = await ref.read(liveSessionControllerProvider.notifier).complete();
    if (completed != null && mounted) {
      context.push('/live/summary', extra: completed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final templateExercise = state.currentTemplateExercise;
    final isFreeSession = state.template == null;
    final currentExerciseId = templateExercise?.exerciseId ?? _freeExercise?.id;
    final unit = ref.watch(unitSystemProvider);

    WorkoutSessionExercise? currentSessionExercise;
    if (currentExerciseId != null && state.session != null) {
      for (final e in state.session!.exercises) {
        if (e.exerciseId == currentExerciseId) {
          currentSessionExercise = e;
          break;
        }
      }
    }

    ref.listen<LiveSessionState>(liveSessionControllerProvider, (previous, next) {
      if (next.recordBanner != null && next.recordBanner != previous?.recordBanner) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.recordBanner!),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(liveSessionControllerProvider.notifier).dismissRecordBanner();
      }
      if (next.restJustCompleted && !(previous?.restJustCompleted ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repos terminé — série suivante !'),
            duration: Duration(seconds: 2),
          ),
        );
        ref.read(liveSessionControllerProvider.notifier).dismissRestComplete();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(state.template?.name ?? 'Séance libre'),
        actions: [
          TextButton(
            onPressed: _finishSession,
            child: const Text('Terminer'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isFreeSession)
            _FreeExercisePicker(exercise: _freeExercise, onPick: _pickFreeExercise)
          else if (templateExercise != null)
            _CurrentExerciseHeader(exerciseId: templateExercise.exerciseId),
          const SizedBox(height: 8),
          if (templateExercise != null) ...[
            Text(
              'Série ${state.completedSetsForCurrentExercise + 1} / ${templateExercise.targetSets} '
              '· objectif ${templateExercise.targetRepRange.min}-${templateExercise.targetRepRange.max} reps',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (templateExercise.supersetGroup != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 14, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${_supersetLabelFor(templateExercise.supersetGroup!)} — enchaîne avec l\'exercice suivant sans repos complet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ],
                ),
              ),
          ],
          if (currentExerciseId != null)
            _LastPerformanceComparison(
              exerciseId: currentExerciseId,
              targetRepRange: templateExercise?.targetRepRange,
            ),
          if (currentSessionExercise != null && currentSessionExercise.sets.isNotEmpty) ...[
            const SizedBox(height: 12),
            _LoggedSetsList(
              sets: currentSessionExercise.sets,
              unit: unit,
              editingSetId: _editingSet?.id,
              onEdit: _startEditingSet,
              onDelete: (set) =>
                  ref.read(liveSessionControllerProvider.notifier).deleteSet(set),
            ),
          ],
          const SizedBox(height: 16),
          if (!state.isResting &&
              state.completedSetsForCurrentExercise == 0 &&
              currentExerciseId != null)
            _WarmupSuggestionCard(
              exerciseId: currentExerciseId,
              targetWeightKg: templateExercise?.targetWeightKg,
              onApply: _applyWarmupSuggestion,
            ),
          if (state.isResting)
            _RestTimerCard(
              remainingSec: state.restRemainingSec,
              onSkip: () => ref.read(liveSessionControllerProvider.notifier).skipRest(),
            )
          else ...[
            if (_editingSet != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Modification d\'une série',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const Spacer(),
                    TextButton(onPressed: _cancelEditingSet, child: const Text('Annuler')),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Poids (kg)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilterChip(
              avatar: const Icon(Icons.whatshot, size: 16),
              label: const Text('Série d\'échauffement'),
              selected: _isWarmup,
              onSelected: (selected) => setState(() => _isWarmup = selected),
            ),
            const SizedBox(height: 10),
            Text(
              'RPE (difficulté ressentie)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (final value in const [6, 7, 8, 9, 10])
                  ChoiceChip(
                    label: Text('$value'),
                    selected: _rpe == value.toDouble(),
                    onSelected: (selected) =>
                        setState(() => _rpe = selected ? value.toDouble() : null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _logSet,
              icon: Icon(_editingSet != null ? Icons.save : Icons.check),
              label: Text(_editingSet != null ? 'Mettre à jour la série' : 'Valider la série'),
            ),
          ],
          if (!isFreeSession && templateExercise != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: state.isLastExercise
                  ? null
                  : () => ref.read(liveSessionControllerProvider.notifier).nextExercise(),
              icon: const Icon(Icons.skip_next),
              label: const Text('Exercice suivant'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrentExerciseHeader extends ConsumerWidget {
  final String exerciseId;
  const _CurrentExerciseHeader({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));
    return exerciseAsync.when(
      data: (e) => Text(e?.name ?? exerciseId, style: Theme.of(context).textTheme.headlineSmall),
      loading: () => const SizedBox(height: 24),
      error: (_, __) => Text(exerciseId),
    );
  }
}

class _LastPerformanceComparison extends ConsumerWidget {
  final String exerciseId;
  final RepRange? targetRepRange;
  const _LastPerformanceComparison({required this.exerciseId, this.targetRepRange});

  bool _looksLikeMachine(String equipment) {
    const machineKeywords = ['machine', 'smith', 'cable', 'leverage'];
    final lower = equipment.toLowerCase();
    return machineKeywords.any(lower.contains);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastAsync = ref.watch(lastPerformanceForExerciseProvider(exerciseId));
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));
    final unit = ref.watch(unitSystemProvider);

    return lastAsync.when(
      data: (last) {
        if (last == null || last.sets.isEmpty) return const SizedBox.shrink();
        final bestSet = last.sets.reduce((a, b) => a.weightKg >= b.weightKg ? a : b);

        LoadSuggestion? suggestion;
        final range = targetRepRange;
        if (range != null) {
          final equipment = exerciseAsync.valueOrNull?.equipment ?? '';
          suggestion = NextSessionSuggestionService.suggest(
            lastExercise: last,
            targetRepRange: range,
            lastWeightKg: bestSet.weightKg,
            isMachine: _looksLikeMachine(equipment),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Dernière fois : ${bestSet.weightKg.displayWeight(unit)} × ${bestSet.actualReps} reps',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              if (suggestion != null && suggestion.action != SuggestionAction.maintain)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        suggestion.action == SuggestionAction.increaseLoad
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Suggestion : ${suggestion.suggestedWeightKg.displayWeight(unit)} — ${suggestion.rationale}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _LoggedSetsList extends StatelessWidget {
  final List<SetLog> sets;
  final UnitSystem unit;
  final String? editingSetId;
  final ValueChanged<SetLog> onEdit;
  final ValueChanged<SetLog> onDelete;
  const _LoggedSetsList({
    required this.sets,
    required this.unit,
    required this.editingSetId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: [
          for (final set in sets)
            ListTile(
              dense: true,
              tileColor: set.id == editingSetId ? scheme.primary.withValues(alpha: 0.08) : null,
              leading: set.isWarmup
                  ? Icon(Icons.whatshot, size: 18, color: scheme.onSurfaceVariant)
                  : Icon(Icons.check_circle_outline, size: 18, color: scheme.primary),
              title: Text('${set.weightKg.displayWeight(unit)} × ${set.actualReps} reps'),
              subtitle: (set.isWarmup || set.rpe != null)
                  ? Text(
                      [
                        if (set.isWarmup) 'Échauffement',
                        if (set.rpe != null) 'RPE ${set.rpe!.toStringAsFixed(0)}',
                      ].join(' · '),
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => onEdit(set),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
                    onPressed: () => onDelete(set),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WarmupSuggestionCard extends ConsumerWidget {
  final String exerciseId;
  final double? targetWeightKg;
  final ValueChanged<WarmupSet> onApply;
  const _WarmupSuggestionCard({
    required this.exerciseId,
    required this.targetWeightKg,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastAsync = ref.watch(lastPerformanceForExerciseProvider(exerciseId));
    final unit = ref.watch(unitSystemProvider);

    return lastAsync.when(
      data: (last) {
        var reference = targetWeightKg;
        if (reference == null && last != null && last.sets.isNotEmpty) {
          reference = last.sets
              .where((s) => !s.isWarmup)
              .map((s) => s.weightKg)
              .fold<double>(0, (max, w) => w > max ? w : max);
        }
        if (reference == null || reference <= 0) return const SizedBox.shrink();

        final suggestions = WarmupCalculator.suggest(reference);
        if (suggestions.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.whatshot, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Échauffement suggéré',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final suggestion in suggestions)
                        ActionChip(
                          label: Text('${suggestion.weightKg.displayWeight(unit)} × ${suggestion.reps}'),
                          onPressed: () => onApply(suggestion),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _FreeExercisePicker extends StatelessWidget {
  final Exercise? exercise;
  final VoidCallback onPick;
  const _FreeExercisePicker({required this.exercise, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(exercise?.name ?? 'Choisir un exercice'),
        trailing: const Icon(Icons.swap_horiz),
        onTap: onPick,
      ),
    );
  }
}

class _RestTimerCard extends StatelessWidget {
  final int remainingSec;
  final VoidCallback onSkip;
  const _RestTimerCard({required this.remainingSec, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primary.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.timer, size: 32),
            const SizedBox(height: 8),
            Text('Repos — $remainingSec s', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            TextButton(onPressed: onSkip, child: const Text('Passer le repos')),
          ],
        ),
      ),
    );
  }
}
