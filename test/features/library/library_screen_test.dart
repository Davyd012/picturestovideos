import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picturestovideos/features/library/library_screen.dart';

void main() {
  testWidgets('library screen shows search and category controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LibraryScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Media library'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Giphy'), findsOneWidget);
    expect(find.text('Obsidian_Range_A01.mp4'), findsOneWidget);
  });

  testWidgets('library screen filters items by search query', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LibraryScreen())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'neon');
    await tester.pumpAndSettle();

    expect(find.text('Neon_City_D04.mp4'), findsOneWidget);
    expect(find.text('Obsidian_Range_A01.mp4'), findsNothing);
  });
}
