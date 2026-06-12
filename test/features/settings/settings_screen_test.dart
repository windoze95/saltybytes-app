import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/features/settings/settings_screen.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_helpers.dart';

/// Counts logout() calls so tests can assert the sign-out tile works.
class _RecordingAuthNotifier extends FakeAuthNotifier {
  int logoutCalls = 0;

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late MockApiClient apiClient;
  late _RecordingAuthNotifier authNotifier;
  late ProviderContainer container;

  setUp(() {
    apiClient = MockApiClient();
    authNotifier = _RecordingAuthNotifier();
    container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(apiClient),
      authStateProvider.overrideWith(() => authNotifier),
    ]);

    when(() => apiClient.get(ApiEndpoints.userProfile))
        .thenAnswer((_) async => fakeResponse<dynamic>({
              'user': testUserJson(),
            }));
    when(() => apiClient.put(
          ApiEndpoints.userSettings,
          data: any(named: 'data'),
        )).thenAnswer((_) async => fakeResponse<dynamic>({}));
    when(() => apiClient.put(
          ApiEndpoints.userPersonalization,
          data: any(named: 'data'),
        )).thenAnswer((_) async => fakeResponse<dynamic>({}));
  });

  tearDown(() {
    container.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    // First pump resolves auth, second resolves the profile fetch.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('SettingsScreen unit system', () {
    testWidgets('renders both unit segments enabled with US selected',
        (tester) async {
      await pumpScreen(tester);

      final segFinder = find.byType(SegmentedButton<String>);
      expect(segFinder, findsOneWidget);

      final seg = tester.widget<SegmentedButton<String>>(segFinder);
      expect(seg.segments, hasLength(2));
      expect(seg.segments.map((s) => s.value),
          containsAll(['us_customary', 'metric']));
      // Metric is a real choice now — both segments must be enabled.
      expect(seg.segments.every((s) => s.enabled), isTrue);
      expect(seg.selected, {'us_customary'});
      expect(find.text('US Customary'), findsOneWidget);
    });

    testWidgets('tapping Metric PUTs unit_system=metric', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Metric'));
      await tester.pump(const Duration(milliseconds: 100));

      final captured = verify(() => apiClient.put(
            ApiEndpoints.userPersonalization,
            data: captureAny(named: 'data'),
          )).captured.single as Map<String, dynamic>;
      expect(captured['unit_system'], 'metric');

      // Selection updates locally too.
      final seg = tester
          .widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>));
      expect(seg.selected, {'metric'});
    });
  });

  group('SettingsScreen app settings', () {
    testWidgets('toggling keep-screen-awake persists via PUT settings',
        (tester) async {
      await pumpScreen(tester);

      final tile = find.text('Keep Screen Awake');
      await tester.scrollUntilVisible(tile, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();

      // Fixture starts with keep_screen_awake=true; tapping turns it off.
      await tester.tap(tile);
      await tester.pump(const Duration(milliseconds: 100));

      final captured = verify(() => apiClient.put(
            ApiEndpoints.userSettings,
            data: captureAny(named: 'data'),
          )).captured.single as Map<String, dynamic>;
      expect(captured['keep_screen_awake'], isFalse);

      final switchTile =
          tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchTile.value, isFalse);
    });
  });

  group('SettingsScreen sign out', () {
    testWidgets('confirming the dialog triggers AuthNotifier.logout',
        (tester) async {
      await pumpScreen(tester);

      final signOutButton = find.widgetWithText(OutlinedButton, 'Sign Out');
      await tester.scrollUntilVisible(signOutButton, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();

      await tester.tap(signOutButton);
      await tester.pump(const Duration(milliseconds: 100));

      // Confirmation dialog appears.
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
      expect(authNotifier.logoutCalls, 0);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Out'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(authNotifier.logoutCalls, 1);
    });

    testWidgets('cancelling the dialog does not log out', (tester) async {
      await pumpScreen(tester);

      final signOutButton = find.widgetWithText(OutlinedButton, 'Sign Out');
      await tester.scrollUntilVisible(signOutButton, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();

      await tester.tap(signOutButton);
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(authNotifier.logoutCalls, 0);
      expect(find.text('Are you sure you want to sign out?'), findsNothing);
    });
  });
}
