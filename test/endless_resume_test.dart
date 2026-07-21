import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:free_the_key/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openEndless(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();
    await tester.tap(find.text('ENDLESS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('endless starts at #1 with no saved progress', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await openEndless(tester);
    expect(find.text('ENDLESS #1'), findsOneWidget);
  });

  testWidgets('endless resumes after the last cleared level', (tester) async {
    // 4 levels cleared -> next unplayed is index 4, shown as "#5".
    SharedPreferences.setMockInitialValues({'endless_best': 4});
    await openEndless(tester);
    expect(find.text('ENDLESS #5'), findsOneWidget);
  });
}
