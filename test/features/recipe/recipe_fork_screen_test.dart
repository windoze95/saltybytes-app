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
import 'package:saltybytes_app/features/recipe/recipe_fork_screen.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_helpers.dart';

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

  group('RecipeForkScreen submit', () {
    testWidgets(
        'fires POST /v1/recipes/:id/fork with the combined user_prompt, '
        'polls the placeholder, and lands on the new recipe', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final apiClient = MockApiClient();
      when(() => apiClient.post(
            ApiEndpoints.recipeFork('r-1'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'recipe': testRecipeJson(id: '99', status: 'generating'),
          }));
      when(() => apiClient.get(ApiEndpoints.recipeById('99')))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'recipe': testRecipeJson(id: '99', status: 'ready'),
              }));

      final recipe =
          Recipe.fromJson(testRecipeJson(id: 'r-1', imageUrl: null));
      final router = GoRouter(
        initialLocation: '/fork',
        routes: [
          GoRoute(
            path: '/fork',
            builder: (context, state) =>
                const RecipeForkScreen(recipeId: 'r-1'),
          ),
          GoRoute(
            path: '/recipe/:id',
            name: 'recipe-detail',
            builder: (context, state) => Scaffold(
              body: Text('detail-${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

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
      await _settle(tester);

      await tester.enterText(find.byType(TextField).first, 'spicy-version');
      await tester.enterText(
          find.byType(TextField).last, 'Double the spices');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Fork Recipe'));
      await tester.pump();

      // Submitting state while the placeholder generates.
      expect(find.text('Forking...'), findsOneWidget);

      // waitUntilGenerated polls after 2s; the recipe is then ready.
      await tester.pump(const Duration(seconds: 2));
      await _settle(tester);

      expect(find.text('detail-99'), findsOneWidget);

      final captured = verify(() => apiClient.post(
            ApiEndpoints.recipeFork('r-1'),
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single;
      expect(captured, {
        'user_prompt':
            'Variation name: spicy-version. Changes: Double the spices',
        'gen_image': true,
      });
    });

    testWidgets('modifications-only fork sends just the modifications text',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final apiClient = MockApiClient();
      when(() => apiClient.post(
            ApiEndpoints.recipeFork('r-1'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'recipe': testRecipeJson(id: '99', status: 'generating'),
          }));
      when(() => apiClient.get(ApiEndpoints.recipeById('99')))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'recipe': testRecipeJson(id: '99', status: 'ready'),
              }));

      final recipe =
          Recipe.fromJson(testRecipeJson(id: 'r-1', imageUrl: null));
      final router = GoRouter(
        initialLocation: '/fork',
        routes: [
          GoRoute(
            path: '/fork',
            builder: (context, state) =>
                const RecipeForkScreen(recipeId: 'r-1'),
          ),
          GoRoute(
            path: '/recipe/:id',
            name: 'recipe-detail',
            builder: (context, state) => Scaffold(
              body: Text('detail-${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

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
      await _settle(tester);

      await tester.enterText(
          find.byType(TextField).last, 'Use olive oil instead of butter');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Fork Recipe'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await _settle(tester);

      final captured = verify(() => apiClient.post(
            ApiEndpoints.recipeFork('r-1'),
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single;
      expect(
        captured,
        {
          'user_prompt': 'Use olive oil instead of butter',
          'gen_image': true,
        },
      );
    });
  });
}
