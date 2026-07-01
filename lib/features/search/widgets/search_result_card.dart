import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/providers/search_provider.dart';
import '../../../models/allergen.dart';

/// A multi-recipe card is "pending extraction" while its recipe is still being
/// pulled in the background.
bool isPendingExtraction(String? status) =>
    status == 'extracting' || status == 'pending';

/// Grid card for a single web search result (image, safety dots, per-card
/// extraction badge, title/source/rating), used by the search grid.
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.result,
    required this.onTap,
    this.index = 0,
  });

  final WebSearchResult result;
  final VoidCallback onTap;

  /// Position in the list, used to stagger the entrance animation.
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image — top ~65%
            Expanded(
              flex: 13,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    child: result.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: result.imageUrl!,
                            memCacheWidth: 600, // card-sized; cap decode memory
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Center(
                              child: Icon(Icons.restaurant,
                                  size: 32,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3)),
                            ),
                            errorWidget: (_, __, ___) => Center(
                              child: Icon(Icons.broken_image_outlined,
                                  size: 32,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3)),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.restaurant,
                                size: 36,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3)),
                          ),
                  ),
                  // Safety indicator dots (top-right)
                  if (result.familySafetyChecks.isNotEmpty)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: result.familySafetyChecks.map((check) {
                          final color = check.isSafe
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.error;
                          return Container(
                            margin: const EdgeInsets.only(left: 3),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  // Extraction status (top-left) for multi-recipe cards
                  if (isPendingExtraction(result.extractionStatus) ||
                      result.extractionStatus == 'failed')
                    Positioned(
                      top: 6,
                      left: 6,
                      child: ExtractionStatusBadge(
                          status: result.extractionStatus!),
                    ),
                ],
              ),
            ),

            // Info — bottom ~35%
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    // Source domain
                    if (result.sourceDomain != null)
                      Text(
                        result.sourceDomain!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontSize: 11,
                        ),
                      ),
                    // Rating
                    if (result.rating != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final filled = i < result.rating!.round();
                            return Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 12,
                              color: filled
                                  ? const Color(0xFFF9A825)
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3),
                            );
                          }),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (30 * index).ms)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: 300.ms,
          delay: (30 * index).ms,
        );
  }
}

/// A small pill shown on a multi-recipe card while its recipe is still being
/// extracted in the background (spinner + "Extracting…"), or muted if that
/// card's extraction failed.
class ExtractionStatusBadge extends StatelessWidget {
  const ExtractionStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = status == 'failed';
    final bg = failed ? theme.colorScheme.error : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failed)
            const Icon(Icons.error_outline, size: 12, color: Colors.white)
          else
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          const SizedBox(width: 5),
          Text(
            failed ? "Couldn't extract" : 'Extracting…',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// A per-member safety pill (green "safe", amber "caution", red "avoid"),
/// keyed off the member's [FamilySafetyCheck.status]. Search results carry no
/// safety data today, so this only lights up on finder shortlist cards.
class SafetyBadge extends StatelessWidget {
  const SafetyBadge({super.key, required this.check});

  final FamilySafetyCheck check;

  @override
  Widget build(BuildContext context) {
    // Three states from MemberSafety.status: safe / caution / avoid. Anything
    // that isn't explicitly "safe" or "caution" is treated as avoid (red).
    final (Color color, IconData icon) = switch (check.status) {
      'safe' => (const Color(0xFF5CFFD4), Icons.check_circle),
      'caution' => (const Color(0xFFFFB74D), Icons.info_outline),
      _ => (const Color(0xFFFF6B6B), Icons.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            check.memberName,
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
