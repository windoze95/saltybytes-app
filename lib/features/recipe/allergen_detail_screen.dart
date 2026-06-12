import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/allergen_provider.dart';
import '../../core/providers/family_provider.dart';
import '../../core/providers/recipe_provider.dart';
import '../../models/allergen.dart';
import '../../models/family.dart';
import 'widgets/allergen_badge.dart';

class AllergenDetailScreen extends ConsumerStatefulWidget {
  const AllergenDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<AllergenDetailScreen> createState() =>
      _AllergenDetailScreenState();
}

class _AllergenDetailScreenState extends ConsumerState<AllergenDetailScreen> {
  bool _isAnalyzing = false;

  Future<void> _runAnalysis() async {
    setState(() => _isAnalyzing = true);
    try {
      final analyzer = ref.read(allergenAnalyzeProvider);
      await analyzer.analyze(widget.recipeId);
      ref.invalidate(allergenAnalysisProvider(widget.recipeId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisAsync =
        ref.watch(allergenAnalysisProvider(widget.recipeId));
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));
    final recipeTitle = recipeAsync.whenOrNull(data: (r) => r.title) ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allergen Analysis'),
      ),
      body: analysisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _NotAnalyzedState(
          recipeTitle: recipeTitle,
          isAnalyzing: _isAnalyzing,
          onAnalyze: _runAnalysis,
        ),
        data: (analysis) => _AnalysisBody(
          analysis: analysis,
          onReanalyze: _runAnalysis,
          isAnalyzing: _isAnalyzing,
        ),
      ),
    );
  }
}

class _NotAnalyzedState extends StatelessWidget {
  const _NotAnalyzedState({
    required this.recipeTitle,
    required this.isAnalyzing,
    required this.onAnalyze,
  });

  final String recipeTitle;
  final bool isAnalyzing;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.science_outlined,
              size: 64,
              color: colors.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'Not Yet Analyzed',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Run AI-powered allergen analysis to check ingredient safety for your family.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isAnalyzing ? null : onAnalyze,
                icon: isAnalyzing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.science),
                label: Text(isAnalyzing ? 'Analyzing...' : 'Analyze'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A family member's safety status derived from the analysis profile lists.
class _MemberSafety {
  const _MemberSafety({required this.name, required this.isSafe});

  final String name;
  final bool isSafe;
}

class _AnalysisBody extends ConsumerWidget {
  const _AnalysisBody({
    required this.analysis,
    required this.onReanalyze,
    required this.isAnalyzing,
  });

  final AllergenAnalysis analysis;
  final VoidCallback onReanalyze;
  final bool isAnalyzing;

  List<_MemberSafety> _memberSafety(List<FamilyMember> members) {
    String nameFor(String memberId) {
      for (final m in members) {
        if (m.id == memberId) return m.name;
      }
      return 'Member #$memberId';
    }

    return [
      for (final id in analysis.unsafeForProfiles)
        _MemberSafety(name: nameFor(id), isSafe: false),
      for (final id in analysis.safeForProfiles)
        _MemberSafety(name: nameFor(id), isSafe: true),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final members =
        ref.watch(familyProvider).valueOrNull?.members ?? const <FamilyMember>[];
    final memberSafety = _memberSafety(members);
    final detected = analysis.detectedAllergens;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9A825).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF9A825).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFFF9A825),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  analysis.disclaimer.isNotEmpty
                      ? analysis.disclaimer
                      : 'AI-generated analysis -- does not replace medical advice. Always verify with your healthcare provider.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Safety summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: detected.isEmpty
                ? colors.tertiary.withValues(alpha: 0.08)
                : colors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                detected.isEmpty
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: detected.isEmpty ? colors.tertiary : colors.error,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detected.isEmpty
                          ? 'No major allergens detected'
                          : 'Contains potential allergens',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            detected.isEmpty ? colors.tertiary : colors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        'Confidence ${(analysis.confidence * 100).round()}%',
                        if (analysis.requiresReview) 'needs review',
                        if (analysis.analyzedAt != null)
                          'analyzed ${_timeAgo(analysis.analyzedAt!)}',
                      ].join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Detected allergens
        if (detected.isNotEmpty) ...[
          Text(
            'Detected Allergens',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final allergen in detected)
                AllergenBadge(
                  label: allergen,
                  severity: AllergenSeverity.unsafe,
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],

        // Per-ingredient breakdown
        if (analysis.ingredientAnalyses.isNotEmpty) ...[
          Text(
            'Ingredient Breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...analysis.ingredientAnalyses.map(
            (ia) => _IngredientAnalysisCard(ingredientAnalysis: ia),
          ),
          const SizedBox(height: 20),
        ],

        // Family safety
        if (memberSafety.isNotEmpty) ...[
          Text(
            'Family Member Safety',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...memberSafety.map((safety) => _FamilySafetyCard(safety: safety)),
          const SizedBox(height: 20),
        ],

        // Re-analyze button
        Center(
          child: OutlinedButton.icon(
            onPressed: isAnalyzing ? null : onReanalyze,
            icon: isAnalyzing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(isAnalyzing ? 'Analyzing...' : 'Re-analyze'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _IngredientAnalysisCard extends StatelessWidget {
  const _IngredientAnalysisCard({required this.ingredientAnalysis});

  final IngredientAnalysis ingredientAnalysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ia = ingredientAnalysis;
    final hasAllergens =
        ia.commonAllergens.isNotEmpty || ia.possibleAllergens.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: hasAllergens
            ? colors.error.withValues(alpha: 0.04)
            : colors.tertiary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ia.ingredientName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (ia.seedOilRisk)
                    const AllergenBadge(
                      label: 'Seed Oil Risk',
                      severity: AllergenSeverity.caution,
                    ),
                ],
              ),
              if (hasAllergens) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final allergen in ia.commonAllergens)
                      AllergenBadge(
                        label: allergen,
                        severity: AllergenSeverity.unsafe,
                      ),
                    for (final allergen in ia.possibleAllergens)
                      AllergenBadge(
                        label: allergen,
                        severity: AllergenSeverity.caution,
                      ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  'No allergens identified',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.tertiary,
                  ),
                ),
              ],
              if (ia.subIngredients.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'May contain: ${ia.subIngredients.join(', ')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // Confidence bar
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Confidence: ',
                    style: theme.textTheme.labelSmall,
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ia.confidence.clamp(0.0, 1.0),
                        backgroundColor:
                            colors.onSurface.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(
                          ia.confidence >= 0.8
                              ? colors.tertiary
                              : const Color(0xFFF9A825),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(ia.confidence * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilySafetyCard extends StatelessWidget {
  const _FamilySafetyCard({required this.safety});

  final _MemberSafety safety;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: safety.isSafe
            ? colors.tertiary.withValues(alpha: 0.04)
            : colors.error.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                safety.isSafe ? Icons.check_circle : Icons.cancel,
                color: safety.isSafe ? colors.tertiary : colors.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      safety.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      safety.isSafe
                          ? 'Safe to eat'
                          : 'Contains allergens unsafe for this member',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: safety.isSafe ? colors.tertiary : colors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
