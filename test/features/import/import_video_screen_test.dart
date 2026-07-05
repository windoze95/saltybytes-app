import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/features/import/import_video_screen.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_helpers.dart';

class _FakeAuthNotifier extends AsyncNotifier<AuthStatus>
    implements AuthNotifier {

  @override
  bool needsEmailVerification = false;

  @override
  void markEmailVerificationHandled() {
    needsEmailVerification = false;
  }
  @override
  Future<AuthStatus> build() async => AuthStatus.authenticated;

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

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late MockApiClient apiClient;
  late ProviderContainer container;

  setUp(() {
    apiClient = MockApiClient();
    container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(apiClient),
      authStateProvider.overrideWith(_FakeAuthNotifier.new),
    ]);

    // Home grid list fetch (refreshed after a successful import).
    when(() => apiClient.get(
          ApiEndpoints.recipes,
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer(
        (_) async => fakeResponse<dynamic>({'recipes': <dynamic>[]}));

    // POST start -> a queued job.
    when(() => apiClient.post(
          ApiEndpoints.importFromVideo,
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => fakeResponse<dynamic>({
          'job': {
            'id': 1,
            'status': 'queued',
            'platform': 'tiktok',
            'cache_hit': false,
          }
        }, statusCode: 202));

    // Poll -> done with a recipe id.
    when(() => apiClient.get(ApiEndpoints.importVideoStatus(1))).thenAnswer(
        (_) async => fakeResponse<dynamic>({
              'job': {
                'id': 1,
                'status': 'done',
                'recipe_id': 1,
                'cache_hit': false,
              }
            }));

    // Fetch the resulting recipe.
    when(() => apiClient.get(ApiEndpoints.recipeById('1'))).thenAnswer(
        (_) async => fakeResponse<dynamic>(
            {'recipe': testRecipeJson(id: '1', title: 'Imported Pancakes')}));
  });

  tearDown(() => container.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ImportVideoScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ImportVideoScreen', () {
    testWidgets('shows the paste field and supported-platforms hint',
        (tester) async {
      await pumpScreen(tester);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Import'), findsOneWidget);
      expect(find.textContaining('TikTok'), findsWidgets);
    });

    testWidgets('polls the queued job to completion and shows View Recipe',
        (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
          find.byType(TextField).first, 'https://www.tiktok.com/@x/video/1');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Import'));
      await tester.pump(); // POST resolves, schedule the first poll
      await tester.pump(const Duration(seconds: 4)); // fire poll -> done -> recipe
      await tester.pump(const Duration(milliseconds: 100)); // rebuild

      expect(find.text('View Recipe'), findsOneWidget);
      expect(find.text('Imported Pancakes'), findsOneWidget);
      verify(() => apiClient.post(
            ApiEndpoints.importFromVideo,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).called(1);
    });

    testWidgets('over-quota (403) surfaces the upgrade message',
        (tester) async {
      when(() => apiClient.post(
            ApiEndpoints.importFromVideo,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => throw DioException(
            requestOptions:
                RequestOptions(path: ApiEndpoints.importFromVideo),
            response: Response(
              requestOptions:
                  RequestOptions(path: ApiEndpoints.importFromVideo),
              statusCode: 403,
              data: const {
                'error': 'Video import limit reached; upgrade to premium',
                'code': 'video_limit_reached',
              },
            ),
          ));

      await pumpScreen(tester);
      await tester.enterText(
          find.byType(TextField).first, 'https://www.tiktok.com/@x/video/1');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Import'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('limit reached'), findsOneWidget);
      expect(find.text('View Recipe'), findsNothing);
    });

    testWidgets('a failed job shows the failure reason', (tester) async {
      when(() => apiClient.get(ApiEndpoints.importVideoStatus(1))).thenAnswer(
          (_) async => fakeResponse<dynamic>({
                'job': {
                  'id': 1,
                  'status': 'failed',
                  'error': 'could not find a recipe in this video',
                }
              }));

      await pumpScreen(tester);
      await tester.enterText(
          find.byType(TextField).first, 'https://www.tiktok.com/@x/video/1');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Import'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('could not find a recipe'), findsOneWidget);
      expect(find.text('View Recipe'), findsNothing);
    });
  });
}
