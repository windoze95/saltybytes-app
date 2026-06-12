import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/features/home/widgets/recipe_card.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Recipe buildRecipe({
    String title = 'Classic Margherita Pizza',
    int? cookTimeMinutes = 15,
    int? portions = 4,
    String? imageUrl = 'https://cdn.saltybytes.ai/images/pizza.jpg',
    String? createdAt,
  }) {
    return Recipe.fromJson(testRecipeJson(
      title: title,
      cookTimeMinutes: cookTimeMinutes,
      portions: portions,
      imageUrl: imageUrl,
      createdAt: createdAt,
    ));
  }

  // flutter_animate creates repeating timers, so pumpAndSettle will never
  // complete. Use pump() with a short duration instead.
  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(testApp(
      SizedBox(width: 200, height: 300, child: card),
    ));
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('RecipeCard', () {
    testWidgets('displays recipe title text', (tester) async {
      await pumpCard(
        tester,
        RecipeCard(recipe: buildRecipe(title: 'Spaghetti Carbonara')),
      );

      expect(find.text('Spaghetti Carbonara'), findsOneWidget);
    });

    testWidgets('displays cook time with timer icon when set', (tester) async {
      await pumpCard(
        tester,
        RecipeCard(recipe: buildRecipe(cookTimeMinutes: 25)),
      );

      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.text('25m'), findsOneWidget);
    });

    testWidgets('displays portions count with restaurant icon', (tester) async {
      await pumpCard(
        tester,
        RecipeCard(recipe: buildRecipe(portions: 6)),
      );

      expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('shows NEW badge when isNew is true', (tester) async {
      await pumpCard(
        tester,
        RecipeCard(recipe: buildRecipe(), isNew: true),
      );

      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('does NOT show NEW badge when isNew is false', (tester) async {
      await pumpCard(
        tester,
        RecipeCard(recipe: buildRecipe(), isNew: false),
      );

      expect(find.text('NEW'), findsNothing);
    });

    testWidgets('shows placeholder icon when imageUrl is null', (tester) async {
      await pumpCard(
        tester,
        RecipeCard(recipe: buildRecipe(imageUrl: null)),
      );

      // The _ImagePlaceholder shows Icons.restaurant
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('shows placeholder when API sends empty-string imageUrl',
        (tester) async {
      // Recipe.fromJson normalizes "" to null
      final fromApi = buildRecipe(imageUrl: '');
      expect(fromApi.imageUrl, isNull);

      await pumpCard(tester, RecipeCard(recipe: fromApi));
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    });

    testWidgets('render guard also handles an empty imageUrl directly',
        (tester) async {
      // Bypass fromJson normalization: even a directly-constructed Recipe
      // with an empty imageUrl must not be fed into CachedNetworkImage.
      const recipe = Recipe(
        id: 'r-1',
        title: 'No Image',
        ownerId: 'u-1',
        imageUrl: '',
      );

      await pumpCard(tester, const RecipeCard(recipe: recipe));
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    });

    testWidgets('calls onTap callback when card is tapped', (tester) async {
      var tapped = false;
      await pumpCard(
        tester,
        RecipeCard(
          recipe: buildRecipe(),
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });
  });
}
