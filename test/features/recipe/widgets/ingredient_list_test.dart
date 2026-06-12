import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/features/recipe/widgets/ingredient_list.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/pump_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Builds the list under a user whose personalization carries [unitSystem]
/// (null leaves the user signed out: defaults to us_customary).
Widget _build(
  List<Ingredient> ingredients, {
  required String recipeUnitSystem,
  String? userUnitSystem,
}) {
  final overrides = <Override>[];
  if (userUnitSystem != null) {
    final apiClient = MockApiClient();
    when(() => apiClient.get(ApiEndpoints.userProfile))
        .thenAnswer((_) async => fakeResponse<dynamic>({
              'user': testUserJson(
                personalization:
                    testPersonalizationJson(unitSystem: userUnitSystem),
              ),
            }));
    overrides
      ..add(apiClientProvider.overrideWithValue(apiClient))
      ..add(authStateProvider.overrideWith(FakeAuthNotifier.new));
  } else {
    overrides.add(authStateProvider
        .overrideWith(() => FakeAuthNotifier(AuthStatus.unauthenticated)));
  }

  return testApp(
    IngredientList(
      ingredients: ingredients,
      recipeUnitSystem: recipeUnitSystem,
    ),
    overrides: overrides,
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Ingredient _ing(String name, double? amount, String? unit,
    {String? metricUnit, double? metricAmount}) {
  return Ingredient(
    name: name,
    amount: amount,
    unit: unit,
    metricUnit: metricUnit,
    metricAmount: metricAmount,
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('IngredientList us_customary -> metric conversion', () {
    testWidgets('converts volume and weight for a metric user',
        (tester) async {
      await tester.pumpWidget(_build(
        [
          _ing('flour', 2.0, 'cups'),
          _ing('ground beef', 1.0, 'lb'),
        ],
        recipeUnitSystem: 'us_customary',
        userUnitSystem: 'metric',
      ));
      await _settle(tester);

      expect(find.text('480 mL'), findsOneWidget); // 2 cups
      expect(find.text('450 g'), findsOneWidget); // 1 lb, rounded to 10 g
      expect(find.text('flour'), findsOneWidget);
      expect(find.text('ground beef'), findsOneWidget);
    });

    testWidgets('prefers AI-provided metric_amount/metric_unit when present',
        (tester) async {
      await tester.pumpWidget(_build(
        [
          _ing('cheddar', 8.0, 'oz', metricUnit: 'g', metricAmount: 225.0),
        ],
        recipeUnitSystem: 'us_customary',
        userUnitSystem: 'metric',
      ));
      await _settle(tester);

      // 8 oz * 28 would be 225 anyway via fallback, but the AI value wins:
      // the displayed pair comes straight from metric_amount/metric_unit.
      expect(find.text('225 g'), findsOneWidget);
      expect(find.text('8 oz'), findsNothing);
    });

    testWidgets('identity units pass through unconverted', (tester) async {
      await tester.pumpWidget(_build(
        [_ing('garlic', 2.0, 'cloves')],
        recipeUnitSystem: 'us_customary',
        userUnitSystem: 'metric',
      ));
      await _settle(tester);

      expect(find.text('2 cloves'), findsOneWidget);
    });
  });

  group('IngredientList metric -> us_customary conversion', () {
    testWidgets('converts weight and volume for a US user (signed out '
        'defaults to us_customary)', (tester) async {
      await tester.pumpWidget(_build(
        [
          _ing('parmesan', 84.0, 'g'),
          _ing('vanilla', 10.0, 'mL'),
        ],
        recipeUnitSystem: 'metric',
      ));
      await _settle(tester);

      expect(find.text('3 oz'), findsOneWidget); // 84 g / 28
      expect(find.text('2 tsp'), findsOneWidget); // 10 mL / 5
    });

    testWidgets('keeps the metric unit when the US amount would be ugly',
        (tester) async {
      await tester.pumpWidget(_build(
        // 100 g -> 3.571 oz: no clean fraction, so the original stays.
        [_ing('chocolate', 100.0, 'g')],
        recipeUnitSystem: 'metric',
      ));
      await _settle(tester);

      expect(find.text('100 g'), findsOneWidget);
    });
  });

  group('IngredientList amount formatting', () {
    testWidgets('US amounts render as cooking fractions', (tester) async {
      await tester.pumpWidget(_build(
        [
          _ing('flour', 1.5, 'cups'),
          _ing('salt', 0.75, 'tsp'),
        ],
        recipeUnitSystem: 'us_customary',
      ));
      await _settle(tester);

      expect(find.text('1 1/2 cups'), findsOneWidget);
      expect(find.text('3/4 tsp'), findsOneWidget);
    });

    testWidgets('metric amounts render as clean decimals', (tester) async {
      await tester.pumpWidget(_build(
        [
          _ing('saffron', 2.5, 'g'),
          _ing('milk', 250.0, 'mL'),
        ],
        recipeUnitSystem: 'metric',
        userUnitSystem: 'metric',
      ));
      await _settle(tester);

      expect(find.text('2.5 g'), findsOneWidget);
      expect(find.text('250 mL'), findsOneWidget);
    });

    testWidgets('amountless ingredients render just the name',
        (tester) async {
      await tester.pumpWidget(_build(
        [_ing('salt to taste', null, null)],
        recipeUnitSystem: 'us_customary',
      ));
      await _settle(tester);

      expect(find.text('salt to taste'), findsOneWidget);
    });
  });
}
