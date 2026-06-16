import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/timeline/application/event_runner.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/core/timeline/domain/event_execution.dart';

final runEventUseCaseProvider = Provider<RunEventUseCase>(
  (ref) => RunEventUseCase(eventRunner: ref.watch(eventRunnerProvider)),
);

class RunEventUseCase {
  const RunEventUseCase({required EventRunner eventRunner})
    : this._(eventRunner);

  const RunEventUseCase._(this._eventRunner);

  final EventRunner _eventRunner;

  EventExecution call({
    required BeatEvent event,
    required Duration executedAt,
  }) {
    return _eventRunner.run(event: event, executedAt: executedAt);
  }
}
