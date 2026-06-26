import 'package:flutter_test/flutter_test.dart';
import 'package:saltybytes_app/core/utils/unit_converter.dart';
import 'package:saltybytes_app/models/recipe.dart';

void main() {
  group('needsConversion', () {
    test('returns false when systems match', () {
      expect(needsConversion('us_customary', 'us_customary'), isFalse);
      expect(needsConversion('metric', 'metric'), isFalse);
    });

    test('returns true when systems differ', () {
      expect(needsConversion('us_customary', 'metric'), isTrue);
      expect(needsConversion('metric', 'us_customary'), isTrue);
    });
  });

  group('US to Metric conversion', () {
    Ingredient convert(double amount, String unit) {
      return convertIngredient(
        Ingredient(name: 'test', amount: amount, unit: unit),
        'us_customary',
        'metric',
      );
    }

    test('tsp to mL', () {
      final result = convert(2, 'tsp');
      expect(result.amount, 10.0);
      expect(result.unit, 'mL');
    });

    test('tbsp to mL', () {
      final result = convert(3, 'tbsp');
      expect(result.amount, 45.0);
      expect(result.unit, 'mL');
    });

    test('cup to mL', () {
      final result = convert(1, 'cup');
      expect(result.amount, 240.0);
      expect(result.unit, 'mL');
    });

    test('cups to mL (plural)', () {
      final result = convert(2, 'cups');
      expect(result.amount, 480.0);
      expect(result.unit, 'mL');
    });

    test('fl oz to mL', () {
      final result = convert(8, 'fl oz');
      expect(result.amount, 240.0);
      expect(result.unit, 'mL');
    });

    test('qt to L', () {
      final result = convert(1, 'qt');
      expect(result.amount, closeTo(0.95, 0.1));
      expect(result.unit, 'L');
    });

    test('gal to L', () {
      final result = convert(1, 'gal');
      expect(result.amount, closeTo(4.0, 0.25));
      expect(result.unit, 'L');
    });

    test('oz to g', () {
      final result = convert(4, 'oz');
      expect(result.amount, closeTo(110, 5));
      expect(result.unit, 'g');
    });

    test('lb to g', () {
      final result = convert(1, 'lb');
      expect(result.amount, closeTo(450, 10));
      expect(result.unit, 'g');
    });

    test('auto-scales mL to L when >= 1000', () {
      final result = convert(5, 'cups'); // 5 * 240 = 1200 mL
      expect(result.unit, 'L');
      expect(result.amount, closeTo(1.2, 0.1));
    });

    test('auto-scales g to kg when >= 1000', () {
      final result = convert(3, 'lb'); // 3 * 454 = 1362 g
      expect(result.unit, 'kg');
      expect(result.amount, closeTo(1.4, 0.1));
    });

    test('pint to mL', () {
      final result = convert(1, 'pt');
      expect(result.amount, 475.0);
      expect(result.unit, 'mL');
    });
  });

  group('Metric to US conversion', () {
    Ingredient convert(double amount, String unit) {
      return convertIngredient(
        Ingredient(name: 'test', amount: amount, unit: unit),
        'metric',
        'us_customary',
      );
    }

    test('5 mL to tsp', () {
      final result = convert(5, 'mL');
      expect(result.amount, 1.0);
      expect(result.unit, 'tsp');
    });

    test('240 mL converts to cup', () {
      final result = convert(240, 'mL');
      expect(result.amount, 1.0);
      expect(result.unit, 'cup');
    });

    test('grams to oz', () {
      final result = convert(28, 'g');
      expect(result.amount, 1.0);
      expect(result.unit, 'oz');
    });

    test('kg to lb', () {
      final result = convert(1, 'kg');
      // 1000/454 ≈ 2.2 — should snap to 2.25 (2 1/4)
      expect(result.amount, closeTo(2.25, 0.05));
      expect(result.unit, 'lb');
    });

    test('keeps metric when the US conversion is not a clean cooking amount',
        () {
      final result = convert(100, 'mL');
      expect(result.unit, 'mL');
      expect(result.amount, 100.0);
    });
  });

  group('Identity units', () {
    test('pieces are not converted', () {
      final ing = Ingredient(name: 'eggs', amount: 3, unit: 'pieces');
      final result = convertIngredient(ing, 'us_customary', 'metric');
      expect(result.amount, 3.0);
      expect(result.unit, 'pieces');
    });

    test('pinch is not converted', () {
      final ing = Ingredient(name: 'salt', amount: 1, unit: 'pinch');
      final result = convertIngredient(ing, 'us_customary', 'metric');
      expect(result.amount, 1.0);
      expect(result.unit, 'pinch');
    });

    test('clove is not converted', () {
      final ing = Ingredient(name: 'garlic', amount: 2, unit: 'clove');
      final result = convertIngredient(ing, 'us_customary', 'metric');
      expect(result.amount, 2.0);
      expect(result.unit, 'clove');
    });

    test('empty unit is not converted', () {
      final ing = Ingredient(name: 'water', amount: 1, unit: '');
      final result = convertIngredient(ing, 'us_customary', 'metric');
      expect(result.amount, 1.0);
      expect(result.unit, '');
    });

    test('dash is not converted', () {
      final ing = Ingredient(name: 'pepper', amount: 1, unit: 'dash');
      final result = convertIngredient(ing, 'us_customary', 'metric');
      expect(result.amount, 1.0);
      expect(result.unit, 'dash');
    });

    test('can is not converted', () {
      final ing = Ingredient(name: 'tomatoes', amount: 2, unit: 'can');
      final result = convertIngredient(ing, 'us_customary', 'metric');
      expect(result.amount, 2.0);
      expect(result.unit, 'can');
    });
  });

  group('Edge cases', () {
    test('null amount returns ingredient unchanged', () {
      final ing = Ingredient(name: 'salt', unit: 'tsp');
      final result = convertIngredient(ing, 'us_customary', 'metric');
      expect(result.amount, isNull);
      expect(result.unit, 'tsp');
    });

    test('zero amount returns ingredient unchanged', () {
      final ing = Ingredient(name: 'salt', amount: 0, unit: 'tsp');
      final result = convertIngredient(ing, 'us_customary', 'metric');
      expect(result.amount, 0.0);
      expect(result.unit, 'tsp');
    });

    test('same system returns ingredient unchanged', () {
      final ing = Ingredient(name: 'flour', amount: 2, unit: 'cups');
      final result = convertIngredient(ing, 'us_customary', 'us_customary');
      expect(result.amount, 2.0);
      expect(result.unit, 'cups');
    });

    test('unknown unit returns ingredient unchanged', () {
      final ing = Ingredient(name: 'stuff', amount: 3, unit: 'scoops');
      final result = convertIngredient(ing, 'us_customary', 'metric');
      expect(result.amount, 3.0);
      expect(result.unit, 'scoops');
    });

    test('null unit returns ingredient unchanged', () {
      final ing = Ingredient(name: 'stuff', amount: 3);
      final result = convertIngredient(ing, 'us_customary', 'metric');
      expect(result.amount, 3.0);
      expect(result.unit, isNull);
    });
  });

  group('formatAmount', () {
    test('US fractions', () {
      expect(formatAmount(1.5, 'cup'), '1 1/2');
      expect(formatAmount(0.25, 'tsp'), '1/4');
      expect(formatAmount(0.333, 'cup'), '1/3');
      expect(formatAmount(0.667, 'cup'), '2/3');
      expect(formatAmount(0.75, 'tbsp'), '3/4');
      expect(formatAmount(2.0, 'cups'), '2');
    });

    test('metric clean decimals', () {
      expect(formatAmount(240.0, 'mL'), '240');
      expect(formatAmount(1.5, 'L'), '1.5');
      expect(formatAmount(500.0, 'g'), '500');
    });

    test('zero returns empty string', () {
      expect(formatAmount(0, 'cup'), '');
      expect(formatAmount(0, 'mL'), '');
    });

    test('whole numbers for US', () {
      expect(formatAmount(3.0, 'tbsp'), '3');
      expect(formatAmount(1.0, 'cup'), '1');
    });
  });

  group('formatAmountForUnit', () {
    test('null amount returns empty', () {
      expect(formatAmountForUnit(null, 'cup'), '');
    });

    test('zero amount returns empty', () {
      expect(formatAmountForUnit(0, 'cup'), '');
    });

    test('null unit defaults to fraction style', () {
      expect(formatAmountForUnit(1.5, null), '1 1/2');
    });
  });

  group('formatIngredientQuantityWithAlternate', () {
    test('keeps primary US measurement and adds metric alternate', () {
      final ing = Ingredient(
        name: 'flour',
        amount: 2,
        unit: 'cups',
        metricAmount: 240,
        metricUnit: 'g',
      );

      expect(
        formatIngredientQuantityWithAlternate(
          ing,
          recipeUnitSystem: 'us_customary',
          userUnitSystem: 'metric',
        ),
        '2 cups (240 g)',
      );
    });

    test('keeps primary metric measurement and adds clean US alternate', () {
      final ing = Ingredient(name: 'milk', amount: 240, unit: 'mL');

      expect(
        formatIngredientQuantityWithAlternate(
          ing,
          recipeUnitSystem: 'metric',
          userUnitSystem: 'us_customary',
        ),
        '240 mL (1 cup)',
      );
    });

    test('omits alternate when conversion is not useful', () {
      final ing = Ingredient(name: 'water', amount: 100, unit: 'mL');

      expect(
        formatIngredientQuantityWithAlternate(
          ing,
          recipeUnitSystem: 'metric',
          userUnitSystem: 'us_customary',
        ),
        '100 mL',
      );
    });
  });

  group('parseFractionalAmount', () {
    test('parses plain integers', () {
      expect(parseFractionalAmount('2'), 2.0);
      expect(parseFractionalAmount('10'), 10.0);
    });

    test('parses plain decimals', () {
      expect(parseFractionalAmount('1.5'), 1.5);
      expect(parseFractionalAmount('0.25'), 0.25);
    });

    test('parses simple fractions', () {
      expect(parseFractionalAmount('1/2'), 0.5);
      expect(parseFractionalAmount('1/4'), 0.25);
      expect(parseFractionalAmount('3/4'), 0.75);
      expect(parseFractionalAmount('2/3'), closeTo(0.667, 0.001));
    });

    test('parses mixed fractions', () {
      expect(parseFractionalAmount('1 1/2'), 1.5);
      expect(parseFractionalAmount('2 1/4'), 2.25);
      expect(parseFractionalAmount('3 3/4'), 3.75);
    });

    test('handles whitespace', () {
      expect(parseFractionalAmount('  1/2  '), 0.5);
      expect(parseFractionalAmount('  2  '), 2.0);
      expect(parseFractionalAmount('1  1/2'), 1.5);
    });

    test('returns null for empty string', () {
      expect(parseFractionalAmount(''), isNull);
      expect(parseFractionalAmount('  '), isNull);
    });

    test('returns null for non-numeric input', () {
      expect(parseFractionalAmount('abc'), isNull);
      expect(parseFractionalAmount('one half'), isNull);
    });

    test('returns null for division by zero', () {
      expect(parseFractionalAmount('1/0'), isNull);
    });
  });
}
