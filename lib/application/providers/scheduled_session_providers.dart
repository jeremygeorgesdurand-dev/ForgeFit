import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/scheduled_session.dart';
import 'repository_providers.dart';
import 'user_providers.dart';

final scheduledSessionsProvider = FutureProvider<List<ScheduledSession>>((ref) async {
  return ref.watch(scheduledSessionRepositoryProvider).getScheduled(localUserId);
});
