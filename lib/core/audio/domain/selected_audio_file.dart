import 'dart:typed_data';

import 'package:picturestovideos/core/audio/domain/audio_source.dart';

class SelectedAudioFile {
  const SelectedAudioFile({
    required this.source,
    required this.bytes,
  });

  final AudioSource source;
  final Uint8List bytes;
}
