import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/allergen_provider.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/recipe_provider.dart';
import 'package:saltybytes_app/features/recipe/recipe_detail_screen.dart';
import 'package:saltybytes_app/models/allergen.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_helpers.dart';

Widget _buildScreen({
  Recipe? recipe,
  AllergenAnalysis? analysis,
  List<Recipe> similar = const [],
  AuthStatus authStatus = AuthStatus.unauthenticated,
  ApiClient? apiClient,
}) {
  final theRecipe =
      recipe ?? Recipe.fromJson(testRecipeJson(id: 'r-1', imageUrl: null));
  final theAnalysis = analysis ??
      AllergenAnalysis.fromJson(
        testAllergenAnalysisJson(unsafeForProfiles: []),
      );
  return testAppScaffold(
    const RecipeDetailScreen(recipeId: 'r-1'),
    overrides: [
      authStateProvider.overrideWith(() => FakeAuthNotifier(authStatus)),
      recipeDetailProvider.overrideWith((ref, id) async => theRecipe),
      similarRecipesProvider.overrideWith((ref, id) async => similar),
      allergenAnalysisProvider.overrideWith((ref, id) async => theAnalysis),
      if (apiClient != null) apiClientProvider.overrideWithValue(apiClient),
    ],
  );
}

/// Pumps several short frames so chained async providers settle without
/// pumpAndSettle (flutter_animate repeats forever).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Most of the body sits below the fold at the default 800x600 test
/// viewport; use a taller surface so the lazy slivers all build.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('RecipeDetailScreen allergen banner', () {
    testWidgets('shows the warning banner when members are flagged unsafe',
        (tester) async {
      final analysis = AllergenAnalysis.fromJson(
        testAllergenAnalysisJson(unsafeForProfiles: [1]),
      );

      await tester.pumpWidget(_buildScreen(analysis: analysis));
      await _settle(tester);

      expect(
        find.text('Contains allergens unsafe for family members'),
        findsOneWidget,
      );
    });

    testWidgets('hides the banner when no members are flagged unsafe',
        (tester) async {
      final analysis = AllergenAnalysis.fromJson(
        testAllergenAnalysisJson(unsafeForProfiles: []),
      );

      await tester.pumpWidget(_buildScreen(analysis: analysis));
      await _settle(tester);

      expect(
        find.text('Contains allergens unsafe for family members'),
        findsNothing,
      );
    });
  });

  group('RecipeDetailScreen similar recipes rail', () {
    testWidgets('renders a horizontal card per similar recipe', (tester) async {
      _useTallViewport(tester);
      final similar = [
        Recipe.fromJson(testRecipeJson(
          id: 'sim-1',
          title: 'Garlic Naan Pizza',
          imageUrl: null,
        )),
        Recipe.fromJson(testRecipeJson(
          id: 'sim-2',
          title: 'Detroit-Style Pepperoni',
          imageUrl: null,
        )),
      ];

      await tester.pumpWidget(_buildScreen(similar: similar));
      await _settle(tester);

      expect(find.text('Similar Recipes'), findsOneWidget);
      expect(find.text('Garlic Naan Pizza'), findsOneWidget);
      expect(find.text('Detroit-Style Pepperoni'), findsOneWidget);
    });

    testWidgets('shows the empty message when none are found', (tester) async {
      _useTallViewport(tester);
      await tester.pumpWidget(_buildScreen());
      await _settle(tester);

      expect(find.text('No similar recipes found yet.'), findsOneWidget);
    });
  });

  group('RecipeDetailScreen share', () {
    testWidgets('renders a share button in the app bar', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await _settle(tester);

      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      expect(find.byTooltip('Share'), findsOneWidget);
    });

    test(
        'buildRecipeShareText includes title, ingredients, instructions, '
        'and source', () {
      final recipe = Recipe.fromJson(testRecipeJson(
        sourceUrl: 'https://example.com/pizza',
      ));

      final text = buildRecipeShareText(recipe);

      expect(text, startsWith('Classic Margherita Pizza\n'));
      expect(text, contains('Cook time: 15 min'));
      expect(text, contains('- 1 ball pizza dough'));
      expect(text, contains('1. Preheat oven to 475F'));
      expect(text, contains('Source: https://example.com/pizza'));
      expect(text, endsWith('Shared from SaltyBytes'));
    });

    test(
        'buildRecipeShareText matches the in-app ingredient formatting: '
        'no "0" for unquantified amounts, cooking fractions for partials', () {
      final recipe = Recipe.fromJson(testRecipeJson(
        ingredients: [
          // Go serializes Amount without omitempty: "to taste" arrives as 0.
          testIngredientJson(name: 'salt', amount: 0, unit: ''),
          testIngredientJson(name: 'flour', amount: 0.5, unit: 'cup'),
        ],
      ));

      final text = buildRecipeShareText(recipe);

      expect(text, contains('- salt'));
      expect(text, isNot(contains('- 0 salt')));
      expect(text, contains('- 1/2 cup flour'));
      expect(text, isNot(contains('0.5')));
    });
  });

  group('RecipeDetailScreen unit conversion', () {
    testWidgets(
        'metric user viewing a us_customary recipe sees metric alternates',
        (tester) async {
      _useTallViewport(tester);

      final apiClient = MockApiClient();
      when(() => apiClient.get(ApiEndpoints.userProfile))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'user': testUserJson(
                  personalization:
                      testPersonalizationJson(unitSystem: 'metric'),
                ),
              }));

      final recipe = Recipe.fromJson(testRecipeJson(
        id: 'r-1',
        imageUrl: null,
        unitSystem: 'us_customary',
        ingredients: [
          testIngredientJson(name: 'flour', amount: 2.0, unit: 'cups'),
          testIngredientJson(name: 'ground beef', amount: 1.0, unit: 'lb'),
        ],
      ));

      await tester.pumpWidget(_buildScreen(
        recipe: recipe,
        authStatus: AuthStatus.authenticated,
        apiClient: apiClient,
      ));
      await _settle(tester);

      // 2 cups -> 480 mL, 1 lb -> 450 g (cooking-friendly rounding).
      expect(find.text('2 cups (480 mL)'), findsOneWidget);
      expect(find.text('1 lb (450 g)'), findsOneWidget);
    });

    testWidgets('us_customary user sees the recipe amounts unchanged',
        (tester) async {
      _useTallViewport(tester);

      final recipe = Recipe.fromJson(testRecipeJson(
        id: 'r-1',
        imageUrl: null,
        unitSystem: 'us_customary',
        ingredients: [
          testIngredientJson(name: 'flour', amount: 2.0, unit: 'cups'),
        ],
      ));

      await tester.pumpWidget(_buildScreen(recipe: recipe));
      await _settle(tester);

      expect(find.text('2 cups'), findsOneWidget);
      expect(find.text('480 mL'), findsNothing);
    });
  });
}
