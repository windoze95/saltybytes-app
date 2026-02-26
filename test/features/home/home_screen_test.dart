import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/core/providers/recipe_provider.dart';
import 'package:saltybytes_app/features/home/home_screen.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../../helpers/fixtures.dart';

/// Wraps HomeScreen with MaterialApp + ProviderScope + required overrides.
Widget _buildHomeScreen({
  required Override recipeOverride,
}) {
  return ProviderScope(
    overrides: [recipeOverride],
    child: const MaterialApp(
      home: HomeScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('HomeScreen', () {
    testWidgets('shows loading grid when recipeListProvider is loading',
        (tester) async {
      await tester.pumpWidget(_buildHomeScreen(
        recipeOverride: recipeListProvider.overrideWith(
          () => _FakeRecipeListNotifier(const AsyncValue.loading()),
        ),
      ));
      // Use pump() instead of pumpAndSettle since shimmer animation repeats forever
      await tester.pump(const Duration(milliseconds: 100));

      // The _LoadingGrid renders shimmer Card placeholders.
      // GridView is lazy so not all 6 may be built; verify at least some are present.
      expect(find.byType(Card), findsWidgets);
      // The grid itself should be rendered
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('displays recipe grid when data is available', (tester) async {
      final recipes = [
        Recipe.fromJson(testRecipeJson(id: 'r-1', title: 'Pizza')),
        Recipe.fromJson(testRecipeJson(id: 'r-2', title: 'Pasta')),
        Recipe.fromJson(testRecipeJson(id: 'r-3', title: 'Salad')),
      ];

      await tester.pumpWidget(_buildHomeScreen(
        recipeOverride: recipeListProvider.overrideWith(
          () => _FakeRecipeListNotifier(AsyncValue.data(recipes)),
        ),
      ));
      // flutter_animate uses repeating animations so use pump()
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('Pasta'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows empty state when recipe list is empty', (tester) async {
      await tester.pumpWidget(_buildHomeScreen(
        recipeOverride: recipeListProvider.overrideWith(
          () => _FakeRecipeListNotifier(const AsyncValue.data([])),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No recipes yet'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    });

    testWidgets('FAB has add icon', (tester) async {
      await tester.pumpWidget(_buildHomeScreen(
        recipeOverride: recipeListProvider.overrideWith(
          () => _FakeRecipeListNotifier(const AsyncValue.data([])),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      // Verify the FAB contains an add icon
      expect(
        find.descendant(of: fab, matching: find.byIcon(Icons.add)),
        findsOneWidget,
      );
    });

    testWidgets('shows search icon in app bar', (tester) async {
      await tester.pumpWidget(_buildHomeScreen(
        recipeOverride: recipeListProvider.overrideWith(
          () => _FakeRecipeListNotifier(const AsyncValue.data([])),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}

/// A fake [RecipeListNotifier] that immediately returns the provided state.
class _FakeRecipeListNotifier extends AsyncNotifier<List<Recipe>>
    implements RecipeListNotifier {
  _FakeRecipeListNotifier(this._initial);

  final AsyncValue<List<Recipe>> _initial;

  @override
  Future<List<Recipe>> build() async {
    if (_initial is AsyncLoading) {
      // Return a future that never completes so state stays as loading
      state = const AsyncValue.loading();
      return Completer<List<Recipe>>().future;
    }
    state = _initial;
    return _initial.value ?? [];
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> search(String query) async {}

  @override
  Future<void> deleteRecipe(String id) async {}
}
