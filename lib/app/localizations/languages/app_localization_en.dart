import 'package:picturestovideos/app/localizations/app_localizations.dart';

class AppLocalizationEn extends AppLocalizations {
  const AppLocalizationEn();

  @override
  String get sequenceOrder => 'Sequence order';
  @override
  String get custom => 'Custom';
  @override
  String get importOrder => 'Import order';
  @override
  String get title => 'Title';
  @override
  String get fileDate => 'File date';
  @override
  String get reverseCurrent => 'Reverse current';
  @override
  String get moveToPosition => 'Move to position';
  @override
  String get moveImage => 'Move image';
  @override
  String get position => 'Position';
  @override
  String positionRange(int count) => 'Enter a number from 1 to $count';
  @override
  String get cancel => 'Cancel';
  @override
  String get move => 'Move';
  @override
  String get removeImported => 'Remove imported';
  @override
  String get removeImportedTitle => 'Remove imported images?';
  @override
  String get removeImportedMessage =>
      'The images will be forgotten by the app. Original files will not be deleted.';
  @override
  String get remove => 'Remove';
  @override
  String get cropAll => 'Crop all';
  @override
  String get fullImageForAll => 'Full image for all';
  @override
  String get fillFrameCrop => 'Fill frame (crop)';
  @override
  String get fullImage => 'Full image';
  @override
  String get adjustCrop => 'Adjust crop';
  @override
  String get reset => 'Reset';
  @override
  String get apply => 'Apply';
}
