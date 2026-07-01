import 'package:flutter/material.dart';

import '../../../models/family.dart' as models;

/// A selectable facet option: what the user sees ([label]) vs. the search-
/// friendly string sent to the backend ([value]). An empty [value] means the
/// option clears its facet group (e.g. Time → "Any").
class FacetOption {
  const FacetOption(this.label, this.value);
  final String label;
  final String value;
}

// Tap-first facet taxonomy. Labels are shown on chips; values are concatenated
// into the backend search query, so they read as natural search terms.
const kOccasions = [
  FacetOption('Weeknight', 'quick weeknight'),
  FacetOption('Comfort food', 'comfort food'),
  FacetOption('Healthy', 'healthy'),
  FacetOption('Impress guests', 'impressive dinner party'),
  FacetOption('Meal prep', 'meal prep'),
];

const kTimes = [
  FacetOption('Any', ''), // clears the time budget
  FacetOption('≤15 min', 'under 15 minutes'),
  FacetOption('≤30 min', 'under 30 minutes'),
  FacetOption('≤1 hr', 'under 1 hour'),
];

const kProteins = [
  FacetOption('Chicken', 'chicken'),
  FacetOption('Beef', 'beef'),
  FacetOption('Pork', 'pork'),
  FacetOption('Fish', 'fish'),
  FacetOption('Vegetarian', 'vegetarian'),
  FacetOption('Tofu', 'tofu'),
];

const kCuisines = [
  FacetOption('Italian', 'Italian'),
  FacetOption('Mexican', 'Mexican'),
  FacetOption('Thai', 'Thai'),
  FacetOption('Indian', 'Indian'),
  FacetOption('Mediterranean', 'Mediterranean'),
  FacetOption('American', 'American'),
  FacetOption('Japanese', 'Japanese'),
];

/// Builds a short family diet summary ("no peanuts · vegetarian") from every
/// member's allergies + restrictions, or null when there's nothing to show.
String? familyDietSummary(models.Family? family) {
  if (family == null || family.members.isEmpty) return null;

  final allergies = <String>{};
  final restrictions = <String>{};
  for (final m in family.members) {
    for (final a in m.dietaryProfile.allergies) {
      final name = a.name.trim();
      if (name.isNotEmpty) allergies.add(name.toLowerCase());
    }
    for (final r in m.dietaryProfile.restrictions) {
      final name = r.trim();
      if (name.isNotEmpty) restrictions.add(name.toLowerCase());
    }
  }

  final parts = <String>[
    ...allergies.map((a) => 'no $a'),
    ...restrictions,
  ];
  if (parts.isEmpty) return null;
  return parts.take(4).join(' · ');
}

/// Single-select facet chip: tapping the active one clears it (back to null).
/// The "clear" option (empty value, e.g. "Any") shows as selected when nothing
/// is chosen.
class FacetChoiceChip extends StatelessWidget {
  const FacetChoiceChip({
    super.key,
    required this.option,
    required this.groupValue,
    required this.onChanged,
  });

  final FacetOption option;
  final String? groupValue;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final isClear = option.value.isEmpty;
    final selected = isClear ? groupValue == null : groupValue == option.value;
    return ChoiceChip(
      label: Text(option.label),
      selected: selected,
      onSelected: (sel) {
        if (isClear) {
          onChanged(null);
        } else {
          onChanged(sel ? option.value : null);
        }
      },
    );
  }
}

class FacetSection extends StatelessWidget {
  const FacetSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// The read-only "cooking for your family" chip, tappable through to the
/// family screen.
class DietaryChip extends StatelessWidget {
  const DietaryChip({super.key, required this.summary, required this.onTap});

  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.secondaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cooking for your family',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      summary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18, color: colors.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The prominent "Surprise me" option — a full-width selectable card.
class SurpriseTile extends StatelessWidget {
  const SurpriseTile({super.key, required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: selected
          ? colors.primary.withValues(alpha: 0.14)
          : colors.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? colors.primary
                  : colors.outlineVariant.withValues(alpha: 0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.casino_outlined,
                  size: 28,
                  color: selected
                      ? colors.primary
                      : colors.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Surprise me',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected ? colors.primary : null,
                      ),
                    ),
                    Text(
                      "We'll pick something great from across the internet",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// The demoted, collapsible "Add details" free-text field with a voice mic.
class DetailsField extends StatelessWidget {
  const DetailsField({
    super.key,
    required this.controller,
    required this.expanded,
    required this.isListening,
    required this.onToggleExpand,
    required this.onVoice,
  });

  final TextEditingController controller;
  final bool expanded;
  final bool isListening;
  final VoidCallback onToggleExpand;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onToggleExpand,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add details (optional)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onVoice,
              tooltip: 'Speak',
              icon: Icon(isListening ? Icons.mic : Icons.mic_none),
              color: isListening ? colors.primary : null,
            ),
          ],
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: isListening
                    ? 'Listening…'
                    : 'e.g. something cozy the kids will actually eat',
              ),
            ),
          ),
      ],
    );
  }
}
