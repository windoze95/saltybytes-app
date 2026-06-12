import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/features/family/family_member_detail_screen.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_helpers.dart';

Widget _buildScreen(MockApiClient apiClient) {
  return testAppScaffold(
    const FamilyMemberDetailScreen(memberId: '1'),
    overrides: [
      apiClientProvider.overrideWithValue(apiClient),
      authStateProvider.overrideWith(FakeAuthNotifier.new),
    ],
  );
}

/// Pumps several short frames so chained async providers (auth -> family)
/// settle without pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
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

  group('FamilyMemberDetailScreen view mode', () {
    testWidgets('renders the member profile from the family fixture',
        (tester) async {
      _useTallViewport(tester);
      await tester.pumpWidget(_buildScreen(apiClient));
      await _settle(tester);

      // Junior appears in the app bar and the header.
      expect(find.text('Junior'), findsNWidgets(2));
      expect(find.text('son'), findsOneWidget);
      expect(find.text('peanuts'), findsOneWidget); // allergy
      expect(find.text('lactose'), findsOneWidget); // intolerance
      expect(find.text('vegetarian'), findsOneWidget); // restriction chip
      expect(find.text('no cilantro'), findsOneWidget); // preference chip
      expect(find.text('AI Dietary Interview'), findsOneWidget);
    });

    testWidgets('shows a not-found body for an unknown member',
        (tester) async {
      await tester.pumpWidget(testAppScaffold(
        const FamilyMemberDetailScreen(memberId: '999'),
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider.overrideWith(FakeAuthNotifier.new),
        ],
      ));
      await _settle(tester);

      expect(find.text('Member not found'), findsOneWidget);
    });
  });

  group('FamilyMemberDetailScreen edit + save', () {
    testWidgets(
        'saving persists name via PUT member and the profile via PUT dietary',
        (tester) async {
      _useTallViewport(tester);
      when(() => apiClient.put(
            ApiEndpoints.familyMember('1'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'member': testFamilyMemberJson(id: 1, name: 'Junior Jr'),
          }));
      when(() => apiClient.put(
            ApiEndpoints.familyMemberDietary('1'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({}));

      await tester.pumpWidget(_buildScreen(apiClient));
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.edit));
      await _settle(tester);

      // Edit mode: name/relationship become text fields.
      expect(find.text('Edit Member'), findsOneWidget);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Junior'), 'Junior Jr');
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Save'));
      await _settle(tester);

      final memberBody = verify(() => apiClient.put(
            ApiEndpoints.familyMember('1'),
            data: captureAny(named: 'data'),
          )).captured.single as Map<String, dynamic>;
      expect(memberBody, {'name': 'Junior Jr', 'relationship': 'son'});

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
      expect(dietaryBody['intolerances'], contains('lactose'));
      expect(dietaryBody['restrictions'], contains('vegetarian'));
      expect(dietaryBody['preferences'], contains('no cilantro'));

      // Back in view mode with the updated name from the PUT response.
      expect(find.text('Edit Member'), findsNothing);
      expect(find.text('Junior Jr'), findsWidgets);
    });

    testWidgets('editing chips: removing a restriction drops it from the '
        'dietary PUT body', (tester) async {
      _useTallViewport(tester);
      when(() => apiClient.put(
            ApiEndpoints.familyMember('1'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({
            'member': testFamilyMemberJson(id: 1),
          }));
      when(() => apiClient.put(
            ApiEndpoints.familyMemberDietary('1'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({}));

      await tester.pumpWidget(_buildScreen(apiClient));
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.edit));
      await _settle(tester);

      // Delete the 'vegetarian' chip via its delete icon.
      final vegetarianChip = find.widgetWithText(Chip, 'vegetarian');
      expect(vegetarianChip, findsOneWidget);
      await tester.tap(find.descendant(
        of: vegetarianChip,
        matching: find.byIcon(Icons.cancel),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Save'));
      await _settle(tester);

      final captured = verify(() => apiClient.put(
            ApiEndpoints.familyMemberDietary('1'),
            data: captureAny(named: 'data'),
          )).captured.single;
      final dietaryBody =
          jsonDecode(jsonEncode(captured)) as Map<String, dynamic>;
      expect(dietaryBody['restrictions'], isEmpty);
    });
  });
}
