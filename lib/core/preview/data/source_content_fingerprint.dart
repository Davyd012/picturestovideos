import 'dart:io';

import 'package:crypto/crypto.dart';

/// Returns a content identity that changes even when a file keeps its path,
/// size, and modification time.
Future<String> sourceContentFingerprint(
  File file, {
  void Function()? onChunk,
}) async {
  final digest = await sha256
      .bind(
        file.openRead().map((chunk) {
          onChunk?.call();
          return chunk;
        }),
      )
      .first;
  return digest.toString();
}
