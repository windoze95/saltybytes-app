import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:saltybytes_app/models/family.dart';

import '../helpers/fixtures.dart';

void main() {
  group('Family', () {
    test('fromJson with snake_case backend payload', () {
      final family = Family.fromJson(testFamilyJson());

      expect(family.id, '1');
      expect(family.name, 'The Smiths');
      expect(family.ownerId, '99');
      expect(family.members, hasLength(2));
      expect(family.createdAt, isA<DateTime>());
    });

    test('normalizes int and String IDs to the same value', () {
      final fromInt = Family.fromJson(testFamilyJson(id: 5, ownerId: 9));
      final fromString =
          Family.fromJson(testFamilyJson(id: '5', ownerId: '9'));

      expect(fromInt.id, fromString.id);
      expect(fromInt.ownerId, fromString.ownerId);
    });

    test('fromJson with missing members defaults to empty', () {
      final json = testFamilyJson()..remove('members');
      final family = Family.fromJson(json);

      expect(family.members, isEmpty);
    });
  });

  group('FamilyMember', () {
    test('fromJson with dietary profile', () {
      final member = FamilyMember.fromJson(testFamilyMemberJson(
        id: 3,
        name: 'Junior',
        relationship: 'son',
      ));

      expect(member.id, '3');
      expect(member.name, 'Junior');
      expect(member.relationship, 'son');
      expect(member.familyId, '1');
      expect(member.userId, isNull);
      expect(member.dietaryProfile.allergies, hasLength(1));
      expect(member.dietaryProfile.allergies[0].name, 'peanuts');
      expect(member.dietaryProfile.intolerances, ['lactose']);
    });

    test('fromJson with null dietary_profile coerces to empty profile', () {
      final member =
          FamilyMember.fromJson(testFamilyMemberJson(includeProfile: false));

      expect(member.dietaryProfile.allergies, isEmpty);
      expect(member.dietaryProfile.intolerances, isEmpty);
      expect(member.dietaryProfile.restrictions, isEmpty);
      expect(member.dietaryProfile.preferences, isEmpty);
    });
  });

  group('DietaryProfile', () {
    test('fromJson with snake_case keys', () {
      final profile = DietaryProfile.fromJson(testDietaryProfileJson(
        medicalNotes: 'carries an epipen',
      ));

      expect(profile.allergies, hasLength(1));
      expect(profile.allergies[0].severity, 'severe');
      expect(profile.intolerances, ['lactose']);
      expect(profile.restrictions, ['vegetarian']);
      expect(profile.preferences, ['no cilantro']);
      expect(profile.medicalNotes, 'carries an epipen');
    });

    test('fromJson with null jsonb lists defaults to empty', () {
      final profile = DietaryProfile.fromJson(<String, dynamic>{
        'allergies': null,
        'intolerances': null,
        'restrictions': null,
        'preferences': null,
      });

      expect(profile.allergies, isEmpty);
      expect(profile.intolerances, isEmpty);
      expect(profile.restrictions, isEmpty);
      expect(profile.preferences, isEmpty);
    });

    test('encodes to backend snake_case wire format', () {
      const profile = DietaryProfile(
        allergies: [Allergy(name: 'peanuts', severity: 'severe')],
        intolerances: ['lactose'],
        medicalNotes: 'note',
      );
      // jsonEncode invokes toJson on nested objects, mirroring what Dio
      // sends over the wire.
      final wire =
          jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>;

      expect(wire['intolerances'], ['lactose']);
      expect(wire['medical_notes'], 'note');
      final allergy = (wire['allergies'] as List).first as Map<String, dynamic>;
      expect(allergy['name'], 'peanuts');
      expect(allergy['severity'], 'severe');
      expect(allergy.containsKey('sub_forms'), true);
    });
  });

  group('Allergy', () {
    test('fromJson with sub_forms', () {
      final allergy = Allergy.fromJson(testAllergyJson(
        name: 'tree nuts',
        severity: 'moderate',
        subForms: ['almonds', 'cashews'],
        notes: 'avoid cross-contamination',
      ));

      expect(allergy.name, 'tree nuts');
      expect(allergy.severity, 'moderate');
      expect(allergy.subForms, ['almonds', 'cashews']);
      expect(allergy.notes, 'avoid cross-contamination');
    });
  });
}
