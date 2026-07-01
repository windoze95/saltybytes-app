import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/providers/finder_provider.dart';
import '../../../models/allergen.dart';

/// A full-width, curated-list row for one finder shortlist pick: a photo
/// thumbnail, the title, the agent's one-line rationale (the hero), and a
/// compact meta row (rating + an aggregate family-safety summary). Tapping it
/// hands off to the existing preview → import flow.
///
/// Finder-specific (the search grid keeps using its own card): the finder
/// `SearchResult` carries no cook time, so none is shown; images are often
/// absent, so a neutral placeholder is used.
class FinderShortlistCard extends StatelessWidget {
  const FinderShortlistCard({
    super.key,
    required this.item,
    required this.onTap,
    this.index = 0,
  });

  final FinderResultItem item;
  final VoidCallback onTap;

  /// Position in the list, used to stagger the entrance animation.
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = item.result;
    final rating = result.rating;
    final reason = item.reason;
    final safety = _safetySummary(item.safety, theme);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(imageUrl: result.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // The rationale is the hero — prominent secondary subtitle.
                    if (reason != null && reason.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Meta row: rating (only when > 0) + family-safety summary.
                    // No cook time — the finder result has none.
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (rating != null && rating > 0)
                          _RatingLabel(rating: rating),
                        if (safety != null)
                          _SafetySummaryChip(
                            color: safety.color,
                            icon: safety.icon,
                            label: safety.label,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Icon(Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (40 * index).ms)
        .slideY(begin: 0.12, end: 0, duration: 300.ms, delay: (40 * index).ms);
  }
}

/// Aggregates per-member safety into one summary badge. Returns null when there
/// is no safety data (finder safety is best-effort/model-supplied):
/// - any `avoid`   → red `Avoid for <name>` (or "Avoid for N")
/// - else any `caution` → amber "N caution"
/// - else all safe → green "Family-safe"
///
/// Colors mirror the per-member [SafetyBadge] semantics (green/amber/red) but
/// use theme-aware tertiary/error so they stay readable on the card surface.
({Color color, IconData icon, String label})? _safetySummary(
    List<FamilySafetyCheck> safety, ThemeData theme) {
  if (safety.isEmpty) return null;

  final avoid = [for (final s in safety) if (s.status == 'avoid') s];
  if (avoid.isNotEmpty) {
    final name = avoid.first.memberName.trim();
    final label = avoid.length == 1
        ? (name.isEmpty ? 'Not family-safe' : 'Avoid for $name')
        : 'Avoid for ${avoid.length}';
    return (
      color: theme.colorScheme.error,
      icon: Icons.warning_amber_rounded,
      label: label,
    );
  }

  final cautions = safety.where((s) => s.status == 'caution').length;
  if (cautions > 0) {
    return (
      color: const Color(0xFFF9A825),
      icon: Icons.info_outline,
      label: '$cautions caution',
    );
  }

  return (
    color: theme.colorScheme.tertiary,
    icon: Icons.check_circle,
    label: 'Family-safe',
  );
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(Icons.restaurant,
            size: 28, color: theme.colorScheme.primary.withValues(alpha: 0.35)),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        height: 72,
        child: (imageUrl == null || imageUrl!.isEmpty)
            ? placeholder
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                memCacheWidth: 200, // 72px @ up to ~2.7x; cap decode memory
                fit: BoxFit.cover,
                placeholder: (_, __) => placeholder,
                errorWidget: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}

class _RatingLabel extends StatelessWidget {
  const _RatingLabel({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF9A825)),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SafetySummaryChip extends StatelessWidget {
  const _SafetySummaryChip({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
