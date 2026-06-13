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

    testWidgets('does not show the dead filter button stub', (tester) async {
      await tester.pumpWidget(_buildHomeScreen(
        recipeOverride: recipeListProvider.overrideWith(
          () => _FakeRecipeListNotifier(const AsyncValue.data([])),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.filter_list), findsNothing);
    });
  });

  group('HomeScreen search debounce', () {
    late _FakeRecipeListNotifier fakeNotifier;

    Future<void> openSearch(WidgetTester tester) async {
      fakeNotifier = _FakeRecipeListNotifier(const AsyncValue.data([]));
      await tester.pumpWidget(_buildHomeScreen(
        recipeOverride: recipeListProvider.overrideWith(() => fakeNotifier),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('debounces keystrokes by 350ms', (tester) async {
      await openSearch(tester);

      await tester.enterText(find.byType(TextField), 'pizza');
      // Before the debounce window elapses: no API hit.
      await tester.pump(const Duration(milliseconds: 200));
      expect(fakeNotifier.searchCalls, isEmpty);

      // After the window: exactly one search.
      await tester.pump(const Duration(milliseconds: 200));
      expect(fakeNotifier.searchCalls, ['pizza']);
    });

    testWidgets('rapid typing fires only the final query', (tester) async {
      await openSearch(tester);

      await tester.enterText(find.byType(TextField), 'pi');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'piz');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'pizza');
      await tester.pump(const Duration(milliseconds: 400));

      expect(fakeNotifier.searchCalls, ['pizza']);
    });

    testWidgets('does not search for queries shorter than 2 chars',
        (tester) async {
      await openSearch(tester);

      await tester.enterText(find.byType(TextField), 'p');
      await tester.pump(const Duration(milliseconds: 500));

      expect(fakeNotifier.searchCalls, isEmpty);
    });

    testWidgets('clearing the query refreshes the full list immediately',
        (tester) async {
      await openSearch(tester);

      await tester.enterText(find.byType(TextField), 'pizza');
      await tester.pump(const Duration(milliseconds: 400));
      expect(fakeNotifier.searchCalls, ['pizza']);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(fakeNotifier.refreshCalls, greaterThanOrEqualTo(1));
      // No extra search fired for the empty query.
      await tester.pump(const Duration(milliseconds: 400));
      expect(fakeNotifier.searchCalls, ['pizza']);
    });
  });
}

/// A fake [RecipeListNotifier] that immediately returns the provided state
/// and records search/refresh calls for assertions.
class _FakeRecipeListNotifier extends AsyncNotifier<List<Recipe>>
    implements RecipeListNotifier {
  _FakeRecipeListNotifier(this._initial);

  final AsyncValue<List<Recipe>> _initial;
  final List<String> searchCalls = [];
  int refreshCalls = 0;

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
  Future<void> refresh() async {
    refreshCalls++;
  }

  @override
  Future<void> search(String query) async {
    searchCalls.add(query);
  }

  @override
  Future<void> deleteRecipe(String id) async {}
}
