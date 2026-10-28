import 'dart:async';
import 'dart:io';

/// Tracks incomplete preview renders so abandoned work can be cleaned later.
class RenderTempDirectoryManager {
  const RenderTempDirectoryManager(
    this.root, {
    this.staleAfter = const Duration(minutes: 5),
    this.heartbeatInterval = const Duration(minutes: 1),
  });

  static const _directoryPrefix = 'picturestovideos-preview-';
  static const _inProgressMarkerName = '.render-in-progress';
  static final Set<String> _activeDirectories = {};
  static final Set<String> _retainedDirectories = {};

  final Directory root;
  final Duration staleAfter;
  final Duration heartbeatInterval;

  Future<RenderTempDirectoryLease> create() async {
    await root.create(recursive: true);
    try {
      await cleanupAbandoned();
    } on FileSystemException {
      // A cleanup failure must not prevent a new render from starting.
    }

    final directory = await root.createTemp(_directoryPrefix);
    final key = _pathKey(directory.path);
    _activeDirectories.add(key);
    final marker = File('${directory.path}/$_inProgressMarkerName');
    try {
      await marker.writeAsString('in-progress', flush: true);
      return RenderTempDirectoryLease._(
        directory: directory,
        marker: marker,
        key: key,
        heartbeatInterval: heartbeatInterval,
      );
    } catch (_) {
      _activeDirectories.remove(key);
      if (await directory.exists()) await directory.delete(recursive: true);
      rethrow;
    }
  }

  Future<int> cleanupAbandoned() async {
    if (!await root.exists()) return 0;
    final now = DateTime.now();
    var removed = 0;
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = entity.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .last;
      if (!name.startsWith(_directoryPrefix)) continue;
      final key = _pathKey(entity.path);
      if (_activeDirectories.contains(key) ||
          _retainedDirectories.contains(key)) {
        continue;
      }

      final marker = File('${entity.path}/$_inProgressMarkerName');
      try {
        final hasInProgressMarker = await marker.exists();
        if (!hasInProgressMarker) {
          final hasOutput = (await entity.list(followLinks: false).toList())
              .whereType<File>()
              .any((file) => file.path.toLowerCase().endsWith('.mp4'));
          if (hasOutput) continue;
        }
        final lastModified = hasInProgressMarker
            ? await marker.lastModified()
            : (await entity.stat()).modified;
        if (now.difference(lastModified) <= staleAfter) {
          continue;
        }
        await entity.delete(recursive: true);
        removed++;
      } on FileSystemException {
        // The next render can retry cleanup after a transient file lock.
      }
    }
    return removed;
  }

  static String _pathKey(String path) {
    final uri = Directory(path).absolute.uri.normalizePath().toString();
    return Platform.isWindows ? uri.toLowerCase() : uri;
  }
}

class RenderTempDirectoryLease {
  RenderTempDirectoryLease._({
    required this.directory,
    required this._marker,
    required this._key,
    required Duration heartbeatInterval,
  }) {
    _heartbeat = Timer.periodic(heartbeatInterval, (_) async {
      try {
        if (await _marker.exists()) {
          await _marker.setLastModified(DateTime.now());
        }
      } on FileSystemException {
        // Cleanup or shutdown may remove the marker concurrently.
      }
    });
  }

  final Directory directory;
  final File _marker;
  final String _key;
  late final Timer _heartbeat;
  bool _disposed = false;

  Future<void> markCompleted() async {
    RenderTempDirectoryManager._retainedDirectories.add(_key);
    try {
      if (await _marker.exists()) await _marker.delete();
    } on FileSystemException {
      // The completed preview stays retained for this process lifetime.
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _heartbeat.cancel();
    RenderTempDirectoryManager._activeDirectories.remove(_key);
  }
}
