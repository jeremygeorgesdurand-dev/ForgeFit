import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/user_providers.dart';
import '../../../domain/entities/user_profile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _setUnit(WidgetRef ref, UserProfile profile, UnitSystem unit) async {
    if (profile.preferredUnits == unit) return;
    final updated = UserProfile(
      id: profile.id,
      displayName: profile.displayName,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      birthDate: profile.birthDate,
      level: profile.level,
      goals: profile.goals,
      preferredUnits: unit,
      weeklyFrequencyTarget: profile.weeklyFrequencyTarget,
      createdAt: profile.createdAt,
    );
    await ref.read(userRepositoryProvider).saveProfile(updated);
    ref.invalidate(currentUserProvider);
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref, UserProfile? profile) async {
    final templates = await ref.read(workoutRepositoryProvider).getTemplates(localUserId);
    final history = await ref.read(workoutRepositoryProvider).getHistory(localUserId, limit: 10000);

    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile == null
          ? null
          : {
              'displayName': profile.displayName,
              'level': profile.level.name,
              'goals': profile.goals.map((g) => g.name).toList(),
              'heightCm': profile.heightCm,
              'weightKg': profile.weightKg,
              'weeklyFrequencyTarget': profile.weeklyFrequencyTarget,
            },
      'templates': templates
          .map((t) => {
                'name': t.name,
                'exercises': t.exercises
                    .map((e) => {
                          'exerciseId': e.exerciseId,
                          'targetSets': e.targetSets,
                          'targetRepRange': '${e.targetRepRange.min}-${e.targetRepRange.max}',
                          'targetRestSec': e.targetRestSec,
                        })
                    .toList(),
              })
          .toList(),
      'sessions': history
          .map((s) => {
                'startedAt': s.startedAt.toIso8601String(),
                'endedAt': s.endedAt?.toIso8601String(),
                'totalVolumeKg': s.totalVolumeKg,
                'exercises': s.exercises
                    .map((e) => {
                          'exerciseId': e.exerciseId,
                          'sets': e.sets
                              .map((set) => {
                                    'reps': set.actualReps,
                                    'weightKg': set.weightKg,
                                    'rpe': set.rpe,
                                    'isWarmup': set.isWarmup,
                                  })
                              .toList(),
                        })
                    .toList(),
              })
          .toList(),
    };

    final json = const JsonEncoder.withIndent('  ').convert(data);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export des données'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(json, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copié dans le presse-papiers')),
                );
              }
            },
            child: const Text('Copier'),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: profileAsync.when(
        data: (profile) => ListView(
          children: [
            const ListTile(
              title: Text('Unités'),
              subtitle: Text('Poids affichés dans l\'app'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<UnitSystem>(
                segments: const [
                  ButtonSegment(value: UnitSystem.metric, label: Text('Métrique (kg)')),
                  ButtonSegment(value: UnitSystem.imperial, label: Text('Impérial (lb)')),
                ],
                selected: {profile?.preferredUnits ?? UnitSystem.metric},
                onSelectionChanged: profile == null
                    ? null
                    : (selection) => _setUnit(ref, profile, selection.first),
              ),
            ),
            const Divider(),
            const ListTile(
              title: Text('Langue'),
              subtitle: Text('Français (langue unique pour l\'instant)'),
              enabled: false,
            ),
            const Divider(),
            ListTile(
              title: const Text('Export des données'),
              subtitle: const Text('Copier ton historique et tes programmes en JSON'),
              trailing: const Icon(Icons.download_outlined),
              onTap: () => _exportData(context, ref, profile),
            ),
            const Divider(),
            const ListTile(
              title: Text('Mentions légales'),
              subtitle: Text(
                'Base d\'exercices : © hasaneyldrm/exercises-dataset (MIT).\n'
                'Médias (images/GIFs) : © Gym visual — https://gymvisual.com/',
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
