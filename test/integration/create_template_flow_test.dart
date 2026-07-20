import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/application/providers/repository_providers.dart';
import 'package:forgefit/data/datasources/local/app_database.dart';
import 'package:forgefit/main.dart';
import 'package:forgefit/presentation/routes/app_router.dart';

Future<void> _settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('creating a template with one exercise makes it appear in Mes séances', (tester) async {
    appRouter.go('/builder');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase.forTesting(NativeDatabase.memory())),
        ],
        child: const ForgeFitApp(),
      ),
    );
    await _settle(tester);

    expect(find.text('Aucune séance créée pour le moment.'), findsOneWidget);

    // Open the new-template editor.
    await tester.tap(find.byIcon(Icons.add));
    await _settle(tester);
    expect(find.text('Nouvelle séance'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Nom de la séance'), 'Full Body A');

    // Add an exercise via the picker. The dataset (1324 exercises, ~17MB
    // JSON) can take longer than the usual settle window to parse.
    await tester.tap(find.byIcon(Icons.add));
    await _settle(tester, frames: 30);
    expect(find.text('Choisir un exercice'), findsOneWidget);

    await tester.tap(find.byType(ListTile).first);
    await _settle(tester);

    // Back on the editor, with the picked exercise showing as a draft card.
    expect(find.text('Nouvelle séance'), findsOneWidget);

    // Save.
    await tester.tap(find.byIcon(Icons.check));
    await _settle(tester);

    expect(find.text('Full Body A'), findsOneWidget);
    expect(find.text('Aucune séance créée pour le moment.'), findsNothing);
  });
}
