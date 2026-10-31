import 'package:picturestovideos/app/localizations/languages/app_localization_en.dart';

class AppLocalizationRu extends AppLocalizationEn {
  @override
  String get cropZoom => 'Масштаб';
  @override
  String get cropHorizontal => 'Положение по горизонтали';
  @override
  String get cropVertical => 'Положение по вертикали';
  @override
  String get cropOnlyForFill =>
      'Масштаб и положение применяются только при выборе «Заполнить кадр (обрезать)».';
  @override
  String get framingPreview => 'Предпросмотр кадрирования';
  @override
  String get centerImage => 'По центру';
  @override
  String get cropPositionCentered => 'По центру';
  @override
  String get cropDirectionLeft => 'левому';
  @override
  String get cropDirectionRight => 'правому';
  @override
  String get cropDirectionUp => 'верхнему';
  @override
  String get cropDirectionDown => 'нижнему';
  @override
  String cropZoomValue(String value) => 'увеличение $value';
  @override
  String cropOffsetValue(String direction, String percent) =>
      '$percent% к $direction краю';
  @override
  String get homeTitle => 'Главная';
  @override
  String get refreshSavedMedia => 'Обновить сохранённые материалы';
  @override
  String get savedMedia => 'Сохранённые материалы';
  @override
  String get savedMediaDescription =>
      'Откройте сохранённые аудиомаркеры и используйте их с новыми фотографиями.';
  @override
  String savedCount(int count) => 'Сохранено: $count';
  @override
  String get savedAudio => 'Сохранённое аудио';
  @override
  String get noSavedAudio => 'Сохранённого аудио пока нет';
  @override
  String get saveMarkersForReuse =>
      'Сохраните маркеры в редакторе, чтобы использовать их здесь.';
  @override
  String get savedAssets => 'Сохранённые изображения';
  @override
  String get noSavedAssets => 'Сохранённых изображений пока нет';
  @override
  String get importImagesToLibrary =>
      'Импортируйте изображения в библиотеку, чтобы увидеть их здесь.';
  @override
  String markerCount(int count) => 'Маркеры: $count';
  @override
  String get open => 'Открыть';
  @override
  String get savedMediaLoadFailed =>
      'Не удалось загрузить сохранённые материалы';
  @override
  String get tryAgain => 'Повторить';
  @override
  String get unknownDuration => 'Неизвестная длительность';
  @override
  String get unknownSize => 'Неизвестный размер';
  @override
  String get missingAudioPath =>
      'У сохранённого аудио отсутствует путь к файлу.';
  @override
  String missingAudioAt(String path) => 'Аудиофайл не найден по пути $path.';
  @override
  String get savedAudioOpenFailed =>
      'Не удалось открыть аудио. Проверьте файл и повторите попытку.';
  @override
  String get navImport => 'Импорт';
  @override
  String get navLibrary => 'Библиотека';
  @override
  String get navEditor => 'Редактор';
  @override
  String get navExport => 'Экспорт';
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
  String queuedImages(int count) => 'Изображения в очереди ($count)';
  @override
  String get queuedImagesPurpose =>
      'Изображения, ожидающие добавления на временную шкалу';
  @override
  String get bulkImageTools => 'Инструменты для нескольких изображений';
  @override
  String get reorder => 'Изменить порядок';
  @override
  String get done => 'Готово';
  @override
  String get selected => 'Выбрано';
  @override
  String get returnToTimelineOrder => 'Вернуться к порядку временной шкалы';
  @override
  String get reviewSequence => 'Проверить последовательность';
  @override
  String get openTimeline => 'Открыть временную шкалу';
  @override
  String get clipActions => 'Действия с клипом';
  @override
  String get noTimelineClips => 'На временной шкале пока нет клипов.';
  @override
  String clipMovedToPosition(int position) => 'Перемещено на позицию $position';
  @override
  String get moveFailed =>
      'Этот клип больше недоступен. Обновите список и повторите попытку.';
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
  @override
  String get clipCaptions => 'Подписи к клипам';
  @override
  String get removeClip => 'Удалить клип';
  @override
  String get editCaption => 'Изменить подпись';
  @override
  String get editClip => 'Изменить клип';
  @override
  String get captionTitle => 'Заголовок';
  @override
  String get captionSupportingLine => 'Дополнительная строка (необязательно)';
  @override
  String get noCaption => 'Без подписи';
  @override
  String clipNumber(int number, String name) => 'Клип $number: $name';
  @override
  String get editingPreview => 'Предпросмотр при редактировании';
  @override
  String get renderedPreview => 'Предпросмотр после рендеринга';
  @override
  String get renderedPreviewSource =>
      'Создан с помощью процесса рендеринга экспорта.';
  @override
  String get renderedPreviewCurrent =>
      'Этот предпросмотр соответствует текущим изменениям.';
  @override
  String get renderedPreviewStale =>
      'Этот предпросмотр устарел. Обновите его, чтобы учесть последние изменения.';
  @override
  String get renderPreview => 'Создать предпросмотр';
  @override
  String get refreshRenderedPreview => 'Обновить предпросмотр';
  @override
  String get motion => 'Движение';
  @override
  String get styleDefault => 'По умолчанию для стиля';
  @override
  String get motionNone => 'Нет';
  @override
  String get motionZoomIn => 'Медленное приближение';
  @override
  String get motionZoomOut => 'Медленное отдаление';
  @override
  String get motionPan => 'Плавное панорамирование';
  @override
  String get motionIntensity => 'Интенсивность движения';
  @override
  String get motionSubtle => 'Незаметное';
  @override
  String get motionMore => 'Больше движения';
  @override
  String get savedProjects => 'Сохранённые проекты';
  @override
  String get noSavedProjects =>
      'Сохраните проект в редакторе, чтобы открыть его здесь.';
  @override
  String get saveProject => 'Сохранить проект';
  @override
  String get projectSaved => 'Проект сохранён';
  @override
  String get projectSaveFailed => 'Не удалось сохранить проект';
  @override
  String get projectsLoadFailed => 'Не удалось загрузить проекты';
  @override
  String get projectStorageRecoveryNotice =>
      'Некоторые сохранённые проекты не удалось прочитать. Доступные проекты остаются в списке, а где возможно восстановлена предыдущая версия.';
  @override
  String get openProject => 'Открыть проект';
  @override
  String get retry => 'Повторить';
  @override
  String get missingProjectFiles => 'Некоторые файлы проекта отсутствуют';
  @override
  String get missingAudio => 'Музыка';
  @override
  String get missingImage => 'Фотография';
  @override
  String get relink => 'Указать файл';
  @override
  String get relinkFailed => 'Не удалось открыть выбранный файл.';
  @override
  String get relinkSaveReminder =>
      'Файл указан. Сохраните проект, чтобы сохранить изменение.';
  @override
  String get transitionToNext => 'Переход к следующему клипу';
  @override
  String get transitionCut => 'Смена кадра';
  @override
  String get transitionDissolve => 'Плавное растворение';
  @override
  String get transitionSlide => 'Плавный сдвиг';
  @override
  String get transitionDuration => 'Длительность перехода';
  @override
  String get transitionClamped =>
      'Переход будет сокращён с учётом длительности клипов.';
  @override
  String get pacing => 'Темп';
  @override
  String get pacingRelaxed => 'Спокойный';
  @override
  String get pacingBalanced => 'Сбалансированный';
  @override
  String get pacingEnergetic => 'Энергичный';
  @override
  String get applyPacing => 'Создать вариант последовательности';
  @override
  String get pacingOverwriteTitle => 'Заменить текущее время клипов?';
  @override
  String get pacingOverwriteMessage =>
      'Время начала и конца всех клипов будет пересчитано, а снятые с выбора фотографии будут удалены. Кадрирование, подписи, движение и переходы существующих клипов сохранятся. После применения проверьте обновлённую шкалу.';
  @override
  String get confirmPacing => 'Применить новое время';
  @override
  String get pacingApplied => 'Новый темп применён';
  @override
  String get undo => 'Отменить';
  @override
  String get pacingExplanation =>
      'Начинается с начала музыки. Новые фотографии используются один раз, а ближайшие музыкальные метки могут сдвигать точки смены. Повторяющиеся клипы сохраняются. Конец определяется меньшей из длительности музыки и предложенной длительности.';
  @override
  String get pacingManualNotice =>
      'Последовательность изменена. Изменения очереди и меток не перестраивают её автоматически. Новый вариант изменит время и удалит клипы фотографий, которых больше нет в очереди.';
  @override
  String expectedVideoDuration(String duration) =>
      'Ожидаемая длительность видео: $duration';
  @override
  String pacingTimingImpact({
    required int changed,
    required int total,
    required int added,
    required int removed,
  }) =>
      'Изменение времени: перемещено клипов — $changed из $total; добавлено — $added; удалено — $removed.';
  @override
  String pacingClipDurationRange(String shortest, String longest) =>
      'Предлагаемая длительность клипов: $shortest–$longest.';
  @override
  String get clipDuration => 'Длительность клипа (секунды)';
  @override
  String get snapToMarkers => 'Привязка к музыкальным меткам';
  @override
  String get snapDescription => 'Привязать к метке в пределах 0,25 секунды.';
  @override
  String durationRange(String maximum) =>
      'Введите длительность от 0,1 до $maximum секунд.';
  @override
  String get musicSettings => 'Диапазон музыки и затухание';
  @override
  String get musicStart => 'Начало (секунды)';
  @override
  String get musicEnd => 'Конец (секунды, необязательно)';
  @override
  String get musicFadeIn => 'Нарастание (секунды)';
  @override
  String get musicFadeOut => 'Затухание (секунды)';
  @override
  String get musicRangeExplanation =>
      'Видео начинается с выбранного места музыки. Музыка заканчивается в выбранной точке или с концом видео; после короткой музыки наступает тишина. Длительность нарастания и затухания ограничена половиной слышимого диапазона.';
  @override
  String get musicRangeInvalid =>
      'Укажите допустимый диапазон музыки и неотрицательную длительность затухания.';
  @override
  String get musicPlaybackFailed =>
      'Настройки сохранены, но подготовить воспроизведение не удалось.';
  @override
  String get visualStyle => 'Визуальный стиль';
  @override
  String get styleCalm => 'Тёплые воспоминания';
  @override
  String get styleCalmDescription =>
      'Сдержанный тёплый стиль с медленным движением и плавными переходами.';
  @override
  String get styleStorybook => 'История';
  @override
  String get styleStorybookDescription =>
      'Спокойное изменение кадра и заметные заголовки для личных историй.';
  @override
  String get styleCelebration => 'Праздник';
  @override
  String get styleCelebrationDescription =>
      'Более живое движение, короткие подписи и плавные сдвиги.';
  @override
  String get styleOverridesPreserved =>
      'Смена стиля меняет настройки по умолчанию и сохраняет изменения клипов и формат кадра.';
  @override
  String get aspectRatio => 'Формат кадра';
  @override
  String get legacyStyle => 'Сохранённый пользовательский стиль';
  @override
  String get captionPlacement => 'Расположение подписи';
  @override
  String get captionBottom => 'Снизу';
  @override
  String get captionCenter => 'По центру';
  @override
  String get captionTop => 'Сверху';
  @override
  String get captionStyle => 'Стиль';
  @override
  String get captionStyleClean => 'Чистый';
  @override
  String get captionStyleSoft => 'Мягкий фон';
  @override
  String get captionStyleBold => 'Контрастный';
  @override
  String get captionSize => 'Размер подписи';
  @override
  String get captionFont => 'Шрифт';
  @override
  String get captionFontUnavailable =>
      'Выбор шрифта недоступен: экспорт использует один найденный системный шрифт. В предпросмотре применяется тот же нейтральный стиль.';
  @override
  String get captionTextColor => 'Цвет текста';
  @override
  String get captionBackdrop => 'Фон';
  @override
  String get captionBackdropNone => 'Без фона';
  @override
  String get captionBackdropSoft => 'Мягкая панель';
  @override
  String get captionBackdropStrong => 'Контрастная панель';
  @override
  String get captionBackdropClassic => 'Классические блоки';
  @override
  String get captionBackdropUnavailable =>
      'Фоновые панели недоступны: в этом рендерере нет фильтра drawbox.';
  @override
  String get captionNoBackdropWarning =>
      'Без фона читаемость зависит от изображения. Панель обеспечивает более стабильный контраст.';
  @override
  String get captionLowContrastWarning =>
      'Тёмный текст на тёмном фоне может быть плохо виден. Выберите светлый текст.';
  @override
  String get captionSectionText => 'Текст';
  @override
  String get captionSectionStyle => 'Стиль';
  @override
  String get captionSectionPosition => 'Положение';
  @override
  String get captionSectionTiming => 'Время';
  @override
  String get captionColorLight => 'Светлый';
  @override
  String get captionColorDark => 'Тёмный';
  @override
  String get captionReset => 'Сбросить стиль';
  @override
  String get captionNotVisibleAtTime => 'В это время подпись не отображается.';
  @override
  String get clipListSort => 'Сортировка списка клипов';
  @override
  String get clipSortTimeline => 'Порядок на шкале';
  @override
  String get clipSortNameAscending => 'Имя файла А–Я';
  @override
  String get clipSortNameDescending => 'Имя файла Я–А';
  @override
  String get clipSortModifiedOldest => 'Дата изменения файла: сначала старые';
  @override
  String get clipSortModifiedNewest => 'Дата изменения файла: сначала новые';
  @override
  String get clipDateUnavailable => 'Дата недоступна';
  @override
  String get clipRepeatedSource => 'Повтор источника';
  @override
  String get clipRepeatedDetails => 'Просмотреть повторы источника';
  @override
  String get clipOccurrence => 'Вхождение';
  @override
  String get captionApplyAllStyles => 'Применить стиль ко всем клипам';
  @override
  String get captionApplyAllStylesConfirm =>
      'Применить этот вид подписи ко всем клипам? Их текст, расположение, время и появление останутся прежними.';
  @override
  String get captionEntrance => 'Появление подписи';
  @override
  String get captionEntranceNone => 'Без анимации';
  @override
  String get captionEntranceFade => 'Плавное появление';
  @override
  String get captionEntranceSlide => 'Выезд';
  @override
  String get captionTiming => 'Часть клипа с подписью';
  @override
  String get captionOverflowWarning =>
      'Текст не помещается в безопасную область и будет сокращён. Попробуйте использовать меньше слов.';
  @override
  String get captionReadingWarning =>
      'Текст может быть трудно прочитать за выбранное время.';
  @override
  String get cancelExport => 'Отменить экспорт';
  @override
  String get cancellingExport => 'Отмена экспорта';
  @override
  String get exportCancelled => 'Экспорт отменён';
  @override
  String get exportUnsupportedPlatform =>
      'Рендеринг недоступен на этой платформе. Откройте проект на Android или на Windows, macOS либо Linux с установленным FFmpeg.';
  @override
  String get exportMissingFfmpeg =>
      'FFmpeg не найден. Установите поддерживаемую сборку FFmpeg, доступную приложению, и повторите попытку.';
  @override
  String get exportMissingFilter =>
      'Для этого стиля видео нужен фильтр FFmpeg, которого нет в сборке. Установите совместимую сборку или отключите неподдерживаемое движение, переход либо подпись.';
  @override
  String get exportMissingEncoder =>
      'В сборке отсутствует нужный кодировщик видео или звука. Установите совместимую сборку FFmpeg для этой платформы.';
  @override
  String get exportMissingMuxer =>
      'Сборка FFmpeg не поддерживает MP4. Используйте сборку с поддержкой MP4.';
  @override
  String get exportMissingFont =>
      'Не найден поддерживаемый шрифт для подписей. Установите системный шрифт и повторите попытку без эмодзи и неподдерживаемых символов.';
  @override
  String get exportCapabilityProbeFailed =>
      'Не удалось проверить рендерер. Проверьте установку FFmpeg и разрешения, затем повторите попытку.';
  @override
  String get exportFailed =>
      'Не удалось экспортировать видео. Проверьте исходные файлы и свободное место, затем повторите попытку.';
  @override
  String get exportCapabilityChecking => 'Проверка поддержки рендеринга…';
  @override
  String get editorMotionUnavailable =>
      'Настройки движения заблокированы: средство рендеринга не поддерживает необходимый фильтр.';
  @override
  String get editorTransitionUnavailable =>
      'Настройки переходов заблокированы: средство рендеринга не поддерживает необходимый фильтр.';
  @override
  String get editorCaptionUnavailable =>
      'Редактирование титров заблокировано: недоступны рендеринг текста или нужный шрифт.';
  @override
  String get styleUnavailable =>
      'Для этого стиля нужны функции рендеринга, недоступные на этом устройстве.';
  @override
  String get importAudioTitle => 'Импорт аудио';
  @override
  String get openEditor => 'Открыть редактор';
  @override
  String get productName => 'Фото в видео';
  @override
  String get importTagline => 'Превратите ритм и фотографии в движение.';
  @override
  String get dropWav => 'Перетащите сюда файл WAV';
  @override
  String get importInstructions =>
      'Проанализируйте файл WAV или выберите песню и добавьте метки вручную.';
  @override
  String get analyzeWav => 'Анализ WAV';
  @override
  String get selectSongOnly => 'Выбрать только песню';
  @override
  String get wavFromPath => 'WAV по пути';
  @override
  String get songFromPath => 'Песня по пути';
  @override
  String get selectSongFromPath => 'Выбрать песню по пути';
  @override
  String get importWavFromPath => 'Импортировать WAV по пути';
  @override
  String get absoluteAudioPath => 'Полный путь к аудио';
  @override
  String get selectAction => 'Выбрать';
  @override
  String get importAction => 'Импортировать';
  @override
  String get imageLibraryTitle => 'Библиотека изображений';
  @override
  String get libraryDescription =>
      'Импортируйте фотографии, выберите лучшие кадры и отправьте их в редактор с синхронизацией по ритму.';
  @override
  String get importImagesHeading => 'Импорт фотографий';
  @override
  String libraryVisibleCount(int count) => 'Видно: $count';
  @override
  String libraryImportedCount(int count) => 'Импортировано: $count';
  @override
  String libraryInEditorCount(int count) => 'В редакторе: $count';
  @override
  String libraryStagedCount(int count) => 'Добавлено: $count';
  @override
  String librarySelectedCount(int count) => '$count выбрано';
  @override
  String libraryImagesAdded(int count) {
    final remainder = count % 100;
    final lastDigit = count % 10;
    final noun = remainder >= 11 && remainder <= 14
        ? 'изображений'
        : switch (lastDigit) {
            1 => 'изображение',
            2 || 3 || 4 => 'изображения',
            _ => 'изображений',
          };
    return 'Добавлено $count $noun в библиотеку.';
  }

  @override
  String libraryImagesRemoved(int count) {
    final remainder = count % 100;
    final lastDigit = count % 10;
    final noun = remainder >= 11 && remainder <= 14
        ? 'изображений'
        : switch (lastDigit) {
            1 => 'изображение',
            2 || 3 || 4 => 'изображения',
            _ => 'изображений',
          };
    return 'Удалено $count $noun из приложения.';
  }

  @override
  String get librarySearchHint => 'Поиск фотографий, папок и дат';
  @override
  String get librarySort => 'Сортировка';
  @override
  String get libraryFilterAll => 'Все';
  @override
  String get libraryFilterRecent => 'Недавние';
  @override
  String get libraryFilterStaged => 'Выбранные';
  @override
  String get libraryFilterFavorites => 'Избранное';
  @override
  String get librarySortNewest => 'Сначала новые';
  @override
  String get librarySortOldest => 'Сначала старые';
  @override
  String get librarySortByName => 'По названию';
  @override
  String get librarySortByFileSize => 'По размеру файла';
  @override
  String get libraryNoMatchingImages => 'Нет подходящих фотографий';
  @override
  String get libraryTryDifferentSearch =>
      'Измените поисковый запрос, фильтр или сортировку.';
  @override
  String get libraryNoNewImages =>
      'Новые поддерживаемые фотографии не добавлены.';
  @override
  String get libraryImportFailed =>
      'Не удалось импортировать фотографии. Проверьте файлы и попробуйте ещё раз.';
  @override
  String get libraryFolderPathRequired =>
      'Укажите путь к папке перед импортом.';
  @override
  String get libraryFolderNotFound =>
      'Не удалось найти или открыть папку. Проверьте путь и разрешения.';
  @override
  String get libraryFolderReadFailed =>
      'Не удалось прочитать фотографии из выбранной папки. Проверьте доступ и попробуйте ещё раз.';
  @override
  String get libraryRemovalFailed =>
      'Не удалось удалить импортированные фотографии. Попробуйте ещё раз.';
  @override
  String get folderPathUnavailableOnAndroid =>
      'Выберите папку через системный выбор Android. Импортируются только поддерживаемые изображения из этой папки.';
  @override
  String get libraryReadyForEditor => 'Готово к редактированию';
  @override
  String get libraryReviewStaged => 'Проверить выбранные';
  @override
  String get libraryGoToExport => 'Перейти к экспорту';
  @override
  String get libraryImportMore => 'Импортировать ещё';
  @override
  String get libraryStageAllImported => 'Добавить все импортированные';
  @override
  String get libraryStageSelected => 'Добавить выбранные';
  @override
  String get libraryClearSelection => 'Снять выделение';
  @override
  String get libraryStage => 'Добавить';
  @override
  String get libraryStaged => 'Добавлено';
  @override
  String get libraryReady => 'Готово';
  @override
  String get pasteFolderPath => 'Вставьте путь к папке';
  @override
  String get pickImages => 'Выбрать фотографии';
  @override
  String get importFolder => 'Импортировать папку';
  @override
  String openEditorCount(int count) => 'Открыть редактор ($count)';
}
