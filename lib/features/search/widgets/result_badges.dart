import 'package:flutter/material.dart';

import '../../../models/allergen.dart';

/// A multi-recipe card is "pending extraction" while its recipe is still being
/// pulled in the background.
bool isPendingExtraction(String? status) =>
    status == 'extracting' || status == 'pending';

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

/// A per-member safety pill (green "safe", amber "caution", red "avoid"), keyed
/// off the member's [FamilySafetyCheck.status]. Tuned for the dark immersive
/// overlay; used by the full-screen result page.
class SafetyBadge extends StatelessWidget {
  const SafetyBadge({super.key, required this.check});

  final FamilySafetyCheck check;

  @override
  Widget build(BuildContext context) {
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
