import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/providers/recipe_provider.dart';
import '../../models/recipe.dart';

class RecipeEditScreen extends ConsumerStatefulWidget {
  const RecipeEditScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends ConsumerState<RecipeEditScreen> {
  final _promptController = TextEditingController();
  bool _generateNewImage = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _handleRegenerate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        ApiEndpoints.recipeById(widget.recipeId),
        data: {
          'prompt': prompt,
          'regenerate_image': _generateNewImage,
        },
      );

      ref.invalidate(recipeDetailProvider(widget.recipeId));
      ref.invalidate(recipeListProvider);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          final error = e;
          if (error is ApiError) {
            _errorMessage = error.message;
          } else {
            _errorMessage = 'Failed to regenerate recipe. Please try again.';
          }
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
        title: const Text('Edit Recipe'),
      ),
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (recipe) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current recipe summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      color: colors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Prompt section
              Text(
                'How would you like to modify this recipe?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Describe your changes in natural language',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _promptController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'e.g., "Make it spicier", "Use less sugar", "Make it vegan"...',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Quick suggestions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SuggestionChip(
                    label: 'Make healthier',
                    onTap: () => _promptController.text = 'Make it healthier',
                  ),
                  _SuggestionChip(
                    label: 'Reduce sugar',
                    onTap: () =>
                        _promptController.text = 'Reduce the sugar content',
                  ),
                  _SuggestionChip(
                    label: 'Make spicier',
                    onTap: () => _promptController.text = 'Make it spicier',
                  ),
                  _SuggestionChip(
                    label: 'Simplify',
                    onTap: () => _promptController.text =
                        'Simplify with fewer ingredients',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Generate new image toggle
              SwitchListTile(
                value: _generateNewImage,
                onChanged: (v) => setState(() => _generateNewImage = v),
                title: const Text('Generate new image'),
                subtitle: const Text(
                  'Create a new AI-generated image for the updated recipe',
                ),
                contentPadding: EdgeInsets.zero,
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

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ||
                          _promptController.text.trim().isEmpty
                      ? null
                      : _handleRegenerate,
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isSubmitting ? 'Regenerating...' : 'Regenerate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
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
