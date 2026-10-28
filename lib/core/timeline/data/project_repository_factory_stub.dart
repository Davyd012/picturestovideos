import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/data/project_repository_contract.dart';
import 'package:picturestovideos/core/timeline/data/shared_preferences_project_repository.dart';

ProjectRepository createProjectRepository(ProjectSerializer serializer) =>
    SharedPreferencesProjectRepository(serializer);
