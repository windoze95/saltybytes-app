import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/recipe_provider.dart';
import '../../models/recipe.dart';

class ImportVideoScreen extends ConsumerStatefulWidget {
  const ImportVideoScreen({super.key});

  @override
  ConsumerState<ImportVideoScreen> createState() => _ImportVideoScreenState();
}

class _ImportVideoScreenState extends ConsumerState<ImportVideoScreen> {
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

  /// Maps an import failure to a user-facing message, surfacing the backend's
  /// reason for the quota gate (403), unsupported link (400), and the
  /// feature-off (503) cases, and the job error for async failures.
  String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      final apiMsg =
          (data is Map && data['error'] is String) ? data['error'] as String : null;
      switch (e.response?.statusCode) {
        case 403:
          return apiMsg ??
              'You\'ve reached your video import limit. Upgrade to premium for more.';
        case 400:
          return apiMsg ??
              'That link isn\'t supported. Try a TikTok or Instagram video.';
        case 503:
          return 'Video import isn\'t available right now. Please try again later.';
        default:
          return apiMsg ?? 'Could not import this video. Please try again.';
      }
    }
    if (e is VideoImportException) return e.message;
    return 'Could not import this video. Please try another link.';
  }

  Future<void> _importVideo() async {
    // The recipe row is created server-side on the first successful import;
    // never re-import the same input.
    if (_isLoading || _preview != null) return;

    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Please paste a video link');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // The container stays usable after this screen is popped (a disposed
    // widget's `ref` throws), so the list still refreshes if the user backs
    // out during the (slow) import.
    final container = ProviderScope.containerOf(context, listen: false);

    try {
      final recipe = await ref.read(recipeCrudProvider).importFromVideo(url);
      container.invalidate(recipeListProvider);
      if (!mounted) return;
      setState(() {
        _preview = recipe;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _viewRecipe() {
    final recipe = _preview;
    if (recipe != null) {
      // pushReplacement keeps the underlying stack (import hub / home) so the
      // detail screen still has a back route.
      context.pushReplacement('/recipe/${recipe.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Import from Video')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Paste a video link', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'TikTok and Instagram supported. We watch the video and read the '
              'recipe from what\'s shown and said.',
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
                      labelText: 'Video link',
                      hintText: 'https://www.tiktok.com/@...',
                      prefixIcon: Icon(Icons.play_circle_outline),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    enabled: !_isLoading,
                    onChanged: (_) {
                      if (_preview != null || _error != null) {
                        setState(() {
                          _preview = null;
                          _error = null;
                        });
                      }
                    },
                    onSubmitted: (_) => _importVideo(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isLoading ? null : _pasteFromClipboard,
                  icon: const Icon(Icons.paste),
                  tooltip: 'Paste',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Import button (disabled after a successful import — the recipe
            // already exists server-side; re-tapping would create duplicates)
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    (_isLoading || _preview != null) ? null : _importVideo,
                icon: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Icon(_preview != null ? Icons.check : Icons.download),
                label: Text(_isLoading
                    ? 'Pulling recipe...'
                    : (_preview != null ? 'Imported' : 'Import')),
              ),
            ),

            // Loading hint — this path is slow (download + frames + AI).
            if (_isLoading) ...[
              const SizedBox(height: 16),
              Text(
                'This can take up to a minute. You can leave this screen — '
                'your recipe will be waiting on your home page.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],

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

            // Imported recipe
            if (_preview != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text('Imported Recipe', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              _VideoRecipePreviewCard(recipe: _preview!),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _viewRecipe,
                  icon: const Icon(Icons.menu_book),
                  label: const Text('View Recipe'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideoRecipePreviewCard extends StatelessWidget {
  const _VideoRecipePreviewCard({required this.recipe});

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
                  Icon(Icons.timer_outlined,
                      size: 16,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text('${recipe.cookTimeMinutes} min',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(width: 16),
                ],
                Icon(Icons.restaurant_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text('${recipe.ingredients.length} ingredients',
                    style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(Icons.format_list_numbered,
                    size: 16,
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
