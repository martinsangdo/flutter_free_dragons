import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:free_the_key/data/egg_sprites.dart';
import 'package:free_the_key/logic/game_engine.dart';
import 'package:free_the_key/data/levels_data.dart';
import 'package:free_the_key/widgets/game_board.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every declared egg sprite decodes from the bundle',
      (tester) async {
    await EggSprites.load();
    expect(EggSprites.isLoaded, isTrue);
    // A missing or misdeclared asset would throw in load() above; this catches
    // the subtler case of the folder being pruned to fewer files.
    for (int i = 0; i < 200; i++) {
      expect(EggSprites.forLevel(i), isNotNull);
    }
    expect(EggSprites.sample, isNotNull);
  });

  testWidgets('a level always gets the same egg', (tester) async {
    await EggSprites.load();
    for (final n in [1, 7, 42, 80]) {
      expect(EggSprites.forLevel(n), same(EggSprites.forLevel(n)),
          reason: 'level $n reshuffled its egg between reads');
    }
  });

  testWidgets('different levels do not all share one egg', (tester) async {
    await EggSprites.load();
    final seen = {for (int n = 1; n <= 80; n++) EggSprites.forLevel(n)};
    expect(seen.length, greaterThan(1));
  });

  testWidgets('board paints with and without artwork', (tester) async {
    final engine = GameEngine(kCuratedLevels.first);

    // Before load: must not throw, just renders the bare goal block.
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: GameBoard(engine: engine))),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await EggSprites.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameBoard(engine: engine, eggSprite: EggSprites.forLevel(1)),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
