import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/live_session_controller.dart';
import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/workout_providers.dart';
import '../../../domain/entities/workout_template.dart';

class WorkoutBuilderScreen extends ConsumerWidget {
  const WorkoutBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes séances')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push<void>('/builder/new'),
        child: const Icon(Icons.add),
      ),
      body: templatesAsync.when(
        data: (templates) => templates.isEmpty
            ? const Center(child: Text('Aucune séance créée pour le moment.'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: templates.length,
                itemBuilder: (context, index) => _TemplateCard(template: templates[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final WorkoutTemplate template;
  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(template.name),
        subtitle: Text('${template.exercises.length} exercices'),
        onTap: () => context.push<void>('/builder/${template.id}/edit', extra: template),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Démarrer',
              onPressed: () async {
                await ref.read(liveSessionControllerProvider.notifier).start(template: template);
                if (context.mounted) context.go('/live');
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Supprimer',
              onPressed: () async {
                await ref.read(workoutRepositoryProvider).deleteTemplate(template.id);
                ref.invalidate(templatesProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}
