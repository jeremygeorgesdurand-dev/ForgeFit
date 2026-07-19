import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/user_providers.dart';
import '../../../core/localization/fr_labels.dart';
import '../../../domain/entities/user_profile.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  final UserProfile profile;
  const ProfileEditScreen({super.key, required this.profile});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late TrainingLevel _level;
  late Set<TrainingGoal> _goals;
  late int _weeklyFrequencyTarget;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.displayName);
    _heightController = TextEditingController(text: p.heightCm?.toStringAsFixed(0) ?? '');
    _weightController = TextEditingController(text: p.weightKg?.toStringAsFixed(1) ?? '');
    _level = p.level;
    _goals = p.goals.toSet();
    _weeklyFrequencyTarget = p.weeklyFrequencyTarget;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = UserProfile(
        id: widget.profile.id,
        displayName: _nameController.text.trim().isEmpty
            ? widget.profile.displayName
            : _nameController.text.trim(),
        heightCm: double.tryParse(_heightController.text.replaceAll(',', '.')),
        weightKg: double.tryParse(_weightController.text.replaceAll(',', '.')),
        birthDate: widget.profile.birthDate,
        level: _level,
        goals: _goals.toList(),
        preferredUnits: widget.profile.preferredUnits,
        weeklyFrequencyTarget: _weeklyFrequencyTarget,
        createdAt: widget.profile.createdAt,
      );
      await ref.read(userRepositoryProvider).saveProfile(updated);
      ref.invalidate(currentUserProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'enregistrer : $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Prénom', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Taille (cm)', border: OutlineInputBorder()),
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
          const SizedBox(height: 20),
          Text('Niveau', style: Theme.of(context).textTheme.bodySmall),
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
          const SizedBox(height: 20),
          Text('Objectifs', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final goal in TrainingGoal.values)
                FilterChip(
                  label: Text(goal.labelFr),
                  selected: _goals.contains(goal),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _goals.add(goal);
                    } else {
                      _goals.remove(goal);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Fréquence hebdomadaire cible', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => setState(
                  () => _weeklyFrequencyTarget = (_weeklyFrequencyTarget - 1).clamp(1, 7),
                ),
              ),
              Text('$_weeklyFrequencyTarget× / semaine', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(
                  () => _weeklyFrequencyTarget = (_weeklyFrequencyTarget + 1).clamp(1, 7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
