import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/application/providers/repository_providers.dart';
import 'package:forgefit/data/datasources/local/app_database.dart';
import 'package:forgefit/main.dart';
import 'package:forgefit/presentation/routes/app_router.dart';

Future<void> _settle(WidgetTester tester, {int frames = 15}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('starting a free session, logging a set, and finishing reaches the summary', (tester) async {
    appRouter.go('/live');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase.forTesting(NativeDatabase.memory())),
        ],
        child: const ForgeFitApp(),
      ),
    );
    await _settle(tester);

    expect(find.text('Démarrer une séance'), findsOneWidget);
    await tester.tap(find.text('Séance libre'));
    await _settle(tester);

    // Pick a free exercise.
    await tester.tap(find.text('Choisir un exercice'));
    await _settle(tester);
    expect(find.text('Choisir un exercice'), findsWidgets);
    await tester.tap(find.byType(ListTile).first);
    await _settle(tester);

    // Log one working set.
    await tester.enterText(find.widgetWithText(TextField, 'Reps'), '8');
    await tester.enterText(find.widgetWithText(TextField, 'Poids (kg)'), '60');
    await tester.tap(find.text('Valider la série'));
    await _settle(tester);

    // Finish the session.
    await tester.tap(find.text('Terminer'));
    await _settle(tester);

    expect(find.text('Récapitulatif'), findsOneWidget);
    expect(find.text('1'), findsWidgets); // "Exercices" stat tile
  });
}
