import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/recipe.dart';

class ImportTextScreen extends ConsumerStatefulWidget {
  const ImportTextScreen({super.key});

  @override
  ConsumerState<ImportTextScreen> createState() => _ImportTextScreenState();
}

class _ImportTextScreenState extends ConsumerState<ImportTextScreen> {
  final _textController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Recipe? _preview;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _extractRecipe() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Please paste some recipe text.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _preview = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        ApiEndpoints.importFromText,
        data: {'text': text},
      );

      final recipe = Recipe.fromJson(response.data as Map<String, dynamic>);
      setState(() {
        _preview = recipe;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not extract a recipe from this text. Try reformatting.';
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
      appBar: AppBar(title: const Text('Import from Text')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paste your recipe text',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Paste the full recipe including ingredients and instructions.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),

            // Text area
            TextField(
              controller: _textController,
              maxLines: 12,
              decoration: const InputDecoration(
                hintText:
                    'Paste recipe text here...\n\n'
                    'e.g. Ingredients:\n'
                    '- 2 cups flour\n'
                    '- 1 cup sugar\n\n'
                    'Instructions:\n'
                    '1. Mix dry ingredients...',
                alignLabelWithHint: true,
              ),
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 20),

            // Extract button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _extractRecipe,
                icon: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isLoading ? 'Extracting...' : 'Extract Recipe'),
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
              Text('Extracted Recipe', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _preview!.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_preview!.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _preview!.description!,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        '${_preview!.ingredients.length} ingredients, '
                        '${_preview!.instructions.length} steps',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
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
