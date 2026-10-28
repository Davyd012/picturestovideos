import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/preview/data/source_content_fingerprint.dart';

void main() {
  test(
    'changes when bytes change at the same path, size, and timestamp',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'source-fingerprint-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/image.bin');
      final originalTimestamp = DateTime(2024, 2, 3, 4, 5, 6);

      await file.writeAsBytes([1, 2, 3, 4, 5, 6, 7, 8]);
      await file.setLastModified(originalTimestamp);
      final originalFingerprint = await sourceContentFingerprint(file);
      final originalStat = await file.stat();

      await file.writeAsBytes([8, 7, 6, 5, 4, 3, 2, 1]);
      await file.setLastModified(originalTimestamp);
      final updatedFingerprint = await sourceContentFingerprint(file);
      final updatedStat = await file.stat();

      expect(updatedStat.size, originalStat.size);
      expect(updatedStat.modified, originalStat.modified);
      expect(updatedFingerprint, isNot(originalFingerprint));
      expect(updatedFingerprint, hasLength(64));
    },
  );

  test('checks cancellation between file chunks', () async {
    final directory = await Directory.systemTemp.createTemp(
      'source-fingerprint-cancel-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/large.bin');
    await file.writeAsBytes(List<int>.filled(1024 * 1024, 7));
    var checkedChunks = 0;

    await expectLater(
      sourceContentFingerprint(
        file,
        onChunk: () {
          checkedChunks++;
          if (checkedChunks == 2) throw const _FingerprintCancelled();
        },
      ),
      throwsA(isA<_FingerprintCancelled>()),
    );
    expect(checkedChunks, 2);
  });
}

class _FingerprintCancelled implements Exception {
  const _FingerprintCancelled();
}
