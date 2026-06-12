import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/family.dart' as models;
import '../../models/family.dart' show FamilyMember, DietaryProfile;
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'auth_provider.dart';

// Family list provider
final familyProvider =
    AsyncNotifierProvider<FamilyNotifier, models.Family?>(FamilyNotifier.new);

class FamilyNotifier extends AsyncNotifier<models.Family?> {
  late ApiClient _apiClient;

  @override
  Future<models.Family?> build() async {
    _apiClient = ref.watch(apiClientProvider);

    final authStatus = ref.watch(authStateProvider).valueOrNull;
    if (authStatus != AuthStatus.authenticated) {
      return null;
    }

    return _fetchFamily();
  }

  Future<models.Family?> _fetchFamily() async {
    final response = await _apiClient.get(ApiEndpoints.family);
    final data = response.data;

    // Backend wraps the family in {"family": ...} and returns
    // {"family": null} when no family exists.
    if (data is Map<String, dynamic>) {
      final familyJson = data['family'];
      if (familyJson is Map<String, dynamic>) {
        return models.Family.fromJson(familyJson);
      }
    }

    return null;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFamily());
  }

  /// Creates a new family for the current user (POST /v1/family).
  Future<models.Family> createFamily(String name) async {
    final response = await _apiClient.post(
      ApiEndpoints.family,
      data: {'name': name},
    );
    final data = response.data as Map<String, dynamic>;
    final family =
        models.Family.fromJson(data['family'] as Map<String, dynamic>);

    state = AsyncData(family);
    return family;
  }

  Future<FamilyMember> addMember({
    required String name,
    String relationship = '',
  }) async {
    final family = state.valueOrNull;
    if (family == null) throw Exception('No family loaded');

    final response = await _apiClient.post(
      ApiEndpoints.familyMembers,
      data: {'name': name, 'relationship': relationship},
    );
    final data = response.data as Map<String, dynamic>;
    final member =
        FamilyMember.fromJson(data['member'] as Map<String, dynamic>);

    state = AsyncData(
      family.copyWith(members: [...family.members, member]),
    );

    return member;
  }

  Future<void> removeMember(String memberId) async {
    final family = state.valueOrNull;
    if (family == null) return;

    final previousMembers = family.members;
    state = AsyncData(
      family.copyWith(
        members: family.members.where((m) => m.id != memberId).toList(),
      ),
    );

    try {
      await _apiClient.delete(
        ApiEndpoints.familyMember(memberId),
      );
    } catch (e) {
      state = AsyncData(family.copyWith(members: previousMembers));
      rethrow;
    }
  }

  /// Updates a member's name/relationship. The backend accepts only those
  /// two fields on PUT /v1/family/members/:id; dietary profiles persist
  /// through [updateMemberDietaryProfile].
  Future<FamilyMember> updateMember(FamilyMember member) async {
    final family = state.valueOrNull;
    if (family == null) throw Exception('No family loaded');

    final response = await _apiClient.put(
      ApiEndpoints.familyMember(member.id),
      data: {
        'name': member.name,
        'relationship': member.relationship,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final updated =
        FamilyMember.fromJson(data['member'] as Map<String, dynamic>);

    state = AsyncData(
      family.copyWith(
        members: family.members
            .map((m) => m.id == updated.id ? updated : m)
            .toList(),
      ),
    );

    return updated;
  }

  /// Persists a dietary profile through the dedicated
  /// PUT /v1/family/members/:id/dietary route.
  Future<void> updateMemberDietaryProfile(
    String memberId,
    DietaryProfile profile,
  ) async {
    await _apiClient.put(
      ApiEndpoints.familyMemberDietary(memberId),
      data: profile.toJson(),
    );

    final family = state.valueOrNull;
    if (family == null) return;

    state = AsyncData(
      family.copyWith(
        members: family.members
            .map((m) =>
                m.id == memberId ? m.copyWith(dietaryProfile: profile) : m)
            .toList(),
      ),
    );
  }
}

// Family member detail provider
final familyMemberProvider =
    Provider.family<FamilyMember?, String>((ref, memberId) {
  final family = ref.watch(familyProvider).valueOrNull;
  if (family == null) return null;
  try {
    return family.members.firstWhere((m) => m.id == memberId);
  } catch (_) {
    return null;
  }
});

// Dietary interview state
enum InterviewStatus { idle, listening, thinking, responding, complete }

class InterviewMessage {
  const InterviewMessage({
    required this.text,
    required this.isUser,
    this.timestamp,
  });

  final String text;
  final bool isUser;
  final DateTime? timestamp;

  /// Contract C5 wire format: {"role": "user"|"assistant", "content": "..."}.
  Map<String, dynamic> toWireJson() => {
        'role': isUser ? 'user' : 'assistant',
        'content': text,
      };
}

class InterviewState {
  const InterviewState({
    this.status = InterviewStatus.idle,
    this.messages = const [],
    this.extractedProfile,
    this.error,
  });

  final InterviewStatus status;
  final List<InterviewMessage> messages;
  final DietaryProfile? extractedProfile;
  final String? error;

  InterviewState copyWith({
    InterviewStatus? status,
    List<InterviewMessage>? messages,
    DietaryProfile? extractedProfile,
    String? error,
  }) {
    return InterviewState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      extractedProfile: extractedProfile ?? this.extractedProfile,
      error: error,
    );
  }
}

final dietaryInterviewProvider = StateNotifierProvider.autoDispose
    .family<DietaryInterviewNotifier, InterviewState, String>(
  (ref, memberId) {
    final apiClient = ref.watch(apiClientProvider);
    final family = ref.watch(familyProvider).valueOrNull;
    FamilyMember? member;
    if (family != null) {
      try {
        member = family.members.firstWhere((m) => m.id == memberId);
      } catch (_) {}
    }
    return DietaryInterviewNotifier(
      apiClient: apiClient,
      memberId: memberId,
      memberName: member?.name ?? 'this person',
    );
  },
);

class DietaryInterviewNotifier extends StateNotifier<InterviewState> {
  DietaryInterviewNotifier({
    required ApiClient apiClient,
    required this.memberId,
    required this.memberName,
  })  : _apiClient = apiClient,
        super(const InterviewState());

  final ApiClient _apiClient;
  final String memberId;
  final String memberName;

  void startInterview() {
    state = state.copyWith(
      status: InterviewStatus.responding,
      messages: [
        InterviewMessage(
          text: "Hi! I'd like to learn about $memberName's dietary needs. "
              "Let's start with the basics -- does $memberName have any "
              "known food allergies?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    final userMessage = InterviewMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      status: InterviewStatus.thinking,
      messages: [...state.messages, userMessage],
    );

    try {
      // POST /v1/family/members/:member_id/dietary/interview with the full
      // running conversation: {"messages": [{role, content}, ...]}.
      final response = await _apiClient.post(
        ApiEndpoints.familyMemberInterview(memberId),
        data: {
          'messages': state.messages.map((m) => m.toWireJson()).toList(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      final reply = data['response'] as String? ?? 'Could you tell me more?';
      final isComplete = data['complete'] as bool? ?? false;

      DietaryProfile? extracted;
      final profileJson = data['profile'];
      if (profileJson is Map<String, dynamic>) {
        extracted = DietaryProfile.fromJson(profileJson);
      }

      state = state.copyWith(
        status:
            isComplete ? InterviewStatus.complete : InterviewStatus.responding,
        messages: [
          ...state.messages,
          InterviewMessage(
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
        extractedProfile: extracted ?? state.extractedProfile,
      );
    } catch (e) {
      state = state.copyWith(
        status: InterviewStatus.responding,
        messages: [
          ...state.messages,
          InterviewMessage(
            text: "Sorry, I had trouble processing that. Could you try again?",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
        error: e.toString(),
      );
    }
  }
}
