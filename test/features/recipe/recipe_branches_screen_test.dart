import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/recipe_provider.dart';
import 'package:saltybytes_app/features/recipe/recipe_branches_screen.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_helpers.dart';

Widget _buildScreen(MockApiClient apiClient) {
  final recipe = Recipe.fromJson(testRecipeJson(id: 'r-1', imageUrl: null));
  return testAppScaffold(
    const RecipeBranchesScreen(recipeId: 'r-1'),
    overrides: [
      apiClientProvider.overrideWithValue(apiClient),
      authStateProvider
          .overrideWith(() => FakeAuthNotifier(AuthStatus.unauthenticated)),
      recipeDetailProvider.overrideWith((ref, id) async => recipe),
    ],
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The node list shares the screen with the tree painter; use a taller
/// surface so all three node cards build and are tappable.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
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
    when(() => apiClient.get(ApiEndpoints.recipeTree('r-1')))
        .thenAnswer((_) async => fakeResponse<dynamic>({
              'tree': testRecipeTreeJson(recipeId: 'r-1'),
            }));
  });

  group('RecipeBranchesScreen tree rendering', () {
    testWidgets('renders the 3-node tree: root plus two branches',
        (tester) async {
      _useTallViewport(tester);
      await tester.pumpWidget(_buildScreen(apiClient));
      await _settle(tester);

      expect(find.text('Recipe Tree'), findsOneWidget);
      expect(find.text('original'), findsOneWidget);
      expect(find.text('spicy-version'), findsOneWidget);
      expect(find.text('vegan-version'), findsOneWidget);

      // Node summaries render under each branch name.
      expect(find.text('Doubled the chili'), findsOneWidget);
      expect(find.text('Swapped dairy for cashew cream'), findsOneWidget);

      // Exactly one node (the root) carries the ACTIVE chip.
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('marks the branch flagged by active_node_id as ACTIVE',
        (tester) async {
      _useTallViewport(tester);
      when(() => apiClient.get(ApiEndpoints.recipeTree('r-1')))
          .thenAnswer((_) async => fakeResponse<dynamic>({
                'tree': testRecipeTreeJson(recipeId: 'r-1', activeNodeId: 2),
              }));

      await tester.pumpWidget(_buildScreen(apiClient));
      await _settle(tester);

      // The ACTIVE chip lives in the same row as the active branch name.
      final activeRow = find.ancestor(
        of: find.text('ACTIVE'),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: activeRow.first, matching: find.text('spicy-version')),
        findsOneWidget,
      );
    });
  });

  group('RecipeBranchesScreen set active node', () {
    testWidgets('tapping a node fires PUT .../tree/active/:nodeId',
        (tester) async {
      _useTallViewport(tester);
      when(() => apiClient.put('${ApiEndpoints.recipeTree('r-1')}/active/2'))
          .thenAnswer(
              (_) async => fakeResponse<dynamic>({'message': 'active node set'}));

      await tester.pumpWidget(_buildScreen(apiClient));
      await _settle(tester);

      await tester.tap(find.text('spicy-version'));
      await _settle(tester);

      verify(() =>
              apiClient.put('${ApiEndpoints.recipeTree('r-1')}/active/2'))
          .called(1);
      expect(find.text('Switched active node'), findsOneWidget);
    });

    testWidgets('shows a failure snackbar when set-active errors',
        (tester) async {
      _useTallViewport(tester);
      when(() => apiClient.put('${ApiEndpoints.recipeTree('r-1')}/active/3'))
          .thenAnswer((_) async => throw Exception('boom'));

      await tester.pumpWidget(_buildScreen(apiClient));
      await _settle(tester);

      await tester.tap(find.text('vegan-version'));
      await _settle(tester);

      expect(find.textContaining('Failed to switch node'), findsOneWidget);
    });
  });
}
