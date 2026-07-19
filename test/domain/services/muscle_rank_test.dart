import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/domain/services/muscle_rank.dart';

void main() {
  test('rankForScore maps scores to the right tier boundaries', () {
    expect(rankForScore(0), MuscleRank.iron);
    expect(rankForScore(14.9), MuscleRank.iron);
    expect(rankForScore(15), MuscleRank.bronze);
    expect(rankForScore(34.9), MuscleRank.bronze);
    expect(rankForScore(35), MuscleRank.silver);
    expect(rankForScore(55), MuscleRank.gold);
    expect(rankForScore(75), MuscleRank.platinum);
    expect(rankForScore(90), MuscleRank.diamond);
    expect(rankForScore(100), MuscleRank.diamond);
  });

  test('next is null only for the top tier', () {
    expect(MuscleRank.iron.next, MuscleRank.bronze);
    expect(MuscleRank.platinum.next, MuscleRank.diamond);
    expect(MuscleRank.diamond.next, isNull);
  });
}
