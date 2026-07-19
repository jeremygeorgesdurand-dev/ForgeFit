/// Internal normalized muscle taxonomy.
///
/// The exercises dataset uses free-text muscle/bodyPart strings that vary in
/// naming. Every raw value is mapped to one of these at ingestion time so the
/// rest of the app never depends on the dataset's vocabulary.
enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  core,
  quads,
  hamstrings,
  glutes,
  calves,
  fullBody,
  unknown;

  /// Mapping validated against the real distinct `target` (primary),
  /// `muscle_group` (synergist), and `body_part` (fallback) values found in
  /// the 1324-row exercises-dataset (data/exercises.json).
  static MuscleGroup fromRaw(String raw) {
    final normalized = raw.trim().toLowerCase();
    const mapping = <String, MuscleGroup>{
      // target / muscle_group values
      'pectorals': MuscleGroup.chest,
      'chest': MuscleGroup.chest,
      'lats': MuscleGroup.back,
      'latissimus dorsi': MuscleGroup.back,
      'upper back': MuscleGroup.back,
      'lower back': MuscleGroup.back,
      'traps': MuscleGroup.back,
      'trapezius': MuscleGroup.back,
      'rhomboids': MuscleGroup.back,
      'spine': MuscleGroup.back,
      'delts': MuscleGroup.shoulders,
      'deltoids': MuscleGroup.shoulders,
      'shoulders': MuscleGroup.shoulders,
      'rotator cuff': MuscleGroup.shoulders,
      'levator scapulae': MuscleGroup.shoulders,
      'serratus anterior': MuscleGroup.shoulders,
      'biceps': MuscleGroup.biceps,
      'triceps': MuscleGroup.triceps,
      'forearms': MuscleGroup.forearms,
      'wrist extensors': MuscleGroup.forearms,
      'wrist flexors': MuscleGroup.forearms,
      'wrists': MuscleGroup.forearms,
      'hands': MuscleGroup.forearms,
      'abs': MuscleGroup.core,
      'abdominals': MuscleGroup.core,
      'obliques': MuscleGroup.core,
      'core': MuscleGroup.core,
      'hip flexors': MuscleGroup.core,
      'quads': MuscleGroup.quads,
      'quadriceps': MuscleGroup.quads,
      'abductors': MuscleGroup.quads,
      'adductors': MuscleGroup.quads,
      'hamstrings': MuscleGroup.hamstrings,
      'glutes': MuscleGroup.glutes,
      'calves': MuscleGroup.calves,
      'soleus': MuscleGroup.calves,
      'ankles': MuscleGroup.calves,
      'ankle stabilizers': MuscleGroup.calves,
      'cardiovascular system': MuscleGroup.fullBody,
      // body_part fallback values
      'back': MuscleGroup.back,
      'cardio': MuscleGroup.fullBody,
      'lower arms': MuscleGroup.forearms,
      'lower legs': MuscleGroup.calves,
      'neck': MuscleGroup.shoulders,
      'upper arms': MuscleGroup.biceps,
      'upper legs': MuscleGroup.quads,
      'waist': MuscleGroup.core,
    };
    return mapping[normalized] ?? MuscleGroup.unknown;
  }
}
