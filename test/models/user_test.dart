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
      expect(user.displayName, 'Chef Mike');
      expect(user.avatarUrl, 'https://cdn.saltybytes.ai/avatars/mike.jpg');
      expect(user.settings.themeMode, 'dark');
      expect(user.settings.measurementSystem, 'us_customary');
      expect(user.settings.defaultServings, 4);
      expect(user.settings.notificationsEnabled, true);
      expect(user.settings.cookingModeWakelock, true);
      expect(user.personalization.dietaryRestrictions, ['vegetarian']);
      expect(user.personalization.cuisinePreferences, ['Italian', 'Japanese']);
      expect(user.personalization.skillLevel, 'intermediate');
      expect(user.personalization.allergens, ['peanuts']);
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
      expect(user.displayName, isNull);
      expect(user.avatarUrl, isNull);
      // Settings defaults
      expect(user.settings.themeMode, 'system');
      expect(user.settings.measurementSystem, 'us_customary');
      expect(user.settings.defaultServings, 4);
      expect(user.settings.notificationsEnabled, true);
      expect(user.settings.cookingModeWakelock, true);
      // Personalization defaults
      expect(user.personalization.dietaryRestrictions, isEmpty);
      expect(user.personalization.cuisinePreferences, isEmpty);
      expect(user.personalization.skillLevel, 'intermediate');
      expect(user.personalization.allergens, isEmpty);
    });

    test('round-trip toJson/fromJson preserves data', () {
      final original = User.fromJson(testUserJson());
      // Encode through JSON string to get pure Map<String, dynamic> (not freezed impl types)
      final jsonString = jsonEncode(original.toJson());
      final roundTripped = User.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

      expect(roundTripped.id, original.id);
      expect(roundTripped.username, original.username);
      expect(roundTripped.email, original.email);
      expect(roundTripped.displayName, original.displayName);
      expect(roundTripped.avatarUrl, original.avatarUrl);
      expect(roundTripped.settings.themeMode, original.settings.themeMode);
      expect(roundTripped.settings.measurementSystem, original.settings.measurementSystem);
      expect(roundTripped.personalization.skillLevel, original.personalization.skillLevel);
      expect(roundTripped.personalization.allergens, original.personalization.allergens);
    });
  });

  group('UserSettings', () {
    test('default values when constructed with const', () {
      const settings = UserSettings();

      expect(settings.themeMode, 'system');
      expect(settings.measurementSystem, 'us_customary');
      expect(settings.defaultServings, 4);
      expect(settings.notificationsEnabled, true);
      expect(settings.cookingModeWakelock, true);
    });

    test('fromJson with partial data fills defaults', () {
      final json = <String, dynamic>{
        'themeMode': 'light',
      };
      final settings = UserSettings.fromJson(json);

      expect(settings.themeMode, 'light');
      expect(settings.measurementSystem, 'us_customary');
      expect(settings.defaultServings, 4);
    });
  });

  group('Personalization', () {
    test('default values when constructed with const', () {
      const p = Personalization();

      expect(p.dietaryRestrictions, isEmpty);
      expect(p.cuisinePreferences, isEmpty);
      expect(p.skillLevel, 'intermediate');
      expect(p.allergens, isEmpty);
    });

    test('fromJson with all fields', () {
      final json = testPersonalizationJson(
        dietaryRestrictions: ['vegan', 'gluten-free'],
        cuisinePreferences: ['Thai', 'Mexican'],
        skillLevel: 'beginner',
        allergens: ['dairy', 'eggs'],
      );
      final p = Personalization.fromJson(json);

      expect(p.dietaryRestrictions, ['vegan', 'gluten-free']);
      expect(p.cuisinePreferences, ['Thai', 'Mexican']);
      expect(p.skillLevel, 'beginner');
      expect(p.allergens, ['dairy', 'eggs']);
    });
  });
}
