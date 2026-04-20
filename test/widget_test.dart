import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fi_foll/main.dart';

void main() {
  testWidgets('App Launches and Add Person Dialog Opens', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FiFollApp());

    // Verify that the title 'Hesaplar' is shown
    expect(find.text('Hesaplar'), findsOneWidget);

    // Verify empty state text is shown (checked in consumer Column now)
    // expect(find.text('Henüz hesap yok.'), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add_circle_rounded));
    await tester.pumpAndSettle();

    // Verify that the Add Person dialog appears
    expect(find.text('Kişi Ekle'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
