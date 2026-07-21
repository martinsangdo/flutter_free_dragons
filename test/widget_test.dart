// Widget smoke test for the home screen. The full app boots through a splash
// screen that touches platform plugins (shared_preferences) and an isolate, so
// we test the home screen directly here and cover the game logic in
// solver_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:free_the_key/screens/home_screen.dart';

void main() {
  testWidgets('Home screen shows title and modes', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    expect(find.text('FREE THE KEY'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('LEVELS'), findsOneWidget);
    expect(find.text('ENDLESS'), findsOneWidget);
  });
}
