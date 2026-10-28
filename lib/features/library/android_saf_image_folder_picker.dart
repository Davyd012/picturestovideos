import 'package:flutter/services.dart';
import 'package:picturestovideos/features/library/image_file_picker.dart';

class AndroidSafImageFolderPicker {
  AndroidSafImageFolderPicker({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'picturestovideos/android_saf_folder';
  static const _supportedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  final MethodChannel _channel;

  Future<List<PickedImageFile>> pickImagesFromFolder() async {
    final result = await _channel.invokeListMethod<Object?>(
      'pickImagesFromFolder',
    );
    if (result == null || result.isEmpty) {
      return const [];
    }

    final files = <PickedImageFile>[];
    for (final value in result) {
      if (value is! Map) {
        continue;
      }
      final name = value['name'];
      final path = value['path'];
      final size = value['size'];
      final modifiedMillis = value['modifiedOn'];
      if (name is! String || path is! String || size is! num) {
        continue;
      }
      final extension = _extension(name);
      if (!_supportedExtensions.contains(extension)) {
        continue;
      }
      files.add(
        PickedImageFile(
          name: name,
          extension: extension,
          size: size.toInt(),
          path: path,
          modifiedOn: modifiedMillis is num
              ? DateTime.fromMillisecondsSinceEpoch(modifiedMillis.toInt())
              : null,
        ),
      );
    }
    return List.unmodifiable(files);
  }

  String _extension(String name) {
    final dotIndex = name.lastIndexOf('.');
    return dotIndex < 0 ? '' : name.substring(dotIndex + 1).toLowerCase();
  }
}
