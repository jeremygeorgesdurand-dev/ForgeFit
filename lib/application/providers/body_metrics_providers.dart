import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/progress.dart';
import 'repository_providers.dart';
import 'user_providers.dart';

/// Most recent entries first.
final bodyMetricsHistoryProvider = FutureProvider<List<BodyMetric>>((ref) async {
  return ref.watch(bodyMetricsRepositoryProvider).getHistory(localUserId);
});
