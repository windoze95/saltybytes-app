import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/recipe_provider.dart';
import '../../models/recipe.dart';

class ImportUrlScreen extends ConsumerStatefulWidget {
  const ImportUrlScreen({super.key});

  @override
  ConsumerState<ImportUrlScreen> createState() => _ImportUrlScreenState();
}

class _ImportUrlScreenState extends ConsumerState<ImportUrlScreen> {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Recipe? _preview;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _urlController.text = data!.text!;
      setState(() {});
    }
  }

  Future<void> _importUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Please enter a URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _preview = null;
    });

    try {
      final recipe = await ref.read(recipeCrudProvider).importFromUrl(url);
      setState(() {
        _preview = recipe;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not extract recipe from this URL. Please try another.';
        _isLoading = false;
      });
    }
  }

  void _saveRecipe() {
    if (_preview != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe imported successfully!')),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Import from URL')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paste a recipe URL',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll extract the recipe details automatically.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),

            // URL input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Recipe URL',
                      hintText: 'https://example.com/recipe...',
                      prefixIcon: Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _importUrl(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste),
                  tooltip: 'Paste',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Import button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _importUrl,
                icon: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(_isLoading ? 'Extracting...' : 'Import'),
              ),
            ),

            // Error
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Preview
            if (_preview != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text('Recipe Preview', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              _RecipePreviewCard(recipe: _preview!),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saveRecipe,
                  icon: const Icon(Icons.check),
                  label: const Text('Save Recipe'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecipePreviewCard extends StatelessWidget {
  const _RecipePreviewCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recipe.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (recipe.cookTimeMinutes != null) ...[
                  Icon(Icons.timer_outlined, size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text('${recipe.cookTimeMinutes} min',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(width: 16),
                ],
                Icon(Icons.restaurant_outlined, size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text('${recipe.ingredients.length} ingredients',
                    style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(Icons.format_list_numbered, size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text('${recipe.instructions.length} steps',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
