import 'package:picturestovideos/app/localizations/languages/app_localization_en.dart';

class AppLocalizationRu extends AppLocalizationEn {
  const AppLocalizationRu();

  @override
  String get sequenceOrder => 'Порядок';
  @override
  String get custom => 'Пользовательский';
  @override
  String get importOrder => 'Порядок импорта';
  @override
  String get title => 'Название';
  @override
  String get fileDate => 'Дата файла';
  @override
  String get reverseCurrent => 'Обратный порядок';
  @override
  String get moveToPosition => 'Переместить';
  @override
  String get moveImage => 'Переместить изображение';
  @override
  String get position => 'Позиция';
  @override
  String positionRange(int count) => 'Введите число от 1 до $count';
  @override
  String get cancel => 'Отмена';
  @override
  String get move => 'Переместить';
  @override
  String get removeImported => 'Удалить импортированные';
  @override
  String get removeImportedTitle => 'Удалить импортированные изображения?';
  @override
  String get removeImportedMessage =>
      'Приложение забудет изображения. Исходные файлы не будут удалены.';
  @override
  String get remove => 'Удалить';
  @override
  String get cropAll => 'Обрезать все';
  @override
  String get fullImageForAll => 'Полное изображение для всех';
  @override
  String get fillFrameCrop => 'Заполнить кадр';
  @override
  String get fullImage => 'Полное изображение';
  @override
  String get adjustCrop => 'Настроить обрезку';
  @override
  String get reset => 'Сбросить';
  @override
  String get apply => 'Применить';
}
