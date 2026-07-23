import 'package:flutter/widgets.dart';
import 'package:picturestovideos/app/localizations/app_localizations.dart';
import 'package:picturestovideos/app/localizations/languages/app_localization_en.dart';

extension BuildContextLocalizationExtensions on BuildContext {
  AppLocalizations get l10n {
    return Localizations.of<AppLocalizations>(this, AppLocalizations) ??
        const AppLocalizationEn();
  }
}
