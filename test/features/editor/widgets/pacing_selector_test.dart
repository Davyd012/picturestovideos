import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/app/localizations/languages/app_localization_en.dart';
import 'package:picturestovideos/app/localizations/languages/app_localization_no.dart';
import 'package:picturestovideos/app/localizations/languages/app_localization_ru.dart';
import 'package:picturestovideos/core/timeline/domain/pacing_suggestion_summary.dart';
import 'package:picturestovideos/core/timeline/domain/sequence_pacing.dart';
import 'package:picturestovideos/features/editor/widgets/pacing_selector.dart';

void main() {
  test('pacing impact is available in every supported locale', () {
    const english = AppLocalizationEn();
    const norwegian = AppLocalizationNo();
    const russian = AppLocalizationRu();
    expect(english.pacingExplanation, contains('music markers'));
    expect(norwegian.pacingExplanation, contains('musikkmarkører'));
    expect(russian.pacingExplanation, contains('музыкальные метки'));
    for (final localization in [english, norwegian, russian]) {
      expect(
        localization.pacingTimingImpact(
          changed: 2,
          total: 3,
          added: 1,
          removed: 0,
        ),
        contains('2'),
      );
      expect(
        localization.pacingClipDurationRange('00:02', '00:04'),
        contains('00:02'),
      );
      expect(
        localization.pacingClipDurationRange('00:02', '00:04'),
        contains('00:04'),
      );
    }
  });

  testWidgets('pacing choices require an explicit action to rebuild', (
    tester,
  ) async {
    SequencePacing? choice;
    var applied = false;
    var undone = false;
    Future<void> pumpSelector(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PacingSelector(
            value: SequencePacing.balanced,
            hasManualEdits: true,
            duration: const Duration(seconds: 7),
            suggestionSummary: const PacingSuggestionSummary(
              clipCount: 3,
              changedCount: 2,
              addedCount: 1,
              removedCount: 0,
              shortestClip: Duration(seconds: 2),
              longestClip: Duration(seconds: 4),
            ),
            onChanged: (value) => choice = value,
            onApply: () async => applied = true,
            onUndo: () => undone = true,
          ),
        ),
      ),
    );
    await pumpSelector(tester);
    expect(find.text('Expected video duration: 00:07'), findsOneWidget);
    expect(
      find.text(
        'Timing changes: 2 of 3 suggested clips move; 1 added; 0 removed.',
      ),
      findsOneWidget,
    );
    expect(find.text('Suggested clip lengths: 00:02–00:04.'), findsOneWidget);
    expect(find.textContaining('Your sequence has edits.'), findsOneWidget);
    await tester.tap(find.text('Relaxed'));
    expect(choice, SequencePacing.relaxed);
    expect(applied, isFalse);
    await tester.tap(find.text('Create sequence suggestion'));
    await tester.pumpAndSettle();
    expect(applied, isFalse);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(applied, isFalse);
    await tester.tap(find.text('Create sequence suggestion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply new timing'));
    await tester.pumpAndSettle();
    expect(applied, isTrue);
    expect(find.text('New pacing applied'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    expect(undone, isTrue);
  });
}
