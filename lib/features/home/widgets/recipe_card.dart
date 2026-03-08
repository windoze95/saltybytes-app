import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.isNew = false,
  });

  final Recipe recipe;
  final VoidCallback? onTap;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                    child: recipe.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: recipe.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _ImagePlaceholder(
                              theme: theme,
                            ),
                            errorWidget: (_, __, ___) => Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 32,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          )
                        : _ImagePlaceholder(theme: theme),
                  ),
                  if (isNew)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'NEW',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),

                    // Metadata row
                    Row(
                      children: [
                        if (recipe.cookTimeMinutes != null) ...[
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${recipe.cookTimeMinutes}m',
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (recipe.portions != null) ...[
                          Icon(
                            Icons.restaurant_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${recipe.portions}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.restaurant,
        size: 40,
        color: theme.colorScheme.primary.withValues(alpha: 0.3),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 800.ms)
        .then()
        .fadeOut(duration: 800.ms);
  }
}
