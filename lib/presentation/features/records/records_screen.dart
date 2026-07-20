import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/exercise_providers.dart';
import '../../../application/providers/progress_providers.dart';
import '../../../application/providers/user_providers.dart';
import '../../../core/localization/fr_labels.dart';
import '../../../core/units/weight_units.dart';
import '../../../domain/entities/progress.dart';
import '../../../domain/entities/user_profile.dart';

/// Current personal best per exercise/record type — PARTIE 4 "Records".
/// [PersonalRecordDetector] emits one event per historical PR; this screen
/// shows the latest (highest-value) one per (exercise, type) as a chip,
/// and the full progression history when a chip is tapped.
class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(personalRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes records')),
      body: recordsAsync.when(
        data: (records) {
          final bests = _currentBests(records);
          if (bests.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun record pour le moment — termine une séance pour commencer à en établir.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final byExercise = <String, List<PersonalRecord>>{};
          for (final r in records) {
            byExercise.putIfAbsent(r.exerciseId, () => []).add(r);
          }
          final exerciseIds = bests.keys.toList();
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: exerciseIds.length,
            itemBuilder: (context, index) {
              final exerciseId = exerciseIds[index];
              return _ExerciseRecordsCard(
                exerciseId: exerciseId,
                byType: bests[exerciseId]!,
                allRecords: byExercise[exerciseId]!,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Map<String, Map<RecordType, PersonalRecord>> _currentBests(List<PersonalRecord> records) {
    final result = <String, Map<RecordType, PersonalRecord>>{};
    for (final r in records) {
      final byType = result.putIfAbsent(r.exerciseId, () => {});
      final existing = byType[r.type];
      if (existing == null || r.value > existing.value) {
        byType[r.type] = r;
      }
    }
    return result;
  }
}

class _ExerciseRecordsCard extends ConsumerWidget {
  final String exerciseId;
  final Map<RecordType, PersonalRecord> byType;
  final List<PersonalRecord> allRecords;
  const _ExerciseRecordsCard({
    required this.exerciseId,
    required this.byType,
    required this.allRecords,
  });

  void _showHistory(BuildContext context, UnitSystem unit, RecordType type) {
    final history = allRecords.where((r) => r.type == type).toList()
      ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Progression — ${type.labelFr}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final r in history)
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text(
                  type == RecordType.maxReps
                      ? r.value.toStringAsFixed(1)
                      : r.value.displayWeight(unit),
                ),
                subtitle: Text(
                  '${r.achievedAt.day.toString().padLeft(2, '0')}/'
                  '${r.achievedAt.month.toString().padLeft(2, '0')}/${r.achievedAt.year}',
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));
    final unit = ref.watch(unitSystemProvider);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            exerciseAsync.when(
              data: (e) => Text(e?.name ?? exerciseId, style: Theme.of(context).textTheme.titleSmall),
              loading: () => const Text('…'),
              error: (_, __) => Text(exerciseId),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in byType.entries)
                  ActionChip(
                    avatar: Icon(Icons.emoji_events, size: 16, color: scheme.secondary),
                    label: Text(
                      entry.key == RecordType.maxReps
                          ? '${entry.key.labelFr} : ${entry.value.value.toStringAsFixed(1)}'
                          : '${entry.key.labelFr} : ${entry.value.value.displayWeight(unit)}',
                    ),
                    onPressed: () => _showHistory(context, unit, entry.key),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
