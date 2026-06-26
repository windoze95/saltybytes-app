import '../../models/recipe.dart';

/// Deterministic cooking unit handling — the Dart mirror of the Go reference in
/// saltybytes-api `internal/units`. All conversion is offline and exact
/// same-dimension by default (mass<->mass, volume<->volume). Crossing
/// dimensions (volume<->mass) only ever happens US->metric, via the
/// AI-provided density-aware metric pair; metric->US renders an exact
/// same-dimension unit (g->oz/lb, mL->cup), so there is no density table to
/// drift. Both ports are pinned by the same golden vectors.

// Measure kinds. Count/imprecise are never converted.
const kindMass = 'mass';
const kindVolume = 'volume';
const kindCount = 'count';
const kindImprecise = 'imprecise';

// Measurement systems (match the API's RecipeDef.unit_system values).
const sysUS = 'us_customary';
const sysMetric = 'metric';

class _UnitMeta {
  final String dim;
  final String system;
  final double
      factor; // amount * factor = base magnitude (g for mass, mL for volume)
  const _UnitMeta(this.dim, this.system, this.factor);
}

const _meta = <String, _UnitMeta>{
  // US customary volume (base mL)
  'tsp': _UnitMeta(kindVolume, sysUS, 4.92892),
  'tbsp': _UnitMeta(kindVolume, sysUS, 14.7868),
  'fl oz': _UnitMeta(kindVolume, sysUS, 29.5735),
  'cup': _UnitMeta(kindVolume, sysUS, 236.588),
  'pt': _UnitMeta(kindVolume, sysUS, 473.176),
  'qt': _UnitMeta(kindVolume, sysUS, 946.353),
  'gal': _UnitMeta(kindVolume, sysUS, 3785.41),
  // US customary mass (base g)
  'oz': _UnitMeta(kindMass, sysUS, 28.3495),
  'lb': _UnitMeta(kindMass, sysUS, 453.592),
  // metric volume (base mL)
  'mL': _UnitMeta(kindVolume, sysMetric, 1),
  'L': _UnitMeta(kindVolume, sysMetric, 1000),
  // metric mass (base g)
  'mg': _UnitMeta(kindMass, sysMetric, 0.001),
  'g': _UnitMeta(kindMass, sysMetric, 1),
  'kg': _UnitMeta(kindMass, sysMetric, 1000),
};

const _aliases = <String, String>{
  'tsp': 'tsp',
  'tsps': 'tsp',
  'teaspoon': 'tsp',
  'teaspoons': 'tsp',
  'tbsp': 'tbsp',
  'tbsps': 'tbsp',
  'tbs': 'tbsp',
  'tbl': 'tbsp',
  'tablespoon': 'tbsp',
  'tablespoons': 'tbsp',
  'cup': 'cup',
  'cups': 'cup',
  'c': 'cup',
  'pt': 'pt',
  'pts': 'pt',
  'pint': 'pt',
  'pints': 'pt',
  'qt': 'qt',
  'qts': 'qt',
  'quart': 'qt',
  'quarts': 'qt',
  'gal': 'gal',
  'gals': 'gal',
  'gallon': 'gal',
  'gallons': 'gal',
  'floz': 'fl oz',
  'fl oz': 'fl oz',
  'fluid ounce': 'fl oz',
  'fluid ounces': 'fl oz',
  'oz': 'oz',
  'ozs': 'oz',
  'ounce': 'oz',
  'ounces': 'oz',
  'lb': 'lb',
  'lbs': 'lb',
  'pound': 'lb',
  'pounds': 'lb',
  'ml': 'mL',
  'mls': 'mL',
  'milliliter': 'mL',
  'milliliters': 'mL',
  'millilitre': 'mL',
  'millilitres': 'mL',
  'cc': 'mL',
  'l': 'L',
  'liter': 'L',
  'liters': 'L',
  'litre': 'L',
  'litres': 'L',
  'mg': 'mg',
  'mgs': 'mg',
  'milligram': 'mg',
  'milligrams': 'mg',
  'g': 'g',
  'gram': 'g',
  'grams': 'g',
  'gr': 'g',
  'kg': 'kg',
  'kgs': 'kg',
  'kilogram': 'kg',
  'kilograms': 'kg',
  'kilo': 'kg',
  'kilos': 'kg',
  'pinch': 'pinch',
  'pinches': 'pinch',
  'dash': 'dash',
  'dashes': 'dash',
  'drop': 'drop',
  'drops': 'drop',
  'bushel': 'bushel',
  'bushels': 'bushel',
  'piece': 'pieces',
  'pieces': 'pieces',
  'pc': 'pieces',
  'pcs': 'pieces',
  'clove': 'pieces',
  'cloves': 'pieces',
  'can': 'pieces',
  'cans': 'pieces',
  'slice': 'pieces',
  'slices': 'pieces',
  'stick': 'pieces',
  'sticks': 'pieces',
  'stalk': 'pieces',
  'stalks': 'pieces',
  'sprig': 'pieces',
  'sprigs': 'pieces',
  'head': 'pieces',
  'heads': 'pieces',
  'bunch': 'pieces',
  'bunches': 'pieces',
  'package': 'pieces',
  'packages': 'pieces',
  'pkg': 'pieces',
  'pkgs': 'pieces',
  'ear': 'pieces',
  'ears': 'pieces',
  'fillet': 'pieces',
  'fillets': 'pieces',
};

const _liquidNames = [
  'water',
  'milk',
  'stock',
  'broth',
  'wine',
  'juice',
  'oil',
  'vinegar',
  'beer',
  'coffee',
  'tea',
  'buttermilk',
  'liqueur',
  'rum',
  'vodka',
  'whiskey',
  'brandy',
  'soda',
];

String? canonicalUnit(String? token) {
  if (token == null) return null;
  final t = token.trim().toLowerCase();
  if (t.isEmpty) return null;
  return _aliases[t];
}

String _canon(String unit) {
  if (_meta.containsKey(unit)) return unit;
  return canonicalUnit(unit) ?? unit;
}

bool _isLiquidName(String name) {
  final n = name.toLowerCase();
  return _liquidNames.any(n.contains);
}

String dimensionOf(String? unit) => _meta[_canon(unit ?? '')]?.dim ?? '';

String systemOf(String? unit) => _meta[_canon(unit ?? '')]?.system ?? '';

/// Classify an ingredient measurement. name/metricUnit disambiguate "oz"
/// (weight vs fluid ounce).
String measureKind(String? unit, String name, String? metricUnit) {
  final u = _canon(unit ?? '');
  if (u == 'oz') {
    switch (dimensionOf(metricUnit)) {
      case kindVolume:
        return kindVolume;
      case kindMass:
        return kindMass;
    }
    return _isLiquidName(name) ? kindVolume : kindMass;
  }
  final m = _meta[u];
  if (m != null) return m.dim;
  if (u == 'pieces') return kindCount;
  return kindImprecise;
}

/// Base magnitude in the ingredient's own dimension (g for mass, mL for
/// volume, the amount for count, 0 for imprecise).
double baseAmount(double amount, String? unit, String kind) {
  final u = _canon(unit ?? '');
  if (kind == kindCount) return amount;
  if (kind == kindImprecise) return 0;
  if (u == 'oz' && kind == kindVolume) return amount * _meta['fl oz']!.factor;
  final m = _meta[u];
  if (m != null) return amount * m.factor;
  return 0;
}

String _ingredientKind(Ingredient ing) {
  final k = ing.measureKind;
  if (k != null && k.isNotEmpty) return k;
  return measureKind(ing.unit, ing.name, ing.metricUnit);
}

double _ingredientBase(Ingredient ing) {
  final b = ing.baseAmount;
  if (b != null && b > 0) return b;
  return baseAmount(ing.amount ?? 0, ing.unit, _ingredientKind(ing));
}

/// Convert an ingredient into the viewer's system, returning the alternate
/// amount/unit, or null when no useful conversion exists (count/imprecise, or
/// already in the viewer's system).
({double amount, String unit})? convertToViewer(Ingredient ing, String viewer) {
  final kind = _ingredientKind(ing);
  if (kind == kindCount || kind == kindImprecise || kind.isEmpty) return null;
  final amount = ing.amount;
  if (amount == null || amount <= 0) return null;
  final src = systemOf(ing.unit ?? '');
  if (src.isEmpty || src == viewer) return null;
  final base = _ingredientBase(ing);
  if (base <= 0) return null;

  // US -> metric may cross dimensions via the density-aware AI metric pair.
  if (viewer == sysMetric && src == sysUS) {
    final mu = ing.metricUnit, ma = ing.metricAmount;
    if (mu != null && mu.isNotEmpty && ma != null && ma > 0) {
      return (amount: ma, unit: _canon(mu));
    }
  }

  final r = expressInSystem(base, kind, viewer);
  if (r == null || r.amount <= 0) return null;
  return r;
}

/// Pick a cooking-friendly unit and amount for a base magnitude in the given
/// system and dimension.
({double amount, String unit})? expressInSystem(
    double base, String kind, String system) {
  if (kind == kindMass) {
    return system == sysMetric ? _metricMass(base) : _usMass(base);
  }
  if (kind == kindVolume) {
    return system == sysMetric ? _metricVolume(base) : _usVolume(base);
  }
  return null;
}

// --- system-specific unit selection (mirrors Go) ---------------------------

({double amount, String unit}) _usVolume(double ml) {
  if (ml < _meta['tbsp']!.factor) {
    return (
      amount: _snapCookingFraction(ml / _meta['tsp']!.factor),
      unit: 'tsp'
    );
  }
  if (ml < 0.25 * _meta['cup']!.factor) {
    return (
      amount: _snapCookingFraction(ml / _meta['tbsp']!.factor),
      unit: 'tbsp'
    );
  }
  if (ml < 4.5 * _meta['cup']!.factor) {
    return (
      amount: _snapCookingFraction(ml / _meta['cup']!.factor),
      unit: 'cup'
    );
  }
  if (ml < 4 * _meta['qt']!.factor) {
    return (amount: _snapCookingFraction(ml / _meta['qt']!.factor), unit: 'qt');
  }
  return (amount: _round1(ml / _meta['gal']!.factor), unit: 'gal');
}

({double amount, String unit}) _usMass(double g) {
  if (g >= _meta['lb']!.factor) {
    return (amount: _round1(g / _meta['lb']!.factor), unit: 'lb');
  }
  return (amount: _round1(g / _meta['oz']!.factor), unit: 'oz');
}

({double amount, String unit}) _metricVolume(double ml) {
  if (ml >= 1000) return (amount: _round2(ml / 1000), unit: 'L');
  return (amount: _roundMetricSmall(ml), unit: 'mL');
}

({double amount, String unit}) _metricMass(double g) {
  if (g >= 1000) return (amount: _round2(g / 1000), unit: 'kg');
  return (amount: _roundMetricSmall(g), unit: 'g');
}

// --- rounding / snapping ----------------------------------------------------

const _cookingFractions = <double>[
  0,
  1 / 8,
  1 / 6,
  1 / 4,
  1 / 3,
  3 / 8,
  1 / 2,
  5 / 8,
  2 / 3,
  3 / 4,
  5 / 6,
  7 / 8,
  1,
];

double _snapCookingFraction(double x) {
  if (x <= 0) return 0;
  final whole = x.floorToDouble();
  final frac = x - whole;
  var best = 0.0;
  var bestDist = double.maxFinite;
  for (final f in _cookingFractions) {
    final d = (frac - f).abs();
    if (d < bestDist) {
      bestDist = d;
      best = f;
    }
  }
  return whole + best;
}

double _round1(double x) => (x * 10).round() / 10;
double _round2(double x) => (x * 100).round() / 100;

double _roundMetricSmall(double x) {
  if (x >= 100) return (x / 5).round() * 5;
  if (x >= 10) return x.roundToDouble();
  return _round1(x);
}

// --- formatting -------------------------------------------------------------

/// Format a numeric amount: cooking fractions for US volume units, plain
/// decimals for metric and weights.
String formatAmount(double amount, String unit) {
  if (amount == 0) return '';
  final c = _canon(unit);
  final useDecimal = systemOf(c) == sysMetric ||
      (systemOf(c) == sysUS && dimensionOf(c) == kindMass);
  return useDecimal ? _formatDecimal(amount) : _formatUsFraction(amount);
}

String _formatDecimal(double amount) {
  if (amount == amount.roundToDouble()) return amount.toInt().toString();
  final s = amount.toStringAsFixed(1);
  if (s.endsWith('.0')) return amount.toInt().toString();
  return s;
}

String _formatUsFraction(double amount) {
  if (amount == amount.roundToDouble()) return amount.toInt().toString();

  final whole = amount.floor();
  final frac = amount - whole;

  const fractionLabels = [
    (1 / 8, '1/8'),
    (1 / 6, '1/6'),
    (1 / 4, '1/4'),
    (1 / 3, '1/3'),
    (3 / 8, '3/8'),
    (1 / 2, '1/2'),
    (5 / 8, '5/8'),
    (2 / 3, '2/3'),
    (3 / 4, '3/4'),
    (5 / 6, '5/6'),
    (7 / 8, '7/8'),
  ];

  for (final (target, label) in fractionLabels) {
    if ((frac - target).abs() < 0.04) {
      return whole > 0 ? '$whole $label' : label;
    }
  }
  return _formatDecimal(amount);
}

/// Format an amount for display, auto-detecting fraction style from the unit.
String formatAmountForUnit(double? amount, String? unit) {
  if (amount == null || amount == 0) return '';
  return formatAmount(amount, unit ?? '');
}

String _qtyString(double? amount, String? unit, {double? high}) {
  if (amount == null || amount <= 0) return '';
  final a = formatAmount(amount, unit ?? '');
  if (a.isEmpty) return '';
  final hi = (high != null && high > amount)
      ? '-${formatAmount(high, unit ?? '')}'
      : '';
  final u = (unit != null && unit.isNotEmpty) ? ' $unit' : '';
  return '$a$hi$u';
}

/// Format an ingredient quantity (amount + unit, with range), no name.
String formatIngredientQuantity(Ingredient ingredient) {
  final parts = <String>[];
  final qty = _qtyString(ingredient.amount, ingredient.unit,
      high: ingredient.amountHigh);
  if (qty.isNotEmpty) {
    parts.add(qty);
  } else if (ingredient.unit != null && ingredient.unit!.isNotEmpty) {
    parts.add(ingredient.unit!);
  }
  return parts.join(' ');
}

/// Format the stored (source) quantity first, appending the viewer's
/// preferred-system equivalent in parentheses when a useful, per-ingredient
/// conversion exists. recipeUnitSystem is retained for call-site compatibility;
/// the source system is now derived per ingredient from its own unit.
String formatIngredientQuantityWithAlternate(
  Ingredient ingredient, {
  required String recipeUnitSystem,
  required String userUnitSystem,
}) {
  final primary = formatIngredientQuantity(ingredient);
  if (primary.isEmpty) return primary;

  final alt = convertToViewer(ingredient, userUnitSystem);
  if (alt == null) return primary;

  final alternate = _qtyString(alt.amount, alt.unit);
  if (alternate.isEmpty || alternate == primary) return primary;

  return '$primary ($alternate)';
}

/// Parse a fractional string like "1/2", "1 1/2", "1,5" (European decimal), or
/// a plain number. Returns null if the input cannot be parsed.
double? parseFractionalAmount(String input) {
  var s = input.trim();
  if (s.isEmpty) return null;
  s = _normalizeDecimal(s);

  final plain = double.tryParse(s);
  if (plain != null) return plain;

  final fractionMatch = RegExp(r'^(\d+)\s*/\s*(\d+)$').firstMatch(s);
  if (fractionMatch != null) {
    final num = int.parse(fractionMatch.group(1)!);
    final den = int.parse(fractionMatch.group(2)!);
    if (den == 0) return null;
    return num / den;
  }

  final mixedMatch = RegExp(r'^(\d+)\s+(\d+)\s*/\s*(\d+)$').firstMatch(s);
  if (mixedMatch != null) {
    final whole = int.parse(mixedMatch.group(1)!);
    final num = int.parse(mixedMatch.group(2)!);
    final den = int.parse(mixedMatch.group(3)!);
    if (den == 0) return null;
    return whole + num / den;
  }

  return null;
}

/// Fold a European decimal comma ("1,5" -> "1.5") or thousands grouping
/// ("1,000" -> "1000") into a plain parseable number.
String _normalizeDecimal(String tok) {
  if (','.allMatches(tok).length != 1 || tok.contains('.')) return tok;
  final i = tok.indexOf(',');
  final intPart = tok.substring(0, i);
  final fracPart = tok.substring(i + 1);
  final digits = RegExp(r'^\d+$');
  if (!digits.hasMatch(intPart) || !digits.hasMatch(fracPart)) return tok;
  return fracPart.length == 3 ? '$intPart$fracPart' : '$intPart.$fracPart';
}
