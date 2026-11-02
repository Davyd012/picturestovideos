import 'package:picturestovideos/app/localizations/app_localizations.dart';

class AppLocalizationEn extends AppLocalizations {
  @override
  String get emptyEditorTitle => 'Your project is empty';
  @override
  String get emptyEditorDescription =>
      'Import images to make your first video.';
  @override
  String get emptyEditorAddImages => 'Add images';
  @override
  String get emptyEditorAddQueued => 'Add images from queue';
  @override
  String get emptyEditorSteps => 'After adding images';
  @override
  String get emptyEditorOrder => 'Choose the order';
  @override
  String get emptyEditorEdit => 'Edit framing and motion';
  @override
  String get emptyEditorExport => 'Preview and export';
  @override
  String get emptyEditorToolsHint =>
      'Editing tools open after you add at least one image.';
  @override
  String get editorTimeline => 'Timeline';
  @override
  String get editorMarkers => 'Markers';
  @override
  String get editorTools => 'Tools';
  @override
  String get editorSave => 'Save';
  @override
  String get editorDiscardChanges => 'Discard unsaved changes?';
  @override
  String get editorOutputRatio => 'Video aspect ratio';
  @override
  String get editorClips => 'Clips';
  @override
  String get editorQueue => 'Queue';
  @override
  String get editorQueueTitle => 'Queued images';
  @override
  String get editorSelectAll => 'Select all';
  @override
  String editorAddSelected(int count) => 'Add selected ($count)';
  @override
  String get editorImageSettings => 'Image settings';
  @override
  String get editorDisplayDuration => 'Display duration';
  @override
  String get editorOptionalCaption => 'Caption (optional)';
  @override
  String get editorSmoothAnimation => 'Apply smooth animation';
  @override
  String get editorFit => 'Fit';
  @override
  String get editorFill => 'Fill';
  @override
  String get editorMore => 'More';
  @override
  String get editorText => 'Text';
  @override
  String get editorSpeed => 'Speed';
  @override
  String get editorCrop => 'Crop';
  @override
  String editorAddedCount(int count) => 'Added $count images';
  @override
  String get editorAlreadyOnTimeline =>
      'Selected images are already on the timeline';
  @override
  String get cropZoom => 'Zoom';
  @override
  String get cropHorizontal => 'Horizontal position';
  @override
  String get cropVertical => 'Vertical position';
  @override
  String get cropOnlyForFill =>
      'Zoom and position apply only when Fill frame (crop) is selected.';
  @override
  String get framingPreview => 'Framing preview';
  @override
  String get centerImage => 'Center image';
  @override
  String get applyFramingToAllClips => 'Apply framing to all clips';
  @override
  String get applyFramingToAllClipsConfirm =>
      'Apply this image fit and crop to every clip?';
  @override
  String get cropPositionCentered => 'Centered';
  @override
  String get cropDirectionLeft => 'left';
  @override
  String get cropDirectionRight => 'right';
  @override
  String get cropDirectionUp => 'top';
  @override
  String get cropDirectionDown => 'bottom';
  @override
  String cropZoomValue(String value) => '$value times';
  @override
  String cropOffsetValue(String direction, String percent) =>
      '$percent% toward the $direction edge';
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
  String queuedImages(int count) => 'Queued images ($count)';
  @override
  String get queuedImagesPurpose =>
      'Images waiting to be placed on the timeline';
  @override
  String get bulkImageTools => 'Bulk image tools';
  @override
  String get reorder => 'Reorder';
  @override
  String get done => 'Done';
  @override
  String get selected => 'Selected';
  @override
  String get returnToTimelineOrder => 'Return to timeline order';
  @override
  String get reviewSequence => 'Review sequence';
  @override
  String get openTimeline => 'Open timeline';
  @override
  String get clipActions => 'Clip actions';
  @override
  String get noTimelineClips => 'No clips are on the timeline yet.';
  @override
  String clipMovedToPosition(int position) => 'Moved to position $position';
  @override
  String get moveFailed =>
      'This clip is no longer available. Refresh the list and try again.';
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
  @override
  String get clipCaptions => 'Sequence captions';
  @override
  String get removeClip => 'Remove clip';
  @override
  String get editCaption => 'Edit caption';
  @override
  String get editClip => 'Edit clip';
  @override
  String get captionTitle => 'Title';
  @override
  String get captionSupportingLine => 'Supporting line (optional)';
  @override
  String get noCaption => 'No caption';
  @override
  String clipNumber(int number, String name) => 'Clip $number: $name';
  @override
  String get editingPreview => 'Editing preview';
  @override
  String get renderedPreview => 'Rendered preview';
  @override
  String get renderedPreviewSource =>
      'Generated by the export rendering pipeline.';
  @override
  String get renderedPreviewCurrent =>
      'This rendered preview matches the current edits.';
  @override
  String get renderedPreviewStale =>
      'This rendered preview is out of date. Refresh it to include the latest edits.';
  @override
  String get renderPreview => 'Render preview';
  @override
  String get refreshRenderedPreview => 'Refresh rendered preview';
  @override
  String get motion => 'Motion';
  @override
  String get styleDefault => 'Style default';
  @override
  String get motionNone => 'None';
  @override
  String get motionZoomIn => 'Slow zoom in';
  @override
  String get motionZoomOut => 'Slow zoom out';
  @override
  String get motionPan => 'Gentle pan';
  @override
  String get motionIntensity => 'Movement';
  @override
  String get motionSubtle => 'Subtle';
  @override
  String get motionMore => 'More movement';
  @override
  String get savedProjects => 'Saved projects';
  @override
  String get noSavedProjects =>
      'Save a project in the editor to reopen it here.';
  @override
  String get saveProject => 'Save project';
  @override
  String get projectSaved => 'Project saved';
  @override
  String get projectSaveFailed => 'Could not save the project';
  @override
  String get projectsLoadFailed => 'Could not load saved projects';
  @override
  String get projectStorageRecoveryNotice =>
      'Some saved projects could not be read. Available projects are still listed, and a previous save was restored where possible.';
  @override
  String get openProject => 'Open project';
  @override
  String get retry => 'Try again';
  @override
  String get missingProjectFiles => 'Some project files are missing';
  @override
  String get missingAudio => 'Music';
  @override
  String get missingImage => 'Photo';
  @override
  String get relink => 'Relink';
  @override
  String get relinkFailed => 'The selected file could not be opened.';
  @override
  String get relinkSaveReminder =>
      'File relinked. Save the project to keep this change.';
  @override
  String get transitionToNext => 'Transition to next clip';
  @override
  String get transitionCut => 'Cut';
  @override
  String get transitionDissolve => 'Dissolve';
  @override
  String get transitionSlide => 'Gentle slide';
  @override
  String get transitionDuration => 'Transition duration';
  @override
  String get transitionClamped =>
      'The transition will be shortened to fit these clips.';
  @override
  String get pacing => 'Pacing';
  @override
  String get pacingRelaxed => 'Relaxed';
  @override
  String get pacingBalanced => 'Balanced';
  @override
  String get pacingEnergetic => 'Energetic';
  @override
  String get applyPacing => 'Create sequence suggestion';
  @override
  String get pacingOverwriteTitle => 'Replace your current clip timing?';
  @override
  String get pacingOverwriteMessage =>
      'This recalculates every clip start and end, and removes queued photos that are no longer selected. Framing, captions, motion, and transitions on matching clips are kept. Review the updated timeline after applying.';
  @override
  String get confirmPacing => 'Apply new timing';
  @override
  String get pacingApplied => 'New pacing applied';
  @override
  String get undo => 'Undo';
  @override
  String get pacingExplanation =>
      'Starts at the beginning of the music. New photos are used once, and nearby music markers can shift cut points. Existing repeated clips are kept. The sequence ends at the music length or suggested length, whichever is shorter.';
  @override
  String get pacingManualNotice =>
      'Your sequence has edits. Queue and marker changes will not rebuild it automatically. A new suggestion changes timing and removes clips for photos no longer in the queue.';
  @override
  String expectedVideoDuration(String duration) =>
      'Expected video duration: $duration';
  @override
  String pacingTimingImpact({
    required int changed,
    required int total,
    required int added,
    required int removed,
  }) =>
      'Timing changes: $changed of $total suggested clips move; $added added; $removed removed.';
  @override
  String pacingClipDurationRange(String shortest, String longest) =>
      'Suggested clip lengths: $shortest–$longest.';
  @override
  String get clipDuration => 'Clip duration (seconds)';
  @override
  String get snapToMarkers => 'Snap to music markers';
  @override
  String get snapDescription => 'Snap to a marker within 0.25 seconds.';
  @override
  String durationRange(String maximum) =>
      'Enter a duration from 0.1 to $maximum seconds.';
  @override
  String get musicSettings => 'Music range and fades';
  @override
  String get musicStart => 'Start (seconds)';
  @override
  String get musicEnd => 'End (seconds, optional)';
  @override
  String get musicFadeIn => 'Fade in (seconds)';
  @override
  String get musicFadeOut => 'Fade out (seconds)';
  @override
  String get musicRangeExplanation =>
      'Video time zero starts at the selected music start. Music ends at the selected end or when the video ends; short music is followed by silence. Fades are limited to half the audible range.';
  @override
  String get musicRangeInvalid =>
      'Enter a valid range within the music and non-negative fade durations.';
  @override
  String get musicPlaybackFailed =>
      'Music settings saved, but playback could not be prepared.';
  @override
  String get visualStyle => 'Visual style';
  @override
  String get styleCalm => 'Calm memories';
  @override
  String get styleCalmDescription =>
      'Warm and understated, with slow movement and soft dissolves.';
  @override
  String get styleStorybook => 'Storybook';
  @override
  String get styleStorybookDescription =>
      'Reflective reframing and prominent titles for personal stories.';
  @override
  String get styleCelebration => 'Celebration';
  @override
  String get styleCelebrationDescription =>
      'Livelier movement, short captions, and gentle slides.';
  @override
  String get styleOverridesPreserved =>
      'Switching styles changes defaults and keeps your clip edits and aspect ratio.';
  @override
  String get aspectRatio => 'Aspect ratio';
  @override
  String get legacyStyle => 'Saved custom style';
  @override
  String get captionPlacement => 'Caption placement';
  @override
  String get captionBottom => 'Bottom';
  @override
  String get captionCenter => 'Center';
  @override
  String get captionTop => 'Top';
  @override
  String get captionStyle => 'Style preset';
  @override
  String get captionStyleClean => 'Clean';
  @override
  String get captionStyleSoft => 'Soft backdrop';
  @override
  String get captionStyleBold => 'Bold';
  @override
  String get captionSize => 'Caption size';
  @override
  String get captionFont => 'Font';
  @override
  String get captionFontUnavailable =>
      'Font choices are unavailable because export uses one detected system font. The preview uses the same neutral text style.';
  @override
  String get captionTextColor => 'Text color';
  @override
  String get captionBackdrop => 'Backdrop';
  @override
  String get captionBackdropNone => 'None';
  @override
  String get captionBackdropSoft => 'Soft panel';
  @override
  String get captionBackdropStrong => 'Strong panel';
  @override
  String get captionBackdropClassic => 'Classic line boxes';
  @override
  String get captionBackdropUnavailable =>
      'Panel backdrops are unavailable because this renderer lacks the drawbox filter.';
  @override
  String get captionNoBackdropWarning =>
      'Without a backdrop, readability changes with the footage. Use a panel for more consistent contrast.';
  @override
  String get captionLowContrastWarning =>
      'Dark text on a dark backdrop may be difficult to read. Choose light text.';
  @override
  String get captionSectionText => 'Text';
  @override
  String get captionSectionStyle => 'Style';
  @override
  String get captionSectionPosition => 'Position';
  @override
  String get captionSectionTiming => 'Timing';
  @override
  String get captionColorLight => 'Light';
  @override
  String get captionColorDark => 'Dark';
  @override
  String get captionReset => 'Reset style';
  @override
  String get captionNotVisibleAtTime => 'Caption is outside its visible time.';
  @override
  String get clipListSort => 'Sort clip list';
  @override
  String get clipSortTimeline => 'Timeline order';
  @override
  String get clipSortNameAscending => 'Filename A–Z';
  @override
  String get clipSortNameDescending => 'Filename Z–A';
  @override
  String get clipSortModifiedOldest => 'File modified date: oldest';
  @override
  String get clipSortModifiedNewest => 'File modified date: newest';
  @override
  String get clipDateUnavailable => 'Date unavailable';
  @override
  String get clipRepeatedSource => 'Repeated source';
  @override
  String get clipRepeatedDetails => 'Review repeated source occurrences';
  @override
  String get clipOccurrence => 'Occurrence';
  @override
  String get captionApplyAllStyles => 'Apply style to all clips';
  @override
  String get captionApplyAllStylesConfirm =>
      'Apply this caption appearance to every clip? Their text, placement, timing, and entrance will stay unchanged.';
  @override
  String get captionEntrance => 'Caption entrance';
  @override
  String get captionEntranceNone => 'None';
  @override
  String get captionEntranceFade => 'Fade';
  @override
  String get captionEntranceSlide => 'Slide in';
  @override
  String get captionTiming => 'Caption portion of clip';
  @override
  String get captionOverflowWarning =>
      'This text exceeds the safe area and will be shortened. Consider using fewer words.';
  @override
  String get captionReadingWarning =>
      'This text may be difficult to read in the selected time.';
  @override
  String get cancelExport => 'Cancel export';
  @override
  String get cancellingExport => 'Cancelling export';
  @override
  String get exportCancelled => 'Export cancelled';
  @override
  String get exportUnsupportedPlatform =>
      'Rendering is unavailable on this platform. Open the project on Android or Windows, macOS, or Linux with FFmpeg installed.';
  @override
  String get exportMissingFfmpeg =>
      'FFmpeg is missing. Install a supported FFmpeg build and make it available to the app, then try again.';
  @override
  String get exportMissingFilter =>
      'This video style needs an FFmpeg filter that is unavailable. Use a compatible FFmpeg build or remove the unsupported motion, transition, or caption.';
  @override
  String get exportMissingEncoder =>
      'The required video or audio encoder is unavailable. Use a compatible FFmpeg build for this platform.';
  @override
  String get exportMissingMuxer =>
      'MP4 output is unavailable in this FFmpeg build. Use a build with MP4 muxing support.';
  @override
  String get exportMissingFont =>
      'A supported caption font could not be found. Install a system font and try again without emoji or unsupported characters.';
  @override
  String get exportCapabilityProbeFailed =>
      'The app could not check the renderer. Check FFmpeg installation and permissions, then try again.';
  @override
  String get exportFailed =>
      'Export failed. Check the source files and available storage, then try again.';
  @override
  String get exportCapabilityChecking => 'Checking rendering support…';
  @override
  String get editorMotionUnavailable =>
      'Motion options are locked because this renderer does not support the required filter.';
  @override
  String get editorTransitionUnavailable =>
      'Transition options are locked because this renderer does not support the required filter.';
  @override
  String get editorCaptionUnavailable =>
      'Caption editing is locked because text rendering or its font is unavailable.';
  @override
  String get styleUnavailable =>
      'This style needs renderer features that are unavailable on this device.';
  @override
  String get homeTitle => 'Home';
  @override
  String get refreshSavedMedia => 'Refresh saved media';
  @override
  String get savedMedia => 'Saved media';
  @override
  String get savedMediaDescription =>
      'Reopen saved audio markers and pair them with new image selections.';
  @override
  String savedCount(int count) => '$count saved';
  @override
  String get savedAudio => 'Saved audio';
  @override
  String get noSavedAudio => 'No saved audio yet';
  @override
  String get saveMarkersForReuse =>
      'Save markers from the editor to reuse them here.';
  @override
  String get savedAssets => 'Saved assets';
  @override
  String get noSavedAssets => 'No saved assets yet';
  @override
  String get importImagesToLibrary =>
      'Import images in the Library to list them here.';
  @override
  String markerCount(int count) => '$count markers';
  @override
  String get open => 'Open';
  @override
  String get savedMediaLoadFailed => 'Saved media could not load';
  @override
  String get tryAgain => 'Try again';
  @override
  String get unknownDuration => 'Unknown duration';
  @override
  String get unknownSize => 'Unknown size';
  @override
  String get missingAudioPath => 'This saved audio does not have a file path.';
  @override
  String missingAudioAt(String path) => 'No audio file exists at $path.';
  @override
  String get savedAudioOpenFailed =>
      'Saved audio could not be opened. Check the file and try again.';
  @override
  String get navImport => 'Import';
  @override
  String get navLibrary => 'Library';
  @override
  String get navEditor => 'Editor';
  @override
  String get navExport => 'Export';
  @override
  String get importMediaTitle => 'Import media';

  @override
  String get importStepsSubtitle => 'Choose files in two simple steps';

  @override
  String get importOptionalStep => '1  OPTIONAL';

  @override
  String get importAddMusic => 'Add music';

  @override
  String get importMusicDescription =>
      'Use audio to create a video to the rhythm.';

  @override
  String get importNoAudio => 'No audio selected';

  @override
  String get importAudioFormats => 'WAV · can be added later';

  @override
  String get importAudioFormatsAndroid =>
      'WAV, MP3, M4A, AAC · can be added later';

  @override
  String get importChooseAudio => 'Choose audio from device';

  @override
  String get importChoosingFile => 'Waiting for file selection';

  @override
  String get importAnalyzing => 'Importing and analyzing audio';

  @override
  String get importAudioFailed => 'Audio import failed';

  @override
  String get importStop => 'Stop import';

  @override
  String get importRequiredStep => '2  REQUIRED';

  @override
  String get importChooseImagesTitle => 'Choose images';

  @override
  String get importImagesDescription => 'Choose images from your device.';

  @override
  String get importImagesProgress => 'Importing images';

  @override
  String get importChooseImages => 'Choose images from device';

  @override
  String get importImageFormats => 'JPG, PNG, WEBP · select multiple images';

  @override
  String get importNextStep =>
      'Next, select images in the library and open the editor.';

  @override
  String get importOpenImages => 'Open images';

  @override
  String get importRetry => 'Try again';

  @override
  String get importAudioTitle => 'Import audio';
  @override
  String get openEditor => 'Open editor';
  @override
  String get productName => 'Pictures to Videos';
  @override
  String get importTagline => 'Turn rhythm and still images into motion.';
  @override
  String get dropWav => 'Drop a WAV file here';
  @override
  String get importInstructions =>
      'Analyze a WAV file, or select any song and add markers yourself.';
  @override
  String get analyzeWav => 'Analyze WAV';
  @override
  String get selectSongOnly => 'Select song only';
  @override
  String get wavFromPath => 'WAV from path';
  @override
  String get songFromPath => 'Song from path';
  @override
  String get selectSongFromPath => 'Select song from path';
  @override
  String get importWavFromPath => 'Import WAV from path';
  @override
  String get absoluteAudioPath => 'Absolute audio path';
  @override
  String get selectAction => 'Select';
  @override
  String get importAction => 'Import';
  @override
  String get imageLibraryTitle => 'Image library';
  @override
  String get libraryDescription =>
      'Import images, stage the strongest frames, and send them into the beat-synced editor flow.';
  @override
  String get importImagesHeading => 'Import images';
  @override
  String get libraryEmptyTitle => 'Start with your images';
  @override
  String get libraryEmptyDescription =>
      'Add images to choose their order, motion and duration.';
  @override
  String get libraryExampleTitle => 'Your image queue';
  @override
  String get libraryExampleDescription =>
      'After importing, tap images to select them.';
  @override
  String libraryVisibleCount(int count) => 'Visible: $count';
  @override
  String libraryImportedCount(int count) => 'Imported: $count';
  @override
  String libraryInEditorCount(int count) => 'In editor: $count';
  @override
  String libraryStagedCount(int count) => 'Staged: $count';
  @override
  String librarySelectedCount(int count) => '$count selected';
  @override
  String libraryImagesAdded(int count) =>
      'Added $count image${count == 1 ? '' : 's'} to the library.';
  @override
  String libraryImagesRemoved(int count) =>
      'Removed $count image${count == 1 ? '' : 's'} from the app.';
  @override
  String get librarySearchHint => 'Search images, folders, or dates';
  @override
  String get librarySort => 'Sort';
  @override
  String get libraryFilterAll => 'All';
  @override
  String get libraryFilterRecent => 'Recent';
  @override
  String get libraryFilterStaged => 'Staged';
  @override
  String get libraryFilterFavorites => 'Favorites';
  @override
  String get librarySortNewest => 'Newest';
  @override
  String get librarySortOldest => 'Oldest';
  @override
  String get librarySortByName => 'Name';
  @override
  String get librarySortByFileSize => 'File size';
  @override
  String get libraryNoMatchingImages => 'No matching images';
  @override
  String get libraryTryDifferentSearch =>
      'Try another search, filter, or sort option.';
  @override
  String get libraryNoNewImages => 'No new supported images were added.';
  @override
  String get libraryImportFailed =>
      'Images could not be imported. Check the files and try again.';
  @override
  String get libraryFolderPathRequired =>
      'Enter a folder path before importing.';
  @override
  String get libraryFolderNotFound =>
      'That folder could not be found or opened. Check the path and permissions.';
  @override
  String get libraryFolderReadFailed =>
      'Images could not be read from the selected folder. Check access and try again.';
  @override
  String get libraryRemovalFailed =>
      'Imported images could not be removed. Try again.';
  @override
  String get folderPathUnavailableOnAndroid =>
      'Choose a folder with the Android folder picker. Only supported image files in that folder are imported.';
  @override
  String get libraryReadyForEditor => 'Ready for editor';
  @override
  String get libraryReviewStaged => 'Review staged';
  @override
  String get libraryGoToExport => 'Go to export';
  @override
  String get libraryImportMore => 'Import more';
  @override
  String get libraryStageAllImported => 'Stage all imported';
  @override
  String get libraryStageSelected => 'Stage selected';
  @override
  String get libraryClearSelection => 'Clear selection';
  @override
  String get libraryStage => 'Stage';
  @override
  String get libraryStaged => 'Staged';
  @override
  String get libraryReady => 'Ready';
  @override
  String get pasteFolderPath => 'Paste folder path';
  @override
  String get pickImages => 'Pick images';
  @override
  String get importFolder => 'Import folder';
  @override
  String openEditorCount(int count) => 'Open editor ($count)';
}
