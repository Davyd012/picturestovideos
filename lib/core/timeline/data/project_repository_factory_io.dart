import 'package:path_provider/path_provider.dart';
import 'package:picturestovideos/core/timeline/application/project_serializer.dart';
import 'package:picturestovideos/core/timeline/data/file_project_repository.dart';
import 'package:picturestovideos/core/timeline/data/project_repository_contract.dart';

ProjectRepository createProjectRepository(ProjectSerializer serializer) =>
    FileProjectRepository(
      serializer: serializer,
      supportDirectory: getApplicationSupportDirectory,
    );
