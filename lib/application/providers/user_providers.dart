import 'package:flutter/material.dart';
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

/// Flutter's [ThemeMode] derived from the profile's theme preference
/// (defaults to following the OS while the profile is loading/absent).
final themeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(currentUserProvider).valueOrNull?.themeMode ?? AppThemeMode.system;
  switch (mode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
});

/// Placeholder single-user id until real auth is wired in (V2, Supabase Auth).
const localUserId = 'local-user';
