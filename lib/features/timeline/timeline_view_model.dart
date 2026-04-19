import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/audio/domain/beat_map.dart';
import 'package:picturestovideos/core/timeline/application/build_project_timeline_use_case.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/domain/beat_event.dart';
import 'package:picturestovideos/features/timeline/timeline_state.dart';

final timelineViewModelProvider =
    AsyncNotifierProvider.autoDispose<TimelineViewModel, TimelineState>(
  TimelineViewModel.new,
);

class TimelineViewModel extends AsyncNotifier<TimelineState> {
  @override
  Future<TimelineState> build() async {
    return const TimelineState.initial();
  }

  Future<void> buildProjectTimeline({
    required BeatMap beatMap,
    required List<BeatEvent> events,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final project = ref.read(buildProjectTimelineUseCaseProvider).call(
            beatMap: beatMap,
            events: events,
          );
      final serializedProject =
          ref.read(projectSerializerProvider).serialize(project);

      return TimelineState(
        project: project,
        serializedProject: serializedProject,
      );
    });
  }
}
