import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/data/datasources/local/exercises_dataset_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exercises dataset loads directly', () async {
    final stopwatch = Stopwatch()..start();
    final rows = await ExercisesDatasetLoader().load();
    stopwatch.stop();
    // ignore: avoid_print
    print('Loaded ${rows.length} rows in ${stopwatch.elapsedMilliseconds}ms');
    expect(rows, isNotEmpty);
  });
}
