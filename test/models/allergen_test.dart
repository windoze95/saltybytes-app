import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:saltybytes_app/models/allergen.dart';

import '../helpers/fixtures.dart';

void main() {
  group('AllergenAnalysis', () {
    test('fromJson with full data', () {
      final json = testAllergenAnalysisJson();
      final analysis = AllergenAnalysis.fromJson(json);

      expect(analysis.recipeId, 'recipe-abc-123');
      expect(analysis.detectedAllergens, hasLength(2));
      expect(analysis.possibleAllergens, hasLength(1));
      expect(analysis.familySafetyChecks, hasLength(1));
      expect(analysis.isSafeForAll, false);
      expect(analysis.analyzedAt, isA<DateTime>());
    });

    test('fromJson with empty lists', () {
      final json = <String, dynamic>{
        'recipeId': 'r-safe',
        'detectedAllergens': <dynamic>[],
        'possibleAllergens': <dynamic>[],
        'familySafetyChecks': <dynamic>[],
        'isSafeForAll': true,
      };
      final analysis = AllergenAnalysis.fromJson(json);

      expect(analysis.recipeId, 'r-safe');
      expect(analysis.detectedAllergens, isEmpty);
      expect(analysis.possibleAllergens, isEmpty);
      expect(analysis.familySafetyChecks, isEmpty);
      expect(analysis.isSafeForAll, true);
      expect(analysis.analyzedAt, isNull);
    });

    test('fromJson with null lists defaults to empty', () {
      final json = <String, dynamic>{
        'recipeId': 'r-1',
      };
      final analysis = AllergenAnalysis.fromJson(json);

      expect(analysis.detectedAllergens, isEmpty);
      expect(analysis.possibleAllergens, isEmpty);
      expect(analysis.familySafetyChecks, isEmpty);
      expect(analysis.isSafeForAll, false);
    });
  });

  group('AllergenInfo', () {
    test('fromJson with all fields', () {
      final json = testAllergenInfoJson(
        allergen: 'dairy',
        severity: 'moderate',
        source: 'cream cheese',
        ingredient: 'cream cheese frosting',
        notes: 'Contains lactose',
      );
      final info = AllergenInfo.fromJson(json);

      expect(info.allergen, 'dairy');
      expect(info.severity, 'moderate');
      expect(info.source, 'cream cheese');
      expect(info.ingredient, 'cream cheese frosting');
      expect(info.notes, 'Contains lactose');
    });

    test('fromJson with only required fields', () {
      final json = <String, dynamic>{
        'allergen': 'shellfish',
        'severity': 'high',
        'source': 'shrimp',
      };
      final info = AllergenInfo.fromJson(json);

      expect(info.allergen, 'shellfish');
      expect(info.ingredient, isNull);
      expect(info.notes, isNull);
    });

    test('round-trip toJson/fromJson', () {
      final original = AllergenInfo.fromJson(testAllergenInfoJson());
      final jsonString = jsonEncode(original.toJson());
      final roundTripped = AllergenInfo.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

      expect(roundTripped.allergen, original.allergen);
      expect(roundTripped.severity, original.severity);
      expect(roundTripped.source, original.source);
      expect(roundTripped.ingredient, original.ingredient);
      expect(roundTripped.notes, original.notes);
    });
  });

  group('FamilySafetyCheck', () {
    test('fromJson with conflicts and warnings', () {
      final json = testFamilySafetyCheckJson(
        memberId: 'member-002',
        memberName: 'Sarah',
        isSafe: false,
        conflicts: ['Contains dairy - Sarah is lactose intolerant'],
        warnings: ['Cross-contamination risk'],
      );
      final check = FamilySafetyCheck.fromJson(json);

      expect(check.memberId, 'member-002');
      expect(check.memberName, 'Sarah');
      expect(check.isSafe, false);
      expect(check.conflicts, hasLength(1));
      expect(check.conflicts[0], contains('dairy'));
      expect(check.warnings, hasLength(1));
    });

    test('fromJson with empty conflicts defaults to empty lists', () {
      final json = <String, dynamic>{
        'memberId': 'member-003',
        'memberName': 'Alex',
        'isSafe': true,
      };
      final check = FamilySafetyCheck.fromJson(json);

      expect(check.isSafe, true);
      expect(check.conflicts, isEmpty);
      expect(check.warnings, isEmpty);
    });

    test('round-trip toJson/fromJson', () {
      final original = FamilySafetyCheck.fromJson(testFamilySafetyCheckJson());
      final jsonString = jsonEncode(original.toJson());
      final roundTripped = FamilySafetyCheck.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

      expect(roundTripped.memberId, original.memberId);
      expect(roundTripped.memberName, original.memberName);
      expect(roundTripped.isSafe, original.isSafe);
      expect(roundTripped.conflicts, original.conflicts);
      expect(roundTripped.warnings, original.warnings);
    });
  });
}
