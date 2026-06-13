import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/features/family/family_screen.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_helpers.dart';

/// Fake auth notifier that reports authenticated immediately.
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
  Future<void> logout() async {}
}

Widget _buildScreen(MockApiClient apiClient) {
  return testAppScaffold(
    const FamilyScreen(),
    overrides: [
      apiClientProvider.overrideWithValue(apiClient),
      authStateProvider.overrideWith(_FakeAuthNotifier.new),
    ],
  );
}

/// Pumps several short frames so chained async providers (auth -> family ->
/// fetch) settle without pumpAndSettle (flutter_animate repeats forever).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late MockApiClient apiClient;

  setUp(() {
    apiClient = MockApiClient();
  });

  group('FamilyScreen create-family flow', () {
    testWidgets('shows create state when no family exists and creates one',
        (tester) async {
      when(() => apiClient.get(ApiEndpoints.family)).thenAnswer(
        (_) async => fakeResponse<dynamic>({'family': null}),
      );
      when(() => apiClient.post(ApiEndpoints.family, data: any(named: 'data')))
          .thenAnswer(
        (_) async => fakeResponse<dynamic>({
          'family': testFamilyJson(id: 10, name: 'New Crew', members: []),
        }),
      );

      await tester.pumpWidget(_buildScreen(apiClient));
      await _settle(tester);

      // Create-family empty state, and no FAB until a family exists.
      expect(find.text('Create your family'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.enterText(find.byType(TextField), 'New Crew');
      await tester.tap(find.text('Create Family'));
      await _settle(tester);

      final captured = verify(() => apiClient.post(
            ApiEndpoints.family,
            data: captureAny(named: 'data'),
          )).captured;
      expect(captured.single, {'name': 'New Crew'});

      // Family now exists (no members yet): member empty state + add FAB.
      expect(find.text('No family members yet'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders member list with relationships when family exists',
        (tester) async {
      when(() => apiClient.get(ApiEndpoints.family)).thenAnswer(
        (_) async => fakeResponse<dynamic>({'family': testFamilyJson()}),
      );

      await tester.pumpWidget(_buildScreen(apiClient));
      await _settle(tester);

      expect(find.text('Junior'), findsOneWidget);
      expect(find.text('son'), findsOneWidget);
      expect(find.text('Sarah'), findsOneWidget);
      expect(find.text('spouse'), findsOneWidget);
      // Junior's profile carries one allergy badge.
      expect(find.textContaining('allergy'), findsOneWidget);
    });
  });
}
