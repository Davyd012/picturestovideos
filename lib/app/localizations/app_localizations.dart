import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:picturestovideos/app/localizations/languages/app_localization_en.dart';
import 'package:picturestovideos/app/localizations/languages/app_localization_no.dart';
import 'package:picturestovideos/app/localizations/languages/app_localization_ru.dart';

abstract class AppLocalizations {
  const AppLocalizations();

  static const delegate = _AppLocalizationsDelegate();
  static const supportedLocales = [Locale('en'), Locale('no'), Locale('ru')];

  String get sequenceOrder;
  String get custom;
  String get importOrder;
  String get title;
  String get fileDate;
  String get reverseCurrent;
  String get moveToPosition;
  String get moveImage;
  String get position;
  String positionRange(int count);
  String get cancel;
  String get move;
  String get removeImported;
  String get removeImportedTitle;
  String get removeImportedMessage;
  String get remove;
  String get cropAll;
  String get fullImageForAll;
  String get fillFrameCrop;
  String get fullImage;
  String get adjustCrop;
  String get reset;
  String get apply;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    final localization = switch (locale.languageCode) {
      'no' => const AppLocalizationNo(),
      'ru' => const AppLocalizationRu(),
      _ => const AppLocalizationEn(),
    };
    return SynchronousFuture(localization);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
