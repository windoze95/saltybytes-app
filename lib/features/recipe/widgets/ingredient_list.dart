import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../models/recipe.dart';

class IngredientList extends ConsumerWidget {
  const IngredientList({
    super.key,
    required this.ingredients,
    this.servings,
    this.showCategory = true,
    this.recipeUnitSystem = 'us_customary',
  });

  final List<Ingredient> ingredients;
  final int? servings;
  final bool showCategory;
  final String recipeUnitSystem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final userUnitSystem =
        userAsync.valueOrNull?.personalization.unitSystem ?? 'us_customary';

    final displayIngredients = ingredients.map((ing) {
      return convertIngredient(ing, recipeUnitSystem, userUnitSystem);
    }).toList();

    if (!showCategory) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: displayIngredients
            .map((ing) => _IngredientRow(ingredient: ing))
            .toList(),
      );
    }

    // Group by category
    final grouped = <String, List<Ingredient>>{};
    for (final ing in displayIngredients) {
      final cat = ing.category ?? 'Main';
      (grouped[cat] ??= []).add(ing);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          if (grouped.length > 1) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                entry.key,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
          ...entry.value.map((ing) => _IngredientRow(ingredient: ing)),
        ],
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient});

  final Ingredient ingredient;

  String _formatQuantity() {
    final parts = <String>[];
    if (ingredient.amount != null && ingredient.amount! > 0) {
      parts.add(formatAmountForUnit(ingredient.amount, ingredient.unit));
    }
    if (ingredient.unit != null && ingredient.unit!.isNotEmpty) {
      parts.add(ingredient.unit!);
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quantity = _formatQuantity();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          if (quantity.isNotEmpty) ...[
            Text(
              quantity,
              style: theme.textTheme.ingredientQuantity,
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: ingredient.name,
                    style: theme.textTheme.ingredientItem,
                  ),
                  if (ingredient.optional) ...[
                    TextSpan(
                      text: ' (optional)',
                      style: theme.textTheme.ingredientItem.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                  if (ingredient.notes != null) ...[
                    TextSpan(
                      text: ', ${ingredient.notes}',
                      style: theme.textTheme.ingredientItem.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
