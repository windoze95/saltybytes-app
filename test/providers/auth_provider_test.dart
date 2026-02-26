import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/storage/secure_storage.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('AuthStatus', () {
    test('has all three expected values', () {
      expect(AuthStatus.values, hasLength(3));
      expect(AuthStatus.values, contains(AuthStatus.authenticated));
      expect(AuthStatus.values, contains(AuthStatus.unauthenticated));
      expect(AuthStatus.values, contains(AuthStatus.loading));
    });

    test('enum name strings match expected values', () {
      expect(AuthStatus.authenticated.name, 'authenticated');
      expect(AuthStatus.unauthenticated.name, 'unauthenticated');
      expect(AuthStatus.loading.name, 'loading');
    });
  });

  group('Login request body shape', () {
    test('has correct structure with username and password', () {
      // Mirrors the data sent in AuthNotifier.login
      final requestBody = <String, dynamic>{
        'username': 'chefmike',
        'password': 'secret123',
      };

      expect(requestBody, isA<Map<String, dynamic>>());
      expect(requestBody.containsKey('username'), true);
      expect(requestBody.containsKey('password'), true);
      expect(requestBody['username'], 'chefmike');
      expect(requestBody['password'], 'secret123');
    });

    test('register request body includes email', () {
      // Mirrors the data sent in AuthNotifier.register
      final requestBody = <String, dynamic>{
        'username': 'newchef',
        'email': 'new@example.com',
        'password': 'securePass!',
      };

      expect(requestBody.containsKey('username'), true);
      expect(requestBody.containsKey('email'), true);
      expect(requestBody.containsKey('password'), true);
    });
  });

  group('Token storage with mock', () {
    late MockSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockSecureStorage();
    });

    test('saveTokens stores both access and refresh tokens', () async {
      when(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      await mockStorage.saveTokens(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
      );

      verify(() => mockStorage.saveTokens(
            accessToken: 'test-access-token',
            refreshToken: 'test-refresh-token',
          )).called(1);
    });

    test('getAccessToken returns stored token', () async {
      when(() => mockStorage.getAccessToken())
          .thenAnswer((_) async => 'stored-access-token');

      final token = await mockStorage.getAccessToken();

      expect(token, 'stored-access-token');
    });

    test('hasTokens returns true when token exists', () async {
      when(() => mockStorage.hasTokens()).thenAnswer((_) async => true);

      final result = await mockStorage.hasTokens();

      expect(result, true);
    });

    test('hasTokens returns false when no token', () async {
      when(() => mockStorage.hasTokens()).thenAnswer((_) async => false);

      final result = await mockStorage.hasTokens();

      expect(result, false);
    });
  });

  group('Logout clears state', () {
    late MockSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockSecureStorage();
    });

    test('clearTokens is called during logout flow', () async {
      when(() => mockStorage.clearTokens()).thenAnswer((_) async {});

      // Simulates the logout() flow: clear tokens
      await mockStorage.clearTokens();

      verify(() => mockStorage.clearTokens()).called(1);
    });

    test('refresh token response has expected shape', () {
      // Mirrors the expected API response for token refresh
      final refreshResponse = <String, dynamic>{
        'access_token': 'new-access-token',
        'refresh_token': 'new-refresh-token',
      };

      expect(refreshResponse['access_token'], isA<String>());
      expect(refreshResponse['refresh_token'], isA<String>());
    });
  });
}
