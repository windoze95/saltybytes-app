import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum AllergenSeverity { safe, caution, unsafe }

class AllergenBadge extends StatelessWidget {
  const AllergenBadge({
    super.key,
    required this.label,
    required this.severity,
    this.compact = false,
  });

  final String label;
  final AllergenSeverity severity;
  final bool compact;

  Color _backgroundColor(ColorScheme colors) {
    return switch (severity) {
      AllergenSeverity.safe => colors.tertiary.withValues(alpha: 0.12),
      AllergenSeverity.caution =>
        const Color(0xFFF9A825).withValues(alpha: 0.15),
      AllergenSeverity.unsafe => colors.error.withValues(alpha: 0.12),
    };
  }

  Color _dotColor(ColorScheme colors) {
    return switch (severity) {
      AllergenSeverity.safe => colors.tertiary,
      AllergenSeverity.caution => const Color(0xFFF9A825),
      AllergenSeverity.unsafe => colors.error,
    };
  }

  Color _textColor(ColorScheme colors) {
    return switch (severity) {
      AllergenSeverity.safe => colors.tertiary,
      AllergenSeverity.caution => const Color(0xFFE65100),
      AllergenSeverity.unsafe => colors.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (compact) {
      return Tooltip(
        message: '$label (${severity.name})',
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _dotColor(colors),
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor(colors),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _dotColor(colors),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.allergenBadge.copyWith(
              color: _textColor(colors),
            ),
          ),
        ],
      ),
    );
  }
}
