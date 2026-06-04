import 'package:file_picker/file_picker.dart';
import 'package:picturestovideos/core/logging/app_logger.dart';
import 'package:picturestovideos/features/library/image_file_picker.dart';

class SystemImageFilePicker implements ImageFilePicker {
  const SystemImageFilePicker({required this.logger});

  final AppLogger logger;

  static const _supportedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  @override
  Future<List<PickedImageFile>> pickImageFiles() async {
    logger.info('ImageFilePicker', 'Opening system image picker');

    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      allowedExtensions: _supportedExtensions,
      type: FileType.custom,
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      logger.warning('ImageFilePicker', 'Image pick canceled');
      return const [];
    }

    final pickedFiles = <PickedImageFile>[];
    for (final file in result.files) {
      pickedFiles.add(
        PickedImageFile(
          name: file.name,
          extension: (file.extension ?? '').toLowerCase(),
          size: file.size,
          path: file.path,
          bytes: file.bytes,
        ),
      );
    }

    logger.info(
      'ImageFilePicker',
      'Picked ${pickedFiles.length} image files from system picker',
    );
    return List.unmodifiable(pickedFiles);
  }
}
