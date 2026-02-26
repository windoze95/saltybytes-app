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

    if (data is List && data.isNotEmpty) {
      return models.Family.fromJson(data[0] as Map<String, dynamic>);
    }
    if (data is Map<String, dynamic>) {
      if (data['families'] is List) {
        final families = data['families'] as List;
        if (families.isNotEmpty) {
          return models.Family.fromJson(families[0] as Map<String, dynamic>);
        }
      }
      return models.Family.fromJson(data);
    }

    return null;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFamily());
  }

  Future<FamilyMember> addMember({
    required String name,
    String role = 'member',
  }) async {
    final family = state.valueOrNull;
    if (family == null) throw Exception('No family loaded');

    final response = await _apiClient.post(
      ApiEndpoints.familyMembers,
      data: {'name': name, 'role': role},
    );
    final member =
        FamilyMember.fromJson(response.data as Map<String, dynamic>);

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

  Future<FamilyMember> updateMember(FamilyMember member) async {
    final family = state.valueOrNull;
    if (family == null) throw Exception('No family loaded');

    final response = await _apiClient.put(
      ApiEndpoints.familyMember(member.id),
      data: member.toJson(),
    );
    final updated =
        FamilyMember.fromJson(response.data as Map<String, dynamic>);

    state = AsyncData(
      family.copyWith(
        members:
            family.members.map((m) => m.id == updated.id ? updated : m).toList(),
      ),
    );

    return updated;
  }

  Future<void> updateMemberDietaryProfile(
    String memberId,
    DietaryProfile profile,
  ) async {
    final family = state.valueOrNull;
    if (family == null) return;

    final member = family.members.firstWhere((m) => m.id == memberId);
    final updated = member.copyWith(dietaryProfile: profile);
    await updateMember(updated);
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
      final response = await _apiClient.post(
        '${ApiEndpoints.apiVersion}/ai/dietary-interview',
        data: {
          'member_id': memberId,
          'message': text,
          'history': state.messages
              .map((m) => {'text': m.text, 'is_user': m.isUser})
              .toList(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      final reply = data['reply'] as String? ?? 'Could you tell me more?';
      final isComplete = data['complete'] as bool? ?? false;

      DietaryProfile? extracted;
      if (isComplete && data['profile'] != null) {
        extracted = DietaryProfile.fromJson(
          data['profile'] as Map<String, dynamic>,
        );
      }

      state = state.copyWith(
        status: isComplete ? InterviewStatus.complete : InterviewStatus.responding,
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
