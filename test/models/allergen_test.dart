import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:saltybytes_app/core/providers/allergen_provider.dart';
import 'package:saltybytes_app/models/allergen.dart';

import '../helpers/fixtures.dart';

void main() {
  group('AllergenAnalysis', () {
    test('fromJson with full snake_case backend payload', () {
      final json = testAllergenAnalysisJson();
      final analysis = AllergenAnalysis.fromJson(json);

      expect(analysis.recipeId, '7');
      expect(analysis.ingredientAnalyses, hasLength(2));
      expect(analysis.containsDairy, true);
      expect(analysis.containsGluten, true);
      expect(analysis.containsNuts, false);
      expect(analysis.safeForProfiles, ['2']);
      expect(analysis.unsafeForProfiles, ['1']);
      expect(analysis.confidence, 0.92);
      expect(analysis.requiresReview, false);
      expect(analysis.disclaimer, contains('medical advice'));
      expect(analysis.analyzedAt, isA<DateTime>());
    });

    test('normalizes int and String IDs', () {
      final fromInt = AllergenAnalysis.fromJson(
        testAllergenAnalysisJson(recipeId: 7, unsafeForProfiles: [1, 2]),
      );
      final fromString = AllergenAnalysis.fromJson(
        testAllergenAnalysisJson(recipeId: '7', unsafeForProfiles: ['1', '2']),
      );

      expect(fromInt.recipeId, fromString.recipeId);
      expect(fromInt.unsafeForProfiles, fromString.unsafeForProfiles);
    });

    test('detectedAllergens derives labels from contains_* flags', () {
      final analysis = AllergenAnalysis.fromJson(testAllergenAnalysisJson(
        containsNuts: true,
        containsDairy: true,
        containsGluten: false,
        containsSeedOils: true,
      ));

      expect(analysis.detectedAllergens, ['Nuts', 'Dairy', 'Seed Oils']);
      expect(analysis.hasDetectedAllergens, true);
    });

    test('hasUnsafeMembers reflects unsafe_for_profiles', () {
      final unsafe = AllergenAnalysis.fromJson(
        testAllergenAnalysisJson(unsafeForProfiles: [1]),
      );
      final safe = AllergenAnalysis.fromJson(
        testAllergenAnalysisJson(unsafeForProfiles: []),
      );

      expect(unsafe.hasUnsafeMembers, true);
      expect(safe.hasUnsafeMembers, false);
    });

    test('fromJson tolerates null jsonb lists and missing keys', () {
      final analysis = AllergenAnalysis.fromJson(<String, dynamic>{
        'recipe_id': 3,
        'ingredient_analyses': null,
        'safe_for_profiles': null,
        'unsafe_for_profiles': null,
      });

      expect(analysis.recipeId, '3');
      expect(analysis.ingredientAnalyses, isEmpty);
      expect(analysis.safeForProfiles, isEmpty);
      expect(analysis.unsafeForProfiles, isEmpty);
      expect(analysis.detectedAllergens, isEmpty);
      expect(analysis.analyzedAt, isNull);
    });

    test('parseAnalysisEnvelope unwraps {"analysis": ...}', () {
      final envelope = <String, dynamic>{
        'analysis': testAllergenAnalysisJson(recipeId: 11),
      };
      final analysis = parseAnalysisEnvelope(envelope);

      expect(analysis.recipeId, '11');
      expect(analysis.containsDairy, true);
    });

    test('parseAnalysisEnvelope falls back to bare object', () {
      final analysis =
          parseAnalysisEnvelope(testAllergenAnalysisJson(recipeId: 12));

      expect(analysis.recipeId, '12');
    });
  });

  group('IngredientAnalysis', () {
    test('fromJson with all fields', () {
      final json = testIngredientAnalysisJson(
        ingredientName: 'soy sauce',
        commonAllergens: ['soy', 'gluten'],
        possibleAllergens: ['wheat'],
        subIngredients: ['soybeans', 'wheat'],
        seedOilRisk: true,
        confidence: 0.85,
      );
      final ia = IngredientAnalysis.fromJson(json);

      expect(ia.ingredientName, 'soy sauce');
      expect(ia.commonAllergens, ['soy', 'gluten']);
      expect(ia.possibleAllergens, ['wheat']);
      expect(ia.subIngredients, ['soybeans', 'wheat']);
      expect(ia.seedOilRisk, true);
      expect(ia.confidence, 0.85);
    });

    test('fromJson with null lists defaults to empty', () {
      final ia = IngredientAnalysis.fromJson(<String, dynamic>{
        'ingredient_name': 'salt',
        'common_allergens': null,
        'possible_allergens': null,
        'sub_ingredients': null,
      });

      expect(ia.ingredientName, 'salt');
      expect(ia.commonAllergens, isEmpty);
      expect(ia.possibleAllergens, isEmpty);
      expect(ia.subIngredients, isEmpty);
      expect(ia.seedOilRisk, false);
    });

    test('round-trip toJson/fromJson', () {
      final original =
          IngredientAnalysis.fromJson(testIngredientAnalysisJson());
      final jsonString = jsonEncode(original.toJson());
      final roundTripped = IngredientAnalysis.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>);

      expect(roundTripped, original);
    });
  });

  group('FamilySafetyCheck', () {
    test('fromJson with snake_case keys', () {
      final json = testFamilySafetyCheckJson(
        memberId: 2,
        memberName: 'Sarah',
        status: 'unsafe',
        warnings: ['Contains dairy - Sarah is lactose intolerant'],
      );
      final check = FamilySafetyCheck.fromJson(json);

      expect(check.memberId, '2');
      expect(check.memberName, 'Sarah');
      expect(check.status, 'unsafe');
      expect(check.isSafe, false);
      expect(check.warnings, hasLength(1));
      expect(check.warnings[0], contains('dairy'));
    });

    test('isSafe is true only for safe status', () {
      expect(
        FamilySafetyCheck.fromJson(testFamilySafetyCheckJson(status: 'safe'))
            .isSafe,
        true,
      );
      expect(
        FamilySafetyCheck.fromJson(testFamilySafetyCheckJson(status: 'caution'))
            .isSafe,
        false,
      );
    });

    test('fromJson with missing keys uses defaults', () {
      final check = FamilySafetyCheck.fromJson(<String, dynamic>{});

      expect(check.memberId, '');
      expect(check.memberName, '');
      expect(check.status, 'safe');
      expect(check.warnings, isEmpty);
    });
  });
}
