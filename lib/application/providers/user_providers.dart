import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_profile.dart';
import 'repository_providers.dart';

final currentUserProvider = FutureProvider<UserProfile?>((ref) async {
  return ref.watch(userRepositoryProvider).getCurrentProfile();
});

/// The unit system to use for displaying weights, derived from the current
/// profile (defaults to metric while the profile is loading/absent).
final unitSystemProvider = Provider<UnitSystem>((ref) {
  return ref.watch(currentUserProvider).valueOrNull?.preferredUnits ?? UnitSystem.metric;
});

/// Placeholder single-user id until real auth is wired in (V2, Supabase Auth).
const localUserId = 'local-user';
