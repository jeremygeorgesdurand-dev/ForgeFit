import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/application/providers/repository_providers.dart';
import 'package:forgefit/data/datasources/local/app_database.dart';
import 'package:forgefit/main.dart';
import 'package:forgefit/presentation/routes/app_router.dart';

void main() {
  testWidgets('completing onboarding lands on the library screen', (tester) async {
    appRouter.go('/onboarding');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase.forTesting(NativeDatabase.memory())),
        ],
        child: const ForgeFitApp(),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Bienvenue sur ForgeFit'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Ton prénom'), 'Jeremy');
    await tester.tap(find.text('Commencer'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Bibliothèque'), findsWidgets);
  });
}
