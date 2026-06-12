import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/features/import/import_manual_screen.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_helpers.dart';

class _FakeAuthNotifier extends AsyncNotifier<AuthStatus>
    implements AuthNotifier {
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
  void enterDemoMode() {}

  @override
  Future<void> logout() async {}
}

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
      authStateProvider.overrideWith(_FakeAuthNotifier.new),
    ]);

    when(() => apiClient.get(
          ApiEndpoints.recipes,
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer(
        (_) async => fakeResponse<dynamic>({'recipes': <dynamic>[]}));

    when(() => apiClient.post(
          ApiEndpoints.importManual,
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => fakeResponse<dynamic>(
        {'recipe': testRecipeJson(id: 'r-77', title: 'Grandma Cake')}));

    router = GoRouter(
      initialLocation: '/import/manual',
      routes: [
        GoRoute(
          path: '/import/manual',
          builder: (_, __) => const ImportManualScreen(),
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
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> fillForm(WidgetTester tester) async {
    // Field order on screen: title, cook time, portions are TextFormFields;
    // ingredient amount/name and instruction steps are plain TextFields.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Recipe Title'), 'Grandma Cake');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Cook Time (min)'), '45');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Portions'), '8');
    await tester.enterText(
        find.widgetWithText(TextField, 'Amt'), '1 1/2');
    await tester.enterText(
        find.widgetWithText(TextField, 'Ingredient name'), 'flour');
    await tester.enterText(
        find.widgetWithText(TextField, 'Step 1'), 'Mix everything');
    await tester.pump();
  }

  group('ImportManualScreen', () {
    testWidgets(
        'saves via POST /recipes/import/manual with snake_case body shape',
        (tester) async {
      await pumpScreen(tester);
      await fillForm(tester);

      // Tap the app bar Save action.
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pump(const Duration(milliseconds: 100));

      final captured = verify(() => apiClient.post(
            ApiEndpoints.importManual,
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single as Map<String, dynamic>;

      expect(captured['title'], 'Grandma Cake');
      expect(captured['cook_time'], 45);
      expect(captured['portions'], 8);
      expect(captured['instructions'], ['Mix everything']);

      final ingredients = captured['ingredients'] as List;
      expect(ingredients, hasLength(1));
      final flour = ingredients.first as Map<String, dynamic>;
      expect(flour['name'], 'flour');
      expect(flour['amount'], 1.5); // "1 1/2" parsed as fractional amount
      expect(flour.containsKey('unit'), isTrue);

      // No camelCase keys leak into the request.
      expect(captured.containsKey('cookTimeMinutes'), isFalse);
      expect(captured.containsKey('ownerId'), isFalse);
      expect(captured.containsKey('id'), isFalse);
    });

    testWidgets('navigates to the created recipe after save', (tester) async {
      await pumpScreen(tester);
      await fillForm(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('detail-r-77'), findsOneWidget);
    });

    testWidgets('does not POST when title is missing', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => apiClient.post(
            ApiEndpoints.importManual,
            data: any(named: 'data'),
            options: any(named: 'options'),
          ));
      expect(find.text('Title is required'), findsOneWidget);
    });
  });
}
