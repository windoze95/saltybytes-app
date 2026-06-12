import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/allergen_provider.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/recipe_provider.dart';
import 'package:saltybytes_app/features/recipe/allergen_detail_screen.dart';
import 'package:saltybytes_app/features/recipe/widgets/allergen_badge.dart';
import 'package:saltybytes_app/models/allergen.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_helpers.dart';

Widget _buildScreen(
  MockApiClient apiClient, {
  required AllergenAnalysis analysis,
}) {
  final recipe = Recipe.fromJson(testRecipeJson(id: 'r-1', imageUrl: null));
  return testAppScaffold(
    const AllergenDetailScreen(recipeId: 'r-1'),
    overrides: [
      apiClientProvider.overrideWithValue(apiClient),
      authStateProvider.overrideWith(FakeAuthNotifier.new),
      recipeDetailProvider.overrideWith((ref, id) async => recipe),
      allergenAnalysisProvider.overrideWith((ref, id) async => analysis),
    ],
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The analysis body is a lazy ListView; use a taller surface so every
/// section (chips, ingredient cards, family safety) builds.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late MockApiClient apiClient;

  setUp(() {
    apiClient = MockApiClient();
    // Junior (id 1) and Sarah (id 2) for the family safety section.
    when(() => apiClient.get(ApiEndpoints.family)).thenAnswer(
      (_) async => fakeResponse<dynamic>({'family': testFamilyJson()}),
    );
  });

  group('AllergenDetailScreen analysis rendering', () {
    testWidgets(
        'renders contains_* chips, ingredient analyses, and family safety',
        (tester) async {
      _useTallViewport(tester);
      final analysis = AllergenAnalysis.fromJson(testAllergenAnalysisJson(
        containsDairy: true,
        containsGluten: true,
        safeForProfiles: [2],
        unsafeForProfiles: [1],
      ));

      await tester.pumpWidget(_buildScreen(apiClient, analysis: analysis));
      await _settle(tester);

      // Summary banner + detected allergen chips from the contains_* flags.
      expect(find.text('Contains potential allergens'), findsOneWidget);
      expect(find.text('Detected Allergens'), findsOneWidget);
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text('Gluten'), findsOneWidget);
      expect(find.text('Nuts'), findsNothing);

      // Per-ingredient breakdown with allergen badges.
      expect(find.text('Ingredient Breakdown'), findsOneWidget);
      expect(find.text('all-purpose flour'), findsOneWidget);
      expect(find.text('mozzarella'), findsOneWidget);
      expect(find.text('gluten'), findsOneWidget);
      expect(find.text('wheat'), findsOneWidget);
      // 'dairy' badge for mozzarella, plus 'lactose' as possible allergen.
      expect(find.text('dairy'), findsOneWidget);
      expect(find.text('lactose'), findsOneWidget);

      // Family safety section resolves member names from the family.
      expect(find.text('Family Member Safety'), findsOneWidget);
      expect(find.text('Junior'), findsOneWidget);
      expect(
        find.text('Contains allergens unsafe for this member'),
        findsOneWidget,
      );
      expect(find.text('Sarah'), findsOneWidget);
      expect(find.text('Safe to eat'), findsOneWidget);

      // Disclaimer and re-analyze affordance.
      expect(
        find.text('AI-generated analysis. Does not replace medical advice.'),
        findsOneWidget,
      );
      expect(find.text('Re-analyze'), findsOneWidget);
    });

    testWidgets('clean analysis shows the all-clear summary and no sections',
        (tester) async {
      _useTallViewport(tester);
      final analysis = AllergenAnalysis.fromJson(testAllergenAnalysisJson(
        containsDairy: false,
        containsGluten: false,
        ingredientAnalyses: [
          testIngredientAnalysisJson(
            ingredientName: 'basil',
            commonAllergens: [],
            possibleAllergens: [],
          ),
        ],
        safeForProfiles: [],
        unsafeForProfiles: [],
      ));

      await tester.pumpWidget(_buildScreen(apiClient, analysis: analysis));
      await _settle(tester);

      expect(find.text('No major allergens detected'), findsOneWidget);
      expect(find.text('Detected Allergens'), findsNothing);
      expect(find.text('Family Member Safety'), findsNothing);
      expect(find.text('No allergens identified'), findsOneWidget);
      expect(find.byType(AllergenBadge), findsNothing);
    });

    testWidgets('shows the not-analyzed state when the fetch 404s '
        '(no analysis exists)', (tester) async {
      final recipe =
          Recipe.fromJson(testRecipeJson(id: 'r-1', imageUrl: null));
      await tester.pumpWidget(testAppScaffold(
        const AllergenDetailScreen(recipeId: 'r-1'),
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider.overrideWith(FakeAuthNotifier.new),
          recipeDetailProvider.overrideWith((ref, id) async => recipe),
          allergenAnalysisProvider.overrideWith(
            (ref, id) async => throw _notFoundException(),
          ),
        ],
      ));
      await _settle(tester);

      expect(find.text('Not Yet Analyzed'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Analyze'), findsOneWidget);
    });

    testWidgets(
        'shows a load-error state (not "Not Yet Analyzed") for non-404 '
        'failures so transient errors cannot burn analysis quota',
        (tester) async {
      final recipe =
          Recipe.fromJson(testRecipeJson(id: 'r-1', imageUrl: null));
      await tester.pumpWidget(testAppScaffold(
        const AllergenDetailScreen(recipeId: 'r-1'),
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider.overrideWith(FakeAuthNotifier.new),
          recipeDetailProvider.overrideWith((ref, id) async => recipe),
          allergenAnalysisProvider.overrideWith(
            (ref, id) async => throw DioException(
              requestOptions: RequestOptions(path: '/v1/recipes/r-1/allergens'),
              type: DioExceptionType.connectionError,
            ),
          ),
        ],
      ));
      await _settle(tester);

      expect(find.text('Could not load analysis'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
      expect(find.text('Not Yet Analyzed'), findsNothing);
    });
  });
}

/// A DioException shaped like the backend's 404 "no analysis exists yet".
DioException _notFoundException() {
  final requestOptions = RequestOptions(path: '/v1/recipes/r-1/allergens');
  return DioException(
    requestOptions: requestOptions,
    response: Response(requestOptions: requestOptions, statusCode: 404),
    type: DioExceptionType.badResponse,
  );
}
