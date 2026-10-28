import 'package:picturestovideos/core/audio/domain/audio_marker_preset.dart';
import 'package:picturestovideos/core/media/domain/saved_image_asset.dart';

class HomeState {
  const HomeState({
    required this.audioPresets,
    required this.imageAssets,
    required this.isOpeningAudio,
    required this.statusCode,
    required this.statusPath,
  });

  const HomeState.initial()
    : audioPresets = const [],
      imageAssets = const [],
      isOpeningAudio = false,
      statusCode = null,
      statusPath = null;

  final List<AudioMarkerPreset> audioPresets;
  final List<SavedImageAsset> imageAssets;
  final bool isOpeningAudio;
  final HomeStatusCode? statusCode;
  final String? statusPath;

  bool get hasSavedAudio => audioPresets.isNotEmpty;
  bool get hasSavedImages => imageAssets.isNotEmpty;
  bool get hasSavedMedia => hasSavedAudio || hasSavedImages;

  HomeState copyWith({
    List<AudioMarkerPreset>? audioPresets,
    List<SavedImageAsset>? imageAssets,
    bool? isOpeningAudio,
    HomeStatusCode? statusCode,
    String? statusPath,
    bool clearStatus = false,
  }) {
    return HomeState(
      audioPresets: audioPresets ?? this.audioPresets,
      imageAssets: imageAssets ?? this.imageAssets,
      isOpeningAudio: isOpeningAudio ?? this.isOpeningAudio,
      statusCode: clearStatus ? null : statusCode ?? this.statusCode,
      statusPath: clearStatus ? null : statusPath ?? this.statusPath,
    );
  }
}

enum HomeStatusCode { missingAudioPath, missingAudioFile, openAudioFailed }
