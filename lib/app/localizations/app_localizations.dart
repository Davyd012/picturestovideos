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
  String get cropZoom;
  String get cropHorizontal;
  String get cropVertical;
  String get cropOnlyForFill;
  String get framingPreview;
  String get centerImage;
  String get cropPositionCentered;
  String get cropDirectionLeft;
  String get cropDirectionRight;
  String get cropDirectionUp;
  String get cropDirectionDown;
  String cropZoomValue(String value);
  String cropOffsetValue(String direction, String percent);
  String get reset;
  String get apply;
  String get clipCaptions;
  String get editCaption;
  String get editClip;
  String get captionTitle;
  String get captionSupportingLine;
  String get noCaption;
  String clipNumber(int number, String name);
  String get editingPreview;
  String get renderedPreview;
  String get renderedPreviewSource;
  String get renderedPreviewCurrent;
  String get renderedPreviewStale;
  String get renderPreview;
  String get refreshRenderedPreview;
  String get motion;
  String get styleDefault;
  String get motionNone;
  String get motionZoomIn;
  String get motionZoomOut;
  String get motionPan;
  String get motionIntensity;
  String get motionSubtle;
  String get motionMore;
  String get savedProjects;
  String get noSavedProjects;
  String get saveProject;
  String get projectSaved;
  String get projectSaveFailed;
  String get projectsLoadFailed;
  String get projectStorageRecoveryNotice;
  String get openProject;
  String get retry;
  String get missingProjectFiles;
  String get missingAudio;
  String get missingImage;
  String get relink;
  String get relinkFailed;
  String get relinkSaveReminder;
  String get transitionToNext;
  String get transitionCut;
  String get transitionDissolve;
  String get transitionSlide;
  String get transitionDuration;
  String get transitionClamped;
  String get pacing;
  String get pacingRelaxed;
  String get pacingBalanced;
  String get pacingEnergetic;
  String get applyPacing;
  String get pacingOverwriteTitle;
  String get pacingOverwriteMessage;
  String get confirmPacing;
  String get pacingApplied;
  String get undo;
  String get pacingExplanation;
  String get pacingManualNotice;
  String expectedVideoDuration(String duration);
  String pacingTimingImpact({
    required int changed,
    required int total,
    required int added,
    required int removed,
  });
  String pacingClipDurationRange(String shortest, String longest);
  String get clipDuration;
  String get snapToMarkers;
  String get snapDescription;
  String durationRange(String maximum);
  String get musicSettings;
  String get musicStart;
  String get musicEnd;
  String get musicFadeIn;
  String get musicFadeOut;
  String get musicRangeExplanation;
  String get musicRangeInvalid;
  String get musicPlaybackFailed;
  String get visualStyle;
  String get styleCalm;
  String get styleCalmDescription;
  String get styleStorybook;
  String get styleStorybookDescription;
  String get styleCelebration;
  String get styleCelebrationDescription;
  String get styleOverridesPreserved;
  String get aspectRatio;
  String get legacyStyle;
  String get captionPlacement;
  String get captionBottom;
  String get captionCenter;
  String get captionTop;
  String get captionEntrance;
  String get captionEntranceNone;
  String get captionEntranceFade;
  String get captionEntranceSlide;
  String get captionTiming;
  String get captionOverflowWarning;
  String get captionReadingWarning;
  String get cancelExport;
  String get cancellingExport;
  String get exportCancelled;
  String get exportUnsupportedPlatform;
  String get exportMissingFfmpeg;
  String get exportMissingFilter;
  String get exportMissingEncoder;
  String get exportMissingMuxer;
  String get exportMissingFont;
  String get exportCapabilityProbeFailed;
  String get exportFailed;
  String get exportCapabilityChecking;
  String get editorMotionUnavailable;
  String get editorTransitionUnavailable;
  String get editorCaptionUnavailable;
  String get styleUnavailable;
  String get homeTitle;
  String get refreshSavedMedia;
  String get savedMedia;
  String get savedMediaDescription;
  String savedCount(int count);
  String get savedAudio;
  String get noSavedAudio;
  String get saveMarkersForReuse;
  String get savedAssets;
  String get noSavedAssets;
  String get importImagesToLibrary;
  String markerCount(int count);
  String get open;
  String get savedMediaLoadFailed;
  String get tryAgain;
  String get unknownDuration;
  String get unknownSize;
  String get missingAudioPath;
  String missingAudioAt(String path);
  String get savedAudioOpenFailed;
  String get navImport;
  String get navLibrary;
  String get navEditor;
  String get navExport;
  String get importAudioTitle;
  String get openEditor;
  String get productName;
  String get importTagline;
  String get dropWav;
  String get importInstructions;
  String get analyzeWav;
  String get selectSongOnly;
  String get wavFromPath;
  String get songFromPath;
  String get selectSongFromPath;
  String get importWavFromPath;
  String get absoluteAudioPath;
  String get selectAction;
  String get importAction;
  String get imageLibraryTitle;
  String get libraryDescription;
  String get importImagesHeading;
  String libraryVisibleCount(int count);
  String libraryImportedCount(int count);
  String libraryInEditorCount(int count);
  String libraryStagedCount(int count);
  String librarySelectedCount(int count);
  String libraryImagesAdded(int count);
  String libraryImagesRemoved(int count);
  String get librarySearchHint;
  String get librarySort;
  String get libraryFilterAll;
  String get libraryFilterRecent;
  String get libraryFilterStaged;
  String get libraryFilterFavorites;
  String get librarySortNewest;
  String get librarySortOldest;
  String get librarySortByName;
  String get librarySortByFileSize;
  String get libraryNoMatchingImages;
  String get libraryTryDifferentSearch;
  String get libraryNoNewImages;
  String get folderPathUnavailableOnAndroid;
  String get libraryReadyForEditor;
  String get libraryReviewStaged;
  String get libraryGoToExport;
  String get libraryImportMore;
  String get libraryStageAllImported;
  String get libraryStageSelected;
  String get libraryClearSelection;
  String get libraryStage;
  String get libraryStaged;
  String get libraryReady;
  String get pasteFolderPath;
  String get pickImages;
  String get importFolder;
  String openEditorCount(int count);
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
