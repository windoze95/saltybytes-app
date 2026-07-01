import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// The live "using the app for you" strip: one line per streamed agent event,
/// with a spinner on the last line while the run is still in flight.
class NarrationStrip extends StatelessWidget {
  const NarrationStrip({super.key, required this.lines, required this.active});

  final List<String> lines;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      lines[i],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: i == lines.length - 1
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                        fontWeight:
                            i == lines.length - 1 ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                  if (active && i == lines.length - 1) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ).animate(key: ValueKey('narr-$i')).fadeIn(duration: 250.ms).slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 250.ms,
                ),
        ],
      ),
    );
  }
}

/// Tap-to-refine bar: bounded refinement chips + a voice mic. Tapping a chip
/// re-runs the agent search with that constraint.
class RefineBar extends StatelessWidget {
  const RefineBar({
    super.key,
    required this.chips,
    required this.isListening,
    required this.onChip,
    required this.onVoice,
  });

  final List<String> chips;
  final bool isListening;
  final void Function(String) onChip;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: chips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => Center(
                      child: ActionChip(
                        avatar: const Icon(Icons.tune, size: 16),
                        label: Text(chips[i]),
                        onPressed: () => onChip(chips[i]),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onVoice,
                tooltip: 'Refine by voice',
                icon: Icon(isListening ? Icons.mic : Icons.mic_none),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A subtle "working" indicator shown while the agent is streaming but no
/// shortlist has landed yet and there is nothing in the narration strip.
class SearchWorkingPlaceholder extends StatelessWidget {
  const SearchWorkingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Finding real recipes…',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly agent empty state — never implies a recipe was invented; offers the
/// backend's broaden suggestions as tappable re-runs.
class FinderEmptyState extends StatelessWidget {
  const FinderEmptyState({
    super.key,
    required this.broaden,
    required this.onBroaden,
  });

  final List<String> broaden;
  final void Function(String) onBroaden;

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
              Icons.travel_explore,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "Couldn't find a great match",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try widening the search — tap one of these to look again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (broaden.isNotEmpty) ...[
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in broaden)
                    ActionChip(
                      label: Text(b),
                      onPressed: () => onBroaden(b),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Search-quota (403) state with an upgrade affordance.
class SearchLimitState extends StatelessWidget {
  const SearchLimitState({
    super.key,
    required this.message,
    required this.onUpgrade,
  });

  final String message;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'Search limit reached',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onUpgrade,
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Upgrade to Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
