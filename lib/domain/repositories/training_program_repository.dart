import '../entities/training_program.dart';

abstract class TrainingProgramRepository {
  Future<List<TrainingProgram>> getPrograms(String userId);
  Future<TrainingProgram> saveProgram(TrainingProgram program);
  Future<void> deleteProgram(String programId);
}
