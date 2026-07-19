import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/services/personal_record_detector.dart';
import 'repository_providers.dart';
import 'user_providers.dart';

class LiveSessionState {
  final WorkoutTemplate? template;
  final WorkoutSession? session;
  final int currentExerciseIndex;
  final int completedSetsForCurrentExercise;
  final int restRemainingSec;
  final bool isResting;

  /// Set right after `logSet` detects a new record; consumed and cleared by
  /// the UI once shown (PARTIE 7 — "badges de record").
  final String? recordBanner;

  const LiveSessionState({
    this.template,
    this.session,
    this.currentExerciseIndex = 0,
    this.completedSetsForCurrentExercise = 0,
    this.restRemainingSec = 0,
    this.isResting = false,
    this.recordBanner,
  });

  WorkoutTemplateExercise? get currentTemplateExercise {
    final t = template;
    if (t == null || currentExerciseIndex >= t.exercises.length) return null;
    return t.exercises[currentExerciseIndex];
  }

  bool get isLastExercise =>
      template == null || currentExerciseIndex >= template!.exercises.length - 1;

  LiveSessionState copyWith({
    WorkoutTemplate? template,
    WorkoutSession? session,
    int? currentExerciseIndex,
    int? completedSetsForCurrentExercise,
    int? restRemainingSec,
    bool? isResting,
    String? recordBanner,
    bool clearRecordBanner = false,
  }) {
    return LiveSessionState(
      template: template ?? this.template,
      session: session ?? this.session,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      completedSetsForCurrentExercise:
          completedSetsForCurrentExercise ?? this.completedSetsForCurrentExercise,
      restRemainingSec: restRemainingSec ?? this.restRemainingSec,
      isResting: isResting ?? this.isResting,
      recordBanner: clearRecordBanner ? null : (recordBanner ?? this.recordBanner),
    );
  }
}

/// Drives the live execution screen: current exercise/set, rest countdown,
/// live PR detection, and persistence of each validated set via
/// [WorkoutRepository] (PARTIE 4/7 — "exécution de séance").
class LiveSessionController extends StateNotifier<LiveSessionState> {
  final Ref _ref;
  Timer? _restTimer;
  final _rng = Random();

  LiveSessionController(this._ref) : super(const LiveSessionState());

  Future<void> start({WorkoutTemplate? template}) async {
    final session = await _ref
        .read(workoutRepositoryProvider)
        .startSession(userId: localUserId, templateId: template?.id);
    state = LiveSessionState(template: template, session: session);
  }

  Future<void> logSet({
    required int actualReps,
    required double weightKg,
    double? rpe,
    String? freeExerciseId,
  }) async {
    final currentSession = state.session;
    final templateExercise = state.currentTemplateExercise;
    if (currentSession == null) return;

    final exerciseId = templateExercise?.exerciseId ?? freeExerciseId;
    if (exerciseId == null) return;

    final baseline = await _bestPriorPerformance(exerciseId);

    final setId = '${DateTime.now().microsecondsSinceEpoch}-${_rng.nextInt(99999)}';
    final set = SetLog(
      id: setId,
      setIndex: state.completedSetsForCurrentExercise,
      targetReps: templateExercise?.targetRepRange.max ?? actualReps,
      actualReps: actualReps,
      weightKg: weightKg,
      rpe: rpe,
      completedAt: DateTime.now(),
      restTakenSec: 0,
    );

    final updatedSession = await _ref.read(workoutRepositoryProvider).appendSet(
          sessionId: currentSession.id,
          exerciseId: exerciseId,
          set: set,
        );

    final newCompletedSets = state.completedSetsForCurrentExercise + 1;
    final targetSets = templateExercise?.targetSets ?? newCompletedSets;
    final restSec = templateExercise?.targetRestSec ?? 90;

    final record = _detectRecord(baseline, weightKg: weightKg, actualReps: actualReps);

    state = state.copyWith(
      session: updatedSession,
      completedSetsForCurrentExercise: newCompletedSets,
      recordBanner: record,
    );

    if (newCompletedSets < targetSets) {
      _startRest(restSec);
    }
  }

  /// Best weight and estimated-1RM across this user's completed history for
  /// [exerciseId], ignoring warmup sets — the baseline a new set must beat
  /// to count as a record. Zero means "no prior data", which deliberately
  /// suppresses the very first set of an exercise from being flagged.
  Future<({double bestWeight, double best1RM})> _bestPriorPerformance(String exerciseId) async {
    final history = await _ref.read(workoutRepositoryProvider).getHistory(localUserId, limit: 200);
    double bestWeight = 0;
    double best1RM = 0;
    for (final session in history) {
      if (session.status != SessionStatus.completed) continue;
      for (final se in session.exercises) {
        if (se.exerciseId != exerciseId) continue;
        for (final set in se.sets) {
          if (set.isWarmup) continue;
          if (set.weightKg > bestWeight) bestWeight = set.weightKg;
          final est1RM = PersonalRecordDetector.estimated1RM(set.weightKg, set.actualReps);
          if (est1RM > best1RM) best1RM = est1RM;
        }
      }
    }
    return (bestWeight: bestWeight, best1RM: best1RM);
  }

  String? _detectRecord(
    ({double bestWeight, double best1RM}) baseline, {
    required double weightKg,
    required int actualReps,
  }) {
    if (baseline.bestWeight > 0 && weightKg > baseline.bestWeight) {
      return '🏆 Nouveau record de charge : ${weightKg.toStringAsFixed(1)} kg !';
    }
    final est1RM = PersonalRecordDetector.estimated1RM(weightKg, actualReps);
    if (baseline.best1RM > 0 && est1RM > baseline.best1RM) {
      return '🏆 Nouveau record estimé (1RM) !';
    }
    return null;
  }

  void dismissRecordBanner() {
    state = state.copyWith(clearRecordBanner: true);
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    state = state.copyWith(isResting: true, restRemainingSec: seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.restRemainingSec - 1;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(isResting: false, restRemainingSec: 0);
      } else {
        state = state.copyWith(restRemainingSec: remaining);
      }
    });
  }

  void skipRest() {
    _restTimer?.cancel();
    state = state.copyWith(isResting: false, restRemainingSec: 0);
  }

  void nextExercise() {
    _restTimer?.cancel();
    state = state.copyWith(
      currentExerciseIndex: state.currentExerciseIndex + 1,
      completedSetsForCurrentExercise: 0,
      isResting: false,
      restRemainingSec: 0,
    );
  }

  Future<WorkoutSession?> complete() async {
    _restTimer?.cancel();
    final session = state.session;
    if (session == null) return null;
    final completed = await _ref.read(workoutRepositoryProvider).completeSession(session.id);
    state = const LiveSessionState();
    return completed;
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }
}

final liveSessionControllerProvider =
    StateNotifierProvider<LiveSessionController, LiveSessionState>((ref) {
  return LiveSessionController(ref);
});
