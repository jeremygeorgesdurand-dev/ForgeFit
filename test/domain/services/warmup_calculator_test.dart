import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/domain/services/warmup_calculator.dart';

void main() {
  test('suggests no warm-up for light working weights', () {
    expect(WarmupCalculator.suggest(20), isEmpty);
  });

  test('suggests an ascending ramp below the working weight', () {
    final suggestions = WarmupCalculator.suggest(100);
    expect(suggestions, isNotEmpty);
    for (var i = 0; i < suggestions.length; i++) {
      expect(suggestions[i].weightKg, lessThan(100));
      if (i > 0) {
        expect(suggestions[i].weightKg, greaterThan(suggestions[i - 1].weightKg));
      }
    }
  });

  test('rounds suggested weights to the nearest 2.5kg plate increment', () {
    final suggestions = WarmupCalculator.suggest(83);
    for (final s in suggestions) {
      expect(s.weightKg % 2.5, closeTo(0, 0.001));
    }
  });
}
