import '../entities/achievement.dart';
import '../entities/progress.dart';
import '../entities/workout_session.dart';
import 'muscle_rank.dart';
import 'training_streak_calculator.dart';

class AchievementCalculator {
  static Achievement _milestone({
    required String id,
    required AchievementCategory category,
    required String title,
    required String description,
    required double current,
    required double target,
  }) {
    final progress = target == 0 ? 1.0 : (current / target).clamp(0.0, 1.0);
    return Achievement(
      id: id,
      category: category,
      titleFr: title,
      descriptionFr: description,
      unlocked: current >= target,
      progress: progress,
      current: current,
      target: target,
    );
  }

  static Achievement _flag({
    required String id,
    required AchievementCategory category,
    required String title,
    required String description,
    required bool unlocked,
  }) {
    return Achievement(
      id: id,
      category: category,
      titleFr: title,
      descriptionFr: description,
      unlocked: unlocked,
      progress: unlocked ? 1 : 0,
      current: unlocked ? 1 : 0,
      target: 1,
    );
  }

  static List<Achievement> compute({
    required List<WorkoutSession> sessions,
    required List<PersonalRecord> records,
    required List<MuscleGroupScore> muscleScores,
  }) {
    final completed = sessions.where((s) => s.status == SessionStatus.completed).toList();
    final totalSessions = completed.length.toDouble();
    final totalVolumeKg = completed.fold<double>(0, (sum, s) => sum + s.totalVolumeKg);
    final streak = weekStreak(sessions).toDouble();
    final recordsCount = records.length.toDouble();

    final ranks = muscleScores.map((s) => rankForScore(s.score)).toList();
    final hasGold = ranks.any((r) => r.index >= MuscleRank.gold.index);
    final hasDiamond = ranks.any((r) => r == MuscleRank.diamond);
    final allBronzePlus = muscleScores.isNotEmpty && ranks.every((r) => r.index >= MuscleRank.bronze.index);

    return [
      _milestone(
        id: 'sessions_1',
        category: AchievementCategory.sessions,
        title: 'Premier pas',
        description: 'Termine ta première séance.',
        current: totalSessions,
        target: 1,
      ),
      _milestone(
        id: 'sessions_10',
        category: AchievementCategory.sessions,
        title: 'Régulier',
        description: 'Termine 10 séances.',
        current: totalSessions,
        target: 10,
      ),
      _milestone(
        id: 'sessions_50',
        category: AchievementCategory.sessions,
        title: 'Vétéran',
        description: 'Termine 50 séances.',
        current: totalSessions,
        target: 50,
      ),
      _milestone(
        id: 'sessions_100',
        category: AchievementCategory.sessions,
        title: 'Centurion',
        description: 'Termine 100 séances.',
        current: totalSessions,
        target: 100,
      ),
      _milestone(
        id: 'volume_10t',
        category: AchievementCategory.volume,
        title: '10 tonnes soulevées',
        description: 'Cumule 10 000 kg de volume au total.',
        current: totalVolumeKg,
        target: 10000,
      ),
      _milestone(
        id: 'volume_100t',
        category: AchievementCategory.volume,
        title: '100 tonnes soulevées',
        description: 'Cumule 100 000 kg de volume au total.',
        current: totalVolumeKg,
        target: 100000,
      ),
      _milestone(
        id: 'streak_2',
        category: AchievementCategory.streak,
        title: 'Sur la lancée',
        description: '2 semaines d\'affilée avec au moins une séance.',
        current: streak,
        target: 2,
      ),
      _milestone(
        id: 'streak_4',
        category: AchievementCategory.streak,
        title: 'Un mois de rigueur',
        description: '4 semaines d\'affilée avec au moins une séance.',
        current: streak,
        target: 4,
      ),
      _milestone(
        id: 'streak_8',
        category: AchievementCategory.streak,
        title: 'Discipline de fer',
        description: '8 semaines d\'affilée avec au moins une séance.',
        current: streak,
        target: 8,
      ),
      _milestone(
        id: 'records_1',
        category: AchievementCategory.records,
        title: 'Premier record',
        description: 'Bats ton premier record personnel.',
        current: recordsCount,
        target: 1,
      ),
      _milestone(
        id: 'records_10',
        category: AchievementCategory.records,
        title: 'Collectionneur',
        description: 'Bats 10 records personnels.',
        current: recordsCount,
        target: 10,
      ),
      _flag(
        id: 'rank_gold',
        category: AchievementCategory.rank,
        title: 'Rang Or',
        description: 'Atteins le rang Or sur un groupe musculaire.',
        unlocked: hasGold,
      ),
      _flag(
        id: 'rank_diamond',
        category: AchievementCategory.rank,
        title: 'Rang Diamant',
        description: 'Atteins le rang Diamant sur un groupe musculaire.',
        unlocked: hasDiamond,
      ),
      _flag(
        id: 'rank_balanced',
        category: AchievementCategory.rank,
        title: 'Équilibré',
        description: 'Tous tes groupes entraînés sont au moins Bronze.',
        unlocked: allBronzePlus,
      ),
    ];
  }
}
