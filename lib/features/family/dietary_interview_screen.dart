import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/providers/family_provider.dart';

class DietaryInterviewScreen extends ConsumerStatefulWidget {
  const DietaryInterviewScreen({super.key, required this.memberId});

  final String memberId;

  @override
  ConsumerState<DietaryInterviewScreen> createState() =>
      _DietaryInterviewScreenState();
}

class _DietaryInterviewScreenState
    extends ConsumerState<DietaryInterviewScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _started = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _start() {
    ref.read(dietaryInterviewProvider(widget.memberId).notifier).startInterview();
    setState(() => _started = true);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    ref
        .read(dietaryInterviewProvider(widget.memberId).notifier)
        .sendMessage(text);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(100.ms, () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _saveProfile() async {
    final interviewState =
        ref.read(dietaryInterviewProvider(widget.memberId));
    if (interviewState.extractedProfile == null) return;

    try {
      await ref.read(familyProvider.notifier).updateMemberDietaryProfile(
            widget.memberId,
            interviewState.extractedProfile!,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dietary profile saved!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFacingErrorMessage(
              e,
              'Failed to save the profile. Please try again.',
            )),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final interviewState =
        ref.watch(dietaryInterviewProvider(widget.memberId));
    final member = ref.watch(familyMemberProvider(widget.memberId));

    // Scroll to bottom when messages change
    if (interviewState.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dietary Interview${member != null ? ' - ${member.name}' : ''}',
        ),
        actions: [
          if (interviewState.status == InterviewStatus.complete &&
              interviewState.extractedProfile != null)
            TextButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: !_started
                ? _StartPrompt(
                    memberName: member?.name ?? 'family member',
                    onStart: _start,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: interviewState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = interviewState.messages[index];
                      return _ChatBubble(
                        text: msg.text,
                        isUser: msg.isUser,
                      )
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .slideY(begin: 0.1, end: 0, duration: 200.ms);
                    },
                  ),
          ),

          // Thinking indicator
          if (interviewState.status == InterviewStatus.thinking)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thinking...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),

          // Completion banner
          if (interviewState.status == InterviewStatus.complete &&
              interviewState.extractedProfile != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: theme.colorScheme.tertiary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Interview complete! Tap Save to update the dietary profile.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          if (_started &&
              interviewState.status != InterviewStatus.complete) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type your response...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled:
                          interviewState.status != InterviewStatus.thinking,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color:
                          interviewState.status == InterviewStatus.thinking
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4)
                              : theme.colorScheme.primary,
                    ),
                    onPressed:
                        interviewState.status == InterviewStatus.thinking
                            ? null
                            : _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StartPrompt extends StatelessWidget {
  const _StartPrompt({required this.memberName, required this.onStart});

  final String memberName;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'AI Dietary Interview',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'I\'ll ask a few questions to understand $memberName\'s '
              'dietary needs, allergies, and preferences.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.chat),
              label: const Text('Start Interview'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
