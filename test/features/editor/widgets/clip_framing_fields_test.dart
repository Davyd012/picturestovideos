import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/app/localizations/app_localizations.dart';
import 'package:picturestovideos/app/localizations/languages/app_localization_en.dart';
import 'package:picturestovideos/app/localizations/languages/app_localization_no.dart';
import 'package:picturestovideos/app/localizations/languages/app_localization_ru.dart';
import 'package:picturestovideos/core/preview/domain/image_crop_transform.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/features/editor/widgets/clip_framing_fields.dart';

void main() {
  testWidgets('contain mode explains and disables crop-only controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClipFramingFields(
              imageFit: VideoTemplateImageFit.contain,
              crop: const ImageCropTransform(zoom: 2, focalX: 0.5),
              sourcePath: '',
              aspectRatio: 16 / 9,
              onFitChanged: (_) {},
              onCropChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.text(
        'Zoom and position apply only when Fill frame (crop) is selected.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widgetList<Slider>(find.byType(Slider))
          .every((slider) => slider.onChanged == null),
      isTrue,
    );
  });

  testWidgets('framing controls expose values and allow centering the image', (
    tester,
  ) async {
    ImageCropTransform? updatedCrop;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClipFramingFields(
              imageFit: VideoTemplateImageFit.cover,
              crop: const ImageCropTransform(
                zoom: 2,
                focalX: 0.5,
                focalY: -0.25,
              ),
              sourcePath: '',
              aspectRatio: 16 / 9,
              onFitChanged: (_) {},
              onCropChanged: (value) => updatedCrop = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text('2.0 times'), findsOneWidget);
    expect(find.text('50% toward the right edge'), findsOneWidget);
    expect(find.text('25% toward the top edge'), findsOneWidget);
    expect(find.bySemanticsLabel('Framing preview'), findsOneWidget);

    expect(find.bySemanticsLabel('Horizontal position'), findsOneWidget);
    final horizontalSlider = tester.getSemantics(
      find.bySemanticsLabel('Horizontal position'),
    );
    final horizontalSliderWidget = tester.widget<Slider>(
      find.byType(Slider).at(1),
    );
    expect(
      horizontalSliderWidget.semanticFormatterCallback!(0.5),
      '50% toward the right edge',
    );
    expect(
      horizontalSlider.getSemanticsData().value,
      '50% toward the right edge',
    );
    expect(horizontalSlider.getSemanticsData().actions, isNot(0));

    await tester.tap(find.text('Center image'));
    await tester.pump();
    expect(updatedCrop, ImageCropTransform.centered);
  });

  testWidgets('framing fields fit narrow screens with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ClipFramingFields(
                imageFit: VideoTemplateImageFit.cover,
                crop: ImageCropTransform.centered,
                sourcePath: '',
                aspectRatio: 16 / 9,
                onFitChanged: (_) {},
                onCropChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Center image'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(3));
  });

  testWidgets('crop sliders respond to keyboard arrow keys', (tester) async {
    ImageCropTransform? updatedCrop;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClipFramingFields(
              imageFit: VideoTemplateImageFit.cover,
              crop: ImageCropTransform.centered,
              sourcePath: '',
              aspectRatio: 16 / 9,
              onFitChanged: (_) {},
              onCropChanged: (value) => updatedCrop = value,
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byType(Slider).first);
    await tester.tap(find.byType(Slider).first);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(updatedCrop, isNotNull);
    expect(updatedCrop!.zoom, greaterThan(1));
  });

  test('framing labels and values are localized', () {
    final localizations = [
      (
        const AppLocalizationEn(),
        'Framing preview',
        'Center image',
        '2.0 times',
      ),
      (
        const AppLocalizationNo(),
        'Forhåndsvisning av bildeutsnitt',
        'Sentrer bildet',
        '2.0 ganger',
      ),
      (
        const AppLocalizationRu(),
        'Предпросмотр кадрирования',
        'По центру',
        'увеличение 2.0',
      ),
    ];

    for (final (localization, preview, center, zoomValue) in localizations) {
      expect(localization.framingPreview, preview);
      expect(localization.centerImage, center);
      expect(localization.cropZoomValue('2.0'), zoomValue);
      expect(
        localization.cropOffsetValue(localization.cropDirectionRight, '50'),
        isNotEmpty,
      );
    }
  });

  test('editing and rendered preview status is localized', () {
    expect(const AppLocalizationEn().renderedPreview, 'Rendered preview');
    expect(
      const AppLocalizationEn().renderedPreviewSource,
      'Generated by the export rendering pipeline.',
    );
    expect(
      const AppLocalizationEn().renderedPreviewStale,
      'This rendered preview is out of date. Refresh it to include the latest edits.',
    );
    expect(
      const AppLocalizationEn().refreshRenderedPreview,
      'Refresh rendered preview',
    );

    expect(
      const AppLocalizationNo().renderedPreview,
      'Gjengitt forhåndsvisning',
    );
    expect(
      const AppLocalizationNo().renderedPreviewSource,
      'Generert av gjengivelsesprosessen for eksport.',
    );
    expect(
      const AppLocalizationNo().renderedPreviewStale,
      'Denne gjengitte forhåndsvisningen er utdatert. Oppdater den for å ta med de nyeste endringene.',
    );
    expect(
      const AppLocalizationNo().refreshRenderedPreview,
      'Oppdater gjengitt forhåndsvisning',
    );

    expect(
      const AppLocalizationRu().renderedPreview,
      'Предпросмотр после рендеринга',
    );
    expect(
      const AppLocalizationRu().renderedPreviewSource,
      'Создан с помощью процесса рендеринга экспорта.',
    );
    expect(
      const AppLocalizationRu().renderedPreviewStale,
      'Этот предпросмотр устарел. Обновите его, чтобы учесть последние изменения.',
    );
    expect(
      const AppLocalizationRu().refreshRenderedPreview,
      'Обновить предпросмотр',
    );
  });

  test('unsupported editor feature messages are localized', () {
    expect(
      const AppLocalizationEn().styleUnavailable,
      'This style needs renderer features that are unavailable on this device.',
    );
    expect(
      const AppLocalizationNo().styleUnavailable,
      'Denne stilen krever gjengivelsesfunksjoner som ikke er tilgjengelige på denne enheten.',
    );
    expect(
      const AppLocalizationRu().styleUnavailable,
      'Для этого стиля нужны функции рендеринга, недоступные на этом устройстве.',
    );

    expect(
      const AppLocalizationEn().editorMotionUnavailable,
      'Motion options are locked because this renderer does not support the required filter.',
    );
    expect(
      const AppLocalizationNo().editorMotionUnavailable,
      'Bevegelsesvalg er låst fordi gjengiveren ikke støtter det nødvendige filteret.',
    );
    expect(
      const AppLocalizationRu().editorMotionUnavailable,
      'Настройки движения заблокированы: средство рендеринга не поддерживает необходимый фильтр.',
    );

    expect(
      const AppLocalizationEn().editorTransitionUnavailable,
      'Transition options are locked because this renderer does not support the required filter.',
    );
    expect(
      const AppLocalizationNo().editorTransitionUnavailable,
      'Overgangsvalg er låst fordi gjengiveren ikke støtter det nødvendige filteret.',
    );
    expect(
      const AppLocalizationRu().editorTransitionUnavailable,
      'Настройки переходов заблокированы: средство рендеринга не поддерживает необходимый фильтр.',
    );

    expect(
      const AppLocalizationEn().editorCaptionUnavailable,
      'Caption editing is locked because text rendering or its font is unavailable.',
    );
    expect(
      const AppLocalizationNo().editorCaptionUnavailable,
      'Teksting er låst fordi tekstrendering eller skrifttypen ikke er tilgjengelig.',
    );
    expect(
      const AppLocalizationRu().editorCaptionUnavailable,
      'Редактирование титров заблокировано: недоступны рендеринг текста или нужный шрифт.',
    );
  });
}
