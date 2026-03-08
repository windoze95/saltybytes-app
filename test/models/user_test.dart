import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:saltybytes_app/models/user.dart';

import '../helpers/fixtures.dart';

void main() {
  group('User', () {
    test('fromJson with full data', () {
      final json = testUserJson();
      final user = User.fromJson(json);

      expect(user.id, 'user-xyz-456');
      expect(user.username, 'chefmike');
      expect(user.email, 'mike@example.com');
      expect(user.firstName, 'Chef Mike');
      expect(user.settings.keepScreenAwake, true);
      expect(user.personalization.unitSystem, 'us_customary');
      expect(user.personalization.requirements, '');
      expect(user.createdAt, isA<DateTime>());
      expect(user.updatedAt, isA<DateTime>());
    });

    test('fromJson with missing settings/personalization uses defaults', () {
      final json = <String, dynamic>{
        'id': 'u-1',
        'username': 'newuser',
        'email': 'new@test.com',
        'createdAt': '2025-03-01T00:00:00.000Z',
      };
      final user = User.fromJson(json);

      expect(user.id, 'u-1');
      expect(user.firstName, isNull);
      // Settings defaults
      expect(user.settings.keepScreenAwake, true);
      // Personalization defaults
      expect(user.personalization.unitSystem, 'us_customary');
      expect(user.personalization.requirements, '');
    });

    test('round-trip toJson/fromJson preserves data', () {
      final original = User.fromJson(testUserJson());
      final jsonString = jsonEncode(original.toJson());
      final roundTripped =
          User.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

      expect(roundTripped.id, original.id);
      expect(roundTripped.username, original.username);
      expect(roundTripped.email, original.email);
      expect(roundTripped.firstName, original.firstName);
      expect(roundTripped.settings.keepScreenAwake,
          original.settings.keepScreenAwake);
      expect(roundTripped.personalization.unitSystem,
          original.personalization.unitSystem);
    });
  });

  group('UserSettings', () {
    test('default values when constructed with const', () {
      const settings = UserSettings();

      expect(settings.keepScreenAwake, true);
    });

    test('fromJson with data', () {
      final json = <String, dynamic>{
        'keep_screen_awake': false,
      };
      final settings = UserSettings.fromJson(json);

      expect(settings.keepScreenAwake, false);
    });
  });

  group('Personalization', () {
    test('default values when constructed with const', () {
      const p = Personalization();

      expect(p.unitSystem, 'us_customary');
      expect(p.requirements, '');
      expect(p.uid, '');
    });

    test('fromJson with all fields', () {
      final json = testPersonalizationJson(
        unitSystem: 'metric',
        requirements: 'No peanuts',
        uid: '22222222-2222-2222-2222-222222222222',
      );
      final p = Personalization.fromJson(json);

      expect(p.unitSystem, 'metric');
      expect(p.requirements, 'No peanuts');
      expect(p.uid, '22222222-2222-2222-2222-222222222222');
    });
  });
}
