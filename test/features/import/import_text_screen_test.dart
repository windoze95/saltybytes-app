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
import 'package:saltybytes_app/features/import/import_text_screen.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late MockApiClient apiClient;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    apiClient = MockApiClient();
    container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(apiClient),
      authStateProvider.overrideWith(FakeAuthNotifier.new),
    ]);

    when(() => apiClient.post(
          ApiEndpoints.importFromText,
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => fakeResponse<dynamic>(
        {'recipe': testRecipeJson(id: 'r-txt-1', title: 'Pasted Lasagna')}));

    router = GoRouter(
      initialLocation: '/import/text',
      routes: [
        GoRoute(
          path: '/import/text',
          builder: (_, __) => const ImportTextScreen(),
        ),
        GoRoute(
          path: '/recipe/:id',
          builder: (_, state) => Scaffold(
            body: Text('detail-${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    // The 12-line text area pushes the result card below the default 600px
    // surface; enlarge it so post-import widgets are tappable.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ImportTextScreen', () {
    testWidgets('successful extraction parses the recipe envelope',
        (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
          find.byType(TextField), 'Ingredients: 2 cups flour...');
      await tester.tap(find.text('Extract Recipe'));
      await tester.pump(const Duration(milliseconds: 100));

      // Envelope {"recipe": {...}} is unwrapped and rendered.
      expect(find.text('Pasted Lasagna'), findsOneWidget);
      expect(find.text('View Recipe'), findsOneWidget);

      // Single-shot: the button flips to a disabled 'Imported'.
      final imported = find.widgetWithText(ElevatedButton, 'Imported');
      expect(imported, findsOneWidget);
      expect(tester.widget<ElevatedButton>(imported).onPressed, isNull);
      await tester.tap(imported, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => apiClient.post(
            ApiEndpoints.importFromText,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).called(1);
    });

    testWidgets('posts the pasted text in the request body', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField), '  My recipe text  ');
      await tester.tap(find.text('Extract Recipe'));
      await tester.pump(const Duration(milliseconds: 100));

      final captured = verify(() => apiClient.post(
            ApiEndpoints.importFromText,
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single as Map<String, dynamic>;
      expect(captured['text'], 'My recipe text');
    });

    testWidgets('View Recipe navigates to the imported recipe',
        (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField), 'some recipe text');
      await tester.tap(find.text('Extract Recipe'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('View Recipe'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('detail-r-txt-1'), findsOneWidget);
    });

    testWidgets('failure shows the error state without retrying silently',
        (tester) async {
      when(() => apiClient.post(
            ApiEndpoints.importFromText,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => throw DioException(
            requestOptions: RequestOptions(path: ApiEndpoints.importFromText),
          ));

      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'gibberish');
      await tester.tap(find.text('Extract Recipe'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Could not extract a recipe from this text. '
            'Try reformatting.'),
        findsOneWidget,
      );
      expect(find.text('View Recipe'), findsNothing);

      // The button returns to an enabled manual-retry state; exactly one
      // request was made (no automatic retry loop).
      final extract = find.widgetWithText(ElevatedButton, 'Extract Recipe');
      expect(tester.widget<ElevatedButton>(extract).onPressed, isNotNull);
      await tester.pump(const Duration(seconds: 2));
      verify(() => apiClient.post(
            ApiEndpoints.importFromText,
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).called(1);
    });

    testWidgets('empty input shows a validation message and skips the API',
        (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Extract Recipe'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Please paste some recipe text.'), findsOneWidget);
      verifyNever(() => apiClient.post(
            ApiEndpoints.importFromText,
            data: any(named: 'data'),
            options: any(named: 'options'),
          ));
    });
  });
}
