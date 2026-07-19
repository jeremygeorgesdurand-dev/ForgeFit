import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/user_providers.dart';
import '../../../core/localization/fr_labels.dart';
import '../../../core/units/weight_units.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProvider);
    final unit = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          profileAsync.maybeWhen(
            data: (profile) => profile == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => context.push('/profile/edit', extra: profile),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => profile == null
            ? const Center(child: Text('Aucun profil — complétez l\'onboarding.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(profile.displayName, style: Theme.of(context).textTheme.headlineSmall),
                  Text('Niveau: ${profile.level.labelFr}'),
                  Text(
                    'Objectifs: ${profile.goals.isEmpty ? '—' : profile.goals.map((g) => g.labelFr).join(', ')}',
                  ),
                  if (profile.heightCm != null || profile.weightKg != null)
                    Text(
                      [
                        if (profile.heightCm != null) '${profile.heightCm!.toStringAsFixed(0)} cm',
                        if (profile.weightKg != null) profile.weightKg!.displayWeight(unit),
                      ].join(' · '),
                    ),
                  Text('Fréquence cible: ${profile.weeklyFrequencyTarget}× / semaine'),
                  const SizedBox(height: 24),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.monitor_weight_outlined),
                          title: const Text('Suivi du poids'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/profile/body-metrics'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.history),
                          title: const Text('Historique'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/history'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.emoji_events_outlined),
                          title: const Text('Mes records'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/records'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.workspace_premium_outlined),
                          title: const Text('Succès'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/achievements'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.event_note_outlined),
                          title: const Text('Programmes'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/programs'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: const Text('Paramètres'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/settings'),
                        ),
                      ],
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
