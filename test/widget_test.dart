import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgefit/application/providers/repository_providers.dart';
import 'package:forgefit/data/datasources/local/app_database.dart';
import 'package:forgefit/main.dart';

void main() {
  testWidgets('ForgeFit starts on the onboarding screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(AppDatabase.forTesting(NativeDatabase.memory())),
        ],
        child: const ForgeFitApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Bienvenue sur ForgeFit'), findsOneWidget);
  });
}
