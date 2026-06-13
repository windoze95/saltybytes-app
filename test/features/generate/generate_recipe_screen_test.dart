import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/theme/app_theme.dart';
import 'package:saltybytes_app/features/generate/generate_recipe_screen.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_helpers.dart';

/// Fake auth notifier that stays unauthenticated so recipeListProvider
/// stays inert (no API call) when invalidated.
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

GoRouter _buildRouter({String initialLocation = '/generate'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) =>
            const Scaffold(body: Text('home-stub')),
      ),
      GoRoute(
        path: '/generate',
        name: 'generate',
        builder: (context, state) => const GenerateRecipeScreen(),
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
}

Widget _buildApp(MockApiClient apiClient, {GoRouter? router}) {
  router ??= _buildRouter();

  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(apiClient),
      authStateProvider.overrideWith(_FakeAuthNotifier.new),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('GenerateRecipeScreen', () {
    testWidgets('submit button enables as the user types', (tester) async {
      final apiClient = MockApiClient();
      await tester.pumpWidget(_buildApp(apiClient));
      await tester.pump(const Duration(milliseconds: 100));

      ElevatedButton button() => tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Generate Recipe'),
          );

      expect(button().onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'A cozy pot pie');
      await tester.pump(const Duration(milliseconds: 50));

      expect(button().onPressed, isNotNull);
    });

    testWidgets(
        'happy path: POSTs the prompt, polls the generating placeholder, '
        'then navigates to the finished recipe', (tester) async {
      final apiClient = MockApiClient();

      when(() => apiClient.post(
            ApiEndpoints.generateRecipe,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'recipe': testRecipeJson(id: '42', status: 'generating'),
            'message': 'Generating recipe',
          }));

      var polls = 0;
      when(() => apiClient.get(ApiEndpoints.recipeById('42')))
          .thenAnswer((_) async {
        polls++;
        return fakeResponse<dynamic>({
          'recipe': testRecipeJson(
            id: '42',
            status: polls < 2 ? 'generating' : 'ready',
          ),
        });
      });

      // Mimic the real app: the generate screen is pushed from home, so
      // there is a stack underneath it.
      final router = _buildRouter(initialLocation: '/home');
      await tester.pumpWidget(_buildApp(apiClient, router: router));
      router.pushNamed('generate');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.enterText(
          find.byType(TextField), 'A cozy chicken pot pie');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Generate Recipe'));
      await tester.pump();

      // Progress UI while the placeholder generates.
      expect(find.text('Generating your recipe...'), findsOneWidget);

      // First poll: still generating.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Generating your recipe...'), findsOneWidget);

      // Second poll: ready -> navigate.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('detail-42'), findsOneWidget);
      expect(polls, 2);

      // pushReplacement (not go) keeps the underlying stack, so the detail
      // screen still has a back route to home instead of stranding the user.
      expect(router.canPop(), isTrue);
      router.pop();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('home-stub'), findsOneWidget);

      // Request shape: user_prompt + gen_image (toggle defaults to true).
      final captured = verify(() => apiClient.post(
            ApiEndpoints.generateRecipe,
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single;
      expect(captured, {
        'user_prompt': 'A cozy chicken pot pie',
        'gen_image': true,
      });
    });

    testWidgets('shows an error and returns to the form when polling 404s',
        (tester) async {
      final apiClient = MockApiClient();

      when(() => apiClient.post(
            ApiEndpoints.generateRecipe,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'recipe': testRecipeJson(id: '42', status: 'generating'),
          }));

      when(() => apiClient.get(ApiEndpoints.recipeById('42'))).thenAnswer(
        (invocation) async => throw DioException(
          requestOptions: RequestOptions(path: '/v1/recipes/42'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/recipes/42'),
            statusCode: 404,
          ),
        ),
      );

      await tester.pumpWidget(_buildApp(apiClient));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField), 'Something impossible');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Generate Recipe'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Recipe generation failed. Please try again.'),
        findsOneWidget,
      );
      // Back on the form.
      expect(find.widgetWithText(ElevatedButton, 'Generate Recipe'),
          findsOneWidget);
    });
  });
}
