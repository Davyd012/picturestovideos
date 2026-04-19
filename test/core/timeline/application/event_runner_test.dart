import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/timeline/application/event_runner.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';

void main() {
  group('EventRunner', () {
    test('handles supported event type', () {
      const runner = EventRunner();
      final execution = runner.run(
        event: const BeatEvent(
          time: Duration(milliseconds: 200),
          type: 'marker',
          payload: 'Beat 1',
        ),
        executedAt: const Duration(milliseconds: 210),
      );

      expect(execution.wasHandled, isTrue);
      expect(execution.message, contains('Handled marker'));
    });

    test('marks unknown event type as unhandled', () {
      const runner = EventRunner();
      final execution = runner.run(
        event: const BeatEvent(
          time: Duration(milliseconds: 200),
          type: 'unknown',
        ),
        executedAt: const Duration(milliseconds: 210),
      );

      expect(execution.wasHandled, isFalse);
      expect(execution.message, contains('Unsupported'));
    });
  });
}
