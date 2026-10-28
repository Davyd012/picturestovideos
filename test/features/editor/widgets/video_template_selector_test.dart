import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:picturestovideos/app/localizations/app_localizations.dart';
import 'package:picturestovideos/core/templates/domain/video_template.dart';
import 'package:picturestovideos/core/templates/domain/video_templates.dart';
import 'package:picturestovideos/core/preview/domain/render_capabilities.dart';
import 'package:picturestovideos/features/editor/widgets/video_template_selector.dart';

void main() {
  testWidgets('shows localized cards and selects a style at narrow widths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    VideoTemplate? chosen;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('no'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: MediaQuery(
              data: const MediaQueryData(
                disableAnimations: true,
                size: Size(320, 800),
              ),
              child: VideoTemplateSelector(
                selectedTemplate: VideoTemplates.calmMemories,
                renderCapabilities: _capableRenderer(),
                gateRenderCapabilities: true,
                clipCount: 2,
                onTemplateSelected: (style) => chosen = style,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rolige minner'), findsOneWidget);
    expect(find.text('Historiebok'), findsOneWidget);
    expect(find.text('Feiring'), findsOneWidget);
    await tester.tap(find.text('Historiebok'));
    expect(chosen?.id, VideoTemplates.storybook.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not offer styles whose renderer features are missing', (
    tester,
  ) async {
    VideoTemplate? chosen;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: SingleChildScrollView(
            child: VideoTemplateSelector(
              selectedTemplate: VideoTemplates.calmMemories,
              renderCapabilities: RenderCapabilities(
                platformSupported: true,
                ffmpegAvailable: true,
                filters: {'scale', 'crop', 'pad', 'drawbox'},
                encoders: {'libx264'},
                muxers: {'mp4'},
                videoEncoder: 'libx264',
              ),
              gateRenderCapabilities: true,
              clipCount: 2,
              onTemplateSelected: (style) => chosen = style,
            ),
          ),
        ),
      ),
    );

    expect(
      find.text(
        'This style needs renderer features that are unavailable on this device.',
      ),
      findsNWidgets(3),
    );
    await tester.tap(find.text('Storybook'));
    expect(chosen, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'waits for a successful capability probe before enabling styles',
    (tester) async {
      VideoTemplate? chosen;
      Widget app({bool probeFailed = false}) => MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: VideoTemplateSelector(
            selectedTemplate: VideoTemplates.calmMemories,
            gateRenderCapabilities: true,
            capabilityProbeFailed: probeFailed,
            onTemplateSelected: (style) => chosen = style,
          ),
        ),
      );

      await tester.pumpWidget(app());
      expect(find.text('Checking rendering support…'), findsOneWidget);
      await tester.tap(find.text('Storybook'));
      expect(chosen, isNull);

      await tester.pumpWidget(app(probeFailed: true));
      expect(
        find.text(
          'The app could not check the renderer. Check FFmpeg installation and permissions, then try again.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Storybook'));
      expect(chosen, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}

RenderCapabilities _capableRenderer() => RenderCapabilities(
  platformSupported: true,
  ffmpegAvailable: true,
  filters: {'scale', 'crop', 'pad', 'zoompan', 'xfade', 'drawbox'},
  encoders: {'libx264'},
  muxers: {'mp4'},
  videoEncoder: 'libx264',
);
