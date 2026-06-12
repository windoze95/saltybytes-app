import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/core/providers/recipe_provider.dart';
import 'package:saltybytes_app/features/recipe/recipe_fork_screen.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_helpers.dart';

Widget _buildScreen() {
  final recipe = Recipe.fromJson(testRecipeJson(id: 'r-1', imageUrl: null));
  return testAppScaffold(
    const RecipeForkScreen(recipeId: 'r-1'),
    overrides: [
      recipeDetailProvider.overrideWith((ref, id) async => recipe),
    ],
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

ElevatedButton _forkButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Fork Recipe'),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('RecipeForkScreen submit button', () {
    testWidgets('is disabled while both fields are empty', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await _settle(tester);

      expect(_forkButton(tester).onPressed, isNull);
    });

    testWidgets('enables when the user types a branch name', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await _settle(tester);

      // First TextField is the branch name.
      await tester.enterText(find.byType(TextField).first, 'spicy-version');
      await tester.pump(const Duration(milliseconds: 50));

      expect(_forkButton(tester).onPressed, isNotNull);
    });

    testWidgets('enables when the user types modifications only',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await _settle(tester);

      // Second TextField is the modifications prompt.
      await tester.enterText(
          find.byType(TextField).last, 'Double the spices');
      await tester.pump(const Duration(milliseconds: 50));

      expect(_forkButton(tester).onPressed, isNotNull);
    });
  });
}
