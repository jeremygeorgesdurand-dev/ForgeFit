import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgefit/main.dart';

void main() {
  testWidgets('ForgeFit starts on the onboarding screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ForgeFitApp()));
    await tester.pump();

    expect(find.text('Bienvenue sur ForgeFit'), findsOneWidget);
  });
}
