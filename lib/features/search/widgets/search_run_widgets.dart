import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/providers/search_provider.dart';

/// The live "using the app for you" status: a single slim line showing the
/// agent's LATEST step (with a spinner while the run is in flight). Results
/// paint live underneath, so the strip stays out of the way — the full
/// narration log lives on in saved sessions.
class NarrationStrip extends StatelessWidget {
  const NarrationStrip({super.key, required this.lines, required this.active});

  final List<String> lines;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (lines.isEmpty) return const SizedBox.shrink();
    final latest = lines.last;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: 250.ms,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                latest,
                key: ValueKey(latest),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (active) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chips for the collections the agent is digging through this run:
/// 📖 '50 Best Weeknight Dinners' pulses while open, then shows how many
/// recipes it folded in.
class DiggingStrip extends StatelessWidget {
  const DiggingStrip({super.key, required this.digging});

  final List<DiggingCollection> digging;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (digging.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: digging.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = digging[i];
          final chip = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer
                  .withValues(alpha: d.done ? 0.35 : 0.6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(d.done ? '📖' : '🔎',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    d.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                if (d.done && d.folded > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '+${d.folded}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          );
          if (d.done) return Center(child: chip);
          return Center(
            child: chip
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(begin: 0.55, end: 1.0, duration: 700.ms),
          );
        },
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

/// The body of the Search screen in the brief window before an agent run's
/// FIRST results paint (results land live as soon as search returns). [found]
/// shows a thumbnail cluster when a late stage is still assembling the list
/// (e.g. an all-collections search waiting on its first mined batch).
class AgentWorkingView extends StatelessWidget {
  const AgentWorkingView({super.key, required this.found});

  final List<WebSearchResult> found;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = found.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count == 0) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Finding real recipes…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ] else ...[
              FoundSoFarThumbs(found: found),
              const SizedBox(height: 16),
              Text(
                '$count ${count == 1 ? 'recipe' : 'recipes'} found',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Curating your picks…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: const LinearProgressIndicator(minHeight: 4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An overlapping cluster of the found-so-far recipe thumbnails (capped, with
/// a "+n" bubble for the rest). Each new find pops in as it lands.
class FoundSoFarThumbs extends StatelessWidget {
  const FoundSoFarThumbs({super.key, required this.found});

  final List<WebSearchResult> found;

  static const _maxThumbs = 5;
  static const _size = 52.0;
  static const _overlap = 36.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shown = found.take(_maxThumbs).toList();
    final extra = found.length - shown.length;
    final slots = shown.length + (extra > 0 ? 1 : 0);

    Widget circle(Widget child) => Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.surface, width: 2.5),
            color: colors.primary.withValues(alpha: 0.12),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        );

    return SizedBox(
      height: _size,
      width: _overlap * (slots - 1) + _size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * _overlap,
              child: KeyedSubtree(
                key: ValueKey(shown[i].sourceUrl ?? shown[i].title),
                child: circle(
                  shown[i].imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: shown[i].imageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 156,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.restaurant,
                            size: 22,
                            color: colors.primary.withValues(alpha: 0.5),
                          ),
                        )
                      : Icon(
                          Icons.restaurant,
                          size: 22,
                          color: colors.primary.withValues(alpha: 0.5),
                        ),
                ).animate().fadeIn(duration: 250.ms).scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1, 1),
                      duration: 250.ms,
                      curve: Curves.easeOutBack,
                    ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * _overlap,
              child: circle(
                Center(
                  child: Text(
                    '+$extra',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ),
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
