import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/recipe_provider.dart';
import 'package:saltybytes_app/features/import/import_url_screen.dart';

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

    // Home grid list fetch
    when(() => apiClient.get(
          ApiEndpoints.recipes,
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer(
        (_) async => fakeResponse<dynamic>({'recipes': <dynamic>[]}));

    // URL import returns the wrapped recipe envelope
    when(() => apiClient.post(
          ApiEndpoints.importFromUrl,
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => fakeResponse<dynamic>(
        {'recipe': testRecipeJson(id: 'r-new', title: 'Imported Pizza')}));
  });

  tearDown(() {
    container.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ImportUrlScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ImportUrlScreen', () {
    testWidgets('imports exactly once regardless of repeated taps',
        (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
          find.byType(TextField).first, 'https://example.com/recipe');
      await tester.pump();

      final importButton = find.widgetWithText(ElevatedButton, 'Import');
      await tester.tap(importButton);
      await tester.pump(const Duration(milliseconds: 100));

      // Button now reads 'Imported' and is disabled; tap it anyway.
      final importedButton = find.widgetWithText(ElevatedButton, 'Imported');
      expect(importedButton, findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(importedButton).onPressed,
        isNull,
      );
      await tester.tap(importedButton, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => apiClient.post(
            ApiEndpoints.importFromUrl,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).called(1);
    });

    testWidgets('shows View Recipe instead of Save Recipe after import',
        (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
          find.byType(TextField).first, 'https://example.com/recipe');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Import'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('View Recipe'), findsOneWidget);
      expect(find.text('Save Recipe'), findsNothing);
      expect(find.text('Imported Pizza'), findsOneWidget);
    });

    testWidgets('invalidates recipeListProvider after a successful import',
        (tester) async {
      // Resolve auth first so the list provider isn't marked dirty mid-read
      // (which would park the unlistened .future forever).
      await container.read(authStateProvider.future);
      // Prime the list so a later read only refetches if invalidated.
      await container.read(recipeListProvider.future);
      verify(() => apiClient.get(
            ApiEndpoints.recipes,
            queryParameters: any(named: 'queryParameters'),
          )).called(1);

      await pumpScreen(tester);
      await tester.enterText(
          find.byType(TextField).first, 'https://example.com/recipe');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Import'));
      await tester.pump(const Duration(milliseconds: 100));

      // Reading again must trigger a fresh fetch (provider was invalidated).
      await container.read(recipeListProvider.future);
      verify(() => apiClient.get(
            ApiEndpoints.recipes,
            queryParameters: any(named: 'queryParameters'),
          )).called(1);
    });

    testWidgets('failure shows the error state without retrying silently',
        (tester) async {
      when(() => apiClient.post(
            ApiEndpoints.importFromUrl,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => throw DioException(
            requestOptions: RequestOptions(path: ApiEndpoints.importFromUrl),
          ));

      await pumpScreen(tester);
      await tester.enterText(
          find.byType(TextField).first, 'https://example.com/broken');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Import'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Could not extract recipe from this URL. '
            'Please try another.'),
        findsOneWidget,
      );
      expect(find.text('View Recipe'), findsNothing);

      // The button returns to an enabled manual-retry state and exactly one
      // request was made (no automatic retry loop).
      final importButton = find.widgetWithText(ElevatedButton, 'Import');
      expect(tester.widget<ElevatedButton>(importButton).onPressed, isNotNull);
      await tester.pump(const Duration(seconds: 2));
      verify(() => apiClient.post(
            ApiEndpoints.importFromUrl,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).called(1);
    });

    testWidgets('changing the URL clears the previous import result',
        (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
          find.byType(TextField).first, 'https://example.com/recipe');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Import'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Imported Pizza'), findsOneWidget);

      await tester.enterText(
          find.byType(TextField).first, 'https://example.com/other');
      await tester.pump();

      expect(find.text('Imported Pizza'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Import'), findsOneWidget);
    });
  });
}
