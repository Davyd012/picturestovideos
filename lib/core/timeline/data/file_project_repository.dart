import 'dart:convert';
import 'dart:io';

import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/data/project_repository_contract.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';

typedef ProjectDirectoryProvider = Future<Directory> Function();
typedef ProjectSaveObserver = Future<void> Function(ProjectSaveStage stage);

enum ProjectSaveStage { stagedAndValidated, previousGenerationBackedUp }

/// Stores each project as its own validated JSON file. A previous valid
/// generation remains as a backup until a replacement has been committed.
class FileProjectRepository implements ProjectRepository {
  FileProjectRepository({
    required this.serializer,
    required this.supportDirectory,
    this.saveObserver,
  });

  final ProjectSerializer serializer;
  final ProjectDirectoryProvider supportDirectory;
  final ProjectSaveObserver? saveObserver;
  List<ProjectStorageIssue> _lastLoadIssues = const [];

  @override
  List<ProjectStorageIssue> get lastLoadIssues => _lastLoadIssues;

  Future<Directory> _projectDirectory() async {
    final directory = Directory('${(await supportDirectory()).path}/projects');
    await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<List<ProjectTimeline>> loadAll() async {
    final directory = await _projectDirectory();
    await _removeInterruptedStagingDirectories(directory);
    final entries = await directory.list(followLinks: false).toList();
    final files =
        entries
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final projects = <ProjectTimeline>[];
    final issues = <ProjectStorageIssue>[];

    for (final backup in entries.whereType<File>().where(
      (file) => file.path.endsWith('.json.bak'),
    )) {
      final destination = File(
        backup.path.substring(0, backup.path.length - '.bak'.length),
      );
      if (!await destination.exists()) {
        try {
          final recovered = await _readProject(backup);
          await backup.copy(destination.path);
          projects.add(recovered);
          issues.add(
            ProjectStorageIssue(
              projectFile: destination.uri.pathSegments.last,
              recoveredFromBackup: true,
            ),
          );
        } on Object {
          issues.add(
            ProjectStorageIssue(
              projectFile: destination.uri.pathSegments.last,
              recoveredFromBackup: false,
            ),
          );
        }
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      try {
        projects.add(await _readProject(file));
      } on Object {
        final backup = File('${file.path}.bak');
        try {
          final recovered = await _readProject(backup);
          await _preserveCorruptFile(file);
          await backup.copy(file.path);
          projects.add(recovered);
          issues.add(
            ProjectStorageIssue(
              projectFile: file.uri.pathSegments.last,
              recoveredFromBackup: true,
            ),
          );
        } on Object {
          issues.add(
            ProjectStorageIssue(
              projectFile: file.uri.pathSegments.last,
              recoveredFromBackup: false,
            ),
          );
        }
      }
    }

    _lastLoadIssues = List.unmodifiable(issues);
    return List.unmodifiable(projects);
  }

  @override
  Future<void> save(ProjectTimeline project) async {
    final directory = await _projectDirectory();
    final projectName = _fileNameFor(project.id);
    final destination = File('${directory.path}/$projectName.json');
    final backup = File('${destination.path}.bak');
    final stagingDirectory = await directory.createTemp('pending-');
    final stagedFile = File('${stagingDirectory.path}/project.json');
    var movedExistingToBackup = false;

    try {
      final encoded = jsonEncode(serializer.serialize(project));
      await stagedFile.writeAsString(encoded, flush: true);
      final verified = await _readProject(stagedFile);
      if (verified.id != project.id) {
        throw const FormatException('Staged project identity changed');
      }
      await saveObserver?.call(ProjectSaveStage.stagedAndValidated);

      if (await destination.exists()) {
        await _readProject(destination);
        if (await backup.exists()) await backup.delete();
        await destination.rename(backup.path);
        movedExistingToBackup = true;
      }

      try {
        await saveObserver?.call(ProjectSaveStage.previousGenerationBackedUp);
        await stagedFile.rename(destination.path);
      } on Object {
        if (movedExistingToBackup &&
            !await destination.exists() &&
            await backup.exists()) {
          await backup.rename(destination.path);
        }
        rethrow;
      }
    } finally {
      if (await stagingDirectory.exists()) {
        await stagingDirectory.delete(recursive: true);
      }
    }
  }

  Future<ProjectTimeline> _readProject(File file) async {
    final document = jsonDecode(await file.readAsString());
    if (document is! Map) {
      throw const FormatException('Project document must be an object');
    }
    final project = serializer.deserialize(Map<String, Object?>.from(document));
    if (project.id.isEmpty) {
      throw const FormatException('Project identity is missing');
    }
    return project;
  }

  Future<void> _preserveCorruptFile(File file) async {
    if (!await file.exists()) return;
    final suffix = DateTime.now().microsecondsSinceEpoch;
    await file.rename('${file.path}.corrupt-$suffix');
  }

  Future<void> _removeInterruptedStagingDirectories(Directory directory) async {
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is Directory &&
          entry.uri.pathSegments.any((part) => part.startsWith('pending-'))) {
        try {
          await entry.delete(recursive: true);
        } on FileSystemException {
          // A later load can retry cleanup if the operating system holds it.
        }
      }
    }
  }

  String _fileNameFor(String id) {
    final bytes = utf8.encode(id);
    final encoded = base64Url.encode(bytes).replaceAll('=', '');
    // Shorten paths while retaining deterministic identity for ordinary ids.
    if (encoded.length <= 96) return encoded;
    var hash = 0xcbf29ce484222325;
    for (final byte in bytes) {
      hash = ((hash ^ byte) * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return 'project-${hash.toRadixString(16)}';
  }
}
