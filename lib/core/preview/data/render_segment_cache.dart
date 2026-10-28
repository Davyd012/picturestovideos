import 'dart:async';
import 'dart:io';

import 'package:picturestovideos/core/preview/data/source_content_fingerprint.dart';
import 'package:picturestovideos/core/preview/domain/render_cancellation.dart';

/// Bounds only this app's generated segment files. Active inputs are pinned.
class RenderSegmentCache {
  RenderSegmentCache(this.directory, {this.maxBytes = 512 * 1024 * 1024});
  final Directory directory;
  final int maxBytes;
  static final Map<String, int> _pins = {};
  static final Map<String, Future<void>> _artifactLocks = {};
  // Accept the previous 16-character keys so old cache files remain eligible
  // for eviction after switching to SHA-256 names.
  static final _fileName = RegExp(
    r'^([0-9a-f]{16}(?:[0-9a-f]{48})?\.(?:mp4|png))(?:\.sha256)?$',
  );
  static final _digestPattern = RegExp(r'^[0-9a-f]{64}$');
  static final _stagedChecksumName = RegExp(
    r'^[0-9a-f]{16}(?:[0-9a-f]{48})?\.(?:mp4|png)\.sha256\.\d+\.\d+\.tmp$',
  );
  static const _stagedChecksumGracePeriod = Duration(minutes: 5);

  String _key(String path) {
    final uri = File(path).absolute.uri.normalizePath().toString();
    return Platform.isWindows ? uri.toLowerCase() : uri;
  }

  void pin(String path) {
    final key = _key(path);
    _pins[key] = (_pins[key] ?? 0) + 1;
  }

  void unpin(String path) {
    final key = _key(path);
    final count = _pins[key] ?? 0;
    if (count <= 1) {
      _pins.remove(key);
    } else {
      _pins[key] = count - 1;
    }
  }

  Future<T> withArtifactLock<T>(
    File file, {
    required Future<T> Function() action,
    RenderCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    final key = _key(file.path);
    final previous = _artifactLocks[key] ?? Future<void>.value();
    final release = Completer<void>();
    final releaseFuture = release.future;
    _artifactLocks[key] = releaseFuture;
    var acquired = false;
    try {
      await Future.any<void>([
        previous,
        if (cancellation != null) cancellation.whenCancelled,
      ]);
      cancellation?.throwIfCancelled();
      acquired = true;
      return await action();
    } finally {
      if (acquired) {
        release.complete();
        if (identical(_artifactLocks[key], releaseFuture)) {
          _artifactLocks.remove(key);
        }
      } else {
        previous.whenComplete(() {
          if (!release.isCompleted) release.complete();
          if (identical(_artifactLocks[key], releaseFuture)) {
            _artifactLocks.remove(key);
          }
        });
      }
    }
  }

  Future<void> touch(File file) async {
    for (final candidate in [file, _checksumFile(file)]) {
      try {
        await candidate.setLastModified(DateTime.now());
      } on FileSystemException {
        /* A competing render may remove it. */
      }
    }
  }

  Future<bool> isValid(File file, {void Function()? onChunk}) async {
    try {
      if (!await file.exists()) return false;
      final checksumFile = _checksumFile(file);
      if (!await checksumFile.exists()) return false;
      final expected = (await checksumFile.readAsString()).trim();
      if (!_digestPattern.hasMatch(expected)) return false;
      return expected == await sourceContentFingerprint(file, onChunk: onChunk);
    } on FileSystemException {
      return false;
    }
  }

  Future<void> remove(File file) async {
    for (final candidate in [file, _checksumFile(file)]) {
      if (await candidate.exists()) await candidate.delete();
    }
  }

  Future<void> publish(File source, File destination) async {
    try {
      await source.rename(destination.path);
    } on FileSystemException {
      if (!await destination.exists()) rethrow;
      if (await source.exists()) await source.delete();
    }

    final checksum = await sourceContentFingerprint(destination);
    final checksumFile = _checksumFile(destination);
    if (await checksumFile.exists()) {
      final existing = (await checksumFile.readAsString()).trim();
      if (existing == checksum) return;
      await checksumFile.delete();
    }

    final stagedChecksum = File(
      '${checksumFile.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await stagedChecksum.writeAsString(checksum, flush: true);
      await stagedChecksum.rename(checksumFile.path);
    } on FileSystemException {
      if (!await checksumFile.exists() ||
          (await checksumFile.readAsString()).trim() != checksum) {
        rethrow;
      }
    } finally {
      if (await stagedChecksum.exists()) await stagedChecksum.delete();
    }
  }

  Future<void> prune() async {
    if (!await directory.exists()) return;
    final groupedEntries = <String, List<(File, FileStat)>>{};
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (_stagedChecksumName.hasMatch(name)) {
        try {
          final stat = await entity.stat();
          if (DateTime.now().difference(stat.modified) >
              _stagedChecksumGracePeriod) {
            await entity.delete();
          }
        } on FileSystemException {
          /* A later prune can retry. */
        }
        continue;
      }
      final match = _fileName.firstMatch(name);
      if (match == null) continue;
      final basePath = File('${directory.path}/${match.group(1)}').path;
      try {
        groupedEntries.putIfAbsent(basePath, () => []).add((
          entity,
          await entity.stat(),
        ));
      } on FileSystemException {
        continue;
      }
    }
    final groups =
        groupedEntries.entries
            .map((entry) => _CacheEntryGroup(entry.key, entry.value))
            .toList()
          ..sort((a, b) => a.oldestModified.compareTo(b.oldestModified));
    var size = groups.fold<int>(0, (total, group) => total + group.size);
    for (final group in groups) {
      if (size <= maxBytes) break;
      if ((_pins[_key(group.basePath)] ?? 0) > 0) continue;
      for (final (file, stat) in group.files) {
        try {
          await file.delete();
          size -= stat.size;
        } on FileSystemException {
          /* The next cleanup can retry. */
        }
      }
    }
  }

  File _checksumFile(File file) => File('${file.path}.sha256');
}

class _CacheEntryGroup {
  const _CacheEntryGroup(this.basePath, this.files);

  final String basePath;
  final List<(File, FileStat)> files;

  int get size => files.fold<int>(0, (sum, file) => sum + file.$2.size);

  DateTime get oldestModified => files
      .map((file) => file.$2.modified)
      .reduce((oldest, current) => current.isBefore(oldest) ? current : oldest);
}
