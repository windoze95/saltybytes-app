import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/recipe_provider.dart';

/// Generate-with-AI screen backing POST /v1/recipes/chat.
///
/// The backend immediately returns a placeholder recipe with
/// status == "generating" and finishes asynchronously, so after submitting
/// we poll GET /v1/recipes/:id until the recipe is ready, then navigate to
/// the finished recipe.
class GenerateRecipeScreen extends ConsumerStatefulWidget {
  const GenerateRecipeScreen({super.key});

  @override
  ConsumerState<GenerateRecipeScreen> createState() =>
      _GenerateRecipeScreenState();
}

class _GenerateRecipeScreenState extends ConsumerState<GenerateRecipeScreen> {
  final _promptController = TextEditingController();
  bool _generateImage = true;
  bool _isGenerating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Rebuild as the user types so the submit button enables/disables live.
    _promptController.addListener(_onPromptChanged);
  }

  void _onPromptChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _promptController.removeListener(_onPromptChanged);
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final crud = ref.read(recipeCrudProvider);
      // The container stays usable after this screen is popped (a disposed
      // widget's `ref` throws), so the list still refreshes if the user
      // backs out mid-generation.
      final container = ProviderScope.containerOf(context, listen: false);

      // Returns a placeholder recipe (status == "generating") immediately.
      final placeholder = await crud.generate(
        userPrompt: prompt,
        genImage: _generateImage,
      );

      container.invalidate(recipeListProvider);

      // Poll until the backend finishes generating.
      final recipe = await crud.waitUntilGenerated(placeholder.id);

      container.invalidate(recipeListProvider);
      container.invalidate(recipeDetailProvider(recipe.id));

      if (mounted) {
        // pushReplacement keeps the underlying stack (home) so the detail
        // screen still has a back route; go() would replace the whole stack
        // and strand the user.
        context.pushReplacementNamed(
          'recipe-detail',
          pathParameters: {'id': recipe.id},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _error = e is RecipeGenerationException
              ? e.message
              : 'Could not generate the recipe. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canSubmit = _promptController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Generate with AI')),
      body: _isGenerating
          ? const _GeneratingProgress()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'What would you like to cook?',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Describe a dish, cuisine, or ingredients you have on '
                    'hand and we\'ll create a recipe for you.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _promptController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'e.g., "A cozy chicken pot pie", "Something '
                          'quick with salmon and asparagus"...',
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
                        label: 'Weeknight dinner',
                        onTap: () => _promptController.text =
                            'An easy weeknight dinner ready in 30 minutes',
                      ),
                      _SuggestionChip(
                        label: 'Comfort food',
                        onTap: () => _promptController.text =
                            'A hearty comfort food classic',
                      ),
                      _SuggestionChip(
                        label: 'Healthy lunch',
                        onTap: () => _promptController.text =
                            'A light, healthy lunch full of vegetables',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SwitchListTile(
                    value: _generateImage,
                    onChanged: (v) => setState(() => _generateImage = v),
                    title: const Text('Generate image'),
                    subtitle: const Text(
                      'Create an AI-generated photo of the finished dish',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Error message
                  if (_error != null) ...[
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
                          Icon(Icons.error_outline,
                              color: colors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
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

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: canSubmit ? _handleGenerate : null,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate Recipe'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _GeneratingProgress extends StatelessWidget {
  const _GeneratingProgress();

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
              Icons.auto_awesome,
              size: 56,
              color: colors.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Generating your recipe...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This usually takes under a minute.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
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
