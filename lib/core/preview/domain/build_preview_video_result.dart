import 'dart:typed_data';

class BuildPreviewVideoResult {
  const BuildPreviewVideoResult({
    required this.outputPath,
    required this.signature,
    required this.totalDuration,
    required this.thumbnails,
  });

  final String outputPath;
  final String signature;
  final Duration totalDuration;
  final List<PreviewImageFrame> thumbnails;
}

class PreviewImageFrame {
  const PreviewImageFrame({required this.clipId, required this.bytes});

  final String clipId;
  final Uint8List bytes;
}
