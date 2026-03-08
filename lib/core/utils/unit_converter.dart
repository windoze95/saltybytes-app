import '../../models/recipe.dart';

/// Deterministic cooking unit conversion utility.
///
/// Converts between US customary and metric units with cooking-friendly
/// smart rounding. All conversions are deterministic (no AI involved).

const _identityUnits = {
  'pieces', 'piece', 'pinch', 'dash', 'drop', 'clove', 'cloves',
  'slice', 'slices', 'bunch', 'sprig', 'sprigs', 'can', 'cans',
  'head', 'heads', 'stalk', 'stalks', 'leaf', 'leaves',
  'whole', 'to taste', 'as needed', '',
};

// US → Metric conversion table: (factor, metricUnit, roundTo)
const _usToMetric = <String, (double, String, double)>{
  'tsp': (5.0, 'mL', 0.5),
  'teaspoon': (5.0, 'mL', 0.5),
  'teaspoons': (5.0, 'mL', 0.5),
  'tbsp': (15.0, 'mL', 5.0),
  'tablespoon': (15.0, 'mL', 5.0),
  'tablespoons': (15.0, 'mL', 5.0),
  'fl oz': (30.0, 'mL', 5.0),
  'fluid ounce': (30.0, 'mL', 5.0),
  'fluid ounces': (30.0, 'mL', 5.0),
  'cup': (240.0, 'mL', 10.0),
  'cups': (240.0, 'mL', 10.0),
  'pt': (475.0, 'mL', 25.0),
  'pint': (475.0, 'mL', 25.0),
  'pints': (475.0, 'mL', 25.0),
  'qt': (0.95, 'L', 0.1),
  'quart': (0.95, 'L', 0.1),
  'quarts': (0.95, 'L', 0.1),
  'gal': (3.8, 'L', 0.5),
  'gallon': (3.8, 'L', 0.5),
  'gallons': (3.8, 'L', 0.5),
  'oz': (28.0, 'g', 5.0),
  'ounce': (28.0, 'g', 5.0),
  'ounces': (28.0, 'g', 5.0),
  'lb': (454.0, 'g', 10.0),
  'pound': (454.0, 'g', 10.0),
  'pounds': (454.0, 'g', 10.0),
};

// Metric → US conversion table: (factor, usUnit, common fractions to snap to)
const _metricToUs = <String, (double, String)>{
  'ml': (1 / 5, 'tsp'),
  'mL': (1 / 5, 'tsp'),
  'milliliter': (1 / 5, 'tsp'),
  'milliliters': (1 / 5, 'tsp'),
  'millilitre': (1 / 5, 'tsp'),
  'millilitres': (1 / 5, 'tsp'),
  'l': (1 / 0.95, 'qt'),
  'L': (1 / 0.95, 'qt'),
  'liter': (1 / 0.95, 'qt'),
  'liters': (1 / 0.95, 'qt'),
  'litre': (1 / 0.95, 'qt'),
  'litres': (1 / 0.95, 'qt'),
  'g': (1 / 28, 'oz'),
  'gram': (1 / 28, 'oz'),
  'grams': (1 / 28, 'oz'),
  'kg': (1000 / 454, 'lb'),
  'kilogram': (1000 / 454, 'lb'),
  'kilograms': (1000 / 454, 'lb'),
};

// Common cooking fractions for US unit snapping
const _commonFractions = [
  (1, 4),  // 0.25
  (1, 3),  // 0.333
  (1, 2),  // 0.5
  (2, 3),  // 0.667
  (3, 4),  // 0.75
];

bool needsConversion(String recipeSystem, String userSystem) {
  return recipeSystem != userSystem;
}

Ingredient convertIngredient(
  Ingredient ing,
  String fromSystem,
  String toSystem,
) {
  if (fromSystem == toSystem) return ing;
  if (ing.amount == null || ing.amount == 0) return ing;

  final unit = ing.unit?.trim() ?? '';
  final unitLower = unit.toLowerCase();

  // Identity units: no conversion
  if (_identityUnits.contains(unitLower) || unit.isEmpty) return ing;

  // Converting TO metric: use AI-provided metric data if available
  if (toSystem == 'metric' &&
      ing.metricUnit != null && ing.metricUnit!.isNotEmpty &&
      ing.metricAmount != null && ing.metricAmount! > 0) {
    return ing.copyWith(amount: ing.metricAmount, unit: ing.metricUnit);
  }

  // Fallback: legacy client-side conversion
  if (fromSystem == 'us_customary' && toSystem == 'metric') {
    return _convertUsToMetric(ing, unit);
  } else if (fromSystem == 'metric' && toSystem == 'us_customary') {
    return _convertMetricToUs(ing, unit);
  }

  return ing;
}

Ingredient _convertUsToMetric(Ingredient ing, String unit) {
  final entry = _usToMetric[unit] ?? _usToMetric[unit.toLowerCase()];
  if (entry == null) return ing;

  final (factor, metricUnit, roundTo) = entry;
  var converted = ing.amount! * factor;
  converted = _roundTo(converted, roundTo);

  // Auto-scale: mL → L, g → kg
  var finalUnit = metricUnit;
  if (metricUnit == 'mL' && converted >= 1000) {
    converted = _roundTo(converted / 1000, 0.1);
    finalUnit = 'L';
  } else if (metricUnit == 'g' && converted >= 1000) {
    converted = _roundTo(converted / 1000, 0.1);
    finalUnit = 'kg';
  }

  return ing.copyWith(amount: converted, unit: finalUnit);
}

Ingredient _convertMetricToUs(Ingredient ing, String unit) {
  final entry = _metricToUs[unit] ?? _metricToUs[unit.toLowerCase()];
  if (entry == null) return ing;

  final (factor, usUnit) = entry;
  final converted = ing.amount! * factor;

  // Try to snap to a clean fraction
  final snapped = _snapToFraction(converted);
  if (snapped != null) {
    return ing.copyWith(amount: snapped, unit: usUnit);
  }

  // If the result is ugly, keep it in the original metric unit
  return ing;
}

double? _snapToFraction(double value) {
  // Check if it's close to a whole number
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.05 && rounded > 0) {
    return rounded;
  }

  final whole = value.floor();
  final frac = value - whole;

  for (final (num, den) in _commonFractions) {
    final target = num / den;
    if ((frac - target).abs() < 0.05) {
      return whole + target;
    }
  }

  // Also check whole + fraction combinations
  if (whole > 0) {
    if (frac < 0.05) return whole.toDouble();
  }

  return null; // ugly fraction
}

double _roundTo(double value, double step) {
  return (value / step).round() * step;
}

/// Format a numeric amount for display.
///
/// For US units: produces cooking fractions like "1 1/2"
/// For metric units: clean decimals
String formatAmount(double amount, String unit) {
  if (amount == 0) return '';

  final unitLower = unit.toLowerCase();
  final isMetric = unitLower == 'ml' || unitLower == 'l' ||
      unitLower == 'g' || unitLower == 'kg' ||
      unitLower == 'milliliter' || unitLower == 'milliliters' ||
      unitLower == 'liter' || unitLower == 'liters' ||
      unitLower == 'gram' || unitLower == 'grams' ||
      unitLower == 'kilogram' || unitLower == 'kilograms';

  if (isMetric) {
    return _formatMetricAmount(amount);
  }
  return _formatUsFraction(amount);
}

String _formatMetricAmount(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toInt().toString();
  }
  // One decimal place for metric
  final s = amount.toStringAsFixed(1);
  // Remove trailing zero after decimal only if it's .0
  if (s.endsWith('.0')) return amount.toInt().toString();
  return s;
}

String _formatUsFraction(double amount) {
  if (amount == amount.roundToDouble() && amount == amount.toInt().toDouble()) {
    return amount.toInt().toString();
  }

  final whole = amount.floor();
  final frac = amount - whole;

  const fractionLabels = [
    (0.25, '1/4'),
    (0.333, '1/3'),
    (0.5, '1/2'),
    (0.667, '2/3'),
    (0.75, '3/4'),
  ];

  for (final (target, label) in fractionLabels) {
    if ((frac - target).abs() < 0.05) {
      if (whole > 0) {
        return '$whole $label';
      }
      return label;
    }
  }

  // Fallback: clean decimal
  return _formatMetricAmount(amount);
}

/// Format an amount for display, auto-detecting fraction style from the unit.
String formatAmountForUnit(double? amount, String? unit) {
  if (amount == null || amount == 0) return '';
  return formatAmount(amount, unit ?? '');
}

/// Parse a fractional string like "1/2", "1 1/2", or a plain number.
///
/// Returns null if the input cannot be parsed.
double? parseFractionalAmount(String input) {
  final s = input.trim();
  if (s.isEmpty) return null;

  // Try plain number first
  final plain = double.tryParse(s);
  if (plain != null) return plain;

  // Try "a/b" (simple fraction)
  final fractionMatch = RegExp(r'^(\d+)\s*/\s*(\d+)$').firstMatch(s);
  if (fractionMatch != null) {
    final num = int.parse(fractionMatch.group(1)!);
    final den = int.parse(fractionMatch.group(2)!);
    if (den == 0) return null;
    return num / den;
  }

  // Try "whole a/b" (mixed fraction)
  final mixedMatch =
      RegExp(r'^(\d+)\s+(\d+)\s*/\s*(\d+)$').firstMatch(s);
  if (mixedMatch != null) {
    final whole = int.parse(mixedMatch.group(1)!);
    final num = int.parse(mixedMatch.group(2)!);
    final den = int.parse(mixedMatch.group(3)!);
    if (den == 0) return null;
    return whole + num / den;
  }

  return null;
}
