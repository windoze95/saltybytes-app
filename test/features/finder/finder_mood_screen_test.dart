import 'package:flutter/material.dart';
// FamilyNotifier is also exported by Riverpod; hide it so the subclass below
// extends our app's FamilyNotifier.
import 'package:flutter_riverpod/flutter_riverpod.dart' hide FamilyNotifier;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:saltybytes_app/core/providers/family_provider.dart';
import 'package:saltybytes_app/core/theme/app_theme.dart';
import 'package:saltybytes_app/core/voice/speech_service.dart';
import 'package:saltybytes_app/features/finder/finder_mood_screen.dart';
import 'package:saltybytes_app/models/family.dart' as models;

import '../../helpers/fixtures.dart';
import '../../helpers/test_helpers.dart';

/// Family notifier that returns a fixed family without any API/auth wiring.
class _FakeFamilyNotifier extends FamilyNotifier {
  _FakeFamilyNotifier(this._family);

  final models.Family? _family;

  @override
  Future<models.Family?> build() async => _family;
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/find',
    routes: [
      GoRoute(path: '/find', builder: (_, __) => const FinderMoodScreen()),
      GoRoute(
        path: '/find/run',
        name: 'find-run',
        builder: (_, __) => const Scaffold(body: Text('run-stub')),
      ),
      GoRoute(
        path: '/import',
        name: 'import',
        builder: (_, __) => const Scaffold(body: Text('import-stub')),
      ),
      GoRoute(
        path: '/family',
        name: 'family',
        builder: (_, __) => const Scaffold(body: Text('family-stub')),
      ),
    ],
  );
}

Widget _buildApp({models.Family? family}) {
  return ProviderScope(
    overrides: [
      familyProvider.overrideWith(() => _FakeFamilyNotifier(family)),
      speechServiceProvider.overrideWithValue(FakeSpeechService()),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: _buildRouter(),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('FinderMoodScreen', () {
    testWidgets('tapping a facet chip selects it (and untapping clears it)',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await _settle(tester);

      ChoiceChip chip(String label) =>
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));

      expect(chip('Weeknight').selected, isFalse);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Weeknight'));
      await tester.pump();
      expect(chip('Weeknight').selected, isTrue);

      // Tapping the selected chip again clears it.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Weeknight'));
      await tester.pump();
      expect(chip('Weeknight').selected, isFalse);
    });

    testWidgets('Surprise me toggles on tap', (tester) async {
      await tester.pumpWidget(_buildApp());
      await _settle(tester);

      // No check icon until selected.
      expect(find.byIcon(Icons.check_circle), findsNothing);
      await tester.tap(find.text('Surprise me'));
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders the dietary summary chip from the family provider',
        (tester) async {
      final family = models.Family.fromJson(testFamilyJson());
      await tester.pumpWidget(_buildApp(family: family));
      await _settle(tester);

      expect(find.text('Cooking for your family'), findsOneWidget);
      // Junior carries a peanut allergy + vegetarian restriction (fixtures).
      expect(find.textContaining('no peanuts'), findsOneWidget);
      expect(find.textContaining('vegetarian'), findsOneWidget);
    });

    testWidgets('hides the dietary chip when there is no family',
        (tester) async {
      await tester.pumpWidget(_buildApp(family: null));
      await _settle(tester);

      expect(find.text('Cooking for your family'), findsNothing);
    });

    testWidgets('Find recipes navigates to the run screen', (tester) async {
      await tester.pumpWidget(_buildApp());
      await _settle(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Find recipes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('run-stub'), findsOneWidget);
    });
  });
}
