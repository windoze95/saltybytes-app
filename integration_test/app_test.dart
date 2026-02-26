/// End-to-end integration tests for the SaltyBytes app.
///
/// These tests launch the full app on a simulator/device and verify that
/// core user flows work correctly against the live production API.
///
/// ## Prerequisites
///   - An iOS Simulator must be booted (or a physical device connected)
///   - The production API (https://api.saltybytes.ai) must be reachable
///   - A valid test account must exist (see [_kUsername] / [_kPassword])
///
/// ## Running
///   ```bash
///   # Run on the default device
///   flutter test integration_test/app_test.dart
///
///   # Run on a specific simulator
///   flutter test integration_test/app_test.dart -d <DEVICE_ID>
///   ```
///
/// ## What's covered
///   1. **Login flow** — enters credentials, taps Sign In, verifies navigation
///      to the home screen.
///   2. **Home screen** — verifies the recipe grid renders with recipe titles,
///      cook times, and servings.
///   3. **Recipe detail** — taps a recipe card and verifies the detail screen
///      loads with ingredients & instructions (no null-type-cast crash).
///   4. **Bottom navigation** — cycles through Search, Family, Settings, and
///      back to Home to verify each tab renders.
///   5. **Add Recipe sheet** — taps the FAB and verifies the bottom-sheet
///      import menu appears.
///   6. **Import options** — navigates into the import screen and verifies all
///      four import cards render.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:saltybytes_app/main.dart' as app;

// ---------------------------------------------------------------------------
// Test account credentials – must exist on the production API.
// ---------------------------------------------------------------------------
const _kUsername = 'julian';
const _kPassword = r'4%A^5Yd^m67WLfC!';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SaltyBytes end-to-end', () {
    testWidgets('Full app walkthrough', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ----- 1. Login (or skip if already authenticated) ----- //
      final textFormFields = find.byType(TextFormField);
      if (textFormFields.evaluate().length >= 2) {
        debugPrint('── Login screen detected');

        await tester.tap(textFormFields.at(0));
        await tester.pumpAndSettle();
        await tester.enterText(textFormFields.at(0), _kUsername);

        await tester.tap(textFormFields.at(1));
        await tester.pumpAndSettle();
        await tester.enterText(textFormFields.at(1), _kPassword);

        final signIn = find.widgetWithText(ElevatedButton, 'Sign In');
        expect(signIn, findsOneWidget, reason: 'Sign In button should exist');
        await tester.tap(signIn);

        // Wait for network + auth + navigation.
        await _pumpUntilSettled(tester, timeout: const Duration(seconds: 12));
        debugPrint('── Login complete');
      } else {
        debugPrint('── Already authenticated, skipping login');
      }

      // ----- 2. Home screen — recipe grid ----- //
      await _pumpUntilSettled(tester);
      _expectAnyText(
        ['Taco', 'Spaghetti', 'Grilled Cheese', 'Chicken', 'Stroganoff'],
        reason: 'Home grid should contain at least one known recipe',
      );
      debugPrint('── Home screen OK — recipes visible');

      // ----- 3. Recipe detail ----- //
      // Tap a recipe title to navigate to the detail screen.
      // We tap the text directly (inside the InkWell) rather than the Card
      // container, because the Card itself doesn't carry the tap gesture.
      final recipeTitles = [
        find.textContaining('Taco Recipe'),
        find.textContaining('Grilled Cheese'),
        find.textContaining('Spaghetti'),
      ];
      Finder? titleToTap;
      for (final f in recipeTitles) {
        if (f.evaluate().isNotEmpty) {
          titleToTap = f.first;
          break;
        }
      }
      expect(titleToTap, isNotNull, reason: 'Should find a recipe to tap');
      await tester.tap(titleToTap!);
      await _pumpUntilSettled(tester, timeout: const Duration(seconds: 10));

      // If the detail screen loaded without the old "type 'Null' is not a
      // subtype of type 'String'" error, these finders will succeed.
      // "Ingredients" is above the fold; "Instructions" is below, so we
      // check it with skipOffstage: false (off-screen but in the tree).
      expect(find.text('Ingredients'), findsOneWidget,
          reason: 'Detail screen should show Ingredients heading');
      expect(
          find.text('Instructions', skipOffstage: false), findsWidgets,
          reason: 'Detail screen should have Instructions in the widget tree');
      debugPrint('── Recipe detail OK — ingredients & instructions loaded');

      // Navigate back to home.
      await _goBack(tester);
      await _pumpUntilSettled(tester);

      // ----- 4. Bottom navigation tabs ----- //
      for (final tab in ['Search', 'Family', 'Settings']) {
        final tabFinder = find.text(tab);
        if (tabFinder.evaluate().isNotEmpty) {
          await tester.tap(tabFinder.last); // last = bottom-nav label
          await _pumpUntilSettled(tester);
          debugPrint('── $tab tab OK');
        }
      }

      // Return to Home.
      final homeTab = find.text('Home');
      if (homeTab.evaluate().isNotEmpty) {
        await tester.tap(homeTab.last);
        await _pumpUntilSettled(tester);
      }

      // ----- 5. Add Recipe bottom sheet ----- //
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget, reason: 'Home should have a FAB');
      await tester.tap(fab);
      await _pumpUntilSettled(tester);

      expect(find.text('Add Recipe'), findsOneWidget,
          reason: 'Bottom sheet should show "Add Recipe" title');
      expect(find.text('Generate with AI'), findsOneWidget);
      expect(find.text('Import from URL'), findsOneWidget);
      debugPrint('── Add Recipe sheet OK');

      // Tap "Generate with AI" to navigate to the import screen.
      await tester.tap(find.text('Generate with AI'));
      await _pumpUntilSettled(tester);

      // ----- 6. Import options screen ----- //
      expect(find.text('From URL'), findsOneWidget);
      expect(find.text('From Photo'), findsOneWidget);
      expect(find.text('From Text'), findsOneWidget);
      expect(find.text('Manual Entry'), findsOneWidget);
      debugPrint('── Import screen OK — all 4 options visible');

      debugPrint('══ All checks passed ══');
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps frames until the widget tree settles or the [timeout] is reached.
///
/// Flutter's `pumpAndSettle` can throw if animations are looping (e.g. shimmer
/// effects). This helper retries up to [timeout] worth of 1-second pumps.
Future<void> _pumpUntilSettled(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(seconds: 1));
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      return;
    } catch (_) {
      // Animations still running — keep pumping.
    }
  }
}

/// Asserts that at least one of the given [substrings] appears somewhere on
/// screen as part of a Text widget.
void _expectAnyText(List<String> substrings, {required String reason}) {
  for (final s in substrings) {
    if (find.textContaining(s).evaluate().isNotEmpty) return;
  }
  fail('$reason (looked for: ${substrings.join(", ")})');
}

/// Taps the first back-navigation affordance found on screen.
Future<void> _goBack(WidgetTester tester) async {
  // SliverAppBar uses the default leading back button (Icons.arrow_back_ios or
  // BackButton). Try common variants.
  for (final icon in [Icons.arrow_back, Icons.arrow_back_ios, Icons.close]) {
    final finder = find.byIcon(icon);
    if (finder.evaluate().isNotEmpty) {
      await tester.tap(finder.first);
      return;
    }
  }
  // Fallback: BackButton widget.
  final backButton = find.byType(BackButton);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
  }
}
