import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers/user_providers.dart';
import 'core/theme/app_theme.dart';
import 'presentation/routes/app_router.dart';

void main() {
  runApp(const ProviderScope(child: ForgeFitApp()));
}

class ForgeFitApp extends ConsumerWidget {
  const ForgeFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ForgeFit',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
