import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/data/project_repository_contract.dart';
import 'package:picturestovideos/core/timeline/data/project_repository_factory.dart'
    as repository_factory;

export 'package:picturestovideos/core/timeline/data/project_repository_contract.dart';
export 'package:picturestovideos/core/timeline/data/shared_preferences_project_repository.dart';

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => repository_factory.createProjectRepository(
    ref.watch(projectSerializerProvider),
  ),
);
