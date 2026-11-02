import 'package:picturestovideos/app/localizations/languages/app_localization_en.dart';

class AppLocalizationNo extends AppLocalizationEn {
  @override
  String get editorTimeline => 'Tidslinje';
  @override
  String get editorMarkers => 'Markører';
  @override
  String get editorTools => 'Verktøy';
  @override
  String get editorSave => 'Lagre';
  @override
  String get editorDiscardChanges => 'Forkaste ulagrede endringer?';
  @override
  String get editorOutputRatio => 'Videoformat';
  @override
  String get editorClips => 'Klipp';
  @override
  String get editorQueue => 'Kø';
  @override
  String get editorQueueTitle => 'Bilder i kø';
  @override
  String get editorSelectAll => 'Velg alle';
  @override
  String editorAddSelected(int count) => 'Legg til valgte ($count)';
  @override
  String get editorImageSettings => 'Bildeinnstillinger';
  @override
  String get editorDisplayDuration => 'Visningsvarighet';
  @override
  String get editorOptionalCaption => 'Bildetekst (valgfritt)';
  @override
  String get editorSmoothAnimation => 'Bruk myk animasjon';
  @override
  String get editorFit => 'Tilpass';
  @override
  String get editorFill => 'Fyll';
  @override
  String get editorMore => 'Mer';
  @override
  String get editorText => 'Tekst';
  @override
  String get editorSpeed => 'Hastighet';
  @override
  String get editorCrop => 'Beskjær';
  @override
  String editorAddedCount(int count) => 'La til $count bilder';
  @override
  String get editorAlreadyOnTimeline =>
      'De valgte bildene er allerede på tidslinjen';
  @override
  String get cropZoom => 'Zoom';
  @override
  String get cropHorizontal => 'Vannrett plassering';
  @override
  String get cropVertical => 'Loddrett plassering';
  @override
  String get cropOnlyForFill =>
      'Zoom og plassering gjelder bare når Fyll rammen (beskjær) er valgt.';
  @override
  String get framingPreview => 'Forhåndsvisning av bildeutsnitt';
  @override
  String get centerImage => 'Sentrer bildet';
  @override
  String get applyFramingToAllClips => 'Bruk innramming på alle klipp';
  @override
  String get applyFramingToAllClipsConfirm =>
      'Bruke denne bildetilpasningen og beskjæringen på alle klipp?';
  @override
  String get cropPositionCentered => 'Midtstilt';
  @override
  String get cropDirectionLeft => 'venstre';
  @override
  String get cropDirectionRight => 'høyre';
  @override
  String get cropDirectionUp => 'øverste';
  @override
  String get cropDirectionDown => 'nederste';
  @override
  String cropZoomValue(String value) => '$value ganger';
  @override
  String cropOffsetValue(String direction, String percent) =>
      '$percent % mot $direction kant';
  @override
  String get homeTitle => 'Hjem';
  @override
  String get refreshSavedMedia => 'Oppdater lagrede medier';
  @override
  String get savedMedia => 'Lagrede medier';
  @override
  String get savedMediaDescription =>
      'Åpne lagrede lydmarkører igjen og bruk dem med nye bildevalg.';
  @override
  String savedCount(int count) => '$count lagret';
  @override
  String get savedAudio => 'Lagret lyd';
  @override
  String get noSavedAudio => 'Ingen lagret lyd ennå';
  @override
  String get saveMarkersForReuse =>
      'Lagre markører i redigereren for å bruke dem her.';
  @override
  String get savedAssets => 'Lagrede bilder';
  @override
  String get noSavedAssets => 'Ingen lagrede bilder ennå';
  @override
  String get importImagesToLibrary =>
      'Importer bilder i biblioteket for å vise dem her.';
  @override
  String markerCount(int count) => '$count markører';
  @override
  String get open => 'Åpne';
  @override
  String get savedMediaLoadFailed => 'Kunne ikke laste lagrede medier';
  @override
  String get tryAgain => 'Prøv igjen';
  @override
  String get unknownDuration => 'Ukjent varighet';
  @override
  String get unknownSize => 'Ukjent størrelse';
  @override
  String get missingAudioPath => 'Den lagrede lyden mangler filbane.';
  @override
  String missingAudioAt(String path) => 'Ingen lydfil finnes på $path.';
  @override
  String get savedAudioOpenFailed =>
      'Kunne ikke åpne den lagrede lyden. Kontroller filen og prøv igjen.';
  @override
  String get navImport => 'Importer';
  @override
  String get navLibrary => 'Bibliotek';
  @override
  String get navEditor => 'Redigerer';
  @override
  String get navExport => 'Eksporter';
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
  String queuedImages(int count) => 'Bilder i kø ($count)';
  @override
  String get queuedImagesPurpose =>
      'Bilder som venter på å bli lagt til i tidslinjen';
  @override
  String get bulkImageTools => 'Verktøy for flere bilder';
  @override
  String get reorder => 'Endre rekkefølge';
  @override
  String get done => 'Ferdig';
  @override
  String get selected => 'Valgt';
  @override
  String get returnToTimelineOrder => 'Gå tilbake til tidslinjerekkefølgen';
  @override
  String get reviewSequence => 'Se gjennom sekvensen';
  @override
  String get openTimeline => 'Åpne tidslinjen';
  @override
  String get clipActions => 'Klippvalg';
  @override
  String get noTimelineClips => 'Det er ingen klipp på tidslinjen ennå.';
  @override
  String clipMovedToPosition(int position) => 'Flyttet til plass $position';
  @override
  String get moveFailed =>
      'Dette klippet er ikke lenger tilgjengelig. Oppdater listen og prøv igjen.';
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
  @override
  String get clipCaptions => 'Tekst i sekvensen';
  @override
  String get removeClip => 'Fjern klipp';
  @override
  String get editCaption => 'Rediger tekst';
  @override
  String get editClip => 'Rediger klipp';
  @override
  String get captionTitle => 'Tittel';
  @override
  String get captionSupportingLine => 'Undertekst (valgfritt)';
  @override
  String get noCaption => 'Ingen tekst';
  @override
  String clipNumber(int number, String name) => 'Klipp $number: $name';
  @override
  String get editingPreview => 'Redigeringsforhåndsvisning';
  @override
  String get renderedPreview => 'Gjengitt forhåndsvisning';
  @override
  String get renderedPreviewSource =>
      'Generert av gjengivelsesprosessen for eksport.';
  @override
  String get renderedPreviewCurrent =>
      'Denne gjengitte forhåndsvisningen samsvarer med de gjeldende endringene.';
  @override
  String get renderedPreviewStale =>
      'Denne gjengitte forhåndsvisningen er utdatert. Oppdater den for å ta med de nyeste endringene.';
  @override
  String get renderPreview => 'Gjengi forhåndsvisning';
  @override
  String get refreshRenderedPreview => 'Oppdater gjengitt forhåndsvisning';
  @override
  String get motion => 'Bevegelse';
  @override
  String get styleDefault => 'Stilens standard';
  @override
  String get motionNone => 'Ingen';
  @override
  String get motionZoomIn => 'Sakte zoom inn';
  @override
  String get motionZoomOut => 'Sakte zoom ut';
  @override
  String get motionPan => 'Rolig panorering';
  @override
  String get motionIntensity => 'Bevegelsesmengde';
  @override
  String get motionSubtle => 'Forsiktig';
  @override
  String get motionMore => 'Mer bevegelse';
  @override
  String get savedProjects => 'Lagrede prosjekter';
  @override
  String get noSavedProjects =>
      'Lagre et prosjekt i redigereren for å åpne det her.';
  @override
  String get saveProject => 'Lagre prosjekt';
  @override
  String get projectSaved => 'Prosjektet er lagret';
  @override
  String get projectSaveFailed => 'Kunne ikke lagre prosjektet';
  @override
  String get projectsLoadFailed => 'Kunne ikke laste lagrede prosjekter';
  @override
  String get projectStorageRecoveryNotice =>
      'Noen lagrede prosjekter kunne ikke leses. Tilgjengelige prosjekter vises fortsatt, og en tidligere lagring ble gjenopprettet der det var mulig.';
  @override
  String get openProject => 'Åpne prosjekt';
  @override
  String get retry => 'Prøv igjen';
  @override
  String get missingProjectFiles => 'Noen prosjektfiler mangler';
  @override
  String get missingAudio => 'Musikk';
  @override
  String get missingImage => 'Bilde';
  @override
  String get relink => 'Koble til på nytt';
  @override
  String get relinkFailed => 'Den valgte filen kunne ikke åpnes.';
  @override
  String get relinkSaveReminder =>
      'Filen er koblet til. Lagre prosjektet for å beholde endringen.';
  @override
  String get transitionToNext => 'Overgang til neste klipp';
  @override
  String get transitionCut => 'Klipp';
  @override
  String get transitionDissolve => 'Overtoning';
  @override
  String get transitionSlide => 'Rolig skyv';
  @override
  String get transitionDuration => 'Overgangens varighet';
  @override
  String get transitionClamped => 'Overgangen forkortes for å passe klippene.';
  @override
  String get pacing => 'Tempo';
  @override
  String get pacingRelaxed => 'Rolig';
  @override
  String get pacingBalanced => 'Balansert';
  @override
  String get pacingEnergetic => 'Energisk';
  @override
  String get applyPacing => 'Lag sekvensforslag';
  @override
  String get pacingOverwriteTitle => 'Erstatte gjeldende klipptider?';
  @override
  String get pacingOverwriteMessage =>
      'Start- og sluttid for alle klipp beregnes på nytt, og bilder som ikke lenger er valgt, fjernes. Utsnitt, tekst, bevegelse og overganger beholdes for klipp som finnes fra før. Se gjennom tidslinjen etterpå.';
  @override
  String get confirmPacing => 'Bruk nye tider';
  @override
  String get pacingApplied => 'Nytt tempo er brukt';
  @override
  String get undo => 'Angre';
  @override
  String get pacingExplanation =>
      'Starter ved begynnelsen av musikken. Nye bilder brukes én gang, og nærliggende musikkmarkører kan flytte klippepunktene. Gjentatte klipp beholdes. Sekvensen slutter ved musikklengden eller foreslått lengde, avhengig av hva som kommer først.';
  @override
  String get pacingManualNotice =>
      'Sekvensen har endringer. Endringer i kø og markører bygger den ikke automatisk på nytt. Et nytt forslag endrer tidspunkter og fjerner klipp for bilder som ikke lenger er i køen.';
  @override
  String expectedVideoDuration(String duration) =>
      'Forventet videolengde: $duration';
  @override
  String pacingTimingImpact({
    required int changed,
    required int total,
    required int added,
    required int removed,
  }) =>
      'Tidsendringer: $changed av $total foreslåtte klipp flyttes; $added legges til; $removed fjernes.';
  @override
  String pacingClipDurationRange(String shortest, String longest) =>
      'Foreslåtte klipplengder: $shortest–$longest.';
  @override
  String get clipDuration => 'Klippets varighet (sekunder)';
  @override
  String get snapToMarkers => 'Fest til musikkmarkører';
  @override
  String get snapDescription => 'Fest til en markør innenfor 0,25 sekunder.';
  @override
  String durationRange(String maximum) =>
      'Skriv inn en varighet fra 0,1 til $maximum sekunder.';
  @override
  String get musicSettings => 'Musikkområde og inn- og uttoning';
  @override
  String get musicStart => 'Start (sekunder)';
  @override
  String get musicEnd => 'Slutt (sekunder, valgfritt)';
  @override
  String get musicFadeIn => 'Inntoning (sekunder)';
  @override
  String get musicFadeOut => 'Uttoning (sekunder)';
  @override
  String get musicRangeExplanation =>
      'Videoen starter ved valgt startpunkt i musikken. Musikken slutter ved valgt sluttpunkt eller når videoen slutter; kort musikk etterfølges av stillhet. Inn- og uttoning begrenses til halvparten av det hørbare området.';
  @override
  String get musicRangeInvalid =>
      'Angi et gyldig område innenfor musikken og ikke-negative varigheter.';
  @override
  String get musicPlaybackFailed =>
      'Musikkinnstillingene er lagret, men avspillingen kunne ikke klargjøres.';
  @override
  String get visualStyle => 'Visuell stil';
  @override
  String get styleCalm => 'Rolige minner';
  @override
  String get styleCalmDescription =>
      'Varm og dempet, med rolige bevegelser og myke overtoninger.';
  @override
  String get styleStorybook => 'Historiebok';
  @override
  String get styleStorybookDescription =>
      'Ettertenksomme utsnitt og tydelige titler for personlige historier.';
  @override
  String get styleCelebration => 'Feiring';
  @override
  String get styleCelebrationDescription =>
      'Livligere bevegelser, korte tekster og rolige skyveoverganger.';
  @override
  String get styleOverridesPreserved =>
      'Stilbytte endrer standardene og beholder klippendringene og sideforholdet.';
  @override
  String get aspectRatio => 'Sideforhold';
  @override
  String get legacyStyle => 'Lagret egendefinert stil';
  @override
  String get captionPlacement => 'Tekstplassering';
  @override
  String get captionBottom => 'Nederst';
  @override
  String get captionCenter => 'Midten';
  @override
  String get captionTop => 'Øverst';
  @override
  String get captionStyle => 'Forhåndsinnstilling';
  @override
  String get captionStyleClean => 'Ren';
  @override
  String get captionStyleSoft => 'Myk bakgrunn';
  @override
  String get captionStyleBold => 'Tydelig';
  @override
  String get captionSize => 'Tekststørrelse';
  @override
  String get captionFont => 'Skrift';
  @override
  String get captionFontUnavailable =>
      'Skriftvalg er utilgjengelig fordi eksport bruker én funnet systemskrift. Forhåndsvisningen bruker samme nøytrale tekststil.';
  @override
  String get captionTextColor => 'Tekstfarge';
  @override
  String get captionBackdrop => 'Bakgrunn';
  @override
  String get captionBackdropNone => 'Ingen';
  @override
  String get captionBackdropSoft => 'Mykt panel';
  @override
  String get captionBackdropStrong => 'Tydelig panel';
  @override
  String get captionBackdropClassic => 'Klassiske tekstbokser';
  @override
  String get captionBackdropUnavailable =>
      'Panelbakgrunner er utilgjengelige fordi denne rendereren mangler drawbox-filteret.';
  @override
  String get captionNoBackdropWarning =>
      'Uten bakgrunn varierer lesbarheten med motivet. Bruk et panel for jevnere kontrast.';
  @override
  String get captionLowContrastWarning =>
      'Mørk tekst på mørk bakgrunn kan være vanskelig å lese. Velg lys tekst.';
  @override
  String get captionSectionText => 'Tekst';
  @override
  String get captionSectionStyle => 'Stil';
  @override
  String get captionSectionPosition => 'Plassering';
  @override
  String get captionSectionTiming => 'Tid';
  @override
  String get captionColorLight => 'Lys';
  @override
  String get captionColorDark => 'Mørk';
  @override
  String get captionReset => 'Tilbakestill stil';
  @override
  String get captionNotVisibleAtTime =>
      'Teksten vises ikke på dette tidspunktet.';
  @override
  String get clipListSort => 'Sorter klipplisten';
  @override
  String get clipSortTimeline => 'Tidslinjerekkefølge';
  @override
  String get clipSortNameAscending => 'Filnavn A–Å';
  @override
  String get clipSortNameDescending => 'Filnavn Å–A';
  @override
  String get clipSortModifiedOldest => 'Filendret dato: eldste';
  @override
  String get clipSortModifiedNewest => 'Filendret dato: nyeste';
  @override
  String get clipDateUnavailable => 'Dato utilgjengelig';
  @override
  String get clipRepeatedSource => 'Gjentatt kilde';
  @override
  String get clipRepeatedDetails => 'Se gjentatte kildeforekomster';
  @override
  String get clipOccurrence => 'Forekomst';
  @override
  String get captionApplyAllStyles => 'Bruk stil på alle klipp';
  @override
  String get captionApplyAllStylesConfirm =>
      'Bruke dette utseendet på alle klipp? Tekst, plassering, tid og inngang beholdes.';
  @override
  String get captionEntrance => 'Tekstens inngang';
  @override
  String get captionEntranceNone => 'Ingen';
  @override
  String get captionEntranceFade => 'Toning';
  @override
  String get captionEntranceSlide => 'Skyv inn';
  @override
  String get captionTiming => 'Tekstens del av klippet';
  @override
  String get captionOverflowWarning =>
      'Teksten overstiger det trygge området og blir forkortet. Vurder å bruke færre ord.';
  @override
  String get captionReadingWarning =>
      'Teksten kan være vanskelig å lese på den valgte tiden.';
  @override
  String get cancelExport => 'Avbryt eksport';
  @override
  String get cancellingExport => 'Avbryter eksport';
  @override
  String get exportCancelled => 'Eksporten er avbrutt';
  @override
  String get exportUnsupportedPlatform =>
      'Eksportering er ikke tilgjengelig på denne plattformen. Åpne prosjektet på Android eller Windows, macOS eller Linux med FFmpeg installert.';
  @override
  String get exportMissingFfmpeg =>
      'FFmpeg mangler. Installer en støttet FFmpeg-versjon som appen finner, og prøv igjen.';
  @override
  String get exportMissingFilter =>
      'Denne videostilen krever et FFmpeg-filter som ikke er tilgjengelig. Bruk en kompatibel FFmpeg-versjon eller fjern den aktuelle bevegelsen, overgangen eller teksten.';
  @override
  String get exportMissingEncoder =>
      'Nødvendig video- eller lydkoder er ikke tilgjengelig. Bruk en kompatibel FFmpeg-versjon for denne plattformen.';
  @override
  String get exportMissingMuxer =>
      'MP4-utdata er ikke tilgjengelig i denne FFmpeg-versjonen. Bruk en versjon med støtte for MP4.';
  @override
  String get exportMissingFont =>
      'Fant ingen støttet tekstskrift. Installer en systemskrift, og prøv igjen uten emoji eller tegn som ikke støttes.';
  @override
  String get exportCapabilityProbeFailed =>
      'Appen kunne ikke kontrollere gjengiveren. Kontroller FFmpeg-installasjonen og tillatelsene, og prøv igjen.';
  @override
  String get exportFailed =>
      'Eksporten mislyktes. Kontroller kildefilene og ledig lagringsplass, og prøv igjen.';
  @override
  String get exportCapabilityChecking => 'Kontrollerer støtte for gjengivelse…';
  @override
  String get editorMotionUnavailable =>
      'Bevegelsesvalg er låst fordi gjengiveren ikke støtter det nødvendige filteret.';
  @override
  String get editorTransitionUnavailable =>
      'Overgangsvalg er låst fordi gjengiveren ikke støtter det nødvendige filteret.';
  @override
  String get editorCaptionUnavailable =>
      'Teksting er låst fordi tekstrendering eller skrifttypen ikke er tilgjengelig.';
  @override
  String get styleUnavailable =>
      'Denne stilen krever gjengivelsesfunksjoner som ikke er tilgjengelige på denne enheten.';
  @override
  String get importMediaTitle => 'Importer medier';

  @override
  String get importStepsSubtitle => 'Velg filer i to enkle steg';

  @override
  String get importOptionalStep => '1  VALGFRITT';

  @override
  String get importAddMusic => 'Legg til musikk';

  @override
  String get importMusicDescription => 'Bruk lyd for å lage video til rytmen.';

  @override
  String get importNoAudio => 'Ingen lyd valgt';

  @override
  String get importAudioFormats => 'WAV · kan legges til senere';

  @override
  String get importAudioFormatsAndroid =>
      'WAV, MP3, M4A, AAC · kan legges til senere';

  @override
  String get importChooseAudio => 'Velg lyd fra enheten';

  @override
  String get importChoosingFile => 'Venter på filvalg';

  @override
  String get importAnalyzing => 'Importerer og analyserer lyd';

  @override
  String get importAudioFailed => 'Lydimporten mislyktes';

  @override
  String get importStop => 'Stopp import';

  @override
  String get importRequiredStep => '2  PÅKREVD';

  @override
  String get importChooseImagesTitle => 'Velg bilder';

  @override
  String get importImagesDescription => 'Bruk bilder fra enheten.';

  @override
  String get importImagesProgress => 'Importerer bilder';

  @override
  String get importChooseImages => 'Velg bilder fra enheten';

  @override
  String get importImageFormats =>
      'JPG, PNG, WEBP · velg flere bilder samtidig';

  @override
  String get importNextStep =>
      'Velg deretter bilder i biblioteket og åpne editoren.';

  @override
  String get importOpenImages => 'Åpne bilder';

  @override
  String get importRetry => 'Prøv igjen';

  @override
  String get importAudioTitle => 'Importer lyd';
  @override
  String get openEditor => 'Åpne redigering';
  @override
  String get productName => 'Bilder til videoer';
  @override
  String get importTagline => 'Gjør rytme og stillbilder levende.';
  @override
  String get dropWav => 'Slipp en WAV-fil her';
  @override
  String get importInstructions =>
      'Analyser en WAV-fil, eller velg en sang og legg til markører selv.';
  @override
  String get analyzeWav => 'Analyser WAV';
  @override
  String get selectSongOnly => 'Velg bare sang';
  @override
  String get wavFromPath => 'WAV fra filbane';
  @override
  String get songFromPath => 'Sang fra filbane';
  @override
  String get selectSongFromPath => 'Velg sang fra filbane';
  @override
  String get importWavFromPath => 'Importer WAV fra filbane';
  @override
  String get absoluteAudioPath => 'Fullstendig lydbane';
  @override
  String get selectAction => 'Velg';
  @override
  String get importAction => 'Importer';
  @override
  String get imageLibraryTitle => 'Bildebibliotek';
  @override
  String get libraryDescription =>
      'Importer bilder, velg de beste motivene, og send dem til den taktsynkroniserte redigeringen.';
  @override
  String get importImagesHeading => 'Importer bilder';
  @override
  String get libraryEmptyTitle => 'Start med bildene dine';
  @override
  String get libraryEmptyDescription =>
      'Legg til bilder for å velge rekkefølge, bevegelse og varighet.';
  @override
  String get libraryExampleTitle => 'Slik vil bildekøen se ut';
  @override
  String get libraryExampleDescription =>
      'Etter import kan du trykke på bilder for å velge dem.';
  @override
  String libraryVisibleCount(int count) => 'Synlige: $count';
  @override
  String libraryImportedCount(int count) => 'Importert: $count';
  @override
  String libraryInEditorCount(int count) => 'I redigering: $count';
  @override
  String libraryStagedCount(int count) => 'Valgt: $count';
  @override
  String librarySelectedCount(int count) => '$count valgt';
  @override
  String libraryImagesAdded(int count) =>
      'La til $count bilde${count == 1 ? '' : 'r'} i biblioteket.';
  @override
  String libraryImagesRemoved(int count) =>
      'Fjernet $count bilde${count == 1 ? '' : 'r'} fra appen.';
  @override
  String get librarySearchHint => 'Søk etter bilder, mapper eller datoer';
  @override
  String get librarySort => 'Sorter';
  @override
  String get libraryFilterAll => 'Alle';
  @override
  String get libraryFilterRecent => 'Nylige';
  @override
  String get libraryFilterStaged => 'Valgte';
  @override
  String get libraryFilterFavorites => 'Favoritter';
  @override
  String get librarySortNewest => 'Nyeste';
  @override
  String get librarySortOldest => 'Eldste';
  @override
  String get librarySortByName => 'Navn';
  @override
  String get librarySortByFileSize => 'Filstørrelse';
  @override
  String get libraryNoMatchingImages => 'Ingen bilder samsvarer';
  @override
  String get libraryTryDifferentSearch =>
      'Prøv et annet søk, filter eller sorteringsvalg.';
  @override
  String get libraryNoNewImages => 'Ingen nye støttede bilder ble lagt til.';
  @override
  String get libraryImportFailed =>
      'Kunne ikke importere bilder. Kontroller filene og prøv igjen.';
  @override
  String get libraryFolderPathRequired =>
      'Oppgi en mappebane før du importerer.';
  @override
  String get libraryFolderNotFound =>
      'Fant eller åpnet ikke mappen. Kontroller banen og tilgangen.';
  @override
  String get libraryFolderReadFailed =>
      'Kunne ikke lese bilder fra den valgte mappen. Kontroller tilgangen og prøv igjen.';
  @override
  String get libraryRemovalFailed =>
      'Kunne ikke fjerne importerte bilder. Prøv igjen.';
  @override
  String get folderPathUnavailableOnAndroid =>
      'Velg en mappe med Androids mappevelger. Bare støttede bildefiler i mappen importeres.';
  @override
  String get libraryReadyForEditor => 'Klar for redigering';
  @override
  String get libraryReviewStaged => 'Se gjennom valgte';
  @override
  String get libraryGoToExport => 'Gå til eksport';
  @override
  String get libraryImportMore => 'Importer flere';
  @override
  String get libraryStageAllImported => 'Velg alle importerte';
  @override
  String get libraryStageSelected => 'Velg markerte';
  @override
  String get libraryClearSelection => 'Fjern markering';
  @override
  String get libraryStage => 'Velg';
  @override
  String get libraryStaged => 'Valgt';
  @override
  String get libraryReady => 'Klar';
  @override
  String get pasteFolderPath => 'Lim inn mappebane';
  @override
  String get pickImages => 'Velg bilder';
  @override
  String get importFolder => 'Importer mappe';
  @override
  String openEditorCount(int count) => 'Åpne redigering ($count)';
}
