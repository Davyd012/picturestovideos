import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/preview/data/render_temp_directory_manager.dart';

void main() {
  test(
    'cleans stale interrupted renders and keeps recent/completed outputs',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'render-temp-cleanup-test-',
      );
      addTearDown(() async => root.delete(recursive: true));
      final stale = Directory('${root.path}/picturestovideos-preview-stale');
      final unmarkedInterrupted = Directory(
        '${root.path}/picturestovideos-preview-unmarked',
      );
      final recent = Directory('${root.path}/picturestovideos-preview-recent');
      final completed = Directory(
        '${root.path}/picturestovideos-preview-completed',
      );
      await stale.create();
      await unmarkedInterrupted.create();
      await recent.create();
      await completed.create();
      final staleMarker = File('${stale.path}/.render-in-progress');
      await staleMarker.writeAsString('in-progress');
      await staleMarker.setLastModified(DateTime(2020));
      await File('${stale.path}/partial.mp4').writeAsBytes([1, 2, 3]);
      await File('${unmarkedInterrupted.path}/partial.tmp')
          .writeAsString('part');
      final recentMarker = File('${recent.path}/.render-in-progress');
      await recentMarker.writeAsString('active');
      await recentMarker.setLastModified(
        DateTime.now().add(const Duration(days: 1)),
      );
      await File('${completed.path}/preview.mp4').writeAsBytes([1, 2, 3]);

      final removed = await RenderTempDirectoryManager(
        root,
        staleAfter: Duration.zero,
      ).cleanupAbandoned();

      expect(removed, 2);
      expect(await stale.exists(), isFalse);
      expect(await unmarkedInterrupted.exists(), isFalse);
      expect(await recent.exists(), isTrue);
      expect(await completed.exists(), isTrue);
    },
  );

  test(
    'an active lease stays protected and completed output is retained',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'render-temp-lease-test-',
      );
      addTearDown(() async => root.delete(recursive: true));
      final manager = RenderTempDirectoryManager(root);
      final lease = await manager.create();
      final marker = File('${lease.directory.path}/.render-in-progress');
      await marker.setLastModified(DateTime(2020));

      expect(await manager.cleanupAbandoned(), 0);
      expect(await lease.directory.exists(), isTrue);

      await File('${lease.directory.path}/preview.mp4').writeAsBytes([4, 5, 6]);
      await lease.markCompleted();
      lease.dispose();
      expect(await marker.exists(), isFalse);
      expect(await manager.cleanupAbandoned(), 0);
      expect(await lease.directory.exists(), isTrue);
    },
  );
}
