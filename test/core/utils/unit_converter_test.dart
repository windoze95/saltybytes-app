import 'package:flutter_test/flutter_test.dart';
import 'package:saltybytes_app/core/utils/unit_converter.dart';
import 'package:saltybytes_app/models/recipe.dart';

void main() {
  group('measureKind', () {
    test('classifies volume, mass, count, imprecise', () {
      expect(measureKind('cup', 'flour', 'g'), kindVolume);
      expect(measureKind('g', 'flour', null), kindMass);
      expect(measureKind('pieces', 'egg', null), kindCount);
      expect(measureKind('pinch', 'salt', null), kindImprecise);
      expect(measureKind('', 'salt to taste', null), kindImprecise);
    });

    test('disambiguates oz by metric dimension then name', () {
      expect(measureKind('oz', 'cream cheese', 'g'), kindMass);
      expect(measureKind('oz', 'milk', 'mL'), kindVolume);
      expect(measureKind('oz', 'water', null), kindVolume);
      expect(measureKind('oz', 'sour cream', null), kindMass); // not a fluid
      expect(measureKind('oz', 'chocolate', null), kindMass);
    });
  });

  group('baseAmount', () {
    test('normalizes to grams / mL / count', () {
      expect(baseAmount(2, 'cup', kindVolume), closeTo(473.176, 0.1));
      expect(baseAmount(200, 'g', kindMass), 200);
      expect(baseAmount(8, 'oz', kindMass), closeTo(226.8, 0.1));
      expect(baseAmount(8, 'oz', kindVolume), closeTo(236.6, 0.1)); // fluid oz
      expect(baseAmount(3, 'pieces', kindCount), 3);
      expect(baseAmount(1, 'pinch', kindImprecise), 0);
    });
  });

  group('convertToViewer (same-dimension-first)', () {
    ({double amount, String unit})? toUser(Ingredient ing, String viewer) =>
        convertToViewer(ing, viewer);

    test('US cup -> metric uses the AI density pair', () {
      final ing = Ingredient(
          name: 'flour',
          amount: 2,
          unit: 'cup',
          metricUnit: 'g',
          metricAmount: 240);
      final r = toUser(ing, sysMetric)!;
      expect(r.amount, 240);
      expect(r.unit, 'g');
    });

    test('US cup -> metric without a pair falls to same-dimension mL', () {
      final ing = Ingredient(name: 'water', amount: 2, unit: 'cup');
      final r = toUser(ing, sysMetric)!;
      expect(r.amount, 475);
      expect(r.unit, 'mL');
    });

    test('metric grams -> US is exact ounces, never cups', () {
      final r =
          toUser(Ingredient(name: 'flour', amount: 200, unit: 'g'), sysUS)!;
      expect(r.amount, closeTo(7.1, 0.05));
      expect(r.unit, 'oz');
    });

    test('metric grams chicken -> US is pounds, never cups', () {
      final r =
          toUser(Ingredient(name: 'chicken', amount: 500, unit: 'g'), sysUS)!;
      expect(r.amount, closeTo(1.1, 0.05));
      expect(r.unit, 'lb');
    });

    test('metric mL -> US cup', () {
      final r =
          toUser(Ingredient(name: 'milk', amount: 240, unit: 'mL'), sysUS)!;
      expect(r.amount, 1.0);
      expect(r.unit, 'cup');
    });

    test('small metric mL -> US tsp', () {
      final r =
          toUser(Ingredient(name: 'vanilla', amount: 10, unit: 'mL'), sysUS)!;
      expect(r.amount, 2.0);
      expect(r.unit, 'tsp');
    });

    test('returns null when already in the viewer system', () {
      expect(toUser(Ingredient(name: 'flour', amount: 2, unit: 'cup'), sysUS),
          isNull);
    });

    test('returns null for count and imprecise units', () {
      expect(
          toUser(Ingredient(name: 'egg', amount: 3, unit: 'pieces'), sysMetric),
          isNull);
      expect(
          toUser(Ingredient(name: 'salt', amount: 1, unit: 'pinch'), sysMetric),
          isNull);
      expect(
          toUser(
              Ingredient(name: 'garlic', amount: 2, unit: 'clove'), sysMetric),
          isNull);
      expect(toUser(Ingredient(name: 'water', amount: 1, unit: ''), sysMetric),
          isNull);
    });
  });

  group('formatAmount', () {
    test('US volume uses cooking fractions', () {
      expect(formatAmount(1.5, 'cup'), '1 1/2');
      expect(formatAmount(0.25, 'tsp'), '1/4');
      expect(formatAmount(0.333, 'cup'), '1/3');
      expect(formatAmount(0.667, 'cup'), '2/3');
      expect(formatAmount(0.75, 'tbsp'), '3/4');
      expect(formatAmount(0.375, 'cup'), '3/8');
      expect(formatAmount(2.0, 'cups'), '2');
    });

    test('metric and weights use decimals', () {
      expect(formatAmount(240.0, 'mL'), '240');
      expect(formatAmount(1.5, 'L'), '1.5');
      expect(formatAmount(500.0, 'g'), '500');
      expect(formatAmount(7.1, 'oz'),
          '7.1'); // US weight is decimal, not a fraction
      expect(formatAmount(1.1, 'lb'), '1.1');
    });

    test('zero returns empty string', () {
      expect(formatAmount(0, 'cup'), '');
      expect(formatAmount(0, 'mL'), '');
    });
  });

  group('formatAmountForUnit', () {
    test('null and zero return empty', () {
      expect(formatAmountForUnit(null, 'cup'), '');
      expect(formatAmountForUnit(0, 'cup'), '');
    });

    test('null unit defaults to fraction style', () {
      expect(formatAmountForUnit(1.5, null), '1 1/2');
    });
  });

  group('formatIngredientQuantityWithAlternate', () {
    String render(Ingredient ing, String recipe, String user) =>
        formatIngredientQuantityWithAlternate(ing,
            recipeUnitSystem: recipe, userUnitSystem: user);

    test('US primary with metric alternate from the AI pair', () {
      final ing = Ingredient(
          name: 'flour',
          amount: 2,
          unit: 'cups',
          metricAmount: 240,
          metricUnit: 'g');
      expect(render(ing, 'us_customary', 'metric'), '2 cups (240 g)');
    });

    test('metric primary with clean US alternate', () {
      final ing = Ingredient(name: 'milk', amount: 240, unit: 'mL');
      expect(render(ing, 'metric', 'us_customary'), '240 mL (1 cup)');
    });

    test('metric grams primary gets an exact US weight alternate', () {
      final ing = Ingredient(name: 'flour', amount: 200, unit: 'g');
      expect(render(ing, 'metric', 'us_customary'), '200 g (7.1 oz)');
    });

    test('renders a range and no alternate for count units', () {
      final ing =
          Ingredient(name: 'eggs', amount: 2, unit: 'pieces', amountHigh: 3);
      expect(render(ing, 'us_customary', 'metric'), '2-3 pieces');
    });

    test('omits the alternate when already in the viewer system', () {
      final ing = Ingredient(name: 'flour', amount: 2, unit: 'cups');
      expect(render(ing, 'us_customary', 'us_customary'), '2 cups');
    });
  });

  // The viewer only ever sees a parenthetical when an ingredient's OWN source
  // unit differs from their setting, and the parens hold THEIR system. A US
  // user never sees metric on a US measurement; they see it only on genuinely
  // metric measurements, converted to US. Gating is per-ingredient, not
  // per-recipe — so a mixed recipe converts only its off-system rows.
  group('parenthetical appears only for off-system ingredients', () {
    String render(Ingredient ing, String user) =>
        formatIngredientQuantityWithAlternate(ing,
            recipeUnitSystem: 'us_customary', userUnitSystem: user);

    test('US user, US measurement -> no parens', () {
      expect(
          render(Ingredient(name: 'flour', amount: 2, unit: 'cups'),
              'us_customary'),
          '2 cups');
    });

    test('US user, metric measurement -> parens contain US', () {
      expect(
          render(Ingredient(name: 'sugar', amount: 200, unit: 'g'),
              'us_customary'),
          '200 g (7.1 oz)');
    });

    test('metric user, metric measurement -> no parens', () {
      expect(
          render(Ingredient(name: 'sugar', amount: 200, unit: 'g'), 'metric'),
          '200 g');
    });

    test('mixed recipe, US user -> parens only on the metric row', () {
      expect(
          render(Ingredient(name: 'flour', amount: 2, unit: 'cups'),
              'us_customary'),
          '2 cups'); // US row: untouched
      expect(
          render(Ingredient(name: 'butter', amount: 113, unit: 'g'),
              'us_customary'),
          '113 g (4 oz)'); // metric row: converted to US
    });
  });

  group('parseFractionalAmount', () {
    test('parses integers, decimals, fractions, mixed', () {
      expect(parseFractionalAmount('2'), 2.0);
      expect(parseFractionalAmount('1.5'), 1.5);
      expect(parseFractionalAmount('1/2'), 0.5);
      expect(parseFractionalAmount('2/3'), closeTo(0.667, 0.001));
      expect(parseFractionalAmount('1 1/2'), 1.5);
    });

    test('parses European decimal commas and thousands grouping', () {
      expect(parseFractionalAmount('1,5'), 1.5);
      expect(parseFractionalAmount('0,25'), 0.25);
      expect(parseFractionalAmount('1,000'), 1000.0);
    });

    test('returns null for empty, non-numeric, and divide-by-zero', () {
      expect(parseFractionalAmount(''), isNull);
      expect(parseFractionalAmount('abc'), isNull);
      expect(parseFractionalAmount('1/0'), isNull);
    });
  });
}
