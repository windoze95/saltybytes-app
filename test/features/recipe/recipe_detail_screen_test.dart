import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/core/providers/allergen_provider.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/recipe_provider.dart';
import 'package:saltybytes_app/features/recipe/recipe_detail_screen.dart';
import 'package:saltybytes_app/models/allergen.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_helpers.dart';

/// Fake auth notifier that reports unauthenticated (keeps user/profile
/// providers inert in widget tests).
class _FakeAuthNotifier extends AsyncNotifier<AuthStatus>
    implements AuthNotifier {
  @override
  Future<AuthStatus> build() async => AuthStatus.unauthenticated;

  @override
  Future<void> login(
      {required String username, required String password}) async {}

  @override
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> logout() async {}
}

Widget _buildScreen({required AllergenAnalysis analysis}) {
  final recipe = Recipe.fromJson(testRecipeJson(id: 'r-1', imageUrl: null));
  return testAppScaffold(
    const RecipeDetailScreen(recipeId: 'r-1'),
    overrides: [
      authStateProvider.overrideWith(_FakeAuthNotifier.new),
      recipeDetailProvider.overrideWith((ref, id) async => recipe),
      similarRecipesProvider.overrideWith((ref, id) async => <Recipe>[]),
      allergenAnalysisProvider.overrideWith((ref, id) async => analysis),
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
}
