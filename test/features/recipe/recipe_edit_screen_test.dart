import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/core/providers/recipe_provider.dart';
import 'package:saltybytes_app/features/recipe/recipe_edit_screen.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_helpers.dart';

Widget _buildScreen() {
  final recipe = Recipe.fromJson(testRecipeJson(id: 'r-1', imageUrl: null));
  return testAppScaffold(
    const RecipeEditScreen(recipeId: 'r-1'),
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

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('RecipeEditScreen submit button', () {
    testWidgets('is disabled while the prompt is empty', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await _settle(tester);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Regenerate'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('enables as the user types (controller listener rebuild)',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await _settle(tester);

      await tester.enterText(find.byType(TextField), 'Make it spicier');
      await tester.pump(const Duration(milliseconds: 50));

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Regenerate'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('disables again when the prompt is cleared', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await _settle(tester);

      await tester.enterText(find.byType(TextField), 'Make it spicier');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 50));

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Regenerate'),
      );
      expect(button.onPressed, isNull);
    });
  });
}
