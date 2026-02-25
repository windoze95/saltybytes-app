import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/allergen_provider.dart';
import '../../core/providers/recipe_provider.dart';
import '../../models/allergen.dart';
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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

class _AnalysisBody extends StatelessWidget {
  const _AnalysisBody({
    required this.analysis,
    required this.onReanalyze,
    required this.isAnalyzing,
  });

  final AllergenAnalysis analysis;
  final VoidCallback onReanalyze;
  final bool isAnalyzing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
                  'AI-generated analysis -- does not replace medical advice. Always verify with your healthcare provider.',
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
            color: analysis.isSafeForAll
                ? colors.tertiary.withValues(alpha: 0.08)
                : colors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                analysis.isSafeForAll
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: analysis.isSafeForAll ? colors.tertiary : colors.error,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.isSafeForAll
                          ? 'Safe for all family members'
                          : 'Contains potential allergens',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: analysis.isSafeForAll
                            ? colors.tertiary
                            : colors.error,
                      ),
                    ),
                    if (analysis.analyzedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Analyzed ${_timeAgo(analysis.analyzedAt!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Detected allergens
        if (analysis.detectedAllergens.isNotEmpty) ...[
          Text(
            'Detected Allergens',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...analysis.detectedAllergens.map(
            (info) => _AllergenInfoCard(
              info: info,
              severity: AllergenSeverity.unsafe,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Possible allergens
        if (analysis.possibleAllergens.isNotEmpty) ...[
          Text(
            'Possible Allergens',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...analysis.possibleAllergens.map(
            (info) => _AllergenInfoCard(
              info: info,
              severity: AllergenSeverity.caution,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Family safety
        if (analysis.familySafetyChecks.isNotEmpty) ...[
          Text(
            'Family Member Safety',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...analysis.familySafetyChecks.map(
            (check) => _FamilySafetyCard(check: check),
          ),
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

class _AllergenInfoCard extends StatelessWidget {
  const _AllergenInfoCard({
    required this.info,
    required this.severity,
  });

  final AllergenInfo info;
  final AllergenSeverity severity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: severity == AllergenSeverity.unsafe
            ? colors.error.withValues(alpha: 0.04)
            : const Color(0xFFF9A825).withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AllergenBadge(
                label: info.allergen,
                severity: severity,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Source: ${info.source}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (info.ingredient != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Ingredient: ${info.ingredient}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    if (info.notes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        info.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    // Severity bar
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Severity: ',
                          style: theme.textTheme.labelSmall,
                        ),
                        Expanded(
                          child: _SeverityBar(
                            level: info.severity,
                            colors: colors,
                          ),
                        ),
                      ],
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

class _SeverityBar extends StatelessWidget {
  const _SeverityBar({
    required this.level,
    required this.colors,
  });

  final String level;
  final ColorScheme colors;

  double get _fillRatio {
    return switch (level.toLowerCase()) {
      'low' => 0.25,
      'medium' => 0.5,
      'high' => 0.75,
      'critical' => 1.0,
      _ => 0.5,
    };
  }

  Color get _color {
    return switch (level.toLowerCase()) {
      'low' => colors.tertiary,
      'medium' => const Color(0xFFF9A825),
      'high' || 'critical' => colors.error,
      _ => const Color(0xFFF9A825),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _fillRatio,
              backgroundColor: colors.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(_color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          level,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _color,
          ),
        ),
      ],
    );
  }
}

class _FamilySafetyCard extends StatelessWidget {
  const _FamilySafetyCard({required this.check});

  final FamilySafetyCheck check;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: check.isSafe
            ? colors.tertiary.withValues(alpha: 0.04)
            : colors.error.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                check.isSafe
                    ? Icons.check_circle
                    : Icons.cancel,
                color: check.isSafe ? colors.tertiary : colors.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      check.memberName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (check.conflicts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Conflicts: ${check.conflicts.join(', ')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ],
                    if (check.warnings.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Warnings: ${check.warnings.join(', ')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFF9A825),
                        ),
                      ),
                    ],
                    if (check.isSafe &&
                        check.conflicts.isEmpty &&
                        check.warnings.isEmpty)
                      Text(
                        'Safe to eat',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.tertiary,
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
