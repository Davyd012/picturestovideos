import 'package:picturestovideos/app/localizations/languages/app_localization_en.dart';

class AppLocalizationNo extends AppLocalizationEn {
  const AppLocalizationNo();

  @override
  String get sequenceOrder => 'Rekkefølge';
  @override
  String get custom => 'Egendefinert';
  @override
  String get importOrder => 'Importrekkefølge';
  @override
  String get title => 'Tittel';
  @override
  String get fileDate => 'Fildato';
  @override
  String get reverseCurrent => 'Snu rekkefølgen';
  @override
  String get moveToPosition => 'Flytt til posisjon';
  @override
  String get moveImage => 'Flytt bilde';
  @override
  String get position => 'Posisjon';
  @override
  String positionRange(int count) => 'Skriv inn et tall fra 1 til $count';
  @override
  String get cancel => 'Avbryt';
  @override
  String get move => 'Flytt';
  @override
  String get removeImported => 'Fjern importerte';
  @override
  String get removeImportedTitle => 'Fjerne importerte bilder?';
  @override
  String get removeImportedMessage =>
      'Bildene glemmes av appen. Originalfilene slettes ikke.';
  @override
  String get remove => 'Fjern';
  @override
  String get cropAll => 'Beskjær alle';
  @override
  String get fullImageForAll => 'Hele bildet for alle';
  @override
  String get fillFrameCrop => 'Fyll rammen (beskjær)';
  @override
  String get fullImage => 'Hele bildet';
  @override
  String get adjustCrop => 'Juster beskjæring';
  @override
  String get reset => 'Tilbakestill';
  @override
  String get apply => 'Bruk';
}
