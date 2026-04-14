import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_scheduler/services/quiz_scheduling_service.dart';

// This is a pure UNIT TEST targeting the exact style mentioned in flutter.dev/cookbook/testing/unit
void main() {
  group('ScheduleResult Unit Tests', () {
    test('ScheduleResult initialization assigns correct values', () {
      // Act
      final result = ScheduleResult(
        status: ScheduleStatus.timeConflict, 
        message: 'Conflict with another quiz', 
        maxWorkload: 1
      );

      // Assert
      expect(result.status, ScheduleStatus.timeConflict);
      expect(result.message, 'Conflict with another quiz');
      expect(result.maxWorkload, 1);
    });

    test('ScheduleResult uses default parameters correctly', () {
      // Act
      final result = ScheduleResult(status: ScheduleStatus.ok);

      // Assert
      expect(result.status, ScheduleStatus.ok);
      expect(result.message, '');
      expect(result.maxWorkload, 0);
    });

    test('ScheduleStatus enums parse correctly', () {
      expect(ScheduleStatus.ok.name, 'ok');
      expect(ScheduleStatus.timeConflict.name, 'timeConflict');
      expect(ScheduleStatus.workloadWarning.name, 'workloadWarning');
    });
  });
}
