import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/features/library/android_saf_image_folder_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('picturestovideos/android_saf_folder');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('folder channel maps supported files and source metadata', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'pickImagesFromFolder');
      return [
        {
          'name': 'Trip.JPG',
          'path': '/app/imported_images/trip.jpg',
          'size': 42,
          'modifiedOn': 1_798_000_000_000,
        },
        {
          'name': 'notes.txt',
          'path': '/app/imported_images/notes.txt',
          'size': 4,
        },
        'invalid result',
      ];
    });

    final files = await AndroidSafImageFolderPicker().pickImagesFromFolder();

    expect(files, hasLength(1));
    expect(files.single.name, 'Trip.JPG');
    expect(files.single.extension, 'jpg');
    expect(files.single.path, '/app/imported_images/trip.jpg');
    expect(files.single.size, 42);
    expect(
      files.single.modifiedOn,
      DateTime.fromMillisecondsSinceEpoch(1_798_000_000_000),
    );
  });

  test('folder channel cancellation returns no files', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);

    expect(await AndroidSafImageFolderPicker().pickImagesFromFolder(), isEmpty);
  });

  test('removes imported source paths through the native channel', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'removeImportedImages');
      expect(call.arguments, {
        'paths': ['/app/imported_images/a.png', '/app/imported_images/b.jpg'],
      });
      return null;
    });

    await AndroidSafImageFolderPicker().removeImportedImages({
      '/app/imported_images/a.png',
      '/app/imported_images/b.jpg',
    });
  });
}
