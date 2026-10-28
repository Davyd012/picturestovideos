import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/preview/data/render_segment_cache.dart';
import 'package:picturestovideos/core/preview/domain/render_cancellation.dart';

void main() {
  test(
    'detects corrupted artifacts and evicts their checksum as a pair',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'render-cache-integrity-test-',
      );
      addTearDown(() async => directory.delete(recursive: true));
      final staging = File('${directory.path}/staged.mp4');
      final key = List<String>.filled(64, 'a').join();
      final artifact = File('${directory.path}/$key.mp4');
      await staging.writeAsBytes(List.filled(32, 1));
      final cache = RenderSegmentCache(directory, maxBytes: 0);

      await cache.publish(staging, artifact);
      final checksum = File('${artifact.path}.sha256');
      expect(await cache.isValid(artifact), isTrue);
      expect(await checksum.exists(), isTrue);

      await artifact.writeAsBytes(List.filled(32, 2));
      expect(await cache.isValid(artifact), isFalse);
      await cache.remove(artifact);
      expect(await artifact.exists(), isFalse);
      expect(await checksum.exists(), isFalse);

      final replacementStaging = File('${directory.path}/replacement.mp4');
      await replacementStaging.writeAsBytes(List.filled(32, 3));
      await cache.publish(replacementStaging, artifact);
      expect(await cache.isValid(artifact), isTrue);

      cache.pin(artifact.path);
      await cache.prune();
      expect(await artifact.exists(), isTrue);
      expect(await checksum.exists(), isTrue);
      cache.unpin(artifact.path);
      await cache.prune();
      expect(await artifact.exists(), isFalse);
      expect(await checksum.exists(), isFalse);
    },
  );

  test(
    'prunes oldest generated files while preserving pinned and unrelated files',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'render-cache-test-',
      );
      addTearDown(() async => directory.delete(recursive: true));
      final old = File('${directory.path}/0000000000000001.mp4');
      final pinned = File('${directory.path}/0000000000000002.mp4');
      final unrelated = File('${directory.path}/other.mp4');
      await old.writeAsBytes(List.filled(8, 1));
      await pinned.writeAsBytes(List.filled(8, 2));
      await unrelated.writeAsBytes(List.filled(8, 3));
      await old.setLastModified(DateTime(2020));
      await pinned.setLastModified(DateTime(2021));
      final cache = RenderSegmentCache(directory, maxBytes: 4);
      cache.pin(pinned.path);
      await cache.prune();
      expect(await old.exists(), isFalse);
      expect(await pinned.exists(), isTrue);
      expect(await unrelated.exists(), isTrue);
      cache.unpin(pinned.path);
      await cache.prune();
      expect(await pinned.exists(), isFalse);
      expect(await unrelated.exists(), isTrue);
    },
  );

  test(
    'prune removes interrupted checksum staging files after the grace period',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'render-cache-staging-cleanup-test-',
      );
      addTearDown(() async => directory.delete(recursive: true));
      final key = List<String>.filled(64, 'c').join();
      final interrupted = File(
        '${directory.path}/$key.mp4.sha256.1234.5678.tmp',
      );
      final active = File('${directory.path}/$key.png.sha256.1234.5679.tmp');
      await interrupted.writeAsString('interrupted');
      await active.writeAsString('active');
      await interrupted.setLastModified(DateTime(2020));

      await RenderSegmentCache(directory).prune();

      expect(await interrupted.exists(), isFalse);
      expect(await active.exists(), isTrue);
    },
  );

  test('cancellation invokes listeners once and rejects further work', () {
    final cancellation = RenderCancellation();
    var calls = 0;
    cancellation.addListener(() => calls++);
    cancellation.cancel();
    cancellation.cancel();
    cancellation.addListener(() => calls++);
    expect(calls, 2);
    expect(cancellation.throwIfCancelled, throwsA(isA<RenderCancelled>()));
  });

  test(
    'cancelling a queued cache render leaves the lock queue intact',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'render-cache-lock-test-',
      );
      addTearDown(() async => directory.delete(recursive: true));
      final cache = RenderSegmentCache(directory);
      final key = List<String>.filled(64, 'b').join();
      final artifact = File('${directory.path}/$key.mp4');
      final firstStarted = Completer<void>();
      final releaseFirst = Completer<void>();
      final thirdStarted = Completer<void>();
      final first = cache.withArtifactLock(
        artifact,
        action: () async {
          firstStarted.complete();
          await releaseFirst.future;
        },
      );
      await firstStarted.future;

      final cancellation = RenderCancellation();
      final cancelledWaiter = cache.withArtifactLock(
        artifact,
        cancellation: cancellation,
        action: () async => fail('cancelled waiter acquired the cache lock'),
      );
      var thirdActionStarted = false;
      final third = cache.withArtifactLock(
        artifact,
        action: () async {
          thirdActionStarted = true;
          thirdStarted.complete();
        },
      );
      cancellation.cancel();

      await expectLater(cancelledWaiter, throwsA(isA<RenderCancelled>()));
      expect(thirdActionStarted, isFalse);
      releaseFirst.complete();
      await Future.wait([first, third]);
      await thirdStarted.future;
      expect(thirdActionStarted, isTrue);
    },
  );
}
