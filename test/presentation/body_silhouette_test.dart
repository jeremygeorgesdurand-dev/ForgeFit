import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/domain/entities/muscle_group.dart';
import 'package:forgefit/domain/entities/progress.dart';
import 'package:forgefit/presentation/features/dashboard/body_silhouette.dart';

void main() {
  testWidgets('renders front and back views and reacts to a tap without throwing', (tester) async {
    final scores = {
      MuscleGroup.chest: MuscleGroupScore(
        userId: 'u',
        muscleGroup: MuscleGroup.chest,
        score: 62,
        confidence: 1,
        lastComputedAt: DateTime(2026, 1, 1),
      ),
      MuscleGroup.back: MuscleGroupScore(
        userId: 'u',
        muscleGroup: MuscleGroup.back,
        score: 40,
        confidence: 0.5,
        lastComputedAt: DateTime(2026, 1, 1),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(children: [BodySilhouette(scores: scores)]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Silhouette musculaire'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tap roughly in the chest area of the front view and make sure
    // hit-testing against the parsed SVG paths doesn't throw.
    final canvasFinder = find.byType(CustomPaint).first;
    await tester.tapAt(tester.getCenter(canvasFinder));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Switch to the back view and confirm it also renders cleanly.
    await tester.tap(find.text('Dos'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
