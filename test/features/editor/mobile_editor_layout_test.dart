import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/features/editor/mobile_editor_screen.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(430, 932),
    const Size(568, 320),
  ]) {
    testWidgets('mobile editor fits $size at 1.3 text scale', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: MobileEditorScreen(
              project: null,
              beatMap: null,
              playback: null,
              audioPath: null,
              queueCount: 56,
              canExport: false,
              openAdvanced: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Clips'), findsOneWidget);
      expect(find.text('Queue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
