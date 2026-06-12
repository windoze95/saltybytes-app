import 'dart:convert';

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
import 'package:saltybytes_app/features/family/dietary_interview_screen.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_helpers.dart';

Widget _buildApp(MockApiClient apiClient, GoRouter router) {
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(apiClient),
      authStateProvider.overrideWith(FakeAuthNotifier.new),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
    ),
  );
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Text('member-detail-screen')),
      ),
      GoRoute(
        path: '/interview',
        builder: (context, state) =>
            const DietaryInterviewScreen(memberId: '1'),
      ),
    ],
  );
}

/// Pumps short frames so chained async providers and the chat-scroll
/// timers (100ms delay + 300ms animateTo) settle without pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
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
    when(() => apiClient.get(ApiEndpoints.family)).thenAnswer(
      (_) async => fakeResponse<dynamic>({'family': testFamilyJson()}),
    );
  });

  group('DietaryInterviewScreen turn round-trip', () {
    testWidgets(
        'start renders the greeting; a send POSTs the running transcript '
        'and renders the reply', (tester) async {
      when(() => apiClient.post(
            ApiEndpoints.familyMemberInterview('1'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'response': 'Got it. Any intolerances I should know about?',
            'complete': false,
          }));

      final router = _buildRouter();
      await tester.pumpWidget(_buildApp(apiClient, router));
      router.push('/interview');
      await _settle(tester);

      // Member name resolved from the family fixture.
      expect(find.text('Dietary Interview - Junior'), findsOneWidget);

      await tester.tap(find.text('Start Interview'));
      await _settle(tester);

      // Assistant greeting bubble.
      expect(find.textContaining('known food allergies'), findsOneWidget);

      await tester.enterText(
          find.byType(TextField), 'Severe peanut allergy');
      await tester.tap(find.byIcon(Icons.send));
      await _settle(tester);

      // The user message and the assistant reply both render.
      expect(find.text('Severe peanut allergy'), findsOneWidget);
      expect(
        find.text('Got it. Any intolerances I should know about?'),
        findsOneWidget,
      );

      // The POST carries the whole conversation in role/content form.
      final body = verify(() => apiClient.post(
            ApiEndpoints.familyMemberInterview('1'),
            data: captureAny(named: 'data'),
          )).captured.single as Map<String, dynamic>;
      final messages = body['messages'] as List;
      expect(messages, hasLength(2));
      expect((messages[0] as Map)['role'], 'assistant');
      expect(
        (messages[1] as Map),
        {'role': 'user', 'content': 'Severe peanut allergy'},
      );
    });

    testWidgets(
        'complete=true with a profile shows Save, and Save PUTs the dietary '
        'route and pops', (tester) async {
      when(() => apiClient.post(
            ApiEndpoints.familyMemberInterview('1'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'response': 'That covers everything — thanks!',
            'complete': true,
            'profile': testDietaryProfileJson(),
          }));
      when(() => apiClient.put(
            ApiEndpoints.familyMemberDietary('1'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({}));

      final router = _buildRouter();
      await tester.pumpWidget(_buildApp(apiClient, router));
      router.push('/interview');
      await _settle(tester);

      await tester.tap(find.text('Start Interview'));
      await _settle(tester);

      await tester.enterText(find.byType(TextField), 'Nothing else');
      await tester.tap(find.byIcon(Icons.send));
      await _settle(tester);

      // Completion banner + Save action appear; the input is gone.
      expect(
        find.textContaining('Interview complete!'),
        findsOneWidget,
      );
      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Save'));
      await _settle(tester);

      final captured = verify(() => apiClient.put(
            ApiEndpoints.familyMemberDietary('1'),
            data: captureAny(named: 'data'),
          )).captured.single;
      // Normalize through json round-trip (what Dio puts on the wire).
      final dietaryBody =
          jsonDecode(jsonEncode(captured)) as Map<String, dynamic>;
      final allergies = dietaryBody['allergies'] as List;
      expect(
        allergies.map((a) => (a as Map<String, dynamic>)['name']),
        contains('peanuts'),
      );

      // Saved: snackbar + pop back to the member detail screen.
      expect(find.text('Dietary profile saved!'), findsOneWidget);
      expect(find.text('member-detail-screen'), findsOneWidget);
    });
  });
}
