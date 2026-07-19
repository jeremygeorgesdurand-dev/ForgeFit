import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/user_providers.dart';
import '../../../application/providers/workout_providers.dart';
import '../../../core/units/weight_units.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final unit = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: historyAsync.when(
        data: (sessions) => sessions.isEmpty
            ? const Center(child: Text('Aucune séance terminée pour le moment.'))
            : ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final s = sessions[index];
                  final d = s.startedAt.toLocal();
                  return ListTile(
                    title: Text(
                      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
                    ),
                    subtitle: Text(
                      '${s.exercises.length} exercices · Volume: ${s.totalVolumeKg.displayWeight(unit, decimals: 0)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/history/detail', extra: s),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
