import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/exercise_providers.dart';
import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/user_providers.dart';
import '../../../core/localization/fr_labels.dart';
import '../../../domain/entities/user_profile.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  TrainingLevel _level = TrainingLevel.beginner;
  final Set<String> _equipment = {};
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      await ref
          .read(userRepositoryProvider)
          .saveProfile(
            UserProfile(
              id: localUserId,
              displayName: name.isEmpty ? 'Athlète' : name,
              level: _level,
              createdAt: DateTime.now(),
            ),
          )
          .timeout(const Duration(seconds: 10));
      if (_equipment.isNotEmpty) {
        await ref.read(userRepositoryProvider).saveEquipmentProfile(
              EquipmentProfile(userId: localUserId, availableEquipment: _equipment),
            );
      }
      if (mounted) context.go('/library');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de démarrer : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentAsync = ref.watch(equipmentOptionsProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.fitness_center, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Bienvenue sur ForgeFit',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ton prénom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Niveau', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              'Sert à calibrer les futurs programmes suggérés — modifiable plus tard dans ton profil.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final level in TrainingLevel.values)
                  ChoiceChip(
                    label: Text(level.labelFr),
                    selected: _level == level,
                    onSelected: (_) => setState(() => _level = level),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Équipement disponible (optionnel)', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              'Utilisé pour générer des programmes adaptés — modifiable plus tard.',
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Erreur: $err'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _start,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Commencer'),
            ),
          ],
        ),
      ),
    );
  }
}
