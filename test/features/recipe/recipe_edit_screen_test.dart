import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/recipe_provider.dart';
import 'package:saltybytes_app/core/theme/app_theme.dart';
import 'package:saltybytes_app/features/recipe/recipe_edit_screen.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_helpers.dart';

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

/// The submit button sits below the fold at the default 800x600 viewport;
/// use a taller surface so taps land on it.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
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

  group('RecipeEditScreen submit', () {
    testWidgets(
        'fires PUT /v1/recipes/:id/chat with user_prompt + gen_image and '
        'pops back', (tester) async {
      final apiClient = MockApiClient();
      when(() => apiClient.put(
            ApiEndpoints.recipeChat('r-1'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async =>
          fakeResponse<dynamic>({'message': 'Regenerating recipe'}));
      // The background poll watches updatedAt move past the cached value.
      when(() => apiClient.get(ApiEndpoints.recipeById('r-1')))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'recipe': testRecipeJson(
                  id: 'r-1',
                  updatedAt: '2025-03-01T10:00:00.000Z',
                ),
              }));

      final recipe =
          Recipe.fromJson(testRecipeJson(id: 'r-1', imageUrl: null));
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Text('home-screen')),
          ),
          GoRoute(
            path: '/edit',
            builder: (context, state) =>
                const RecipeEditScreen(recipeId: 'r-1'),
          ),
        ],
      );

      _useTallViewport(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider
              .overrideWith(() => FakeAuthNotifier(AuthStatus.unauthenticated)),
          recipeDetailProvider.overrideWith((ref, id) async => recipe),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ));
      router.push('/edit');
      await _settle(tester);

      await tester.enterText(find.byType(TextField), 'Make it spicier');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Regenerate'));
      await _settle(tester);

      final captured = verify(() => apiClient.put(
            ApiEndpoints.recipeChat('r-1'),
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single;
      expect(captured, {
        'user_prompt': 'Make it spicier',
        'gen_image': false,
      });

      // The screen pops back after kicking off the regeneration.
      expect(find.text('home-screen'), findsOneWidget);
      expect(
        find.text('Regenerating recipe — this may take a minute.'),
        findsOneWidget,
      );

      // The background poll detects the regenerated recipe (updatedAt moved)
      // on its first 2s tick and stops — no leaked timers.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 100));
      verify(() => apiClient.get(ApiEndpoints.recipeById('r-1'))).called(1);
    });

    testWidgets('gen_image follows the "Generate new image" toggle',
        (tester) async {
      final apiClient = MockApiClient();
      when(() => apiClient.put(
            ApiEndpoints.recipeChat('r-1'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async =>
          fakeResponse<dynamic>({'message': 'Regenerating recipe'}));
      // The background poll watches updatedAt move past the cached value.
      when(() => apiClient.get(ApiEndpoints.recipeById('r-1')))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'recipe': testRecipeJson(
                  id: 'r-1',
                  updatedAt: '2025-03-01T10:00:00.000Z',
                ),
              }));

      final recipe =
          Recipe.fromJson(testRecipeJson(id: 'r-1', imageUrl: null));
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Text('home-screen')),
          ),
          GoRoute(
            path: '/edit',
            builder: (context, state) =>
                const RecipeEditScreen(recipeId: 'r-1'),
          ),
        ],
      );

      _useTallViewport(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider
              .overrideWith(() => FakeAuthNotifier(AuthStatus.unauthenticated)),
          recipeDetailProvider.overrideWith((ref, id) async => recipe),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ));
      router.push('/edit');
      await _settle(tester);

      await tester.enterText(find.byType(TextField), 'Make it vegan');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Regenerate'));
      await _settle(tester);

      final captured = verify(() => apiClient.put(
            ApiEndpoints.recipeChat('r-1'),
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single;
      expect(captured, {
        'user_prompt': 'Make it vegan',
        'gen_image': true,
      });

      // Drain the background regen-completion poll.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
        'refreshes the cached recipe once the async regen lands '
        '(backend never flips status to "generating")', (tester) async {
      final apiClient = MockApiClient();
      when(() => apiClient.put(
            ApiEndpoints.recipeChat('r-1'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async =>
          fakeResponse<dynamic>({'message': 'Regenerating recipe'}));

      // First poll still returns the old updatedAt (regen in flight); the
      // second returns the regenerated recipe.
      var polls = 0;
      when(() => apiClient.get(ApiEndpoints.recipeById('r-1')))
          .thenAnswer((_) async {
        polls++;
        return fakeResponse<dynamic>({
          'recipe': testRecipeJson(
            id: 'r-1',
            updatedAt: polls < 2
                ? '2025-02-21T14:45:00.000Z'
                : '2025-03-01T10:00:00.000Z',
          ),
        });
      });

      var detailFetches = 0;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            // Watch the detail provider from "home" the way the real detail
            // screen (one pop below the edit screen) does.
            builder: (context, state) => Scaffold(
              body: Consumer(
                builder: (context, ref, _) =>
                    ref.watch(recipeDetailProvider('r-1')).when(
                          loading: () => const Text('loading'),
                          error: (e, _) => Text('error: $e'),
                          data: (r) => Text(r.title),
                        ),
              ),
            ),
          ),
          GoRoute(
            path: '/edit',
            builder: (context, state) =>
                const RecipeEditScreen(recipeId: 'r-1'),
          ),
        ],
      );

      _useTallViewport(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider
              .overrideWith(() => FakeAuthNotifier(AuthStatus.unauthenticated)),
          recipeDetailProvider.overrideWith((ref, id) async {
            detailFetches++;
            return Recipe.fromJson(testRecipeJson(
              id: 'r-1',
              title: detailFetches == 1
                  ? 'Classic Margherita Pizza'
                  : 'Vegan Margherita Pizza',
            ));
          }),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ));
      router.push('/edit');
      await _settle(tester);

      await tester.enterText(find.byType(TextField), 'Make it vegan');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Regenerate'));
      await _settle(tester);

      // Let the pop transition finish entirely.
      await tester.pump(const Duration(milliseconds: 400));

      // Popped back; the detail provider was fetched once and NOT
      // invalidated yet (refetching now would re-cache the old recipe).
      expect(find.byType(RecipeEditScreen), findsNothing);
      expect(detailFetches, 1);

      // First poll: updatedAt unchanged, keep waiting.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 100));
      expect(detailFetches, 1);

      // Second poll: regen landed -> providers invalidated -> the watching
      // "detail" screen refetches and shows the regenerated recipe.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(detailFetches, 2);
      expect(find.text('Vegan Margherita Pizza'), findsOneWidget);
    });
  });
}
