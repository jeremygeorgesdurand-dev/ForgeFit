import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/achievement_providers.dart';
import '../../../application/providers/body_metrics_providers.dart';
import '../../../application/providers/exercise_providers.dart';
import '../../../application/providers/progress_providers.dart';
import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/training_program_providers.dart';
import '../../../application/providers/user_providers.dart';
import '../../../application/providers/workout_providers.dart';
import '../../../data/services/backup_codec.dart';
import '../../../domain/entities/user_profile.dart';
import '../../widgets/confirm_dialog.dart';

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
      themeMode: profile.themeMode,
    );
    await ref.read(userRepositoryProvider).saveProfile(updated);
    ref.invalidate(currentUserProvider);
  }

  Future<void> _setThemeMode(WidgetRef ref, UserProfile profile, AppThemeMode mode) async {
    if (profile.themeMode == mode) return;
    final updated = UserProfile(
      id: profile.id,
      displayName: profile.displayName,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      birthDate: profile.birthDate,
      level: profile.level,
      goals: profile.goals,
      preferredUnits: profile.preferredUnits,
      weeklyFrequencyTarget: profile.weeklyFrequencyTarget,
      createdAt: profile.createdAt,
      themeMode: mode,
    );
    await ref.read(userRepositoryProvider).saveProfile(updated);
    ref.invalidate(currentUserProvider);
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref, UserProfile? profile) async {
    final equipment = await ref.read(userRepositoryProvider).getEquipmentProfile(localUserId);
    final templates = await ref.read(workoutRepositoryProvider).getTemplates(localUserId);
    final history = await ref.read(workoutRepositoryProvider).getHistory(localUserId, limit: 10000);
    final programs = await ref.read(trainingProgramRepositoryProvider).getPrograms(localUserId);
    final bodyMetrics = await ref.read(bodyMetricsRepositoryProvider).getHistory(localUserId, limit: 10000);
    final favoriteIds = await ref.read(favoritesRepositoryProvider).getFavoriteExerciseIds(localUserId);

    final json = const JsonEncoder.withIndent('  ').convert(
      BackupCodec.encode(
        BackupData(
          profile: profile,
          equipmentProfile: equipment,
          templates: templates,
          sessions: history,
          trainingPrograms: programs,
          bodyMetrics: bodyMetrics,
          favoriteExerciseIds: favoriteIds.toList(),
        ),
      ),
    );
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

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final clipboard = await Clipboard.getData('text/plain');
    if (clipboard?.text != null && clipboard!.text!.trim().startsWith('{')) {
      controller.text = clipboard.text!;
    }
    if (!context.mounted) return;

    final json = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer des données'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Colle ici le JSON exporté depuis Export des données',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    if (json == null || json.trim().isEmpty) return;

    BackupData data;
    try {
      data = BackupCodec.decode(jsonDecode(json) as Map<String, dynamic>, userId: localUserId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('JSON invalide : $e')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final confirmed = await confirmDialog(
      context,
      title: 'Importer ces données ?',
      message: 'Profil, ${data.templates.length} séance(s), ${data.sessions.length} entrée(s) '
          'd\'historique, ${data.trainingPrograms.length} programme(s) et ${data.bodyMetrics.length} '
          'mesure(s) seront fusionnés avec ce qui existe déjà (mêmes ids = remplacés).',
      confirmLabel: 'Importer',
    );
    if (!confirmed) return;

    if (data.profile != null) {
      await ref.read(userRepositoryProvider).saveProfile(data.profile!);
    }
    if (data.equipmentProfile != null) {
      await ref.read(userRepositoryProvider).saveEquipmentProfile(data.equipmentProfile!);
    }
    for (final template in data.templates) {
      await ref.read(workoutRepositoryProvider).saveTemplate(template);
    }
    for (final session in data.sessions) {
      await ref.read(workoutRepositoryProvider).importSession(session);
    }
    for (final program in data.trainingPrograms) {
      await ref.read(trainingProgramRepositoryProvider).saveProgram(program);
    }
    for (final metric in data.bodyMetrics) {
      await ref.read(bodyMetricsRepositoryProvider).logMetric(metric);
    }
    final alreadyFavorited = await ref.read(favoritesRepositoryProvider).getFavoriteExerciseIds(localUserId);
    for (final exerciseId in data.favoriteExerciseIds) {
      if (!alreadyFavorited.contains(exerciseId)) {
        await ref.read(favoritesRepositoryProvider).toggleFavorite(localUserId, exerciseId);
      }
    }

    ref.invalidate(currentUserProvider);
    ref.invalidate(templatesProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(personalRecordsProvider);
    ref.invalidate(muscleGroupScoresProvider);
    ref.invalidate(achievementsProvider);
    ref.invalidate(favoriteExerciseIdsProvider);
    ref.invalidate(trainingProgramsProvider);
    ref.invalidate(bodyMetricsHistoryProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import terminé')),
      );
    }
  }

  Future<void> _resetAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Réinitialiser toutes les données ?',
      message: 'Profil, séances, historique, records, succès, mesures — tout sera '
          'définitivement supprimé. Cette action est irréversible.',
      confirmLabel: 'Tout supprimer',
    );
    if (!confirmed) return;

    await ref.read(appDatabaseProvider).resetAllData();
    ref.invalidate(currentUserProvider);
    ref.invalidate(templatesProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(personalRecordsProvider);
    ref.invalidate(muscleGroupScoresProvider);
    ref.invalidate(achievementsProvider);
    ref.invalidate(favoriteExerciseIdsProvider);
    ref.invalidate(trainingProgramsProvider);
    ref.invalidate(bodyMetricsHistoryProvider);

    if (context.mounted) context.go('/onboarding');
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
              title: Text('Apparence'),
              subtitle: Text('Thème clair ou sombre'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<AppThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: AppThemeMode.system,
                    label: Text('Système'),
                    icon: Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment(
                    value: AppThemeMode.light,
                    label: Text('Clair'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: AppThemeMode.dark,
                    label: Text('Sombre'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: {profile?.themeMode ?? AppThemeMode.system},
                onSelectionChanged: profile == null
                    ? null
                    : (selection) => _setThemeMode(ref, profile, selection.first),
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
            ListTile(
              title: const Text('Importer des données'),
              subtitle: const Text('Restaurer depuis un export JSON'),
              trailing: const Icon(Icons.upload_outlined),
              onTap: () => _importData(context, ref),
            ),
            const Divider(),
            const ListTile(
              title: Text('Mentions légales'),
              subtitle: Text(
                'Base d\'exercices : © hasaneyldrm/exercises-dataset (MIT).\n'
                'Médias (images/GIFs) : © Gym visual — https://gymvisual.com/\n'
                'Silhouette musculaire : vulovix/body-muscles (Apache 2.0)',
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(
                'Réinitialiser toutes les données',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text('Supprime définitivement tout ce qui est stocké dans l\'app'),
              trailing: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
              onTap: () => _resetAllData(context, ref),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
