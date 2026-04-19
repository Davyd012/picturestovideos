import 'package:picturestovideos/core/audio/domain/beat_map.dart';

class PreprocessingState {
  const PreprocessingState({
    required this.cachedBeatMap,
    required this.lastAction,
  });

  const PreprocessingState.initial()
      : cachedBeatMap = null,
        lastAction = 'Idle';

  final BeatMap? cachedBeatMap;
  final String lastAction;

  bool get hasCachedBeatMap => cachedBeatMap != null;
}
