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
import 'package:saltybytes_app/core/providers/user_provider.dart';
import 'package:saltybytes_app/features/auth/verify_email_screen.dart';
import 'package:saltybytes_app/models/user.dart';

import '../../helpers/test_helpers.dart';

class _FakeCurrentUser extends AsyncNotifier<User?>
    implements CurrentUserNotifier {
  _FakeCurrentUser(this.user);

  final User? user;
  bool refreshed = false;

  @override
  Future<User?> build() async => user;

  @override
  Future<void> refreshProfile() async {
    refreshed = true;
  }

  @override
  Future<void> updateSettings(UserSettings settings) async {}

  @override
  Future<void> updatePersonalization(Personalization personalization) async {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late MockApiClient api;

  setUp(() {
    api = MockApiClient();
  });

  final testUser = User(
    id: 'u-1',
    username: 'newchef',
    email: 'newchef@example.com',
    emailVerified: false,
    createdAt: DateTime(2026, 7, 1),
  );

  Future<(_FakeCurrentUser, FakeAuthNotifier)> pumpScreen(
      WidgetTester tester) async {
    final userNotifier = _FakeCurrentUser(testUser);
    final authNotifier = FakeAuthNotifier();

    final router = GoRouter(
      initialLocation: '/verify-email',
      routes: [
        GoRoute(
          path: '/verify-email',
          builder: (_, __) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('HOME-STUB')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          currentUserProvider.overrideWith(() => userNotifier),
          authStateProvider.overrideWith(() => authNotifier),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    return (userNotifier, authNotifier);
  }

  testWidgets('shows the destination email and a cooled-down resend button',
      (tester) async {
    await pumpScreen(tester);

    expect(
        find.textContaining('newchef@example.com', findRichText: true),
        findsOneWidget);
    expect(find.textContaining('Resend code in'), findsOneWidget);
  });

  testWidgets('submitting the code POSTs confirm, refreshes the profile and '
      'lands on home', (tester) async {
    when(() => api.post(
          ApiEndpoints.emailVerificationConfirm,
          data: any(named: 'data'),
        )).thenAnswer((_) async => fakeResponse<dynamic>({'message': 'ok'}));

    final (userNotifier, _) = await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    final body = verify(() => api.post(
          ApiEndpoints.emailVerificationConfirm,
          data: captureAny(named: 'data'),
        )).captured.single;
    expect(body, {'code': '123456'});
    expect(userNotifier.refreshed, isTrue);
    expect(find.text('HOME-STUB'), findsOneWidget);
  });

  testWidgets('a wrong code shows the server message and stays put',
      (tester) async {
    when(() => api.post(
          ApiEndpoints.emailVerificationConfirm,
          data: any(named: 'data'),
        )).thenThrow(DioException(
      requestOptions:
          RequestOptions(path: ApiEndpoints.emailVerificationConfirm),
      error: const ApiError(
        message: "That code didn't match. Try again.",
        statusCode: 400,
        errorCode: 'code_invalid',
      ),
    ));

    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), '000000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("That code didn't match. Try again."), findsOneWidget);
    expect(find.text('HOME-STUB'), findsNothing);
  });

  testWidgets('short codes are rejected client-side without a request',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Enter the 6-digit code from the email'), findsOneWidget);
    verifyNever(() => api.post(any(), data: any(named: 'data')));
  });

  testWidgets('skip for now clears the routing flag and goes home',
      (tester) async {
    final (_, authNotifier) = await pumpScreen(tester);
    authNotifier.needsEmailVerification = true;

    await tester.tap(find.text('Skip for now'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('HOME-STUB'), findsOneWidget);
    expect(authNotifier.needsEmailVerification, isFalse);
  });
}
