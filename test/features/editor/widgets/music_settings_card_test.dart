import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/core/audio/domain/audio_mix.dart';
import 'package:picturestovideos/features/editor/widgets/music_settings_card.dart';

void main() {
  testWidgets('validates and applies the selected music range', (tester) async {
    AudioMix? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MusicSettingsCard(
            mix: const AudioMix(),
            sourceDuration: const Duration(seconds: 10),
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Music range and fades'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Start (seconds)'),
      '2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'End (seconds, optional)'),
      '12',
    );
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Enter a valid range within the music and non-negative fade durations.',
      ),
      findsOneWidget,
    );
    expect(selected, isNull);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'End (seconds, optional)'),
      '8',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Fade in (seconds)'),
      '1',
    );
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(selected?.start, const Duration(seconds: 2));
    expect(selected?.end, const Duration(seconds: 8));
    expect(selected?.fadeIn, const Duration(seconds: 1));
  });
}
