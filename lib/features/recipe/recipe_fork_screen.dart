import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/recipe_provider.dart';

class RecipeForkScreen extends ConsumerStatefulWidget {
  const RecipeForkScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<RecipeForkScreen> createState() => _RecipeForkScreenState();
}

class _RecipeForkScreenState extends ConsumerState<RecipeForkScreen> {
  final _branchNameController = TextEditingController();
  final _modificationsController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Rebuild as the user types so the submit button enables/disables live.
    _branchNameController.addListener(_onInputChanged);
    _modificationsController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _branchNameController.removeListener(_onInputChanged);
    _modificationsController.removeListener(_onInputChanged);
    _branchNameController.dispose();
    _modificationsController.dispose();
    super.dispose();
  }

  /// The backend's fork endpoint takes a free-text user_prompt; combine the
  /// optional variation name with the modifications text.
  String _buildUserPrompt() {
    final branchName = _branchNameController.text.trim();
    final modifications = _modificationsController.text.trim();

    if (branchName.isNotEmpty && modifications.isNotEmpty) {
      return 'Variation name: $branchName. Changes: $modifications';
    }
    if (modifications.isNotEmpty) {
      return modifications;
    }
    return 'Create a variation of this recipe named "$branchName".';
  }

  bool get _canSubmit =>
      _branchNameController.text.trim().isNotEmpty ||
      _modificationsController.text.trim().isNotEmpty;

  Future<void> _handleFork() async {
    if (!_canSubmit) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final crud = ref.read(recipeCrudProvider);
      // The backend returns a placeholder (status == "generating") and
      // finishes the fork asynchronously; wait for it to complete so the
      // user lands on a fully formed recipe.
      final placeholder = await crud.fork(
        widget.recipeId,
        userPrompt: _buildUserPrompt(),
      );

      ref.invalidate(recipeListProvider);

      final newRecipe = await crud.waitUntilGenerated(placeholder.id);

      ref.invalidate(recipeListProvider);
      ref.invalidate(recipeDetailProvider(newRecipe.id));

      if (mounted) {
        context.goNamed(
          'recipe-detail',
          pathParameters: {'id': newRecipe.id},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e is RecipeGenerationException
              ? e.message
              : 'Failed to fork recipe. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fork Recipe'),
      ),
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (recipe) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source recipe info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.secondary.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.fork_right,
                          color: colors.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Forking from',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recipe.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Branch name
              Text(
                'Branch name',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _branchNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., spicy-version, dairy-free',
                ),
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),

              // Modifications
              Text(
                'Modifications (optional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Describe how this fork should differ from the original',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _modificationsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'e.g., "Replace butter with olive oil", "Double the spices"...',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Quick fork reasons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickChip(
                    label: 'Dietary swap',
                    onTap: () {
                      _branchNameController.text = 'dietary-alternative';
                      _modificationsController.text =
                          'Replace allergens with safe alternatives';
                    },
                  ),
                  _QuickChip(
                    label: 'Kid-friendly',
                    onTap: () {
                      _branchNameController.text = 'kid-friendly';
                      _modificationsController.text =
                          'Make it more kid-friendly with milder flavors';
                    },
                  ),
                  _QuickChip(
                    label: 'Quick version',
                    onTap: () {
                      _branchNameController.text = 'quick-version';
                      _modificationsController.text =
                          'Simplify for a faster cook time';
                    },
                  ),
                ],
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Fork button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting || !_canSubmit ? null : _handleFork,
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.fork_right),
                  label: Text(_isSubmitting ? 'Forking...' : 'Fork Recipe'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
