import 'dart:convert';

import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/data/project_repository_contract.dart';
import 'package:picturestovideos/core/timeline/domain/project_timeline.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesProjectRepository implements ProjectRepository {
  const SharedPreferencesProjectRepository(this._serializer);
  final ProjectSerializer _serializer;
  static const _storageKey = 'saved_projects_v1';

  @override
  List<ProjectStorageIssue> get lastLoadIssues => const [];

  @override
  Future<List<ProjectTimeline>> loadAll() async {
    final storage = await SharedPreferences.getInstance();
    final encoded = storage.getString(_storageKey);
    if (encoded == null) return const [];
    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      throw const FormatException('Invalid saved project collection');
    }
    return List.unmodifiable(
      decoded.map(
        (value) =>
            _serializer.deserialize(Map<String, Object?>.from(value as Map)),
      ),
    );
  }

  @override
  Future<void> save(ProjectTimeline project) async {
    final existing = await loadAll();
    final next = [project, ...existing.where((item) => item.id != project.id)];
    final storage = await SharedPreferences.getInstance();
    final saved = await storage.setString(
      _storageKey,
      jsonEncode([for (final item in next) _serializer.serialize(item)]),
    );
    if (!saved) throw StateError('Could not save project');
  }
}
