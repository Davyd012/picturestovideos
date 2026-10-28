import 'dart:math';

/// Creates an identity for one use of a media item, independent of its timing.
String newClipId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
