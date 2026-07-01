import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/finder_provider.dart';
import '../../core/voice/speech_service.dart';
import 'widgets/finder_shortlist_card.dart';

/// The finder run screen: kicks off a run for the given [facets], streams the
/// bounded trajectory into a live narration strip, then reveals the ranked
/// shortlist of real recipes (reason + safety). Tapping a card hands off to the
/// existing preview → import flow; refine chips re-run with a constraint.
class FinderRunScreen extends ConsumerStatefulWidget {
  const FinderRunScreen({super.key, required this.facets});

  final FinderFacets facets;

  @override
  ConsumerState<FinderRunScreen> createState() => _FinderRunScreenState();
}

class _FinderRunScreenState extends ConsumerState<FinderRunScreen> {
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Defer so we don't mutate the provider while the tree is first building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(finderProvider.notifier).run(widget.facets);
    });
  }

  void _openPreview(FinderResultItem item) {
    // Reuse the existing search preview → import flow verbatim.
    context.push('/search/preview', extra: item.result);
  }

  void _refine(String constraint) {
    ref.read(finderProvider.notifier).refine(constraint);
  }

  Future<void> _voiceRefine() async {
    final speech = ref.read(speechServiceProvider);
    if (_isListening) {
      await speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    final available = await speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Voice input is unavailable on this device.')),
        );
      }
      return;
    }
    if (mounted) setState(() => _isListening = true);
    await speech.listen(
      onResult: (text, isFinal) {
        if (!mounted || !isFinal) return;
        setState(() => _isListening = false);
        final trimmed = text.trim();
        if (trimmed.isNotEmpty) _refine(trimmed);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(finderProvider);
    final showRefineBar = state.refineChips.isNotEmpty && state.hasItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Finding recipes')),
      body: _body(state),
      bottomNavigationBar: showRefineBar
          ? _RefineBar(
              chips: state.refineChips,
              isListening: _isListening,
              onChip: _refine,
              onVoice: _voiceRefine,
            )
          : null,
    );
  }

  Widget _body(FinderRunState state) {
    if (state.isLimitReached) {
      return _LimitState(
        message: state.error ??
            'You’ve reached your search limit. Upgrade to Premium for '
                'unlimited recipe finds.',
      );
    }
    if (state.phase == FinderPhase.error) {
      return _ErrorState(
        message:
            state.error ?? 'Something went wrong finding recipes. Please try again.',
        onRetry: () => ref.read(finderProvider.notifier).run(widget.facets),
      );
    }

    return CustomScrollView(
      slivers: [
        if (state.narration.isNotEmpty)
          SliverToBoxAdapter(
            child: _NarrationStrip(
              lines: state.narration,
              active: state.isActive,
            ),
          ),
        if (state.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyFinderState(
              broaden: state.broaden,
              onBroaden: _refine,
            ),
          )
        else if (state.hasItems)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = state.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FinderShortlistCard(
                      item: item,
                      index: index,
                      onTap: () => _openPreview(item),
                    ),
                  );
                },
                childCount: state.items.length,
              ),
            ),
          )
        else if (state.isActive)
          SliverFillRemaining(
            hasScrollBody: false,
            child: state.narration.isEmpty
                ? const _WorkingPlaceholder()
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}

/// The live "using the app for you" strip: one line per streamed event, with a
/// spinner on the last line while the run is still in flight.
class _NarrationStrip extends StatelessWidget {
  const _NarrationStrip({required this.lines, required this.active});

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
                            : theme.colorScheme.onSurface.withValues(alpha: 0.55),
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

class _WorkingPlaceholder extends StatelessWidget {
  const _WorkingPlaceholder();

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

/// Tap-to-refine bar: bounded refinement chips + a voice mic. Tapping a chip
/// re-runs the finder with that constraint.
class _RefineBar extends StatelessWidget {
  const _RefineBar({
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

/// Friendly empty state — never implies a recipe was invented; offers the
/// backend's broaden suggestions as tappable re-runs.
class _EmptyFinderState extends StatelessWidget {
  const _EmptyFinderState({required this.broaden, required this.onBroaden});

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
class _LimitState extends StatelessWidget {
  const _LimitState({required this.message});

  final String message;

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
                size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
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
              onPressed: () => context.pushNamed('subscription'),
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Upgrade to Premium'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Something went wrong', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
