import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/network/websocket_client.dart';
import '../../core/providers/cooking_provider.dart';
import '../../core/providers/recipe_provider.dart';

class CookingModeScreen extends ConsumerStatefulWidget {
  const CookingModeScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends ConsumerState<CookingModeScreen> {
  final _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initSession();
  }

  Future<void> _initSession() async {
    final recipe = await ref.read(recipeDetailProvider(widget.recipeId).future);
    ref.read(cookingProvider.notifier).startSession(recipe);
  }

  @override
  void dispose() {
    _chatController.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    ref.read(cookingProvider.notifier).sendChatMessage(text);
  }

  void _showEphemeralEdit(BuildContext context) {
    final cookState = ref.read(cookingProvider);
    final controller =
        TextEditingController(text: cookState.currentInstruction);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Step (Just for Now)'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Modify this step...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cookingProvider.notifier).applyEphemeralEdit(
                    cookState.currentStep,
                    controller.text,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cookState = ref.watch(cookingProvider);
    final recipe = cookState.recipe;

    // Surface WS / voice errors as snackbars.
    ref.listen<CookingState>(cookingProvider, (previous, next) {
      final error = next.error;
      if (error != null && error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    if (recipe == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1210),
      body: Stack(
        children: [
          // Main content - swipeable step view
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! < -100) {
                ref.read(cookingProvider.notifier).nextStep();
              } else if (details.primaryVelocity! > 100) {
                ref.read(cookingProvider.notifier).previousStep();
              }
            },
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () {
                            ref.read(cookingProvider.notifier).endSession();
                            context.pop();
                          },
                        ),
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Ephemeral edit
                        IconButton(
                          icon: const Icon(Icons.edit_note,
                              color: Colors.white70),
                          onPressed: () => _showEphemeralEdit(context),
                          tooltip: 'Edit step (just for now)',
                        ),
                      ],
                    ),
                  ),

                  // Progress indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: LinearProgressIndicator(
                      value: cookState.totalSteps > 0
                          ? (cookState.currentStep + 1) / cookState.totalSteps
                          : 0,
                      backgroundColor: Colors.white12,
                      valueColor:
                          AlwaysStoppedAnimation(theme.colorScheme.primary),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step ${cookState.currentStep + 1} of ${cookState.totalSteps}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                  if (cookState.wsState !=
                      WebSocketConnectionState.connected) ...[
                    const SizedBox(height: 4),
                    Text(
                      switch (cookState.wsState) {
                        WebSocketConnectionState.connecting => 'Connecting…',
                        WebSocketConnectionState.reconnecting =>
                          'Reconnecting…',
                        _ => 'Offline — assistant unavailable',
                      },
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade300,
                      ),
                    ),
                  ],

                  // Step content
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          cookState.currentInstruction,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate(
                              key: ValueKey(cookState.currentStep),
                            )
                            .fadeIn(duration: 300.ms)
                            .slideX(
                              begin: 0.05,
                              end: 0,
                              duration: 300.ms,
                            ),
                      ),
                    ),
                  ),

                  // Hands-free status line: prompt for the wake word while
                  // passive, show the live transcript while actively listening.
                  if (cookState.handsFreePhase != HandsFreePhase.off)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 4),
                      child: Text(
                        cookState.handsFreePhase == HandsFreePhase.active
                            ? (cookState.voiceTranscript.isEmpty
                                ? 'Listening…'
                                : cookState.voiceTranscript)
                            : 'Say "Hey Salty"',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              cookState.handsFreePhase == HandsFreePhase.active
                                  ? theme.colorScheme.primary
                                  : Colors.white54,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Navigation buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: cookState.isFirstStep
                                ? Colors.white24
                                : Colors.white70,
                          ),
                          onPressed: cookState.isFirstStep
                              ? null
                              : () => ref
                                  .read(cookingProvider.notifier)
                                  .previousStep(),
                        ),
                        // Step dots
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            cookState.totalSteps.clamp(0, 12),
                            (i) => Container(
                              width: i == cookState.currentStep ? 10 : 6,
                              height: i == cookState.currentStep ? 10 : 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == cookState.currentStep
                                    ? theme.colorScheme.primary
                                    : i < cookState.currentStep
                                        ? Colors.white38
                                        : Colors.white10,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: cookState.isLastStep
                                ? Colors.white24
                                : Colors.white70,
                          ),
                          onPressed: cookState.isLastStep
                              ? null
                              : () =>
                                  ref.read(cookingProvider.notifier).nextStep(),
                        ),
                      ],
                    ),
                  ),

                  // Voice commands hint
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () =>
                              ref.read(cookingProvider.notifier).toggleChat(),
                          icon: const Icon(Icons.chat_bubble_outline,
                              size: 18, color: Colors.white54),
                          label: Text(
                            'Ask Salty',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          'Swipe to navigate',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.white30),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Voice indicator in corner
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Tooltip(
              message: !cookState.voiceAvailable
                  ? 'Voice input unavailable'
                  : switch (cookState.handsFreePhase) {
                      HandsFreePhase.off => 'Tap to enable hands-free',
                      HandsFreePhase.passive =>
                        'Listening for "Hey Salty" — tap to mute',
                      HandsFreePhase.active => 'Listening…',
                    },
              child: GestureDetector(
                onTap: () =>
                    ref.read(cookingProvider.notifier).toggleHandsFree(),
                child: AnimatedContainer(
                  duration: 300.ms,
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: switch (cookState.handsFreePhase) {
                      HandsFreePhase.active => theme.colorScheme.primary,
                      HandsFreePhase.passive =>
                        theme.colorScheme.primary.withValues(alpha: 0.25),
                      HandsFreePhase.off => Colors.white12,
                    },
                  ),
                  child: Icon(
                    !cookState.voiceAvailable
                        ? Icons.mic_off
                        : switch (cookState.handsFreePhase) {
                            HandsFreePhase.active => Icons.mic,
                            HandsFreePhase.passive => Icons.hearing,
                            HandsFreePhase.off => Icons.mic_none,
                          },
                    color: !cookState.voiceAvailable
                        ? Colors.white24
                        : cookState.handsFreePhase == HandsFreePhase.off
                            ? Colors.white54
                            : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          // Chat overlay
          if (cookState.isChatOpen)
            _ChatOverlay(
              chatMessages: cookState.chatMessages,
              chatController: _chatController,
              onSend: _sendChat,
              onClose: () => ref.read(cookingProvider.notifier).toggleChat(),
            ),
        ],
      ),
    );
  }
}

class _ChatOverlay extends StatelessWidget {
  const _ChatOverlay({
    required this.chatMessages,
    required this.chatController,
    required this.onSend,
    required this.onClose,
  });

  final List<ChatMessage> chatMessages;
  final TextEditingController chatController;
  final VoidCallback onSend;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2D2220),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.smart_toy,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Ask Salty',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: onClose,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white12),

              // Messages
              Expanded(
                child: chatMessages.isEmpty
                    ? Center(
                        child: Text(
                          'Ask about this step, substitutions, or anything!',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.white38),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: chatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = chatMessages[index];
                          return _CookingChatBubble(
                            text: msg.text,
                            isUser: msg.isUser,
                          );
                        },
                      ),
              ),

              // Input
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white12),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chatController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ask a question...',
                            hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3)),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => onSend(),
                        ),
                      ),
                      IconButton(
                        icon:
                            Icon(Icons.send, color: theme.colorScheme.primary),
                        onPressed: onSend,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CookingChatBubble extends StatelessWidget {
  const _CookingChatBubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : Colors.white.withValues(alpha: 0.08),
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
            color: isUser ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
