import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
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

  /// True for one state tick right after the rest countdown hits zero —
  /// consumed and cleared by the UI, same pattern as [recordBanner]. The
  /// controller also fires haptic feedback directly since that doesn't
  /// need the UI at all.
  final bool restJustCompleted;

  /// This-session-only exercise swaps, keyed by template exercise index.
  /// The saved template is never touched — swapping only changes which
  /// exercise the *current* session logs sets against (e.g. equipment is
  /// taken, or an injury rules an exercise out for today).
  final Map<int, String> substitutions;

  const LiveSessionState({
    this.template,
    this.session,
    this.currentExerciseIndex = 0,
    this.completedSetsForCurrentExercise = 0,
    this.restRemainingSec = 0,
    this.isResting = false,
    this.recordBanner,
    this.restJustCompleted = false,
    this.substitutions = const {},
  });

  WorkoutTemplateExercise? get currentTemplateExercise {
    final t = template;
    if (t == null || currentExerciseIndex >= t.exercises.length) return null;
    return t.exercises[currentExerciseIndex];
  }

  /// The exercise actually being trained right now: the substitution for
  /// this slot if one was made, otherwise the template's own exercise.
  String? get effectiveExerciseId =>
      substitutions[currentExerciseIndex] ?? currentTemplateExercise?.exerciseId;

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
    bool? restJustCompleted,
    Map<int, String>? substitutions,
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
      restJustCompleted: restJustCompleted ?? this.restJustCompleted,
      substitutions: substitutions ?? this.substitutions,
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

  /// When the previous set was actually completed — used to compute
  /// [SetLog.restTakenSec] for the next one. Reset whenever there's no
  /// meaningful "rest before this set" (session start, new exercise).
  DateTime? _lastSetCompletedAt;

  /// Warmup sets don't count toward the working-set target, so they need
  /// their own index rather than borrowing [LiveSessionState.completedSetsForCurrentExercise].
  int _warmupSetsForCurrentExercise = 0;

  LiveSessionController(this._ref) : super(const LiveSessionState());

  Future<void> start({WorkoutTemplate? template}) async {
    final session = await _ref
        .read(workoutRepositoryProvider)
        .startSession(userId: localUserId, templateId: template?.id);
    _lastSetCompletedAt = null;
    _warmupSetsForCurrentExercise = 0;
    state = LiveSessionState(template: template, session: session);
  }

  Future<void> logSet({
    required int actualReps,
    required double weightKg,
    double? rpe,
    String? freeExerciseId,
    bool isWarmup = false,
  }) async {
    final currentSession = state.session;
    final templateExercise = state.currentTemplateExercise;
    if (currentSession == null) return;

    final exerciseId = state.effectiveExerciseId ?? freeExerciseId;
    if (exerciseId == null) return;

    // Warmup sets never count as records — they're deliberately submaximal.
    final baseline = isWarmup ? null : await _bestPriorPerformance(exerciseId);

    final now = DateTime.now();
    final restTakenSec =
        _lastSetCompletedAt == null ? 0 : now.difference(_lastSetCompletedAt!).inSeconds;

    final setId = '${now.microsecondsSinceEpoch}-${_rng.nextInt(99999)}';
    final set = SetLog(
      id: setId,
      setIndex: isWarmup ? _warmupSetsForCurrentExercise : state.completedSetsForCurrentExercise,
      targetReps: templateExercise?.targetRepRange.max ?? actualReps,
      actualReps: actualReps,
      weightKg: weightKg,
      rpe: rpe,
      isWarmup: isWarmup,
      completedAt: now,
      restTakenSec: restTakenSec,
    );
    _lastSetCompletedAt = now;

    final updatedSession = await _ref.read(workoutRepositoryProvider).appendSet(
          sessionId: currentSession.id,
          exerciseId: exerciseId,
          set: set,
        );

    if (isWarmup) {
      _warmupSetsForCurrentExercise++;
      state = state.copyWith(session: updatedSession);
      return;
    }

    final newCompletedSets = state.completedSetsForCurrentExercise + 1;
    final targetSets = templateExercise?.targetSets ?? newCompletedSets;
    // Superset members share their round-ending rest with their paired
    // exercise, not between their own sets — a short fixed rest instead.
    final restSec = templateExercise?.supersetGroup != null
        ? min(templateExercise!.targetRestSec, 20)
        : (templateExercise?.targetRestSec ?? 90);

    final record = baseline == null
        ? null
        : _detectRecord(baseline, weightKg: weightKg, actualReps: actualReps);

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

  /// Corrects a typo'd set (weight/reps/warmup flag) without touching
  /// working-set counters — it's a data fix, not a new set.
  Future<void> updateSet(SetLog updatedSet) async {
    final session = state.session;
    if (session == null) return;
    final updated = await _ref
        .read(workoutRepositoryProvider)
        .updateSet(sessionId: session.id, set: updatedSet);
    state = state.copyWith(session: updated);
  }

  /// Removes a mis-logged set. If it was a working (non-warmup) set for the
  /// exercise currently in progress, the "Série X/Y" counter steps back so
  /// the rest timer and target-set logic stay consistent.
  Future<void> deleteSet(SetLog set) async {
    final session = state.session;
    if (session == null) return;
    final updated = await _ref
        .read(workoutRepositoryProvider)
        .deleteSet(sessionId: session.id, setId: set.id);
    final newCompleted = set.isWarmup
        ? state.completedSetsForCurrentExercise
        : max(0, state.completedSetsForCurrentExercise - 1);
    state = state.copyWith(session: updated, completedSetsForCurrentExercise: newCompleted);
  }

  void dismissRecordBanner() {
    state = state.copyWith(clearRecordBanner: true);
  }

  /// Swaps the exercise in the current template slot for [newExerciseId],
  /// for this session only. Resets this slot's working-set counter since
  /// the new exercise has no sets logged yet.
  void substituteExercise(String newExerciseId) {
    if (state.template == null) return;
    _lastSetCompletedAt = null;
    _warmupSetsForCurrentExercise = 0;
    final updated = Map<int, String>.from(state.substitutions);
    updated[state.currentExerciseIndex] = newExerciseId;
    state = state.copyWith(substitutions: updated, completedSetsForCurrentExercise: 0);
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    state = state.copyWith(isResting: true, restRemainingSec: seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.restRemainingSec - 1;
      if (remaining <= 0) {
        timer.cancel();
        HapticFeedback.mediumImpact();
        state = state.copyWith(isResting: false, restRemainingSec: 0, restJustCompleted: true);
      } else {
        state = state.copyWith(restRemainingSec: remaining);
      }
    });
  }

  void dismissRestComplete() {
    state = state.copyWith(restJustCompleted: false);
  }

  void skipRest() {
    _restTimer?.cancel();
    state = state.copyWith(isResting: false, restRemainingSec: 0);
  }

  void nextExercise() {
    _restTimer?.cancel();
    _lastSetCompletedAt = null;
    _warmupSetsForCurrentExercise = 0;
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
