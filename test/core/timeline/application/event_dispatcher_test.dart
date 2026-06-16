import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/timeline/application/event_dispatcher.dart'
    as timeline;
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';

void main() {
  group('EventDispatcher', () {
    test('dispatches due events in order and advances index', () {
      const dispatcher = timeline.EventDispatcher();
      final result = dispatcher.dispatch(
        events: const [
          BeatEvent(time: Duration(milliseconds: 200), type: 'marker'),
          BeatEvent(time: Duration(milliseconds: 500), type: 'marker'),
        ],
        currentTime: const Duration(milliseconds: 210),
        nextEventIndex: 0,
      );

      expect(result.dispatchedEvents.length, 1);
      expect(
        result.dispatchedEvents.first.time,
        const Duration(milliseconds: 200),
      );
      expect(result.nextEventIndex, 1);
    });

    test('does not redispatch already consumed events', () {
      const dispatcher = timeline.EventDispatcher();
      final result = dispatcher.dispatch(
        events: const [
          BeatEvent(time: Duration(milliseconds: 200), type: 'marker'),
          BeatEvent(time: Duration(milliseconds: 500), type: 'marker'),
        ],
        currentTime: const Duration(milliseconds: 520),
        nextEventIndex: 1,
      );

      expect(result.dispatchedEvents.length, 1);
      expect(
        result.dispatchedEvents.first.time,
        const Duration(milliseconds: 500),
      );
      expect(result.nextEventIndex, 2);
    });
  });
}
