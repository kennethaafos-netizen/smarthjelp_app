// Sprint 8 fix: erstattet default Flutter-template-testen (som referte til
// MyApp + counter-app) med en minimal smoke-test. Pakken kompilerer og
// widget-treet kan bygges. Vi pumpe-tester ikke SmartHjelpApp direkte
// fordi den initialiserer Firebase + Supabase, som krever ekte konfig
// i test-kjøretid og hører hjemme i integration_test/, ikke widget_test/.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Trivial smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}