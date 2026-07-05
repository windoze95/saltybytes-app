import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/api_endpoints.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/providers/family_provider.dart';
import 'package:saltybytes_app/models/family.dart' as models;

import '../helpers/fixtures.dart';
import '../helpers/test_helpers.dart';

/// Fake auth notifier that reports authenticated immediately.
class _FakeAuthNotifier extends AsyncNotifier<AuthStatus>
    implements AuthNotifier {

  @override
  bool needsEmailVerification = false;

  @override
  void markEmailVerificationHandled() {
    needsEmailVerification = false;
  }
  @override
  Future<AuthStatus> build() async => AuthStatus.authenticated;

  @override
  Future<void> login(
      {required String username, required String password}) async {}

  @override
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> logout() async {}
}

ProviderContainer _buildContainer(MockApiClient apiClient) {
  final container = ProviderContainer(overrides: [
    apiClientProvider.overrideWithValue(apiClient),
    authStateProvider.overrideWith(_FakeAuthNotifier.new),
  ]);
  // Keep familyProvider active: without a listener, the rebuild triggered by
  // the auth state resolving never flushes and `.future` deadlocks.
  container.listen(familyProvider, (_, __) {});
  return container;
}

/// Waits for auth to resolve and the dependent family fetch to settle.
Future<models.Family?> _loadFamily(ProviderContainer container) async {
  await container.read(authStateProvider.future);
  await Future<void>.delayed(Duration.zero);
  return container.read(familyProvider.future);
}

void main() {
  late MockApiClient apiClient;

  setUp(() {
    apiClient = MockApiClient();
  });

  group('FamilyNotifier fetch', () {
    test('unwraps the {"family": ...} envelope', () async {
      when(() => apiClient.get(ApiEndpoints.family)).thenAnswer(
        (_) async => fakeResponse<dynamic>({'family': testFamilyJson()}),
      );

      final container = _buildContainer(apiClient);
      addTearDown(container.dispose);

      final family = await _loadFamily(container);

      expect(family, isNotNull);
      expect(family!.id, '1');
      expect(family.name, 'The Smiths');
      expect(family.members, hasLength(2));
      expect(family.members[0].relationship, 'son');
    });

    test('returns null for {"family": null}', () async {
      when(() => apiClient.get(ApiEndpoints.family)).thenAnswer(
        (_) async => fakeResponse<dynamic>({'family': null}),
      );

      final container = _buildContainer(apiClient);
      addTearDown(container.dispose);

      final family = await _loadFamily(container);

      expect(family, isNull);
    });
  });

  group('FamilyNotifier createFamily', () {
    test('POSTs /v1/family and stores the unwrapped family', () async {
      when(() => apiClient.get(ApiEndpoints.family)).thenAnswer(
        (_) async => fakeResponse<dynamic>({'family': null}),
      );
      when(() => apiClient.post(ApiEndpoints.family, data: any(named: 'data')))
          .thenAnswer(
        (_) async => fakeResponse<dynamic>({
          'family': testFamilyJson(id: 10, name: 'New Crew', members: []),
        }),
      );

      final container = _buildContainer(apiClient);
      addTearDown(container.dispose);
      await _loadFamily(container);

      final created = await container
          .read(familyProvider.notifier)
          .createFamily('New Crew');

      expect(created.id, '10');
      expect(created.name, 'New Crew');
      expect(container.read(familyProvider).valueOrNull?.id, '10');

      final captured = verify(() => apiClient.post(
            ApiEndpoints.family,
            data: captureAny(named: 'data'),
          )).captured;
      expect(captured.single, {'name': 'New Crew'});
    });
  });

  group('FamilyNotifier addMember', () {
    test('unwraps the {"member": ...} envelope and sends relationship',
        () async {
      when(() => apiClient.get(ApiEndpoints.family)).thenAnswer(
        (_) async =>
            fakeResponse<dynamic>({'family': testFamilyJson(members: [])}),
      );
      when(() =>
              apiClient.post(ApiEndpoints.familyMembers,
                  data: any(named: 'data')))
          .thenAnswer(
        (_) async => fakeResponse<dynamic>({
          'member': testFamilyMemberJson(
            id: 5,
            name: 'Alex',
            relationship: 'son',
            includeProfile: false,
          ),
        }),
      );

      final container = _buildContainer(apiClient);
      addTearDown(container.dispose);
      await _loadFamily(container);

      final member = await container
          .read(familyProvider.notifier)
          .addMember(name: 'Alex', relationship: 'son');

      expect(member.id, '5');
      expect(member.name, 'Alex');
      expect(member.relationship, 'son');
      expect(
        container.read(familyProvider).valueOrNull?.members,
        hasLength(1),
      );

      final captured = verify(() => apiClient.post(
            ApiEndpoints.familyMembers,
            data: captureAny(named: 'data'),
          )).captured;
      expect(captured.single, {'name': 'Alex', 'relationship': 'son'});
    });
  });

  group('FamilyNotifier updateMemberDietaryProfile', () {
    test('PUTs the dedicated dietary route and updates local state',
        () async {
      when(() => apiClient.get(ApiEndpoints.family)).thenAnswer(
        (_) async => fakeResponse<dynamic>({'family': testFamilyJson()}),
      );
      when(() => apiClient.put(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => fakeResponse<dynamic>({'message': 'dietary profile updated'}),
      );

      final container = _buildContainer(apiClient);
      addTearDown(container.dispose);
      await _loadFamily(container);

      const profile = models.DietaryProfile(
        allergies: [models.Allergy(name: 'shellfish', severity: 'severe')],
        restrictions: ['pescatarian'],
      );
      await container
          .read(familyProvider.notifier)
          .updateMemberDietaryProfile('1', profile);

      verify(() => apiClient.put(
            ApiEndpoints.familyMemberDietary('1'),
            data: any(named: 'data'),
          )).called(1);

      final stored = container
          .read(familyProvider)
          .valueOrNull
          ?.members
          .firstWhere((m) => m.id == '1');
      expect(stored?.dietaryProfile.allergies.single.name, 'shellfish');
      expect(stored?.dietaryProfile.restrictions, ['pescatarian']);
    });
  });

  group('DietaryInterviewNotifier', () {
    test('POSTs role/content history to the interview route', () async {
      when(() => apiClient.post(any(),
          data: any(named: 'data'),
          options: any(named: 'options'))).thenAnswer(
        (_) async => fakeResponse<dynamic>({
          'response': 'Any other allergies?',
          'complete': false,
          'profile': null,
        }),
      );

      final notifier = DietaryInterviewNotifier(
        apiClient: apiClient,
        memberId: '7',
        memberName: 'Junior',
      );
      addTearDown(notifier.dispose);

      notifier.startInterview();
      await notifier.sendMessage('He is allergic to peanuts');

      final captured = verify(() => apiClient.post(
            ApiEndpoints.familyMemberInterview('7'),
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured;
      final body = captured.single as Map<String, dynamic>;
      final messages = body['messages'] as List;
      expect(messages, hasLength(2));
      expect((messages[0] as Map)['role'], 'assistant');
      expect((messages[1] as Map)['role'], 'user');
      expect((messages[1] as Map)['content'], 'He is allergic to peanuts');

      expect(notifier.state.status, InterviewStatus.responding);
      expect(notifier.state.messages.last.text, 'Any other allergies?');
      expect(notifier.state.extractedProfile, isNull);
    });

    test('parses complete=true with an extracted profile', () async {
      when(() => apiClient.post(any(),
          data: any(named: 'data'),
          options: any(named: 'options'))).thenAnswer(
        (_) async => fakeResponse<dynamic>({
          'response': 'Thanks, I have everything I need!',
          'complete': true,
          'profile': testDietaryProfileJson(
            allergies: [testAllergyJson(name: 'peanuts')],
            intolerances: [],
            restrictions: ['vegetarian'],
            preferences: [],
          ),
        }),
      );

      final notifier = DietaryInterviewNotifier(
        apiClient: apiClient,
        memberId: '7',
        memberName: 'Junior',
      );
      addTearDown(notifier.dispose);

      notifier.startInterview();
      await notifier.sendMessage('He is vegetarian and allergic to peanuts');

      expect(notifier.state.status, InterviewStatus.complete);
      expect(notifier.state.extractedProfile, isNotNull);
      expect(
        notifier.state.extractedProfile!.allergies.single.name,
        'peanuts',
      );
      expect(notifier.state.extractedProfile!.restrictions, ['vegetarian']);
    });

    test('recovers gracefully when the request fails', () async {
      when(() => apiClient.post(any(),
          data: any(named: 'data'),
          options: any(named: 'options'))).thenThrow(Exception('network down'));

      final notifier = DietaryInterviewNotifier(
        apiClient: apiClient,
        memberId: '7',
        memberName: 'Junior',
      );
      addTearDown(notifier.dispose);

      notifier.startInterview();
      await notifier.sendMessage('peanuts');

      expect(notifier.state.status, InterviewStatus.responding);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.messages.last.isUser, false);
    });

    test('uses the AI-generation receive timeout (full LLM turn)', () async {
      when(() => apiClient.post(any(),
          data: any(named: 'data'),
          options: any(named: 'options'))).thenAnswer(
        (_) async => fakeResponse<dynamic>({
          'response': 'Any other allergies?',
          'complete': false,
        }),
      );

      final notifier = DietaryInterviewNotifier(
        apiClient: apiClient,
        memberId: '7',
        memberName: 'Junior',
      );
      addTearDown(notifier.dispose);

      notifier.startInterview();
      await notifier.sendMessage('peanuts');

      final options = verify(() => apiClient.post(any(),
              data: any(named: 'data'),
              options: captureAny(named: 'options')))
          .captured
          .single as Options?;
      expect(options?.receiveTimeout, ApiTimeouts.aiGeneration);
    });

    test('drops the response without erroring when disposed mid-request',
        () async {
      final completer = Completer<Response<dynamic>>();
      when(() => apiClient.post(any(),
              data: any(named: 'data'), options: any(named: 'options')))
          .thenAnswer((_) => completer.future);

      final notifier = DietaryInterviewNotifier(
        apiClient: apiClient,
        memberId: '7',
        memberName: 'Junior',
      );

      notifier.startInterview();
      final pending = notifier.sendMessage('peanuts');

      // User pops the interview screen while the POST is in flight.
      notifier.dispose();
      completer.complete(fakeResponse<dynamic>({
        'response': 'Any other allergies?',
        'complete': false,
      }));

      // Must not throw ("setState after dispose" StateError).
      await pending;
    });
  });
}
