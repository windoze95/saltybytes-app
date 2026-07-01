import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/family_provider.dart';
import '../../core/providers/finder_provider.dart';
import '../../core/voice/speech_service.dart';
import '../../models/family.dart' as models;

/// A selectable facet option: what the user sees ([label]) vs. the search-
/// friendly string sent to the backend ([value]).
class _Facet {
  const _Facet(this.label, this.value);
  final String label;
  final String value;
}

// Tap-first facet taxonomy. Labels are shown on chips; values are concatenated
// into the backend search query, so they read as natural search terms.
const _occasions = [
  _Facet('Weeknight', 'quick weeknight'),
  _Facet('Comfort food', 'comfort food'),
  _Facet('Healthy', 'healthy'),
  _Facet('Impress guests', 'impressive dinner party'),
  _Facet('Meal prep', 'meal prep'),
];

const _times = [
  _Facet('Any', ''), // clears the time budget
  _Facet('≤15 min', 'under 15 minutes'),
  _Facet('≤30 min', 'under 30 minutes'),
  _Facet('≤1 hr', 'under 1 hour'),
];

const _proteins = [
  _Facet('Chicken', 'chicken'),
  _Facet('Beef', 'beef'),
  _Facet('Pork', 'pork'),
  _Facet('Fish', 'fish'),
  _Facet('Vegetarian', 'vegetarian'),
  _Facet('Tofu', 'tofu'),
];

const _cuisines = [
  _Facet('Italian', 'Italian'),
  _Facet('Mexican', 'Mexican'),
  _Facet('Thai', 'Thai'),
  _Facet('Indian', 'Indian'),
  _Facet('Mediterranean', 'Mediterranean'),
  _Facet('American', 'American'),
  _Facet('Japanese', 'Japanese'),
];

/// The tap-first "what are you in the mood for?" launch screen. Chips dominate;
/// typing and voice are secondary. Builds a [FinderFacets] and hands off to the
/// run screen.
class FinderMoodScreen extends ConsumerStatefulWidget {
  const FinderMoodScreen({super.key});

  @override
  ConsumerState<FinderMoodScreen> createState() => _FinderMoodScreenState();
}

class _FinderMoodScreenState extends ConsumerState<FinderMoodScreen> {
  String? _occasion;
  String? _timeBudget;
  String? _protein;
  String? _cuisine;
  final List<String> _ingredients = [];
  bool _surpriseMe = false;

  final _detailsController = TextEditingController();
  final _ingredientController = TextEditingController();
  bool _detailsExpanded = false;
  bool _isListening = false;

  @override
  void dispose() {
    _detailsController.dispose();
    _ingredientController.dispose();
    super.dispose();
  }

  FinderFacets _buildFacets() {
    final details = _detailsController.text.trim();
    return FinderFacets(
      occasion: _occasion,
      timeBudget: _timeBudget,
      protein: _protein,
      cuisine: _cuisine,
      useWhatIHave: List.unmodifiable(_ingredients),
      surpriseMe: _surpriseMe,
      freeText: details.isEmpty ? null : details,
    );
  }

  void _find() {
    context.pushNamed('find-run', extra: _buildFacets());
  }

  void _addIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (!_ingredients.contains(text)) _ingredients.add(text);
      _ingredientController.clear();
    });
  }

  Future<void> _toggleVoice() async {
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

    if (mounted) {
      setState(() {
        _isListening = true;
        _detailsExpanded = true;
      });
    }
    await speech.listen(
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _detailsController.text = text;
          _detailsController.selection =
              TextSelection.collapsed(offset: text.length);
          if (isFinal) _isListening = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final family = ref.watch(familyProvider).valueOrNull;
    final diet = _familyDietSummary(family);

    return Scaffold(
      appBar: AppBar(title: const Text('Find a recipe')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'What are you in the mood for?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Tap a few, or just hit find — we'll pull real recipes for your family.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),

          if (diet != null) ...[
            _DietaryChip(
              summary: diet,
              onTap: () => context.pushNamed('family'),
            ),
            const SizedBox(height: 16),
          ],

          _SurpriseTile(
            selected: _surpriseMe,
            onTap: () => setState(() => _surpriseMe = !_surpriseMe),
          ),
          const SizedBox(height: 20),

          _FacetSection(
            title: 'Occasion',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in _occasions)
                  _facetChip(f, _occasion,
                      (v) => setState(() => _occasion = v)),
              ],
            ),
          ),

          _FacetSection(
            title: 'Time',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in _times)
                  _facetChip(f, _timeBudget,
                      (v) => setState(() => _timeBudget = v)),
              ],
            ),
          ),

          _FacetSection(
            title: 'Protein',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in _proteins)
                  _facetChip(
                      f, _protein, (v) => setState(() => _protein = v)),
              ],
            ),
          ),

          _FacetSection(
            title: 'Cuisine',
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _cuisines.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => Center(
                  child: _facetChip(_cuisines[i], _cuisine,
                      (v) => setState(() => _cuisine = v)),
                ),
              ),
            ),
          ),

          _FacetSection(
            title: 'Use what I have',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ingredientController,
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Add an ingredient…',
                          prefixIcon: Icon(Icons.kitchen_outlined),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addIngredient(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _addIngredient,
                      icon: const Icon(Icons.add),
                      tooltip: 'Add ingredient',
                    ),
                  ],
                ),
                if (_ingredients.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final ing in _ingredients)
                        InputChip(
                          label: Text(ing),
                          onDeleted: () =>
                              setState(() => _ingredients.remove(ing)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 4),
          _DetailsField(
            controller: _detailsController,
            expanded: _detailsExpanded,
            isListening: _isListening,
            onToggleExpand: () =>
                setState(() => _detailsExpanded = !_detailsExpanded),
            onVoice: _toggleVoice,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _find,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Find recipes'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.pushNamed('import'),
              child: const Text('Import instead'),
            ),
          ],
        ),
      ),
    );
  }

  /// Single-select chip: tapping the active one clears it (back to null).
  Widget _facetChip(
      _Facet facet, String? groupValue, void Function(String?) onChanged) {
    // The "Any" option carries an empty value: selecting it clears the facet.
    final isClear = facet.value.isEmpty;
    final selected = isClear ? groupValue == null : groupValue == facet.value;
    return ChoiceChip(
      label: Text(facet.label),
      selected: selected,
      onSelected: (sel) {
        if (isClear) {
          onChanged(null);
        } else {
          onChanged(sel ? facet.value : null);
        }
      },
    );
  }
}

/// Builds a short family diet summary ("no peanuts · vegetarian") from every
/// member's allergies + restrictions, or null when there's nothing to show.
String? _familyDietSummary(models.Family? family) {
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

class _FacetSection extends StatelessWidget {
  const _FacetSection({required this.title, required this.child});

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
class _DietaryChip extends StatelessWidget {
  const _DietaryChip({required this.summary, required this.onTap});

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
class _SurpriseTile extends StatelessWidget {
  const _SurpriseTile({required this.selected, required this.onTap});

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
                      "We'll pick something great for your family",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// The demoted, collapsible "Add details" free-text field with a voice mic.
class _DetailsField extends StatelessWidget {
  const _DetailsField({
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
