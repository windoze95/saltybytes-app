import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/user_provider.dart';
import 'package:saltybytes_app/models/user.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockApiClient apiClient;
  late ProviderContainer container;

  setUp(() {
    apiClient = MockApiClient();
    container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(apiClient),
      authStateProvider.overrideWith(FakeAuthNotifier.new),
    ]);
    addTearDown(container.dispose);
  });

  void stubProfile(Map<String, dynamic> userJson) {
    when(() => apiClient.get(ApiEndpoints.userProfile)).thenAnswer(
        (_) async => fakeResponse<dynamic>({'user': userJson}));
  }

  /// Primes auth BEFORE reading the user provider (Riverpod gotcha), then
  /// resolves the current user.
  Future<User?> primeUser() async {
    await container.read(authStateProvider.future);
    return container.read(currentUserProvider.future);
  }

  group('currentUserProvider.build', () {
    test('fetches GET /v1/users/me and parses the {user: {...}} envelope',
        () async {
      stubProfile(testUserJson(
        id: 'u-7',
        username: 'chefmike',
        email: 'mike@example.com',
        firstName: 'Chef Mike',
        settings: testUserSettingsJson(keepScreenAwake: false),
        personalization: testPersonalizationJson(
          unitSystem: 'metric',
          requirements: 'low sodium',
          uid: 'uid-123',
        ),
      ));

      final user = await primeUser();

      expect(user, isNotNull);
      expect(user!.id, 'u-7');
      expect(user.username, 'chefmike');
      expect(user.email, 'mike@example.com');
      expect(user.firstName, 'Chef Mike');
      expect(user.settings.keepScreenAwake, isFalse);
      expect(user.personalization.unitSystem, 'metric');
      expect(user.personalization.requirements, 'low sodium');
      expect(user.personalization.uid, 'uid-123');
    });

    test('returns null without hitting the network when unauthenticated',
        () async {
      final unauthContainer = ProviderContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        authStateProvider
            .overrideWith(() => FakeAuthNotifier(AuthStatus.unauthenticated)),
      ]);
      addTearDown(unauthContainer.dispose);

      await unauthContainer.read(authStateProvider.future);
      final user = await unauthContainer.read(currentUserProvider.future);

      expect(user, isNull);
      verifyNever(() => apiClient.get(any()));
    });
  });

  group('CurrentUserNotifier.updateSettings', () {
    test('PUTs the settings JSON to /v1/users/me/settings and applies the '
        'change optimistically', () async {
      stubProfile(testUserJson(
        settings: testUserSettingsJson(keepScreenAwake: true),
      ));
      when(() => apiClient.put(
            ApiEndpoints.userSettings,
            data: any(named: 'data'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({'message': 'ok'}));

      await primeUser();
      await container
          .read(currentUserProvider.notifier)
          .updateSettings(const UserSettings(keepScreenAwake: false));

      final body = verify(() => apiClient.put(
            ApiEndpoints.userSettings,
            data: captureAny(named: 'data'),
          )).captured.single;
      expect(body, {'keep_screen_awake': false});
      expect(
        container.read(currentUserProvider).value!.settings.keepScreenAwake,
        isFalse,
      );
    });

    test('is a no-op when no user is loaded', () async {
      final unauthContainer = ProviderContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        authStateProvider
            .overrideWith(() => FakeAuthNotifier(AuthStatus.unauthenticated)),
      ]);
      addTearDown(unauthContainer.dispose);
      await unauthContainer.read(authStateProvider.future);
      await unauthContainer.read(currentUserProvider.future);

      await unauthContainer
          .read(currentUserProvider.notifier)
          .updateSettings(const UserSettings(keepScreenAwake: false));

      verifyNever(() => apiClient.put(any(), data: any(named: 'data')));
    });
  });

  group('CurrentUserNotifier.updatePersonalization', () {
    test('changing unit_system preserves requirements and uid in the PUT '
        'body (no client-side wipe)', () async {
      stubProfile(testUserJson(
        personalization: testPersonalizationJson(
          unitSystem: 'us_customary',
          requirements: 'no cilantro, low sodium',
          uid: 'uid-123',
        ),
      ));
      when(() => apiClient.put(
            ApiEndpoints.userPersonalization,
            data: any(named: 'data'),
          )).thenAnswer((_) async => fakeResponse<dynamic>({'message': 'ok'}));

      final user = await primeUser();

      // The UI mutates one field via copyWith on the CURRENT value; the
      // other personalization fields must survive the round-trip.
      await container.read(currentUserProvider.notifier).updatePersonalization(
            user!.personalization.copyWith(unitSystem: 'metric'),
          );

      final body = verify(() => apiClient.put(
            ApiEndpoints.userPersonalization,
            data: captureAny(named: 'data'),
          )).captured.single;
      expect(body, {
        'unit_system': 'metric',
        'requirements': 'no cilantro, low sodium',
        'uid': 'uid-123',
      });

      final personalization =
          container.read(currentUserProvider).value!.personalization;
      expect(personalization.unitSystem, 'metric');
      expect(personalization.requirements, 'no cilantro, low sodium');
      expect(personalization.uid, 'uid-123');
    });

    test('is a no-op when no user is loaded', () async {
      final unauthContainer = ProviderContainer(overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        authStateProvider
            .overrideWith(() => FakeAuthNotifier(AuthStatus.unauthenticated)),
      ]);
      addTearDown(unauthContainer.dispose);
      await unauthContainer.read(authStateProvider.future);
      await unauthContainer.read(currentUserProvider.future);

      await unauthContainer
          .read(currentUserProvider.notifier)
          .updatePersonalization(const Personalization(unitSystem: 'metric'));

      verifyNever(() => apiClient.put(any(), data: any(named: 'data')));
    });
  });

  group('CurrentUserNotifier.refreshProfile', () {
    test('re-fetches the profile and replaces state', () async {
      stubProfile(testUserJson(username: 'chefmike'));
      await primeUser();

      stubProfile(testUserJson(username: 'renamedchef'));
      await container.read(currentUserProvider.notifier).refreshProfile();

      expect(
        container.read(currentUserProvider).value!.username,
        'renamedchef',
      );
    });
  });
}
